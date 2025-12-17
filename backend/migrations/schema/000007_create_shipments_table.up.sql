-- Create shipments table in tenant schemas
CREATE TABLE IF NOT EXISTS tenant_default.shipments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tracking_number VARCHAR(100) NOT NULL UNIQUE,
    customer VARCHAR(255) NOT NULL,
    destination VARCHAR(255) NOT NULL,
    departure_date TIMESTAMP WITH TIME ZONE NOT NULL,
    estimated_arrival TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'preparing' CHECK (status IN ('preparing', 'in_transit', 'customs', 'delivered', 'delayed')),
    carrier VARCHAR(255) NOT NULL,
    weight DECIMAL(10, 2) NOT NULL,
    temperature DECIMAL(5, 2),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_shipments_status ON tenant_default.shipments(status);
CREATE INDEX IF NOT EXISTS idx_shipments_tracking ON tenant_default.shipments(tracking_number);

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        CREATE TABLE IF NOT EXISTS tenant_demo_balikcilik.shipments (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            tracking_number VARCHAR(100) NOT NULL UNIQUE,
            customer VARCHAR(255) NOT NULL,
            destination VARCHAR(255) NOT NULL,
            departure_date TIMESTAMP WITH TIME ZONE NOT NULL,
            estimated_arrival TIMESTAMP WITH TIME ZONE NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT 'preparing' CHECK (status IN ('preparing', 'in_transit', 'customs', 'delivered', 'delayed')),
            carrier VARCHAR(255) NOT NULL,
            weight DECIMAL(10, 2) NOT NULL,
            temperature DECIMAL(5, 2),
            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_shipments_status ON tenant_demo_balikcilik.shipments(status);
        CREATE INDEX IF NOT EXISTS idx_shipments_tracking ON tenant_demo_balikcilik.shipments(tracking_number);
    END IF;
END $$;
