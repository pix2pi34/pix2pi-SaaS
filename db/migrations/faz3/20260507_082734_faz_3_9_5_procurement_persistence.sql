BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS erp;

CREATE TABLE IF NOT EXISTS erp.procurement_purchase_orders (
    tenant_id uuid NOT NULL,
    purchase_order_id uuid NOT NULL DEFAULT gen_random_uuid(),

    order_no varchar(96) NOT NULL,
    vendor_id uuid,
    vendor_code varchar(96),
    vendor_title varchar(255) NOT NULL,

    order_date date NOT NULL DEFAULT CURRENT_DATE,
    expected_receipt_date date,
    currency_code char(3) NOT NULL DEFAULT 'TRY',

    subtotal_amount numeric(18, 2) NOT NULL DEFAULT 0,
    discount_amount numeric(18, 2) NOT NULL DEFAULT 0,
    tax_amount numeric(18, 2) NOT NULL DEFAULT 0,
    total_amount numeric(18, 2) NOT NULL DEFAULT 0,

    status varchar(40) NOT NULL DEFAULT 'DRAFT',

    source_module varchar(64),
    source_document_id uuid,
    approval_ref varchar(128),
    notes text,

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,
    approved_by uuid,
    approved_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT procurement_purchase_orders_pk PRIMARY KEY (tenant_id, purchase_order_id),
    CONSTRAINT procurement_purchase_orders_status_chk CHECK (
        status IN (
            'DRAFT',
            'APPROVAL_WAITING',
            'APPROVED',
            'SENT',
            'PARTIALLY_RECEIVED',
            'RECEIVED',
            'PARTIALLY_INVOICED',
            'INVOICED',
            'CANCELED',
            'CLOSED'
        )
    ),
    CONSTRAINT procurement_purchase_orders_amount_chk CHECK (
        subtotal_amount >= 0
        AND discount_amount >= 0
        AND tax_amount >= 0
        AND total_amount >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.procurement_purchase_order_lines (
    tenant_id uuid NOT NULL,
    purchase_order_line_id uuid NOT NULL DEFAULT gen_random_uuid(),
    purchase_order_id uuid NOT NULL,

    line_no integer NOT NULL,

    item_id uuid,
    item_code varchar(96),
    item_name varchar(255) NOT NULL,
    category_id uuid,
    unit_code varchar(32) NOT NULL DEFAULT 'ADET',

    quantity_ordered numeric(18, 4) NOT NULL DEFAULT 0,
    quantity_received numeric(18, 4) NOT NULL DEFAULT 0,
    quantity_invoiced numeric(18, 4) NOT NULL DEFAULT 0,

    unit_price numeric(18, 4) NOT NULL DEFAULT 0,
    discount_amount numeric(18, 2) NOT NULL DEFAULT 0,
    tax_rate numeric(9, 4) NOT NULL DEFAULT 0,
    tax_amount numeric(18, 2) NOT NULL DEFAULT 0,
    line_total_amount numeric(18, 2) NOT NULL DEFAULT 0,

    status varchar(40) NOT NULL DEFAULT 'OPEN',

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT procurement_purchase_order_lines_pk PRIMARY KEY (tenant_id, purchase_order_line_id),
    CONSTRAINT procurement_purchase_order_lines_order_fk FOREIGN KEY (tenant_id, purchase_order_id)
        REFERENCES erp.procurement_purchase_orders (tenant_id, purchase_order_id)
        ON DELETE CASCADE,
    CONSTRAINT procurement_purchase_order_lines_line_unique UNIQUE (tenant_id, purchase_order_id, line_no),
    CONSTRAINT procurement_purchase_order_lines_status_chk CHECK (
        status IN ('OPEN', 'PARTIALLY_RECEIVED', 'RECEIVED', 'PARTIALLY_INVOICED', 'INVOICED', 'CANCELED', 'CLOSED')
    ),
    CONSTRAINT procurement_purchase_order_lines_qty_chk CHECK (
        quantity_ordered >= 0
        AND quantity_received >= 0
        AND quantity_invoiced >= 0
    ),
    CONSTRAINT procurement_purchase_order_lines_amount_chk CHECK (
        unit_price >= 0
        AND discount_amount >= 0
        AND tax_rate >= 0
        AND tax_amount >= 0
        AND line_total_amount >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.procurement_receipts (
    tenant_id uuid NOT NULL,
    receipt_id uuid NOT NULL DEFAULT gen_random_uuid(),

    receipt_no varchar(96) NOT NULL,
    purchase_order_id uuid,

    vendor_id uuid,
    vendor_code varchar(96),
    vendor_title varchar(255) NOT NULL,

    warehouse_id uuid,
    warehouse_code varchar(96),
    warehouse_name varchar(255),

    receipt_date date NOT NULL DEFAULT CURRENT_DATE,
    delivery_note_no varchar(96),

    status varchar(40) NOT NULL DEFAULT 'DRAFT',

    inventory_posted boolean NOT NULL DEFAULT false,
    inventory_posted_at timestamptz,

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,
    posted_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT procurement_receipts_pk PRIMARY KEY (tenant_id, receipt_id),
    CONSTRAINT procurement_receipts_purchase_order_fk FOREIGN KEY (tenant_id, purchase_order_id)
        REFERENCES erp.procurement_purchase_orders (tenant_id, purchase_order_id)
        ON DELETE SET NULL,
    CONSTRAINT procurement_receipts_status_chk CHECK (
        status IN ('DRAFT', 'READY', 'POSTED', 'CANCELED', 'REVERSED')
    )
);

CREATE TABLE IF NOT EXISTS erp.procurement_receipt_lines (
    tenant_id uuid NOT NULL,
    receipt_line_id uuid NOT NULL DEFAULT gen_random_uuid(),
    receipt_id uuid NOT NULL,

    purchase_order_id uuid,
    purchase_order_line_id uuid,

    line_no integer NOT NULL,

    item_id uuid,
    item_code varchar(96),
    item_name varchar(255) NOT NULL,
    unit_code varchar(32) NOT NULL DEFAULT 'ADET',

    quantity_received numeric(18, 4) NOT NULL DEFAULT 0,
    quantity_rejected numeric(18, 4) NOT NULL DEFAULT 0,

    warehouse_id uuid,
    inventory_movement_id uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT procurement_receipt_lines_pk PRIMARY KEY (tenant_id, receipt_line_id),
    CONSTRAINT procurement_receipt_lines_receipt_fk FOREIGN KEY (tenant_id, receipt_id)
        REFERENCES erp.procurement_receipts (tenant_id, receipt_id)
        ON DELETE CASCADE,
    CONSTRAINT procurement_receipt_lines_order_fk FOREIGN KEY (tenant_id, purchase_order_id)
        REFERENCES erp.procurement_purchase_orders (tenant_id, purchase_order_id)
        ON DELETE SET NULL,
    CONSTRAINT procurement_receipt_lines_order_line_fk FOREIGN KEY (tenant_id, purchase_order_line_id)
        REFERENCES erp.procurement_purchase_order_lines (tenant_id, purchase_order_line_id)
        ON DELETE SET NULL,
    CONSTRAINT procurement_receipt_lines_line_unique UNIQUE (tenant_id, receipt_id, line_no),
    CONSTRAINT procurement_receipt_lines_qty_chk CHECK (
        quantity_received >= 0
        AND quantity_rejected >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.procurement_purchase_invoices (
    tenant_id uuid NOT NULL,
    purchase_invoice_id uuid NOT NULL DEFAULT gen_random_uuid(),

    invoice_no varchar(96) NOT NULL,
    vendor_invoice_no varchar(96),

    purchase_order_id uuid,
    receipt_id uuid,

    vendor_id uuid,
    vendor_code varchar(96),
    vendor_title varchar(255) NOT NULL,

    invoice_date date NOT NULL DEFAULT CURRENT_DATE,
    due_date date,
    currency_code char(3) NOT NULL DEFAULT 'TRY',

    subtotal_amount numeric(18, 2) NOT NULL DEFAULT 0,
    discount_amount numeric(18, 2) NOT NULL DEFAULT 0,
    tax_amount numeric(18, 2) NOT NULL DEFAULT 0,
    total_amount numeric(18, 2) NOT NULL DEFAULT 0,

    status varchar(40) NOT NULL DEFAULT 'DRAFT',

    journal_id uuid,
    e_belge_id uuid,
    payment_status varchar(40) NOT NULL DEFAULT 'UNPAID',

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,
    posted_by uuid,
    posted_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT procurement_purchase_invoices_pk PRIMARY KEY (tenant_id, purchase_invoice_id),
    CONSTRAINT procurement_purchase_invoices_order_fk FOREIGN KEY (tenant_id, purchase_order_id)
        REFERENCES erp.procurement_purchase_orders (tenant_id, purchase_order_id)
        ON DELETE SET NULL,
    CONSTRAINT procurement_purchase_invoices_receipt_fk FOREIGN KEY (tenant_id, receipt_id)
        REFERENCES erp.procurement_receipts (tenant_id, receipt_id)
        ON DELETE SET NULL,
    CONSTRAINT procurement_purchase_invoices_status_chk CHECK (
        status IN ('DRAFT', 'READY', 'POSTED', 'CANCELED', 'REVERSED')
    ),
    CONSTRAINT procurement_purchase_invoices_payment_status_chk CHECK (
        payment_status IN ('UNPAID', 'PARTIALLY_PAID', 'PAID', 'REFUNDED', 'RECONCILED')
    ),
    CONSTRAINT procurement_purchase_invoices_amount_chk CHECK (
        subtotal_amount >= 0
        AND discount_amount >= 0
        AND tax_amount >= 0
        AND total_amount >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.procurement_purchase_invoice_lines (
    tenant_id uuid NOT NULL,
    purchase_invoice_line_id uuid NOT NULL DEFAULT gen_random_uuid(),
    purchase_invoice_id uuid NOT NULL,

    purchase_order_line_id uuid,
    receipt_line_id uuid,

    line_no integer NOT NULL,

    item_id uuid,
    item_code varchar(96),
    item_name varchar(255) NOT NULL,
    unit_code varchar(32) NOT NULL DEFAULT 'ADET',

    quantity numeric(18, 4) NOT NULL DEFAULT 0,
    unit_price numeric(18, 4) NOT NULL DEFAULT 0,
    discount_amount numeric(18, 2) NOT NULL DEFAULT 0,
    tax_rate numeric(9, 4) NOT NULL DEFAULT 0,
    tax_amount numeric(18, 2) NOT NULL DEFAULT 0,
    line_total_amount numeric(18, 2) NOT NULL DEFAULT 0,

    account_code varchar(32),
    tax_account_code varchar(32),

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT procurement_purchase_invoice_lines_pk PRIMARY KEY (tenant_id, purchase_invoice_line_id),
    CONSTRAINT procurement_purchase_invoice_lines_invoice_fk FOREIGN KEY (tenant_id, purchase_invoice_id)
        REFERENCES erp.procurement_purchase_invoices (tenant_id, purchase_invoice_id)
        ON DELETE CASCADE,
    CONSTRAINT procurement_purchase_invoice_lines_order_line_fk FOREIGN KEY (tenant_id, purchase_order_line_id)
        REFERENCES erp.procurement_purchase_order_lines (tenant_id, purchase_order_line_id)
        ON DELETE SET NULL,
    CONSTRAINT procurement_purchase_invoice_lines_receipt_line_fk FOREIGN KEY (tenant_id, receipt_line_id)
        REFERENCES erp.procurement_receipt_lines (tenant_id, receipt_line_id)
        ON DELETE SET NULL,
    CONSTRAINT procurement_purchase_invoice_lines_line_unique UNIQUE (tenant_id, purchase_invoice_id, line_no),
    CONSTRAINT procurement_purchase_invoice_lines_qty_chk CHECK (
        quantity >= 0
    ),
    CONSTRAINT procurement_purchase_invoice_lines_amount_chk CHECK (
        unit_price >= 0
        AND discount_amount >= 0
        AND tax_rate >= 0
        AND tax_amount >= 0
        AND line_total_amount >= 0
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS procurement_purchase_orders_order_no_uidx
    ON erp.procurement_purchase_orders (tenant_id, order_no);

CREATE INDEX IF NOT EXISTS procurement_purchase_orders_vendor_status_idx
    ON erp.procurement_purchase_orders (tenant_id, vendor_id, status, order_date DESC);

CREATE INDEX IF NOT EXISTS procurement_purchase_order_lines_order_idx
    ON erp.procurement_purchase_order_lines (tenant_id, purchase_order_id, line_no);

CREATE UNIQUE INDEX IF NOT EXISTS procurement_receipts_receipt_no_uidx
    ON erp.procurement_receipts (tenant_id, receipt_no);

CREATE INDEX IF NOT EXISTS procurement_receipts_order_idx
    ON erp.procurement_receipts (tenant_id, purchase_order_id, receipt_date DESC);

CREATE INDEX IF NOT EXISTS procurement_receipts_warehouse_idx
    ON erp.procurement_receipts (tenant_id, warehouse_id, receipt_date DESC);

CREATE INDEX IF NOT EXISTS procurement_receipt_lines_receipt_idx
    ON erp.procurement_receipt_lines (tenant_id, receipt_id, line_no);

CREATE INDEX IF NOT EXISTS procurement_receipt_lines_order_line_idx
    ON erp.procurement_receipt_lines (tenant_id, purchase_order_line_id);

CREATE UNIQUE INDEX IF NOT EXISTS procurement_purchase_invoices_invoice_no_uidx
    ON erp.procurement_purchase_invoices (tenant_id, invoice_no);

CREATE INDEX IF NOT EXISTS procurement_purchase_invoices_vendor_status_idx
    ON erp.procurement_purchase_invoices (tenant_id, vendor_id, status, invoice_date DESC);

CREATE INDEX IF NOT EXISTS procurement_purchase_invoices_order_receipt_idx
    ON erp.procurement_purchase_invoices (tenant_id, purchase_order_id, receipt_id);

CREATE INDEX IF NOT EXISTS procurement_purchase_invoice_lines_invoice_idx
    ON erp.procurement_purchase_invoice_lines (tenant_id, purchase_invoice_id, line_no);

CREATE INDEX IF NOT EXISTS procurement_purchase_invoice_lines_order_receipt_idx
    ON erp.procurement_purchase_invoice_lines (tenant_id, purchase_order_line_id, receipt_line_id);

ALTER TABLE erp.procurement_purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.procurement_purchase_order_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.procurement_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.procurement_receipt_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.procurement_purchase_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.procurement_purchase_invoice_lines ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp.procurement_purchase_orders FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.procurement_purchase_order_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.procurement_receipts FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.procurement_receipt_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.procurement_purchase_invoices FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.procurement_purchase_invoice_lines FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS procurement_purchase_orders_tenant_policy ON erp.procurement_purchase_orders;
CREATE POLICY procurement_purchase_orders_tenant_policy ON erp.procurement_purchase_orders
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS procurement_purchase_order_lines_tenant_policy ON erp.procurement_purchase_order_lines;
CREATE POLICY procurement_purchase_order_lines_tenant_policy ON erp.procurement_purchase_order_lines
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS procurement_receipts_tenant_policy ON erp.procurement_receipts;
CREATE POLICY procurement_receipts_tenant_policy ON erp.procurement_receipts
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS procurement_receipt_lines_tenant_policy ON erp.procurement_receipt_lines;
CREATE POLICY procurement_receipt_lines_tenant_policy ON erp.procurement_receipt_lines
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS procurement_purchase_invoices_tenant_policy ON erp.procurement_purchase_invoices;
CREATE POLICY procurement_purchase_invoices_tenant_policy ON erp.procurement_purchase_invoices
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS procurement_purchase_invoice_lines_tenant_policy ON erp.procurement_purchase_invoice_lines;
CREATE POLICY procurement_purchase_invoice_lines_tenant_policy ON erp.procurement_purchase_invoice_lines
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

COMMENT ON TABLE erp.procurement_purchase_orders IS 'FAZ 3-9.5 procurement purchase order header table';
COMMENT ON TABLE erp.procurement_purchase_order_lines IS 'FAZ 3-9.5 procurement purchase order line table';
COMMENT ON TABLE erp.procurement_receipts IS 'FAZ 3-9.5 procurement receipt header table';
COMMENT ON TABLE erp.procurement_receipt_lines IS 'FAZ 3-9.5 procurement receipt line table';
COMMENT ON TABLE erp.procurement_purchase_invoices IS 'FAZ 3-9.5 procurement purchase invoice header table';
COMMENT ON TABLE erp.procurement_purchase_invoice_lines IS 'FAZ 3-9.5 procurement purchase invoice line table';

COMMIT;
