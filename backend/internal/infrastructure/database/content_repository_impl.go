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
	"github.com/mehmetkilic/yazihanem/pkg/tenant"
)

// ContentRepositoryImpl implements repository.ContentRepository
type ContentRepositoryImpl struct {
	pool *pgxpool.Pool
}

// NewContentRepository creates a new content repository
func NewContentRepository(pool *pgxpool.Pool) repository.ContentRepository {
	return &ContentRepositoryImpl{
		pool: pool,
	}
}

// Create creates a new content
func (r *ContentRepositoryImpl) Create(ctx context.Context, content *entity.Content) error {
	tconn, err := dbutil.AcquireTenantConn(ctx, r.pool)
	if err != nil {
		return err
	}
	defer tconn.Release()

	// Generate UUID for new content
	contentID := uuid.New()

	query := `
		INSERT INTO content (
			id, title, slug, body, status, author_id, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8
		)
	`

	now := time.Now()
	authorUUID, err := uuid.Parse(content.AuthorID)
	if err != nil {
		return fmt.Errorf("invalid author ID: %w", err)
	}

	_, err = tconn.Conn().Exec(ctx, query,
		contentID,
		content.Title,
		content.Slug,
		content.Body,
		content.Status,
		authorUUID,
		now,
		now,
	)
	if err != nil {
		return fmt.Errorf("failed to create content: %w", err)
	}

	content.ID = contentID.String()
	content.CreatedAt = now
	content.UpdatedAt = now

	return nil
}

// GetByID retrieves content by ID
func (r *ContentRepositoryImpl) GetByID(ctx context.Context, tenantID, contentID string) (*entity.Content, error) {
	schema, ok := tenant.GetSchemaFromContext(ctx)
	if !ok {
		return nil, fmt.Errorf("tenant schema not found in context")
	}

	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to acquire connection: %w", err)
	}
	defer conn.Release()

	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s", schema))
	if err != nil {
		return nil, fmt.Errorf("failed to set search_path: %w", err)
	}

	contentUUID, err := uuid.Parse(contentID)
	if err != nil {
		return nil, fmt.Errorf("invalid content ID: %w", err)
	}

	query := `
		SELECT id, title, slug, body, status, author_id, published_at, created_at, updated_at
		FROM content
		WHERE id = $1
	`

	var content entity.Content
	var id, authorID uuid.UUID
	var publishedAt *time.Time

	err = conn.QueryRow(ctx, query, contentUUID).Scan(
		&id,
		&content.Title,
		&content.Slug,
		&content.Body,
		&content.Status,
		&authorID,
		&publishedAt,
		&content.CreatedAt,
		&content.UpdatedAt,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, entity.ErrContentNotFound
		}
		return nil, fmt.Errorf("failed to get content: %w", err)
	}

	content.ID = id.String()
	content.TenantID = tenantID
	content.AuthorID = authorID.String()
	content.PublishedAt = publishedAt

	return &content, nil
}

// GetBySlug retrieves content by slug
func (r *ContentRepositoryImpl) GetBySlug(ctx context.Context, tenantID, slug string) (*entity.Content, error) {
	schema, ok := tenant.GetSchemaFromContext(ctx)
	if !ok {
		return nil, fmt.Errorf("tenant schema not found in context")
	}

	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to acquire connection: %w", err)
	}
	defer conn.Release()

	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s", schema))
	if err != nil {
		return nil, fmt.Errorf("failed to set search_path: %w", err)
	}

	query := `
		SELECT id, title, slug, body, status, author_id, published_at, created_at, updated_at
		FROM content
		WHERE slug = $1
	`

	var content entity.Content
	var id, authorID uuid.UUID
	var publishedAt *time.Time

	err = conn.QueryRow(ctx, query, slug).Scan(
		&id,
		&content.Title,
		&content.Slug,
		&content.Body,
		&content.Status,
		&authorID,
		&publishedAt,
		&content.CreatedAt,
		&content.UpdatedAt,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, entity.ErrContentNotFound
		}
		return nil, fmt.Errorf("failed to get content: %w", err)
	}

	content.ID = id.String()
	content.TenantID = tenantID
	content.AuthorID = authorID.String()
	content.PublishedAt = publishedAt

	return &content, nil
}

// Update updates existing content
func (r *ContentRepositoryImpl) Update(ctx context.Context, content *entity.Content) error {
	tconn, err := dbutil.AcquireTenantConn(ctx, r.pool)
	if err != nil {
		return err
	}
	defer tconn.Release()

	contentUUID, err := uuid.Parse(content.ID)
	if err != nil {
		return fmt.Errorf("invalid content ID: %w", err)
	}

	query := `
		UPDATE content
		SET title = $2, slug = $3, body = $4, status = $5,
		    published_at = $6, updated_at = $7
		WHERE id = $1
	`

	now := time.Now()
	result, err := tconn.Conn().Exec(ctx, query,
		contentUUID,
		content.Title,
		content.Slug,
		content.Body,
		content.Status,
		content.PublishedAt,
		now,
	)
	if err != nil {
		return fmt.Errorf("failed to update content: %w", err)
	}

	if result.RowsAffected() == 0 {
		return entity.ErrContentNotFound
	}

	content.UpdatedAt = now
	return nil
}

// Delete deletes content by ID
func (r *ContentRepositoryImpl) Delete(ctx context.Context, tenantID, contentID string) error {
	tconn, err := dbutil.AcquireTenantConn(ctx, r.pool)
	if err != nil {
		return err
	}
	defer tconn.Release()

	contentUUID, err := uuid.Parse(contentID)
	if err != nil {
		return fmt.Errorf("invalid content ID: %w", err)
	}

	query := `DELETE FROM content WHERE id = $1`

	result, err := tconn.Conn().Exec(ctx, query, contentUUID)
	if err != nil {
		return fmt.Errorf("failed to delete content: %w", err)
	}

	if result.RowsAffected() == 0 {
		return entity.ErrContentNotFound
	}

	return nil
}

// List retrieves content list with optional status filter
func (r *ContentRepositoryImpl) List(ctx context.Context, tenantID string, status entity.ContentStatus, offset, limit int) ([]*entity.Content, error) {
	schema, ok := tenant.GetSchemaFromContext(ctx)
	if !ok {
		return nil, fmt.Errorf("tenant schema not found in context")
	}

	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to acquire connection: %w", err)
	}
	defer conn.Release()

	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s", schema))
	if err != nil {
		return nil, fmt.Errorf("failed to set search_path: %w", err)
	}

	var query string
	var args []interface{}

	if status != "" {
		query = `
			SELECT id, title, slug, body, status, author_id, published_at, created_at, updated_at
			FROM content
			WHERE status = $1
			ORDER BY created_at DESC
			LIMIT $2 OFFSET $3
		`
		args = []interface{}{status, limit, offset}
	} else {
		query = `
			SELECT id, title, slug, body, status, author_id, published_at, created_at, updated_at
			FROM content
			ORDER BY created_at DESC
			LIMIT $1 OFFSET $2
		`
		args = []interface{}{limit, offset}
	}

	rows, err := conn.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to list content: %w", err)
	}
	defer rows.Close()

	var contents []*entity.Content
	for rows.Next() {
		var content entity.Content
		var id, authorID uuid.UUID
		var publishedAt *time.Time

		err := rows.Scan(
			&id,
			&content.Title,
			&content.Slug,
			&content.Body,
			&content.Status,
			&authorID,
			&publishedAt,
			&content.CreatedAt,
			&content.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan content: %w", err)
		}

		content.ID = id.String()
		content.TenantID = tenantID
		content.AuthorID = authorID.String()
		content.PublishedAt = publishedAt

		contents = append(contents, &content)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating content: %w", err)
	}

	return contents, nil
}

// ListByAuthor retrieves content list for a specific author
func (r *ContentRepositoryImpl) ListByAuthor(ctx context.Context, tenantID, authorID string, offset, limit int) ([]*entity.Content, error) {
	schema, ok := tenant.GetSchemaFromContext(ctx)
	if !ok {
		return nil, fmt.Errorf("tenant schema not found in context")
	}

	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to acquire connection: %w", err)
	}
	defer conn.Release()

	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s", schema))
	if err != nil {
		return nil, fmt.Errorf("failed to set search_path: %w", err)
	}

	authorUUID, err := uuid.Parse(authorID)
	if err != nil {
		return nil, fmt.Errorf("invalid author ID: %w", err)
	}

	query := `
		SELECT id, title, slug, body, status, author_id, published_at, created_at, updated_at
		FROM content
		WHERE author_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := conn.Query(ctx, query, authorUUID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to list content by author: %w", err)
	}
	defer rows.Close()

	var contents []*entity.Content
	for rows.Next() {
		var content entity.Content
		var id, authorIDScanned uuid.UUID
		var publishedAt *time.Time

		err := rows.Scan(
			&id,
			&content.Title,
			&content.Slug,
			&content.Body,
			&content.Status,
			&authorIDScanned,
			&publishedAt,
			&content.CreatedAt,
			&content.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan content: %w", err)
		}

		content.ID = id.String()
		content.TenantID = tenantID
		content.AuthorID = authorIDScanned.String()
		content.PublishedAt = publishedAt

		contents = append(contents, &content)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating content: %w", err)
	}

	return contents, nil
}
