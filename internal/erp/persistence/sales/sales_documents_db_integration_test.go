package sales_test

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

func salesIntegrationDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping DB integration test")
	}

	return dsn
}

func salesPSQL(t *testing.T, dsn string, sql string) string {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("psql failed\nsql:\n%s\nerror: %v\noutput:\n%s", sql, err, string(out))
	}

	return strings.TrimSpace(string(out))
}

func salesPSQLMustFail(t *testing.T, dsn string, sql string) {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err == nil {
		t.Fatalf("expected psql failure but command succeeded\nsql:\n%s\noutput:\n%s", sql, string(out))
	}
}

func TestSalesDocumentsDBTablesExist(t *testing.T) {
	dsn := salesIntegrationDSN(t)

	got := salesPSQL(t, dsn, `
SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'erp_sales_quotations',
    'erp_sales_quotation_lines',
    'erp_sales_orders',
    'erp_sales_order_lines',
    'erp_sales_deliveries',
    'erp_sales_delivery_lines',
    'erp_sales_invoices',
    'erp_sales_invoice_lines'
  );
`)

	if got != "8" {
		t.Fatalf("expected 8 sales document tables, got %s", got)
	}
}

func TestSalesDocumentsDBIndexesExist(t *testing.T) {
	dsn := salesIntegrationDSN(t)

	got := salesPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'ux_erp_sales_quotations_tenant_no',
    'ix_erp_sales_quotations_tenant_customer',
    'ix_erp_sales_quotations_tenant_party',
    'ix_erp_sales_quotations_tenant_status',
    'ix_erp_sales_quotations_tenant_document_date',

    'ux_erp_sales_quotation_lines_tenant_doc_line',
    'ix_erp_sales_quotation_lines_tenant_item',
    'ix_erp_sales_quotation_lines_tenant_product',

    'ux_erp_sales_orders_tenant_no',
    'ix_erp_sales_orders_tenant_customer',
    'ix_erp_sales_orders_tenant_party',
    'ix_erp_sales_orders_tenant_status',
    'ix_erp_sales_orders_tenant_document_date',
    'ix_erp_sales_orders_tenant_quotation',

    'ux_erp_sales_order_lines_tenant_doc_line',
    'ix_erp_sales_order_lines_tenant_item',
    'ix_erp_sales_order_lines_tenant_product',
    'ix_erp_sales_order_lines_tenant_quotation_line',

    'ux_erp_sales_deliveries_tenant_no',
    'ix_erp_sales_deliveries_tenant_order',
    'ix_erp_sales_deliveries_tenant_customer',
    'ix_erp_sales_deliveries_tenant_warehouse',
    'ix_erp_sales_deliveries_tenant_status',
    'ix_erp_sales_deliveries_tenant_document_date',

    'ux_erp_sales_delivery_lines_tenant_doc_line',
    'ix_erp_sales_delivery_lines_tenant_item',
    'ix_erp_sales_delivery_lines_tenant_product',
    'ix_erp_sales_delivery_lines_tenant_order_line',

    'ux_erp_sales_invoices_tenant_no',
    'ix_erp_sales_invoices_tenant_order',
    'ix_erp_sales_invoices_tenant_delivery',
    'ix_erp_sales_invoices_tenant_customer',
    'ix_erp_sales_invoices_tenant_status',
    'ix_erp_sales_invoices_tenant_document_date',

    'ux_erp_sales_invoice_lines_tenant_doc_line',
    'ix_erp_sales_invoice_lines_tenant_item',
    'ix_erp_sales_invoice_lines_tenant_product',
    'ix_erp_sales_invoice_lines_tenant_order_line',
    'ix_erp_sales_invoice_lines_tenant_delivery_line'
  );
`)

	if got != "39" {
		t.Fatalf("expected 39 sales document indexes, got %s", got)
	}
}

func TestSalesDocumentsDBRLSEnabledAndForced(t *testing.T) {
	dsn := salesIntegrationDSN(t)

	got := salesPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN (
    'erp_sales_quotations',
    'erp_sales_quotation_lines',
    'erp_sales_orders',
    'erp_sales_order_lines',
    'erp_sales_deliveries',
    'erp_sales_delivery_lines',
    'erp_sales_invoices',
    'erp_sales_invoice_lines'
  )
  AND c.relrowsecurity = true
  AND c.relforcerowsecurity = true;
`)

	if got != "8" {
		t.Fatalf("expected RLS enabled and forced on 8 sales document tables, got %s", got)
	}
}

func TestSalesDocumentsDBTenantPoliciesExist(t *testing.T) {
	dsn := salesIntegrationDSN(t)

	got := salesPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_policy p
JOIN pg_class c ON c.oid = p.polrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND p.polname IN (
    'erp_sales_quotations_tenant_isolation_policy',
    'erp_sales_quotation_lines_tenant_isolation_policy',
    'erp_sales_orders_tenant_isolation_policy',
    'erp_sales_order_lines_tenant_isolation_policy',
    'erp_sales_deliveries_tenant_isolation_policy',
    'erp_sales_delivery_lines_tenant_isolation_policy',
    'erp_sales_invoices_tenant_isolation_policy',
    'erp_sales_invoice_lines_tenant_isolation_policy'
  );
`)

	if got != "8" {
		t.Fatalf("expected 8 tenant isolation policies, got %s", got)
	}
}

func TestSalesDocumentsDBTenantIsolationWorks(t *testing.T) {
	dsn := salesIntegrationDSN(t)

	isSuperUser := salesPSQL(t, dsn, `
SELECT rolsuper
FROM pg_roles
WHERE rolname = current_user;
`)

	if isSuperUser == "t" {
		t.Skip("current DB user is superuser; PostgreSQL superuser bypasses RLS behavior checks")
	}

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	partyID := salesPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_parties (
    tenant_id,
    party_type,
    display_name,
    legal_name,
    tax_no,
    tax_office,
    phone,
    email,
    source,
    created_by
)
VALUES (
    'tenant_7',
    'organization',
    'Sales Test Musteri %s',
    'Sales Test Musteri Ltd %s',
    'SLS%s',
    'Kadikoy',
    '05000000000',
    'sales_%s@example.com',
    'integration_test',
    'faz3_sales_test'
)
RETURNING party_id;
`, unique, unique, unique, unique))

	customerID := salesPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_customers (
    tenant_id,
    party_id,
    customer_code,
    currency_code,
    is_credit_allowed,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    'SLS-CUST-%s',
    'TRY',
    true,
    'active',
    'faz3_sales_test'
)
RETURNING customer_id;
`, partyID, unique))

	unitID := salesPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_units (
    tenant_id,
    unit_code,
    unit_name,
    unit_type,
    decimal_precision,
    is_base_unit,
    created_by
)
VALUES (
    'tenant_7',
    'SLS-UNIT-%s',
    'Sales Unit Test %s',
    'quantity',
    0,
    true,
    'faz3_sales_test'
)
RETURNING unit_id;
`, unique, unique))

	itemID := salesPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_items (
    tenant_id,
    item_code,
    item_name,
    item_type,
    base_unit_id,
    barcode,
    sku,
    vat_rate,
    is_inventory_tracked,
    is_sales_allowed,
    is_purchase_allowed,
    created_by
)
VALUES (
    'tenant_7',
    'SLS-ITEM-%s',
    'Sales Item Test %s',
    'stock',
    '%s',
    'SLS-BAR-%s',
    'SLS-SKU-%s',
    20.00,
    true,
    true,
    true,
    'faz3_sales_test'
)
RETURNING item_id;
`, unique, unique, unitID, unique, unique))

	warehouseID := salesPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_warehouses (
    tenant_id,
    warehouse_code,
    warehouse_name,
    warehouse_type,
    city,
    district,
    is_default,
    created_by
)
VALUES (
    'tenant_7',
    'SLS-WH-%s',
    'Sales Warehouse Test %s',
    'main',
    'Istanbul',
    'Kadikoy',
    false,
    'faz3_sales_test'
)
RETURNING warehouse_id;
`, unique, unique))

	quotationID := salesPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_sales_quotations (
    tenant_id,
    quotation_no,
    customer_id,
    party_id,
    document_date,
    subtotal_amount,
    vat_amount,
    total_amount,
    status,
    created_by
)
VALUES (
    'tenant_7',
    'SLS-QT-%s',
    '%s',
    '%s',
    CURRENT_DATE,
    100.00,
    20.00,
    120.00,
    'draft',
    'faz3_sales_test'
)
RETURNING quotation_id;
`, unique, customerID, partyID))

	quotationLineID := salesPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_sales_quotation_lines (
    tenant_id,
    quotation_id,
    line_no,
    item_id,
    unit_id,
    description,
    quantity,
    unit_price,
    vat_rate,
    vat_amount,
    line_total,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    1,
    '%s',
    '%s',
    'Sales quotation line test %s',
    1.000000,
    100.000000,
    20.00,
    20.00,
    120.00,
    'faz3_sales_test'
)
RETURNING quotation_line_id;
`, quotationID, itemID, unitID, unique))

	orderID := salesPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_sales_orders (
    tenant_id,
    sales_order_no,
    quotation_id,
    customer_id,
    party_id,
    document_date,
    subtotal_amount,
    vat_amount,
    total_amount,
    status,
    created_by
)
VALUES (
    'tenant_7',
    'SLS-ORD-%s',
    '%s',
    '%s',
    '%s',
    CURRENT_DATE,
    100.00,
    20.00,
    120.00,
    'draft',
    'faz3_sales_test'
)
RETURNING sales_order_id;
`, unique, quotationID, customerID, partyID))

	orderLineID := salesPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_sales_order_lines (
    tenant_id,
    sales_order_id,
    quotation_line_id,
    line_no,
    item_id,
    unit_id,
    description,
    quantity,
    unit_price,
    vat_rate,
    vat_amount,
    line_total,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    '%s',
    1,
    '%s',
    '%s',
    'Sales order line test %s',
    1.000000,
    100.000000,
    20.00,
    20.00,
    120.00,
    'faz3_sales_test'
)
RETURNING sales_order_line_id;
`, orderID, quotationLineID, itemID, unitID, unique))

	deliveryID := salesPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_sales_deliveries (
    tenant_id,
    delivery_no,
    sales_order_id,
    customer_id,
    party_id,
    warehouse_id,
    document_date,
    delivery_date,
    status,
    created_by
)
VALUES (
    'tenant_7',
    'SLS-DEL-%s',
    '%s',
    '%s',
    '%s',
    '%s',
    CURRENT_DATE,
    CURRENT_DATE,
    'draft',
    'faz3_sales_test'
)
RETURNING delivery_id;
`, unique, orderID, customerID, partyID, warehouseID))

	deliveryLineID := salesPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_sales_delivery_lines (
    tenant_id,
    delivery_id,
    sales_order_line_id,
    line_no,
    item_id,
    unit_id,
    description,
    quantity,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    '%s',
    1,
    '%s',
    '%s',
    'Sales delivery line test %s',
    1.000000,
    'faz3_sales_test'
)
RETURNING delivery_line_id;
`, deliveryID, orderLineID, itemID, unitID, unique))

	invoiceID := salesPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_sales_invoices (
    tenant_id,
    sales_invoice_no,
    sales_order_id,
    delivery_id,
    customer_id,
    party_id,
    invoice_type,
    document_date,
    due_date,
    subtotal_amount,
    vat_amount,
    total_amount,
    paid_amount,
    remaining_amount,
    e_document_status,
    status,
    created_by
)
VALUES (
    'tenant_7',
    'SLS-INV-%s',
    '%s',
    '%s',
    '%s',
    '%s',
    'sales',
    CURRENT_DATE,
    CURRENT_DATE,
    100.00,
    20.00,
    120.00,
    0.00,
    120.00,
    'none',
    'draft',
    'faz3_sales_test'
)
RETURNING sales_invoice_id;
`, unique, orderID, deliveryID, customerID, partyID))

	invoiceLineID := salesPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_sales_invoice_lines (
    tenant_id,
    sales_invoice_id,
    sales_order_line_id,
    delivery_line_id,
    line_no,
    item_id,
    unit_id,
    description,
    quantity,
    unit_price,
    vat_rate,
    vat_amount,
    line_total,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    '%s',
    '%s',
    1,
    '%s',
    '%s',
    'Sales invoice line test %s',
    1.000000,
    100.000000,
    20.00,
    20.00,
    120.00,
    'faz3_sales_test'
)
RETURNING sales_invoice_line_id;
`, invoiceID, orderLineID, deliveryLineID, itemID, unitID, unique))

	defer func() {
		cleanupSQL := fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

DELETE FROM erp_sales_invoice_lines WHERE sales_invoice_line_id = '%s';
DELETE FROM erp_sales_invoices WHERE sales_invoice_id = '%s';

DELETE FROM erp_sales_delivery_lines WHERE delivery_line_id = '%s';
DELETE FROM erp_sales_deliveries WHERE delivery_id = '%s';

DELETE FROM erp_sales_order_lines WHERE sales_order_line_id = '%s';
DELETE FROM erp_sales_orders WHERE sales_order_id = '%s';

DELETE FROM erp_sales_quotation_lines WHERE quotation_line_id = '%s';
DELETE FROM erp_sales_quotations WHERE quotation_id = '%s';

DELETE FROM erp_warehouses WHERE warehouse_id = '%s';
DELETE FROM erp_items WHERE item_id = '%s';
DELETE FROM erp_units WHERE unit_id = '%s';

DELETE FROM erp_customers WHERE customer_id = '%s';
DELETE FROM erp_parties WHERE party_id = '%s';
`, invoiceLineID, invoiceID, deliveryLineID, deliveryID, orderLineID, orderID, quotationLineID, quotationID, warehouseID, itemID, unitID, customerID, partyID)

		_ = exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", cleanupSQL).Run()
	}()

	visibleForTenant7 := salesPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_sales_invoices
WHERE sales_invoice_id = '%s';
`, invoiceID))

	if visibleForTenant7 != "1" {
		t.Fatalf("expected tenant_7 to see inserted sales invoice, got %s", visibleForTenant7)
	}

	visibleForTenant99 := salesPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_99';
SELECT COUNT(*)
FROM erp_sales_invoices
WHERE sales_invoice_id = '%s';
`, invoiceID))

	if visibleForTenant99 != "0" {
		t.Fatalf("expected tenant_99 not to see tenant_7 sales invoice, got %s", visibleForTenant99)
	}

	salesPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_sales_quotations (
    tenant_id,
    quotation_no,
    customer_id,
    party_id,
    document_date,
    status
)
VALUES (
    'tenant_99',
    'BAD-QT-%s',
    '%s',
    '%s',
    CURRENT_DATE,
    'draft'
);
`, unique, customerID, partyID))
}
