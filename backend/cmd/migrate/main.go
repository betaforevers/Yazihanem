package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mehmetkilic/yazihanem/config"
	"github.com/mehmetkilic/yazihanem/pkg/migration"
)

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	command := os.Args[1]

	// Load configuration
	cfg := config.Load()

	// Create database connection
	ctx := context.Background()
	connString := fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		cfg.Database.User,
		cfg.Database.Password,
		cfg.Database.Host,
		cfg.Database.Port,
		cfg.Database.Database,
		cfg.Database.SSLMode,
	)

	pool, err := pgxpool.New(ctx, connString)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer pool.Close()

	// Create migrator
	migrator := migration.NewMigrator(pool)

	// Execute command
	switch command {
	case "up":
		if err := migrator.MigratePublicSchema(ctx); err != nil {
			log.Fatalf("Migration failed: %v", err)
		}
		fmt.Println("✓ Public schema migrations completed successfully")

	case "create-tenant":
		if len(os.Args) < 3 {
			fmt.Println("Error: schema name required")
			fmt.Println("Usage: migrate create-tenant <schema_name>")
			os.Exit(1)
		}
		schemaName := os.Args[2]
		if err := migrator.CreateTenantSchema(ctx, schemaName); err != nil {
			log.Fatalf("Failed to create tenant schema: %v", err)
		}
		fmt.Printf("✓ Tenant schema '%s' created successfully\n", schemaName)

	case "drop-tenant":
		if len(os.Args) < 3 {
			fmt.Println("Error: schema name required")
			fmt.Println("Usage: migrate drop-tenant <schema_name>")
			os.Exit(1)
		}
		schemaName := os.Args[2]
		if err := migrator.DropTenantSchema(ctx, schemaName); err != nil {
			log.Fatalf("Failed to drop tenant schema: %v", err)
		}
		fmt.Printf("✓ Tenant schema '%s' dropped successfully\n", schemaName)

	case "help", "--help", "-h":
		printUsage()

	default:
		fmt.Printf("Unknown command: %s\n\n", command)
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println("Yazıhanem Migration Tool")
	fmt.Println("\nUsage:")
	fmt.Println("  migrate <command> [arguments]")
	fmt.Println("\nCommands:")
	fmt.Println("  up                          Run pending public schema migrations")
	fmt.Println("  create-tenant <schema_name> Create a new tenant schema")
	fmt.Println("  drop-tenant <schema_name>   Drop an existing tenant schema")
	fmt.Println("  help                        Show this help message")
	fmt.Println("\nExamples:")
	fmt.Println("  migrate up")
	fmt.Println("  migrate create-tenant tenant_acme")
	fmt.Println("  migrate drop-tenant tenant_acme")
}
