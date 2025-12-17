-- Revert users table changes
ALTER TABLE tenant_default.users
  ADD COLUMN IF NOT EXISTS name VARCHAR(255);

-- Migrate back to name column
UPDATE tenant_default.users
SET name = CONCAT_WS(' ', first_name, last_name)
WHERE name IS NULL;

-- Drop the new columns
ALTER TABLE tenant_default.users
  DROP COLUMN IF EXISTS first_name,
  DROP COLUMN IF EXISTS last_name,
  DROP COLUMN IF EXISTS is_active;
