-- FAZ 3 / 9.5.1
-- ERP Turkiye canli cekirdegi
-- Procurement document tabloları
--
-- Ana mantik:
-- erp_purchase_orders + erp_purchase_order_lines
-- erp_purchase_receipts + erp_purchase_receipt_lines
-- erp_purchase_invoices + erp_purchase_invoice_lines

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS erp_purchase_orders (
    purchase_order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    purchase_order_no TEXT NOT NULL,

    vendor_id UUID NOT NULL REFERENCES erp_vendors(vendor_id) ON DELETE RESTRICT,
    party_id UUID NOT NULL REFERENCES erp_parties(party_id) ON DELETE RESTRICT,

    document_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_receipt_date DATE,

    currency_code TEXT NOT NULL DEFAULT 'TRY',
    exchange_rate NUMERIC(18, 6) NOT NULL DEFAULT 1,

    subtotal_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    vat_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    status TEXT NOT NULL DEFAULT 'draft',
    note TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_purchase_orders_status_chk
        CHECK (status IN ('draft', 'confirmed', 'partially_received', 'received', 'partially_invoiced', 'invoiced', 'cancelled', 'closed')),

    CONSTRAINT erp_purchase_orders_amount_chk
        CHECK (
            exchange_rate > 0
            AND subtotal_amount >= 0
            AND discount_amount >= 0
            AND vat_amount >= 0
            AND total_amount >= 0
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_purchase_orders_tenant_no
    ON erp_purchase_orders (tenant_id, purchase_order_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_purchase_orders_tenant_vendor
    ON erp_purchase_orders (tenant_id, vendor_id);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_orders_tenant_party
    ON erp_purchase_orders (tenant_id, party_id);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_orders_tenant_status
    ON erp_purchase_orders (tenant_id, status);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_orders_tenant_document_date
    ON erp_purchase_orders (tenant_id, document_date);


CREATE TABLE IF NOT EXISTS erp_purchase_order_lines (
    purchase_order_line_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    purchase_order_id UUID NOT NULL REFERENCES erp_purchase_orders(purchase_order_id) ON DELETE CASCADE,

    line_no INTEGER NOT NULL,

    item_id UUID NOT NULL REFERENCES erp_items(item_id) ON DELETE RESTRICT,
    product_id UUID REFERENCES erp_products(product_id) ON DELETE RESTRICT,
    unit_id UUID NOT NULL REFERENCES erp_units(unit_id) ON DELETE RESTRICT,

    description TEXT,

    quantity NUMERIC(18, 6) NOT NULL,
    received_quantity NUMERIC(18, 6) NOT NULL DEFAULT 0,
    invoiced_quantity NUMERIC(18, 6) NOT NULL DEFAULT 0,

    unit_cost NUMERIC(18, 6) NOT NULL DEFAULT 0,

    discount_rate NUMERIC(5, 2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    vat_rate NUMERIC(5, 2) NOT NULL DEFAULT 20.00,
    vat_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    line_total NUMERIC(18, 2) NOT NULL DEFAULT 0,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_purchase_order_lines_status_chk
        CHECK (status IN ('active', 'cancelled', 'closed', 'deleted')),

    CONSTRAINT erp_purchase_order_lines_quantity_chk
        CHECK (
            quantity > 0
            AND received_quantity >= 0
            AND invoiced_quantity >= 0
            AND received_quantity <= quantity
            AND invoiced_quantity <= quantity
        ),

    CONSTRAINT erp_purchase_order_lines_amount_chk
        CHECK (
            unit_cost >= 0
            AND discount_rate >= 0
            AND discount_rate <= 100
            AND discount_amount >= 0
            AND vat_rate >= 0
            AND vat_rate <= 100
            AND vat_amount >= 0
            AND line_total >= 0
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_purchase_order_lines_tenant_doc_line
    ON erp_purchase_order_lines (tenant_id, purchase_order_id, line_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_purchase_order_lines_tenant_item
    ON erp_purchase_order_lines (tenant_id, item_id);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_order_lines_tenant_product
    ON erp_purchase_order_lines (tenant_id, product_id);


CREATE TABLE IF NOT EXISTS erp_purchase_receipts (
    purchase_receipt_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    purchase_receipt_no TEXT NOT NULL,

    purchase_order_id UUID REFERENCES erp_purchase_orders(purchase_order_id) ON DELETE RESTRICT,

    vendor_id UUID NOT NULL REFERENCES erp_vendors(vendor_id) ON DELETE RESTRICT,
    party_id UUID NOT NULL REFERENCES erp_parties(party_id) ON DELETE RESTRICT,
    warehouse_id UUID NOT NULL REFERENCES erp_warehouses(warehouse_id) ON DELETE RESTRICT,

    document_date DATE NOT NULL DEFAULT CURRENT_DATE,
    receipt_date DATE,

    status TEXT NOT NULL DEFAULT 'draft',
    note TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_purchase_receipts_status_chk
        CHECK (status IN ('draft', 'received', 'cancelled', 'returned'))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_purchase_receipts_tenant_no
    ON erp_purchase_receipts (tenant_id, purchase_receipt_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_purchase_receipts_tenant_order
    ON erp_purchase_receipts (tenant_id, purchase_order_id);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_receipts_tenant_vendor
    ON erp_purchase_receipts (tenant_id, vendor_id);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_receipts_tenant_warehouse
    ON erp_purchase_receipts (tenant_id, warehouse_id);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_receipts_tenant_status
    ON erp_purchase_receipts (tenant_id, status);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_receipts_tenant_document_date
    ON erp_purchase_receipts (tenant_id, document_date);


CREATE TABLE IF NOT EXISTS erp_purchase_receipt_lines (
    purchase_receipt_line_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    purchase_receipt_id UUID NOT NULL REFERENCES erp_purchase_receipts(purchase_receipt_id) ON DELETE CASCADE,
    purchase_order_line_id UUID REFERENCES erp_purchase_order_lines(purchase_order_line_id) ON DELETE RESTRICT,

    line_no INTEGER NOT NULL,

    item_id UUID NOT NULL REFERENCES erp_items(item_id) ON DELETE RESTRICT,
    product_id UUID REFERENCES erp_products(product_id) ON DELETE RESTRICT,
    unit_id UUID NOT NULL REFERENCES erp_units(unit_id) ON DELETE RESTRICT,

    description TEXT,

    quantity NUMERIC(18, 6) NOT NULL,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_purchase_receipt_lines_status_chk
        CHECK (status IN ('active', 'cancelled', 'returned', 'deleted')),

    CONSTRAINT erp_purchase_receipt_lines_quantity_chk
        CHECK (quantity > 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_purchase_receipt_lines_tenant_doc_line
    ON erp_purchase_receipt_lines (tenant_id, purchase_receipt_id, line_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_purchase_receipt_lines_tenant_item
    ON erp_purchase_receipt_lines (tenant_id, item_id);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_receipt_lines_tenant_product
    ON erp_purchase_receipt_lines (tenant_id, product_id);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_receipt_lines_tenant_order_line
    ON erp_purchase_receipt_lines (tenant_id, purchase_order_line_id);


CREATE TABLE IF NOT EXISTS erp_purchase_invoices (
    purchase_invoice_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    purchase_invoice_no TEXT NOT NULL,
    vendor_invoice_no TEXT,

    purchase_order_id UUID REFERENCES erp_purchase_orders(purchase_order_id) ON DELETE RESTRICT,
    purchase_receipt_id UUID REFERENCES erp_purchase_receipts(purchase_receipt_id) ON DELETE RESTRICT,

    vendor_id UUID NOT NULL REFERENCES erp_vendors(vendor_id) ON DELETE RESTRICT,
    party_id UUID NOT NULL REFERENCES erp_parties(party_id) ON DELETE RESTRICT,

    invoice_type TEXT NOT NULL DEFAULT 'purchase',

    document_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE,

    currency_code TEXT NOT NULL DEFAULT 'TRY',
    exchange_rate NUMERIC(18, 6) NOT NULL DEFAULT 1,

    subtotal_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    vat_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    paid_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    remaining_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    e_document_status TEXT NOT NULL DEFAULT 'none',

    status TEXT NOT NULL DEFAULT 'draft',
    note TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_purchase_invoices_invoice_type_chk
        CHECK (invoice_type IN ('purchase', 'return', 'proforma')),

    CONSTRAINT erp_purchase_invoices_e_document_status_chk
        CHECK (e_document_status IN ('none', 'pending', 'received', 'accepted', 'rejected', 'cancelled')),

    CONSTRAINT erp_purchase_invoices_status_chk
        CHECK (status IN ('draft', 'received', 'partially_paid', 'paid', 'cancelled', 'void')),

    CONSTRAINT erp_purchase_invoices_amount_chk
        CHECK (
            exchange_rate > 0
            AND subtotal_amount >= 0
            AND discount_amount >= 0
            AND vat_amount >= 0
            AND total_amount >= 0
            AND paid_amount >= 0
            AND remaining_amount >= 0
            AND paid_amount <= total_amount
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_purchase_invoices_tenant_no
    ON erp_purchase_invoices (tenant_id, purchase_invoice_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_purchase_invoices_tenant_vendor_invoice_no
    ON erp_purchase_invoices (tenant_id, vendor_invoice_no)
    WHERE vendor_invoice_no IS NOT NULL AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_purchase_invoices_tenant_order
    ON erp_purchase_invoices (tenant_id, purchase_order_id);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_invoices_tenant_receipt
    ON erp_purchase_invoices (tenant_id, purchase_receipt_id);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_invoices_tenant_vendor
    ON erp_purchase_invoices (tenant_id, vendor_id);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_invoices_tenant_status
    ON erp_purchase_invoices (tenant_id, status);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_invoices_tenant_document_date
    ON erp_purchase_invoices (tenant_id, document_date);


CREATE TABLE IF NOT EXISTS erp_purchase_invoice_lines (
    purchase_invoice_line_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    purchase_invoice_id UUID NOT NULL REFERENCES erp_purchase_invoices(purchase_invoice_id) ON DELETE CASCADE,
    purchase_order_line_id UUID REFERENCES erp_purchase_order_lines(purchase_order_line_id) ON DELETE RESTRICT,
    purchase_receipt_line_id UUID REFERENCES erp_purchase_receipt_lines(purchase_receipt_line_id) ON DELETE RESTRICT,

    line_no INTEGER NOT NULL,

    item_id UUID NOT NULL REFERENCES erp_items(item_id) ON DELETE RESTRICT,
    product_id UUID REFERENCES erp_products(product_id) ON DELETE RESTRICT,
    unit_id UUID NOT NULL REFERENCES erp_units(unit_id) ON DELETE RESTRICT,

    description TEXT,

    quantity NUMERIC(18, 6) NOT NULL,
    unit_cost NUMERIC(18, 6) NOT NULL DEFAULT 0,

    discount_rate NUMERIC(5, 2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    vat_rate NUMERIC(5, 2) NOT NULL DEFAULT 20.00,
    vat_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    line_total NUMERIC(18, 2) NOT NULL DEFAULT 0,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_purchase_invoice_lines_status_chk
        CHECK (status IN ('active', 'cancelled', 'deleted')),

    CONSTRAINT erp_purchase_invoice_lines_quantity_chk
        CHECK (quantity > 0),

    CONSTRAINT erp_purchase_invoice_lines_amount_chk
        CHECK (
            unit_cost >= 0
            AND discount_rate >= 0
            AND discount_rate <= 100
            AND discount_amount >= 0
            AND vat_rate >= 0
            AND vat_rate <= 100
            AND vat_amount >= 0
            AND line_total >= 0
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_purchase_invoice_lines_tenant_doc_line
    ON erp_purchase_invoice_lines (tenant_id, purchase_invoice_id, line_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_purchase_invoice_lines_tenant_item
    ON erp_purchase_invoice_lines (tenant_id, item_id);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_invoice_lines_tenant_product
    ON erp_purchase_invoice_lines (tenant_id, product_id);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_invoice_lines_tenant_order_line
    ON erp_purchase_invoice_lines (tenant_id, purchase_order_line_id);

CREATE INDEX IF NOT EXISTS ix_erp_purchase_invoice_lines_tenant_receipt_line
    ON erp_purchase_invoice_lines (tenant_id, purchase_receipt_line_id);


ALTER TABLE erp_purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_purchase_order_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_purchase_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_purchase_receipt_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_purchase_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_purchase_invoice_lines ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp_purchase_orders FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_purchase_order_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_purchase_receipts FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_purchase_receipt_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_purchase_invoices FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_purchase_invoice_lines FORCE ROW LEVEL SECURITY;

CREATE POLICY erp_purchase_orders_tenant_isolation_policy
    ON erp_purchase_orders
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_purchase_order_lines_tenant_isolation_policy
    ON erp_purchase_order_lines
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_purchase_receipts_tenant_isolation_policy
    ON erp_purchase_receipts
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_purchase_receipt_lines_tenant_isolation_policy
    ON erp_purchase_receipt_lines
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_purchase_invoices_tenant_isolation_policy
    ON erp_purchase_invoices
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_purchase_invoice_lines_tenant_isolation_policy
    ON erp_purchase_invoice_lines
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));
