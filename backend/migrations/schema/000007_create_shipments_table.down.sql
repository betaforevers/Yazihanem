DROP TABLE IF EXISTS tenant_default.shipments;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        DROP TABLE IF EXISTS tenant_demo_balikcilik.shipments;
    END IF;
END $$;
