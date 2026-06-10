package productcatalog_test

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

func productCatalogIntegrationDSN(t *testing.T) string {
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

func productCatalogPSQL(t *testing.T, dsn string, sql string) string {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("psql failed\nsql:\n%s\nerror: %v\noutput:\n%s", sql, err, string(out))
	}

	return strings.TrimSpace(string(out))
}

func productCatalogPSQLMustFail(t *testing.T, dsn string, sql string) {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err == nil {
		t.Fatalf("expected psql failure but command succeeded\nsql:\n%s\noutput:\n%s", sql, string(out))
	}
}

func TestProductCatalogDBTablesExist(t *testing.T) {
	dsn := productCatalogIntegrationDSN(t)

	got := productCatalogPSQL(t, dsn, `
SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'erp_units',
    'erp_product_categories',
    'erp_items',
    'erp_products'
  );
`)

	if got != "4" {
		t.Fatalf("expected 4 product catalog tables, got %s", got)
	}
}

func TestProductCatalogDBIndexesExist(t *testing.T) {
	dsn := productCatalogIntegrationDSN(t)

	got := productCatalogPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'ux_erp_units_tenant_code',
    'ix_erp_units_tenant_status',
    'ux_erp_product_categories_tenant_code',
    'ix_erp_product_categories_tenant_parent',
    'ix_erp_product_categories_tenant_status',
    'ux_erp_items_tenant_code',
    'ux_erp_items_tenant_barcode',
    'ix_erp_items_tenant_category',
    'ix_erp_items_tenant_status',
    'ix_erp_items_tenant_name',
    'ux_erp_products_tenant_code',
    'ux_erp_products_tenant_item',
    'ix_erp_products_tenant_status',
    'ix_erp_products_tenant_name'
  );
`)

	if got != "14" {
		t.Fatalf("expected 14 product catalog indexes, got %s", got)
	}
}

func TestProductCatalogDBRLSEnabledAndForced(t *testing.T) {
	dsn := productCatalogIntegrationDSN(t)

	got := productCatalogPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN (
    'erp_units',
    'erp_product_categories',
    'erp_items',
    'erp_products'
  )
  AND c.relrowsecurity = true
  AND c.relforcerowsecurity = true;
`)

	if got != "4" {
		t.Fatalf("expected RLS enabled and forced on 4 tables, got %s", got)
	}
}

func TestProductCatalogDBTenantPoliciesExist(t *testing.T) {
	dsn := productCatalogIntegrationDSN(t)

	got := productCatalogPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_policy p
JOIN pg_class c ON c.oid = p.polrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND p.polname IN (
    'erp_units_tenant_isolation_policy',
    'erp_product_categories_tenant_isolation_policy',
    'erp_items_tenant_isolation_policy',
    'erp_products_tenant_isolation_policy'
  );
`)

	if got != "4" {
		t.Fatalf("expected 4 tenant isolation policies, got %s", got)
	}
}

func TestProductCatalogDBTenantIsolationWorks(t *testing.T) {
	dsn := productCatalogIntegrationDSN(t)

	isSuperUser := productCatalogPSQL(t, dsn, `
SELECT rolsuper
FROM pg_roles
WHERE rolname = current_user;
`)

	if isSuperUser == "t" {
		t.Skip("current DB user is superuser; PostgreSQL superuser bypasses RLS behavior checks")
	}

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	unitCode := "ADT-" + unique
	categoryCode := "CAT-" + unique
	itemCode := "ITEM-" + unique
	barcode := "BAR-" + unique
	productCode := "PRD-" + unique

	unitID := productCatalogPSQL(t, dsn, fmt.Sprintf(`
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
    '%s',
    'Adet Test %s',
    'quantity',
    0,
    true,
    'faz3_test'
)
RETURNING unit_id;
`, unitCode, unique))

	categoryID := productCatalogPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_product_categories (
    tenant_id,
    category_code,
    category_name,
    description,
    sort_order,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    'Kategori Test %s',
    'Faz 3 product catalog test kategorisi',
    1,
    'faz3_test'
)
RETURNING category_id;
`, categoryCode, unique))

	itemID := productCatalogPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_items (
    tenant_id,
    item_code,
    item_name,
    item_type,
    category_id,
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
    '%s',
    'Item Test %s',
    'stock',
    '%s',
    '%s',
    '%s',
    'SKU-%s',
    20.00,
    true,
    true,
    true,
    'faz3_test'
)
RETURNING item_id;
`, itemCode, unique, categoryID, unitID, barcode, unique))

	productID := productCatalogPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_products (
    tenant_id,
    item_id,
    product_code,
    product_name,
    short_description,
    default_sales_unit_id,
    is_sellable,
    is_visible_pos,
    is_visible_web,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    '%s',
    'Product Test %s',
    'Faz 3 product catalog test urunu',
    '%s',
    true,
    true,
    false,
    'faz3_test'
)
RETURNING product_id;
`, itemID, productCode, unique, unitID))

	defer func() {
		cleanupSQL := fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
DELETE FROM erp_products WHERE product_id = '%s';
DELETE FROM erp_items WHERE item_id = '%s';
DELETE FROM erp_product_categories WHERE category_id = '%s';
DELETE FROM erp_units WHERE unit_id = '%s';
`, productID, itemID, categoryID, unitID)

		_ = exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", cleanupSQL).Run()
	}()

	visibleForTenant7 := productCatalogPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_products
WHERE product_id = '%s';
`, productID))

	if visibleForTenant7 != "1" {
		t.Fatalf("expected tenant_7 to see inserted product, got %s", visibleForTenant7)
	}

	visibleForTenant99 := productCatalogPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_99';
SELECT COUNT(*)
FROM erp_products
WHERE product_id = '%s';
`, productID))

	if visibleForTenant99 != "0" {
		t.Fatalf("expected tenant_99 not to see tenant_7 product, got %s", visibleForTenant99)
	}

	productCatalogPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_units (
    tenant_id,
    unit_code,
    unit_name,
    unit_type
)
VALUES (
    'tenant_99',
    'BAD-%s',
    'Bad Tenant Unit',
    'quantity'
);
`, unique))
}
