package entity

import "time"

// AuditAction represents the type of action being audited
type AuditAction string

const (
	// Authentication actions
	AuditActionLogin          AuditAction = "auth.login"
	AuditActionLogout         AuditAction = "auth.logout"
	AuditActionLoginFailed    AuditAction = "auth.login_failed"
	AuditActionPasswordChange AuditAction = "auth.password_change"

	// User management actions
	AuditActionUserCreate AuditAction = "user.create"
	AuditActionUserUpdate AuditAction = "user.update"
	AuditActionUserDelete AuditAction = "user.delete"
	AuditActionUserRoleChange AuditAction = "user.role_change"
	AuditActionUserActivate   AuditAction = "user.activate"
	AuditActionUserDeactivate AuditAction = "user.deactivate"

	// Content management actions
	AuditActionContentCreate  AuditAction = "content.create"
	AuditActionContentUpdate  AuditAction = "content.update"
	AuditActionContentDelete  AuditAction = "content.delete"
	AuditActionContentPublish AuditAction = "content.publish"
	AuditActionContentArchive AuditAction = "content.archive"

	// Media actions
	AuditActionMediaUpload AuditAction = "media.upload"
	AuditActionMediaDelete AuditAction = "media.delete"

	// Tenant management actions
	AuditActionTenantCreate     AuditAction = "tenant.create"
	AuditActionTenantUpdate     AuditAction = "tenant.update"
	AuditActionTenantActivate   AuditAction = "tenant.activate"
	AuditActionTenantDeactivate AuditAction = "tenant.deactivate"
)

// AuditSeverity represents the severity level of an audit event
type AuditSeverity string

const (
	AuditSeverityInfo     AuditSeverity = "info"     // Normal operations
	AuditSeverityWarning  AuditSeverity = "warning"  // Unusual but not critical
	AuditSeverityCritical AuditSeverity = "critical" // Security-sensitive operations
)

// AuditLog represents a single audit log entry
type AuditLog struct {
	ID        string        `json:"id"`
	TenantID  string        `json:"tenant_id"`
	UserID    *string       `json:"user_id,omitempty"` // Nullable for public actions
	Action    AuditAction   `json:"action"`
	Severity  AuditSeverity `json:"severity"`

	// Resource information
	ResourceType string  `json:"resource_type,omitempty"` // e.g., "content", "user", "media"
	ResourceID   *string `json:"resource_id,omitempty"`   // ID of the affected resource

	// Request metadata
	IPAddress string `json:"ip_address"`
	UserAgent string `json:"user_agent"`

	// Additional context (stored as JSON in database)
	Metadata map[string]interface{} `json:"metadata,omitempty"`

	// Result
	Success bool    `json:"success"`
	Error   *string `json:"error,omitempty"` // Error message if failed

	Timestamp time.Time `json:"timestamp"`
}

// NewAuditLog creates a new audit log entry with defaults
func NewAuditLog(tenantID string, action AuditAction) *AuditLog {
	return &AuditLog{
		TenantID:  tenantID,
		Action:    action,
		Severity:  AuditSeverityInfo, // Default severity
		Metadata:  make(map[string]interface{}),
		Success:   true, // Default to success
		Timestamp: time.Now(),
	}
}

// WithUser sets the user ID
func (a *AuditLog) WithUser(userID string) *AuditLog {
	a.UserID = &userID
	return a
}

// WithResource sets the resource information
func (a *AuditLog) WithResource(resourceType, resourceID string) *AuditLog {
	a.ResourceType = resourceType
	a.ResourceID = &resourceID
	return a
}

// WithSeverity sets the severity level
func (a *AuditLog) WithSeverity(severity AuditSeverity) *AuditLog {
	a.Severity = severity
	return a
}

// WithMetadata adds metadata to the audit log
func (a *AuditLog) WithMetadata(key string, value interface{}) *AuditLog {
	if a.Metadata == nil {
		a.Metadata = make(map[string]interface{})
	}
	a.Metadata[key] = value
	return a
}

// WithRequest sets request metadata
func (a *AuditLog) WithRequest(ipAddress, userAgent string) *AuditLog {
	a.IPAddress = ipAddress
	a.UserAgent = userAgent
	return a
}

// WithError marks the action as failed with an error
func (a *AuditLog) WithError(err error) *AuditLog {
	a.Success = false
	errMsg := err.Error()
	a.Error = &errMsg
	return a
}

// IsCritical returns true if the audit log is critical severity
func (a *AuditLog) IsCritical() bool {
	return a.Severity == AuditSeverityCritical
}
