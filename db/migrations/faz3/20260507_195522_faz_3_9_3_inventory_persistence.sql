BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS erp;

CREATE TABLE IF NOT EXISTS erp.inventory_movement_batches (
    tenant_id uuid NOT NULL,
    inventory_movement_batch_id uuid NOT NULL DEFAULT gen_random_uuid(),

    batch_no varchar(96) NOT NULL,
    batch_type varchar(64) NOT NULL DEFAULT 'STOCK_MOVEMENT',
    source_module varchar(64) NOT NULL DEFAULT 'ERP',

    batch_status varchar(40) NOT NULL DEFAULT 'OPEN',

    movement_count integer NOT NULL DEFAULT 0,
    total_quantity_in numeric(18, 4) NOT NULL DEFAULT 0,
    total_quantity_out numeric(18, 4) NOT NULL DEFAULT 0,

    journal_id uuid,
    ledger_posting_batch_id uuid,

    idempotency_key varchar(160),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    posted_by uuid,
    posted_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT inventory_movement_batches_pk PRIMARY KEY (tenant_id, inventory_movement_batch_id),
    CONSTRAINT inventory_movement_batches_no_unique UNIQUE (tenant_id, batch_no),
    CONSTRAINT inventory_movement_batches_idempotency_unique UNIQUE (tenant_id, idempotency_key),
    CONSTRAINT inventory_movement_batches_type_chk CHECK (
        batch_type IN (
            'STOCK_MOVEMENT',
            'PURCHASE_RECEIPT',
            'SALES_DELIVERY',
            'TRANSFER',
            'ADJUSTMENT',
            'COUNT_CORRECTION',
            'RETURN_IN',
            'RETURN_OUT',
            'RESERVATION_RELEASE',
            'IMPORT'
        )
    ),
    CONSTRAINT inventory_movement_batches_status_chk CHECK (
        batch_status IN ('OPEN', 'POSTING', 'POSTED', 'FAILED', 'REVERSED', 'CANCELED')
    ),
    CONSTRAINT inventory_movement_batches_qty_chk CHECK (
        movement_count >= 0
        AND total_quantity_in >= 0
        AND total_quantity_out >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.inventory_stock_movements (
    tenant_id uuid NOT NULL,
    stock_movement_id uuid NOT NULL DEFAULT gen_random_uuid(),

    inventory_movement_batch_id uuid,

    movement_no varchar(128) NOT NULL,
    movement_type varchar(64) NOT NULL,
    movement_direction varchar(16) NOT NULL,

    movement_date date NOT NULL DEFAULT CURRENT_DATE,
    movement_time timestamptz NOT NULL DEFAULT now(),

    item_id uuid NOT NULL,
    item_code varchar(96),
    item_name varchar(255) NOT NULL,
    category_id uuid,
    unit_code varchar(32) NOT NULL DEFAULT 'ADET',

    warehouse_id uuid NOT NULL,
    warehouse_code varchar(96),
    warehouse_name varchar(255),

    source_warehouse_id uuid,
    target_warehouse_id uuid,

    quantity numeric(18, 4) NOT NULL DEFAULT 0,
    unit_cost numeric(18, 4) NOT NULL DEFAULT 0,
    total_cost numeric(18, 2) NOT NULL DEFAULT 0,

    currency_code char(3) NOT NULL DEFAULT 'TRY',
    exchange_rate numeric(18, 8) NOT NULL DEFAULT 1,

    before_on_hand_quantity numeric(18, 4),
    after_on_hand_quantity numeric(18, 4),

    lot_no varchar(128),
    serial_no varchar(128),
    expiry_date date,

    source_module varchar(64),
    source_document_type varchar(64),
    source_document_id uuid,
    source_document_no varchar(96),
    source_line_id uuid,
    source_event_id uuid,

    journal_id uuid,
    journal_line_id uuid,
    ledger_movement_id uuid,

    posting_status varchar(40) NOT NULL DEFAULT 'POSTED',

    is_reversal boolean NOT NULL DEFAULT false,
    reversal_of_stock_movement_id uuid,

    idempotency_key varchar(160),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT inventory_stock_movements_pk PRIMARY KEY (tenant_id, stock_movement_id),
    CONSTRAINT inventory_stock_movements_batch_fk FOREIGN KEY (tenant_id, inventory_movement_batch_id)
        REFERENCES erp.inventory_movement_batches (tenant_id, inventory_movement_batch_id)
        ON DELETE SET NULL,
    CONSTRAINT inventory_stock_movements_reversal_fk FOREIGN KEY (tenant_id, reversal_of_stock_movement_id)
        REFERENCES erp.inventory_stock_movements (tenant_id, stock_movement_id)
        ON DELETE SET NULL,
    CONSTRAINT inventory_stock_movements_no_unique UNIQUE (tenant_id, movement_no),
    CONSTRAINT inventory_stock_movements_idempotency_unique UNIQUE (tenant_id, idempotency_key),
    CONSTRAINT inventory_stock_movements_type_chk CHECK (
        movement_type IN (
            'PURCHASE_RECEIPT',
            'SALES_DELIVERY',
            'SALES_RETURN',
            'PURCHASE_RETURN',
            'WAREHOUSE_TRANSFER_IN',
            'WAREHOUSE_TRANSFER_OUT',
            'ADJUSTMENT_IN',
            'ADJUSTMENT_OUT',
            'COUNT_INCREASE',
            'COUNT_DECREASE',
            'PRODUCTION_IN',
            'CONSUMPTION_OUT',
            'RESERVATION',
            'RESERVATION_RELEASE',
            'CUSTOM'
        )
    ),
    CONSTRAINT inventory_stock_movements_direction_chk CHECK (
        movement_direction IN ('IN', 'OUT')
    ),
    CONSTRAINT inventory_stock_movements_qty_chk CHECK (
        quantity > 0
        AND unit_cost >= 0
        AND total_cost >= 0
        AND exchange_rate > 0
    ),
    CONSTRAINT inventory_stock_movements_posting_status_chk CHECK (
        posting_status IN ('DRAFT', 'POSTED', 'FAILED', 'REVERSED', 'CANCELED')
    )
);

CREATE TABLE IF NOT EXISTS erp.inventory_warehouse_balances (
    tenant_id uuid NOT NULL,
    warehouse_balance_id uuid NOT NULL DEFAULT gen_random_uuid(),

    item_id uuid NOT NULL,
    item_code varchar(96),
    item_name varchar(255),
    category_id uuid,
    unit_code varchar(32) NOT NULL DEFAULT 'ADET',

    warehouse_id uuid NOT NULL,
    warehouse_code varchar(96),
    warehouse_name varchar(255),

    on_hand_quantity numeric(18, 4) NOT NULL DEFAULT 0,
    reserved_quantity numeric(18, 4) NOT NULL DEFAULT 0,
    available_quantity numeric(18, 4) NOT NULL DEFAULT 0,

    incoming_quantity numeric(18, 4) NOT NULL DEFAULT 0,
    outgoing_quantity numeric(18, 4) NOT NULL DEFAULT 0,

    average_cost numeric(18, 4) NOT NULL DEFAULT 0,
    total_cost numeric(18, 2) NOT NULL DEFAULT 0,

    last_movement_id uuid,
    last_movement_at timestamptz,
    last_rebuild_at timestamptz,

    balance_status varchar(40) NOT NULL DEFAULT 'CURRENT',

    correlation_id varchar(128),
    request_id varchar(128),

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT inventory_warehouse_balances_pk PRIMARY KEY (tenant_id, warehouse_balance_id),
    CONSTRAINT inventory_warehouse_balances_item_warehouse_unique UNIQUE (tenant_id, item_id, warehouse_id),
    CONSTRAINT inventory_warehouse_balances_last_movement_fk FOREIGN KEY (tenant_id, last_movement_id)
        REFERENCES erp.inventory_stock_movements (tenant_id, stock_movement_id)
        ON DELETE SET NULL,
    CONSTRAINT inventory_warehouse_balances_qty_chk CHECK (
        on_hand_quantity >= 0
        AND reserved_quantity >= 0
        AND available_quantity >= 0
        AND incoming_quantity >= 0
        AND outgoing_quantity >= 0
    ),
    CONSTRAINT inventory_warehouse_balances_cost_chk CHECK (
        average_cost >= 0
        AND total_cost >= 0
    ),
    CONSTRAINT inventory_warehouse_balances_status_chk CHECK (
        balance_status IN ('CURRENT', 'STALE', 'REBUILDING', 'LOCKED', 'CLOSED')
    )
);

CREATE TABLE IF NOT EXISTS erp.inventory_reservations (
    tenant_id uuid NOT NULL,
    inventory_reservation_id uuid NOT NULL DEFAULT gen_random_uuid(),

    reservation_no varchar(128) NOT NULL,

    item_id uuid NOT NULL,
    item_code varchar(96),
    item_name varchar(255),
    unit_code varchar(32) NOT NULL DEFAULT 'ADET',

    warehouse_id uuid NOT NULL,
    warehouse_code varchar(96),

    reserved_quantity numeric(18, 4) NOT NULL DEFAULT 0,
    released_quantity numeric(18, 4) NOT NULL DEFAULT 0,
    consumed_quantity numeric(18, 4) NOT NULL DEFAULT 0,

    reservation_status varchar(40) NOT NULL DEFAULT 'ACTIVE',

    source_module varchar(64),
    source_document_type varchar(64),
    source_document_id uuid,
    source_document_no varchar(96),
    source_line_id uuid,

    expires_at timestamptz,
    released_at timestamptz,
    consumed_at timestamptz,

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    released_by uuid,
    consumed_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT inventory_reservations_pk PRIMARY KEY (tenant_id, inventory_reservation_id),
    CONSTRAINT inventory_reservations_no_unique UNIQUE (tenant_id, reservation_no),
    CONSTRAINT inventory_reservations_qty_chk CHECK (
        reserved_quantity >= 0
        AND released_quantity >= 0
        AND consumed_quantity >= 0
        AND released_quantity <= reserved_quantity
        AND consumed_quantity <= reserved_quantity
    ),
    CONSTRAINT inventory_reservations_status_chk CHECK (
        reservation_status IN ('ACTIVE', 'PARTIALLY_RELEASED', 'RELEASED', 'PARTIALLY_CONSUMED', 'CONSUMED', 'EXPIRED', 'CANCELED')
    )
);

CREATE TABLE IF NOT EXISTS erp.inventory_balance_rebuild_audit_events (
    tenant_id uuid NOT NULL,
    inventory_balance_rebuild_audit_event_id uuid NOT NULL DEFAULT gen_random_uuid(),

    rebuild_scope varchar(64) NOT NULL DEFAULT 'WAREHOUSE_BALANCE',
    rebuild_status varchar(40) NOT NULL DEFAULT 'RECORDED',

    item_id uuid,
    warehouse_id uuid,

    movement_count integer NOT NULL DEFAULT 0,
    balance_count integer NOT NULL DEFAULT 0,

    before_snapshot jsonb,
    after_snapshot jsonb,

    error_code varchar(96),
    error_message text,

    actor_user_id uuid,

    correlation_id varchar(128),
    request_id varchar(128),

    occurred_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT inventory_balance_rebuild_audit_events_pk PRIMARY KEY (tenant_id, inventory_balance_rebuild_audit_event_id),
    CONSTRAINT inventory_balance_rebuild_audit_events_scope_chk CHECK (
        rebuild_scope IN ('WAREHOUSE_BALANCE', 'ITEM_BALANCE', 'TENANT_BALANCE', 'MOVEMENT_REPLAY', 'SYSTEM_AUDIT')
    ),
    CONSTRAINT inventory_balance_rebuild_audit_events_status_chk CHECK (
        rebuild_status IN ('RECORDED', 'RUNNING', 'PASS', 'FAIL', 'WARN')
    ),
    CONSTRAINT inventory_balance_rebuild_audit_events_count_chk CHECK (
        movement_count >= 0
        AND balance_count >= 0
    )
);

CREATE INDEX IF NOT EXISTS inventory_movement_batches_status_idx
    ON erp.inventory_movement_batches (tenant_id, batch_status, created_at DESC);

CREATE INDEX IF NOT EXISTS inventory_movement_batches_source_idx
    ON erp.inventory_movement_batches (tenant_id, source_module, batch_type, created_at DESC);

CREATE INDEX IF NOT EXISTS inventory_stock_movements_item_date_idx
    ON erp.inventory_stock_movements (tenant_id, item_id, movement_date DESC);

CREATE INDEX IF NOT EXISTS inventory_stock_movements_warehouse_date_idx
    ON erp.inventory_stock_movements (tenant_id, warehouse_id, movement_date DESC);

CREATE INDEX IF NOT EXISTS inventory_stock_movements_item_warehouse_idx
    ON erp.inventory_stock_movements (tenant_id, item_id, warehouse_id, movement_date DESC);

CREATE INDEX IF NOT EXISTS inventory_stock_movements_source_idx
    ON erp.inventory_stock_movements (tenant_id, source_module, source_document_type, source_document_id);

CREATE INDEX IF NOT EXISTS inventory_stock_movements_batch_idx
    ON erp.inventory_stock_movements (tenant_id, inventory_movement_batch_id);

CREATE INDEX IF NOT EXISTS inventory_stock_movements_lot_serial_idx
    ON erp.inventory_stock_movements (tenant_id, item_id, lot_no, serial_no);

CREATE INDEX IF NOT EXISTS inventory_warehouse_balances_item_idx
    ON erp.inventory_warehouse_balances (tenant_id, item_id);

CREATE INDEX IF NOT EXISTS inventory_warehouse_balances_warehouse_idx
    ON erp.inventory_warehouse_balances (tenant_id, warehouse_id);

CREATE INDEX IF NOT EXISTS inventory_warehouse_balances_status_idx
    ON erp.inventory_warehouse_balances (tenant_id, balance_status, updated_at DESC);

CREATE INDEX IF NOT EXISTS inventory_reservations_item_warehouse_idx
    ON erp.inventory_reservations (tenant_id, item_id, warehouse_id, reservation_status);

CREATE INDEX IF NOT EXISTS inventory_reservations_source_idx
    ON erp.inventory_reservations (tenant_id, source_module, source_document_type, source_document_id);

CREATE INDEX IF NOT EXISTS inventory_reservations_expiry_idx
    ON erp.inventory_reservations (tenant_id, reservation_status, expires_at)
    WHERE expires_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS inventory_balance_rebuild_audit_events_scope_idx
    ON erp.inventory_balance_rebuild_audit_events (tenant_id, rebuild_scope, rebuild_status, occurred_at DESC);

CREATE INDEX IF NOT EXISTS inventory_balance_rebuild_audit_events_item_warehouse_idx
    ON erp.inventory_balance_rebuild_audit_events (tenant_id, item_id, warehouse_id, occurred_at DESC);

ALTER TABLE erp.inventory_movement_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.inventory_stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.inventory_warehouse_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.inventory_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.inventory_balance_rebuild_audit_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp.inventory_movement_batches FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.inventory_stock_movements FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.inventory_warehouse_balances FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.inventory_reservations FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.inventory_balance_rebuild_audit_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS inventory_movement_batches_tenant_policy ON erp.inventory_movement_batches;
CREATE POLICY inventory_movement_batches_tenant_policy ON erp.inventory_movement_batches
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS inventory_stock_movements_tenant_policy ON erp.inventory_stock_movements;
CREATE POLICY inventory_stock_movements_tenant_policy ON erp.inventory_stock_movements
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS inventory_warehouse_balances_tenant_policy ON erp.inventory_warehouse_balances;
CREATE POLICY inventory_warehouse_balances_tenant_policy ON erp.inventory_warehouse_balances
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS inventory_reservations_tenant_policy ON erp.inventory_reservations;
CREATE POLICY inventory_reservations_tenant_policy ON erp.inventory_reservations
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS inventory_balance_rebuild_audit_events_tenant_policy ON erp.inventory_balance_rebuild_audit_events;
CREATE POLICY inventory_balance_rebuild_audit_events_tenant_policy ON erp.inventory_balance_rebuild_audit_events
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

COMMENT ON TABLE erp.inventory_movement_batches IS 'FAZ 3-9.3 inventory movement batch table';
COMMENT ON TABLE erp.inventory_stock_movements IS 'FAZ 3-9.3 inventory stock movement table';
COMMENT ON TABLE erp.inventory_warehouse_balances IS 'FAZ 3-9.3 inventory warehouse balance table';
COMMENT ON TABLE erp.inventory_reservations IS 'FAZ 3-9.3 inventory reservation table';
COMMENT ON TABLE erp.inventory_balance_rebuild_audit_events IS 'FAZ 3-9.3 inventory balance rebuild audit event table';

COMMIT;
