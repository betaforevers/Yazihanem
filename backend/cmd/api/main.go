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
	"github.com/mehmetkilic/yazihanem/internal/delivery/http/middleware"
	"github.com/mehmetkilic/yazihanem/internal/infrastructure/database"
	dbpkg "github.com/mehmetkilic/yazihanem/pkg/database"
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

	// Initialize repositories
	tenantRepo := database.NewTenantRepository(pool.Pool)

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
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowMethods: "GET,POST,PUT,DELETE,PATCH,OPTIONS",
		AllowHeaders: "Origin,Content-Type,Accept,Authorization",
	}))

	// Health check endpoint (no tenant required)
	app.Get("/health", func(c *fiber.Ctx) error {
		// Check database health
		dbErr := pool.HealthCheck(ctx)
		dbHealthy := dbErr == nil

		stats := pool.Stats()

		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "yazihanem-api",
			"database": fiber.Map{
				"healthy":           dbHealthy,
				"total_connections": stats.TotalConns(),
				"idle_connections":  stats.IdleConns(),
			},
			"timestamp": time.Now().Unix(),
		})
	})

	// Initialize tenant resolver middleware
	tenantResolver := middleware.NewTenantResolver(tenantRepo)

	// API routes group with tenant resolution
	api := app.Group("/api/v1")
	api.Use(tenantResolver.Resolve()) // Apply tenant middleware to all API routes

	// Root API endpoint
	api.Get("/", func(c *fiber.Ctx) error {
		tenant, err := middleware.GetTenantFromContext(c)
		if err != nil {
			return err
		}

		return c.JSON(fiber.Map{
			"message":      "Yazıhanem API v1",
			"tenant":       tenant.Name,
			"tenant_id":    tenant.ID,
			"schema":       tenant.SchemaName,
		})
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
