package repository

import (
	"context"

	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
)

// ContentRepository defines operations for content persistence within a tenant schema
type ContentRepository interface {
	Create(ctx context.Context, content *entity.Content) error
	GetByID(ctx context.Context, tenantID, contentID string) (*entity.Content, error)
	GetBySlug(ctx context.Context, tenantID, slug string) (*entity.Content, error)
	Update(ctx context.Context, content *entity.Content) error
	Delete(ctx context.Context, tenantID, contentID string) error
	List(ctx context.Context, tenantID string, status entity.ContentStatus, offset, limit int) ([]*entity.Content, error)
	ListByAuthor(ctx context.Context, tenantID, authorID string, offset, limit int) ([]*entity.Content, error)
}
