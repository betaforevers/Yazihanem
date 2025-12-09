-- Rollback tenant schema structure
-- The placeholder {TENANT_SCHEMA} will be replaced with actual schema name

-- Drop content_media table
DROP TABLE IF EXISTS {TENANT_SCHEMA}.content_media;

-- Drop media table
DROP TABLE IF EXISTS {TENANT_SCHEMA}.media;

-- Drop content table
DROP TABLE IF EXISTS {TENANT_SCHEMA}.content;

-- Drop users table
DROP TABLE IF EXISTS {TENANT_SCHEMA}.users;

-- Drop schema (executed dynamically)
-- DROP SCHEMA IF EXISTS {TENANT_SCHEMA} CASCADE;
