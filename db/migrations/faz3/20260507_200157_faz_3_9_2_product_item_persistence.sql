BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS erp;

CREATE TABLE IF NOT EXISTS erp.product_categories (
    tenant_id uuid NOT NULL,
    category_id uuid NOT NULL DEFAULT gen_random_uuid(),

    category_code varchar(96) NOT NULL,
    category_name varchar(255) NOT NULL,
    parent_category_id uuid,

    category_path text,
    category_level integer NOT NULL DEFAULT 1,
    sort_order integer NOT NULL DEFAULT 100,

    status varchar(40) NOT NULL DEFAULT 'ACTIVE',

    accounting_sales_account_code varchar(32),
    accounting_purchase_account_code varchar(32),
    accounting_inventory_account_code varchar(32),
    accounting_cogs_account_code varchar(32),

    tax_rule_id uuid,

    description text,

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT product_categories_pk PRIMARY KEY (tenant_id, category_id),
    CONSTRAINT product_categories_code_unique UNIQUE (tenant_id, category_code),
    CONSTRAINT product_categories_parent_fk FOREIGN KEY (tenant_id, parent_category_id)
        REFERENCES erp.product_categories (tenant_id, category_id)
        ON DELETE SET NULL,
    CONSTRAINT product_categories_status_chk CHECK (
        status IN ('ACTIVE', 'PASSIVE', 'ARCHIVED')
    ),
    CONSTRAINT product_categories_level_chk CHECK (
        category_level >= 1 AND category_level <= 20
    )
);

CREATE TABLE IF NOT EXISTS erp.product_units (
    tenant_id uuid NOT NULL,
    unit_id uuid NOT NULL DEFAULT gen_random_uuid(),

    unit_code varchar(32) NOT NULL,
    unit_name varchar(128) NOT NULL,

    unit_type varchar(40) NOT NULL DEFAULT 'QUANTITY',
    decimal_precision integer NOT NULL DEFAULT 4,

    base_unit_code varchar(32),
    conversion_factor numeric(18, 8) NOT NULL DEFAULT 1,

    is_base_unit boolean NOT NULL DEFAULT false,
    status varchar(40) NOT NULL DEFAULT 'ACTIVE',

    description text,

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT product_units_pk PRIMARY KEY (tenant_id, unit_id),
    CONSTRAINT product_units_code_unique UNIQUE (tenant_id, unit_code),
    CONSTRAINT product_units_type_chk CHECK (
        unit_type IN ('QUANTITY', 'WEIGHT', 'VOLUME', 'LENGTH', 'AREA', 'PACKAGE', 'SERVICE', 'OTHER')
    ),
    CONSTRAINT product_units_status_chk CHECK (
        status IN ('ACTIVE', 'PASSIVE', 'ARCHIVED')
    ),
    CONSTRAINT product_units_precision_chk CHECK (
        decimal_precision >= 0 AND decimal_precision <= 8
    ),
    CONSTRAINT product_units_factor_chk CHECK (
        conversion_factor > 0
    )
);

CREATE TABLE IF NOT EXISTS erp.product_items (
    tenant_id uuid NOT NULL,
    item_id uuid NOT NULL DEFAULT gen_random_uuid(),

    item_code varchar(96) NOT NULL,
    item_name varchar(255) NOT NULL,
    item_short_name varchar(128),

    item_type varchar(40) NOT NULL DEFAULT 'STOCK',
    item_tracking_type varchar(40) NOT NULL DEFAULT 'NONE',

    category_id uuid,
    default_unit_id uuid,
    default_unit_code varchar(32) NOT NULL DEFAULT 'ADET',

    brand varchar(128),
    model varchar(128),
    manufacturer varchar(128),

    oem_code varchar(128),
    equivalent_code varchar(128),

    barcode varchar(128),
    sku varchar(128),

    tax_rule_id uuid,

    sales_enabled boolean NOT NULL DEFAULT true,
    purchase_enabled boolean NOT NULL DEFAULT true,
    inventory_enabled boolean NOT NULL DEFAULT true,

    min_stock_quantity numeric(18, 4) NOT NULL DEFAULT 0,
    max_stock_quantity numeric(18, 4) NOT NULL DEFAULT 0,
    reorder_point_quantity numeric(18, 4) NOT NULL DEFAULT 0,

    standard_cost numeric(18, 4) NOT NULL DEFAULT 0,
    list_price numeric(18, 4) NOT NULL DEFAULT 0,

    currency_code char(3) NOT NULL DEFAULT 'TRY',

    accounting_sales_account_code varchar(32),
    accounting_purchase_account_code varchar(32),
    accounting_inventory_account_code varchar(32),
    accounting_cogs_account_code varchar(32),

    status varchar(40) NOT NULL DEFAULT 'ACTIVE',

    description text,

    idempotency_key varchar(160),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT product_items_pk PRIMARY KEY (tenant_id, item_id),
    CONSTRAINT product_items_code_unique UNIQUE (tenant_id, item_code),
    CONSTRAINT product_items_idempotency_unique UNIQUE (tenant_id, idempotency_key),
    CONSTRAINT product_items_category_fk FOREIGN KEY (tenant_id, category_id)
        REFERENCES erp.product_categories (tenant_id, category_id)
        ON DELETE SET NULL,
    CONSTRAINT product_items_unit_fk FOREIGN KEY (tenant_id, default_unit_id)
        REFERENCES erp.product_units (tenant_id, unit_id)
        ON DELETE SET NULL,
    CONSTRAINT product_items_type_chk CHECK (
        item_type IN ('STOCK', 'SERVICE', 'EXPENSE', 'ASSET', 'BUNDLE', 'RAW_MATERIAL', 'SEMI_FINISHED', 'FINISHED_GOOD', 'OTHER')
    ),
    CONSTRAINT product_items_tracking_chk CHECK (
        item_tracking_type IN ('NONE', 'LOT', 'SERIAL', 'LOT_AND_EXPIRY', 'SERIAL_AND_EXPIRY')
    ),
    CONSTRAINT product_items_status_chk CHECK (
        status IN ('ACTIVE', 'PASSIVE', 'BLOCKED', 'ARCHIVED')
    ),
    CONSTRAINT product_items_qty_chk CHECK (
        min_stock_quantity >= 0
        AND max_stock_quantity >= 0
        AND reorder_point_quantity >= 0
    ),
    CONSTRAINT product_items_amount_chk CHECK (
        standard_cost >= 0
        AND list_price >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.product_item_units (
    tenant_id uuid NOT NULL,
    item_unit_id uuid NOT NULL DEFAULT gen_random_uuid(),

    item_id uuid NOT NULL,
    unit_id uuid NOT NULL,

    unit_code varchar(32) NOT NULL,
    unit_name varchar(128),

    conversion_factor numeric(18, 8) NOT NULL DEFAULT 1,
    is_sales_unit boolean NOT NULL DEFAULT false,
    is_purchase_unit boolean NOT NULL DEFAULT false,
    is_inventory_unit boolean NOT NULL DEFAULT false,
    is_default_unit boolean NOT NULL DEFAULT false,

    barcode varchar(128),

    status varchar(40) NOT NULL DEFAULT 'ACTIVE',

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT product_item_units_pk PRIMARY KEY (tenant_id, item_unit_id),
    CONSTRAINT product_item_units_item_fk FOREIGN KEY (tenant_id, item_id)
        REFERENCES erp.product_items (tenant_id, item_id)
        ON DELETE CASCADE,
    CONSTRAINT product_item_units_unit_fk FOREIGN KEY (tenant_id, unit_id)
        REFERENCES erp.product_units (tenant_id, unit_id)
        ON DELETE RESTRICT,
    CONSTRAINT product_item_units_unique UNIQUE (tenant_id, item_id, unit_id),
    CONSTRAINT product_item_units_status_chk CHECK (
        status IN ('ACTIVE', 'PASSIVE', 'ARCHIVED')
    ),
    CONSTRAINT product_item_units_factor_chk CHECK (
        conversion_factor > 0
    )
);

CREATE TABLE IF NOT EXISTS erp.product_barcodes (
    tenant_id uuid NOT NULL,
    product_barcode_id uuid NOT NULL DEFAULT gen_random_uuid(),

    item_id uuid NOT NULL,
    item_unit_id uuid,

    barcode varchar(128) NOT NULL,
    barcode_type varchar(40) NOT NULL DEFAULT 'EAN13',

    is_primary boolean NOT NULL DEFAULT false,
    status varchar(40) NOT NULL DEFAULT 'ACTIVE',

    source_channel varchar(64) NOT NULL DEFAULT 'ERP',

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT product_barcodes_pk PRIMARY KEY (tenant_id, product_barcode_id),
    CONSTRAINT product_barcodes_item_fk FOREIGN KEY (tenant_id, item_id)
        REFERENCES erp.product_items (tenant_id, item_id)
        ON DELETE CASCADE,
    CONSTRAINT product_barcodes_item_unit_fk FOREIGN KEY (tenant_id, item_unit_id)
        REFERENCES erp.product_item_units (tenant_id, item_unit_id)
        ON DELETE SET NULL,
    CONSTRAINT product_barcodes_barcode_unique UNIQUE (tenant_id, barcode),
    CONSTRAINT product_barcodes_type_chk CHECK (
        barcode_type IN ('EAN8', 'EAN13', 'UPC', 'CODE128', 'QR', 'INTERNAL', 'OTHER')
    ),
    CONSTRAINT product_barcodes_status_chk CHECK (
        status IN ('ACTIVE', 'PASSIVE', 'ARCHIVED')
    )
);

CREATE TABLE IF NOT EXISTS erp.product_item_audit_events (
    tenant_id uuid NOT NULL,
    product_item_audit_event_id uuid NOT NULL DEFAULT gen_random_uuid(),

    item_id uuid,
    entity_name varchar(96) NOT NULL,
    entity_id uuid,

    audit_action varchar(64) NOT NULL,

    old_value jsonb,
    new_value jsonb,

    reason_code varchar(96),
    reason_message text,

    actor_user_id uuid,
    actor_role varchar(96),

    correlation_id varchar(128),
    request_id varchar(128),

    occurred_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT product_item_audit_events_pk PRIMARY KEY (tenant_id, product_item_audit_event_id),
    CONSTRAINT product_item_audit_events_item_fk FOREIGN KEY (tenant_id, item_id)
        REFERENCES erp.product_items (tenant_id, item_id)
        ON DELETE SET NULL,
    CONSTRAINT product_item_audit_events_action_chk CHECK (
        audit_action IN ('CREATE', 'UPDATE', 'BLOCK', 'UNBLOCK', 'ARCHIVE', 'PRICE_CHANGE', 'COST_CHANGE', 'UNIT_CHANGE', 'SYSTEM_MIGRATION')
    )
);

CREATE INDEX IF NOT EXISTS product_categories_parent_idx
    ON erp.product_categories (tenant_id, parent_category_id);

CREATE INDEX IF NOT EXISTS product_categories_status_idx
    ON erp.product_categories (tenant_id, status, category_level, sort_order);

CREATE INDEX IF NOT EXISTS product_units_type_status_idx
    ON erp.product_units (tenant_id, unit_type, status);

CREATE INDEX IF NOT EXISTS product_items_category_idx
    ON erp.product_items (tenant_id, category_id, status);

CREATE INDEX IF NOT EXISTS product_items_type_status_idx
    ON erp.product_items (tenant_id, item_type, status);

CREATE INDEX IF NOT EXISTS product_items_barcode_idx
    ON erp.product_items (tenant_id, barcode)
    WHERE barcode IS NOT NULL;

CREATE INDEX IF NOT EXISTS product_items_sku_idx
    ON erp.product_items (tenant_id, sku)
    WHERE sku IS NOT NULL;

CREATE INDEX IF NOT EXISTS product_items_oem_idx
    ON erp.product_items (tenant_id, oem_code)
    WHERE oem_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS product_items_equivalent_idx
    ON erp.product_items (tenant_id, equivalent_code)
    WHERE equivalent_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS product_item_units_item_idx
    ON erp.product_item_units (tenant_id, item_id, status);

CREATE INDEX IF NOT EXISTS product_item_units_unit_idx
    ON erp.product_item_units (tenant_id, unit_id);

CREATE INDEX IF NOT EXISTS product_item_units_barcode_idx
    ON erp.product_item_units (tenant_id, barcode)
    WHERE barcode IS NOT NULL;

CREATE INDEX IF NOT EXISTS product_barcodes_item_idx
    ON erp.product_barcodes (tenant_id, item_id, is_primary);

CREATE INDEX IF NOT EXISTS product_barcodes_type_status_idx
    ON erp.product_barcodes (tenant_id, barcode_type, status);

CREATE INDEX IF NOT EXISTS product_item_audit_events_item_idx
    ON erp.product_item_audit_events (tenant_id, item_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS product_item_audit_events_entity_idx
    ON erp.product_item_audit_events (tenant_id, entity_name, entity_id, occurred_at DESC);

ALTER TABLE erp.product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.product_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.product_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.product_item_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.product_barcodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.product_item_audit_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp.product_categories FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.product_units FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.product_items FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.product_item_units FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.product_barcodes FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.product_item_audit_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS product_categories_tenant_policy ON erp.product_categories;
CREATE POLICY product_categories_tenant_policy ON erp.product_categories
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS product_units_tenant_policy ON erp.product_units;
CREATE POLICY product_units_tenant_policy ON erp.product_units
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS product_items_tenant_policy ON erp.product_items;
CREATE POLICY product_items_tenant_policy ON erp.product_items
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS product_item_units_tenant_policy ON erp.product_item_units;
CREATE POLICY product_item_units_tenant_policy ON erp.product_item_units
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS product_barcodes_tenant_policy ON erp.product_barcodes;
CREATE POLICY product_barcodes_tenant_policy ON erp.product_barcodes
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS product_item_audit_events_tenant_policy ON erp.product_item_audit_events;
CREATE POLICY product_item_audit_events_tenant_policy ON erp.product_item_audit_events
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

COMMENT ON TABLE erp.product_categories IS 'FAZ 3-9.2 product category table';
COMMENT ON TABLE erp.product_units IS 'FAZ 3-9.2 product unit table';
COMMENT ON TABLE erp.product_items IS 'FAZ 3-9.2 product item table';
COMMENT ON TABLE erp.product_item_units IS 'FAZ 3-9.2 product item unit conversion table';
COMMENT ON TABLE erp.product_barcodes IS 'FAZ 3-9.2 product barcode table';
COMMENT ON TABLE erp.product_item_audit_events IS 'FAZ 3-9.2 product item audit event table';

COMMIT;
