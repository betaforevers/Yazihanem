package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/mehmetkilic/yazihanem/pkg/cache"
)

// CacheManager provides high-level caching operations
type CacheManager struct {
	redis *cache.RedisClient
}

// NewCacheManager creates a new cache manager
func NewCacheManager(redis *cache.RedisClient) *CacheManager {
	return &CacheManager{
		redis: redis,
	}
}

// Set stores a value with expiration
func (cm *CacheManager) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	jsonData, err := json.Marshal(value)
	if err != nil {
		return fmt.Errorf("failed to marshal cache value: %w", err)
	}

	if err := cm.redis.Set(ctx, key, jsonData, ttl).Err(); err != nil {
		return fmt.Errorf("failed to set cache: %w", err)
	}

	return nil
}

// Get retrieves and unmarshals a cached value
func (cm *CacheManager) Get(ctx context.Context, key string, dest interface{}) error {
	jsonData, err := cm.redis.Get(ctx, key).Result()
	if err != nil {
		return fmt.Errorf("cache miss: %w", err)
	}

	if err := json.Unmarshal([]byte(jsonData), dest); err != nil {
		return fmt.Errorf("failed to unmarshal cache value: %w", err)
	}

	return nil
}

// Delete removes a cached value
func (cm *CacheManager) Delete(ctx context.Context, key string) error {
	return cm.redis.Del(ctx, key).Err()
}

// DeletePattern removes all keys matching a pattern
func (cm *CacheManager) DeletePattern(ctx context.Context, pattern string) error {
	return cm.redis.DeletePattern(ctx, pattern)
}

// Exists checks if a key exists
func (cm *CacheManager) Exists(ctx context.Context, key string) (bool, error) {
	count, err := cm.redis.Exists(ctx, key).Result()
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

// GetOrSet gets a value from cache or computes it if missing
func (cm *CacheManager) GetOrSet(ctx context.Context, key string, ttl time.Duration, compute func() (interface{}, error), dest interface{}) error {
	// Try to get from cache first
	err := cm.Get(ctx, key, dest)
	if err == nil {
		return nil // Cache hit
	}

	// Compute the value
	value, err := compute()
	if err != nil {
		return fmt.Errorf("failed to compute value: %w", err)
	}

	// Store in cache
	if err := cm.Set(ctx, key, value, ttl); err != nil {
		return err
	}

	// Marshal the computed value into dest
	jsonData, err := json.Marshal(value)
	if err != nil {
		return err
	}

	return json.Unmarshal(jsonData, dest)
}

// InvalidateTenantCache removes all cache entries for a tenant
func (cm *CacheManager) InvalidateTenantCache(ctx context.Context, tenantID string) error {
	pattern := fmt.Sprintf("tenant:%s:*", tenantID)
	return cm.DeletePattern(ctx, pattern)
}

// IncrementCounter increments a counter atomically
func (cm *CacheManager) IncrementCounter(ctx context.Context, key string, expiry time.Duration) (int64, error) {
	count, err := cm.redis.Incr(ctx, key).Result()
	if err != nil {
		return 0, err
	}

	// Set expiry if this is the first increment
	if count == 1 {
		cm.redis.Expire(ctx, key, expiry)
	}

	return count, nil
}

// GetTTL returns the remaining time to live for a key
func (cm *CacheManager) GetTTL(ctx context.Context, key string) (time.Duration, error) {
	return cm.redis.TTL(ctx, key).Result()
}
