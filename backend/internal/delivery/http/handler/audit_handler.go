package handler

import (
	"strconv"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/mehmetkilic/yazihanem/internal/delivery/http/middleware"
	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
	"github.com/mehmetkilic/yazihanem/pkg/audit"
)

// AuditHandler handles audit log endpoints
type AuditHandler struct {
	auditLogger *audit.Logger
}

// NewAuditHandler creates a new audit handler
func NewAuditHandler(auditLogger *audit.Logger) *AuditHandler {
	return &AuditHandler{
		auditLogger: auditLogger,
	}
}

// QueryLogsRequest represents query parameters for audit logs
type QueryLogsRequest struct {
	UserID       *string `query:"user_id"`
	Action       *string `query:"action"`
	Severity     *string `query:"severity"`
	ResourceType *string `query:"resource_type"`
	ResourceID   *string `query:"resource_id"`
	StartTime    *string `query:"start_time"` // RFC3339 format
	EndTime      *string `query:"end_time"`   // RFC3339 format
	Page         int     `query:"page"`
	PageSize     int     `query:"page_size"`
}

// QueryLogsResponse represents audit logs response
type QueryLogsResponse struct {
	Logs       []*entity.AuditLog `json:"logs"`
	TotalCount int64              `json:"total_count"`
	Page       int                `json:"page"`
	PageSize   int                `json:"page_size"`
	TotalPages int                `json:"total_pages"`
}

// QueryLogs retrieves audit logs with filters (admin only)
func (h *AuditHandler) QueryLogs(c *fiber.Ctx) error {
	// Get tenant from context
	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error":   "Unauthorized",
			"message": "Tenant not found",
		})
	}

	// Verify user has admin role
	claims, err := middleware.GetUserClaimsFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	if claims.Role != string(entity.RoleAdmin) {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "Forbidden",
			"message": "Only admins can access audit logs",
		})
	}

	// Parse query parameters
	var req QueryLogsRequest
	if err := c.QueryParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "Invalid query parameters",
		})
	}

	// Set default pagination
	if req.Page < 1 {
		req.Page = 1
	}
	if req.PageSize < 1 || req.PageSize > 100 {
		req.PageSize = 50 // Default page size
	}

	// Build query options
	opts := audit.QueryOptions{
		TenantID: tenantEntity.ID,
		Limit:    req.PageSize,
		Offset:   (req.Page - 1) * req.PageSize,
	}

	// Add optional filters
	if req.UserID != nil && *req.UserID != "" {
		opts.UserID = req.UserID
	}

	if req.Action != nil && *req.Action != "" {
		action := entity.AuditAction(*req.Action)
		opts.Action = &action
	}

	if req.Severity != nil && *req.Severity != "" {
		severity := entity.AuditSeverity(*req.Severity)
		opts.Severity = &severity
	}

	if req.ResourceType != nil && *req.ResourceType != "" {
		opts.ResourceType = req.ResourceType
	}

	if req.ResourceID != nil && *req.ResourceID != "" {
		opts.ResourceID = req.ResourceID
	}

	// Parse time filters
	if req.StartTime != nil && *req.StartTime != "" {
		startTime, err := time.Parse(time.RFC3339, *req.StartTime)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error":   "Bad Request",
				"message": "Invalid start_time format (use RFC3339)",
			})
		}
		opts.StartTime = &startTime
	}

	if req.EndTime != nil && *req.EndTime != "" {
		endTime, err := time.Parse(time.RFC3339, *req.EndTime)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error":   "Bad Request",
				"message": "Invalid end_time format (use RFC3339)",
			})
		}
		opts.EndTime = &endTime
	}

	// Query audit logs
	ctx := c.UserContext()
	logs, err := h.auditLogger.Query(ctx, opts)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to query audit logs",
		})
	}

	// Get total count for pagination
	count, err := h.auditLogger.Count(ctx, opts)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to count audit logs",
		})
	}

	// Calculate total pages
	totalPages := int(count) / req.PageSize
	if int(count)%req.PageSize > 0 {
		totalPages++
	}

	return c.Status(fiber.StatusOK).JSON(QueryLogsResponse{
		Logs:       logs,
		TotalCount: count,
		Page:       req.Page,
		PageSize:   req.PageSize,
		TotalPages: totalPages,
	})
}

// GetLogStats returns audit log statistics (admin only)
func (h *AuditHandler) GetLogStats(c *fiber.Ctx) error {
	// Get tenant from context
	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error":   "Unauthorized",
			"message": "Tenant not found",
		})
	}

	// Verify user has admin role
	claims, err := middleware.GetUserClaimsFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	if claims.Role != string(entity.RoleAdmin) {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "Forbidden",
			"message": "Only admins can access audit log statistics",
		})
	}

	ctx := c.UserContext()

	// Get counts by severity for the last 24 hours
	now := time.Now()
	last24h := now.Add(-24 * time.Hour)

	// Count critical events
	criticalSeverity := entity.AuditSeverityCritical
	criticalCount, _ := h.auditLogger.Count(ctx, audit.QueryOptions{
		TenantID:  tenantEntity.ID,
		Severity:  &criticalSeverity,
		StartTime: &last24h,
	})

	// Count warning events
	warningSeverity := entity.AuditSeverityWarning
	warningCount, _ := h.auditLogger.Count(ctx, audit.QueryOptions{
		TenantID:  tenantEntity.ID,
		Severity:  &warningSeverity,
		StartTime: &last24h,
	})

	// Count info events
	infoSeverity := entity.AuditSeverityInfo
	infoCount, _ := h.auditLogger.Count(ctx, audit.QueryOptions{
		TenantID:  tenantEntity.ID,
		Severity:  &infoSeverity,
		StartTime: &last24h,
	})

	// Total count for last 24h
	total24h, _ := h.auditLogger.Count(ctx, audit.QueryOptions{
		TenantID:  tenantEntity.ID,
		StartTime: &last24h,
	})

	// Total count overall
	totalCount, _ := h.auditLogger.Count(ctx, audit.QueryOptions{
		TenantID: tenantEntity.ID,
	})

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"tenant_id": tenantEntity.ID,
		"stats": fiber.Map{
			"total":       totalCount,
			"last_24h":    total24h,
			"by_severity": fiber.Map{
				"critical": criticalCount,
				"warning":  warningCount,
				"info":     infoCount,
			},
		},
		"generated_at": now,
	})
}

// DeleteOldLogs deletes audit logs older than retention period (owner only)
func (h *AuditHandler) DeleteOldLogs(c *fiber.Ctx) error {
	// Verify user has owner role
	claims, err := middleware.GetUserClaimsFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	if claims.Role != string(entity.RoleAdmin) {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "Forbidden",
			"message": "Only admins can delete audit logs",
		})
	}

	// Get retention days from query parameter (default: 90 days)
	retentionDays := 90
	if retentionParam := c.Query("retention_days"); retentionParam != "" {
		if days, err := strconv.Atoi(retentionParam); err == nil && days > 0 {
			retentionDays = days
		}
	}

	// Delete old logs
	ctx := c.UserContext()
	deletedCount, err := h.auditLogger.DeleteOldLogs(ctx, retentionDays)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to delete old logs",
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message":        "Old audit logs deleted successfully",
		"retention_days": retentionDays,
		"deleted_count":  deletedCount,
	})
}
