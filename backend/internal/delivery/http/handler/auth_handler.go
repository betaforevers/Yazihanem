package handler

import (
	"context"
	"fmt"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/mehmetkilic/yazihanem/internal/delivery/http/middleware"
	infraCache "github.com/mehmetkilic/yazihanem/internal/infrastructure/cache"
	"github.com/mehmetkilic/yazihanem/pkg/auth"
)

// AuthHandler handles authentication endpoints
type AuthHandler struct {
	jwtManager     *auth.JWTManager
	sessionManager *infraCache.SessionManager
	// userRepository will be added when user repository is implemented
}

// NewAuthHandler creates a new authentication handler
func NewAuthHandler(jwtManager *auth.JWTManager, sessionManager *infraCache.SessionManager) *AuthHandler {
	return &AuthHandler{
		jwtManager:     jwtManager,
		sessionManager: sessionManager,
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
	tenant, err := middleware.GetTenantFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error":   "Unauthorized",
			"message": "Tenant not found",
		})
	}

	// TODO: Implement actual user authentication with database
	// For now, this is a placeholder that demonstrates the flow

	// Mock user data - replace with actual database lookup
	mockUserID := uuid.New().String()
	mockRole := "admin"

	// Validate password (placeholder)
	// In production: fetch user from DB and verify password hash
	// hashedPassword := user.PasswordHash
	// if err := auth.VerifyPassword(hashedPassword, req.Password); err != nil {
	//     return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
	//         "error": "Invalid credentials",
	//     })
	// }

	// Generate JWT token
	token, err := h.jwtManager.GenerateToken(mockUserID, tenant.ID, req.Email, mockRole)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Internal Server Error",
			"message": "Failed to generate token",
		})
	}

	// Create session
	sessionID := uuid.New().String()
	sessionData := &infraCache.SessionData{
		UserID:   mockUserID,
		TenantID: tenant.ID,
		Email:    req.Email,
		Role:     mockRole,
		Metadata: map[string]interface{}{
			"ip":         c.IP(),
			"user_agent": c.Get("User-Agent"),
			"login_at":   time.Now(),
		},
	}

	ctx := context.Background()
	if err := h.sessionManager.Create(ctx, sessionID, sessionData); err != nil {
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
			"id":     mockUserID,
			"email":  req.Email,
			"role":   mockRole,
			"tenant": tenant.Name,
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

	// Get user from context
	claims, err := middleware.GetUserClaimsFromContext(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}

	// TODO: Implement actual password change with database
	// 1. Fetch user from database
	// 2. Verify old password
	// 3. Hash new password
	// 4. Update database
	// 5. Invalidate all sessions except current

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "Password changed successfully",
		"user_id": claims.UserID,
	})
}
