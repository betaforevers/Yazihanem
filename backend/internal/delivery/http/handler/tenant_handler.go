package handler

import (
	"context"

	"github.com/gofiber/fiber/v2"
	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
	"github.com/mehmetkilic/yazihanem/internal/domain/repository"
	"github.com/mehmetkilic/yazihanem/pkg/audit"
	"github.com/mehmetkilic/yazihanem/pkg/auth"
	"github.com/mehmetkilic/yazihanem/pkg/tenant"
)

// TenantHandler handles tenant onboarding and management endpoints
type TenantHandler struct {
	tenantRepo  repository.TenantRepository
	userRepo    repository.UserRepository
	auditLogger *audit.Logger
}

// NewTenantHandler creates a new tenant handler
func NewTenantHandler(
	tenantRepo repository.TenantRepository,
	userRepo repository.UserRepository,
	auditLogger *audit.Logger,
) *TenantHandler {
	return &TenantHandler{
		tenantRepo:  tenantRepo,
		userRepo:    userRepo,
		auditLogger: auditLogger,
	}
}

// RegisterTenantRequest represents tenant registration request
type RegisterTenantRequest struct {
	// Tenant information
	TenantName string `json:"tenant_name" validate:"required,min=2,max=100"`
	Domain     string `json:"domain" validate:"omitempty,min=3,max=100"` // Optional for localhost dev

	// Owner information
	OwnerEmail     string `json:"owner_email" validate:"required,email"`
	OwnerPassword  string `json:"owner_password" validate:"required,min=8"`
	OwnerFirstName string `json:"owner_first_name" validate:"required"`
	OwnerLastName  string `json:"owner_last_name" validate:"required"`
}

// RegisterTenant handles new tenant registration (public endpoint)
func (h *TenantHandler) RegisterTenant(c *fiber.Ctx) error {
	var req RegisterTenantRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "Invalid request body",
		})
	}

	// Create tenant entity
	tenant := entity.NewTenant(req.TenantName, req.Domain)

	// Validate tenant
	if err := tenant.Validate(); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": err.Error(),
		})
	}

	ctx := c.UserContext()

	// Check if domain already exists (only if domain is provided)
	if req.Domain != "" {
		existingTenant, err := h.tenantRepo.GetByDomain(ctx, req.Domain)
		if err == nil && existingTenant != nil {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"error":   "Conflict",
				"message": "Domain already exists",
			})
		}
	}

	// Create tenant (this will also create the schema and tables)
	if err := h.tenantRepo.Create(ctx, tenant); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to create tenant",
		})
	}

	// Hash owner password
	passwordHash, err := auth.HashPassword(req.OwnerPassword)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to hash password",
		})
	}

	// Create owner user
	owner := &entity.User{
		TenantID:     tenant.ID,
		Email:        req.OwnerEmail,
		PasswordHash: passwordHash,
		FirstName:    req.OwnerFirstName,
		LastName:     req.OwnerLastName,
		Role:         entity.RoleAdmin, // Owner gets admin role
		IsActive:     true,
	}

	// Validate owner
	if err := owner.Validate(); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": err.Error(),
		})
	}

	// Set tenant context for user creation
	ctx = c.UserContext()
	// Note: We need to manually set tenant in context since this is a public endpoint
	// The tenant middleware won't run for this endpoint

	// Create owner user in the tenant schema
	// We'll need to use a special method that doesn't require tenant middleware
	if err := h.createFirstUser(ctx, tenant, owner); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to create owner user",
		})
	}

	// Log audit event for tenant creation
	auditLog := entity.NewAuditLog(tenant.ID, entity.AuditActionTenantCreate).
		WithResource("tenant", tenant.ID).
		WithRequest(c.IP(), c.Get("User-Agent")).
		WithMetadata("domain", tenant.Domain).
		WithMetadata("owner_email", owner.Email)

	h.auditLogger.LogAsync(auditLog)

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"message": "Tenant registered successfully",
		"tenant": fiber.Map{
			"id":     tenant.ID,
			"name":   tenant.Name,
			"domain": tenant.Domain,
		},
		"owner": fiber.Map{
			"id":         owner.ID,
			"email":      owner.Email,
			"first_name": owner.FirstName,
			"last_name":  owner.LastName,
		},
	})
}

// createFirstUser creates the first user in a tenant schema
// This is a special method used during tenant onboarding
func (h *TenantHandler) createFirstUser(ctx context.Context, ten *entity.Tenant, user *entity.User) error {
	// Manually set tenant context for user creation
	tCtx := tenant.SetTenantInContext(ctx, ten)

	// Create user in the tenant schema
	return h.userRepo.Create(tCtx, user)
}
