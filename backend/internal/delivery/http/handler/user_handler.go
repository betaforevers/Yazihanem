package handler

import (
	"github.com/gofiber/fiber/v2"
	"github.com/mehmetkilic/yazihanem/internal/delivery/http/middleware"
	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
	"github.com/mehmetkilic/yazihanem/internal/domain/repository"
	"github.com/mehmetkilic/yazihanem/pkg/audit"
	"github.com/mehmetkilic/yazihanem/pkg/auth"
	"github.com/mehmetkilic/yazihanem/pkg/tenant"
)

// UserHandler handles user management endpoints
type UserHandler struct {
	userRepo    repository.UserRepository
	auditLogger *audit.Logger
}

// NewUserHandler creates a new user handler
func NewUserHandler(userRepo repository.UserRepository, auditLogger *audit.Logger) *UserHandler {
	return &UserHandler{
		userRepo:    userRepo,
		auditLogger: auditLogger,
	}
}

// CreateUserRequest represents user creation request
type CreateUserRequest struct {
	Email     string `json:"email" validate:"required,email"`
	Password  string `json:"password" validate:"required,min=8"`
	FirstName string `json:"first_name" validate:"required"`
	LastName  string `json:"last_name" validate:"required"`
	Role      string `json:"role" validate:"required,oneof=admin editor viewer"`
}

// UpdateUserRequest represents user update request
type UpdateUserRequest struct {
	Email     *string `json:"email,omitempty" validate:"omitempty,email"`
	FirstName *string `json:"first_name,omitempty"`
	LastName  *string `json:"last_name,omitempty"`
	Role      *string `json:"role,omitempty" validate:"omitempty,oneof=admin editor viewer"`
}

// CreateUser creates a new user (admin only)
func (h *UserHandler) CreateUser(c *fiber.Ctx) error {
	var req CreateUserRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "Invalid request body",
		})
	}

	// Get tenant from context
	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	// Hash password
	passwordHash, err := auth.HashPassword(req.Password)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to hash password",
		})
	}

	// Create user entity
	user := &entity.User{
		TenantID:     tenantEntity.ID,
		Email:        req.Email,
		PasswordHash: passwordHash,
		FirstName:    req.FirstName,
		LastName:     req.LastName,
		Role:         entity.UserRole(req.Role),
		IsActive:     true,
	}

	// Validate user
	if err := user.Validate(); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": err.Error(),
		})
	}

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Create user in database
	if err := h.userRepo.Create(ctx, user); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to create user",
		})
	}

	// Log audit event
	middleware.LogAuditWithResource(c, h.auditLogger, entity.AuditActionUserCreate, "user", user.ID)

	// Remove password hash from response
	user.PasswordHash = ""

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"message": "User created successfully",
		"user":    user,
	})
}

// GetUser retrieves user by ID
func (h *UserHandler) GetUser(c *fiber.Ctx) error {
	userID := c.Params("id")
	if userID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "User ID is required",
		})
	}

	// Get tenant from context
	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Get user from database
	user, err := h.userRepo.GetByID(ctx, tenantEntity.ID, userID)
	if err != nil {
		if err == entity.ErrUserNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"error":   "Not Found",
				"message": "User not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to get user",
		})
	}

	// Remove password hash from response
	user.PasswordHash = ""

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"user": user,
	})
}

// UpdateUser updates existing user (admin only)
func (h *UserHandler) UpdateUser(c *fiber.Ctx) error {
	userID := c.Params("id")
	if userID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "User ID is required",
		})
	}

	var req UpdateUserRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "Invalid request body",
		})
	}

	// Get tenant from context
	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Get existing user
	user, err := h.userRepo.GetByID(ctx, tenantEntity.ID, userID)
	if err != nil {
		if err == entity.ErrUserNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"error":   "Not Found",
				"message": "User not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to get user",
		})
	}

	// Update fields if provided
	if req.Email != nil {
		user.Email = *req.Email
	}
	if req.FirstName != nil {
		user.FirstName = *req.FirstName
	}
	if req.LastName != nil {
		user.LastName = *req.LastName
	}
	if req.Role != nil {
		user.Role = entity.UserRole(*req.Role)
	}

	// Validate updated user
	if err := user.Validate(); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": err.Error(),
		})
	}

	// Update user in database
	if err := h.userRepo.Update(ctx, user); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to update user",
		})
	}

	// Log audit event
	middleware.LogAuditWithResource(c, h.auditLogger, entity.AuditActionUserUpdate, "user", user.ID)

	// Remove password hash from response
	user.PasswordHash = ""

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "User updated successfully",
		"user":    user,
	})
}

// DeleteUser deletes user by ID (admin only)
func (h *UserHandler) DeleteUser(c *fiber.Ctx) error {
	userID := c.Params("id")
	if userID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "User ID is required",
		})
	}

	// Get tenant and current user from context
	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	claims, err := middleware.GetUserClaimsFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	// Prevent self-deletion
	if claims.UserID == userID {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "Forbidden",
			"message": "You cannot delete yourself",
		})
	}

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Check if user exists
	_, err = h.userRepo.GetByID(ctx, tenantEntity.ID, userID)
	if err != nil {
		if err == entity.ErrUserNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"error":   "Not Found",
				"message": "User not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to get user",
		})
	}

	// Delete user from database
	if err := h.userRepo.Delete(ctx, tenantEntity.ID, userID); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to delete user",
		})
	}

	// Log audit event
	middleware.LogAuditWithResource(c, h.auditLogger, entity.AuditActionUserDelete, "user", userID)

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "User deleted successfully",
	})
}

// ListUsers retrieves user list with pagination (admin only)
func (h *UserHandler) ListUsers(c *fiber.Ctx) error {
	// Get tenant from context
	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	// Parse query parameters
	page := c.QueryInt("page", 1)
	pageSize := c.QueryInt("page_size", 20)

	// Validate page size
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	offset := (page - 1) * pageSize

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Get user list from database
	users, err := h.userRepo.List(ctx, tenantEntity.ID, offset, pageSize)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to list users",
		})
	}

	// Get total count
	totalCount, err := h.userRepo.Count(ctx, tenantEntity.ID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to count users",
		})
	}

	// Remove password hashes from response
	for _, user := range users {
		user.PasswordHash = ""
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"users":       users,
		"page":        page,
		"page_size":   pageSize,
		"total_count": totalCount,
	})
}

// ActivateUser activates a user (admin only)
func (h *UserHandler) ActivateUser(c *fiber.Ctx) error {
	userID := c.Params("id")
	if userID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "User ID is required",
		})
	}

	// Get tenant from context
	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Activate user
	if err := h.userRepo.SetActive(ctx, tenantEntity.ID, userID, true); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to activate user",
		})
	}

	// Log audit event
	middleware.LogAuditWithResource(c, h.auditLogger, entity.AuditActionUserActivate, "user", userID)

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "User activated successfully",
	})
}

// DeactivateUser deactivates a user (admin only)
func (h *UserHandler) DeactivateUser(c *fiber.Ctx) error {
	userID := c.Params("id")
	if userID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "User ID is required",
		})
	}

	// Get tenant and current user from context
	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	claims, err := middleware.GetUserClaimsFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	// Prevent self-deactivation
	if claims.UserID == userID {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "Forbidden",
			"message": "You cannot deactivate yourself",
		})
	}

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Deactivate user
	if err := h.userRepo.SetActive(ctx, tenantEntity.ID, userID, false); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to deactivate user",
		})
	}

	// Log audit event
	middleware.LogAuditWithResource(c, h.auditLogger, entity.AuditActionUserDeactivate, "user", userID)

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "User deactivated successfully",
	})
}
