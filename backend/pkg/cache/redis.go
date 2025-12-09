package cache

import (
	"context"
	"fmt"
	"time"

	"github.com/mehmetkilic/yazihanem/config"
	"github.com/redis/go-redis/v9"
)

// RedisClient wraps redis.Client with additional functionality
type RedisClient struct {
	*redis.Client
}

// NewRedisClient creates a new Redis client
func NewRedisClient(ctx context.Context, cfg *config.RedisConfig) (*RedisClient, error) {
	addr := fmt.Sprintf("%s:%d", cfg.Host, cfg.Port)

	client := redis.NewClient(&redis.Options{
		Addr:         addr,
		Password:     cfg.Password,
		DB:           cfg.DB,
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
		PoolSize:     10,
		MinIdleConns: 5,
		MaxRetries:   3,
	})

	// Test connection
	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("failed to connect to Redis: %w", err)
	}

	return &RedisClient{Client: client}, nil
}

// Close closes the Redis connection
func (r *RedisClient) Close() error {
	return r.Client.Close()
}

// HealthCheck checks if Redis is reachable
func (r *RedisClient) HealthCheck(ctx context.Context) error {
	return r.Client.Ping(ctx).Err()
}

// Stats returns Redis pool statistics
func (r *RedisClient) Stats() *redis.PoolStats {
	return r.Client.PoolStats()
}

// GetWithExpiry gets a value with its remaining TTL
func (r *RedisClient) GetWithExpiry(ctx context.Context, key string) (string, time.Duration, error) {
	pipe := r.Client.Pipeline()
	getCmd := pipe.Get(ctx, key)
	ttlCmd := pipe.TTL(ctx, key)

	if _, err := pipe.Exec(ctx); err != nil && err != redis.Nil {
		return "", 0, err
	}

	val, err := getCmd.Result()
	if err != nil {
		return "", 0, err
	}

	ttl, err := ttlCmd.Result()
	if err != nil {
		return val, 0, nil
	}

	return val, ttl, nil
}

// SetNX sets a value only if it doesn't exist (atomic)
func (r *RedisClient) SetNX(ctx context.Context, key string, value interface{}, expiration time.Duration) (bool, error) {
	return r.Client.SetNX(ctx, key, value, expiration).Result()
}

// IncrBy increments a counter atomically
func (r *RedisClient) IncrBy(ctx context.Context, key string, value int64) (int64, error) {
	return r.Client.IncrBy(ctx, key, value).Result()
}

// DecrBy decrements a counter atomically
func (r *RedisClient) DecrBy(ctx context.Context, key string, value int64) (int64, error) {
	return r.Client.DecrBy(ctx, key, value).Result()
}

// DeletePattern deletes all keys matching a pattern
func (r *RedisClient) DeletePattern(ctx context.Context, pattern string) error {
	var cursor uint64
	for {
		var keys []string
		var err error
		keys, cursor, err = r.Client.Scan(ctx, cursor, pattern, 100).Result()
		if err != nil {
			return err
		}

		if len(keys) > 0 {
			if err := r.Client.Del(ctx, keys...).Err(); err != nil {
				return err
			}
		}

		if cursor == 0 {
			break
		}
	}
	return nil
}
