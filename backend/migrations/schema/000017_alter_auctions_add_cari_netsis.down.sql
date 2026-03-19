ALTER TABLE tenant_default.auctions
    DROP COLUMN IF EXISTS cari_id,
    DROP COLUMN IF EXISTS netsis_aktarim_durumu,
    DROP COLUMN IF EXISTS netsis_fatura_no,
    DROP COLUMN IF EXISTS netsis_aktarim_tarihi,
    DROP COLUMN IF EXISTS netsis_hata_mesaji;

ALTER TABLE tenant_default.auctions
    DROP CONSTRAINT IF EXISTS auctions_durum_check;

ALTER TABLE tenant_default.auctions
    ADD CONSTRAINT auctions_durum_check
        CHECK (durum IN ('acik', 'kapali'));

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        ALTER TABLE tenant_demo_balikcilik.auctions
            DROP COLUMN IF EXISTS cari_id,
            DROP COLUMN IF EXISTS netsis_aktarim_durumu,
            DROP COLUMN IF EXISTS netsis_fatura_no,
            DROP COLUMN IF EXISTS netsis_aktarim_tarihi,
            DROP COLUMN IF EXISTS netsis_hata_mesaji;

        ALTER TABLE tenant_demo_balikcilik.auctions
            DROP CONSTRAINT IF EXISTS auctions_durum_check;

        ALTER TABLE tenant_demo_balikcilik.auctions
            ADD CONSTRAINT auctions_durum_check
                CHECK (durum IN ('acik', 'kapali'));
    END IF;
END $$;
