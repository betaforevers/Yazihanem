package repository

import (
	"context"

	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
)

// TenantRepository defines operations for tenant persistence
type TenantRepository interface {
	Create(ctx context.Context, tenant *entity.Tenant) error
	GetByID(ctx context.Context, id string) (*entity.Tenant, error)
	GetByDomain(ctx context.Context, domain string) (*entity.Tenant, error)
	GetBySchemaName(ctx context.Context, schemaName string) (*entity.Tenant, error)
	Update(ctx context.Context, tenant *entity.Tenant) error
	Delete(ctx context.Context, id string) error
	List(ctx context.Context, offset, limit int) ([]*entity.Tenant, error)
}
