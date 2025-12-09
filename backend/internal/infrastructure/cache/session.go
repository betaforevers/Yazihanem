package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/mehmetkilic/yazihanem/pkg/cache"
)

// SessionManager manages user sessions in Redis
type SessionManager struct {
	redis  *cache.RedisClient
	prefix string
	ttl    time.Duration
}

// SessionData represents session information
type SessionData struct {
	UserID    string                 `json:"user_id"`
	TenantID  string                 `json:"tenant_id"`
	Email     string                 `json:"email"`
	Role      string                 `json:"role"`
	CreatedAt time.Time              `json:"created_at"`
	ExpiresAt time.Time              `json:"expires_at"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

// NewSessionManager creates a new session manager
func NewSessionManager(redis *cache.RedisClient, prefix string, ttl time.Duration) *SessionManager {
	return &SessionManager{
		redis:  redis,
		prefix: prefix,
		ttl:    ttl,
	}
}

// Create creates a new session
func (sm *SessionManager) Create(ctx context.Context, sessionID string, data *SessionData) error {
	data.CreatedAt = time.Now()
	data.ExpiresAt = time.Now().Add(sm.ttl)

	jsonData, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("failed to marshal session data: %w", err)
	}

	key := sm.getKey(sessionID)
	if err := sm.redis.Set(ctx, key, jsonData, sm.ttl).Err(); err != nil {
		return fmt.Errorf("failed to create session: %w", err)
	}

	return nil
}

// Get retrieves a session by ID
func (sm *SessionManager) Get(ctx context.Context, sessionID string) (*SessionData, error) {
	key := sm.getKey(sessionID)
	jsonData, err := sm.redis.Get(ctx, key).Result()
	if err != nil {
		return nil, fmt.Errorf("session not found: %w", err)
	}

	var data SessionData
	if err := json.Unmarshal([]byte(jsonData), &data); err != nil {
		return nil, fmt.Errorf("failed to unmarshal session data: %w", err)
	}

	return &data, nil
}

// Refresh extends the session expiry time
func (sm *SessionManager) Refresh(ctx context.Context, sessionID string) error {
	key := sm.getKey(sessionID)

	// Get existing session
	data, err := sm.Get(ctx, sessionID)
	if err != nil {
		return err
	}

	// Update expiry
	data.ExpiresAt = time.Now().Add(sm.ttl)

	jsonData, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("failed to marshal session data: %w", err)
	}

	if err := sm.redis.Set(ctx, key, jsonData, sm.ttl).Err(); err != nil {
		return fmt.Errorf("failed to refresh session: %w", err)
	}

	return nil
}

// Delete removes a session
func (sm *SessionManager) Delete(ctx context.Context, sessionID string) error {
	key := sm.getKey(sessionID)
	if err := sm.redis.Del(ctx, key).Err(); err != nil {
		return fmt.Errorf("failed to delete session: %w", err)
	}
	return nil
}

// DeleteAllForUser removes all sessions for a specific user
func (sm *SessionManager) DeleteAllForUser(ctx context.Context, userID string) error {
	pattern := fmt.Sprintf("%s:*", sm.prefix)
	return sm.redis.DeletePattern(ctx, pattern)
}

// Update updates session metadata
func (sm *SessionManager) Update(ctx context.Context, sessionID string, metadata map[string]interface{}) error {
	data, err := sm.Get(ctx, sessionID)
	if err != nil {
		return err
	}

	if data.Metadata == nil {
		data.Metadata = make(map[string]interface{})
	}

	for k, v := range metadata {
		data.Metadata[k] = v
	}

	jsonData, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("failed to marshal session data: %w", err)
	}

	key := sm.getKey(sessionID)
	ttl, err := sm.redis.TTL(ctx, key).Result()
	if err != nil {
		ttl = sm.ttl
	}

	if err := sm.redis.Set(ctx, key, jsonData, ttl).Err(); err != nil {
		return fmt.Errorf("failed to update session: %w", err)
	}

	return nil
}

// Exists checks if a session exists
func (sm *SessionManager) Exists(ctx context.Context, sessionID string) (bool, error) {
	key := sm.getKey(sessionID)
	count, err := sm.redis.Exists(ctx, key).Result()
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

// GetRemainingTTL returns the remaining time until session expires
func (sm *SessionManager) GetRemainingTTL(ctx context.Context, sessionID string) (time.Duration, error) {
	key := sm.getKey(sessionID)
	return sm.redis.TTL(ctx, key).Result()
}

// getKey generates the Redis key for a session
func (sm *SessionManager) getKey(sessionID string) string {
	return fmt.Sprintf("%s:%s", sm.prefix, sessionID)
}
