package testutil

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	goredis "github.com/redis/go-redis/v9"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/modules/redis"
	"github.com/testcontainers/testcontainers-go/wait"
)

// TestInfrastructure manages test containers and connections
type TestInfrastructure struct {
	PostgresContainer *postgres.PostgresContainer
	RedisContainer    *redis.RedisContainer
	DBPool            *pgxpool.Pool
	RedisClient       *goredis.Client
	Ctx               context.Context
}

// SetupTestInfrastructure starts PostgreSQL and Redis containers for testing
func SetupTestInfrastructure(t *testing.T) *TestInfrastructure {
	ctx := context.Background()

	// Start PostgreSQL container
	pgContainer, err := postgres.RunContainer(ctx,
		testcontainers.WithImage("postgres:15-alpine"),
		postgres.WithDatabase("yazihanem_test"),
		postgres.WithUsername("test"),
		postgres.WithPassword("test"),
		testcontainers.WithWaitStrategy(
			wait.ForLog("database system is ready to accept connections").
				WithOccurrence(2).
				WithStartupTimeout(60*time.Second)),
	)
	if err != nil {
		t.Fatalf("Failed to start PostgreSQL container: %v", err)
	}

	// Start Redis container
	redisContainer, err := redis.RunContainer(ctx,
		testcontainers.WithImage("redis:7-alpine"),
		testcontainers.WithWaitStrategy(
			wait.ForLog("Ready to accept connections").
				WithStartupTimeout(30*time.Second)),
	)
	if err != nil {
		pgContainer.Terminate(ctx)
		t.Fatalf("Failed to start Redis container: %v", err)
	}

	// Get PostgreSQL connection string
	pgConnStr, err := pgContainer.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		pgContainer.Terminate(ctx)
		redisContainer.Terminate(ctx)
		t.Fatalf("Failed to get PostgreSQL connection string: %v", err)
	}

	// Create connection pool
	dbPool, err := pgxpool.New(ctx, pgConnStr)
	if err != nil {
		pgContainer.Terminate(ctx)
		redisContainer.Terminate(ctx)
		t.Fatalf("Failed to connect to PostgreSQL: %v", err)
	}

	// Verify connection
	if err := dbPool.Ping(ctx); err != nil {
		dbPool.Close()
		pgContainer.Terminate(ctx)
		redisContainer.Terminate(ctx)
		t.Fatalf("Failed to ping PostgreSQL: %v", err)
	}

	// Get Redis endpoint
	redisEndpoint, err := redisContainer.Endpoint(ctx, "")
	if err != nil {
		dbPool.Close()
		pgContainer.Terminate(ctx)
		redisContainer.Terminate(ctx)
		t.Fatalf("Failed to get Redis endpoint: %v", err)
	}

	// Create Redis client
	redisClient := goredis.NewClient(&goredis.Options{
		Addr: redisEndpoint,
	})

	// Verify Redis connection
	if err := redisClient.Ping(ctx).Err(); err != nil {
		dbPool.Close()
		redisClient.Close()
		pgContainer.Terminate(ctx)
		redisContainer.Terminate(ctx)
		t.Fatalf("Failed to ping Redis: %v", err)
	}

	return &TestInfrastructure{
		PostgresContainer: pgContainer,
		RedisContainer:    redisContainer,
		DBPool:            dbPool,
		RedisClient:       redisClient,
		Ctx:               ctx,
	}
}

// Teardown cleans up all test resources
func (ti *TestInfrastructure) Teardown(t *testing.T) {
	if ti.DBPool != nil {
		ti.DBPool.Close()
	}
	if ti.RedisClient != nil {
		ti.RedisClient.Close()
	}
	if ti.PostgresContainer != nil {
		if err := ti.PostgresContainer.Terminate(ti.Ctx); err != nil {
			t.Logf("Failed to terminate PostgreSQL container: %v", err)
		}
	}
	if ti.RedisContainer != nil {
		if err := ti.RedisContainer.Terminate(ti.Ctx); err != nil {
			t.Logf("Failed to terminate Redis container: %v", err)
		}
	}
}

// CreatePublicSchema creates the public schema tables (tenants, audit_logs)
func (ti *TestInfrastructure) CreatePublicSchema(t *testing.T) {
	// Create tenants table
	_, err := ti.DBPool.Exec(ti.Ctx, `
		CREATE TABLE IF NOT EXISTS public.tenants (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			name VARCHAR(255) NOT NULL,
			domain VARCHAR(255),
			schema_name VARCHAR(63) NOT NULL UNIQUE,
			is_active BOOLEAN DEFAULT true,
			created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
		);
	`)
	if err != nil {
		t.Fatalf("Failed to create public.tenants table: %v", err)
	}

	// Create audit_logs table
	_, err = ti.DBPool.Exec(ti.Ctx, `
		CREATE TABLE IF NOT EXISTS public.audit_logs (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			tenant_id UUID NOT NULL,
			user_id UUID,
			action VARCHAR(100) NOT NULL,
			severity VARCHAR(20) NOT NULL,
			resource_type VARCHAR(50),
			resource_id UUID,
			ip_address INET NOT NULL,
			user_agent TEXT,
			metadata JSONB,
			success BOOLEAN DEFAULT true,
			error TEXT,
			timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
		);
	`)
	if err != nil {
		t.Fatalf("Failed to create public.audit_logs table: %v", err)
	}
}

// CreateTestTenant creates a tenant schema with all required tables
func (ti *TestInfrastructure) CreateTestTenant(t *testing.T, schemaName string) {
	// Create schema
	_, err := ti.DBPool.Exec(ti.Ctx, fmt.Sprintf("CREATE SCHEMA IF NOT EXISTS %s", schemaName))
	if err != nil {
		t.Fatalf("Failed to create schema %s: %v", schemaName, err)
	}

	// Read template SQL
	templateSQL, err := os.ReadFile("../migrations/schema/000002_create_tenant_schema_template.up.sql")
	if err != nil {
		// Fallback: create minimal tables inline
		ti.createMinimalTenantTables(t, schemaName)
		return
	}

	// Execute template SQL with schema prefix
	_, err = ti.DBPool.Exec(ti.Ctx, fmt.Sprintf("SET search_path TO %s, public", schemaName))
	if err != nil {
		t.Fatalf("Failed to set search_path: %v", err)
	}

	_, err = ti.DBPool.Exec(ti.Ctx, string(templateSQL))
	if err != nil {
		// Fallback if template fails
		ti.createMinimalTenantTables(t, schemaName)
	}
}

// createMinimalTenantTables creates essential tables for testing
func (ti *TestInfrastructure) createMinimalTenantTables(t *testing.T, schemaName string) {
	_, err := ti.DBPool.Exec(ti.Ctx, fmt.Sprintf(`
		CREATE TABLE IF NOT EXISTS %s.users (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			tenant_id UUID NOT NULL,
			email VARCHAR(255) NOT NULL UNIQUE,
			password_hash TEXT NOT NULL,
			first_name VARCHAR(100) NOT NULL,
			last_name VARCHAR(100) NOT NULL,
			role VARCHAR(20) NOT NULL,
			is_active BOOLEAN DEFAULT true,
			created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
		);

		CREATE TABLE IF NOT EXISTS %s.content (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			tenant_id UUID NOT NULL,
			title VARCHAR(500) NOT NULL,
			slug VARCHAR(500) NOT NULL UNIQUE,
			body TEXT,
			status VARCHAR(20) DEFAULT 'draft',
			author_id UUID NOT NULL,
			published_at TIMESTAMPTZ,
			created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
		);

		CREATE TABLE IF NOT EXISTS %s.media (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			tenant_id UUID NOT NULL,
			filename VARCHAR(255) NOT NULL,
			original_filename VARCHAR(255) NOT NULL,
			mime_type VARCHAR(100) NOT NULL,
			size_bytes BIGINT NOT NULL,
			storage_path TEXT NOT NULL,
			uploaded_by UUID NOT NULL,
			created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
		);
	`, schemaName, schemaName, schemaName))
	if err != nil {
		t.Fatalf("Failed to create minimal tenant tables: %v", err)
	}
}

// CleanupTenantSchema drops a test tenant schema
func (ti *TestInfrastructure) CleanupTenantSchema(t *testing.T, schemaName string) {
	_, err := ti.DBPool.Exec(ti.Ctx, fmt.Sprintf("DROP SCHEMA IF EXISTS %s CASCADE", schemaName))
	if err != nil {
		t.Logf("Warning: Failed to cleanup schema %s: %v", schemaName, err)
	}
}
