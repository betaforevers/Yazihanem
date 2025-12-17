package entity

import "errors"

// Domain errors
var (
	// Tenant errors
	ErrInvalidTenantName = errors.New("invalid tenant name")
	ErrInvalidSchemaName = errors.New("invalid schema name")
	ErrInvalidDomain     = errors.New("invalid domain")
	ErrInvalidTenantID   = errors.New("invalid tenant ID")
	ErrTenantNotFound    = errors.New("tenant not found")
	ErrTenantInactive    = errors.New("tenant is inactive")

	// User errors
	ErrInvalidEmail      = errors.New("invalid email")
	ErrInvalidRole       = errors.New("invalid role")
	ErrUserNotFound      = errors.New("user not found")
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrUserAlreadyExists  = errors.New("user already exists")

	// Content errors
	ErrInvalidTitle    = errors.New("invalid title")
	ErrInvalidSlug     = errors.New("invalid slug")
	ErrInvalidAuthorID = errors.New("invalid author ID")
	ErrInvalidStatus   = errors.New("invalid status")
	ErrContentNotFound = errors.New("content not found")

	// Media errors
	ErrInvalidFilename      = errors.New("invalid filename")
	ErrInvalidMimeType      = errors.New("invalid mime type")
	ErrUnsupportedMimeType  = errors.New("unsupported mime type")
	ErrInvalidFileSize      = errors.New("invalid file size")
	ErrFileSizeTooLarge     = errors.New("file size exceeds maximum limit")
	ErrInvalidStoragePath   = errors.New("invalid storage path")
	ErrInvalidUploader      = errors.New("invalid uploader")
	ErrMediaNotFound        = errors.New("media not found")
	ErrFileUploadFailed     = errors.New("file upload failed")
)
