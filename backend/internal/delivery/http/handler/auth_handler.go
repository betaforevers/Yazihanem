package handler

import (
	"context"
	"fmt"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/mehmetkilic/yazihanem/internal/delivery/http/middleware"
	"github.com/mehmetkilic/yazihanem/internal/domain/repository"
	infraCache "github.com/mehmetkilic/yazihanem/internal/infrastructure/cache"
	"github.com/mehmetkilic/yazihanem/pkg/auth"
	"github.com/mehmetkilic/yazihanem/pkg/tenant"
)

// AuthHandler handles authentication endpoints
type AuthHandler struct {
	jwtManager     *auth.JWTManager
	sessionManager *infraCache.SessionManager
	userRepository repository.UserRepository
}

// NewAuthHandler creates a new authentication handler
func NewAuthHandler(jwtManager *auth.JWTManager, sessionManager *infraCache.SessionManager, userRepo repository.UserRepository) *AuthHandler {
	return &AuthHandler{
		jwtManager:     jwtManager,
		sessionManager: sessionManager,
		userRepository: userRepo,
	}
}

// LoginRequest represents login request payload
type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=8"`
}

// LoginResponse represents login response
type LoginResponse struct {
	AccessToken  string                 `json:"access_token"`
	RefreshToken string                 `json:"refresh_token,omitempty"`
	ExpiresIn    int64                  `json:"expires_in"`
	TokenType    string                 `json:"token_type"`
	User         map[string]interface{} `json:"user"`
}

// Login handles user login
func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var req LoginRequest
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
			"error":   "Unauthorized",
			"message": "Tenant not found",
		})
	}

	// Get user from Fiber context and set tenant in Go context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Fetch user from database by email
	user, err := h.userRepository.GetByEmail(ctx, tenantEntity.ID, req.Email)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error":   "Unauthorized",
			"message": "Invalid credentials",
		})
	}

	// Verify user is active
	if !user.IsActive {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "Forbidden",
			"message": "User account is inactive",
		})
	}

	// Verify password
	if err := auth.VerifyPassword(user.PasswordHash, req.Password); err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error":   "Unauthorized",
			"message": "Invalid credentials",
		})
	}

	// Update last login timestamp
	_ = h.userRepository.UpdateLastLogin(ctx, tenantEntity.ID, user.ID)

	// Generate JWT token
	token, err := h.jwtManager.GenerateToken(user.ID, tenantEntity.ID, user.Email, string(user.Role))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to generate token",
		})
	}

	// Create session
	sessionID := uuid.New().String()
	sessionData := &infraCache.SessionData{
		UserID:   user.ID,
		TenantID: tenantEntity.ID,
		Email:    user.Email,
		Role:     string(user.Role),
		Metadata: map[string]interface{}{
			"ip":         c.IP(),
			"user_agent": c.Get("User-Agent"),
			"login_at":   time.Now(),
		},
	}

	sessionCtx := context.Background()
	if err := h.sessionManager.Create(sessionCtx, sessionID, sessionData); err != nil {
		// Log error but don't fail the request
		fmt.Printf("Failed to create session: %v\n", err)
	}

	// Get token expiry
	expiry, _ := h.jwtManager.GetTokenExpiry(token)
	expiresIn := time.Until(expiry).Seconds()

	return c.Status(fiber.StatusOK).JSON(LoginResponse{
		AccessToken: token,
		ExpiresIn:   int64(expiresIn),
		TokenType:   "Bearer",
		User: map[string]interface{}{
			"id":         user.ID,
			"email":      user.Email,
			"first_name": user.FirstName,
			"last_name":  user.LastName,
			"role":       user.Role,
			"tenant":     tenantEntity.Name,
		},
	})
}

// Logout handles user logout
func (h *AuthHandler) Logout(c *fiber.Ctx) error {
	// Get user claims from context
	claims, err := middleware.GetUserClaimsFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	// Delete session
	// In production, you'd need to track sessionID properly
	// For now, this is a placeholder
	ctx := context.Background()
	if err := h.sessionManager.DeleteAllForUser(ctx, claims.UserID); err != nil {
		// Log error but don't fail the request
		fmt.Printf("Failed to delete session: %v\n", err)
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "Logged out successfully",
	})
}

// RefreshToken handles token refresh
func (h *AuthHandler) RefreshToken(c *fiber.Ctx) error {
	// Get current token from header
	authHeader := c.Get("Authorization")
	token, err := auth.ExtractTokenFromHeader(authHeader)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error":   "Unauthorized",
			"message": err.Error(),
		})
	}

	// Generate new token
	newToken, err := h.jwtManager.RefreshToken(token)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error":   "Unauthorized",
			"message": "Failed to refresh token",
		})
	}

	// Get token expiry
	expiry, _ := h.jwtManager.GetTokenExpiry(newToken)
	expiresIn := time.Until(expiry).Seconds()

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"access_token": newToken,
		"expires_in":   int64(expiresIn),
		"token_type":   "Bearer",
	})
}

// Me returns current user information
func (h *AuthHandler) Me(c *fiber.Ctx) error {
	claims, err := middleware.GetUserClaimsFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	tenant, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"user": map[string]interface{}{
			"id":     claims.UserID,
			"email":  claims.Email,
			"role":   claims.Role,
			"tenant": tenant.Name,
		},
	})
}

// ChangePassword handles password change
func (h *AuthHandler) ChangePassword(c *fiber.Ctx) error {
	type ChangePasswordRequest struct {
		OldPassword string `json:"old_password" validate:"required"`
		NewPassword string `json:"new_password" validate:"required,min=8"`
	}

	var req ChangePasswordRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "Invalid request body",
		})
	}

	// Validate new password strength
	if err := auth.ValidatePasswordStrength(req.NewPassword); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": err.Error(),
		})
	}

	// Get user and tenant from context
	claims, err := middleware.GetUserClaimsFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	tenantEntity, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	// Set tenant context
	ctx := c.UserContext()
	ctx = tenant.SetTenantInContext(ctx, tenantEntity)

	// Fetch current user from database
	user, err := h.userRepository.GetByID(ctx, tenantEntity.ID, claims.UserID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error":   "Not Found",
			"message": "User not found",
		})
	}

	// Verify old password
	if err := auth.VerifyPassword(user.PasswordHash, req.OldPassword); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "Bad Request",
			"message": "Current password is incorrect",
		})
	}

	// Hash new password
	newPasswordHash, err := auth.HashPassword(req.NewPassword)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to hash password",
		})
	}

	// Update password in database
	if err := h.userRepository.UpdatePassword(ctx, tenantEntity.ID, user.ID, newPasswordHash); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to update password",
		})
	}

	// Invalidate all sessions for this user
	sessionCtx := context.Background()
	_ = h.sessionManager.DeleteAllForUser(sessionCtx, user.ID)

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "Password changed successfully",
		"user_id": user.ID,
	})
}
