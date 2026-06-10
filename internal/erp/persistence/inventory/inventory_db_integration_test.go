package inventory_test

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

func inventoryIntegrationDSN(t *testing.T) string {
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

func inventoryPSQL(t *testing.T, dsn string, sql string) string {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("psql failed\nsql:\n%s\nerror: %v\noutput:\n%s", sql, err, string(out))
	}

	return strings.TrimSpace(string(out))
}

func inventoryPSQLMustFail(t *testing.T, dsn string, sql string) {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err == nil {
		t.Fatalf("expected psql failure but command succeeded\nsql:\n%s\noutput:\n%s", sql, string(out))
	}
}

func TestInventoryDBTablesExist(t *testing.T) {
	dsn := inventoryIntegrationDSN(t)

	got := inventoryPSQL(t, dsn, `
SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'erp_warehouses',
    'erp_stock_movements',
    'erp_warehouse_balances'
  );
`)

	if got != "3" {
		t.Fatalf("expected 3 inventory tables, got %s", got)
	}
}

func TestInventoryDBIndexesExist(t *testing.T) {
	dsn := inventoryIntegrationDSN(t)

	got := inventoryPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'ux_erp_warehouses_tenant_code',
    'ux_erp_warehouses_one_default',
    'ix_erp_warehouses_tenant_status',
    'ux_erp_stock_movements_tenant_movement_no',
    'ix_erp_stock_movements_tenant_item',
    'ix_erp_stock_movements_tenant_warehouse',
    'ix_erp_stock_movements_tenant_source',
    'ix_erp_stock_movements_tenant_movement_at',
    'ux_erp_warehouse_balances_tenant_wh_item',
    'ix_erp_warehouse_balances_tenant_item',
    'ix_erp_warehouse_balances_tenant_warehouse',
    'ix_erp_warehouse_balances_tenant_status'
  );
`)

	if got != "12" {
		t.Fatalf("expected 12 inventory indexes, got %s", got)
	}
}

func TestInventoryDBRLSEnabledAndForced(t *testing.T) {
	dsn := inventoryIntegrationDSN(t)

	got := inventoryPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN (
    'erp_warehouses',
    'erp_stock_movements',
    'erp_warehouse_balances'
  )
  AND c.relrowsecurity = true
  AND c.relforcerowsecurity = true;
`)

	if got != "3" {
		t.Fatalf("expected RLS enabled and forced on 3 tables, got %s", got)
	}
}

func TestInventoryDBTenantPoliciesExist(t *testing.T) {
	dsn := inventoryIntegrationDSN(t)

	got := inventoryPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_policy p
JOIN pg_class c ON c.oid = p.polrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND p.polname IN (
    'erp_warehouses_tenant_isolation_policy',
    'erp_stock_movements_tenant_isolation_policy',
    'erp_warehouse_balances_tenant_isolation_policy'
  );
`)

	if got != "3" {
		t.Fatalf("expected 3 tenant isolation policies, got %s", got)
	}
}

func TestInventoryDBTenantIsolationWorks(t *testing.T) {
	dsn := inventoryIntegrationDSN(t)

	isSuperUser := inventoryPSQL(t, dsn, `
SELECT rolsuper
FROM pg_roles
WHERE rolname = current_user;
`)

	if isSuperUser == "t" {
		t.Skip("current DB user is superuser; PostgreSQL superuser bypasses RLS behavior checks")
	}

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	unitID := inventoryPSQL(t, dsn, fmt.Sprintf(`
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
    'INV-UNIT-%s',
    'Inventory Unit Test %s',
    'quantity',
    0,
    true,
    'faz3_inventory_test'
)
RETURNING unit_id;
`, unique, unique))

	itemID := inventoryPSQL(t, dsn, fmt.Sprintf(`
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
    'INV-ITEM-%s',
    'Inventory Item Test %s',
    'stock',
    '%s',
    'INV-BAR-%s',
    'INV-SKU-%s',
    20.00,
    true,
    true,
    true,
    'faz3_inventory_test'
)
RETURNING item_id;
`, unique, unique, unitID, unique, unique))

	warehouseID := inventoryPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_warehouses (
    tenant_id,
    warehouse_code,
    warehouse_name,
    warehouse_type,
    city,
    district,
    address_line,
    is_default,
    created_by
)
VALUES (
    'tenant_7',
    'WH-%s',
    'Inventory Warehouse Test %s',
    'main',
    'Istanbul',
    'Kadikoy',
    'FAZ3 Inventory Test Adresi',
    false,
    'faz3_inventory_test'
)
RETURNING warehouse_id;
`, unique, unique))

	movementID := inventoryPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_stock_movements (
    tenant_id,
    movement_no,
    movement_type,
    movement_direction,
    warehouse_id,
    item_id,
    unit_id,
    quantity,
    unit_cost,
    total_cost,
    source_type,
    source_id,
    status,
    note,
    created_by
)
VALUES (
    'tenant_7',
    'MOV-%s',
    'opening',
    'in',
    '%s',
    '%s',
    '%s',
    10.000000,
    5.000000,
    50.000000,
    'integration_test',
    'SRC-%s',
    'posted',
    'FAZ3 inventory DB integration test',
    'faz3_inventory_test'
)
RETURNING stock_movement_id;
`, unique, warehouseID, itemID, unitID, unique))

	balanceID := inventoryPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_warehouse_balances (
    tenant_id,
    warehouse_id,
    item_id,
    unit_id,
    on_hand_quantity,
    reserved_quantity,
    available_quantity,
    last_movement_at,
    last_stock_movement_id,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    '%s',
    '%s',
    10.000000,
    2.000000,
    8.000000,
    now(),
    '%s',
    'faz3_inventory_test'
)
RETURNING balance_id;
`, warehouseID, itemID, unitID, movementID))

	defer func() {
		cleanupSQL := fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
DELETE FROM erp_warehouse_balances WHERE balance_id = '%s';
DELETE FROM erp_stock_movements WHERE stock_movement_id = '%s';
DELETE FROM erp_items WHERE item_id = '%s';
DELETE FROM erp_units WHERE unit_id = '%s';
DELETE FROM erp_warehouses WHERE warehouse_id = '%s';
`, balanceID, movementID, itemID, unitID, warehouseID)

		_ = exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", cleanupSQL).Run()
	}()

	visibleForTenant7 := inventoryPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_warehouse_balances
WHERE balance_id = '%s';
`, balanceID))

	if visibleForTenant7 != "1" {
		t.Fatalf("expected tenant_7 to see inserted warehouse balance, got %s", visibleForTenant7)
	}

	visibleForTenant99 := inventoryPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_99';
SELECT COUNT(*)
FROM erp_warehouse_balances
WHERE balance_id = '%s';
`, balanceID))

	if visibleForTenant99 != "0" {
		t.Fatalf("expected tenant_99 not to see tenant_7 warehouse balance, got %s", visibleForTenant99)
	}

	inventoryPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_warehouses (
    tenant_id,
    warehouse_code,
    warehouse_name,
    warehouse_type
)
VALUES (
    'tenant_99',
    'BAD-WH-%s',
    'Bad Tenant Warehouse',
    'main'
);
`, unique))
}
