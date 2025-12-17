-- Demo Tenant and User Creation Script
-- This script creates a demo tenant and demo user for testing

-- 1. Create demo tenant in public.tenants table
INSERT INTO public.tenants (id, name, schema_name, domain, is_active, max_users, max_storage)
VALUES
    ('550e8400-e29b-41d4-a716-446655440000', 'Demo Balıkçılık A.Ş.', 'tenant_demo_balikcilik', 'demo.yazihanem.com', true, 50, 10737418240)
ON CONFLICT (domain) DO NOTHING;

-- 2. Create schema for demo tenant
CREATE SCHEMA IF NOT EXISTS tenant_demo_balikcilik;

-- 3. Create users table in demo tenant schema
CREATE TABLE IF NOT EXISTS tenant_demo_balikcilik.users (
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

-- 4. Create demo users
-- Password for all demo users: "demo123"
-- Hash: $2a$10$MRU1cau7WnB69BcuM242BO8DUn5p9wjNqFrm7bKpuf.JUCoGwrPci
INSERT INTO tenant_demo_balikcilik.users (id, email, password_hash, first_name, last_name, role, is_active)
VALUES
    (
        '660e8400-e29b-41d4-a716-446655440001',
        'admin@demo.com',
        '$2a$10$MRU1cau7WnB69BcuM242BO8DUn5p9wjNqFrm7bKpuf.JUCoGwrPci',
        'Ahmet',
        'Yılmaz',
        'admin',
        true
    ),
    (
        '660e8400-e29b-41d4-a716-446655440002',
        'editor@demo.com',
        '$2a$10$MRU1cau7WnB69BcuM242BO8DUn5p9wjNqFrm7bKpuf.JUCoGwrPci',
        'Ayşe',
        'Kara',
        'editor',
        true
    ),
    (
        '660e8400-e29b-41d4-a716-446655440003',
        'viewer@demo.com',
        '$2a$10$MRU1cau7WnB69BcuM242BO8DUn5p9wjNqFrm7bKpuf.JUCoGwrPci',
        'Mehmet',
        'Demir',
        'viewer',
        true
    )
ON CONFLICT (email) DO NOTHING;

-- Create other required tables for demo tenant
CREATE TABLE IF NOT EXISTS tenant_demo_balikcilik.content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(500) NOT NULL,
    slug VARCHAR(500) NOT NULL UNIQUE,
    body TEXT NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('draft', 'published', 'archived')),
    author_id UUID NOT NULL REFERENCES tenant_demo_balikcilik.users(id) ON DELETE CASCADE,
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_demo_balikcilik.media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    size_bytes BIGINT NOT NULL,
    storage_path VARCHAR(500) NOT NULL,
    uploaded_by UUID NOT NULL REFERENCES tenant_demo_balikcilik.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_tenant_demo_balikcilik_users_email ON tenant_demo_balikcilik.users(email);
CREATE INDEX IF NOT EXISTS idx_tenant_demo_balikcilik_users_role ON tenant_demo_balikcilik.users(role);
