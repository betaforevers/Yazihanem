-- Create tenants table in public schema
-- This table holds metadata for all tenants
CREATE TABLE IF NOT EXISTS public.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    schema_name VARCHAR(63) NOT NULL UNIQUE,
    domain VARCHAR(255) NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    max_users INTEGER NOT NULL DEFAULT 10,
    max_storage BIGINT NOT NULL DEFAULT 1073741824, -- 1GB in bytes
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create index on domain for fast lookup during tenant resolution
CREATE INDEX idx_tenants_domain ON public.tenants(domain);

-- Create index on schema_name for schema validation
CREATE INDEX idx_tenants_schema_name ON public.tenants(schema_name);

-- Create index on is_active for filtering active tenants
CREATE INDEX idx_tenants_is_active ON public.tenants(is_active);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for automatic updated_at update
CREATE TRIGGER update_tenants_updated_at
    BEFORE UPDATE ON public.tenants
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default tenant for development
INSERT INTO public.tenants (name, schema_name, domain, is_active, max_users, max_storage)
VALUES ('Default Tenant', 'tenant_default', 'localhost', true, 100, 10737418240)
ON CONFLICT (domain) DO NOTHING;
