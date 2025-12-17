-- Create documents table in tenant schemas
CREATE TABLE IF NOT EXISTS tenant_default.documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_type VARCHAR(100) NOT NULL,
    document_number VARCHAR(100) NOT NULL UNIQUE,
    shipment_id VARCHAR(100),
    customer VARCHAR(255) NOT NULL,
    issue_date TIMESTAMP WITH TIME ZONE NOT NULL,
    expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
    issuer VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_documents_status ON tenant_default.documents(status);
CREATE INDEX IF NOT EXISTS idx_documents_type ON tenant_default.documents(document_type);

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        CREATE TABLE IF NOT EXISTS tenant_demo_balikcilik.documents (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            document_type VARCHAR(100) NOT NULL,
            document_number VARCHAR(100) NOT NULL UNIQUE,
            shipment_id VARCHAR(100),
            customer VARCHAR(255) NOT NULL,
            issue_date TIMESTAMP WITH TIME ZONE NOT NULL,
            expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
            issuer VARCHAR(255) NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_documents_status ON tenant_demo_balikcilik.documents(status);
        CREATE INDEX IF NOT EXISTS idx_documents_type ON tenant_demo_balikcilik.documents(document_type);
    END IF;
END $$;
