ALTER TABLE tenant_default.fish
    DROP COLUMN IF EXISTS kdv_orani,
    DROP COLUMN IF EXISTS netsis_stok_kodu;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        ALTER TABLE tenant_demo_balikcilik.fish
            DROP COLUMN IF EXISTS kdv_orani,
            DROP COLUMN IF EXISTS netsis_stok_kodu;
    END IF;
END $$;
