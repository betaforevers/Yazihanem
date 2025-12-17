-- Create certificates table in tenant schemas
CREATE TABLE IF NOT EXISTS tenant_default.certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    certificate_type VARCHAR(100) NOT NULL,
    certificate_number VARCHAR(100) NOT NULL UNIQUE,
    standard VARCHAR(255) NOT NULL,
    issue_date TIMESTAMP WITH TIME ZONE NOT NULL,
    expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expiring_soon', 'expired', 'pending_renewal')),
    issuer VARCHAR(255) NOT NULL,
    scope TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_certificates_status ON tenant_default.certificates(status);
CREATE INDEX IF NOT EXISTS idx_certificates_type ON tenant_default.certificates(certificate_type);

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        CREATE TABLE IF NOT EXISTS tenant_demo_balikcilik.certificates (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            certificate_type VARCHAR(100) NOT NULL,
            certificate_number VARCHAR(100) NOT NULL UNIQUE,
            standard VARCHAR(255) NOT NULL,
            issue_date TIMESTAMP WITH TIME ZONE NOT NULL,
            expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expiring_soon', 'expired', 'pending_renewal')),
            issuer VARCHAR(255) NOT NULL,
            scope TEXT NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_certificates_status ON tenant_demo_balikcilik.certificates(status);
        CREATE INDEX IF NOT EXISTS idx_certificates_type ON tenant_demo_balikcilik.certificates(certificate_type);
    END IF;
END $$;
