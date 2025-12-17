-- Create stock table in tenant schemas
CREATE TABLE IF NOT EXISTS tenant_default.stock (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_name VARCHAR(255) NOT NULL,
    species VARCHAR(255) NOT NULL,
    quantity DECIMAL(10, 2) NOT NULL DEFAULT 0,
    unit VARCHAR(20) NOT NULL DEFAULT 'kg',
    location VARCHAR(255) NOT NULL,
    temperature DECIMAL(5, 2),
    status VARCHAR(20) NOT NULL DEFAULT 'in_stock' CHECK (status IN ('in_stock', 'low_stock', 'out_of_stock')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_stock_status ON tenant_default.stock(status);
CREATE INDEX IF NOT EXISTS idx_stock_product_name ON tenant_default.stock(product_name);

-- Add the same table to tenant_demo_balikcilik if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        CREATE TABLE IF NOT EXISTS tenant_demo_balikcilik.stock (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            product_name VARCHAR(255) NOT NULL,
            species VARCHAR(255) NOT NULL,
            quantity DECIMAL(10, 2) NOT NULL DEFAULT 0,
            unit VARCHAR(20) NOT NULL DEFAULT 'kg',
            location VARCHAR(255) NOT NULL,
            temperature DECIMAL(5, 2),
            status VARCHAR(20) NOT NULL DEFAULT 'in_stock' CHECK (status IN ('in_stock', 'low_stock', 'out_of_stock')),
            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_stock_status ON tenant_demo_balikcilik.stock(status);
        CREATE INDEX IF NOT EXISTS idx_stock_product_name ON tenant_demo_balikcilik.stock(product_name);
    END IF;
END $$;
