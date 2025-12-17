package storage

import (
	"context"
	"io"
)

// Storage defines the interface for file storage operations
// Implementations: LocalStorage, S3Storage, MinIOStorage
type Storage interface {
	// Upload uploads a file and returns the storage path
	Upload(ctx context.Context, file io.Reader, filename string, contentType string) (string, error)

	// Download retrieves a file by its storage path
	Download(ctx context.Context, path string) (io.ReadCloser, error)

	// Delete removes a file from storage
	Delete(ctx context.Context, path string) error

	// GetURL returns the public URL for a file (if supported)
	GetURL(ctx context.Context, path string) (string, error)

	// Exists checks if a file exists at the given path
	Exists(ctx context.Context, path string) (bool, error)
}

// UploadResult contains information about an uploaded file
type UploadResult struct {
	Path        string // Storage path (e.g., "tenant_123/media/2025/12/uuid.jpg")
	URL         string // Public URL (if available)
	SizeBytes   int64  // File size in bytes
	ContentType string // MIME type
}
