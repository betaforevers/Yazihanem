-- Drop trigger
DROP TRIGGER IF EXISTS update_tenants_updated_at ON public.tenants;

-- Drop trigger function
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop indexes
DROP INDEX IF EXISTS public.idx_tenants_is_active;
DROP INDEX IF EXISTS public.idx_tenants_schema_name;
DROP INDEX IF EXISTS public.idx_tenants_domain;

-- Drop tenants table
DROP TABLE IF EXISTS public.tenants;
