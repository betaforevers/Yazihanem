package ratelimit

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

// Limiter implements rate limiting using Redis sliding window algorithm
type Limiter struct {
	redis *redis.Client
}

// NewLimiter creates a new rate limiter
func NewLimiter(redisClient *redis.Client) *Limiter {
	return &Limiter{
		redis: redisClient,
	}
}

// Config defines rate limit configuration
type Config struct {
	Limit  int           // Maximum number of requests
	Window time.Duration // Time window for the limit
	Burst  int           // Burst capacity (optional, defaults to Limit)
}

// Result represents the result of a rate limit check
type Result struct {
	Allowed       bool          // Whether the request is allowed
	Remaining     int           // Remaining requests in the window
	ResetAt       time.Time     // When the limit resets
	RetryAfter    time.Duration // How long to wait before retrying (if not allowed)
	TotalRequests int           // Total requests in current window
}

// Allow checks if a request is allowed under the rate limit
// Uses Redis sliding window algorithm for accurate rate limiting
func (l *Limiter) Allow(ctx context.Context, key string, config Config) (*Result, error) {
	now := time.Now()
	windowStart := now.Add(-config.Window)

	// Use Redis pipeline for atomic operations
	pipe := l.redis.Pipeline()

	// Remove old entries outside the window
	pipe.ZRemRangeByScore(ctx, key, "0", fmt.Sprintf("%d", windowStart.UnixNano()))

	// Count current requests in window
	zcountCmd := pipe.ZCount(ctx, key, fmt.Sprintf("%d", windowStart.UnixNano()), "+inf")

	// Execute pipeline
	_, err := pipe.Exec(ctx)
	if err != nil && err != redis.Nil {
		return nil, fmt.Errorf("failed to check rate limit: %w", err)
	}

	// Get current count
	currentCount, err := zcountCmd.Result()
	if err != nil && err != redis.Nil {
		return nil, fmt.Errorf("failed to get request count: %w", err)
	}

	// Check if limit exceeded
	limit := config.Limit
	if config.Burst > 0 && config.Burst > limit {
		limit = config.Burst
	}

	allowed := int(currentCount) < limit

	result := &Result{
		Allowed:       allowed,
		Remaining:     max(0, limit-int(currentCount)),
		ResetAt:       now.Add(config.Window),
		TotalRequests: int(currentCount),
	}

	if allowed {
		// Add current request to the window
		score := now.UnixNano()
		member := fmt.Sprintf("%d:%d", score, time.Now().UnixNano()) // Unique member

		err = l.redis.ZAdd(ctx, key, redis.Z{
			Score:  float64(score),
			Member: member,
		}).Err()
		if err != nil {
			return nil, fmt.Errorf("failed to record request: %w", err)
		}

		// Set expiration on the key (cleanup)
		l.redis.Expire(ctx, key, config.Window+time.Minute)

		result.TotalRequests++
		result.Remaining--
	} else {
		// Calculate retry after duration
		result.RetryAfter = config.Window
	}

	return result, nil
}

// Reset removes all rate limit data for a key
func (l *Limiter) Reset(ctx context.Context, key string) error {
	return l.redis.Del(ctx, key).Err()
}

// GetCount returns the current request count for a key
func (l *Limiter) GetCount(ctx context.Context, key string, window time.Duration) (int, error) {
	now := time.Now()
	windowStart := now.Add(-window)

	count, err := l.redis.ZCount(ctx, key, fmt.Sprintf("%d", windowStart.UnixNano()), "+inf").Result()
	if err != nil && err != redis.Nil {
		return 0, fmt.Errorf("failed to get count: %w", err)
	}

	return int(count), nil
}

// Helper function
func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
