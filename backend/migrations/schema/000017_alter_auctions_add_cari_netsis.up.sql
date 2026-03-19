-- Alter auctions (Fisler) table:
--   1. cari_id  → satışın yapıldığı esnaf
--   2. durum    → 'faturalandi' durumu ekleniyor
--   3. Netsis aktarım alanları → e-Fatura entegrasyonu

-- 1. cari_id sütunu
ALTER TABLE tenant_default.auctions
    ADD COLUMN IF NOT EXISTS cari_id UUID
        REFERENCES tenant_default.cariler(id) ON DELETE RESTRICT;

COMMENT ON COLUMN tenant_default.auctions.cari_id IS 'Satışın yapıldığı esnaf/firma (cariler tablosu FK).';

-- 2. durum CHECK kısıtını genişlet: 'faturalandi' ekleniyor
ALTER TABLE tenant_default.auctions
    DROP CONSTRAINT IF EXISTS auctions_durum_check;

ALTER TABLE tenant_default.auctions
    ADD CONSTRAINT auctions_durum_check
        CHECK (durum IN ('acik', 'kapali', 'faturalandi'));

-- 3. Netsis e-Fatura alanları
ALTER TABLE tenant_default.auctions
    ADD COLUMN IF NOT EXISTS netsis_aktarim_durumu VARCHAR(20) NOT NULL DEFAULT 'beklemede'
        CHECK (netsis_aktarim_durumu IN ('beklemede', 'aktarildi', 'hata')),
    ADD COLUMN IF NOT EXISTS netsis_fatura_no       VARCHAR(50),
    ADD COLUMN IF NOT EXISTS netsis_aktarim_tarihi  TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS netsis_hata_mesaji     TEXT;

COMMENT ON COLUMN tenant_default.auctions.netsis_aktarim_durumu  IS 'Netsis aktarım durumu: beklemede | aktarildi | hata';
COMMENT ON COLUMN tenant_default.auctions.netsis_fatura_no       IS 'Netsis tarafından üretilen e-Fatura numarası.';
COMMENT ON COLUMN tenant_default.auctions.netsis_aktarim_tarihi  IS 'Netsis aktarımının gerçekleştiği zaman.';
COMMENT ON COLUMN tenant_default.auctions.netsis_hata_mesaji     IS 'Aktarım başarısız olduğunda Netsis hata detayı.';

CREATE INDEX IF NOT EXISTS idx_auctions_cari_id                ON tenant_default.auctions(cari_id);
CREATE INDEX IF NOT EXISTS idx_auctions_netsis_aktarim_durumu  ON tenant_default.auctions(netsis_aktarim_durumu);

-- ----------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN

        ALTER TABLE tenant_demo_balikcilik.auctions
            ADD COLUMN IF NOT EXISTS cari_id UUID
                REFERENCES tenant_demo_balikcilik.cariler(id) ON DELETE RESTRICT;

        ALTER TABLE tenant_demo_balikcilik.auctions
            DROP CONSTRAINT IF EXISTS auctions_durum_check;

        ALTER TABLE tenant_demo_balikcilik.auctions
            ADD CONSTRAINT auctions_durum_check
                CHECK (durum IN ('acik', 'kapali', 'faturalandi'));

        ALTER TABLE tenant_demo_balikcilik.auctions
            ADD COLUMN IF NOT EXISTS netsis_aktarim_durumu VARCHAR(20) NOT NULL DEFAULT 'beklemede'
                CHECK (netsis_aktarim_durumu IN ('beklemede', 'aktarildi', 'hata')),
            ADD COLUMN IF NOT EXISTS netsis_fatura_no       VARCHAR(50),
            ADD COLUMN IF NOT EXISTS netsis_aktarim_tarihi  TIMESTAMP WITH TIME ZONE,
            ADD COLUMN IF NOT EXISTS netsis_hata_mesaji     TEXT;

        CREATE INDEX IF NOT EXISTS idx_auctions_cari_id               ON tenant_demo_balikcilik.auctions(cari_id);
        CREATE INDEX IF NOT EXISTS idx_auctions_netsis_aktarim_durumu ON tenant_demo_balikcilik.auctions(netsis_aktarim_durumu);

    END IF;
END $$;
