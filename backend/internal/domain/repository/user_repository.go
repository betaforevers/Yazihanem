package repository

import (
	"context"

	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
)

// UserRepository defines operations for user persistence within a tenant schema
type UserRepository interface {
	// Create creates a new user
	Create(ctx context.Context, user *entity.User) error

	// GetByID retrieves a user by ID
	GetByID(ctx context.Context, tenantID, userID string) (*entity.User, error)

	// GetByEmail retrieves a user by email within a tenant
	GetByEmail(ctx context.Context, tenantID, email string) (*entity.User, error)

	// Update updates a user
	Update(ctx context.Context, user *entity.User) error

	// UpdatePassword updates a user's password
	UpdatePassword(ctx context.Context, tenantID, userID, passwordHash string) error

	// UpdateLastLogin updates the last login timestamp
	UpdateLastLogin(ctx context.Context, tenantID, userID string) error

	// Delete deletes a user
	Delete(ctx context.Context, tenantID, userID string) error

	// List retrieves a list of users with pagination
	List(ctx context.Context, tenantID string, offset, limit int) ([]*entity.User, error)

	// Count returns the total number of users in a tenant
	Count(ctx context.Context, tenantID string) (int64, error)

	// SetActive activates or deactivates a user
	SetActive(ctx context.Context, tenantID, userID string, isActive bool) error
}
