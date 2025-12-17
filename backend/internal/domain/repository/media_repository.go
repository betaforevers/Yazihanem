package repository

import (
	"context"

	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
)

// MediaRepository defines operations for media persistence within a tenant schema
type MediaRepository interface {
	// Create creates a new media record
	Create(ctx context.Context, media *entity.Media) error

	// GetByID retrieves a media record by ID within a tenant
	GetByID(ctx context.Context, tenantID, mediaID string) (*entity.Media, error)

	// Delete deletes a media record (soft delete recommended)
	Delete(ctx context.Context, tenantID, mediaID string) error

	// ListByUploader lists media uploaded by a specific user
	ListByUploader(ctx context.Context, tenantID, uploaderID string, offset, limit int) ([]*entity.Media, error)

	// ListByMimeType lists media filtered by MIME type
	ListByMimeType(ctx context.Context, tenantID, mimeType string, offset, limit int) ([]*entity.Media, error)

	// List lists all media for a tenant with pagination
	List(ctx context.Context, tenantID string, offset, limit int) ([]*entity.Media, error)
}
