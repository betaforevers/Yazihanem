package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/mehmetkilic/yazihanem/config"
	"github.com/mehmetkilic/yazihanem/internal/delivery/http/handler"
	"github.com/mehmetkilic/yazihanem/internal/delivery/http/middleware"
	infraCache "github.com/mehmetkilic/yazihanem/internal/infrastructure/cache"
	"github.com/mehmetkilic/yazihanem/internal/infrastructure/database"
	"github.com/mehmetkilic/yazihanem/pkg/audit"
	"github.com/mehmetkilic/yazihanem/pkg/auth"
	cachepkg "github.com/mehmetkilic/yazihanem/pkg/cache"
	dbpkg "github.com/mehmetkilic/yazihanem/pkg/database"
	"github.com/mehmetkilic/yazihanem/pkg/migration"
	"github.com/mehmetkilic/yazihanem/pkg/ratelimit"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Create context
	ctx := context.Background()

	// Initialize database connection pool
	log.Println("Connecting to database...")
	pool, err := dbpkg.NewPool(ctx, &cfg.Database)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer pool.Close()
	log.Println("✓ Database connected")

	// Initialize Redis connection
	log.Println("Connecting to Redis...")
	redisClient, err := cachepkg.NewRedisClient(ctx, &cfg.Redis)
	if err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}
	defer redisClient.Close()
	log.Println("✓ Redis connected")

	// Initialize cache and session managers
	cacheManager := infraCache.NewCacheManager(redisClient)
	sessionManager := infraCache.NewSessionManager(redisClient, "session", 24*time.Hour)

	// Initialize JWT manager
	jwtManager := auth.NewJWTManager(cfg.JWT.Secret, cfg.JWT.ExpiryDuration)

	// Initialize rate limiter
	rateLimiter := ratelimit.NewLimiter(redisClient.Client)

	// Initialize audit logger
	auditLogger := audit.NewLogger(pool.Pool)

	// Initialize migrator
	migrator := migration.NewMigrator(pool.Pool, "migrations/schema")

	// Initialize repositories
	tenantRepo := database.NewTenantRepository(pool.Pool, migrator)
	userRepo := database.NewUserRepository(pool.Pool)
	contentRepo := database.NewContentRepository(pool.Pool)

	// Initialize handlers
	authHandler := handler.NewAuthHandler(jwtManager, sessionManager, userRepo)
	auditHandler := handler.NewAuditHandler(auditLogger)
	contentHandler := handler.NewContentHandler(contentRepo, auditLogger)
	userHandler := handler.NewUserHandler(userRepo, auditLogger)
	tenantHandler := handler.NewTenantHandler(tenantRepo, userRepo, auditLogger)

	// Initialize Fiber app
	app := fiber.New(fiber.Config{
		AppName: "Yazıhanem CMS v1.0",
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}
			return c.Status(code).JSON(fiber.Map{
				"error":   err.Error(),
				"code":    code,
				"path":    c.Path(),
				"method":  c.Method(),
			})
		},
	})

	// Global middleware
	app.Use(recover.New())
	app.Use(logger.New(logger.Config{
		Format: "[${time}] ${status} - ${latency} ${method} ${path}\n",
	}))
	// CORS configuration - restrict to allowed origins only
	allowedOrigins := os.Getenv("ALLOWED_ORIGINS")
	if allowedOrigins == "" {
		// Development default - restrict to localhost only
		allowedOrigins = "http://localhost:3000,http://localhost:5173"
	}

	app.Use(cors.New(cors.Config{
		AllowOrigins:     allowedOrigins,
		AllowMethods:     "GET,POST,PUT,DELETE,PATCH,OPTIONS",
		AllowHeaders:     "Origin,Content-Type,Accept,Authorization",
		AllowCredentials: true, // Required for cookies/auth headers
	}))

	// Health check endpoint (no tenant required)
	app.Get("/health", func(c *fiber.Ctx) error {
		// Check database health
		dbErr := pool.HealthCheck(ctx)
		dbHealthy := dbErr == nil

		// Check Redis health
		redisErr := redisClient.HealthCheck(ctx)
		redisHealthy := redisErr == nil

		stats := pool.Stats()
		redisStats := redisClient.Stats()

		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "yazihanem-api",
			"database": fiber.Map{
				"healthy":           dbHealthy,
				"total_connections": stats.TotalConns(),
				"idle_connections":  stats.IdleConns(),
			},
			"redis": fiber.Map{
				"healthy":     redisHealthy,
				"total_conns": redisStats.TotalConns,
				"idle_conns":  redisStats.IdleConns,
				"stale_conns": redisStats.StaleConns,
			},
			"timestamp": time.Now().Unix(),
		})
	})

	// Initialize middlewares
	tenantResolver := middleware.NewTenantResolver(tenantRepo)
	authMiddleware := middleware.NewAuthMiddleware(jwtManager)

	// API routes group with tenant resolution
	api := app.Group("/api/v1")
	api.Use(tenantResolver.Resolve()) // Apply tenant middleware to all API routes

	// Apply tenant-based rate limiting to all API routes (1000 req/min per tenant)
	api.Use(middleware.TenantRateLimit(rateLimiter, 1000))

	// Apply audit logging middleware to all API routes
	api.Use(middleware.AuditLogger(auditLogger))

	// Public routes (no authentication required)
	api.Get("/", func(c *fiber.Ctx) error {
		tenant, err := middleware.GetTenantFromContext(c)
		if err != nil {
			return err
		}

		return c.JSON(fiber.Map{
			"message":         "Yazıhanem API v1",
			"tenant":          tenant.Name,
			"tenant_id":       tenant.ID,
			"schema":          tenant.SchemaName,
			"cache_manager":   cacheManager != nil,
			"session_manager": sessionManager != nil,
		})
	})

	// Tenant onboarding route (public - no tenant middleware)
	app.Post("/api/v1/register", tenantHandler.RegisterTenant)

	// Auth routes (public) with strict rate limiting
	authRoutes := api.Group("/auth")

	// Login endpoint: 5 attempts per minute per IP (brute-force protection)
	authRoutes.Post("/login", middleware.AuthRateLimit(rateLimiter), authHandler.Login)

	// Refresh token: moderate rate limit (20 per minute per IP)
	authRoutes.Post("/refresh", middleware.IPRateLimit(rateLimiter, 20), authHandler.RefreshToken)

	// Protected auth routes (requires authentication)
	authProtected := authRoutes.Group("", authMiddleware.Authenticate())
	authProtected.Post("/logout", authHandler.Logout)
	authProtected.Get("/me", authHandler.Me)
	authProtected.Post("/change-password", authHandler.ChangePassword)

	// Protected API routes (requires authentication)
	protected := api.Group("", authMiddleware.Authenticate())

	// Admin-only routes
	adminRoutes := protected.Group("/admin", middleware.RequireRole("admin"))

	// Admin stats endpoint
	adminRoutes.Get("/stats", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"message": "Admin stats endpoint",
		})
	})

	// Audit log endpoints (admin only)
	adminRoutes.Get("/audit-logs", auditHandler.QueryLogs)
	adminRoutes.Get("/audit-logs/stats", auditHandler.GetLogStats)
	adminRoutes.Delete("/audit-logs/cleanup", auditHandler.DeleteOldLogs)

	// Content routes (protected - requires authentication)
	contentRoutes := protected.Group("/content")

	// Content CRUD endpoints
	contentRoutes.Post("/", contentHandler.CreateContent)         // Create content
	contentRoutes.Get("/", contentHandler.ListContent)            // List all content (with filters)
	contentRoutes.Get("/my", contentHandler.ListMyContent)        // List my content
	contentRoutes.Get("/:id", contentHandler.GetContent)          // Get content by ID
	contentRoutes.Get("/slug/:slug", contentHandler.GetContentBySlug) // Get content by slug
	contentRoutes.Put("/:id", contentHandler.UpdateContent)       // Update content
	contentRoutes.Delete("/:id", contentHandler.DeleteContent)    // Delete content
	contentRoutes.Patch("/:id/publish", contentHandler.PublishContent) // Publish content

	// User management routes (admin only)
	userRoutes := adminRoutes.Group("/users")
	userRoutes.Post("/", userHandler.CreateUser)                  // Create user
	userRoutes.Get("/", userHandler.ListUsers)                    // List users
	userRoutes.Get("/:id", userHandler.GetUser)                   // Get user by ID
	userRoutes.Put("/:id", userHandler.UpdateUser)                // Update user
	userRoutes.Delete("/:id", userHandler.DeleteUser)             // Delete user
	userRoutes.Patch("/:id/activate", userHandler.ActivateUser)   // Activate user
	userRoutes.Patch("/:id/deactivate", userHandler.DeactivateUser) // Deactivate user

	// Start server with graceful shutdown
	port := cfg.Server.Port
	serverAddr := fmt.Sprintf(":%s", port)

	// Channel to listen for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)

	// Start server in goroutine
	go func() {
		log.Printf("Starting server on port %s", port)
		if err := app.Listen(serverAddr); err != nil {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal
	<-quit
	log.Println("Shutting down server...")

	// Graceful shutdown with timeout
	shutdownCtx, cancel := context.WithTimeout(context.Background(), cfg.Server.ShutdownTimeout)
	defer cancel()

	if err := app.ShutdownWithContext(shutdownCtx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
	}

	log.Println("Server stopped")
}
