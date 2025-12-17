-- Create reports table in tenant schemas
CREATE TABLE IF NOT EXISTS tenant_default.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL CHECK (category IN ('stock', 'sales', 'quality', 'compliance', 'finance')),
    format VARCHAR(20) NOT NULL CHECK (format IN ('pdf', 'excel', 'csv')),
    file_path VARCHAR(500),
    file_size BIGINT,
    generated_by UUID,
    parameters JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_reports_category ON tenant_default.reports(category);
CREATE INDEX IF NOT EXISTS idx_reports_format ON tenant_default.reports(format);

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        CREATE TABLE IF NOT EXISTS tenant_demo_balikcilik.reports (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            description TEXT,
            category VARCHAR(50) NOT NULL CHECK (category IN ('stock', 'sales', 'quality', 'compliance', 'finance')),
            format VARCHAR(20) NOT NULL CHECK (format IN ('pdf', 'excel', 'csv')),
            file_path VARCHAR(500),
            file_size BIGINT,
            generated_by UUID,
            parameters JSONB,
            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_reports_category ON tenant_demo_balikcilik.reports(category);
        CREATE INDEX IF NOT EXISTS idx_reports_format ON tenant_demo_balikcilik.reports(format);
    END IF;
END $$;
