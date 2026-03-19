-- Alter fish (Baliklar) table: Netsis stok kodu ve KDV oranı ekleniyor
-- Türkiye'de su ürünleri için KDV oranı genellikle %1'dir (2024 itibarıyla)

ALTER TABLE tenant_default.fish
    ADD COLUMN IF NOT EXISTS kdv_orani        DECIMAL(5, 2) NOT NULL DEFAULT 1.00
        CHECK (kdv_orani >= 0 AND kdv_orani <= 100),
    ADD COLUMN IF NOT EXISTS netsis_stok_kodu VARCHAR(50);

COMMENT ON COLUMN tenant_default.fish.kdv_orani        IS 'KDV oranı (yüzde). Su ürünleri için varsayılan %1.';
COMMENT ON COLUMN tenant_default.fish.netsis_stok_kodu IS 'Netsis ERP sistemindeki eşleşen stok kartı kodu.';

-- ----------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN

        ALTER TABLE tenant_demo_balikcilik.fish
            ADD COLUMN IF NOT EXISTS kdv_orani        DECIMAL(5, 2) NOT NULL DEFAULT 1.00
                CHECK (kdv_orani >= 0 AND kdv_orani <= 100),
            ADD COLUMN IF NOT EXISTS netsis_stok_kodu VARCHAR(50);

    END IF;
END $$;
