-- FAZ 3 / 9.2.1
-- ERP Turkiye canli cekirdegi
-- Product / Item / Category / Unit tabloları
--
-- Ana mantik:
-- erp_units: olcu birimleri
-- erp_product_categories: urun / stok kategori agaci
-- erp_items: stok / hizmet / hammadde / masraf karti
-- erp_products: satisa acik urun profili
--
-- Not:
-- erp_items cekirdek karttir.
-- erp_products POS, e-ticaret, B2B/B2C ve katalog tarafinda kullanilacak satilabilir profildir.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS erp_units (
    unit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    unit_code TEXT NOT NULL,
    unit_name TEXT NOT NULL,
    unit_type TEXT NOT NULL DEFAULT 'quantity',

    decimal_precision INTEGER NOT NULL DEFAULT 2,

    is_base_unit BOOLEAN NOT NULL DEFAULT false,
    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_units_unit_type_chk
        CHECK (unit_type IN ('quantity', 'weight', 'volume', 'length', 'time', 'package')),

    CONSTRAINT erp_units_status_chk
        CHECK (status IN ('active', 'passive', 'deleted')),

    CONSTRAINT erp_units_decimal_precision_chk
        CHECK (decimal_precision >= 0 AND decimal_precision <= 6)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_units_tenant_code
    ON erp_units (tenant_id, unit_code)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_units_tenant_status
    ON erp_units (tenant_id, status);


CREATE TABLE IF NOT EXISTS erp_product_categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    parent_category_id UUID REFERENCES erp_product_categories(category_id) ON DELETE RESTRICT,

    category_code TEXT NOT NULL,
    category_name TEXT NOT NULL,
    description TEXT,

    sort_order INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_product_categories_status_chk
        CHECK (status IN ('active', 'passive', 'deleted'))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_product_categories_tenant_code
    ON erp_product_categories (tenant_id, category_code)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_product_categories_tenant_parent
    ON erp_product_categories (tenant_id, parent_category_id);

CREATE INDEX IF NOT EXISTS ix_erp_product_categories_tenant_status
    ON erp_product_categories (tenant_id, status);


CREATE TABLE IF NOT EXISTS erp_items (
    item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    item_code TEXT NOT NULL,
    item_name TEXT NOT NULL,
    item_type TEXT NOT NULL DEFAULT 'stock',

    category_id UUID REFERENCES erp_product_categories(category_id) ON DELETE RESTRICT,
    base_unit_id UUID NOT NULL REFERENCES erp_units(unit_id) ON DELETE RESTRICT,

    barcode TEXT,
    sku TEXT,

    vat_rate NUMERIC(5, 2) NOT NULL DEFAULT 20.00,

    is_inventory_tracked BOOLEAN NOT NULL DEFAULT true,
    is_sales_allowed BOOLEAN NOT NULL DEFAULT true,
    is_purchase_allowed BOOLEAN NOT NULL DEFAULT true,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_items_item_type_chk
        CHECK (item_type IN ('stock', 'service', 'raw_material', 'expense', 'asset', 'package')),

    CONSTRAINT erp_items_status_chk
        CHECK (status IN ('active', 'passive', 'blocked', 'deleted')),

    CONSTRAINT erp_items_vat_rate_chk
        CHECK (vat_rate >= 0 AND vat_rate <= 100)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_items_tenant_code
    ON erp_items (tenant_id, item_code)
    WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_items_tenant_barcode
    ON erp_items (tenant_id, barcode)
    WHERE barcode IS NOT NULL AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_items_tenant_category
    ON erp_items (tenant_id, category_id);

CREATE INDEX IF NOT EXISTS ix_erp_items_tenant_status
    ON erp_items (tenant_id, status);

CREATE INDEX IF NOT EXISTS ix_erp_items_tenant_name
    ON erp_items (tenant_id, item_name);


CREATE TABLE IF NOT EXISTS erp_products (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    item_id UUID NOT NULL REFERENCES erp_items(item_id) ON DELETE RESTRICT,

    product_code TEXT NOT NULL,
    product_name TEXT NOT NULL,

    short_description TEXT,
    long_description TEXT,

    default_sales_unit_id UUID REFERENCES erp_units(unit_id) ON DELETE RESTRICT,

    is_sellable BOOLEAN NOT NULL DEFAULT true,
    is_visible_pos BOOLEAN NOT NULL DEFAULT true,
    is_visible_web BOOLEAN NOT NULL DEFAULT false,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_products_status_chk
        CHECK (status IN ('active', 'passive', 'blocked', 'deleted'))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_products_tenant_code
    ON erp_products (tenant_id, product_code)
    WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_products_tenant_item
    ON erp_products (tenant_id, item_id)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_products_tenant_status
    ON erp_products (tenant_id, status);

CREATE INDEX IF NOT EXISTS ix_erp_products_tenant_name
    ON erp_products (tenant_id, product_name);


ALTER TABLE erp_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_products ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp_units FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_product_categories FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_items FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_products FORCE ROW LEVEL SECURITY;

CREATE POLICY erp_units_tenant_isolation_policy
    ON erp_units
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_product_categories_tenant_isolation_policy
    ON erp_product_categories
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_items_tenant_isolation_policy
    ON erp_items
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_products_tenant_isolation_policy
    ON erp_products
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));
