-- FAZ 3 / 9.3.1
-- ERP Turkiye canli cekirdegi
-- Inventory / Stock Movement / Warehouse Balance tabloları
--
-- Ana mantik:
-- erp_warehouses: depo / sube / lokasyon kartlari
-- erp_stock_movements: stok hareket defteri
-- erp_warehouse_balances: depo bazli stok bakiyesi
--
-- Not:
-- Stok bakiyesi dogrudan hareketlerden turetilir ama hizli operasyon icin balance tablosunda tutulur.
-- Hareket defteri muhasebe ve denetim icin silinmez ana kayittir.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS erp_warehouses (
    warehouse_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    warehouse_code TEXT NOT NULL,
    warehouse_name TEXT NOT NULL,
    warehouse_type TEXT NOT NULL DEFAULT 'main',

    city TEXT,
    district TEXT,
    address_line TEXT,

    is_default BOOLEAN NOT NULL DEFAULT false,
    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_warehouses_type_chk
        CHECK (warehouse_type IN ('main', 'branch', 'store', 'virtual', 'transit', 'damaged')),

    CONSTRAINT erp_warehouses_status_chk
        CHECK (status IN ('active', 'passive', 'blocked', 'deleted'))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_warehouses_tenant_code
    ON erp_warehouses (tenant_id, warehouse_code)
    WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_warehouses_one_default
    ON erp_warehouses (tenant_id)
    WHERE is_default = true AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_warehouses_tenant_status
    ON erp_warehouses (tenant_id, status);


CREATE TABLE IF NOT EXISTS erp_stock_movements (
    stock_movement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    movement_no TEXT NOT NULL,
    movement_type TEXT NOT NULL,
    movement_direction TEXT NOT NULL,

    warehouse_id UUID NOT NULL REFERENCES erp_warehouses(warehouse_id) ON DELETE RESTRICT,
    item_id UUID NOT NULL REFERENCES erp_items(item_id) ON DELETE RESTRICT,
    unit_id UUID NOT NULL REFERENCES erp_units(unit_id) ON DELETE RESTRICT,

    quantity NUMERIC(18, 6) NOT NULL,
    unit_cost NUMERIC(18, 6) NOT NULL DEFAULT 0,
    total_cost NUMERIC(18, 6) NOT NULL DEFAULT 0,

    source_type TEXT,
    source_id TEXT,
    source_line_id TEXT,

    movement_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    posted_at TIMESTAMPTZ,

    status TEXT NOT NULL DEFAULT 'posted',

    note TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_stock_movements_type_chk
        CHECK (movement_type IN (
            'opening',
            'purchase_receipt',
            'sales_delivery',
            'stock_in',
            'stock_out',
            'transfer_in',
            'transfer_out',
            'adjustment_in',
            'adjustment_out',
            'return_in',
            'return_out'
        )),

    CONSTRAINT erp_stock_movements_direction_chk
        CHECK (movement_direction IN ('in', 'out')),

    CONSTRAINT erp_stock_movements_status_chk
        CHECK (status IN ('draft', 'posted', 'cancelled', 'reversed')),

    CONSTRAINT erp_stock_movements_quantity_chk
        CHECK (quantity > 0),

    CONSTRAINT erp_stock_movements_cost_chk
        CHECK (unit_cost >= 0 AND total_cost >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_stock_movements_tenant_movement_no
    ON erp_stock_movements (tenant_id, movement_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_stock_movements_tenant_item
    ON erp_stock_movements (tenant_id, item_id);

CREATE INDEX IF NOT EXISTS ix_erp_stock_movements_tenant_warehouse
    ON erp_stock_movements (tenant_id, warehouse_id);

CREATE INDEX IF NOT EXISTS ix_erp_stock_movements_tenant_source
    ON erp_stock_movements (tenant_id, source_type, source_id);

CREATE INDEX IF NOT EXISTS ix_erp_stock_movements_tenant_movement_at
    ON erp_stock_movements (tenant_id, movement_at);


CREATE TABLE IF NOT EXISTS erp_warehouse_balances (
    balance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    warehouse_id UUID NOT NULL REFERENCES erp_warehouses(warehouse_id) ON DELETE RESTRICT,
    item_id UUID NOT NULL REFERENCES erp_items(item_id) ON DELETE RESTRICT,
    unit_id UUID NOT NULL REFERENCES erp_units(unit_id) ON DELETE RESTRICT,

    on_hand_quantity NUMERIC(18, 6) NOT NULL DEFAULT 0,
    reserved_quantity NUMERIC(18, 6) NOT NULL DEFAULT 0,
    available_quantity NUMERIC(18, 6) NOT NULL DEFAULT 0,

    last_movement_at TIMESTAMPTZ,
    last_stock_movement_id UUID REFERENCES erp_stock_movements(stock_movement_id) ON DELETE SET NULL,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_warehouse_balances_status_chk
        CHECK (status IN ('active', 'passive', 'deleted')),

    CONSTRAINT erp_warehouse_balances_quantity_chk
        CHECK (
            on_hand_quantity >= 0
            AND reserved_quantity >= 0
            AND available_quantity >= 0
            AND available_quantity <= on_hand_quantity
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_warehouse_balances_tenant_wh_item
    ON erp_warehouse_balances (tenant_id, warehouse_id, item_id)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_warehouse_balances_tenant_item
    ON erp_warehouse_balances (tenant_id, item_id);

CREATE INDEX IF NOT EXISTS ix_erp_warehouse_balances_tenant_warehouse
    ON erp_warehouse_balances (tenant_id, warehouse_id);

CREATE INDEX IF NOT EXISTS ix_erp_warehouse_balances_tenant_status
    ON erp_warehouse_balances (tenant_id, status);


ALTER TABLE erp_warehouses ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_warehouse_balances ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp_warehouses FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_stock_movements FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_warehouse_balances FORCE ROW LEVEL SECURITY;

CREATE POLICY erp_warehouses_tenant_isolation_policy
    ON erp_warehouses
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_stock_movements_tenant_isolation_policy
    ON erp_stock_movements
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_warehouse_balances_tenant_isolation_policy
    ON erp_warehouse_balances
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));
