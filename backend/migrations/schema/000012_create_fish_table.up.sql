-- Create fish table in tenant schemas
CREATE TABLE IF NOT EXISTS tenant_default.fish (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tur VARCHAR(255) NOT NULL,
    birim_turu VARCHAR(20) NOT NULL DEFAULT 'kilogram' CHECK (birim_turu IN ('adet', 'gram', 'kilogram')),
    miktar DECIMAL(10, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_fish_tur ON tenant_default.fish(tur);

-- Create trigger for updated_at
CREATE TRIGGER update_tenant_default_fish_updated_at
    BEFORE UPDATE ON tenant_default.fish
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Add the same table to tenant_demo_balikcilik if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        CREATE TABLE IF NOT EXISTS tenant_demo_balikcilik.fish (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            tur VARCHAR(255) NOT NULL,
            birim_turu VARCHAR(20) NOT NULL DEFAULT 'kilogram' CHECK (birim_turu IN ('adet', 'gram', 'kilogram')),
            miktar DECIMAL(10, 2) NOT NULL DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_fish_tur ON tenant_demo_balikcilik.fish(tur);

        CREATE TRIGGER update_tenant_demo_balikcilik_fish_updated_at
            BEFORE UPDATE ON tenant_demo_balikcilik.fish
            FOR EACH ROW
            EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
END $$;
