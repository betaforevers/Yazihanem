-- Rollback: Remove last_login_at column from existing tenant schemas

-- For tenant_default
ALTER TABLE tenant_default.users
DROP COLUMN IF EXISTS last_login_at;

-- For tenant_demo_balikcilik (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        ALTER TABLE tenant_demo_balikcilik.users
        DROP COLUMN IF EXISTS last_login_at;
    END IF;
END $$;
