package tenant

import (
	"context"

	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
)

// contextKey is a custom type for context keys to avoid collisions
type contextKey string

const (
	// TenantContextKey is the key for storing tenant in context
	TenantContextKey contextKey = "tenant"
)

// SetTenantInContext adds tenant to context
func SetTenantInContext(ctx context.Context, tenant *entity.Tenant) context.Context {
	return context.WithValue(ctx, TenantContextKey, tenant)
}

// GetTenantFromContext retrieves tenant from context
func GetTenantFromContext(ctx context.Context) (*entity.Tenant, bool) {
	tenant, ok := ctx.Value(TenantContextKey).(*entity.Tenant)
	return tenant, ok
}

// GetSchemaFromContext retrieves tenant schema name from context
func GetSchemaFromContext(ctx context.Context) (string, bool) {
	tenant, ok := GetTenantFromContext(ctx)
	if !ok {
		return "", false
	}
	return tenant.SchemaName, true
}

// MustGetTenantFromContext retrieves tenant from context or panics
// Use this only when you're certain tenant exists (e.g., after middleware)
func MustGetTenantFromContext(ctx context.Context) *entity.Tenant {
	tenant, ok := GetTenantFromContext(ctx)
	if !ok {
		panic("tenant not found in context")
	}
	return tenant
}
