package middleware

import (
	"context"
	"fmt"
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
	"github.com/mehmetkilic/yazihanem/internal/domain/repository"
	"github.com/mehmetkilic/yazihanem/pkg/tenant"
)

// TenantResolver resolves tenant from request and adds to context
type TenantResolver struct {
	tenantRepo repository.TenantRepository
}

// NewTenantResolver creates a new tenant resolver middleware
func NewTenantResolver(tenantRepo repository.TenantRepository) *TenantResolver {
	return &TenantResolver{
		tenantRepo: tenantRepo,
	}
}

// Resolve is the middleware function that resolves tenant from request
func (tr *TenantResolver) Resolve() fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Extract domain from request host
		host := c.Hostname()
		domain := extractDomain(host)

		// Skip tenant resolution for health check endpoints
		if isHealthCheckPath(c.Path()) {
			return c.Next()
		}

		// For development: Create a default tenant for localhost
		ctx := context.Background()
		var tenantEntity *entity.Tenant

		if domain == "localhost" || domain == "127.0.0.1" {
			// Default tenant for development
			tenantEntity = &entity.Tenant{
				ID:         "4941a382-948a-48b4-91ec-a83270feca7c",
				Name:       "Demo Tenant",
				Domain:     "localhost",
				SchemaName: "tenant_default",
				IsActive:   true,
			}
		} else {
			// Try to resolve tenant by domain
			var err error
			tenantEntity, err = tr.tenantRepo.GetByDomain(ctx, domain)
			if err != nil {
				return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
					"error": "Tenant not found",
					"message": fmt.Sprintf("No tenant found for domain: %s", domain),
				})
			}

			// Check if tenant is active
			if !tenantEntity.IsActive {
				return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
					"error": "Tenant inactive",
					"message": "This tenant account is currently inactive",
				})
			}
		}

		// Add tenant to request context
		c.Locals("tenant", tenantEntity)

		// Also set in Go context for use in services
		ctx = tenant.SetTenantInContext(ctx, tenantEntity)
		c.SetUserContext(ctx)

		return c.Next()
	}
}

// GetTenantFromContext retrieves tenant from fiber context
func GetTenantFromContext(c *fiber.Ctx) (*entity.Tenant, error) {
	tenantValue := c.Locals("tenant")
	if tenantValue == nil {
		return nil, fmt.Errorf("tenant not found in context")
	}

	tenantEntity, ok := tenantValue.(*entity.Tenant)
	if !ok {
		return nil, fmt.Errorf("invalid tenant type in context")
	}

	return tenantEntity, nil
}

// RequireTenant is a middleware that ensures tenant exists in context
func RequireTenant() fiber.Handler {
	return func(c *fiber.Ctx) error {
		_, err := GetTenantFromContext(c)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Tenant required",
				"message": "This endpoint requires a valid tenant context",
			})
		}
		return c.Next()
	}
}

// extractDomain extracts domain from host, removing port if present
func extractDomain(host string) string {
	// Remove port if present
	if colonIdx := strings.LastIndex(host, ":"); colonIdx != -1 {
		host = host[:colonIdx]
	}

	// For localhost, return as-is
	if host == "localhost" || host == "127.0.0.1" {
		return "localhost"
	}

	return host
}

// isHealthCheckPath checks if the path is a health check endpoint
func isHealthCheckPath(path string) bool {
	healthPaths := []string{"/health", "/healthz", "/ready", "/live", "/metrics"}
	for _, hp := range healthPaths {
		if path == hp {
			return true
		}
	}
	return false
}
