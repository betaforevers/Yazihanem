-- Drop auctions and auction_items tables from tenant schemas
DROP TABLE IF EXISTS tenant_default.auction_items;
DROP TABLE IF EXISTS tenant_default.auctions;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'tenant_demo_balikcilik') THEN
        DROP TABLE IF EXISTS tenant_demo_balikcilik.auction_items;
        DROP TABLE IF EXISTS tenant_demo_balikcilik.auctions;
    END IF;
END $$;
