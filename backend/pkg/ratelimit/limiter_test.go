package ratelimit_test

import (
	"context"
	"testing"
	"time"

	"github.com/mehmetkilic/yazihanem/pkg/ratelimit"
	"github.com/redis/go-redis/v9"
)

// TestLimiter_Allow tests basic rate limiting functionality
func TestLimiter_Allow(t *testing.T) {
	// Setup Redis client for testing
	// Note: This requires a running Redis instance
	client := redis.NewClient(&redis.Options{
		Addr: "localhost:6379",
		DB:   15, // Use separate DB for tests
	})
	defer client.Close()

	// Test connection
	ctx := context.Background()
	if err := client.Ping(ctx).Err(); err != nil {
		t.Skip("Redis not available, skipping test")
	}

	limiter := ratelimit.NewLimiter(client)

	// Clean up before test
	testKey := "test:ratelimit:basic"
	client.Del(ctx, testKey)

	config := ratelimit.Config{
		Limit:  5,
		Window: time.Minute,
	}

	// Test: Allow first 5 requests
	for i := 0; i < 5; i++ {
		result, err := limiter.Allow(ctx, testKey, config)
		if err != nil {
			t.Fatalf("Unexpected error on request %d: %v", i+1, err)
		}

		if !result.Allowed {
			t.Errorf("Request %d should be allowed", i+1)
		}

		expectedRemaining := 4 - i
		if result.Remaining != expectedRemaining {
			t.Errorf("Request %d: expected remaining %d, got %d", i+1, expectedRemaining, result.Remaining)
		}
	}

	// Test: 6th request should be blocked
	result, err := limiter.Allow(ctx, testKey, config)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if result.Allowed {
		t.Error("6th request should be blocked")
	}

	if result.Remaining != 0 {
		t.Errorf("Expected remaining 0, got %d", result.Remaining)
	}

	// Cleanup
	client.Del(ctx, testKey)
}

// TestLimiter_SlidingWindow tests sliding window behavior
func TestLimiter_SlidingWindow(t *testing.T) {
	client := redis.NewClient(&redis.Options{
		Addr: "localhost:6379",
		DB:   15,
	})
	defer client.Close()

	ctx := context.Background()
	if err := client.Ping(ctx).Err(); err != nil {
		t.Skip("Redis not available, skipping test")
	}

	limiter := ratelimit.NewLimiter(client)

	testKey := "test:ratelimit:sliding"
	client.Del(ctx, testKey)

	config := ratelimit.Config{
		Limit:  2,
		Window: 2 * time.Second,
	}

	// Make 2 requests (should be allowed)
	for i := 0; i < 2; i++ {
		result, err := limiter.Allow(ctx, testKey, config)
		if err != nil || !result.Allowed {
			t.Fatalf("Request %d should be allowed", i+1)
		}
	}

	// 3rd request should be blocked
	result, err := limiter.Allow(ctx, testKey, config)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if result.Allowed {
		t.Error("3rd request should be blocked")
	}

	// Wait for window to slide (2 seconds)
	time.Sleep(2*time.Second + 100*time.Millisecond)

	// Now request should be allowed again
	result, err = limiter.Allow(ctx, testKey, config)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if !result.Allowed {
		t.Error("Request after window should be allowed")
	}

	// Cleanup
	client.Del(ctx, testKey)
}

// TestLimiter_Reset tests reset functionality
func TestLimiter_Reset(t *testing.T) {
	client := redis.NewClient(&redis.Options{
		Addr: "localhost:6379",
		DB:   15,
	})
	defer client.Close()

	ctx := context.Background()
	if err := client.Ping(ctx).Err(); err != nil {
		t.Skip("Redis not available, skipping test")
	}

	limiter := ratelimit.NewLimiter(client)

	testKey := "test:ratelimit:reset"
	client.Del(ctx, testKey)

	config := ratelimit.Config{
		Limit:  1,
		Window: time.Minute,
	}

	// Use up the limit
	limiter.Allow(ctx, testKey, config)

	// Next request should be blocked
	result, err := limiter.Allow(ctx, testKey, config)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if result.Allowed {
		t.Error("Request should be blocked")
	}

	// Reset the limit
	if err := limiter.Reset(ctx, testKey); err != nil {
		t.Fatalf("Failed to reset: %v", err)
	}

	// Now request should be allowed
	result, err = limiter.Allow(ctx, testKey, config)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if !result.Allowed {
		t.Error("Request after reset should be allowed")
	}

	// Cleanup
	client.Del(ctx, testKey)
}

// TestLimiter_GetCount tests count retrieval
func TestLimiter_GetCount(t *testing.T) {
	client := redis.NewClient(&redis.Options{
		Addr: "localhost:6379",
		DB:   15,
	})
	defer client.Close()

	ctx := context.Background()
	if err := client.Ping(ctx).Err(); err != nil {
		t.Skip("Redis not available, skipping test")
	}

	limiter := ratelimit.NewLimiter(client)

	testKey := "test:ratelimit:count"
	client.Del(ctx, testKey)

	config := ratelimit.Config{
		Limit:  10,
		Window: time.Minute,
	}

	// Make 3 requests
	for i := 0; i < 3; i++ {
		limiter.Allow(ctx, testKey, config)
	}

	// Get count
	count, err := limiter.GetCount(ctx, testKey, config.Window)
	if err != nil {
		t.Fatalf("Failed to get count: %v", err)
	}

	if count != 3 {
		t.Errorf("Expected count 3, got %d", count)
	}

	// Cleanup
	client.Del(ctx, testKey)
}
