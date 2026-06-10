package inventory_test

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

func TestInventoryMigrationCreatesCoreTables(t *testing.T) {
	sql := readMigration(t, "20260425_093001_erp_inventory.up.sql")

	expectedTables := []string{
		"CREATE TABLE IF NOT EXISTS erp_warehouses",
		"CREATE TABLE IF NOT EXISTS erp_stock_movements",
		"CREATE TABLE IF NOT EXISTS erp_warehouse_balances",
	}

	for _, table := range expectedTables {
		assertContains(t, sql, table)
	}
}

func TestInventoryMigrationHasTenantAndAuditColumns(t *testing.T) {
	sql := readMigration(t, "20260425_093001_erp_inventory.up.sql")

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

func TestInventoryMigrationHasWarehouseAndStockFields(t *testing.T) {
	sql := readMigration(t, "20260425_093001_erp_inventory.up.sql")

	expectedFields := []string{
		"warehouse_code TEXT NOT NULL",
		"warehouse_name TEXT NOT NULL",
		"movement_no TEXT NOT NULL",
		"movement_type TEXT NOT NULL",
		"movement_direction TEXT NOT NULL",
		"warehouse_id UUID NOT NULL REFERENCES erp_warehouses",
		"item_id UUID NOT NULL REFERENCES erp_items",
		"unit_id UUID NOT NULL REFERENCES erp_units",
		"quantity NUMERIC(18, 6) NOT NULL",
		"on_hand_quantity NUMERIC(18, 6) NOT NULL DEFAULT 0",
		"reserved_quantity NUMERIC(18, 6) NOT NULL DEFAULT 0",
		"available_quantity NUMERIC(18, 6) NOT NULL DEFAULT 0",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestInventoryMigrationHasTenantIndexes(t *testing.T) {
	sql := readMigration(t, "20260425_093001_erp_inventory.up.sql")

	expectedIndexes := []string{
		"ux_erp_warehouses_tenant_code",
		"ux_erp_warehouses_one_default",
		"ix_erp_warehouses_tenant_status",
		"ux_erp_stock_movements_tenant_movement_no",
		"ix_erp_stock_movements_tenant_item",
		"ix_erp_stock_movements_tenant_warehouse",
		"ix_erp_stock_movements_tenant_source",
		"ix_erp_stock_movements_tenant_movement_at",
		"ux_erp_warehouse_balances_tenant_wh_item",
		"ix_erp_warehouse_balances_tenant_item",
		"ix_erp_warehouse_balances_tenant_warehouse",
	}

	for _, index := range expectedIndexes {
		assertContains(t, sql, index)
	}
}

func TestInventoryMigrationEnablesForcedRLS(t *testing.T) {
	sql := readMigration(t, "20260425_093001_erp_inventory.up.sql")

	expectedRLS := []string{
		"ALTER TABLE erp_warehouses ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_stock_movements ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_warehouse_balances ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_warehouses FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_stock_movements FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_warehouse_balances FORCE ROW LEVEL SECURITY",
	}

	for _, rls := range expectedRLS {
		assertContains(t, sql, rls)
	}
}

func TestInventoryMigrationHasTenantIsolationPolicies(t *testing.T) {
	sql := readMigration(t, "20260425_093001_erp_inventory.up.sql")

	expectedPolicies := []string{
		"erp_warehouses_tenant_isolation_policy",
		"erp_stock_movements_tenant_isolation_policy",
		"erp_warehouse_balances_tenant_isolation_policy",
		"tenant_id = current_setting('app.tenant_id', true)",
	}

	for _, policy := range expectedPolicies {
		assertContains(t, sql, policy)
	}
}

func TestInventoryRollbackDropsTablesInSafeOrder(t *testing.T) {
	sql := readMigration(t, "20260425_093001_erp_inventory.down.sql")

	expectedDrops := []string{
		"DROP TABLE IF EXISTS erp_warehouse_balances",
		"DROP TABLE IF EXISTS erp_stock_movements",
		"DROP TABLE IF EXISTS erp_warehouses",
	}

	for _, drop := range expectedDrops {
		assertContains(t, sql, drop)
	}
}
