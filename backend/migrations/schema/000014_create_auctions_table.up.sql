-- Create auctions and auction_items tables in tenant schemas
CREATE TABLE IF NOT EXISTS tenant_default.auctions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fis_no VARCHAR(50) NOT NULL UNIQUE,
    mezat_tarihi TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    durum VARCHAR(20) NOT NULL DEFAULT 'acik' CHECK (durum IN ('acik', 'kapali')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_auctions_fis_no ON tenant_default.auctions(fis_no);
CREATE INDEX IF NOT EXISTS idx_auctions_durum ON tenant_default.auctions(durum);

CREATE TABLE IF NOT EXISTS tenant_default.auction_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auction_id UUID NOT NULL REFERENCES tenant_default.auctions(id) ON DELETE CASCADE,
    fish_id UUID NOT NULL REFERENCES tenant_default.fish(id) ON DELETE RESTRICT,
    boat_id UUID NOT NULL REFERENCES tenant_default.boats(id) ON DELETE RESTRICT,
    miktar DECIMAL(10, 2) NOT NULL,
    birim_fiyat DECIMAL(10, 2) NOT NULL,
    toplam_fiyat DECIMAL(12, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_auction_items_auction_id ON tenant_default.auction_items(auction_id);
CREATE INDEX IF NOT EXISTS idx_auction_items_fish_id ON tenant_default.auction_items(fish_id);
CREATE INDEX IF NOT EXISTS idx_auction_items_boat_id ON tenant_default.auction_items(boat_id);

-- Add the same tables to tenant_demo_balikcilik if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        CREATE TABLE IF NOT EXISTS tenant_demo_balikcilik.auctions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            fis_no VARCHAR(50) NOT NULL UNIQUE,
            mezat_tarihi TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
            durum VARCHAR(20) NOT NULL DEFAULT 'acik' CHECK (durum IN ('acik', 'kapali')),
            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_auctions_fis_no ON tenant_demo_balikcilik.auctions(fis_no);
        CREATE INDEX IF NOT EXISTS idx_auctions_durum ON tenant_demo_balikcilik.auctions(durum);

        CREATE TABLE IF NOT EXISTS tenant_demo_balikcilik.auction_items (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            auction_id UUID NOT NULL REFERENCES tenant_demo_balikcilik.auctions(id) ON DELETE CASCADE,
            fish_id UUID NOT NULL REFERENCES tenant_demo_balikcilik.fish(id) ON DELETE RESTRICT,
            boat_id UUID NOT NULL REFERENCES tenant_demo_balikcilik.boats(id) ON DELETE RESTRICT,
            miktar DECIMAL(10, 2) NOT NULL,
            birim_fiyat DECIMAL(10, 2) NOT NULL,
            toplam_fiyat DECIMAL(12, 2) NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_auction_items_auction_id ON tenant_demo_balikcilik.auction_items(auction_id);
        CREATE INDEX IF NOT EXISTS idx_auction_items_fish_id ON tenant_demo_balikcilik.auction_items(fish_id);
        CREATE INDEX IF NOT EXISTS idx_auction_items_boat_id ON tenant_demo_balikcilik.auction_items(boat_id);
    END IF;
END $$;
