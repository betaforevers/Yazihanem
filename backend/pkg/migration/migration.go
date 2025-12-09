package migration

import (
	"context"
	"database/sql"
	"embed"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

//go:embed schema/*.sql
var migrationFiles embed.FS

// Migrator handles database migrations
type Migrator struct {
	db *pgxpool.Pool
}

// NewMigrator creates a new migrator instance
func NewMigrator(db *pgxpool.Pool) *Migrator {
	return &Migrator{db: db}
}

// MigratePublicSchema runs migrations for the public schema (tenants table)
func (m *Migrator) MigratePublicSchema(ctx context.Context) error {
	// Create schema_migrations table if not exists
	_, err := m.db.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS public.schema_migrations (
			version INTEGER PRIMARY KEY,
			applied_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		return fmt.Errorf("failed to create schema_migrations table: %w", err)
	}

	// Get current version
	var currentVersion int
	err = m.db.QueryRow(ctx, `
		SELECT COALESCE(MAX(version), 0) FROM public.schema_migrations
	`).Scan(&currentVersion)
	if err != nil {
		return fmt.Errorf("failed to get current version: %w", err)
	}

	// Read migration files from embedded FS
	entries, err := migrationFiles.ReadDir("schema")
	if err != nil {
		return fmt.Errorf("failed to read migration directory: %w", err)
	}

	// Execute pending migrations
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		filename := entry.Name()
		if !strings.HasSuffix(filename, ".up.sql") {
			continue
		}

		// Extract version from filename (e.g., "000001_create_tenants_table.up.sql" -> 1)
		var version int
		_, err := fmt.Sscanf(filename, "%d_", &version)
		if err != nil {
			continue
		}

		// Skip if already applied
		if version <= currentVersion {
			continue
		}

		// Skip tenant schema template (handled separately)
		if strings.Contains(filename, "tenant_schema_template") {
			continue
		}

		// Read migration content
		content, err := migrationFiles.ReadFile(filepath.Join("schema", filename))
		if err != nil {
			return fmt.Errorf("failed to read migration file %s: %w", filename, err)
		}

		// Execute migration
		fmt.Printf("Applying migration %d: %s\n", version, filename)
		_, err = m.db.Exec(ctx, string(content))
		if err != nil {
			return fmt.Errorf("failed to execute migration %s: %w", filename, err)
		}

		// Record migration
		_, err = m.db.Exec(ctx, `
			INSERT INTO public.schema_migrations (version) VALUES ($1)
		`, version)
		if err != nil {
			return fmt.Errorf("failed to record migration %d: %w", version, err)
		}

		fmt.Printf("Migration %d applied successfully\n", version)
	}

	return nil
}

// CreateTenantSchema creates a new tenant schema with all required tables
func (m *Migrator) CreateTenantSchema(ctx context.Context, schemaName string) error {
	// Validate schema name (prevent SQL injection)
	if !isValidSchemaName(schemaName) {
		return fmt.Errorf("invalid schema name: %s", schemaName)
	}

	// Create schema
	_, err := m.db.Exec(ctx, fmt.Sprintf("CREATE SCHEMA IF NOT EXISTS %s", schemaName))
	if err != nil {
		return fmt.Errorf("failed to create schema %s: %w", schemaName, err)
	}

	// Read tenant schema template
	content, err := migrationFiles.ReadFile("schema/000002_create_tenant_schema_template.up.sql")
	if err != nil {
		return fmt.Errorf("failed to read tenant schema template: %w", err)
	}

	// Replace placeholder with actual schema name
	sqlContent := strings.ReplaceAll(string(content), "{TENANT_SCHEMA}", schemaName)

	// Execute tenant schema migration
	fmt.Printf("Creating tenant schema: %s\n", schemaName)
	_, err = m.db.Exec(ctx, sqlContent)
	if err != nil {
		return fmt.Errorf("failed to create tenant schema %s: %w", schemaName, err)
	}

	fmt.Printf("Tenant schema %s created successfully\n", schemaName)
	return nil
}

// DropTenantSchema drops a tenant schema and all its contents
func (m *Migrator) DropTenantSchema(ctx context.Context, schemaName string) error {
	// Validate schema name
	if !isValidSchemaName(schemaName) {
		return fmt.Errorf("invalid schema name: %s", schemaName)
	}

	// Prevent dropping public schema
	if schemaName == "public" {
		return fmt.Errorf("cannot drop public schema")
	}

	// Drop schema cascade
	_, err := m.db.Exec(ctx, fmt.Sprintf("DROP SCHEMA IF EXISTS %s CASCADE", schemaName))
	if err != nil {
		return fmt.Errorf("failed to drop schema %s: %w", schemaName, err)
	}

	fmt.Printf("Tenant schema %s dropped successfully\n", schemaName)
	return nil
}

// isValidSchemaName validates schema name to prevent SQL injection
func isValidSchemaName(name string) bool {
	// Schema name must start with 'tenant_' and contain only lowercase letters, numbers, and underscores
	if !strings.HasPrefix(name, "tenant_") {
		return false
	}

	for _, char := range name {
		if !((char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') || char == '_') {
			return false
		}
	}

	return len(name) <= 63 // PostgreSQL identifier max length
}

// MigrateFromFile runs a migration from a file (for development/testing)
func MigrateFromFile(ctx context.Context, db *pgxpool.Pool, filePath string) error {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to read file %s: %w", filePath, err)
	}

	_, err = db.Exec(ctx, string(content))
	if err != nil {
		return fmt.Errorf("failed to execute migration: %w", err)
	}

	return nil
}
