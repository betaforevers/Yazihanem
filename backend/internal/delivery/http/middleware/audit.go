package middleware

import (
	"github.com/gofiber/fiber/v2"
	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
	"github.com/mehmetkilic/yazihanem/pkg/audit"
)

// AuditLogger creates a middleware that automatically logs HTTP requests
func AuditLogger(logger *audit.Logger) fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Skip health check and metrics endpoints
		if isHealthCheckPath(c.Path()) || c.Path() == "/metrics" {
			return c.Next()
		}

		// Get tenant from context (if available)
		var tenantID string
		tenant, err := GetTenantFromContext(c)
		if err == nil {
			tenantID = tenant.ID
		}

		// Continue with request
		err = c.Next()

		// Only log if tenant is available (skip public endpoints)
		if tenantID == "" {
			return err
		}

		// Determine audit action based on method and path
		action := determineAuditAction(c.Method(), c.Path())
		if action == "" {
			// Not an auditable action
			return err
		}

		// Create audit log
		log := entity.NewAuditLog(tenantID, entity.AuditAction(action))

		// Add user ID if authenticated
		if userID := c.Locals("user_id"); userID != nil {
			if uid, ok := userID.(string); ok {
				log.WithUser(uid)
			}
		}

		// Add request metadata
		log.WithRequest(c.IP(), c.Get("User-Agent"))

		// Determine severity based on action
		severity := determineSeverity(action, c.Method())
		log.WithSeverity(severity)

		// Add success/failure based on status code
		if c.Response().StatusCode() >= 400 {
			log.Success = false
		}

		// Log asynchronously (non-blocking)
		logger.LogAsync(log)

		return err
	}
}

// determineAuditAction maps HTTP method and path to audit action
func determineAuditAction(method, path string) string {
	// Authentication actions
	if path == "/api/v1/auth/login" {
		if method == "POST" {
			return string(entity.AuditActionLogin)
		}
	}
	if path == "/api/v1/auth/logout" {
		return string(entity.AuditActionLogout)
	}
	if path == "/api/v1/auth/change-password" {
		return string(entity.AuditActionPasswordChange)
	}

	// Content actions
	if method == "POST" && matchesPattern(path, "/api/v1/content") {
		return string(entity.AuditActionContentCreate)
	}
	if method == "PUT" && matchesPattern(path, "/api/v1/content/*") {
		return string(entity.AuditActionContentUpdate)
	}
	if method == "DELETE" && matchesPattern(path, "/api/v1/content/*") {
		return string(entity.AuditActionContentDelete)
	}
	if method == "PATCH" && matchesPattern(path, "/api/v1/content/*/publish") {
		return string(entity.AuditActionContentPublish)
	}

	// User management actions
	if method == "POST" && matchesPattern(path, "/api/v1/users") {
		return string(entity.AuditActionUserCreate)
	}
	if method == "PUT" && matchesPattern(path, "/api/v1/users/*") {
		return string(entity.AuditActionUserUpdate)
	}
	if method == "DELETE" && matchesPattern(path, "/api/v1/users/*") {
		return string(entity.AuditActionUserDelete)
	}

	// Media actions
	if method == "POST" && matchesPattern(path, "/api/v1/media/upload") {
		return string(entity.AuditActionMediaUpload)
	}
	if method == "DELETE" && matchesPattern(path, "/api/v1/media/*") {
		return string(entity.AuditActionMediaDelete)
	}

	// Not an auditable action
	return ""
}

// determineSeverity determines the severity level based on action and method
func determineSeverity(action, method string) entity.AuditSeverity {
	// Critical actions (security-sensitive)
	criticalActions := []string{
		string(entity.AuditActionLogin),
		string(entity.AuditActionLoginFailed),
		string(entity.AuditActionPasswordChange),
		string(entity.AuditActionUserRoleChange),
		string(entity.AuditActionUserDelete),
		string(entity.AuditActionTenantDeactivate),
	}

	for _, critical := range criticalActions {
		if action == critical {
			return entity.AuditSeverityCritical
		}
	}

	// Warning for DELETE operations
	if method == "DELETE" {
		return entity.AuditSeverityWarning
	}

	// Default to info
	return entity.AuditSeverityInfo
}

// matchesPattern checks if path matches a simple pattern (* is wildcard)
func matchesPattern(path, pattern string) bool {
	// Simple pattern matching (can be improved with regex if needed)
	if pattern == path {
		return true
	}

	// Handle wildcard at end
	if len(pattern) > 0 && pattern[len(pattern)-1] == '*' {
		prefix := pattern[:len(pattern)-1]
		return len(path) >= len(prefix) && path[:len(prefix)] == prefix
	}

	return false
}

// Helper function to create audit logs manually in handlers
func LogAudit(c *fiber.Ctx, logger *audit.Logger, action entity.AuditAction) {
	tenant, err := GetTenantFromContext(c)
	if err != nil {
		return // Skip if no tenant context
	}

	log := entity.NewAuditLog(tenant.ID, action)

	// Add user if authenticated
	if userID := c.Locals("user_id"); userID != nil {
		if uid, ok := userID.(string); ok {
			log.WithUser(uid)
		}
	}

	// Add request metadata
	log.WithRequest(c.IP(), c.Get("User-Agent"))

	// Log asynchronously
	logger.LogAsync(log)
}

// LogAuditWithResource logs an audit event with resource information
func LogAuditWithResource(
	c *fiber.Ctx,
	logger *audit.Logger,
	action entity.AuditAction,
	resourceType, resourceID string,
) {
	tenant, err := GetTenantFromContext(c)
	if err != nil {
		return
	}

	log := entity.NewAuditLog(tenant.ID, action).
		WithResource(resourceType, resourceID).
		WithRequest(c.IP(), c.Get("User-Agent"))

	if userID := c.Locals("user_id"); userID != nil {
		if uid, ok := userID.(string); ok {
			log.WithUser(uid)
		}
	}

	logger.LogAsync(log)
}
