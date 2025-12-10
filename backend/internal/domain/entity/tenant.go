package entity

import (
	"fmt"
	"regexp"
	"strings"
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

// NewTenant creates a new tenant with generated schema name
func NewTenant(name, domain string) *Tenant {
	// Generate schema name from domain (remove special chars, lowercase)
	schemaName := generateSchemaName(domain)

	return &Tenant{
		Name:       name,
		SchemaName: schemaName,
		Domain:     domain,
		IsActive:   true,
		MaxUsers:   10,        // Default: 10 users per tenant
		MaxStorage: 1073741824, // Default: 1GB storage
	}
}

// generateSchemaName generates a valid PostgreSQL schema name from domain
func generateSchemaName(domain string) string {
	// Remove protocol if present
	domain = strings.TrimPrefix(domain, "http://")
	domain = strings.TrimPrefix(domain, "https://")

	// Remove www. prefix
	domain = strings.TrimPrefix(domain, "www.")

	// Take only the domain name (before first dot or entire string)
	parts := strings.Split(domain, ".")
	name := parts[0]

	// Replace invalid characters with underscore
	reg := regexp.MustCompile("[^a-z0-9_]")
	name = reg.ReplaceAllString(strings.ToLower(name), "_")

	// Ensure it starts with letter or underscore
	if len(name) > 0 && name[0] >= '0' && name[0] <= '9' {
		name = "_" + name
	}

	// Prefix with tenant_
	return fmt.Sprintf("tenant_%s", name)
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
