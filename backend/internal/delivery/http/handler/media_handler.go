package handler

import (
	"fmt"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/mehmetkilic/yazihanem/internal/delivery/http/middleware"
	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
	"github.com/mehmetkilic/yazihanem/internal/domain/repository"
	"github.com/mehmetkilic/yazihanem/pkg/audit"
	"github.com/mehmetkilic/yazihanem/pkg/storage"
	"github.com/mehmetkilic/yazihanem/pkg/tenant"
)

// MediaHandler handles media upload and management endpoints
type MediaHandler struct {
	mediaRepo   repository.MediaRepository
	storage     storage.Storage
	auditLogger *audit.Logger
}

// NewMediaHandler creates a new media handler
func NewMediaHandler(
	mediaRepo repository.MediaRepository,
	storage storage.Storage,
	auditLogger *audit.Logger,
) *MediaHandler {
	return &MediaHandler{
		mediaRepo:   mediaRepo,
		storage:     storage,
		auditLogger: auditLogger,
	}
}

// UploadMedia handles file upload
// Request: multipart/form-data with "file" field
func (h *MediaHandler) UploadMedia(c *fiber.Ctx) error {
	// Get tenant and user from context
	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	claims, err := middleware.GetUserClaimsFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	// Parse multipart form
	file, err := c.FormFile("file")
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "No file uploaded",
		})
	}

	// Validate file size
	if file.Size > entity.MaxFileSizeBytes {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": fmt.Sprintf("File size exceeds maximum limit of %d MB", entity.MaxFileSizeBytes/(1024*1024)),
		})
	}

	// Detect MIME type from Content-Type header
	contentType := file.Header.Get("Content-Type")
	if contentType == "" {
		// Fallback: detect from file extension
		ext := strings.ToLower(filepath.Ext(file.Filename))
		contentType = mimeTypeFromExtension(ext)
	}

	// Validate MIME type
	if _, ok := entity.AllowedMimeTypes[contentType]; !ok {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": fmt.Sprintf("Unsupported file type: %s", contentType),
		})
	}

	// Open file stream
	fileStream, err := file.Open()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to read file",
		})
	}
	defer fileStream.Close()

	// Generate unique filename
	ext := filepath.Ext(file.Filename)
	filename := fmt.Sprintf("%s%s", uuid.New().String(), ext)

	// Create tenant-specific storage path
	// Format: {tenant_id}/media/{filename}
	storagePath := filepath.Join(tenantEntity.ID, "media", filename)

	// Upload to storage
	ctx := c.UserContext()
	uploadedPath, err := h.storage.Upload(ctx, fileStream, storagePath, contentType)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to upload file",
		})
	}

	// Create media entity
	media := &entity.Media{
		TenantID:         tenantEntity.ID,
		Filename:         filename,
		OriginalFilename: file.Filename,
		MimeType:         contentType,
		SizeBytes:        file.Size,
		StoragePath:      uploadedPath,
		UploadedBy:       claims.UserID,
	}

	// Validate media
	if err := media.Validate(); err != nil {
		// Cleanup uploaded file on validation error
		_ = h.storage.Delete(ctx, uploadedPath)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": err.Error(),
		})
	}

	// Set tenant context
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Save to database
	if err := h.mediaRepo.Create(ctx, media); err != nil {
		// Cleanup uploaded file on database error
		_ = h.storage.Delete(ctx, uploadedPath)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to save media record",
		})
	}

	// Audit log
	h.auditLogger.LogAsync(&entity.AuditLog{
		TenantID:     tenantEntity.ID,
		UserID:       &claims.UserID,
		Action:       "media.upload",
		Severity:     entity.AuditSeverityInfo,
		ResourceType: "media",
		ResourceID:   &media.ID,
		IPAddress:    c.IP(),
		UserAgent:    c.Get("User-Agent"),
		Success:      true,
	})

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"message": "File uploaded successfully",
		"media":   media,
	})
}

// GetMedia retrieves a media record by ID
func (h *MediaHandler) GetMedia(c *fiber.Ctx) error {
	mediaID := c.Params("id")
	if mediaID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Bad Request",
			"message": "Media ID is required",
		})
	}

	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	media, err := h.mediaRepo.GetByID(ctx, tenantEntity.ID, mediaID)
	if err != nil {
		if err == entity.ErrMediaNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"error": "Not Found",
				"message": "Media not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Internal Server Error",
		})
	}

	return c.JSON(fiber.Map{
		"media": media,
	})
}

// ListMedia lists media with pagination and filters
func (h *MediaHandler) ListMedia(c *fiber.Ctx) error {
	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	// Parse pagination
	page, _ := strconv.Atoi(c.Query("page", "1"))
	pageSize, _ := strconv.Atoi(c.Query("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	offset := (page - 1) * pageSize
	limit := pageSize

	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Filter by uploader if provided
	uploaderID := c.Query("uploader_id")
	mimeType := c.Query("mime_type")

	var mediaList []*entity.Media

	if uploaderID != "" {
		mediaList, err = h.mediaRepo.ListByUploader(ctx, tenantEntity.ID, uploaderID, offset, limit)
	} else if mimeType != "" {
		mediaList, err = h.mediaRepo.ListByMimeType(ctx, tenantEntity.ID, mimeType, offset, limit)
	} else {
		mediaList, err = h.mediaRepo.List(ctx, tenantEntity.ID, offset, limit)
	}

	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Internal Server Error",
		})
	}

	return c.JSON(fiber.Map{
		"media":     mediaList,
		"page":      page,
		"page_size": pageSize,
	})
}

// DeleteMedia deletes a media record and file
func (h *MediaHandler) DeleteMedia(c *fiber.Ctx) error {
	mediaID := c.Params("id")
	if mediaID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Bad Request",
			"message": "Media ID is required",
		})
	}

	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	claims, err := middleware.GetUserClaimsFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Get media to check ownership and get storage path
	media, err := h.mediaRepo.GetByID(ctx, tenantEntity.ID, mediaID)
	if err != nil {
		if err == entity.ErrMediaNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"error": "Not Found",
				"message": "Media not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Internal Server Error",
		})
	}

	// Check ownership (only uploader or admin can delete)
	if media.UploadedBy != claims.UserID && claims.Role != "admin" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "Forbidden",
			"message": "You can only delete media you uploaded",
		})
	}

	// Delete from storage first
	if err := h.storage.Delete(ctx, media.StoragePath); err != nil {
		// Log error but continue with database deletion
		// File might already be deleted
	}

	// Delete from database
	if err := h.mediaRepo.Delete(ctx, tenantEntity.ID, mediaID); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Internal Server Error",
		})
	}

	// Audit log
	h.auditLogger.LogAsync(&entity.AuditLog{
		TenantID:     tenantEntity.ID,
		UserID:       &claims.UserID,
		Action:       "media.delete",
		Severity:     entity.AuditSeverityInfo,
		ResourceType: "media",
		ResourceID:   &mediaID,
		IPAddress:    c.IP(),
		UserAgent:    c.Get("User-Agent"),
		Success:      true,
	})

	return c.JSON(fiber.Map{
		"message": "Media deleted successfully",
	})
}

// mimeTypeFromExtension returns MIME type from file extension
func mimeTypeFromExtension(ext string) string {
	switch ext {
	case ".jpg", ".jpeg":
		return "image/jpeg"
	case ".png":
		return "image/png"
	case ".gif":
		return "image/gif"
	case ".webp":
		return "image/webp"
	case ".svg":
		return "image/svg+xml"
	case ".mp4":
		return "video/mp4"
	case ".webm":
		return "video/webm"
	case ".ogg":
		return "video/ogg"
	case ".mp3":
		return "audio/mpeg"
	case ".wav":
		return "audio/wav"
	case ".pdf":
		return "application/pdf"
	case ".txt":
		return "text/plain"
	case ".doc":
		return "application/msword"
	case ".docx":
		return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
	default:
		return "application/octet-stream"
	}
}
