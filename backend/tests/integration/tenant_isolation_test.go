package integration

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"yazihanem/backend/internal/testutil"
	"yazihanem/backend/pkg/dbutil"
)

// TestTenantIsolation_CannotAccessOtherTenantData verifies strict tenant isolation
// CRITICAL: This test validates the core security boundary of the multi-tenant system
func TestTenantIsolation_CannotAccessOtherTenantData(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	infra := testutil.SetupTestInfrastructure(t)
	defer infra.Teardown(t)

	ctx := context.Background()

	// Create public schema
	infra.CreatePublicSchema(t)

	// Create two tenant schemas
	infra.CreateTestTenant(t, "tenant_acme")
	infra.CreateTestTenant(t, "tenant_widgets")
	defer infra.CleanupTenantSchema(t, "tenant_acme")
	defer infra.CleanupTenantSchema(t, "tenant_widgets")

	tenantAcmeID := uuid.New()
	tenantWidgetsID := uuid.New()

	// Insert user in tenant_acme
	userAlice := testutil.CreateTestUser(t, ctx, infra.DBPool, "tenant_acme", testutil.TestUser{
		TenantID:  tenantAcmeID,
		Email:     "alice@acme.com",
		FirstName: "Alice",
		LastName:  "Admin",
		Role:      "admin",
		IsActive:  true,
	})

	// Insert user in tenant_widgets
	userBob := testutil.CreateTestUser(t, ctx, infra.DBPool, "tenant_widgets", testutil.TestUser{
		TenantID:  tenantWidgetsID,
		Email:     "bob@widgets.com",
		FirstName: "Bob",
		LastName:  "User",
		Role:      "viewer",
		IsActive:  true,
	})

	// CRITICAL TEST: Switch to tenant_acme and verify we CANNOT see tenant_widgets data
	tconn, err := dbutil.AcquireTenantConn(ctx, infra.DBPool, "tenant_acme")
	require.NoError(t, err, "Failed to acquire tenant connection")
	defer tconn.Release()

	var count int
	err = tconn.Conn().QueryRow(ctx, "SELECT COUNT(*) FROM users").Scan(&count)
	require.NoError(t, err, "Failed to query users table")

	// MUST see only 1 user (Alice from tenant_acme)
	assert.Equal(t, 1, count, "Tenant isolation violated! Expected 1 user from tenant_acme, got %d", count)

	// Verify we see the correct user
	var email string
	err = tconn.Conn().QueryRow(ctx, "SELECT email FROM users WHERE id = $1", userAlice.ID).Scan(&email)
	require.NoError(t, err, "Failed to query user email")
	assert.Equal(t, "alice@acme.com", email, "Expected alice@acme.com, got %s", email)

	// Verify we CANNOT see Bob's email
	var bobEmail string
	err = tconn.Conn().QueryRow(ctx, "SELECT email FROM users WHERE id = $1", userBob.ID).Scan(&bobEmail)
	assert.Error(t, err, "Should NOT be able to query user from another tenant")
}

// TestTenantIsolation_ContentSeparation verifies content isolation between tenants
func TestTenantIsolation_ContentSeparation(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	infra := testutil.SetupTestInfrastructure(t)
	defer infra.Teardown(t)

	ctx := context.Background()

	infra.CreatePublicSchema(t)
	infra.CreateTestTenant(t, "tenant_alpha")
	infra.CreateTestTenant(t, "tenant_beta")
	defer infra.CleanupTenantSchema(t, "tenant_alpha")
	defer infra.CleanupTenantSchema(t, "tenant_beta")

	tenantAlphaID := uuid.New()
	tenantBetaID := uuid.New()

	// Create users for each tenant
	userAlpha := testutil.CreateTestUser(t, ctx, infra.DBPool, "tenant_alpha", testutil.TestUser{
		TenantID:  tenantAlphaID,
		Email:     "user@alpha.com",
		FirstName: "Alpha",
		LastName:  "User",
		Role:      "editor",
		IsActive:  true,
	})

	userBeta := testutil.CreateTestUser(t, ctx, infra.DBPool, "tenant_beta", testutil.TestUser{
		TenantID:  tenantBetaID,
		Email:     "user@beta.com",
		FirstName: "Beta",
		LastName:  "User",
		Role:      "editor",
		IsActive:  true,
	})

	// Create content in tenant_alpha
	contentAlpha := testutil.CreateTestContent(t, ctx, infra.DBPool, "tenant_alpha", testutil.TestContent{
		TenantID: tenantAlphaID,
		Title:    "Alpha Secret Content",
		Slug:     "alpha-secret",
		Body:     "This is confidential Alpha data",
		Status:   "published",
		AuthorID: userAlpha.ID,
	})

	// Create content in tenant_beta
	contentBeta := testutil.CreateTestContent(t, ctx, infra.DBPool, "tenant_beta", testutil.TestContent{
		TenantID: tenantBetaID,
		Title:    "Beta Secret Content",
		Slug:     "beta-secret",
		Body:     "This is confidential Beta data",
		Status:   "published",
		AuthorID: userBeta.ID,
	})

	// Connect as tenant_alpha
	tconnAlpha, err := dbutil.AcquireTenantConn(ctx, infra.DBPool, "tenant_alpha")
	require.NoError(t, err)
	defer tconnAlpha.Release()

	// Verify tenant_alpha can only see their content
	var alphaContentCount int
	err = tconnAlpha.Conn().QueryRow(ctx, "SELECT COUNT(*) FROM content").Scan(&alphaContentCount)
	require.NoError(t, err)
	assert.Equal(t, 1, alphaContentCount, "Tenant Alpha should see exactly 1 content item")

	// Verify tenant_alpha CANNOT see tenant_beta's content by ID
	var betaContentTitle string
	err = tconnAlpha.Conn().QueryRow(ctx, "SELECT title FROM content WHERE id = $1", contentBeta.ID).Scan(&betaContentTitle)
	assert.Error(t, err, "Tenant Alpha should NOT see Tenant Beta's content")

	// Verify tenant_alpha sees correct content
	var alphaTitle string
	err = tconnAlpha.Conn().QueryRow(ctx, "SELECT title FROM content WHERE id = $1", contentAlpha.ID).Scan(&alphaTitle)
	require.NoError(t, err)
	assert.Equal(t, "Alpha Secret Content", alphaTitle)
}

// TestTenantIsolation_MaliciousSchemaInjection tests SQL injection attempts
func TestTenantIsolation_MaliciousSchemaInjection(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	infra := testutil.SetupTestInfrastructure(t)
	defer infra.Teardown(t)

	ctx := context.Background()

	// Try to inject malicious schema names
	maliciousSchemas := []string{
		"tenant_acme; DROP SCHEMA tenant_widgets CASCADE; --",
		"tenant_acme' OR '1'='1",
		"../../../etc/passwd",
		"public; DROP TABLE users; --",
		"'; DELETE FROM users WHERE '1'='1",
		"tenant_acme\"; DROP TABLE content; --",
	}

	for _, schemaName := range maliciousSchemas {
		t.Run("reject_"+schemaName, func(t *testing.T) {
			_, err := dbutil.AcquireTenantConn(ctx, infra.DBPool, schemaName)
			assert.Error(t, err, "Should reject malicious schema name: %s", schemaName)
			assert.Contains(t, err.Error(), "invalid schema name", "Error should mention invalid schema name")
		})
	}
}

// TestTenantIsolation_ConcurrentAccess verifies isolation under concurrent access
func TestTenantIsolation_ConcurrentAccess(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	infra := testutil.SetupTestInfrastructure(t)
	defer infra.Teardown(t)

	ctx := context.Background()

	infra.CreatePublicSchema(t)
	infra.CreateTestTenant(t, "tenant_concurrent1")
	infra.CreateTestTenant(t, "tenant_concurrent2")
	defer infra.CleanupTenantSchema(t, "tenant_concurrent1")
	defer infra.CleanupTenantSchema(t, "tenant_concurrent2")

	// Run concurrent queries to both tenants
	done := make(chan bool, 2)

	go func() {
		for i := 0; i < 10; i++ {
			tconn, err := dbutil.AcquireTenantConn(ctx, infra.DBPool, "tenant_concurrent1")
			if err != nil {
				t.Errorf("Failed to acquire connection: %v", err)
				done <- false
				return
			}

			var schemaName string
			err = tconn.Conn().QueryRow(ctx, "SELECT current_schema()").Scan(&schemaName)
			if err != nil {
				t.Errorf("Failed to query schema: %v", err)
			}
			assert.Equal(t, "tenant_concurrent1", schemaName)

			tconn.Release()
		}
		done <- true
	}()

	go func() {
		for i := 0; i < 10; i++ {
			tconn, err := dbutil.AcquireTenantConn(ctx, infra.DBPool, "tenant_concurrent2")
			if err != nil {
				t.Errorf("Failed to acquire connection: %v", err)
				done <- false
				return
			}

			var schemaName string
			err = tconn.Conn().QueryRow(ctx, "SELECT current_schema()").Scan(&schemaName)
			if err != nil {
				t.Errorf("Failed to query schema: %v", err)
			}
			assert.Equal(t, "tenant_concurrent2", schemaName)

			tconn.Release()
		}
		done <- true
	}()

	// Wait for both goroutines
	<-done
	<-done
}
