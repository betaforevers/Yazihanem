-- Create cariler (current accounts) table in tenant schemas
-- Cariler: Satışın yapıldığı esnaf/firma kaydı (Netsis cari eşleşmesi dahil)

CREATE TABLE IF NOT EXISTS tenant_default.cariler (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kod             VARCHAR(20)  NOT NULL UNIQUE,             -- Dahili cari kodu (örn: C0001)
    unvan           VARCHAR(255) NOT NULL,                    -- Firma/şahıs adı
    vergi_no        VARCHAR(20)  NOT NULL,                    -- Vergi kimlik numarası (10 veya 11 hane)
    vergi_dairesi   VARCHAR(100) NOT NULL,                    -- Vergi dairesi adı
    telefon         VARCHAR(20),
    adres           TEXT,
    e_fatura_mukellef BOOLEAN NOT NULL DEFAULT FALSE,         -- GİB e-Fatura mükellefi mi?
    netsis_cari_kodu  VARCHAR(30),                            -- Netsis'teki eşleşen cari kodu
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_cariler_kod        ON tenant_default.cariler(kod);
CREATE INDEX IF NOT EXISTS idx_cariler_vergi_no   ON tenant_default.cariler(vergi_no);
CREATE INDEX IF NOT EXISTS idx_cariler_unvan      ON tenant_default.cariler(unvan);
CREATE INDEX IF NOT EXISTS idx_cariler_is_active  ON tenant_default.cariler(is_active);

CREATE TRIGGER update_tenant_default_cariler_updated_at
    BEFORE UPDATE ON tenant_default.cariler
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ----------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN

        CREATE TABLE IF NOT EXISTS tenant_demo_balikcilik.cariler (
            id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            kod             VARCHAR(20)  NOT NULL UNIQUE,
            unvan           VARCHAR(255) NOT NULL,
            vergi_no        VARCHAR(20)  NOT NULL,
            vergi_dairesi   VARCHAR(100) NOT NULL,
            telefon         VARCHAR(20),
            adres           TEXT,
            e_fatura_mukellef BOOLEAN NOT NULL DEFAULT FALSE,
            netsis_cari_kodu  VARCHAR(30),
            is_active       BOOLEAN NOT NULL DEFAULT TRUE,
            created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_cariler_kod        ON tenant_demo_balikcilik.cariler(kod);
        CREATE INDEX IF NOT EXISTS idx_cariler_vergi_no   ON tenant_demo_balikcilik.cariler(vergi_no);
        CREATE INDEX IF NOT EXISTS idx_cariler_unvan      ON tenant_demo_balikcilik.cariler(unvan);
        CREATE INDEX IF NOT EXISTS idx_cariler_is_active  ON tenant_demo_balikcilik.cariler(is_active);

        CREATE TRIGGER update_tenant_demo_balikcilik_cariler_updated_at
            BEFORE UPDATE ON tenant_demo_balikcilik.cariler
            FOR EACH ROW
            EXECUTE FUNCTION public.update_updated_at_column();

    END IF;
END $$;
