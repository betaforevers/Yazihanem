package audit

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mehmetkilic/yazihanem/internal/domain/entity"
)

// Logger handles audit logging to database
type Logger struct {
	pool *pgxpool.Pool
}

// NewLogger creates a new audit logger
func NewLogger(pool *pgxpool.Pool) *Logger {
	return &Logger{
		pool: pool,
	}
}

// Log writes an audit log entry to the database
func (l *Logger) Log(ctx context.Context, log *entity.AuditLog) error {
	// Serialize metadata to JSON
	var metadataJSON []byte
	var err error
	if log.Metadata != nil && len(log.Metadata) > 0 {
		metadataJSON, err = json.Marshal(log.Metadata)
		if err != nil {
			return fmt.Errorf("failed to marshal metadata: %w", err)
		}
	}

	// Insert audit log
	query := `
		INSERT INTO public.audit_logs (
			tenant_id, user_id, action, severity,
			resource_type, resource_id,
			ip_address, user_agent,
			metadata, success, error, timestamp
		) VALUES (
			$1, $2, $3, $4,
			$5, $6,
			$7, $8,
			$9, $10, $11, $12
		)
		RETURNING id
	`

	var id string
	err = l.pool.QueryRow(
		ctx,
		query,
		log.TenantID,
		log.UserID,
		log.Action,
		log.Severity,
		log.ResourceType,
		log.ResourceID,
		log.IPAddress,
		log.UserAgent,
		metadataJSON,
		log.Success,
		log.Error,
		log.Timestamp,
	).Scan(&id)

	if err != nil {
		return fmt.Errorf("failed to insert audit log: %w", err)
	}

	log.ID = id
	return nil
}

// LogAsync writes an audit log entry asynchronously (non-blocking)
// If logging fails, it will be silently ignored to avoid impacting the main flow
func (l *Logger) LogAsync(log *entity.AuditLog) {
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		if err := l.Log(ctx, log); err != nil {
			// Log error but don't fail the request
			// In production, you might want to send this to a monitoring service
			fmt.Printf("ERROR: Failed to write audit log: %v\n", err)
		}
	}()
}

// Query retrieves audit logs with filters
type QueryOptions struct {
	TenantID     string
	UserID       *string
	Action       *entity.AuditAction
	Severity     *entity.AuditSeverity
	ResourceType *string
	ResourceID   *string
	StartTime    *time.Time
	EndTime      *time.Time
	Limit        int
	Offset       int
}

// Query retrieves audit logs based on filters
func (l *Logger) Query(ctx context.Context, opts QueryOptions) ([]*entity.AuditLog, error) {
	// Build dynamic query
	query := `
		SELECT
			id, tenant_id, user_id, action, severity,
			resource_type, resource_id,
			ip_address, user_agent,
			metadata, success, error, timestamp
		FROM public.audit_logs
		WHERE tenant_id = $1
	`
	args := []interface{}{opts.TenantID}
	argCount := 1

	// Add optional filters
	if opts.UserID != nil {
		argCount++
		query += fmt.Sprintf(" AND user_id = $%d", argCount)
		args = append(args, *opts.UserID)
	}

	if opts.Action != nil {
		argCount++
		query += fmt.Sprintf(" AND action = $%d", argCount)
		args = append(args, *opts.Action)
	}

	if opts.Severity != nil {
		argCount++
		query += fmt.Sprintf(" AND severity = $%d", argCount)
		args = append(args, *opts.Severity)
	}

	if opts.ResourceType != nil {
		argCount++
		query += fmt.Sprintf(" AND resource_type = $%d", argCount)
		args = append(args, *opts.ResourceType)
	}

	if opts.ResourceID != nil {
		argCount++
		query += fmt.Sprintf(" AND resource_id = $%d", argCount)
		args = append(args, *opts.ResourceID)
	}

	if opts.StartTime != nil {
		argCount++
		query += fmt.Sprintf(" AND timestamp >= $%d", argCount)
		args = append(args, *opts.StartTime)
	}

	if opts.EndTime != nil {
		argCount++
		query += fmt.Sprintf(" AND timestamp <= $%d", argCount)
		args = append(args, *opts.EndTime)
	}

	// Order and pagination
	query += " ORDER BY timestamp DESC"

	if opts.Limit > 0 {
		argCount++
		query += fmt.Sprintf(" LIMIT $%d", argCount)
		args = append(args, opts.Limit)
	}

	if opts.Offset > 0 {
		argCount++
		query += fmt.Sprintf(" OFFSET $%d", argCount)
		args = append(args, opts.Offset)
	}

	// Execute query
	rows, err := l.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query audit logs: %w", err)
	}
	defer rows.Close()

	// Parse results
	var logs []*entity.AuditLog
	for rows.Next() {
		log := &entity.AuditLog{}
		var metadataJSON []byte

		err := rows.Scan(
			&log.ID,
			&log.TenantID,
			&log.UserID,
			&log.Action,
			&log.Severity,
			&log.ResourceType,
			&log.ResourceID,
			&log.IPAddress,
			&log.UserAgent,
			&metadataJSON,
			&log.Success,
			&log.Error,
			&log.Timestamp,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan audit log: %w", err)
		}

		// Deserialize metadata
		if metadataJSON != nil {
			if err := json.Unmarshal(metadataJSON, &log.Metadata); err != nil {
				return nil, fmt.Errorf("failed to unmarshal metadata: %w", err)
				}
		}

		logs = append(logs, log)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating audit logs: %w", err)
	}

	return logs, nil
}

// Count returns the total number of audit logs matching the filters
func (l *Logger) Count(ctx context.Context, opts QueryOptions) (int64, error) {
	query := `SELECT COUNT(*) FROM public.audit_logs WHERE tenant_id = $1`
	args := []interface{}{opts.TenantID}
	argCount := 1

	// Add optional filters (same as Query method)
	if opts.UserID != nil {
		argCount++
		query += fmt.Sprintf(" AND user_id = $%d", argCount)
		args = append(args, *opts.UserID)
	}

	if opts.Action != nil {
		argCount++
		query += fmt.Sprintf(" AND action = $%d", argCount)
		args = append(args, *opts.Action)
	}

	if opts.Severity != nil {
		argCount++
		query += fmt.Sprintf(" AND severity = $%d", argCount)
		args = append(args, *opts.Severity)
	}

	if opts.StartTime != nil {
		argCount++
		query += fmt.Sprintf(" AND timestamp >= $%d", argCount)
		args = append(args, *opts.StartTime)
	}

	if opts.EndTime != nil {
		argCount++
		query += fmt.Sprintf(" AND timestamp <= $%d", argCount)
		args = append(args, *opts.EndTime)
	}

	var count int64
	err := l.pool.QueryRow(ctx, query, args...).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to count audit logs: %w", err)
	}

	return count, nil
}

// DeleteOldLogs deletes audit logs older than the specified retention period
// This should be called periodically (e.g., daily cron job)
func (l *Logger) DeleteOldLogs(ctx context.Context, retentionDays int) (int64, error) {
	cutoffDate := time.Now().AddDate(0, 0, -retentionDays)

	result, err := l.pool.Exec(ctx,
		`DELETE FROM public.audit_logs WHERE timestamp < $1`,
		cutoffDate,
	)
	if err != nil {
		return 0, fmt.Errorf("failed to delete old audit logs: %w", err)
	}

	return result.RowsAffected(), nil
}
