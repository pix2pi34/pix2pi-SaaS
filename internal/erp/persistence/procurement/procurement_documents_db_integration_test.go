package procurement_test

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

func procurementIntegrationDSN(t *testing.T) string {
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

func procurementPSQL(t *testing.T, dsn string, sql string) string {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("psql failed\nsql:\n%s\nerror: %v\noutput:\n%s", sql, err, string(out))
	}

	return strings.TrimSpace(string(out))
}

func procurementPSQLMustFail(t *testing.T, dsn string, sql string) {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err == nil {
		t.Fatalf("expected psql failure but command succeeded\nsql:\n%s\noutput:\n%s", sql, string(out))
	}
}

func procurementSQLQuote(value string) string {
	return "'" + strings.ReplaceAll(value, "'", "''") + "'"
}

func TestProcurementDocumentsDBTablesExist(t *testing.T) {
	dsn := procurementIntegrationDSN(t)

	got := procurementPSQL(t, dsn, `
SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'erp_purchase_orders',
    'erp_purchase_order_lines',
    'erp_purchase_receipts',
    'erp_purchase_receipt_lines',
    'erp_purchase_invoices',
    'erp_purchase_invoice_lines'
  );
`)

	if got != "6" {
		t.Fatalf("expected 6 procurement document tables, got %s", got)
	}
}

func TestProcurementDocumentsDBIndexesExist(t *testing.T) {
	dsn := procurementIntegrationDSN(t)

	got := procurementPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'ux_erp_purchase_orders_tenant_no',
    'ix_erp_purchase_orders_tenant_vendor',
    'ix_erp_purchase_orders_tenant_party',
    'ix_erp_purchase_orders_tenant_status',
    'ix_erp_purchase_orders_tenant_document_date',

    'ux_erp_purchase_order_lines_tenant_doc_line',
    'ix_erp_purchase_order_lines_tenant_item',
    'ix_erp_purchase_order_lines_tenant_product',

    'ux_erp_purchase_receipts_tenant_no',
    'ix_erp_purchase_receipts_tenant_order',
    'ix_erp_purchase_receipts_tenant_vendor',
    'ix_erp_purchase_receipts_tenant_warehouse',
    'ix_erp_purchase_receipts_tenant_status',
    'ix_erp_purchase_receipts_tenant_document_date',

    'ux_erp_purchase_receipt_lines_tenant_doc_line',
    'ix_erp_purchase_receipt_lines_tenant_item',
    'ix_erp_purchase_receipt_lines_tenant_product',
    'ix_erp_purchase_receipt_lines_tenant_order_line',

    'ux_erp_purchase_invoices_tenant_no',
    'ix_erp_purchase_invoices_tenant_vendor_invoice_no',
    'ix_erp_purchase_invoices_tenant_order',
    'ix_erp_purchase_invoices_tenant_receipt',
    'ix_erp_purchase_invoices_tenant_vendor',
    'ix_erp_purchase_invoices_tenant_status',
    'ix_erp_purchase_invoices_tenant_document_date',

    'ux_erp_purchase_invoice_lines_tenant_doc_line',
    'ix_erp_purchase_invoice_lines_tenant_item',
    'ix_erp_purchase_invoice_lines_tenant_product',
    'ix_erp_purchase_invoice_lines_tenant_order_line',
    'ix_erp_purchase_invoice_lines_tenant_receipt_line'
  );
`)

	if got != "30" {
		t.Fatalf("expected 30 procurement document indexes, got %s", got)
	}
}

func TestProcurementDocumentsDBRLSEnabledAndForced(t *testing.T) {
	dsn := procurementIntegrationDSN(t)

	got := procurementPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN (
    'erp_purchase_orders',
    'erp_purchase_order_lines',
    'erp_purchase_receipts',
    'erp_purchase_receipt_lines',
    'erp_purchase_invoices',
    'erp_purchase_invoice_lines'
  )
  AND c.relrowsecurity = true
  AND c.relforcerowsecurity = true;
`)

	if got != "6" {
		t.Fatalf("expected RLS enabled and forced on 6 procurement document tables, got %s", got)
	}
}

func TestProcurementDocumentsDBTenantPoliciesExist(t *testing.T) {
	dsn := procurementIntegrationDSN(t)

	got := procurementPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_policy p
JOIN pg_class c ON c.oid = p.polrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND p.polname IN (
    'erp_purchase_orders_tenant_isolation_policy',
    'erp_purchase_order_lines_tenant_isolation_policy',
    'erp_purchase_receipts_tenant_isolation_policy',
    'erp_purchase_receipt_lines_tenant_isolation_policy',
    'erp_purchase_invoices_tenant_isolation_policy',
    'erp_purchase_invoice_lines_tenant_isolation_policy'
  );
`)

	if got != "6" {
		t.Fatalf("expected 6 tenant isolation policies, got %s", got)
	}
}

func TestProcurementDocumentsDBTenantIsolationWorks(t *testing.T) {
	dsn := procurementIntegrationDSN(t)

	isSuperUser := procurementPSQL(t, dsn, `
SELECT rolsuper
FROM pg_roles
WHERE rolname = current_user;
`)

	if isSuperUser == "t" {
		t.Skip("current DB user is superuser; PostgreSQL superuser bypasses RLS behavior checks")
	}

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	partyID := procurementPSQL(t, dsn, fmt.Sprintf(`
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
    'Procurement Test Tedarikci %s',
    'Procurement Test Tedarikci Ltd %s',
    'PRC%s',
    'Kadikoy',
    '05000000000',
    'procurement_%s@example.com',
    'integration_test',
    'faz3_procurement_test'
)
RETURNING party_id;
`, unique, unique, unique, unique))

	vendorID := createProcurementVendor(t, dsn, "tenant_7", partyID, unique)

	unitID := procurementPSQL(t, dsn, fmt.Sprintf(`
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
    'PRC-UNIT-%s',
    'Procurement Unit Test %s',
    'quantity',
    0,
    true,
    'faz3_procurement_test'
)
RETURNING unit_id;
`, unique, unique))

	itemID := procurementPSQL(t, dsn, fmt.Sprintf(`
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
    'PRC-ITEM-%s',
    'Procurement Item Test %s',
    'stock',
    '%s',
    'PRC-BAR-%s',
    'PRC-SKU-%s',
    20.00,
    true,
    true,
    true,
    'faz3_procurement_test'
)
RETURNING item_id;
`, unique, unique, unitID, unique, unique))

	warehouseID := procurementPSQL(t, dsn, fmt.Sprintf(`
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
    'PRC-WH-%s',
    'Procurement Warehouse Test %s',
    'main',
    'Istanbul',
    'Kadikoy',
    false,
    'faz3_procurement_test'
)
RETURNING warehouse_id;
`, unique, unique))

	purchaseOrderID := procurementPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_purchase_orders (
    tenant_id,
    purchase_order_no,
    vendor_id,
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
    'PRC-PO-%s',
    '%s',
    '%s',
    CURRENT_DATE,
    100.00,
    20.00,
    120.00,
    'draft',
    'faz3_procurement_test'
)
RETURNING purchase_order_id;
`, unique, vendorID, partyID))

	purchaseOrderLineID := procurementPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_purchase_order_lines (
    tenant_id,
    purchase_order_id,
    line_no,
    item_id,
    unit_id,
    description,
    quantity,
    unit_cost,
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
    'Procurement order line test %s',
    1.000000,
    100.000000,
    20.00,
    20.00,
    120.00,
    'faz3_procurement_test'
)
RETURNING purchase_order_line_id;
`, purchaseOrderID, itemID, unitID, unique))

	purchaseReceiptID := procurementPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_purchase_receipts (
    tenant_id,
    purchase_receipt_no,
    purchase_order_id,
    vendor_id,
    party_id,
    warehouse_id,
    document_date,
    receipt_date,
    status,
    created_by
)
VALUES (
    'tenant_7',
    'PRC-RCPT-%s',
    '%s',
    '%s',
    '%s',
    '%s',
    CURRENT_DATE,
    CURRENT_DATE,
    'draft',
    'faz3_procurement_test'
)
RETURNING purchase_receipt_id;
`, unique, purchaseOrderID, vendorID, partyID, warehouseID))

	purchaseReceiptLineID := procurementPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_purchase_receipt_lines (
    tenant_id,
    purchase_receipt_id,
    purchase_order_line_id,
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
    'Procurement receipt line test %s',
    1.000000,
    'faz3_procurement_test'
)
RETURNING purchase_receipt_line_id;
`, purchaseReceiptID, purchaseOrderLineID, itemID, unitID, unique))

	purchaseInvoiceID := procurementPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_purchase_invoices (
    tenant_id,
    purchase_invoice_no,
    vendor_invoice_no,
    purchase_order_id,
    purchase_receipt_id,
    vendor_id,
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
    'PRC-INV-%s',
    'VENDOR-INV-%s',
    '%s',
    '%s',
    '%s',
    '%s',
    'purchase',
    CURRENT_DATE,
    CURRENT_DATE,
    100.00,
    20.00,
    120.00,
    0.00,
    120.00,
    'none',
    'draft',
    'faz3_procurement_test'
)
RETURNING purchase_invoice_id;
`, unique, unique, purchaseOrderID, purchaseReceiptID, vendorID, partyID))

	purchaseInvoiceLineID := procurementPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_purchase_invoice_lines (
    tenant_id,
    purchase_invoice_id,
    purchase_order_line_id,
    purchase_receipt_line_id,
    line_no,
    item_id,
    unit_id,
    description,
    quantity,
    unit_cost,
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
    'Procurement invoice line test %s',
    1.000000,
    100.000000,
    20.00,
    20.00,
    120.00,
    'faz3_procurement_test'
)
RETURNING purchase_invoice_line_id;
`, purchaseInvoiceID, purchaseOrderLineID, purchaseReceiptLineID, itemID, unitID, unique))

	defer func() {
		cleanupSQL := fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

DELETE FROM erp_purchase_invoice_lines WHERE purchase_invoice_line_id = '%s';
DELETE FROM erp_purchase_invoices WHERE purchase_invoice_id = '%s';

DELETE FROM erp_purchase_receipt_lines WHERE purchase_receipt_line_id = '%s';
DELETE FROM erp_purchase_receipts WHERE purchase_receipt_id = '%s';

DELETE FROM erp_purchase_order_lines WHERE purchase_order_line_id = '%s';
DELETE FROM erp_purchase_orders WHERE purchase_order_id = '%s';

DELETE FROM erp_warehouses WHERE warehouse_id = '%s';
DELETE FROM erp_items WHERE item_id = '%s';
DELETE FROM erp_units WHERE unit_id = '%s';

DELETE FROM erp_vendors WHERE vendor_id = '%s';
DELETE FROM erp_parties WHERE party_id = '%s';
`, purchaseInvoiceLineID, purchaseInvoiceID, purchaseReceiptLineID, purchaseReceiptID, purchaseOrderLineID, purchaseOrderID, warehouseID, itemID, unitID, vendorID, partyID)

		_ = exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", cleanupSQL).Run()
	}()

	visibleForTenant7 := procurementPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_purchase_invoices
WHERE purchase_invoice_id = '%s';
`, purchaseInvoiceID))

	if visibleForTenant7 != "1" {
		t.Fatalf("expected tenant_7 to see inserted purchase invoice, got %s", visibleForTenant7)
	}

	visibleForTenant99 := procurementPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_99';
SELECT COUNT(*)
FROM erp_purchase_invoices
WHERE purchase_invoice_id = '%s';
`, purchaseInvoiceID))

	if visibleForTenant99 != "0" {
		t.Fatalf("expected tenant_99 not to see tenant_7 purchase invoice, got %s", visibleForTenant99)
	}

	procurementPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_purchase_orders (
    tenant_id,
    purchase_order_no,
    vendor_id,
    party_id,
    document_date,
    status
)
VALUES (
    'tenant_99',
    'BAD-PO-%s',
    '%s',
    '%s',
    CURRENT_DATE,
    'draft'
);
`, unique, vendorID, partyID))
}

func createProcurementVendor(t *testing.T, dsn string, tenantID string, partyID string, unique string) string {
	t.Helper()

	columnRows := procurementPSQL(t, dsn, `
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'erp_vendors'
ORDER BY ordinal_position;
`)

	columnSet := map[string]bool{}
	for _, col := range strings.Split(columnRows, "\n") {
		col = strings.TrimSpace(col)
		if col != "" {
			columnSet[col] = true
		}
	}

	columns := []string{"tenant_id", "party_id"}
	values := []string{procurementSQLQuote(tenantID), procurementSQLQuote(partyID)}

	add := func(column string, value string) {
		if columnSet[column] {
			columns = append(columns, column)
			values = append(values, value)
		}
	}

	add("vendor_code", procurementSQLQuote("PRC-VEND-"+unique))
	add("vendor_name", procurementSQLQuote("Procurement Vendor "+unique))
	add("currency_code", procurementSQLQuote("TRY"))
	add("payment_term_days", "0")
	add("is_credit_allowed", "true")
	add("is_purchase_allowed", "true")
	add("vendor_type", procurementSQLQuote("supplier"))
	add("status", procurementSQLQuote("active"))
	add("source", procurementSQLQuote("integration_test"))
	add("created_by", procurementSQLQuote("faz3_procurement_test"))

	sql := fmt.Sprintf(`
SET app.tenant_id = %s;

INSERT INTO erp_vendors (
    %s
)
VALUES (
    %s
)
RETURNING vendor_id;
`, procurementSQLQuote(tenantID), strings.Join(columns, ",\n    "), strings.Join(values, ",\n    "))

	return procurementPSQL(t, dsn, sql)
}
