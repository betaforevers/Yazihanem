-- Create boats table in tenant schemas
CREATE TABLE IF NOT EXISTS tenant_default.boats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ad VARCHAR(255) NOT NULL,
    komisyon_yuzde DECIMAL(5, 2) NOT NULL DEFAULT 0 CHECK (komisyon_yuzde >= 0 AND komisyon_yuzde <= 100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_boats_ad ON tenant_default.boats(ad);

CREATE TRIGGER update_tenant_default_boats_updated_at
    BEFORE UPDATE ON tenant_default.boats
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Add the same table to tenant_demo_balikcilik if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        CREATE TABLE IF NOT EXISTS tenant_demo_balikcilik.boats (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            ad VARCHAR(255) NOT NULL,
            komisyon_yuzde DECIMAL(5, 2) NOT NULL DEFAULT 0 CHECK (komisyon_yuzde >= 0 AND komisyon_yuzde <= 100),
            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_boats_ad ON tenant_demo_balikcilik.boats(ad);

        CREATE TRIGGER update_tenant_demo_balikcilik_boats_updated_at
            BEFORE UPDATE ON tenant_demo_balikcilik.boats
            FOR EACH ROW
            EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
END $$;
