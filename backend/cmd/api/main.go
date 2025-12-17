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
	"github.com/mehmetkilic/yazihanem/pkg/storage"
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

	// Run public schema migrations (tenants, audit_logs, etc.)
	log.Println("Running database migrations...")
	if err := migrator.MigratePublicSchema(ctx); err != nil {
		log.Printf("Warning: Migration failed: %v", err)
	} else {
		log.Println("✓ Database migrations completed")
	}

	// Initialize storage manager
	var storageManager storage.Storage
	var storageErr error
	switch cfg.Storage.Type {
	case "local":
		uploadPath := getEnv("UPLOAD_PATH", "./uploads")
		storageManager, storageErr = storage.NewLocalStorage(uploadPath)
	case "s3", "minio":
		log.Fatal("S3/MinIO storage not yet implemented")
	default:
		log.Fatal("Invalid STORAGE_TYPE. Must be: local, s3, or minio")
	}
	if storageErr != nil {
		log.Fatalf("Failed to initialize storage: %v", storageErr)
	}
	log.Printf("✓ Storage initialized (type: %s)", cfg.Storage.Type)

	// Initialize repositories
	tenantRepo := database.NewTenantRepository(pool.Pool, migrator)
	userRepo := database.NewUserRepository(pool.Pool)
	contentRepo := database.NewContentRepository(pool.Pool)
	mediaRepo := database.NewMediaRepository(pool.Pool)

	// Initialize handlers
	authHandler := handler.NewAuthHandler(jwtManager, sessionManager, userRepo)
	auditHandler := handler.NewAuditHandler(auditLogger)
	contentHandler := handler.NewContentHandler(contentRepo, auditLogger)
	userHandler := handler.NewUserHandler(userRepo, auditLogger)
	tenantHandler := handler.NewTenantHandler(tenantRepo, userRepo, auditLogger)
	mediaHandler := handler.NewMediaHandler(mediaRepo, storageManager, auditLogger)

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
		tenant, err := middleware.GetTenantFromContext(c)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Tenant not found",
			})
		}

		ctx := c.UserContext()

		// Query actual database statistics
		var userCount int64
		pool.Pool.QueryRow(ctx,
			fmt.Sprintf("SELECT COUNT(*) FROM %s.users WHERE is_active = true", tenant.SchemaName),
		).Scan(&userCount)

		var publishedContent int64
		pool.Pool.QueryRow(ctx,
			fmt.Sprintf("SELECT COUNT(*) FROM %s.content WHERE status = 'published'", tenant.SchemaName),
		).Scan(&publishedContent)

		var draftContent int64
		pool.Pool.QueryRow(ctx,
			fmt.Sprintf("SELECT COUNT(*) FROM %s.content WHERE status = 'draft'", tenant.SchemaName),
		).Scan(&draftContent)

		var mediaCount int64
		var totalMediaSize int64
		pool.Pool.QueryRow(ctx,
			fmt.Sprintf("SELECT COUNT(*), COALESCE(SUM(size_bytes), 0) FROM %s.media", tenant.SchemaName),
		).Scan(&mediaCount, &totalMediaSize)

		return c.JSON(fiber.Map{
			"tenant": fiber.Map{
				"id":   tenant.ID,
				"name": tenant.Name,
			},
			"users": fiber.Map{
				"total":  userCount,
				"active": userCount,
			},
			"content": fiber.Map{
				"total":     publishedContent + draftContent,
				"published": publishedContent,
				"draft":     draftContent,
			},
			"media": fiber.Map{
				"total":      mediaCount,
				"total_size": totalMediaSize,
			},
			"timestamp": time.Now().Unix(),
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

	// Media routes (protected - requires authentication)
	mediaRoutes := protected.Group("/media")
	mediaRoutes.Post("/upload", mediaHandler.UploadMedia)         // Upload file
	mediaRoutes.Get("/", mediaHandler.ListMedia)                  // List media (with filters)
	mediaRoutes.Get("/:id", mediaHandler.GetMedia)                // Get media by ID
	mediaRoutes.Delete("/:id", mediaHandler.DeleteMedia)          // Delete media

	// Stock routes (protected - requires authentication)
	stockRoutes := protected.Group("/stock")

	// List stock items
	stockRoutes.Get("/", func(c *fiber.Ctx) error {
		tenant, err := middleware.GetTenantFromContext(c)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Tenant not found",
			})
		}

		ctx := c.UserContext()
		query := fmt.Sprintf(`
			SELECT id, product_name, species, quantity, unit, location, temperature, status, created_at, updated_at
			FROM %s.stock
			ORDER BY created_at DESC
		`, tenant.SchemaName)

		rows, err := pool.Pool.Query(ctx, query)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "Failed to fetch stock items",
			})
		}
		defer rows.Close()

		var items []map[string]interface{}
		for rows.Next() {
			var item map[string]interface{} = make(map[string]interface{})
			var id, productName, species, unit, location, status string
			var quantity, temperature *float64
			var createdAt, updatedAt time.Time

			err := rows.Scan(&id, &productName, &species, &quantity, &unit, &location, &temperature, &status, &createdAt, &updatedAt)
			if err != nil {
				continue
			}

			item["id"] = id
			item["product_name"] = productName
			item["species"] = species
			item["quantity"] = quantity
			item["unit"] = unit
			item["location"] = location
			item["temperature"] = temperature
			item["status"] = status
			item["created_at"] = createdAt
			item["updated_at"] = updatedAt

			items = append(items, item)
		}

		return c.JSON(fiber.Map{
			"items": items,
			"total": len(items),
		})
	})

	// Create stock item
	stockRoutes.Post("/", func(c *fiber.Ctx) error {
		tenant, err := middleware.GetTenantFromContext(c)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Tenant not found",
			})
		}

		var input struct {
			ProductName string   `json:"product_name"`
			Species     string   `json:"species"`
			Quantity    float64  `json:"quantity"`
			Unit        string   `json:"unit"`
			Location    string   `json:"location"`
			Temperature *float64 `json:"temperature"`
			Status      string   `json:"status"`
		}

		if err := c.BodyParser(&input); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Invalid input",
			})
		}

		ctx := c.UserContext()
		query := fmt.Sprintf(`
			INSERT INTO %s.stock (product_name, species, quantity, unit, location, temperature, status)
			VALUES ($1, $2, $3, $4, $5, $6, $7)
			RETURNING id, product_name, species, quantity, unit, location, temperature, status, created_at, updated_at
		`, tenant.SchemaName)

		var id, status string
		var quantity, temperature *float64
		var createdAt, updatedAt time.Time

		err = pool.Pool.QueryRow(ctx, query,
			input.ProductName, input.Species, input.Quantity, input.Unit,
			input.Location, input.Temperature, input.Status,
		).Scan(&id, &input.ProductName, &input.Species, &quantity, &input.Unit, &input.Location, &temperature, &status, &createdAt, &updatedAt)

		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "Failed to create stock item",
			})
		}

		return c.Status(fiber.StatusCreated).JSON(fiber.Map{
			"id":           id,
			"product_name": input.ProductName,
			"species":      input.Species,
			"quantity":     quantity,
			"unit":         input.Unit,
			"location":     input.Location,
			"temperature":  temperature,
			"status":       status,
			"created_at":   createdAt,
			"updated_at":   updatedAt,
		})
	})

	// Update stock item
	stockRoutes.Put("/:id", func(c *fiber.Ctx) error {
		tenant, err := middleware.GetTenantFromContext(c)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Tenant not found",
			})
		}

		id := c.Params("id")

		var input struct {
			ProductName string   `json:"product_name"`
			Species     string   `json:"species"`
			Quantity    float64  `json:"quantity"`
			Unit        string   `json:"unit"`
			Location    string   `json:"location"`
			Temperature *float64 `json:"temperature"`
			Status      string   `json:"status"`
		}

		if err := c.BodyParser(&input); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Invalid input",
			})
		}

		ctx := c.UserContext()
		query := fmt.Sprintf(`
			UPDATE %s.stock
			SET product_name = $1, species = $2, quantity = $3, unit = $4,
			    location = $5, temperature = $6, status = $7, updated_at = CURRENT_TIMESTAMP
			WHERE id = $8
			RETURNING id, product_name, species, quantity, unit, location, temperature, status, created_at, updated_at
		`, tenant.SchemaName)

		var status string
		var quantity, temperature *float64
		var createdAt, updatedAt time.Time

		err = pool.Pool.QueryRow(ctx, query,
			input.ProductName, input.Species, input.Quantity, input.Unit,
			input.Location, input.Temperature, input.Status, id,
		).Scan(&id, &input.ProductName, &input.Species, &quantity, &input.Unit, &input.Location, &temperature, &status, &createdAt, &updatedAt)

		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "Failed to update stock item",
			})
		}

		return c.JSON(fiber.Map{
			"id":           id,
			"product_name": input.ProductName,
			"species":      input.Species,
			"quantity":     quantity,
			"unit":         input.Unit,
			"location":     input.Location,
			"temperature":  temperature,
			"status":       status,
			"created_at":   createdAt,
			"updated_at":   updatedAt,
		})
	})

	// Delete stock item
	stockRoutes.Delete("/:id", func(c *fiber.Ctx) error {
		tenant, err := middleware.GetTenantFromContext(c)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Tenant not found",
			})
		}

		id := c.Params("id")
		ctx := c.UserContext()

		query := fmt.Sprintf(`DELETE FROM %s.stock WHERE id = $1`, tenant.SchemaName)
		_, err = pool.Pool.Exec(ctx, query, id)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "Failed to delete stock item",
			})
		}

		return c.JSON(fiber.Map{
			"message": "Stock item deleted successfully",
		})
	})

	// Cold Chain routes (protected - requires authentication)
	coldChainRoutes := protected.Group("/cold-chain")

	coldChainRoutes.Get("/", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		ctx := c.UserContext()
		query := fmt.Sprintf(`SELECT id, product_name, batch_id, location, temperature, humidity, status, created_at FROM %s.cold_chain ORDER BY created_at DESC`, tenant.SchemaName)
		rows, _ := pool.Pool.Query(ctx, query)
		defer rows.Close()

		var items []map[string]interface{}
		for rows.Next() {
			var id, productName, batchId, location, status string
			var temperature, humidity *float64
			var createdAt time.Time
			rows.Scan(&id, &productName, &batchId, &location, &temperature, &humidity, &status, &createdAt)
			items = append(items, map[string]interface{}{
				"id": id, "product_name": productName, "batch_id": batchId, "location": location,
				"temperature": temperature, "humidity": humidity, "status": status, "created_at": createdAt,
			})
		}
		return c.JSON(fiber.Map{"items": items})
	})

	coldChainRoutes.Post("/", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		var input struct {
			ProductName string   `json:"product_name"`
			BatchId     string   `json:"batch_id"`
			Location    string   `json:"location"`
			Temperature float64  `json:"temperature"`
			Humidity    *float64 `json:"humidity"`
			Status      string   `json:"status"`
		}
		c.BodyParser(&input)
		ctx := c.UserContext()
		query := fmt.Sprintf(`INSERT INTO %s.cold_chain (product_name, batch_id, location, temperature, humidity, status) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`, tenant.SchemaName)
		var id string
		pool.Pool.QueryRow(ctx, query, input.ProductName, input.BatchId, input.Location, input.Temperature, input.Humidity, input.Status).Scan(&id)
		return c.Status(fiber.StatusCreated).JSON(fiber.Map{"id": id})
	})

	coldChainRoutes.Put("/:id", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		id := c.Params("id")
		var input struct {
			ProductName string   `json:"product_name"`
			BatchId     string   `json:"batch_id"`
			Location    string   `json:"location"`
			Temperature float64  `json:"temperature"`
			Humidity    *float64 `json:"humidity"`
			Status      string   `json:"status"`
		}
		c.BodyParser(&input)
		ctx := c.UserContext()
		query := fmt.Sprintf(`UPDATE %s.cold_chain SET product_name=$1, batch_id=$2, location=$3, temperature=$4, humidity=$5, status=$6 WHERE id=$7`, tenant.SchemaName)
		pool.Pool.Exec(ctx, query, input.ProductName, input.BatchId, input.Location, input.Temperature, input.Humidity, input.Status, id)
		return c.JSON(fiber.Map{"message": "Updated"})
	})

	coldChainRoutes.Delete("/:id", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		pool.Pool.Exec(c.UserContext(), fmt.Sprintf(`DELETE FROM %s.cold_chain WHERE id = $1`, tenant.SchemaName), c.Params("id"))
		return c.JSON(fiber.Map{"message": "Deleted"})
	})

	// Shipments routes
	shipmentsRoutes := protected.Group("/shipments")

	shipmentsRoutes.Get("/", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		rows, _ := pool.Pool.Query(c.UserContext(), fmt.Sprintf(`SELECT id, tracking_number, customer, destination, departure_date, estimated_arrival, status, carrier, weight, temperature FROM %s.shipments ORDER BY created_at DESC`, tenant.SchemaName))
		defer rows.Close()
		var items []map[string]interface{}
		for rows.Next() {
			var id, trackingNumber, customer, destination, status, carrier string
			var weight, temperature *float64
			var departureDate, estimatedArrival time.Time
			rows.Scan(&id, &trackingNumber, &customer, &destination, &departureDate, &estimatedArrival, &status, &carrier, &weight, &temperature)
			items = append(items, map[string]interface{}{
				"id": id, "tracking_number": trackingNumber, "customer": customer, "destination": destination,
				"departure_date": departureDate, "estimated_arrival": estimatedArrival, "status": status,
				"carrier": carrier, "weight": weight, "temperature": temperature,
			})
		}
		return c.JSON(fiber.Map{"items": items})
	})

	shipmentsRoutes.Post("/", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		var input map[string]interface{}
		c.BodyParser(&input)
		var id string
		pool.Pool.QueryRow(c.UserContext(), fmt.Sprintf(`INSERT INTO %s.shipments (tracking_number, customer, destination, departure_date, estimated_arrival, status, carrier, weight, temperature) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id`, tenant.SchemaName),
			input["tracking_number"], input["customer"], input["destination"], input["departure_date"], input["estimated_arrival"], input["status"], input["carrier"], input["weight"], input["temperature"]).Scan(&id)
		return c.Status(fiber.StatusCreated).JSON(fiber.Map{"id": id})
	})

	shipmentsRoutes.Put("/:id", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		var input map[string]interface{}
		c.BodyParser(&input)
		pool.Pool.Exec(c.UserContext(), fmt.Sprintf(`UPDATE %s.shipments SET tracking_number=$1, customer=$2, destination=$3, departure_date=$4, estimated_arrival=$5, status=$6, carrier=$7, weight=$8, temperature=$9 WHERE id=$10`, tenant.SchemaName),
			input["tracking_number"], input["customer"], input["destination"], input["departure_date"], input["estimated_arrival"], input["status"], input["carrier"], input["weight"], input["temperature"], c.Params("id"))
		return c.JSON(fiber.Map{"message": "Updated"})
	})

	shipmentsRoutes.Delete("/:id", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		pool.Pool.Exec(c.UserContext(), fmt.Sprintf(`DELETE FROM %s.shipments WHERE id = $1`, tenant.SchemaName), c.Params("id"))
		return c.JSON(fiber.Map{"message": "Deleted"})
	})

	// Documents routes
	documentsRoutes := protected.Group("/documents")

	documentsRoutes.Get("/", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		rows, _ := pool.Pool.Query(c.UserContext(), fmt.Sprintf(`SELECT id, document_type, document_number, shipment_id, customer, issue_date, expiry_date, status, issuer FROM %s.documents ORDER BY created_at DESC`, tenant.SchemaName))
		defer rows.Close()
		var items []map[string]interface{}
		for rows.Next() {
			var id, docType, docNumber, shipmentId, customer, status, issuer string
			var issueDate, expiryDate time.Time
			rows.Scan(&id, &docType, &docNumber, &shipmentId, &customer, &issueDate, &expiryDate, &status, &issuer)
			items = append(items, map[string]interface{}{
				"id": id, "document_type": docType, "document_number": docNumber, "shipment_id": shipmentId,
				"customer": customer, "issue_date": issueDate, "expiry_date": expiryDate, "status": status, "issuer": issuer,
			})
		}
		return c.JSON(fiber.Map{"items": items})
	})

	documentsRoutes.Post("/", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		var input map[string]interface{}
		c.BodyParser(&input)
		var id string
		pool.Pool.QueryRow(c.UserContext(), fmt.Sprintf(`INSERT INTO %s.documents (document_type, document_number, shipment_id, customer, issue_date, expiry_date, status, issuer) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id`, tenant.SchemaName),
			input["document_type"], input["document_number"], input["shipment_id"], input["customer"], input["issue_date"], input["expiry_date"], input["status"], input["issuer"]).Scan(&id)
		return c.Status(fiber.StatusCreated).JSON(fiber.Map{"id": id})
	})

	documentsRoutes.Put("/:id", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		var input map[string]interface{}
		c.BodyParser(&input)
		pool.Pool.Exec(c.UserContext(), fmt.Sprintf(`UPDATE %s.documents SET document_type=$1, document_number=$2, shipment_id=$3, customer=$4, issue_date=$5, expiry_date=$6, status=$7, issuer=$8 WHERE id=$9`, tenant.SchemaName),
			input["document_type"], input["document_number"], input["shipment_id"], input["customer"], input["issue_date"], input["expiry_date"], input["status"], input["issuer"], c.Params("id"))
		return c.JSON(fiber.Map{"message": "Updated"})
	})

	documentsRoutes.Delete("/:id", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		pool.Pool.Exec(c.UserContext(), fmt.Sprintf(`DELETE FROM %s.documents WHERE id = $1`, tenant.SchemaName), c.Params("id"))
		return c.JSON(fiber.Map{"message": "Deleted"})
	})

	// Certificates routes
	certificatesRoutes := protected.Group("/certificates")

	certificatesRoutes.Get("/", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		rows, _ := pool.Pool.Query(c.UserContext(), fmt.Sprintf(`SELECT id, certificate_type, certificate_number, standard, issue_date, expiry_date, status, issuer, scope FROM %s.certificates ORDER BY created_at DESC`, tenant.SchemaName))
		defer rows.Close()
		var items []map[string]interface{}
		for rows.Next() {
			var id, certType, certNumber, standard, status, issuer, scope string
			var issueDate, expiryDate time.Time
			rows.Scan(&id, &certType, &certNumber, &standard, &issueDate, &expiryDate, &status, &issuer, &scope)
			items = append(items, map[string]interface{}{
				"id": id, "certificate_type": certType, "certificate_number": certNumber, "standard": standard,
				"issue_date": issueDate, "expiry_date": expiryDate, "status": status, "issuer": issuer, "scope": scope,
			})
		}
		return c.JSON(fiber.Map{"items": items})
	})

	certificatesRoutes.Post("/", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		var input map[string]interface{}
		c.BodyParser(&input)
		var id string
		pool.Pool.QueryRow(c.UserContext(), fmt.Sprintf(`INSERT INTO %s.certificates (certificate_type, certificate_number, standard, issue_date, expiry_date, status, issuer, scope) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id`, tenant.SchemaName),
			input["certificate_type"], input["certificate_number"], input["standard"], input["issue_date"], input["expiry_date"], input["status"], input["issuer"], input["scope"]).Scan(&id)
		return c.Status(fiber.StatusCreated).JSON(fiber.Map{"id": id})
	})

	certificatesRoutes.Put("/:id", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		var input map[string]interface{}
		c.BodyParser(&input)
		pool.Pool.Exec(c.UserContext(), fmt.Sprintf(`UPDATE %s.certificates SET certificate_type=$1, certificate_number=$2, standard=$3, issue_date=$4, expiry_date=$5, status=$6, issuer=$7, scope=$8 WHERE id=$9`, tenant.SchemaName),
			input["certificate_type"], input["certificate_number"], input["standard"], input["issue_date"], input["expiry_date"], input["status"], input["issuer"], input["scope"], c.Params("id"))
		return c.JSON(fiber.Map{"message": "Updated"})
	})

	certificatesRoutes.Delete("/:id", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		pool.Pool.Exec(c.UserContext(), fmt.Sprintf(`DELETE FROM %s.certificates WHERE id = $1`, tenant.SchemaName), c.Params("id"))
		return c.JSON(fiber.Map{"message": "Deleted"})
	})

	// Reports routes
	reportsRoutes := protected.Group("/reports")

	reportsRoutes.Get("/", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		rows, _ := pool.Pool.Query(c.UserContext(), fmt.Sprintf(`SELECT id, name, description, category, format, file_path, file_size, created_at FROM %s.reports ORDER BY created_at DESC`, tenant.SchemaName))
		defer rows.Close()
		var items []map[string]interface{}
		for rows.Next() {
			var id, name, description, category, format, filePath string
			var fileSize *int64
			var createdAt time.Time
			rows.Scan(&id, &name, &description, &category, &format, &filePath, &fileSize, &createdAt)
			items = append(items, map[string]interface{}{
				"id": id, "name": name, "description": description, "category": category,
				"format": format, "file_path": filePath, "file_size": fileSize, "created_at": createdAt,
			})
		}
		return c.JSON(fiber.Map{"items": items})
	})

	reportsRoutes.Post("/", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		var input map[string]interface{}
		c.BodyParser(&input)
		var id string
		pool.Pool.QueryRow(c.UserContext(), fmt.Sprintf(`INSERT INTO %s.reports (name, description, category, format) VALUES ($1, $2, $3, $4) RETURNING id`, tenant.SchemaName),
			input["name"], input["description"], input["category"], input["format"]).Scan(&id)
		return c.Status(fiber.StatusCreated).JSON(fiber.Map{"id": id})
	})

	reportsRoutes.Delete("/:id", func(c *fiber.Ctx) error {
		tenant, _ := middleware.GetTenantFromContext(c)
		pool.Pool.Exec(c.UserContext(), fmt.Sprintf(`DELETE FROM %s.reports WHERE id = $1`, tenant.SchemaName), c.Params("id"))
		return c.JSON(fiber.Map{"message": "Deleted"})
	})

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

// getEnv retrieves environment variable or returns default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
