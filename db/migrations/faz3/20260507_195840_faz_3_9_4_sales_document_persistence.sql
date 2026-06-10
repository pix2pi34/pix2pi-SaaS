BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS erp;

CREATE TABLE IF NOT EXISTS erp.sales_quotations (
    tenant_id uuid NOT NULL,
    sales_quotation_id uuid NOT NULL DEFAULT gen_random_uuid(),

    quotation_no varchar(96) NOT NULL,
    quotation_date date NOT NULL DEFAULT CURRENT_DATE,
    valid_until date,

    customer_id uuid,
    customer_code varchar(96),
    customer_title varchar(255) NOT NULL,
    tax_identity_no varchar(32),
    tax_office varchar(128),

    currency_code char(3) NOT NULL DEFAULT 'TRY',
    exchange_rate numeric(18, 8) NOT NULL DEFAULT 1,

    subtotal_amount numeric(18, 2) NOT NULL DEFAULT 0,
    discount_amount numeric(18, 2) NOT NULL DEFAULT 0,
    tax_amount numeric(18, 2) NOT NULL DEFAULT 0,
    total_amount numeric(18, 2) NOT NULL DEFAULT 0,

    status varchar(40) NOT NULL DEFAULT 'DRAFT',

    source_channel varchar(64) DEFAULT 'ERP',
    notes text,

    idempotency_key varchar(160),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,
    approved_by uuid,
    approved_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT sales_quotations_pk PRIMARY KEY (tenant_id, sales_quotation_id),
    CONSTRAINT sales_quotations_no_unique UNIQUE (tenant_id, quotation_no),
    CONSTRAINT sales_quotations_idempotency_unique UNIQUE (tenant_id, idempotency_key),
    CONSTRAINT sales_quotations_status_chk CHECK (
        status IN ('DRAFT', 'SENT', 'ACCEPTED', 'REJECTED', 'EXPIRED', 'CANCELED', 'CONVERTED')
    ),
    CONSTRAINT sales_quotations_amount_chk CHECK (
        subtotal_amount >= 0
        AND discount_amount >= 0
        AND tax_amount >= 0
        AND total_amount >= 0
        AND exchange_rate > 0
    ),
    CONSTRAINT sales_quotations_date_chk CHECK (
        valid_until IS NULL OR valid_until >= quotation_date
    )
);

CREATE TABLE IF NOT EXISTS erp.sales_quotation_lines (
    tenant_id uuid NOT NULL,
    sales_quotation_line_id uuid NOT NULL DEFAULT gen_random_uuid(),
    sales_quotation_id uuid NOT NULL,

    line_no integer NOT NULL,

    item_id uuid,
    item_code varchar(96),
    item_name varchar(255) NOT NULL,
    category_id uuid,
    unit_code varchar(32) NOT NULL DEFAULT 'ADET',

    quantity numeric(18, 4) NOT NULL DEFAULT 0,
    unit_price numeric(18, 4) NOT NULL DEFAULT 0,
    discount_amount numeric(18, 2) NOT NULL DEFAULT 0,
    tax_rate numeric(9, 4) NOT NULL DEFAULT 0,
    tax_amount numeric(18, 2) NOT NULL DEFAULT 0,
    line_total_amount numeric(18, 2) NOT NULL DEFAULT 0,

    tax_rule_id uuid,
    account_mapping_rule_id uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT sales_quotation_lines_pk PRIMARY KEY (tenant_id, sales_quotation_line_id),
    CONSTRAINT sales_quotation_lines_header_fk FOREIGN KEY (tenant_id, sales_quotation_id)
        REFERENCES erp.sales_quotations (tenant_id, sales_quotation_id)
        ON DELETE CASCADE,
    CONSTRAINT sales_quotation_lines_line_unique UNIQUE (tenant_id, sales_quotation_id, line_no),
    CONSTRAINT sales_quotation_lines_qty_chk CHECK (quantity >= 0),
    CONSTRAINT sales_quotation_lines_amount_chk CHECK (
        unit_price >= 0
        AND discount_amount >= 0
        AND tax_rate >= 0
        AND tax_amount >= 0
        AND line_total_amount >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.sales_orders (
    tenant_id uuid NOT NULL,
    sales_order_id uuid NOT NULL DEFAULT gen_random_uuid(),

    order_no varchar(96) NOT NULL,
    order_date date NOT NULL DEFAULT CURRENT_DATE,
    promised_delivery_date date,

    sales_quotation_id uuid,

    customer_id uuid,
    customer_code varchar(96),
    customer_title varchar(255) NOT NULL,
    tax_identity_no varchar(32),
    tax_office varchar(128),

    billing_address_id uuid,
    shipping_address_id uuid,

    currency_code char(3) NOT NULL DEFAULT 'TRY',
    exchange_rate numeric(18, 8) NOT NULL DEFAULT 1,

    subtotal_amount numeric(18, 2) NOT NULL DEFAULT 0,
    discount_amount numeric(18, 2) NOT NULL DEFAULT 0,
    tax_amount numeric(18, 2) NOT NULL DEFAULT 0,
    total_amount numeric(18, 2) NOT NULL DEFAULT 0,

    status varchar(40) NOT NULL DEFAULT 'DRAFT',
    fulfillment_status varchar(40) NOT NULL DEFAULT 'UNFULFILLED',
    invoice_status varchar(40) NOT NULL DEFAULT 'UNINVOICED',
    payment_status varchar(40) NOT NULL DEFAULT 'UNPAID',

    source_channel varchar(64) DEFAULT 'ERP',
    notes text,

    idempotency_key varchar(160),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,
    approved_by uuid,
    approved_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT sales_orders_pk PRIMARY KEY (tenant_id, sales_order_id),
    CONSTRAINT sales_orders_no_unique UNIQUE (tenant_id, order_no),
    CONSTRAINT sales_orders_idempotency_unique UNIQUE (tenant_id, idempotency_key),
    CONSTRAINT sales_orders_quotation_fk FOREIGN KEY (tenant_id, sales_quotation_id)
        REFERENCES erp.sales_quotations (tenant_id, sales_quotation_id)
        ON DELETE SET NULL,
    CONSTRAINT sales_orders_status_chk CHECK (
        status IN ('DRAFT', 'APPROVAL_WAITING', 'APPROVED', 'CONFIRMED', 'CANCELED', 'CLOSED')
    ),
    CONSTRAINT sales_orders_fulfillment_status_chk CHECK (
        fulfillment_status IN ('UNFULFILLED', 'PARTIALLY_FULFILLED', 'FULFILLED', 'CANCELED')
    ),
    CONSTRAINT sales_orders_invoice_status_chk CHECK (
        invoice_status IN ('UNINVOICED', 'PARTIALLY_INVOICED', 'INVOICED', 'CANCELED')
    ),
    CONSTRAINT sales_orders_payment_status_chk CHECK (
        payment_status IN ('UNPAID', 'PARTIALLY_PAID', 'PAID', 'REFUNDED', 'RECONCILED')
    ),
    CONSTRAINT sales_orders_amount_chk CHECK (
        subtotal_amount >= 0
        AND discount_amount >= 0
        AND tax_amount >= 0
        AND total_amount >= 0
        AND exchange_rate > 0
    )
);

CREATE TABLE IF NOT EXISTS erp.sales_order_lines (
    tenant_id uuid NOT NULL,
    sales_order_line_id uuid NOT NULL DEFAULT gen_random_uuid(),
    sales_order_id uuid NOT NULL,
    sales_quotation_line_id uuid,

    line_no integer NOT NULL,

    item_id uuid,
    item_code varchar(96),
    item_name varchar(255) NOT NULL,
    category_id uuid,
    unit_code varchar(32) NOT NULL DEFAULT 'ADET',

    quantity_ordered numeric(18, 4) NOT NULL DEFAULT 0,
    quantity_delivered numeric(18, 4) NOT NULL DEFAULT 0,
    quantity_invoiced numeric(18, 4) NOT NULL DEFAULT 0,

    unit_price numeric(18, 4) NOT NULL DEFAULT 0,
    discount_amount numeric(18, 2) NOT NULL DEFAULT 0,
    tax_rate numeric(9, 4) NOT NULL DEFAULT 0,
    tax_amount numeric(18, 2) NOT NULL DEFAULT 0,
    line_total_amount numeric(18, 2) NOT NULL DEFAULT 0,

    tax_rule_id uuid,
    account_mapping_rule_id uuid,

    status varchar(40) NOT NULL DEFAULT 'OPEN',

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT sales_order_lines_pk PRIMARY KEY (tenant_id, sales_order_line_id),
    CONSTRAINT sales_order_lines_order_fk FOREIGN KEY (tenant_id, sales_order_id)
        REFERENCES erp.sales_orders (tenant_id, sales_order_id)
        ON DELETE CASCADE,
    CONSTRAINT sales_order_lines_quotation_line_fk FOREIGN KEY (tenant_id, sales_quotation_line_id)
        REFERENCES erp.sales_quotation_lines (tenant_id, sales_quotation_line_id)
        ON DELETE SET NULL,
    CONSTRAINT sales_order_lines_line_unique UNIQUE (tenant_id, sales_order_id, line_no),
    CONSTRAINT sales_order_lines_status_chk CHECK (
        status IN ('OPEN', 'PARTIALLY_DELIVERED', 'DELIVERED', 'PARTIALLY_INVOICED', 'INVOICED', 'CANCELED', 'CLOSED')
    ),
    CONSTRAINT sales_order_lines_qty_chk CHECK (
        quantity_ordered >= 0
        AND quantity_delivered >= 0
        AND quantity_invoiced >= 0
    ),
    CONSTRAINT sales_order_lines_amount_chk CHECK (
        unit_price >= 0
        AND discount_amount >= 0
        AND tax_rate >= 0
        AND tax_amount >= 0
        AND line_total_amount >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.sales_deliveries (
    tenant_id uuid NOT NULL,
    sales_delivery_id uuid NOT NULL DEFAULT gen_random_uuid(),

    delivery_no varchar(96) NOT NULL,
    delivery_date date NOT NULL DEFAULT CURRENT_DATE,

    sales_order_id uuid,

    customer_id uuid,
    customer_code varchar(96),
    customer_title varchar(255) NOT NULL,

    warehouse_id uuid,
    warehouse_code varchar(96),
    warehouse_name varchar(255),

    shipping_address_id uuid,
    carrier_name varchar(128),
    tracking_no varchar(128),

    status varchar(40) NOT NULL DEFAULT 'DRAFT',
    inventory_posted boolean NOT NULL DEFAULT false,
    inventory_posted_at timestamptz,

    e_belge_id uuid,

    idempotency_key varchar(160),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,
    posted_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT sales_deliveries_pk PRIMARY KEY (tenant_id, sales_delivery_id),
    CONSTRAINT sales_deliveries_no_unique UNIQUE (tenant_id, delivery_no),
    CONSTRAINT sales_deliveries_idempotency_unique UNIQUE (tenant_id, idempotency_key),
    CONSTRAINT sales_deliveries_order_fk FOREIGN KEY (tenant_id, sales_order_id)
        REFERENCES erp.sales_orders (tenant_id, sales_order_id)
        ON DELETE SET NULL,
    CONSTRAINT sales_deliveries_ebelge_fk FOREIGN KEY (tenant_id, e_belge_id)
        REFERENCES erp.e_belge_documents (tenant_id, e_belge_id)
        ON DELETE SET NULL,
    CONSTRAINT sales_deliveries_status_chk CHECK (
        status IN ('DRAFT', 'READY', 'PICKING', 'SHIPPED', 'DELIVERED', 'CANCELED', 'REVERSED')
    )
);

CREATE TABLE IF NOT EXISTS erp.sales_delivery_lines (
    tenant_id uuid NOT NULL,
    sales_delivery_line_id uuid NOT NULL DEFAULT gen_random_uuid(),
    sales_delivery_id uuid NOT NULL,

    sales_order_id uuid,
    sales_order_line_id uuid,

    line_no integer NOT NULL,

    item_id uuid,
    item_code varchar(96),
    item_name varchar(255) NOT NULL,
    unit_code varchar(32) NOT NULL DEFAULT 'ADET',

    quantity_delivered numeric(18, 4) NOT NULL DEFAULT 0,
    quantity_returned numeric(18, 4) NOT NULL DEFAULT 0,

    warehouse_id uuid,
    inventory_movement_id uuid,

    lot_no varchar(128),
    serial_no varchar(128),
    expiry_date date,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT sales_delivery_lines_pk PRIMARY KEY (tenant_id, sales_delivery_line_id),
    CONSTRAINT sales_delivery_lines_delivery_fk FOREIGN KEY (tenant_id, sales_delivery_id)
        REFERENCES erp.sales_deliveries (tenant_id, sales_delivery_id)
        ON DELETE CASCADE,
    CONSTRAINT sales_delivery_lines_order_fk FOREIGN KEY (tenant_id, sales_order_id)
        REFERENCES erp.sales_orders (tenant_id, sales_order_id)
        ON DELETE SET NULL,
    CONSTRAINT sales_delivery_lines_order_line_fk FOREIGN KEY (tenant_id, sales_order_line_id)
        REFERENCES erp.sales_order_lines (tenant_id, sales_order_line_id)
        ON DELETE SET NULL,
    CONSTRAINT sales_delivery_lines_inventory_movement_fk FOREIGN KEY (tenant_id, inventory_movement_id)
        REFERENCES erp.inventory_stock_movements (tenant_id, stock_movement_id)
        ON DELETE SET NULL,
    CONSTRAINT sales_delivery_lines_line_unique UNIQUE (tenant_id, sales_delivery_id, line_no),
    CONSTRAINT sales_delivery_lines_qty_chk CHECK (
        quantity_delivered >= 0
        AND quantity_returned >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.sales_invoices (
    tenant_id uuid NOT NULL,
    sales_invoice_id uuid NOT NULL DEFAULT gen_random_uuid(),

    invoice_no varchar(96) NOT NULL,
    invoice_date date NOT NULL DEFAULT CURRENT_DATE,
    due_date date,

    sales_order_id uuid,
    sales_delivery_id uuid,

    customer_id uuid,
    customer_code varchar(96),
    customer_title varchar(255) NOT NULL,
    tax_identity_no varchar(32),
    tax_office varchar(128),

    billing_address_id uuid,

    currency_code char(3) NOT NULL DEFAULT 'TRY',
    exchange_rate numeric(18, 8) NOT NULL DEFAULT 1,

    subtotal_amount numeric(18, 2) NOT NULL DEFAULT 0,
    discount_amount numeric(18, 2) NOT NULL DEFAULT 0,
    tax_amount numeric(18, 2) NOT NULL DEFAULT 0,
    total_amount numeric(18, 2) NOT NULL DEFAULT 0,

    status varchar(40) NOT NULL DEFAULT 'DRAFT',
    payment_status varchar(40) NOT NULL DEFAULT 'UNPAID',

    journal_id uuid,
    e_belge_id uuid,

    source_channel varchar(64) DEFAULT 'ERP',

    idempotency_key varchar(160),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,
    posted_by uuid,
    posted_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT sales_invoices_pk PRIMARY KEY (tenant_id, sales_invoice_id),
    CONSTRAINT sales_invoices_no_unique UNIQUE (tenant_id, invoice_no),
    CONSTRAINT sales_invoices_idempotency_unique UNIQUE (tenant_id, idempotency_key),
    CONSTRAINT sales_invoices_order_fk FOREIGN KEY (tenant_id, sales_order_id)
        REFERENCES erp.sales_orders (tenant_id, sales_order_id)
        ON DELETE SET NULL,
    CONSTRAINT sales_invoices_delivery_fk FOREIGN KEY (tenant_id, sales_delivery_id)
        REFERENCES erp.sales_deliveries (tenant_id, sales_delivery_id)
        ON DELETE SET NULL,
    CONSTRAINT sales_invoices_ebelge_fk FOREIGN KEY (tenant_id, e_belge_id)
        REFERENCES erp.e_belge_documents (tenant_id, e_belge_id)
        ON DELETE SET NULL,
    CONSTRAINT sales_invoices_status_chk CHECK (
        status IN ('DRAFT', 'READY', 'POSTED', 'CANCELED', 'REVERSED')
    ),
    CONSTRAINT sales_invoices_payment_status_chk CHECK (
        payment_status IN ('UNPAID', 'PARTIALLY_PAID', 'PAID', 'REFUNDED', 'RECONCILED')
    ),
    CONSTRAINT sales_invoices_amount_chk CHECK (
        subtotal_amount >= 0
        AND discount_amount >= 0
        AND tax_amount >= 0
        AND total_amount >= 0
        AND exchange_rate > 0
    )
);

CREATE TABLE IF NOT EXISTS erp.sales_invoice_lines (
    tenant_id uuid NOT NULL,
    sales_invoice_line_id uuid NOT NULL DEFAULT gen_random_uuid(),
    sales_invoice_id uuid NOT NULL,

    sales_order_line_id uuid,
    sales_delivery_line_id uuid,

    line_no integer NOT NULL,

    item_id uuid,
    item_code varchar(96),
    item_name varchar(255) NOT NULL,
    category_id uuid,
    unit_code varchar(32) NOT NULL DEFAULT 'ADET',

    quantity numeric(18, 4) NOT NULL DEFAULT 0,
    unit_price numeric(18, 4) NOT NULL DEFAULT 0,
    discount_amount numeric(18, 2) NOT NULL DEFAULT 0,
    tax_rate numeric(9, 4) NOT NULL DEFAULT 0,
    tax_amount numeric(18, 2) NOT NULL DEFAULT 0,
    line_total_amount numeric(18, 2) NOT NULL DEFAULT 0,

    tax_rule_id uuid,
    account_code varchar(32),
    tax_account_code varchar(32),
    account_mapping_rule_id uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT sales_invoice_lines_pk PRIMARY KEY (tenant_id, sales_invoice_line_id),
    CONSTRAINT sales_invoice_lines_invoice_fk FOREIGN KEY (tenant_id, sales_invoice_id)
        REFERENCES erp.sales_invoices (tenant_id, sales_invoice_id)
        ON DELETE CASCADE,
    CONSTRAINT sales_invoice_lines_order_line_fk FOREIGN KEY (tenant_id, sales_order_line_id)
        REFERENCES erp.sales_order_lines (tenant_id, sales_order_line_id)
        ON DELETE SET NULL,
    CONSTRAINT sales_invoice_lines_delivery_line_fk FOREIGN KEY (tenant_id, sales_delivery_line_id)
        REFERENCES erp.sales_delivery_lines (tenant_id, sales_delivery_line_id)
        ON DELETE SET NULL,
    CONSTRAINT sales_invoice_lines_line_unique UNIQUE (tenant_id, sales_invoice_id, line_no),
    CONSTRAINT sales_invoice_lines_qty_chk CHECK (quantity >= 0),
    CONSTRAINT sales_invoice_lines_amount_chk CHECK (
        unit_price >= 0
        AND discount_amount >= 0
        AND tax_rate >= 0
        AND tax_amount >= 0
        AND line_total_amount >= 0
    )
);

CREATE INDEX IF NOT EXISTS sales_quotations_customer_status_idx
    ON erp.sales_quotations (tenant_id, customer_id, status, quotation_date DESC);

CREATE INDEX IF NOT EXISTS sales_quotation_lines_header_idx
    ON erp.sales_quotation_lines (tenant_id, sales_quotation_id, line_no);

CREATE INDEX IF NOT EXISTS sales_quotation_lines_item_idx
    ON erp.sales_quotation_lines (tenant_id, item_id);

CREATE INDEX IF NOT EXISTS sales_orders_customer_status_idx
    ON erp.sales_orders (tenant_id, customer_id, status, order_date DESC);

CREATE INDEX IF NOT EXISTS sales_orders_fulfillment_idx
    ON erp.sales_orders (tenant_id, fulfillment_status, invoice_status, payment_status);

CREATE INDEX IF NOT EXISTS sales_order_lines_header_idx
    ON erp.sales_order_lines (tenant_id, sales_order_id, line_no);

CREATE INDEX IF NOT EXISTS sales_order_lines_item_idx
    ON erp.sales_order_lines (tenant_id, item_id);

CREATE INDEX IF NOT EXISTS sales_deliveries_order_status_idx
    ON erp.sales_deliveries (tenant_id, sales_order_id, status, delivery_date DESC);

CREATE INDEX IF NOT EXISTS sales_deliveries_customer_idx
    ON erp.sales_deliveries (tenant_id, customer_id, delivery_date DESC);

CREATE INDEX IF NOT EXISTS sales_delivery_lines_header_idx
    ON erp.sales_delivery_lines (tenant_id, sales_delivery_id, line_no);

CREATE INDEX IF NOT EXISTS sales_delivery_lines_order_line_idx
    ON erp.sales_delivery_lines (tenant_id, sales_order_line_id);

CREATE INDEX IF NOT EXISTS sales_delivery_lines_inventory_idx
    ON erp.sales_delivery_lines (tenant_id, inventory_movement_id);

CREATE INDEX IF NOT EXISTS sales_invoices_customer_status_idx
    ON erp.sales_invoices (tenant_id, customer_id, status, invoice_date DESC);

CREATE INDEX IF NOT EXISTS sales_invoices_order_delivery_idx
    ON erp.sales_invoices (tenant_id, sales_order_id, sales_delivery_id);

CREATE INDEX IF NOT EXISTS sales_invoices_payment_idx
    ON erp.sales_invoices (tenant_id, payment_status, due_date);

CREATE INDEX IF NOT EXISTS sales_invoice_lines_header_idx
    ON erp.sales_invoice_lines (tenant_id, sales_invoice_id, line_no);

CREATE INDEX IF NOT EXISTS sales_invoice_lines_order_delivery_idx
    ON erp.sales_invoice_lines (tenant_id, sales_order_line_id, sales_delivery_line_id);

CREATE INDEX IF NOT EXISTS sales_invoice_lines_item_idx
    ON erp.sales_invoice_lines (tenant_id, item_id);

ALTER TABLE erp.sales_quotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.sales_quotation_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.sales_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.sales_order_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.sales_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.sales_delivery_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.sales_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.sales_invoice_lines ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp.sales_quotations FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.sales_quotation_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.sales_orders FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.sales_order_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.sales_deliveries FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.sales_delivery_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.sales_invoices FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.sales_invoice_lines FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS sales_quotations_tenant_policy ON erp.sales_quotations;
CREATE POLICY sales_quotations_tenant_policy ON erp.sales_quotations
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS sales_quotation_lines_tenant_policy ON erp.sales_quotation_lines;
CREATE POLICY sales_quotation_lines_tenant_policy ON erp.sales_quotation_lines
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS sales_orders_tenant_policy ON erp.sales_orders;
CREATE POLICY sales_orders_tenant_policy ON erp.sales_orders
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS sales_order_lines_tenant_policy ON erp.sales_order_lines;
CREATE POLICY sales_order_lines_tenant_policy ON erp.sales_order_lines
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS sales_deliveries_tenant_policy ON erp.sales_deliveries;
CREATE POLICY sales_deliveries_tenant_policy ON erp.sales_deliveries
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS sales_delivery_lines_tenant_policy ON erp.sales_delivery_lines;
CREATE POLICY sales_delivery_lines_tenant_policy ON erp.sales_delivery_lines
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS sales_invoices_tenant_policy ON erp.sales_invoices;
CREATE POLICY sales_invoices_tenant_policy ON erp.sales_invoices
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS sales_invoice_lines_tenant_policy ON erp.sales_invoice_lines;
CREATE POLICY sales_invoice_lines_tenant_policy ON erp.sales_invoice_lines
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

COMMENT ON TABLE erp.sales_quotations IS 'FAZ 3-9.4 sales quotation header table';
COMMENT ON TABLE erp.sales_quotation_lines IS 'FAZ 3-9.4 sales quotation line table';
COMMENT ON TABLE erp.sales_orders IS 'FAZ 3-9.4 sales order header table';
COMMENT ON TABLE erp.sales_order_lines IS 'FAZ 3-9.4 sales order line table';
COMMENT ON TABLE erp.sales_deliveries IS 'FAZ 3-9.4 sales delivery header table';
COMMENT ON TABLE erp.sales_delivery_lines IS 'FAZ 3-9.4 sales delivery line table';
COMMENT ON TABLE erp.sales_invoices IS 'FAZ 3-9.4 sales invoice header table';
COMMENT ON TABLE erp.sales_invoice_lines IS 'FAZ 3-9.4 sales invoice line table';

COMMIT;
