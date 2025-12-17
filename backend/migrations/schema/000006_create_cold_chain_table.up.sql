-- Create cold_chain table in tenant schemas
CREATE TABLE IF NOT EXISTS tenant_default.cold_chain (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_name VARCHAR(255) NOT NULL,
    batch_id VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL,
    temperature DECIMAL(5, 2) NOT NULL,
    humidity DECIMAL(5, 2),
    status VARCHAR(20) NOT NULL DEFAULT 'normal' CHECK (status IN ('normal', 'warning', 'critical')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_cold_chain_status ON tenant_default.cold_chain(status);
CREATE INDEX IF NOT EXISTS idx_cold_chain_batch_id ON tenant_default.cold_chain(batch_id);

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        CREATE TABLE IF NOT EXISTS tenant_demo_balikcilik.cold_chain (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            product_name VARCHAR(255) NOT NULL,
            batch_id VARCHAR(100) NOT NULL,
            location VARCHAR(255) NOT NULL,
            temperature DECIMAL(5, 2) NOT NULL,
            humidity DECIMAL(5, 2),
            status VARCHAR(20) NOT NULL DEFAULT 'normal' CHECK (status IN ('normal', 'warning', 'critical')),
            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_cold_chain_status ON tenant_demo_balikcilik.cold_chain(status);
        CREATE INDEX IF NOT EXISTS idx_cold_chain_batch_id ON tenant_demo_balikcilik.cold_chain(batch_id);
    END IF;
END $$;
