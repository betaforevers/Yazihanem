-- Fix users table in tenant_default schema to match sqlc schema
ALTER TABLE tenant_default.users
  ADD COLUMN IF NOT EXISTS first_name VARCHAR(100),
  ADD COLUMN IF NOT EXISTS last_name VARCHAR(100),
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Migrate existing 'name' data to first_name and last_name
UPDATE tenant_default.users
SET first_name = COALESCE(SPLIT_PART(name, ' ', 1), ''),
    last_name = COALESCE(NULLIF(TRIM(SUBSTRING(name FROM POSITION(' ' IN name))), ''), '')
WHERE first_name IS NULL;

-- Set is_active to true for all existing users
UPDATE tenant_default.users
SET is_active = true
WHERE is_active IS NULL;

-- Make columns NOT NULL after data migration
ALTER TABLE tenant_default.users
  ALTER COLUMN first_name SET NOT NULL,
  ALTER COLUMN last_login_at DROP NOT NULL,
  ALTER COLUMN is_active SET NOT NULL,
  ALTER COLUMN is_active SET DEFAULT true;

-- Remove old name column
ALTER TABLE tenant_default.users DROP COLUMN IF EXISTS name;
