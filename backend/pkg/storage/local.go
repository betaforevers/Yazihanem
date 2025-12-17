package storage

import (
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"
)

// LocalStorage implements Storage interface for local filesystem
type LocalStorage struct {
	basePath string // Base directory for uploads (e.g., "./uploads")
}

// NewLocalStorage creates a new local storage instance
func NewLocalStorage(basePath string) (*LocalStorage, error) {
	// Create base directory if it doesn't exist
	if err := os.MkdirAll(basePath, 0755); err != nil {
		return nil, fmt.Errorf("failed to create base directory: %w", err)
	}

	return &LocalStorage{
		basePath: basePath,
	}, nil
}

// Upload saves a file to local filesystem
// Path format: {basePath}/{tenant_id}/media/{year}/{month}/{filename}
func (s *LocalStorage) Upload(ctx context.Context, file io.Reader, filename string, contentType string) (string, error) {
	// Generate path with date-based organization
	now := time.Now()
	relativePath := filepath.Join(
		fmt.Sprintf("%d", now.Year()),
		fmt.Sprintf("%02d", now.Month()),
		filename,
	)

	// Full filesystem path
	fullPath := filepath.Join(s.basePath, relativePath)

	// Create directory structure
	dir := filepath.Dir(fullPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return "", fmt.Errorf("failed to create directory: %w", err)
	}

	// Create file
	dst, err := os.Create(fullPath)
	if err != nil {
		return "", fmt.Errorf("failed to create file: %w", err)
	}
	defer dst.Close()

	// Copy data
	if _, err := io.Copy(dst, file); err != nil {
		// Clean up partial file on error
		os.Remove(fullPath)
		return "", fmt.Errorf("failed to write file: %w", err)
	}

	return relativePath, nil
}

// Download retrieves a file from local filesystem
func (s *LocalStorage) Download(ctx context.Context, path string) (io.ReadCloser, error) {
	fullPath := filepath.Join(s.basePath, path)

	file, err := os.Open(fullPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, fmt.Errorf("file not found: %s", path)
		}
		return nil, fmt.Errorf("failed to open file: %w", err)
	}

	return file, nil
}

// Delete removes a file from local filesystem
func (s *LocalStorage) Delete(ctx context.Context, path string) error {
	fullPath := filepath.Join(s.basePath, path)

	if err := os.Remove(fullPath); err != nil {
		if os.IsNotExist(err) {
			return nil // Already deleted, not an error
		}
		return fmt.Errorf("failed to delete file: %w", err)
	}

	return nil
}

// GetURL returns the file path (local storage doesn't have public URLs)
func (s *LocalStorage) GetURL(ctx context.Context, path string) (string, error) {
	// For local storage, return the relative path
	// In production, this should be served via CDN or static file server
	return path, nil
}

// Exists checks if a file exists in local filesystem
func (s *LocalStorage) Exists(ctx context.Context, path string) (bool, error) {
	fullPath := filepath.Join(s.basePath, path)

	_, err := os.Stat(fullPath)
	if err != nil {
		if os.IsNotExist(err) {
			return false, nil
		}
		return false, fmt.Errorf("failed to check file existence: %w", err)
	}

	return true, nil
}
