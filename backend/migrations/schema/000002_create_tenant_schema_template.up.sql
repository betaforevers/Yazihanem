-- This migration creates the schema structure for a tenant
-- It will be executed dynamically for each new tenant
-- The placeholder {TENANT_SCHEMA} will be replaced with actual schema name

-- Create schema for tenant (executed dynamically)
-- CREATE SCHEMA IF NOT EXISTS {TENANT_SCHEMA};

-- Users table within tenant schema
CREATE TABLE IF NOT EXISTS {TENANT_SCHEMA}.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'editor', 'viewer')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for users table
CREATE INDEX idx_{TENANT_SCHEMA}_users_email ON {TENANT_SCHEMA}.users(email);
CREATE INDEX idx_{TENANT_SCHEMA}_users_role ON {TENANT_SCHEMA}.users(role);
CREATE INDEX idx_{TENANT_SCHEMA}_users_is_active ON {TENANT_SCHEMA}.users(is_active);

-- Create trigger for users updated_at
CREATE TRIGGER update_{TENANT_SCHEMA}_users_updated_at
    BEFORE UPDATE ON {TENANT_SCHEMA}.users
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Content table within tenant schema
CREATE TABLE IF NOT EXISTS {TENANT_SCHEMA}.content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(500) NOT NULL,
    slug VARCHAR(500) NOT NULL UNIQUE,
    body TEXT NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('draft', 'published', 'archived')),
    author_id UUID NOT NULL REFERENCES {TENANT_SCHEMA}.users(id) ON DELETE CASCADE,
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for content table
CREATE INDEX idx_{TENANT_SCHEMA}_content_slug ON {TENANT_SCHEMA}.content(slug);
CREATE INDEX idx_{TENANT_SCHEMA}_content_status ON {TENANT_SCHEMA}.content(status);
CREATE INDEX idx_{TENANT_SCHEMA}_content_author_id ON {TENANT_SCHEMA}.content(author_id);
CREATE INDEX idx_{TENANT_SCHEMA}_content_published_at ON {TENANT_SCHEMA}.content(published_at);

-- Create trigger for content updated_at
CREATE TRIGGER update_{TENANT_SCHEMA}_content_updated_at
    BEFORE UPDATE ON {TENANT_SCHEMA}.content
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Media table for file uploads
CREATE TABLE IF NOT EXISTS {TENANT_SCHEMA}.media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    size_bytes BIGINT NOT NULL,
    storage_path VARCHAR(500) NOT NULL,
    uploaded_by UUID NOT NULL REFERENCES {TENANT_SCHEMA}.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for media table
CREATE INDEX idx_{TENANT_SCHEMA}_media_uploaded_by ON {TENANT_SCHEMA}.media(uploaded_by);
CREATE INDEX idx_{TENANT_SCHEMA}_media_mime_type ON {TENANT_SCHEMA}.media(mime_type);

-- Content-Media relationship (many-to-many)
CREATE TABLE IF NOT EXISTS {TENANT_SCHEMA}.content_media (
    content_id UUID NOT NULL REFERENCES {TENANT_SCHEMA}.content(id) ON DELETE CASCADE,
    media_id UUID NOT NULL REFERENCES {TENANT_SCHEMA}.media(id) ON DELETE CASCADE,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (content_id, media_id)
);

-- Create index for content_media queries
CREATE INDEX idx_{TENANT_SCHEMA}_content_media_content_id ON {TENANT_SCHEMA}.content_media(content_id);
CREATE INDEX idx_{TENANT_SCHEMA}_content_media_media_id ON {TENANT_SCHEMA}.content_media(media_id);
