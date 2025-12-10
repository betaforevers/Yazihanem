-- Create audit_logs table in public schema
-- This table stores audit logs for all tenants for security and compliance

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Tenant and user context
    tenant_id UUID NOT NULL,
    user_id UUID, -- Nullable for public/unauthenticated actions

    -- Action details
    action VARCHAR(100) NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),

    -- Resource information
    resource_type VARCHAR(50),
    resource_id UUID,

    -- Request metadata
    ip_address INET NOT NULL,
    user_agent TEXT,

    -- Additional context (JSON)
    metadata JSONB,

    -- Result
    success BOOLEAN NOT NULL DEFAULT true,
    error TEXT, -- Error message if failed

    -- Timestamp
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for efficient querying
CREATE INDEX idx_audit_logs_tenant_id ON public.audit_logs(tenant_id);
CREATE INDEX idx_audit_logs_user_id ON public.audit_logs(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_audit_logs_action ON public.audit_logs(action);
CREATE INDEX idx_audit_logs_severity ON public.audit_logs(severity);
CREATE INDEX idx_audit_logs_timestamp ON public.audit_logs(timestamp DESC);
CREATE INDEX idx_audit_logs_resource ON public.audit_logs(resource_type, resource_id) WHERE resource_type IS NOT NULL;

-- Composite index for common queries
CREATE INDEX idx_audit_logs_tenant_timestamp ON public.audit_logs(tenant_id, timestamp DESC);
CREATE INDEX idx_audit_logs_tenant_action ON public.audit_logs(tenant_id, action, timestamp DESC);

-- Create index on JSONB metadata for fast JSON queries
CREATE INDEX idx_audit_logs_metadata ON public.audit_logs USING GIN(metadata);

-- Add comment for documentation
COMMENT ON TABLE public.audit_logs IS 'Audit trail for all tenant actions (GDPR/KVKK compliance)';
COMMENT ON COLUMN public.audit_logs.metadata IS 'Additional context stored as JSON (e.g., changed fields, old values)';
COMMENT ON COLUMN public.audit_logs.severity IS 'Severity level: info (normal), warning (unusual), critical (security-sensitive)';
