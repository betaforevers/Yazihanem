package database

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
	"github.com/mehmetkilic/yazihanem/internal/domain/repository"
	generated "github.com/mehmetkilic/yazihanem/internal/infrastructure/database/sqlc/generated"
	"github.com/mehmetkilic/yazihanem/pkg/tenant"
)

// UserRepositoryImpl implements repository.UserRepository using sqlc
type UserRepositoryImpl struct {
	pool *pgxpool.Pool
}

// NewUserRepository creates a new user repository
func NewUserRepository(pool *pgxpool.Pool) repository.UserRepository {
	return &UserRepositoryImpl{
		pool: pool,
	}
}

// setSearchPath sets the PostgreSQL search_path to the tenant schema
func (r *UserRepositoryImpl) setSearchPath(ctx context.Context, schema string) error {
	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		return fmt.Errorf("failed to acquire connection: %w", err)
	}
	defer conn.Release()

	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s", schema))
	if err != nil {
		return fmt.Errorf("failed to set search_path: %w", err)
	}

	return nil
}

// Create creates a new user
func (r *UserRepositoryImpl) Create(ctx context.Context, user *entity.User) error {
	schema, ok := tenant.GetSchemaFromContext(ctx)
	if !ok {
		return fmt.Errorf("tenant schema not found in context")
	}

	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		return fmt.Errorf("failed to acquire connection: %w", err)
	}
	defer conn.Release()

	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s", schema))
	if err != nil {
		return fmt.Errorf("failed to set search_path: %w", err)
	}

	queries := generated.New(conn)
	params := generated.CreateUserParams{
		Email:        user.Email,
		PasswordHash: user.PasswordHash,
		FirstName:    user.FirstName,
		LastName:     user.LastName,
		Role:         string(user.Role),
		IsActive:     user.IsActive,
	}

	row, err := queries.CreateUser(ctx, params)
	if err != nil {
		return fmt.Errorf("failed to create user: %w", err)
	}

	user.ID = row.ID.String()
	user.CreatedAt = row.CreatedAt
	user.UpdatedAt = row.UpdatedAt

	return nil
}

// GetByID retrieves a user by ID
func (r *UserRepositoryImpl) GetByID(ctx context.Context, tenantID, userID string) (*entity.User, error) {
	schema, ok := tenant.GetSchemaFromContext(ctx)
	if !ok {
		return nil, fmt.Errorf("tenant schema not found in context")
	}

	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to acquire connection: %w", err)
	}
	defer conn.Release()

	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s", schema))
	if err != nil {
		return nil, fmt.Errorf("failed to set search_path: %w", err)
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		return nil, fmt.Errorf("invalid user ID: %w", err)
	}

	queries := generated.New(conn)
	row, err := queries.GetUserByID(ctx, userUUID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return mapUserRowToEntity(row), nil
}

// GetByEmail retrieves a user by email
func (r *UserRepositoryImpl) GetByEmail(ctx context.Context, tenantID, email string) (*entity.User, error) {
	schema, ok := tenant.GetSchemaFromContext(ctx)
	if !ok {
		return nil, fmt.Errorf("tenant schema not found in context")
	}

	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to acquire connection: %w", err)
	}
	defer conn.Release()

	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s", schema))
	if err != nil {
		return nil, fmt.Errorf("failed to set search_path: %w", err)
	}

	queries := generated.New(conn)
	row, err := queries.GetUserByEmail(ctx, email)
	if err != nil {
		return nil, fmt.Errorf("failed to get user by email: %w", err)
	}

	return mapUserRowToEntity(row), nil
}

// Update updates a user
func (r *UserRepositoryImpl) Update(ctx context.Context, user *entity.User) error {
	schema, ok := tenant.GetSchemaFromContext(ctx)
	if !ok {
		return fmt.Errorf("tenant schema not found in context")
	}

	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		return fmt.Errorf("failed to acquire connection: %w", err)
	}
	defer conn.Release()

	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s", schema))
	if err != nil {
		return fmt.Errorf("failed to set search_path: %w", err)
	}

	userUUID, err := uuid.Parse(user.ID)
	if err != nil {
		return fmt.Errorf("invalid user ID: %w", err)
	}

	params := generated.UpdateUserParams{
		ID:        userUUID,
		Email:     user.Email,
		FirstName: user.FirstName,
		LastName:  user.LastName,
		Role:      string(user.Role),
		IsActive:  user.IsActive,
	}

	queries := generated.New(conn)
	row, err := queries.UpdateUser(ctx, params)
	if err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}

	user.UpdatedAt = row.UpdatedAt
	return nil
}

// UpdatePassword updates a user's password
func (r *UserRepositoryImpl) UpdatePassword(ctx context.Context, tenantID, userID, passwordHash string) error {
	schema, ok := tenant.GetSchemaFromContext(ctx)
	if !ok {
		return fmt.Errorf("tenant schema not found in context")
	}

	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		return fmt.Errorf("failed to acquire connection: %w", err)
	}
	defer conn.Release()

	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s", schema))
	if err != nil {
		return fmt.Errorf("failed to set search_path: %w", err)
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		return fmt.Errorf("invalid user ID: %w", err)
	}

	queries := generated.New(conn)
	params := generated.UpdateUserPasswordParams{
		ID:           userUUID,
		PasswordHash: passwordHash,
	}

	return queries.UpdateUserPassword(ctx, params)
}

// UpdateLastLogin updates the last login timestamp
func (r *UserRepositoryImpl) UpdateLastLogin(ctx context.Context, tenantID, userID string) error {
	schema, ok := tenant.GetSchemaFromContext(ctx)
	if !ok {
		return fmt.Errorf("tenant schema not found in context")
	}

	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		return fmt.Errorf("failed to acquire connection: %w", err)
	}
	defer conn.Release()

	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s", schema))
	if err != nil {
		return fmt.Errorf("failed to set search_path: %w", err)
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		return fmt.Errorf("invalid user ID: %w", err)
	}

	queries := generated.New(conn)
	return queries.UpdateUserLastLogin(ctx, userUUID)
}

// Delete deletes a user
func (r *UserRepositoryImpl) Delete(ctx context.Context, tenantID, userID string) error {
	schema, ok := tenant.GetSchemaFromContext(ctx)
	if !ok {
		return fmt.Errorf("tenant schema not found in context")
	}

	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		return fmt.Errorf("failed to acquire connection: %w", err)
	}
	defer conn.Release()

	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s", schema))
	if err != nil {
		return fmt.Errorf("failed to set search_path: %w", err)
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		return fmt.Errorf("invalid user ID: %w", err)
	}

	queries := generated.New(conn)
	return queries.DeleteUser(ctx, userUUID)
}

// List retrieves a list of users with pagination
func (r *UserRepositoryImpl) List(ctx context.Context, tenantID string, offset, limit int) ([]*entity.User, error) {
	schema, ok := tenant.GetSchemaFromContext(ctx)
	if !ok {
		return nil, fmt.Errorf("tenant schema not found in context")
	}

	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to acquire connection: %w", err)
	}
	defer conn.Release()

	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s", schema))
	if err != nil {
		return nil, fmt.Errorf("failed to set search_path: %w", err)
	}

	queries := generated.New(conn)
	params := generated.ListUsersParams{
		Limit:  int32(limit),
		Offset: int32(offset),
	}

	rows, err := queries.ListUsers(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("failed to list users: %w", err)
	}

	users := make([]*entity.User, len(rows))
	for i, row := range rows {
		users[i] = mapUserRowToEntity(row)
	}

	return users, nil
}

// Count returns the total number of users
func (r *UserRepositoryImpl) Count(ctx context.Context, tenantID string) (int64, error) {
	schema, ok := tenant.GetSchemaFromContext(ctx)
	if !ok {
		return 0, fmt.Errorf("tenant schema not found in context")
	}

	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		return 0, fmt.Errorf("failed to acquire connection: %w", err)
	}
	defer conn.Release()

	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s", schema))
	if err != nil {
		return 0, fmt.Errorf("failed to set search_path: %w", err)
	}

	queries := generated.New(conn)
	return queries.CountUsers(ctx)
}

// SetActive activates or deactivates a user
func (r *UserRepositoryImpl) SetActive(ctx context.Context, tenantID, userID string, isActive bool) error {
	schema, ok := tenant.GetSchemaFromContext(ctx)
	if !ok {
		return fmt.Errorf("tenant schema not found in context")
	}

	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		return fmt.Errorf("failed to acquire connection: %w", err)
	}
	defer conn.Release()

	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s", schema))
	if err != nil {
		return fmt.Errorf("failed to set search_path: %w", err)
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		return fmt.Errorf("invalid user ID: %w", err)
	}

	queries := generated.New(conn)
	params := generated.SetUserActiveParams{
		ID:       userUUID,
		IsActive: isActive,
	}

	return queries.SetUserActive(ctx, params)
}

// mapUserRowToEntity maps sqlc generated User to domain entity
func mapUserRowToEntity(row *generated.User) *entity.User {
	user := &entity.User{
		ID:           row.ID.String(),
		Email:        row.Email,
		PasswordHash: row.PasswordHash,
		FirstName:    row.FirstName,
		LastName:     row.LastName,
		Role:         entity.UserRole(row.Role),
		IsActive:     row.IsActive,
		CreatedAt:    row.CreatedAt,
		UpdatedAt:    row.UpdatedAt,
	}

	if row.LastLoginAt.Valid {
		user.LastLoginAt = row.LastLoginAt.Time
	}

	return user
}
