package productcatalog_test

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

func TestProductCatalogMigrationCreatesCoreTables(t *testing.T) {
	sql := readMigration(t, "20260425_092001_erp_product_catalog.up.sql")

	expectedTables := []string{
		"CREATE TABLE IF NOT EXISTS erp_units",
		"CREATE TABLE IF NOT EXISTS erp_product_categories",
		"CREATE TABLE IF NOT EXISTS erp_items",
		"CREATE TABLE IF NOT EXISTS erp_products",
	}

	for _, table := range expectedTables {
		assertContains(t, sql, table)
	}
}

func TestProductCatalogMigrationHasTenantAndAuditColumns(t *testing.T) {
	sql := readMigration(t, "20260425_092001_erp_product_catalog.up.sql")

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

func TestProductCatalogMigrationHasERPProductFields(t *testing.T) {
	sql := readMigration(t, "20260425_092001_erp_product_catalog.up.sql")

	expectedFields := []string{
		"unit_code TEXT NOT NULL",
		"category_code TEXT NOT NULL",
		"item_code TEXT NOT NULL",
		"item_type TEXT NOT NULL DEFAULT 'stock'",
		"barcode TEXT",
		"vat_rate NUMERIC(5, 2) NOT NULL DEFAULT 20.00",
		"is_inventory_tracked BOOLEAN NOT NULL DEFAULT true",
		"product_code TEXT NOT NULL",
		"is_visible_pos BOOLEAN NOT NULL DEFAULT true",
		"is_visible_web BOOLEAN NOT NULL DEFAULT false",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestProductCatalogMigrationHasTenantIndexes(t *testing.T) {
	sql := readMigration(t, "20260425_092001_erp_product_catalog.up.sql")

	expectedIndexes := []string{
		"ux_erp_units_tenant_code",
		"ux_erp_product_categories_tenant_code",
		"ix_erp_product_categories_tenant_parent",
		"ux_erp_items_tenant_code",
		"ux_erp_items_tenant_barcode",
		"ix_erp_items_tenant_category",
		"ux_erp_products_tenant_code",
		"ux_erp_products_tenant_item",
	}

	for _, index := range expectedIndexes {
		assertContains(t, sql, index)
	}
}

func TestProductCatalogMigrationEnablesForcedRLS(t *testing.T) {
	sql := readMigration(t, "20260425_092001_erp_product_catalog.up.sql")

	expectedRLS := []string{
		"ALTER TABLE erp_units ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_product_categories ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_items ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_products ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_units FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_product_categories FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_items FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_products FORCE ROW LEVEL SECURITY",
	}

	for _, rls := range expectedRLS {
		assertContains(t, sql, rls)
	}
}

func TestProductCatalogMigrationHasTenantIsolationPolicies(t *testing.T) {
	sql := readMigration(t, "20260425_092001_erp_product_catalog.up.sql")

	expectedPolicies := []string{
		"erp_units_tenant_isolation_policy",
		"erp_product_categories_tenant_isolation_policy",
		"erp_items_tenant_isolation_policy",
		"erp_products_tenant_isolation_policy",
		"tenant_id = current_setting('app.tenant_id', true)",
	}

	for _, policy := range expectedPolicies {
		assertContains(t, sql, policy)
	}
}

func TestProductCatalogRollbackDropsTablesInSafeOrder(t *testing.T) {
	sql := readMigration(t, "20260425_092001_erp_product_catalog.down.sql")

	expectedDrops := []string{
		"DROP TABLE IF EXISTS erp_products",
		"DROP TABLE IF EXISTS erp_items",
		"DROP TABLE IF EXISTS erp_product_categories",
		"DROP TABLE IF EXISTS erp_units",
	}

	for _, drop := range expectedDrops {
		assertContains(t, sql, drop)
	}
}
