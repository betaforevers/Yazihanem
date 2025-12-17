-- Add last_login_at column to existing tenant schemas
-- This migration fixes schemas created before last_login_at was added

-- For tenant_default (localhost development)
ALTER TABLE tenant_default.users
ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE;

-- For tenant_demo_balikcilik (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        ALTER TABLE tenant_demo_balikcilik.users
        ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- Note: For new tenants created after this point,
-- the column will be included automatically via 000002_create_tenant_schema_template.up.sql
