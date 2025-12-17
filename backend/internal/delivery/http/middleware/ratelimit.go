package middleware

import (
	"fmt"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/mehmetkilic/yazihanem/pkg/ratelimit"
)

// RateLimitType defines the type of rate limiting
type RateLimitType string

const (
	// RateLimitByTenant limits by tenant ID
	RateLimitByTenant RateLimitType = "tenant"
	// RateLimitByIP limits by client IP
	RateLimitByIP RateLimitType = "ip"
	// RateLimitByUser limits by user ID
	RateLimitByUser RateLimitType = "user"
)

// RateLimitConfig defines configuration for rate limiting middleware
type RateLimitConfig struct {
	Limiter   *ratelimit.Limiter
	Type      RateLimitType
	Limit     int           // Max requests
	Window    time.Duration // Time window
	Burst     int           // Burst capacity (optional)
	KeyPrefix string        // Redis key prefix (e.g., "ratelimit:login")

	// Custom key generator (optional)
	// If provided, this overrides the default key generation
	KeyGenerator func(c *fiber.Ctx) (string, error)

	// Handler for rate limit exceeded
	// If not provided, returns 429 status
	LimitExceededHandler func(c *fiber.Ctx, result *ratelimit.Result) error
}

// RateLimit creates a rate limiting middleware
func RateLimit(config RateLimitConfig) fiber.Handler {
	// Set defaults
	if config.KeyPrefix == "" {
		config.KeyPrefix = "ratelimit"
	}

	if config.Limit <= 0 {
		config.Limit = 100 // Default: 100 requests
	}

	if config.Window <= 0 {
		config.Window = time.Minute // Default: per minute
	}

	return func(c *fiber.Ctx) error {
		// Generate rate limit key
		key, err := generateKey(c, config)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "Failed to generate rate limit key",
			})
		}

		// Check rate limit
		result, err := config.Limiter.Allow(c.Context(), key, ratelimit.Config{
			Limit:  config.Limit,
			Window: config.Window,
			Burst:  config.Burst,
		})
		if err != nil {
			// Log error but don't block request (fail open for availability)
			fmt.Printf("Rate limit check failed: %v\n", err)
			return c.Next()
		}

		// Set rate limit headers
		c.Set("X-RateLimit-Limit", fmt.Sprintf("%d", config.Limit))
		c.Set("X-RateLimit-Remaining", fmt.Sprintf("%d", result.Remaining))
		c.Set("X-RateLimit-Reset", fmt.Sprintf("%d", result.ResetAt.Unix()))

		// Check if request is allowed
		if !result.Allowed {
			// Set Retry-After header
			c.Set("Retry-After", fmt.Sprintf("%d", int(result.RetryAfter.Seconds())))

			// Use custom handler if provided
			if config.LimitExceededHandler != nil {
				return config.LimitExceededHandler(c, result)
			}

			// Default response
			return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{
				"error":   "Rate limit exceeded",
				"message": fmt.Sprintf("Too many requests. Please try again in %s", result.RetryAfter.Round(time.Second)),
				"limit":   config.Limit,
				"window":  config.Window.String(),
				"retry_after": int(result.RetryAfter.Seconds()),
			})
		}

		return c.Next()
	}
}

// generateKey generates the Redis key for rate limiting
func generateKey(c *fiber.Ctx, config RateLimitConfig) (string, error) {
	// Use custom key generator if provided
	if config.KeyGenerator != nil {
		customKey, err := config.KeyGenerator(c)
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("%s:%s", config.KeyPrefix, customKey), nil
	}

	// Default key generation based on type
	var identifier string

	switch config.Type {
	case RateLimitByTenant:
		tenant, err := GetTenantFromContext(c)
		if err != nil {
			return "", fmt.Errorf("tenant not found in context")
		}
		identifier = tenant.ID

	case RateLimitByIP:
		// Get real IP (consider X-Forwarded-For, X-Real-IP headers)
		identifier = c.IP()

	case RateLimitByUser:
		// Get user ID from JWT context
		userID := c.Locals("user_id")
		if userID == nil {
			return "", fmt.Errorf("user not found in context")
		}
		identifier = userID.(string)

	default:
		return "", fmt.Errorf("invalid rate limit type: %s", config.Type)
	}

	return fmt.Sprintf("%s:%s:%s", config.KeyPrefix, config.Type, identifier), nil
}

// Pre-configured rate limiters for common use cases

// TenantRateLimit applies tenant-based rate limiting
func TenantRateLimit(limiter *ratelimit.Limiter, requestsPerMinute int) fiber.Handler {
	return RateLimit(RateLimitConfig{
		Limiter:   limiter,
		Type:      RateLimitByTenant,
		Limit:     requestsPerMinute,
		Window:    time.Minute,
		KeyPrefix: "ratelimit:tenant",
	})
}

// IPRateLimit applies IP-based rate limiting (for public endpoints)
func IPRateLimit(limiter *ratelimit.Limiter, requestsPerMinute int) fiber.Handler {
	return RateLimit(RateLimitConfig{
		Limiter:   limiter,
		Type:      RateLimitByIP,
		Limit:     requestsPerMinute,
		Window:    time.Minute,
		KeyPrefix: "ratelimit:ip",
	})
}

// AuthRateLimit applies strict rate limiting for auth endpoints
func AuthRateLimit(limiter *ratelimit.Limiter) fiber.Handler {
	return RateLimit(RateLimitConfig{
		Limiter:   limiter,
		Type:      RateLimitByIP,
		Limit:     5, // 5 attempts
		Window:    time.Minute,
		KeyPrefix: "ratelimit:auth",
	})
}

// UserRateLimit applies user-based rate limiting
func UserRateLimit(limiter *ratelimit.Limiter, requestsPerMinute int) fiber.Handler {
	return RateLimit(RateLimitConfig{
		Limiter:   limiter,
		Type:      RateLimitByUser,
		Limit:     requestsPerMinute,
		Window:    time.Minute,
		KeyPrefix: "ratelimit:user",
	})
}
