package entity

import (
	"time"
)

// User represents a user within a tenant
type User struct {
	ID        string    `json:"id"`
	TenantID  string    `json:"tenant_id"`
	Email     string    `json:"email"`
	Password  string    `json:"-"` // Never expose in JSON
	FirstName string    `json:"first_name"`
	LastName  string    `json:"last_name"`
	Role      UserRole  `json:"role"`
	IsActive  bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// UserRole defines user permission levels
type UserRole string

const (
	RoleAdmin  UserRole = "admin"
	RoleEditor UserRole = "editor"
	RoleViewer UserRole = "viewer"
)

// Validate validates user data
func (u *User) Validate() error {
	if u.Email == "" {
		return ErrInvalidEmail
	}
	if u.TenantID == "" {
		return ErrInvalidTenantID
	}
	if u.Role != RoleAdmin && u.Role != RoleEditor && u.Role != RoleViewer {
		return ErrInvalidRole
	}
	return nil
}
