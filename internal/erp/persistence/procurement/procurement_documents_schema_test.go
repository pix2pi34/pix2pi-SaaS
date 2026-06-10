package procurement_test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func repoRoot(t *testing.T) string {
	t.Helper()

	dir, err := os.Getwd()
	if err != nil {
		t.Fatalf("get working dir: %v", err)
	}

	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir
		}

		parent := filepath.Dir(dir)
		if parent == dir {
			t.Fatal("repo root not found: go.mod missing")
		}

		dir = parent
	}
}

func readMigration(t *testing.T, name string) string {
	t.Helper()

	path := filepath.Join(repoRoot(t), "db", "migrations", name)

	b, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read migration %s: %v", name, err)
	}

	return string(b)
}

func assertContains(t *testing.T, body string, expected string) {
	t.Helper()

	if !strings.Contains(body, expected) {
		t.Fatalf("migration missing expected SQL fragment:\n%s", expected)
	}
}

func TestProcurementDocumentsMigrationCreatesCoreTables(t *testing.T) {
	sql := readMigration(t, "20260425_095001_erp_procurement_documents.up.sql")

	expectedTables := []string{
		"CREATE TABLE IF NOT EXISTS erp_purchase_orders",
		"CREATE TABLE IF NOT EXISTS erp_purchase_order_lines",
		"CREATE TABLE IF NOT EXISTS erp_purchase_receipts",
		"CREATE TABLE IF NOT EXISTS erp_purchase_receipt_lines",
		"CREATE TABLE IF NOT EXISTS erp_purchase_invoices",
		"CREATE TABLE IF NOT EXISTS erp_purchase_invoice_lines",
	}

	for _, table := range expectedTables {
		assertContains(t, sql, table)
	}
}

func TestProcurementDocumentsMigrationHasTenantAndAuditColumns(t *testing.T) {
	sql := readMigration(t, "20260425_095001_erp_procurement_documents.up.sql")

	expectedColumns := []string{
		"tenant_id TEXT NOT NULL",
		"created_at TIMESTAMPTZ NOT NULL DEFAULT now()",
		"updated_at TIMESTAMPTZ NOT NULL DEFAULT now()",
		"deleted_at TIMESTAMPTZ",
		"created_by TEXT",
		"updated_by TEXT",
	}

	for _, column := range expectedColumns {
		assertContains(t, sql, column)
	}
}

func TestProcurementDocumentsMigrationHasHeaderFields(t *testing.T) {
	sql := readMigration(t, "20260425_095001_erp_procurement_documents.up.sql")

	expectedFields := []string{
		"purchase_order_no TEXT NOT NULL",
		"purchase_receipt_no TEXT NOT NULL",
		"purchase_invoice_no TEXT NOT NULL",
		"vendor_invoice_no TEXT",
		"vendor_id UUID NOT NULL REFERENCES erp_vendors",
		"party_id UUID NOT NULL REFERENCES erp_parties",
		"warehouse_id UUID NOT NULL REFERENCES erp_warehouses",
		"document_date DATE NOT NULL DEFAULT CURRENT_DATE",
		"currency_code TEXT NOT NULL DEFAULT 'TRY'",
		"exchange_rate NUMERIC(18, 6) NOT NULL DEFAULT 1",
		"subtotal_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"vat_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"total_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"e_document_status TEXT NOT NULL DEFAULT 'none'",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestProcurementDocumentsMigrationHasLineFields(t *testing.T) {
	sql := readMigration(t, "20260425_095001_erp_procurement_documents.up.sql")

	expectedFields := []string{
		"line_no INTEGER NOT NULL",
		"item_id UUID NOT NULL REFERENCES erp_items",
		"product_id UUID REFERENCES erp_products",
		"unit_id UUID NOT NULL REFERENCES erp_units",
		"quantity NUMERIC(18, 6) NOT NULL",
		"received_quantity NUMERIC(18, 6) NOT NULL DEFAULT 0",
		"invoiced_quantity NUMERIC(18, 6) NOT NULL DEFAULT 0",
		"unit_cost NUMERIC(18, 6) NOT NULL DEFAULT 0",
		"discount_rate NUMERIC(5, 2) NOT NULL DEFAULT 0",
		"discount_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"vat_rate NUMERIC(5, 2) NOT NULL DEFAULT 20.00",
		"vat_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"line_total NUMERIC(18, 2) NOT NULL DEFAULT 0",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestProcurementDocumentsMigrationHasTenantIndexes(t *testing.T) {
	sql := readMigration(t, "20260425_095001_erp_procurement_documents.up.sql")

	expectedIndexes := []string{
		"ux_erp_purchase_orders_tenant_no",
		"ux_erp_purchase_order_lines_tenant_doc_line",
		"ux_erp_purchase_receipts_tenant_no",
		"ux_erp_purchase_receipt_lines_tenant_doc_line",
		"ux_erp_purchase_invoices_tenant_no",
		"ux_erp_purchase_invoice_lines_tenant_doc_line",
		"ix_erp_purchase_orders_tenant_vendor",
		"ix_erp_purchase_receipts_tenant_warehouse",
		"ix_erp_purchase_invoices_tenant_vendor_invoice_no",
		"ix_erp_purchase_invoices_tenant_document_date",
	}

	for _, index := range expectedIndexes {
		assertContains(t, sql, index)
	}
}

func TestProcurementDocumentsMigrationEnablesForcedRLS(t *testing.T) {
	sql := readMigration(t, "20260425_095001_erp_procurement_documents.up.sql")

	expectedRLS := []string{
		"ALTER TABLE erp_purchase_orders ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_purchase_order_lines ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_purchase_receipts ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_purchase_receipt_lines ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_purchase_invoices ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_purchase_invoice_lines ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_purchase_orders FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_purchase_order_lines FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_purchase_receipts FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_purchase_receipt_lines FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_purchase_invoices FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_purchase_invoice_lines FORCE ROW LEVEL SECURITY",
	}

	for _, rls := range expectedRLS {
		assertContains(t, sql, rls)
	}
}

func TestProcurementDocumentsMigrationHasTenantIsolationPolicies(t *testing.T) {
	sql := readMigration(t, "20260425_095001_erp_procurement_documents.up.sql")

	expectedPolicies := []string{
		"erp_purchase_orders_tenant_isolation_policy",
		"erp_purchase_order_lines_tenant_isolation_policy",
		"erp_purchase_receipts_tenant_isolation_policy",
		"erp_purchase_receipt_lines_tenant_isolation_policy",
		"erp_purchase_invoices_tenant_isolation_policy",
		"erp_purchase_invoice_lines_tenant_isolation_policy",
		"tenant_id = current_setting('app.tenant_id', true)",
	}

	for _, policy := range expectedPolicies {
		assertContains(t, sql, policy)
	}
}

func TestProcurementDocumentsRollbackDropsTablesInSafeOrder(t *testing.T) {
	sql := readMigration(t, "20260425_095001_erp_procurement_documents.down.sql")

	expectedDrops := []string{
		"DROP TABLE IF EXISTS erp_purchase_invoice_lines",
		"DROP TABLE IF EXISTS erp_purchase_invoices",
		"DROP TABLE IF EXISTS erp_purchase_receipt_lines",
		"DROP TABLE IF EXISTS erp_purchase_receipts",
		"DROP TABLE IF EXISTS erp_purchase_order_lines",
		"DROP TABLE IF EXISTS erp_purchase_orders",
	}

	for _, drop := range expectedDrops {
		assertContains(t, sql, drop)
	}
}
