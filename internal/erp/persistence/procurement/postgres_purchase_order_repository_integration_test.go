package procurement

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresPurchaseOrderRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping purchase order repository integration test")
	}

	return dsn
}

func TestPostgresPurchaseOrderRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresPurchaseOrderRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresPurchaseOrderRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	partyID, vendorID, unitID, itemID := createPurchaseOrderFixture(t, pool, "tenant_7", unique)

	purchaseOrderNo := "PO-REPO-" + unique
	expectedReceiptDate := time.Now().UTC().AddDate(0, 0, 5)

	order, err := repo.CreatePurchaseOrder(ctx, CreatePurchaseOrderInput{
		TenantID:            "tenant_7",
		PurchaseOrderNo:     purchaseOrderNo,
		VendorID:            vendorID,
		PartyID:             partyID,
		DocumentDate:        time.Now().UTC(),
		ExpectedReceiptDate: &expectedReceiptDate,
		CurrencyCode:        "TRY",
		ExchangeRate:        1,
		SubtotalAmount:      100,
		DiscountAmount:      0,
		VATAmount:           20,
		TotalAmount:         120,
		Note:                "FAZ3 purchase order repository test " + unique,
		CreatedBy:           "faz3_test",
	})
	if err != nil {
		cleanupPurchaseOrderFixture(t, pool, "tenant_7", "", "", vendorID, partyID, itemID, unitID)
		t.Fatalf("create purchase order: %v", err)
	}

	line, err := repo.CreatePurchaseOrderLine(ctx, CreatePurchaseOrderLineInput{
		TenantID:         "tenant_7",
		PurchaseOrderID:  order.PurchaseOrderID,
		LineNo:           1,
		ItemID:           itemID,
		UnitID:           unitID,
		Description:      "FAZ3 purchase order line test " + unique,
		Quantity:         1,
		ReceivedQuantity: 0,
		InvoicedQuantity: 0,
		UnitCost:         100,
		DiscountRate:     0,
		DiscountAmount:   0,
		VATRate:          20,
		VATAmount:        20,
		LineTotal:        120,
		CreatedBy:        "faz3_test",
	})
	if err != nil {
		cleanupPurchaseOrderFixture(t, pool, "tenant_7", order.PurchaseOrderID, "", vendorID, partyID, itemID, unitID)
		t.Fatalf("create purchase order line: %v", err)
	}

	defer cleanupPurchaseOrderFixture(t, pool, "tenant_7", order.PurchaseOrderID, line.PurchaseOrderLineID, vendorID, partyID, itemID, unitID)

	if order.PurchaseOrderID == "" {
		t.Fatal("expected purchase_order_id")
	}

	if order.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", order.TenantID)
	}

	if order.PurchaseOrderNo != purchaseOrderNo {
		t.Fatalf("expected purchase_order_no %s, got %s", purchaseOrderNo, order.PurchaseOrderNo)
	}

	if order.VendorID != vendorID {
		t.Fatalf("expected vendor_id %s, got %s", vendorID, order.VendorID)
	}

	if line.PurchaseOrderLineID == "" {
		t.Fatal("expected purchase_order_line_id")
	}

	if line.PurchaseOrderID != order.PurchaseOrderID {
		t.Fatalf("expected purchase_order_id %s, got %s", order.PurchaseOrderID, line.PurchaseOrderID)
	}

	got, err := repo.GetPurchaseOrderByID(ctx, "tenant_7", order.PurchaseOrderID)
	if err != nil {
		t.Fatalf("get purchase order: %v", err)
	}

	if got.PurchaseOrderID != order.PurchaseOrderID {
		t.Fatalf("expected purchase_order_id %s, got %s", order.PurchaseOrderID, got.PurchaseOrderID)
	}

	list, err := repo.ListPurchaseOrders(ctx, "tenant_7", ListPurchaseOrdersFilter{
		VendorID: vendorID,
		Query:    unique,
		Status:   PurchaseOrderStatusDraft,
		Limit:    10,
	})
	if err != nil {
		t.Fatalf("list purchase orders: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 purchase order in list, got %d", len(list))
	}

	lines, err := repo.ListPurchaseOrderLines(ctx, "tenant_7", order.PurchaseOrderID)
	if err != nil {
		t.Fatalf("list purchase order lines: %v", err)
	}

	if len(lines) != 1 {
		t.Fatalf("expected 1 purchase order line, got %d", len(lines))
	}

	_, err = repo.GetPurchaseOrderByID(ctx, "tenant_99", order.PurchaseOrderID)
	if !errors.Is(err, ErrPurchaseOrderNotFound) {
		t.Fatalf("expected ErrPurchaseOrderNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresPurchaseOrderRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresPurchaseOrderRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresPurchaseOrderRepository(pool)

	_, err = repo.CreatePurchaseOrder(ctx, CreatePurchaseOrderInput{
		TenantID:     "tenant_7",
		VendorID:     "vendor-id",
		PartyID:      "party-id",
		ExchangeRate: 1,
	})

	if !errors.Is(err, ErrPurchaseOrderNoRequired) {
		t.Fatalf("expected ErrPurchaseOrderNoRequired, got %v", err)
	}
}

func createPurchaseOrderFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) (string, string, string, string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("fixture begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("fixture set tenant failed: %v", err)
	}

	var partyID string
	if err := tx.QueryRow(ctx, `
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
    $1,
    'organization',
    $2,
    $3,
    $4,
    'Kadikoy',
    '05000000000',
    $5,
    'integration_test',
    'faz3_purchase_order_test'
)
RETURNING party_id::text;
`, tenantID, "Purchase Order Fixture "+unique, "Purchase Order Fixture Ltd "+unique, "PO"+unique, "purchase_order_"+unique+"@example.com").Scan(&partyID); err != nil {
		t.Fatalf("fixture party failed: %v", err)
	}

	vendorID := createPurchaseOrderVendor(t, tx, tenantID, partyID, unique)

	var unitID string
	if err := tx.QueryRow(ctx, `
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
    $1,
    $2,
    $3,
    'quantity',
    0,
    true,
    'faz3_purchase_order_test'
)
RETURNING unit_id::text;
`, tenantID, "PO-UNIT-"+unique, "Purchase Order Unit "+unique).Scan(&unitID); err != nil {
		t.Fatalf("fixture unit failed: %v", err)
	}

	var itemID string
	if err := tx.QueryRow(ctx, `
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
    $1,
    $2,
    $3,
    'stock',
    $4,
    $5,
    $6,
    20.00,
    true,
    true,
    true,
    'faz3_purchase_order_test'
)
RETURNING item_id::text;
`, tenantID, "PO-ITEM-"+unique, "Purchase Order Item "+unique, unitID, "PO-BAR-"+unique, "PO-SKU-"+unique).Scan(&itemID); err != nil {
		t.Fatalf("fixture item failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("fixture commit failed: %v", err)
	}

	return partyID, vendorID, unitID, itemID
}

func createPurchaseOrderVendor(t *testing.T, tx pgx.Tx, tenantID string, partyID string, unique string) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	rows, err := tx.Query(ctx, `
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'erp_vendors'
ORDER BY ordinal_position;
`)
	if err != nil {
		t.Fatalf("vendor column lookup failed: %v", err)
	}
	defer rows.Close()

	columnSet := map[string]bool{}
	for rows.Next() {
		var col string
		if err := rows.Scan(&col); err != nil {
			t.Fatalf("vendor column scan failed: %v", err)
		}
		columnSet[col] = true
	}

	columns := []string{"tenant_id", "party_id"}
	values := []any{tenantID, partyID}
	placeholders := []string{"$1", "$2"}

	add := func(column string, value any) {
		if columnSet[column] {
			columns = append(columns, column)
			values = append(values, value)
			placeholders = append(placeholders, fmt.Sprintf("$%d", len(values)))
		}
	}

	add("vendor_code", "PO-VEND-"+unique)
	add("vendor_name", "Purchase Order Vendor "+unique)
	add("currency_code", "TRY")
	add("payment_term_days", 0)
	add("is_credit_allowed", true)
	add("is_purchase_allowed", true)
	add("vendor_type", "supplier")
	add("status", "active")
	add("source", "integration_test")
	add("created_by", "faz3_purchase_order_test")

	sql := fmt.Sprintf(`
INSERT INTO erp_vendors (
    %s
)
VALUES (
    %s
)
RETURNING vendor_id::text;
`, strings.Join(columns, ",\n    "), strings.Join(placeholders, ",\n    "))

	var vendorID string
	if err := tx.QueryRow(ctx, sql, values...).Scan(&vendorID); err != nil {
		t.Fatalf("fixture vendor failed: %v", err)
	}

	return vendorID
}

func cleanupPurchaseOrderFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, purchaseOrderID string, purchaseOrderLineID string, vendorID string, partyID string, itemID string, unitID string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Logf("cleanup begin failed: %v", err)
		return
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Logf("cleanup set tenant failed: %v", err)
		return
	}

	if purchaseOrderLineID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_purchase_order_lines WHERE purchase_order_line_id = $1;", purchaseOrderLineID); err != nil {
			t.Logf("cleanup purchase order line failed: %v", err)
			return
		}
	}

	if purchaseOrderID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_purchase_orders WHERE purchase_order_id = $1;", purchaseOrderID); err != nil {
			t.Logf("cleanup purchase order failed: %v", err)
			return
		}
	}

	if itemID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_items WHERE item_id = $1;", itemID); err != nil {
			t.Logf("cleanup item failed: %v", err)
			return
		}
	}

	if unitID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_units WHERE unit_id = $1;", unitID); err != nil {
			t.Logf("cleanup unit failed: %v", err)
			return
		}
	}

	if vendorID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_vendors WHERE vendor_id = $1;", vendorID); err != nil {
			t.Logf("cleanup vendor failed: %v", err)
			return
		}
	}

	if partyID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_parties WHERE party_id = $1;", partyID); err != nil {
			t.Logf("cleanup party failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
