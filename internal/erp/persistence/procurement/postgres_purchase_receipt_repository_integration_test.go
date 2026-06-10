package procurement

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresPurchaseReceiptRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping purchase receipt repository integration test")
	}

	return dsn
}

func TestPostgresPurchaseReceiptRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresPurchaseReceiptRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresPurchaseReceiptRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	partyID, vendorID, unitID, itemID, warehouseID, purchaseOrderID, purchaseOrderLineID := createPurchaseReceiptFixture(t, pool, "tenant_7", unique)

	purchaseReceiptNo := "RCPT-REPO-" + unique
	receiptDate := time.Now().UTC()

	receipt, err := repo.CreatePurchaseReceipt(ctx, CreatePurchaseReceiptInput{
		TenantID:          "tenant_7",
		PurchaseReceiptNo: purchaseReceiptNo,
		PurchaseOrderID:   purchaseOrderID,
		VendorID:          vendorID,
		PartyID:           partyID,
		WarehouseID:       warehouseID,
		DocumentDate:      time.Now().UTC(),
		ReceiptDate:       &receiptDate,
		Note:              "FAZ3 purchase receipt repository test " + unique,
		CreatedBy:         "faz3_test",
	})
	if err != nil {
		cleanupPurchaseReceiptFixture(t, pool, "tenant_7", "", "", purchaseOrderID, purchaseOrderLineID, warehouseID, vendorID, partyID, itemID, unitID)
		t.Fatalf("create purchase receipt: %v", err)
	}

	line, err := repo.CreatePurchaseReceiptLine(ctx, CreatePurchaseReceiptLineInput{
		TenantID:            "tenant_7",
		PurchaseReceiptID:   receipt.PurchaseReceiptID,
		PurchaseOrderLineID: purchaseOrderLineID,
		LineNo:              1,
		ItemID:              itemID,
		UnitID:              unitID,
		Description:         "FAZ3 purchase receipt line test " + unique,
		Quantity:            1,
		CreatedBy:           "faz3_test",
	})
	if err != nil {
		cleanupPurchaseReceiptFixture(t, pool, "tenant_7", receipt.PurchaseReceiptID, "", purchaseOrderID, purchaseOrderLineID, warehouseID, vendorID, partyID, itemID, unitID)
		t.Fatalf("create purchase receipt line: %v", err)
	}

	defer cleanupPurchaseReceiptFixture(t, pool, "tenant_7", receipt.PurchaseReceiptID, line.PurchaseReceiptLineID, purchaseOrderID, purchaseOrderLineID, warehouseID, vendorID, partyID, itemID, unitID)

	if receipt.PurchaseReceiptID == "" {
		t.Fatal("expected purchase_receipt_id")
	}

	if receipt.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", receipt.TenantID)
	}

	if receipt.PurchaseReceiptNo != purchaseReceiptNo {
		t.Fatalf("expected purchase_receipt_no %s, got %s", purchaseReceiptNo, receipt.PurchaseReceiptNo)
	}

	if receipt.PurchaseOrderID != purchaseOrderID {
		t.Fatalf("expected purchase_order_id %s, got %s", purchaseOrderID, receipt.PurchaseOrderID)
	}

	if receipt.WarehouseID != warehouseID {
		t.Fatalf("expected warehouse_id %s, got %s", warehouseID, receipt.WarehouseID)
	}

	if line.PurchaseReceiptLineID == "" {
		t.Fatal("expected purchase_receipt_line_id")
	}

	if line.PurchaseReceiptID != receipt.PurchaseReceiptID {
		t.Fatalf("expected purchase_receipt_id %s, got %s", receipt.PurchaseReceiptID, line.PurchaseReceiptID)
	}

	got, err := repo.GetPurchaseReceiptByID(ctx, "tenant_7", receipt.PurchaseReceiptID)
	if err != nil {
		t.Fatalf("get purchase receipt: %v", err)
	}

	if got.PurchaseReceiptID != receipt.PurchaseReceiptID {
		t.Fatalf("expected purchase_receipt_id %s, got %s", receipt.PurchaseReceiptID, got.PurchaseReceiptID)
	}

	list, err := repo.ListPurchaseReceipts(ctx, "tenant_7", ListPurchaseReceiptsFilter{
		VendorID:        vendorID,
		PurchaseOrderID: purchaseOrderID,
		WarehouseID:     warehouseID,
		Query:           unique,
		Status:          PurchaseReceiptStatusDraft,
		Limit:           10,
	})
	if err != nil {
		t.Fatalf("list purchase receipts: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 purchase receipt in list, got %d", len(list))
	}

	lines, err := repo.ListPurchaseReceiptLines(ctx, "tenant_7", receipt.PurchaseReceiptID)
	if err != nil {
		t.Fatalf("list purchase receipt lines: %v", err)
	}

	if len(lines) != 1 {
		t.Fatalf("expected 1 purchase receipt line, got %d", len(lines))
	}

	_, err = repo.GetPurchaseReceiptByID(ctx, "tenant_99", receipt.PurchaseReceiptID)
	if !errors.Is(err, ErrPurchaseReceiptNotFound) {
		t.Fatalf("expected ErrPurchaseReceiptNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresPurchaseReceiptRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresPurchaseReceiptRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresPurchaseReceiptRepository(pool)

	_, err = repo.CreatePurchaseReceipt(ctx, CreatePurchaseReceiptInput{
		TenantID:          "tenant_7",
		PurchaseReceiptNo: "RCPT-001",
		VendorID:          "vendor-id",
		PartyID:           "party-id",
	})

	if !errors.Is(err, ErrWarehouseIDRequired) {
		t.Fatalf("expected ErrWarehouseIDRequired, got %v", err)
	}
}

func createPurchaseReceiptFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) (string, string, string, string, string, string, string) {
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
    'faz3_purchase_receipt_test'
)
RETURNING party_id::text;
`, tenantID, "Purchase Receipt Fixture "+unique, "Purchase Receipt Fixture Ltd "+unique, "RCPT"+unique, "purchase_receipt_"+unique+"@example.com").Scan(&partyID); err != nil {
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
    'faz3_purchase_receipt_test'
)
RETURNING unit_id::text;
`, tenantID, "RCPT-UNIT-"+unique, "Purchase Receipt Unit "+unique).Scan(&unitID); err != nil {
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
    'faz3_purchase_receipt_test'
)
RETURNING item_id::text;
`, tenantID, "RCPT-ITEM-"+unique, "Purchase Receipt Item "+unique, unitID, "RCPT-BAR-"+unique, "RCPT-SKU-"+unique).Scan(&itemID); err != nil {
		t.Fatalf("fixture item failed: %v", err)
	}

	var warehouseID string
	if err := tx.QueryRow(ctx, `
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
    $1,
    $2,
    $3,
    'main',
    'Istanbul',
    'Kadikoy',
    false,
    'faz3_purchase_receipt_test'
)
RETURNING warehouse_id::text;
`, tenantID, "RCPT-WH-"+unique, "Purchase Receipt Warehouse "+unique).Scan(&warehouseID); err != nil {
		t.Fatalf("fixture warehouse failed: %v", err)
	}

	var purchaseOrderID string
	if err := tx.QueryRow(ctx, `
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
    $1,
    $2,
    $3,
    $4,
    CURRENT_DATE,
    100.00,
    20.00,
    120.00,
    'draft',
    'faz3_purchase_receipt_test'
)
RETURNING purchase_order_id::text;
`, tenantID, "RCPT-PO-"+unique, vendorID, partyID).Scan(&purchaseOrderID); err != nil {
		t.Fatalf("fixture purchase order failed: %v", err)
	}

	var purchaseOrderLineID string
	if err := tx.QueryRow(ctx, `
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
    $1,
    $2,
    1,
    $3,
    $4,
    $5,
    1.000000,
    100.000000,
    20.00,
    20.00,
    120.00,
    'faz3_purchase_receipt_test'
)
RETURNING purchase_order_line_id::text;
`, tenantID, purchaseOrderID, itemID, unitID, "Purchase receipt fixture order line "+unique).Scan(&purchaseOrderLineID); err != nil {
		t.Fatalf("fixture purchase order line failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("fixture commit failed: %v", err)
	}

	return partyID, vendorID, unitID, itemID, warehouseID, purchaseOrderID, purchaseOrderLineID
}

func cleanupPurchaseReceiptFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, purchaseReceiptID string, purchaseReceiptLineID string, purchaseOrderID string, purchaseOrderLineID string, warehouseID string, vendorID string, partyID string, itemID string, unitID string) {
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

	if purchaseReceiptLineID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_purchase_receipt_lines WHERE purchase_receipt_line_id = $1;", purchaseReceiptLineID); err != nil {
			t.Logf("cleanup purchase receipt line failed: %v", err)
			return
		}
	}

	if purchaseReceiptID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_purchase_receipts WHERE purchase_receipt_id = $1;", purchaseReceiptID); err != nil {
			t.Logf("cleanup purchase receipt failed: %v", err)
			return
		}
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

	if warehouseID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_warehouses WHERE warehouse_id = $1;", warehouseID); err != nil {
			t.Logf("cleanup warehouse failed: %v", err)
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
