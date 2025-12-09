package repository

import (
	"context"

	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
)

// UserRepository defines operations for user persistence within a tenant schema
type UserRepository interface {
	Create(ctx context.Context, user *entity.User) error
	GetByID(ctx context.Context, tenantID, userID string) (*entity.User, error)
	GetByEmail(ctx context.Context, tenantID, email string) (*entity.User, error)
	Update(ctx context.Context, user *entity.User) error
	Delete(ctx context.Context, tenantID, userID string) error
	List(ctx context.Context, tenantID string, offset, limit int) ([]*entity.User, error)
}
