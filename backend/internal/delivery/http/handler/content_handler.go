package handler

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/mehmetkilic/yazihanem/internal/delivery/http/middleware"
	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
	"github.com/mehmetkilic/yazihanem/internal/domain/repository"
	"github.com/mehmetkilic/yazihanem/pkg/audit"
	"github.com/mehmetkilic/yazihanem/pkg/tenant"
)

// ContentHandler handles content management endpoints
type ContentHandler struct {
	contentRepo repository.ContentRepository
	auditLogger *audit.Logger
}

// NewContentHandler creates a new content handler
func NewContentHandler(contentRepo repository.ContentRepository, auditLogger *audit.Logger) *ContentHandler {
	return &ContentHandler{
		contentRepo: contentRepo,
		auditLogger: auditLogger,
	}
}

// CreateContentRequest represents content creation request
type CreateContentRequest struct {
	Title  string `json:"title" validate:"required,min=1,max=200"`
	Slug   string `json:"slug" validate:"required,min=1,max=200"`
	Body   string `json:"body"`
	Status string `json:"status" validate:"omitempty,oneof=draft published archived"`
}

// UpdateContentRequest represents content update request
type UpdateContentRequest struct {
	Title  *string `json:"title,omitempty" validate:"omitempty,min=1,max=200"`
	Slug   *string `json:"slug,omitempty" validate:"omitempty,min=1,max=200"`
	Body   *string `json:"body,omitempty"`
	Status *string `json:"status,omitempty" validate:"omitempty,oneof=draft published archived"`
}

// PublishContentRequest represents content publish request
type PublishContentRequest struct {
	PublishAt *time.Time `json:"publish_at,omitempty"`
}

// CreateContent creates a new content
func (h *ContentHandler) CreateContent(c *fiber.Ctx) error {
	var req CreateContentRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "Invalid request body",
		})
	}

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

	// Set default status to draft if not provided
	status := entity.StatusDraft
	if req.Status != "" {
		status = entity.ContentStatus(req.Status)
	}

	// Create content entity
	content := &entity.Content{
		TenantID: tenantEntity.ID,
		Title:    req.Title,
		Slug:     req.Slug,
		Body:     req.Body,
		Status:   status,
		AuthorID: claims.UserID,
	}

	// Validate content
	if err := content.Validate(); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": err.Error(),
		})
	}

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Create content in database
	if err := h.contentRepo.Create(ctx, content); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to create content",
		})
	}

	// Log audit event
	middleware.LogAuditWithResource(c, h.auditLogger, entity.AuditActionContentCreate, "content", content.ID)

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"message": "Content created successfully",
		"content": content,
	})
}

// GetContent retrieves content by ID
func (h *ContentHandler) GetContent(c *fiber.Ctx) error {
	contentID := c.Params("id")
	if contentID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "Content ID is required",
		})
	}

	// Get tenant from context
	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Get content from database
	content, err := h.contentRepo.GetByID(ctx, tenantEntity.ID, contentID)
	if err != nil {
		if err == entity.ErrContentNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"error":   "Not Found",
				"message": "Content not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to get content",
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"content": content,
	})
}

// GetContentBySlug retrieves content by slug
func (h *ContentHandler) GetContentBySlug(c *fiber.Ctx) error {
	slug := c.Params("slug")
	if slug == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "Slug is required",
		})
	}

	// Get tenant from context
	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Get content from database
	content, err := h.contentRepo.GetBySlug(ctx, tenantEntity.ID, slug)
	if err != nil {
		if err == entity.ErrContentNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"error":   "Not Found",
				"message": "Content not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to get content",
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"content": content,
	})
}

// UpdateContent updates existing content
func (h *ContentHandler) UpdateContent(c *fiber.Ctx) error {
	contentID := c.Params("id")
	if contentID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "Content ID is required",
		})
	}

	var req UpdateContentRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "Invalid request body",
		})
	}

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

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Get existing content
	content, err := h.contentRepo.GetByID(ctx, tenantEntity.ID, contentID)
	if err != nil {
		if err == entity.ErrContentNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"error":   "Not Found",
				"message": "Content not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to get content",
		})
	}

	// Check if user is the author or admin
	if content.AuthorID != claims.UserID && claims.Role != string(entity.RoleAdmin) {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "Forbidden",
			"message": "You can only edit your own content",
		})
	}

	// Update fields if provided
	if req.Title != nil {
		content.Title = *req.Title
	}
	if req.Slug != nil {
		content.Slug = *req.Slug
	}
	if req.Body != nil {
		content.Body = *req.Body
	}
	if req.Status != nil {
		content.Status = entity.ContentStatus(*req.Status)
	}

	// Validate updated content
	if err := content.Validate(); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": err.Error(),
		})
	}

	// Update content in database
	if err := h.contentRepo.Update(ctx, content); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to update content",
		})
	}

	// Log audit event
	middleware.LogAuditWithResource(c, h.auditLogger, entity.AuditActionContentUpdate, "content", content.ID)

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "Content updated successfully",
		"content": content,
	})
}

// DeleteContent deletes content by ID
func (h *ContentHandler) DeleteContent(c *fiber.Ctx) error {
	contentID := c.Params("id")
	if contentID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "Content ID is required",
		})
	}

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

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Get existing content to check ownership
	content, err := h.contentRepo.GetByID(ctx, tenantEntity.ID, contentID)
	if err != nil {
		if err == entity.ErrContentNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"error":   "Not Found",
				"message": "Content not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to get content",
		})
	}

	// Check if user is the author or admin
	if content.AuthorID != claims.UserID && claims.Role != string(entity.RoleAdmin) {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "Forbidden",
			"message": "You can only delete your own content",
		})
	}

	// Delete content from database
	if err := h.contentRepo.Delete(ctx, tenantEntity.ID, contentID); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to delete content",
		})
	}

	// Log audit event
	middleware.LogAuditWithResource(c, h.auditLogger, entity.AuditActionContentDelete, "content", contentID)

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "Content deleted successfully",
	})
}

// ListContent retrieves content list with optional filters
func (h *ContentHandler) ListContent(c *fiber.Ctx) error {
	// Get tenant from context
	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	// Parse query parameters
	status := c.Query("status", "")
	page := c.QueryInt("page", 1)
	pageSize := c.QueryInt("page_size", 20)

	// Validate page size
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	offset := (page - 1) * pageSize

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Get content list from database
	var contents []*entity.Content
	if status != "" {
		contents, err = h.contentRepo.List(ctx, tenantEntity.ID, entity.ContentStatus(status), offset, pageSize)
	} else {
		contents, err = h.contentRepo.List(ctx, tenantEntity.ID, "", offset, pageSize)
	}

	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to list content",
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"contents":  contents,
		"page":      page,
		"page_size": pageSize,
	})
}

// ListMyContent retrieves content list for authenticated user
func (h *ContentHandler) ListMyContent(c *fiber.Ctx) error {
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

	// Parse query parameters
	page := c.QueryInt("page", 1)
	pageSize := c.QueryInt("page_size", 20)

	// Validate page size
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	offset := (page - 1) * pageSize

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Get content list for current user
	contents, err := h.contentRepo.ListByAuthor(ctx, tenantEntity.ID, claims.UserID, offset, pageSize)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to list content",
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"contents":  contents,
		"page":      page,
		"page_size": pageSize,
	})
}

// PublishContent publishes a content
func (h *ContentHandler) PublishContent(c *fiber.Ctx) error {
	contentID := c.Params("id")
	if contentID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "Content ID is required",
		})
	}

	var req PublishContentRequest
	if err := c.BodyParser(&req); err != nil {
		// If no body, use current time
		req.PublishAt = nil
	}

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

	// Only editors and admins can publish
	if claims.Role != string(entity.RoleAdmin) && claims.Role != string(entity.RoleEditor) {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "Forbidden",
			"message": "Only editors and admins can publish content",
		})
	}

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Get existing content
	content, err := h.contentRepo.GetByID(ctx, tenantEntity.ID, contentID)
	if err != nil {
		if err == entity.ErrContentNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"error":   "Not Found",
				"message": "Content not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to get content",
		})
	}

	// Set publish time
	if req.PublishAt != nil {
		content.PublishedAt = req.PublishAt
	} else {
		now := time.Now()
		content.PublishedAt = &now
	}

	// Set status to published
	content.Status = entity.StatusPublished

	// Update content in database
	if err := h.contentRepo.Update(ctx, content); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to publish content",
		})
	}

	// Log audit event
	middleware.LogAuditWithResource(c, h.auditLogger, entity.AuditActionContentPublish, "content", content.ID)

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "Content published successfully",
		"content": content,
	})
}
