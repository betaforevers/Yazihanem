package entity

import (
	"time"
)

// Tenant represents a tenant in the multi-tenant system
type Tenant struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	SchemaName  string    `json:"schema_name"`
	Domain      string    `json:"domain"`
	IsActive    bool      `json:"is_active"`
	MaxUsers    int       `json:"max_users"`
	MaxStorage  int64     `json:"max_storage"` // in bytes
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// Validate validates tenant data
func (t *Tenant) Validate() error {
	if t.Name == "" {
		return ErrInvalidTenantName
	}
	if t.SchemaName == "" {
		return ErrInvalidSchemaName
	}
	if t.Domain == "" {
		return ErrInvalidDomain
	}
	return nil
}
