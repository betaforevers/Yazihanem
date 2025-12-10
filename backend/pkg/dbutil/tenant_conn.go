package dbutil

import (
	"context"
	"fmt"
	"regexp"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mehmetkilic/yazihanem/pkg/tenant"
)

// TenantConn wraps a connection with automatic schema switching
type TenantConn struct {
	conn *pgxpool.Conn
	ctx  context.Context
}

// schemaNamePattern validates PostgreSQL schema names
// Only allows alphanumeric characters and underscores
var schemaNamePattern = regexp.MustCompile(`^[a-zA-Z_][a-zA-Z0-9_]{0,62}$`)

// AcquireTenantConn acquires a connection and sets the search_path to tenant schema
func AcquireTenantConn(ctx context.Context, pool *pgxpool.Pool) (*TenantConn, error) {
	// Get tenant schema from context
	schema, ok := tenant.GetSchemaFromContext(ctx)
	if !ok {
		return nil, fmt.Errorf("tenant schema not found in context")
	}

	// Validate schema name to prevent SQL injection
	if !schemaNamePattern.MatchString(schema) {
		return nil, fmt.Errorf("invalid schema name: %s", schema)
	}

	// Acquire connection from pool
	conn, err := pool.Acquire(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to acquire connection: %w", err)
	}

	// Set search_path to tenant schema
	// Note: We validated schema name above, so this is safe from SQL injection
	_, err = conn.Exec(ctx, fmt.Sprintf("SET search_path TO %s, public", schema))
	if err != nil {
		conn.Release()
		return nil, fmt.Errorf("failed to set search_path: %w", err)
	}

	return &TenantConn{
		conn: conn,
		ctx:  ctx,
	}, nil
}

// Release releases the connection back to the pool
func (tc *TenantConn) Release() {
	if tc.conn != nil {
		tc.conn.Release()
	}
}

// Conn returns the underlying pgx connection
func (tc *TenantConn) Conn() *pgxpool.Conn {
	return tc.conn
}

// QueryRow executes a query that returns at most one row
func (tc *TenantConn) QueryRow(query string, args ...interface{}) pgx.Row {
	return tc.conn.QueryRow(tc.ctx, query, args...)
}

// Query executes a query that returns rows
func (tc *TenantConn) Query(query string, args ...interface{}) (pgx.Rows, error) {
	return tc.conn.Query(tc.ctx, query, args...)
}

// Exec executes a query without returning rows
func (tc *TenantConn) Exec(query string, args ...interface{}) error {
	_, err := tc.conn.Exec(tc.ctx, query, args...)
	return err
}
