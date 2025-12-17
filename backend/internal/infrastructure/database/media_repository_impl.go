package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
	"github.com/mehmetkilic/yazihanem/internal/domain/repository"
	"github.com/mehmetkilic/yazihanem/pkg/dbutil"
)

// MediaRepositoryImpl implements repository.MediaRepository
type MediaRepositoryImpl struct {
	pool *pgxpool.Pool
}

// NewMediaRepository creates a new media repository
func NewMediaRepository(pool *pgxpool.Pool) repository.MediaRepository {
	return &MediaRepositoryImpl{
		pool: pool,
	}
}

// Create creates a new media record
func (r *MediaRepositoryImpl) Create(ctx context.Context, media *entity.Media) error {
	tconn, err := dbutil.AcquireTenantConn(ctx, r.pool)
	if err != nil {
		return err
	}
	defer tconn.Release()

	// Generate UUID for new media
	mediaID := uuid.New()

	query := `
		INSERT INTO media (
			id, filename, original_filename, mime_type, size_bytes,
			storage_path, uploaded_by, created_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8
		)
	`

	now := time.Now()
	uploaderUUID, err := uuid.Parse(media.UploadedBy)
	if err != nil {
		return fmt.Errorf("invalid uploader ID: %w", err)
	}

	_, err = tconn.Conn().Exec(ctx, query,
		mediaID,
		media.Filename,
		media.OriginalFilename,
		media.MimeType,
		media.SizeBytes,
		media.StoragePath,
		uploaderUUID,
		now,
	)
	if err != nil {
		return fmt.Errorf("failed to create media: %w", err)
	}

	media.ID = mediaID.String()
	media.CreatedAt = now

	return nil
}

// GetByID retrieves media by ID
func (r *MediaRepositoryImpl) GetByID(ctx context.Context, tenantID, mediaID string) (*entity.Media, error) {
	tconn, err := dbutil.AcquireTenantConn(ctx, r.pool)
	if err != nil {
		return nil, err
	}
	defer tconn.Release()

	mediaUUID, err := uuid.Parse(mediaID)
	if err != nil {
		return nil, fmt.Errorf("invalid media ID: %w", err)
	}

	query := `
		SELECT id, filename, original_filename, mime_type, size_bytes,
		       storage_path, uploaded_by, created_at
		FROM media
		WHERE id = $1
	`

	var media entity.Media
	var id, uploaderID uuid.UUID

	err = tconn.Conn().QueryRow(ctx, query, mediaUUID).Scan(
		&id,
		&media.Filename,
		&media.OriginalFilename,
		&media.MimeType,
		&media.SizeBytes,
		&media.StoragePath,
		&uploaderID,
		&media.CreatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, entity.ErrMediaNotFound
		}
		return nil, fmt.Errorf("failed to get media: %w", err)
	}

	media.ID = id.String()
	media.TenantID = tenantID
	media.UploadedBy = uploaderID.String()

	return &media, nil
}

// Delete deletes a media record
func (r *MediaRepositoryImpl) Delete(ctx context.Context, tenantID, mediaID string) error {
	tconn, err := dbutil.AcquireTenantConn(ctx, r.pool)
	if err != nil {
		return err
	}
	defer tconn.Release()

	mediaUUID, err := uuid.Parse(mediaID)
	if err != nil {
		return fmt.Errorf("invalid media ID: %w", err)
	}

	query := `DELETE FROM media WHERE id = $1`

	result, err := tconn.Conn().Exec(ctx, query, mediaUUID)
	if err != nil {
		return fmt.Errorf("failed to delete media: %w", err)
	}

	if result.RowsAffected() == 0 {
		return entity.ErrMediaNotFound
	}

	return nil
}

// ListByUploader lists media uploaded by a specific user
func (r *MediaRepositoryImpl) ListByUploader(ctx context.Context, tenantID, uploaderID string, offset, limit int) ([]*entity.Media, error) {
	tconn, err := dbutil.AcquireTenantConn(ctx, r.pool)
	if err != nil {
		return nil, err
	}
	defer tconn.Release()

	uploaderUUID, err := uuid.Parse(uploaderID)
	if err != nil {
		return nil, fmt.Errorf("invalid uploader ID: %w", err)
	}

	query := `
		SELECT id, filename, original_filename, mime_type, size_bytes,
		       storage_path, uploaded_by, created_at
		FROM media
		WHERE uploaded_by = $1
		ORDER BY created_at DESC
		OFFSET $2 LIMIT $3
	`

	rows, err := tconn.Conn().Query(ctx, query, uploaderUUID, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to list media: %w", err)
	}
	defer rows.Close()

	var mediaList []*entity.Media

	for rows.Next() {
		var media entity.Media
		var id, uID uuid.UUID

		err := rows.Scan(
			&id,
			&media.Filename,
			&media.OriginalFilename,
			&media.MimeType,
			&media.SizeBytes,
			&media.StoragePath,
			&uID,
			&media.CreatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan media: %w", err)
		}

		media.ID = id.String()
		media.TenantID = tenantID
		media.UploadedBy = uID.String()

		mediaList = append(mediaList, &media)
	}

	return mediaList, nil
}

// ListByMimeType lists media filtered by MIME type
func (r *MediaRepositoryImpl) ListByMimeType(ctx context.Context, tenantID, mimeType string, offset, limit int) ([]*entity.Media, error) {
	tconn, err := dbutil.AcquireTenantConn(ctx, r.pool)
	if err != nil {
		return nil, err
	}
	defer tconn.Release()

	query := `
		SELECT id, filename, original_filename, mime_type, size_bytes,
		       storage_path, uploaded_by, created_at
		FROM media
		WHERE mime_type = $1
		ORDER BY created_at DESC
		OFFSET $2 LIMIT $3
	`

	rows, err := tconn.Conn().Query(ctx, query, mimeType, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to list media: %w", err)
	}
	defer rows.Close()

	var mediaList []*entity.Media

	for rows.Next() {
		var media entity.Media
		var id, uploaderID uuid.UUID

		err := rows.Scan(
			&id,
			&media.Filename,
			&media.OriginalFilename,
			&media.MimeType,
			&media.SizeBytes,
			&media.StoragePath,
			&uploaderID,
			&media.CreatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan media: %w", err)
		}

		media.ID = id.String()
		media.TenantID = tenantID
		media.UploadedBy = uploaderID.String()

		mediaList = append(mediaList, &media)
	}

	return mediaList, nil
}

// List lists all media for a tenant with pagination
func (r *MediaRepositoryImpl) List(ctx context.Context, tenantID string, offset, limit int) ([]*entity.Media, error) {
	tconn, err := dbutil.AcquireTenantConn(ctx, r.pool)
	if err != nil {
		return nil, err
	}
	defer tconn.Release()

	query := `
		SELECT id, filename, original_filename, mime_type, size_bytes,
		       storage_path, uploaded_by, created_at
		FROM media
		ORDER BY created_at DESC
		OFFSET $1 LIMIT $2
	`

	rows, err := tconn.Conn().Query(ctx, query, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to list media: %w", err)
	}
	defer rows.Close()

	var mediaList []*entity.Media

	for rows.Next() {
		var media entity.Media
		var id, uploaderID uuid.UUID

		err := rows.Scan(
			&id,
			&media.Filename,
			&media.OriginalFilename,
			&media.MimeType,
			&media.SizeBytes,
			&media.StoragePath,
			&uploaderID,
			&media.CreatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan media: %w", err)
		}

		media.ID = id.String()
		media.TenantID = tenantID
		media.UploadedBy = uploaderID.String()

		mediaList = append(mediaList, &media)
	}

	return mediaList, nil
}
