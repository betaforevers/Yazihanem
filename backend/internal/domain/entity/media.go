package entity

import (
	"time"
)

// Media represents an uploaded file in the system
type Media struct {
	ID               string    `json:"id"`
	TenantID         string    `json:"tenant_id"`
	Filename         string    `json:"filename"`          // Generated filename (UUID + extension)
	OriginalFilename string    `json:"original_filename"` // User's original filename
	MimeType         string    `json:"mime_type"`
	SizeBytes        int64     `json:"size_bytes"`
	StoragePath      string    `json:"storage_path"` // S3/local storage path
	UploadedBy       string    `json:"uploaded_by"`  // User ID
	CreatedAt        time.Time `json:"created_at"`
}

// MediaType represents the category of media file
type MediaType string

const (
	MediaTypeImage MediaType = "image"
	MediaTypeVideo MediaType = "video"
	MediaTypeAudio MediaType = "audio"
	MediaTypeDocument MediaType = "document"
	MediaTypeOther MediaType = "other"
)

// AllowedMimeTypes defines the whitelist of acceptable file types
var AllowedMimeTypes = map[string]MediaType{
	// Images
	"image/jpeg":      MediaTypeImage,
	"image/png":       MediaTypeImage,
	"image/gif":       MediaTypeImage,
	"image/webp":      MediaTypeImage,
	"image/svg+xml":   MediaTypeImage,

	// Videos
	"video/mp4":       MediaTypeVideo,
	"video/webm":      MediaTypeVideo,
	"video/ogg":       MediaTypeVideo,

	// Audio
	"audio/mpeg":      MediaTypeAudio,
	"audio/wav":       MediaTypeAudio,
	"audio/ogg":       MediaTypeAudio,

	// Documents
	"application/pdf": MediaTypeDocument,
	"text/plain":      MediaTypeDocument,
	"application/msword": MediaTypeDocument,
	"application/vnd.openxmlformats-officedocument.wordprocessingml.document": MediaTypeDocument,
}

// MaxFileSizeBytes defines maximum upload size (50MB)
const MaxFileSizeBytes = 50 * 1024 * 1024

// Validate validates media data
func (m *Media) Validate() error {
	if m.Filename == "" {
		return ErrInvalidFilename
	}
	if m.OriginalFilename == "" {
		return ErrInvalidFilename
	}
	if m.MimeType == "" {
		return ErrInvalidMimeType
	}
	if _, ok := AllowedMimeTypes[m.MimeType]; !ok {
		return ErrUnsupportedMimeType
	}
	if m.SizeBytes <= 0 {
		return ErrInvalidFileSize
	}
	if m.SizeBytes > MaxFileSizeBytes {
		return ErrFileSizeTooLarge
	}
	if m.StoragePath == "" {
		return ErrInvalidStoragePath
	}
	if m.TenantID == "" {
		return ErrInvalidTenantID
	}
	if m.UploadedBy == "" {
		return ErrInvalidUploader
	}
	return nil
}

// GetMediaType returns the type category for this media
func (m *Media) GetMediaType() MediaType {
	if mediaType, ok := AllowedMimeTypes[m.MimeType]; ok {
		return mediaType
	}
	return MediaTypeOther
}
