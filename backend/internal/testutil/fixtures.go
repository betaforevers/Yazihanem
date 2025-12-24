package testutil

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

// TestUser represents a test user fixture
type TestUser struct {
	ID           uuid.UUID
	TenantID     uuid.UUID
	Email        string
	Password     string
	PasswordHash string
	FirstName    string
	LastName     string
	Role         string
	IsActive     bool
}

// TestContent represents a test content fixture
type TestContent struct {
	ID       uuid.UUID
	TenantID uuid.UUID
	Title    string
	Slug     string
	Body     string
	Status   string
	AuthorID uuid.UUID
}

// CreateTestUser inserts a test user into the specified schema
func CreateTestUser(t *testing.T, ctx context.Context, pool *pgxpool.Pool, schemaName string, user TestUser) TestUser {
	if user.ID == uuid.Nil {
		user.ID = uuid.New()
	}
	if user.TenantID == uuid.Nil {
		user.TenantID = uuid.New()
	}
	if user.Password == "" {
		user.Password = "testpassword123"
	}
	if user.PasswordHash == "" {
		hash, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
		if err != nil {
			t.Fatalf("Failed to hash password: %v", err)
		}
		user.PasswordHash = string(hash)
	}
	if user.Role == "" {
		user.Role = "viewer"
	}

	_, err := pool.Exec(ctx, `
		SET search_path TO `+schemaName+`, public;
		INSERT INTO users (id, tenant_id, email, password_hash, first_name, last_name, role, is_active)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`, user.ID, user.TenantID, user.Email, user.PasswordHash, user.FirstName, user.LastName, user.Role, user.IsActive)

	if err != nil {
		t.Fatalf("Failed to create test user: %v", err)
	}

	return user
}

// CreateTestContent inserts test content into the specified schema
func CreateTestContent(t *testing.T, ctx context.Context, pool *pgxpool.Pool, schemaName string, content TestContent) TestContent {
	if content.ID == uuid.Nil {
		content.ID = uuid.New()
	}
	if content.TenantID == uuid.Nil {
		content.TenantID = uuid.New()
	}
	if content.Status == "" {
		content.Status = "draft"
	}

	_, err := pool.Exec(ctx, `
		SET search_path TO `+schemaName+`, public;
		INSERT INTO content (id, tenant_id, title, slug, body, status, author_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`, content.ID, content.TenantID, content.Title, content.Slug, content.Body, content.Status, content.AuthorID)

	if err != nil {
		t.Fatalf("Failed to create test content: %v", err)
	}

	return content
}

// DefaultTestUser returns a user fixture with default values
func DefaultTestUser() TestUser {
	return TestUser{
		Email:     "test@example.com",
		FirstName: "Test",
		LastName:  "User",
		IsActive:  true,
	}
}

// AdminTestUser returns an admin user fixture
func AdminTestUser() TestUser {
	user := DefaultTestUser()
	user.Email = "admin@example.com"
	user.Role = "admin"
	return user
}
