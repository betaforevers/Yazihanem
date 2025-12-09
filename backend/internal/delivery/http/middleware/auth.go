package middleware

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/mehmetkilic/yazihanem/pkg/auth"
)

// AuthMiddleware handles JWT authentication
type AuthMiddleware struct {
	jwtManager *auth.JWTManager
}

// NewAuthMiddleware creates a new authentication middleware
func NewAuthMiddleware(jwtManager *auth.JWTManager) *AuthMiddleware {
	return &AuthMiddleware{
		jwtManager: jwtManager,
	}
}

// Authenticate validates JWT token and adds claims to context
func (am *AuthMiddleware) Authenticate() fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Get Authorization header
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error":   "Unauthorized",
				"message": "Authorization header is required",
			})
		}

		// Extract token
		token, err := auth.ExtractTokenFromHeader(authHeader)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error":   "Unauthorized",
				"message": err.Error(),
			})
		}

		// Validate token
		claims, err := am.jwtManager.ValidateToken(token)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error":   "Unauthorized",
				"message": "Invalid or expired token",
			})
		}

		// Store claims in context
		c.Locals("user_id", claims.UserID)
		c.Locals("tenant_id", claims.TenantID)
		c.Locals("email", claims.Email)
		c.Locals("role", claims.Role)
		c.Locals("claims", claims)

		return c.Next()
	}
}

// RequireRole checks if user has required role
func RequireRole(roles ...string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		userRole := c.Locals("role")
		if userRole == nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error":   "Unauthorized",
				"message": "User role not found in context",
			})
		}

		roleStr, ok := userRole.(string)
		if !ok {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "Internal Server Error",
			})
		}

		// Check if user has any of the required roles
		for _, requiredRole := range roles {
			if strings.EqualFold(roleStr, requiredRole) {
				return c.Next()
			}
		}

		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "Forbidden",
			"message": "Insufficient permissions",
		})
	}
}

// GetUserIDFromContext retrieves user ID from context
func GetUserIDFromContext(c *fiber.Ctx) (string, error) {
	userID := c.Locals("user_id")
	if userID == nil {
		return "", fiber.ErrUnauthorized
	}

	userIDStr, ok := userID.(string)
	if !ok {
		return "", fiber.ErrInternalServerError
	}

	return userIDStr, nil
}

// GetUserClaimsFromContext retrieves full claims from context
func GetUserClaimsFromContext(c *fiber.Ctx) (*auth.Claims, error) {
	claims := c.Locals("claims")
	if claims == nil {
		return nil, fiber.ErrUnauthorized
	}

	userClaims, ok := claims.(*auth.Claims)
	if !ok {
		return nil, fiber.ErrInternalServerError
	}

	return userClaims, nil
}

// Optional authentication - doesn't fail if no token, but validates if present
func (am *AuthMiddleware) OptionalAuth() fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Next()
		}

		token, err := auth.ExtractTokenFromHeader(authHeader)
		if err != nil {
			return c.Next()
		}

		claims, err := am.jwtManager.ValidateToken(token)
		if err != nil {
			return c.Next()
		}

		// Store claims if valid
		c.Locals("user_id", claims.UserID)
		c.Locals("tenant_id", claims.TenantID)
		c.Locals("email", claims.Email)
		c.Locals("role", claims.Role)
		c.Locals("claims", claims)

		return c.Next()
	}
}
