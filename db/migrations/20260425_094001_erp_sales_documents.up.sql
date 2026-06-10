-- FAZ 3 / 9.4.1
-- ERP Turkiye canli cekirdegi
-- Sales document tabloları
--
-- Ana mantik:
-- erp_sales_quotations + erp_sales_quotation_lines
-- erp_sales_orders + erp_sales_order_lines
-- erp_sales_deliveries + erp_sales_delivery_lines
-- erp_sales_invoices + erp_sales_invoice_lines
--
-- Not:
-- Bu migration sadece satis belge persist zeminidir.
-- Muhasebe fisleri, e-belge, stok posting ve UFK entegrasyonu sonraki adimlarda baglanir.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS erp_sales_quotations (
    quotation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    quotation_no TEXT NOT NULL,

    customer_id UUID NOT NULL REFERENCES erp_customers(customer_id) ON DELETE RESTRICT,
    party_id UUID NOT NULL REFERENCES erp_parties(party_id) ON DELETE RESTRICT,

    document_date DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_until DATE,

    currency_code TEXT NOT NULL DEFAULT 'TRY',
    exchange_rate NUMERIC(18, 6) NOT NULL DEFAULT 1,

    subtotal_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    vat_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    status TEXT NOT NULL DEFAULT 'draft',
    note TEXT,

    converted_order_id UUID,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_sales_quotations_status_chk
        CHECK (status IN ('draft', 'sent', 'accepted', 'rejected', 'expired', 'cancelled', 'converted')),

    CONSTRAINT erp_sales_quotations_amount_chk
        CHECK (
            exchange_rate > 0
            AND subtotal_amount >= 0
            AND discount_amount >= 0
            AND vat_amount >= 0
            AND total_amount >= 0
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_sales_quotations_tenant_no
    ON erp_sales_quotations (tenant_id, quotation_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_sales_quotations_tenant_customer
    ON erp_sales_quotations (tenant_id, customer_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_quotations_tenant_party
    ON erp_sales_quotations (tenant_id, party_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_quotations_tenant_status
    ON erp_sales_quotations (tenant_id, status);

CREATE INDEX IF NOT EXISTS ix_erp_sales_quotations_tenant_document_date
    ON erp_sales_quotations (tenant_id, document_date);


CREATE TABLE IF NOT EXISTS erp_sales_quotation_lines (
    quotation_line_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    quotation_id UUID NOT NULL REFERENCES erp_sales_quotations(quotation_id) ON DELETE CASCADE,

    line_no INTEGER NOT NULL,

    item_id UUID NOT NULL REFERENCES erp_items(item_id) ON DELETE RESTRICT,
    product_id UUID REFERENCES erp_products(product_id) ON DELETE RESTRICT,
    unit_id UUID NOT NULL REFERENCES erp_units(unit_id) ON DELETE RESTRICT,

    description TEXT,

    quantity NUMERIC(18, 6) NOT NULL,
    unit_price NUMERIC(18, 6) NOT NULL DEFAULT 0,

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

    CONSTRAINT erp_sales_quotation_lines_status_chk
        CHECK (status IN ('active', 'cancelled', 'deleted')),

    CONSTRAINT erp_sales_quotation_lines_quantity_chk
        CHECK (quantity > 0),

    CONSTRAINT erp_sales_quotation_lines_amount_chk
        CHECK (
            unit_price >= 0
            AND discount_rate >= 0
            AND discount_rate <= 100
            AND discount_amount >= 0
            AND vat_rate >= 0
            AND vat_rate <= 100
            AND vat_amount >= 0
            AND line_total >= 0
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_sales_quotation_lines_tenant_doc_line
    ON erp_sales_quotation_lines (tenant_id, quotation_id, line_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_sales_quotation_lines_tenant_item
    ON erp_sales_quotation_lines (tenant_id, item_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_quotation_lines_tenant_product
    ON erp_sales_quotation_lines (tenant_id, product_id);


CREATE TABLE IF NOT EXISTS erp_sales_orders (
    sales_order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    sales_order_no TEXT NOT NULL,

    quotation_id UUID REFERENCES erp_sales_quotations(quotation_id) ON DELETE RESTRICT,

    customer_id UUID NOT NULL REFERENCES erp_customers(customer_id) ON DELETE RESTRICT,
    party_id UUID NOT NULL REFERENCES erp_parties(party_id) ON DELETE RESTRICT,

    document_date DATE NOT NULL DEFAULT CURRENT_DATE,
    requested_delivery_date DATE,

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

    CONSTRAINT erp_sales_orders_status_chk
        CHECK (status IN ('draft', 'confirmed', 'partially_delivered', 'delivered', 'partially_invoiced', 'invoiced', 'cancelled', 'closed')),

    CONSTRAINT erp_sales_orders_amount_chk
        CHECK (
            exchange_rate > 0
            AND subtotal_amount >= 0
            AND discount_amount >= 0
            AND vat_amount >= 0
            AND total_amount >= 0
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_sales_orders_tenant_no
    ON erp_sales_orders (tenant_id, sales_order_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_sales_orders_tenant_customer
    ON erp_sales_orders (tenant_id, customer_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_orders_tenant_party
    ON erp_sales_orders (tenant_id, party_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_orders_tenant_status
    ON erp_sales_orders (tenant_id, status);

CREATE INDEX IF NOT EXISTS ix_erp_sales_orders_tenant_document_date
    ON erp_sales_orders (tenant_id, document_date);

CREATE INDEX IF NOT EXISTS ix_erp_sales_orders_tenant_quotation
    ON erp_sales_orders (tenant_id, quotation_id);


CREATE TABLE IF NOT EXISTS erp_sales_order_lines (
    sales_order_line_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    sales_order_id UUID NOT NULL REFERENCES erp_sales_orders(sales_order_id) ON DELETE CASCADE,
    quotation_line_id UUID REFERENCES erp_sales_quotation_lines(quotation_line_id) ON DELETE RESTRICT,

    line_no INTEGER NOT NULL,

    item_id UUID NOT NULL REFERENCES erp_items(item_id) ON DELETE RESTRICT,
    product_id UUID REFERENCES erp_products(product_id) ON DELETE RESTRICT,
    unit_id UUID NOT NULL REFERENCES erp_units(unit_id) ON DELETE RESTRICT,

    description TEXT,

    quantity NUMERIC(18, 6) NOT NULL,
    delivered_quantity NUMERIC(18, 6) NOT NULL DEFAULT 0,
    invoiced_quantity NUMERIC(18, 6) NOT NULL DEFAULT 0,

    unit_price NUMERIC(18, 6) NOT NULL DEFAULT 0,

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

    CONSTRAINT erp_sales_order_lines_status_chk
        CHECK (status IN ('active', 'cancelled', 'closed', 'deleted')),

    CONSTRAINT erp_sales_order_lines_quantity_chk
        CHECK (
            quantity > 0
            AND delivered_quantity >= 0
            AND invoiced_quantity >= 0
            AND delivered_quantity <= quantity
            AND invoiced_quantity <= quantity
        ),

    CONSTRAINT erp_sales_order_lines_amount_chk
        CHECK (
            unit_price >= 0
            AND discount_rate >= 0
            AND discount_rate <= 100
            AND discount_amount >= 0
            AND vat_rate >= 0
            AND vat_rate <= 100
            AND vat_amount >= 0
            AND line_total >= 0
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_sales_order_lines_tenant_doc_line
    ON erp_sales_order_lines (tenant_id, sales_order_id, line_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_sales_order_lines_tenant_item
    ON erp_sales_order_lines (tenant_id, item_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_order_lines_tenant_product
    ON erp_sales_order_lines (tenant_id, product_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_order_lines_tenant_quotation_line
    ON erp_sales_order_lines (tenant_id, quotation_line_id);


CREATE TABLE IF NOT EXISTS erp_sales_deliveries (
    delivery_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    delivery_no TEXT NOT NULL,

    sales_order_id UUID REFERENCES erp_sales_orders(sales_order_id) ON DELETE RESTRICT,

    customer_id UUID NOT NULL REFERENCES erp_customers(customer_id) ON DELETE RESTRICT,
    party_id UUID NOT NULL REFERENCES erp_parties(party_id) ON DELETE RESTRICT,
    warehouse_id UUID NOT NULL REFERENCES erp_warehouses(warehouse_id) ON DELETE RESTRICT,

    document_date DATE NOT NULL DEFAULT CURRENT_DATE,
    delivery_date DATE,

    status TEXT NOT NULL DEFAULT 'draft',
    note TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_sales_deliveries_status_chk
        CHECK (status IN ('draft', 'ready', 'shipped', 'delivered', 'cancelled', 'returned'))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_sales_deliveries_tenant_no
    ON erp_sales_deliveries (tenant_id, delivery_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_sales_deliveries_tenant_order
    ON erp_sales_deliveries (tenant_id, sales_order_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_deliveries_tenant_customer
    ON erp_sales_deliveries (tenant_id, customer_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_deliveries_tenant_warehouse
    ON erp_sales_deliveries (tenant_id, warehouse_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_deliveries_tenant_status
    ON erp_sales_deliveries (tenant_id, status);

CREATE INDEX IF NOT EXISTS ix_erp_sales_deliveries_tenant_document_date
    ON erp_sales_deliveries (tenant_id, document_date);


CREATE TABLE IF NOT EXISTS erp_sales_delivery_lines (
    delivery_line_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    delivery_id UUID NOT NULL REFERENCES erp_sales_deliveries(delivery_id) ON DELETE CASCADE,
    sales_order_line_id UUID REFERENCES erp_sales_order_lines(sales_order_line_id) ON DELETE RESTRICT,

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

    CONSTRAINT erp_sales_delivery_lines_status_chk
        CHECK (status IN ('active', 'cancelled', 'returned', 'deleted')),

    CONSTRAINT erp_sales_delivery_lines_quantity_chk
        CHECK (quantity > 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_sales_delivery_lines_tenant_doc_line
    ON erp_sales_delivery_lines (tenant_id, delivery_id, line_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_sales_delivery_lines_tenant_item
    ON erp_sales_delivery_lines (tenant_id, item_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_delivery_lines_tenant_product
    ON erp_sales_delivery_lines (tenant_id, product_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_delivery_lines_tenant_order_line
    ON erp_sales_delivery_lines (tenant_id, sales_order_line_id);


CREATE TABLE IF NOT EXISTS erp_sales_invoices (
    sales_invoice_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    sales_invoice_no TEXT NOT NULL,

    sales_order_id UUID REFERENCES erp_sales_orders(sales_order_id) ON DELETE RESTRICT,
    delivery_id UUID REFERENCES erp_sales_deliveries(delivery_id) ON DELETE RESTRICT,

    customer_id UUID NOT NULL REFERENCES erp_customers(customer_id) ON DELETE RESTRICT,
    party_id UUID NOT NULL REFERENCES erp_parties(party_id) ON DELETE RESTRICT,

    invoice_type TEXT NOT NULL DEFAULT 'sales',

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

    CONSTRAINT erp_sales_invoices_invoice_type_chk
        CHECK (invoice_type IN ('sales', 'return', 'proforma')),

    CONSTRAINT erp_sales_invoices_e_document_status_chk
        CHECK (e_document_status IN ('none', 'pending', 'sent', 'accepted', 'rejected', 'cancelled')),

    CONSTRAINT erp_sales_invoices_status_chk
        CHECK (status IN ('draft', 'issued', 'partially_paid', 'paid', 'cancelled', 'void')),

    CONSTRAINT erp_sales_invoices_amount_chk
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

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_sales_invoices_tenant_no
    ON erp_sales_invoices (tenant_id, sales_invoice_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_sales_invoices_tenant_order
    ON erp_sales_invoices (tenant_id, sales_order_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_invoices_tenant_delivery
    ON erp_sales_invoices (tenant_id, delivery_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_invoices_tenant_customer
    ON erp_sales_invoices (tenant_id, customer_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_invoices_tenant_status
    ON erp_sales_invoices (tenant_id, status);

CREATE INDEX IF NOT EXISTS ix_erp_sales_invoices_tenant_document_date
    ON erp_sales_invoices (tenant_id, document_date);


CREATE TABLE IF NOT EXISTS erp_sales_invoice_lines (
    sales_invoice_line_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    sales_invoice_id UUID NOT NULL REFERENCES erp_sales_invoices(sales_invoice_id) ON DELETE CASCADE,
    sales_order_line_id UUID REFERENCES erp_sales_order_lines(sales_order_line_id) ON DELETE RESTRICT,
    delivery_line_id UUID REFERENCES erp_sales_delivery_lines(delivery_line_id) ON DELETE RESTRICT,

    line_no INTEGER NOT NULL,

    item_id UUID NOT NULL REFERENCES erp_items(item_id) ON DELETE RESTRICT,
    product_id UUID REFERENCES erp_products(product_id) ON DELETE RESTRICT,
    unit_id UUID NOT NULL REFERENCES erp_units(unit_id) ON DELETE RESTRICT,

    description TEXT,

    quantity NUMERIC(18, 6) NOT NULL,
    unit_price NUMERIC(18, 6) NOT NULL DEFAULT 0,

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

    CONSTRAINT erp_sales_invoice_lines_status_chk
        CHECK (status IN ('active', 'cancelled', 'deleted')),

    CONSTRAINT erp_sales_invoice_lines_quantity_chk
        CHECK (quantity > 0),

    CONSTRAINT erp_sales_invoice_lines_amount_chk
        CHECK (
            unit_price >= 0
            AND discount_rate >= 0
            AND discount_rate <= 100
            AND discount_amount >= 0
            AND vat_rate >= 0
            AND vat_rate <= 100
            AND vat_amount >= 0
            AND line_total >= 0
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_sales_invoice_lines_tenant_doc_line
    ON erp_sales_invoice_lines (tenant_id, sales_invoice_id, line_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_sales_invoice_lines_tenant_item
    ON erp_sales_invoice_lines (tenant_id, item_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_invoice_lines_tenant_product
    ON erp_sales_invoice_lines (tenant_id, product_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_invoice_lines_tenant_order_line
    ON erp_sales_invoice_lines (tenant_id, sales_order_line_id);

CREATE INDEX IF NOT EXISTS ix_erp_sales_invoice_lines_tenant_delivery_line
    ON erp_sales_invoice_lines (tenant_id, delivery_line_id);


ALTER TABLE erp_sales_quotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_sales_quotation_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_sales_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_sales_order_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_sales_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_sales_delivery_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_sales_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_sales_invoice_lines ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp_sales_quotations FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_sales_quotation_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_sales_orders FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_sales_order_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_sales_deliveries FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_sales_delivery_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_sales_invoices FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_sales_invoice_lines FORCE ROW LEVEL SECURITY;

CREATE POLICY erp_sales_quotations_tenant_isolation_policy
    ON erp_sales_quotations
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_sales_quotation_lines_tenant_isolation_policy
    ON erp_sales_quotation_lines
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_sales_orders_tenant_isolation_policy
    ON erp_sales_orders
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_sales_order_lines_tenant_isolation_policy
    ON erp_sales_order_lines
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_sales_deliveries_tenant_isolation_policy
    ON erp_sales_deliveries
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_sales_delivery_lines_tenant_isolation_policy
    ON erp_sales_delivery_lines
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_sales_invoices_tenant_isolation_policy
    ON erp_sales_invoices
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_sales_invoice_lines_tenant_isolation_policy
    ON erp_sales_invoice_lines
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));
