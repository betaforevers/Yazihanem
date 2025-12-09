package database

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
	"github.com/mehmetkilic/yazihanem/internal/domain/repository"
	"github.com/mehmetkilic/yazihanem/internal/infrastructure/database/sqlc/generated"
)

// TenantRepositoryImpl implements repository.TenantRepository using sqlc
type TenantRepositoryImpl struct {
	pool    *pgxpool.Pool
	queries *generated.Queries
}

// NewTenantRepository creates a new tenant repository
func NewTenantRepository(pool *pgxpool.Pool) repository.TenantRepository {
	return &TenantRepositoryImpl{
		pool:    pool,
		queries: generated.New(pool),
	}
}

// Create creates a new tenant
func (r *TenantRepositoryImpl) Create(ctx context.Context, tenant *entity.Tenant) error {
	params := generated.CreateTenantParams{
		Name:       tenant.Name,
		SchemaName: tenant.SchemaName,
		Domain:     tenant.Domain,
		IsActive:   tenant.IsActive,
		MaxUsers:   int32(tenant.MaxUsers),
		MaxStorage: tenant.MaxStorage,
	}

	row, err := r.queries.CreateTenant(ctx, params)
	if err != nil {
		return fmt.Errorf("failed to create tenant: %w", err)
	}

	// Update tenant with generated values
	tenant.ID = row.ID.String()
	tenant.CreatedAt = row.CreatedAt
	tenant.UpdatedAt = row.UpdatedAt

	return nil
}

// GetByID retrieves a tenant by ID
func (r *TenantRepositoryImpl) GetByID(ctx context.Context, id string) (*entity.Tenant, error) {
	tenantID, err := uuid.Parse(id)
	if err != nil {
		return nil, fmt.Errorf("invalid tenant ID: %w", err)
	}

	row, err := r.queries.GetTenantByID(ctx, tenantID)
	if err != nil {
		return nil, fmt.Errorf("failed to get tenant: %w", err)
	}

	return mapTenantRowToEntity(row), nil
}

// GetByDomain retrieves an active tenant by domain
func (r *TenantRepositoryImpl) GetByDomain(ctx context.Context, domain string) (*entity.Tenant, error) {
	row, err := r.queries.GetTenantByDomain(ctx, domain)
	if err != nil {
		return nil, fmt.Errorf("failed to get tenant by domain: %w", err)
	}

	return mapTenantRowToEntity(row), nil
}

// GetBySchemaName retrieves a tenant by schema name
func (r *TenantRepositoryImpl) GetBySchemaName(ctx context.Context, schemaName string) (*entity.Tenant, error) {
	row, err := r.queries.GetTenantBySchemaName(ctx, schemaName)
	if err != nil {
		return nil, fmt.Errorf("failed to get tenant by schema name: %w", err)
	}

	return mapTenantRowToEntity(row), nil
}

// Update updates a tenant
func (r *TenantRepositoryImpl) Update(ctx context.Context, tenant *entity.Tenant) error {
	tenantID, err := uuid.Parse(tenant.ID)
	if err != nil {
		return fmt.Errorf("invalid tenant ID: %w", err)
	}

	params := generated.UpdateTenantParams{
		ID:         tenantID,
		Name:       &tenant.Name,
		Domain:     &tenant.Domain,
		IsActive:   &tenant.IsActive,
		MaxUsers:   toInt32Ptr(int32(tenant.MaxUsers)),
		MaxStorage: &tenant.MaxStorage,
	}

	row, err := r.queries.UpdateTenant(ctx, params)
	if err != nil {
		return fmt.Errorf("failed to update tenant: %w", err)
	}

	// Update tenant with new timestamp
	tenant.UpdatedAt = row.UpdatedAt

	return nil
}

// Delete deletes a tenant
func (r *TenantRepositoryImpl) Delete(ctx context.Context, id string) error {
	tenantID, err := uuid.Parse(id)
	if err != nil {
		return fmt.Errorf("invalid tenant ID: %w", err)
	}

	err = r.queries.DeleteTenant(ctx, tenantID)
	if err != nil {
		return fmt.Errorf("failed to delete tenant: %w", err)
	}

	return nil
}

// List retrieves a list of tenants with pagination
func (r *TenantRepositoryImpl) List(ctx context.Context, offset, limit int) ([]*entity.Tenant, error) {
	params := generated.ListTenantsParams{
		Limit:  int32(limit),
		Offset: int32(offset),
	}

	rows, err := r.queries.ListTenants(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("failed to list tenants: %w", err)
	}

	tenants := make([]*entity.Tenant, len(rows))
	for i, row := range rows {
		tenants[i] = mapTenantRowToEntity(row)
	}

	return tenants, nil
}

// Helper function to map sqlc row to entity
func mapTenantRowToEntity(row *generated.Tenant) *entity.Tenant {
	return &entity.Tenant{
		ID:          row.ID.String(),
		Name:        row.Name,
		SchemaName:  row.SchemaName,
		Domain:      row.Domain,
		IsActive:    row.IsActive,
		MaxUsers:    int(row.MaxUsers),
		MaxStorage:  row.MaxStorage,
		CreatedAt:   row.CreatedAt,
		UpdatedAt:   row.UpdatedAt,
	}
}

// Helper function to convert int32 to *int32
func toInt32Ptr(v int32) *int32 {
	return &v
}
