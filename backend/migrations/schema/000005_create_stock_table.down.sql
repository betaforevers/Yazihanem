-- Drop stock table from tenant schemas
DROP TABLE IF EXISTS tenant_default.stock;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        DROP TABLE IF EXISTS tenant_demo_balikcilik.stock;
    END IF;
END $$;
