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

func postgresPurchaseInvoiceRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping purchase invoice repository integration test")
	}

	return dsn
}

func TestPostgresPurchaseInvoiceRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresPurchaseInvoiceRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresPurchaseInvoiceRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	partyID, vendorID, unitID, itemID, warehouseID, purchaseOrderID, purchaseOrderLineID, purchaseReceiptID, purchaseReceiptLineID := createPurchaseInvoiceFixture(t, pool, "tenant_7", unique)

	purchaseInvoiceNo := "PINV-REPO-" + unique
	vendorInvoiceNo := "VEND-INV-" + unique
	dueDate := time.Now().UTC().AddDate(0, 0, 7)

	invoice, err := repo.CreatePurchaseInvoice(ctx, CreatePurchaseInvoiceInput{
		TenantID:          "tenant_7",
		PurchaseInvoiceNo: purchaseInvoiceNo,
		VendorInvoiceNo:   vendorInvoiceNo,
		PurchaseOrderID:   purchaseOrderID,
		PurchaseReceiptID: purchaseReceiptID,
		VendorID:          vendorID,
		PartyID:           partyID,
		InvoiceType:       PurchaseInvoiceTypePurchase,
		DocumentDate:      time.Now().UTC(),
		DueDate:           &dueDate,
		CurrencyCode:      "TRY",
		ExchangeRate:      1,
		SubtotalAmount:    100,
		DiscountAmount:    0,
		VATAmount:         20,
		TotalAmount:       120,
		PaidAmount:        0,
		RemainingAmount:   120,
		EDocumentStatus:   PurchaseEDocumentStatusNone,
		Note:              "FAZ3 purchase invoice repository test " + unique,
		CreatedBy:         "faz3_test",
	})
	if err != nil {
		cleanupPurchaseInvoiceFixture(t, pool, "tenant_7", "", "", purchaseReceiptID, purchaseReceiptLineID, purchaseOrderID, purchaseOrderLineID, warehouseID, vendorID, partyID, itemID, unitID)
		t.Fatalf("create purchase invoice: %v", err)
	}

	line, err := repo.CreatePurchaseInvoiceLine(ctx, CreatePurchaseInvoiceLineInput{
		TenantID:              "tenant_7",
		PurchaseInvoiceID:     invoice.PurchaseInvoiceID,
		PurchaseOrderLineID:   purchaseOrderLineID,
		PurchaseReceiptLineID: purchaseReceiptLineID,
		LineNo:                1,
		ItemID:                itemID,
		UnitID:                unitID,
		Description:           "FAZ3 purchase invoice line test " + unique,
		Quantity:              1,
		UnitCost:              100,
		DiscountRate:          0,
		DiscountAmount:        0,
		VATRate:               20,
		VATAmount:             20,
		LineTotal:             120,
		CreatedBy:             "faz3_test",
	})
	if err != nil {
		cleanupPurchaseInvoiceFixture(t, pool, "tenant_7", invoice.PurchaseInvoiceID, "", purchaseReceiptID, purchaseReceiptLineID, purchaseOrderID, purchaseOrderLineID, warehouseID, vendorID, partyID, itemID, unitID)
		t.Fatalf("create purchase invoice line: %v", err)
	}

	defer cleanupPurchaseInvoiceFixture(t, pool, "tenant_7", invoice.PurchaseInvoiceID, line.PurchaseInvoiceLineID, purchaseReceiptID, purchaseReceiptLineID, purchaseOrderID, purchaseOrderLineID, warehouseID, vendorID, partyID, itemID, unitID)

	if invoice.PurchaseInvoiceID == "" {
		t.Fatal("expected purchase_invoice_id")
	}

	if invoice.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", invoice.TenantID)
	}

	if invoice.PurchaseInvoiceNo != purchaseInvoiceNo {
		t.Fatalf("expected purchase_invoice_no %s, got %s", purchaseInvoiceNo, invoice.PurchaseInvoiceNo)
	}

	if invoice.VendorInvoiceNo != vendorInvoiceNo {
		t.Fatalf("expected vendor_invoice_no %s, got %s", vendorInvoiceNo, invoice.VendorInvoiceNo)
	}

	if invoice.PurchaseOrderID != purchaseOrderID {
		t.Fatalf("expected purchase_order_id %s, got %s", purchaseOrderID, invoice.PurchaseOrderID)
	}

	if invoice.PurchaseReceiptID != purchaseReceiptID {
		t.Fatalf("expected purchase_receipt_id %s, got %s", purchaseReceiptID, invoice.PurchaseReceiptID)
	}

	if invoice.RemainingAmount != 120 {
		t.Fatalf("expected remaining_amount 120, got %v", invoice.RemainingAmount)
	}

	if line.PurchaseInvoiceLineID == "" {
		t.Fatal("expected purchase_invoice_line_id")
	}

	if line.PurchaseInvoiceID != invoice.PurchaseInvoiceID {
		t.Fatalf("expected purchase_invoice_id %s, got %s", invoice.PurchaseInvoiceID, line.PurchaseInvoiceID)
	}

	got, err := repo.GetPurchaseInvoiceByID(ctx, "tenant_7", invoice.PurchaseInvoiceID)
	if err != nil {
		t.Fatalf("get purchase invoice: %v", err)
	}

	if got.PurchaseInvoiceID != invoice.PurchaseInvoiceID {
		t.Fatalf("expected purchase_invoice_id %s, got %s", invoice.PurchaseInvoiceID, got.PurchaseInvoiceID)
	}

	list, err := repo.ListPurchaseInvoices(ctx, "tenant_7", ListPurchaseInvoicesFilter{
		VendorID:          vendorID,
		PurchaseOrderID:   purchaseOrderID,
		PurchaseReceiptID: purchaseReceiptID,
		Query:             unique,
		Status:            PurchaseInvoiceStatusDraft,
		Limit:             10,
	})
	if err != nil {
		t.Fatalf("list purchase invoices: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 purchase invoice in list, got %d", len(list))
	}

	lines, err := repo.ListPurchaseInvoiceLines(ctx, "tenant_7", invoice.PurchaseInvoiceID)
	if err != nil {
		t.Fatalf("list purchase invoice lines: %v", err)
	}

	if len(lines) != 1 {
		t.Fatalf("expected 1 purchase invoice line, got %d", len(lines))
	}

	_, err = repo.GetPurchaseInvoiceByID(ctx, "tenant_99", invoice.PurchaseInvoiceID)
	if !errors.Is(err, ErrPurchaseInvoiceNotFound) {
		t.Fatalf("expected ErrPurchaseInvoiceNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresPurchaseInvoiceRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresPurchaseInvoiceRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresPurchaseInvoiceRepository(pool)

	_, err = repo.CreatePurchaseInvoice(ctx, CreatePurchaseInvoiceInput{
		TenantID:        "tenant_7",
		VendorID:        "vendor-id",
		PartyID:         "party-id",
		InvoiceType:     PurchaseInvoiceTypePurchase,
		ExchangeRate:    1,
		TotalAmount:     120,
		RemainingAmount: 120,
	})

	if !errors.Is(err, ErrPurchaseInvoiceNoRequired) {
		t.Fatalf("expected ErrPurchaseInvoiceNoRequired, got %v", err)
	}
}

func createPurchaseInvoiceFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) (string, string, string, string, string, string, string, string, string) {
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
    'faz3_purchase_invoice_test'
)
RETURNING party_id::text;
`, tenantID, "Purchase Invoice Fixture "+unique, "Purchase Invoice Fixture Ltd "+unique, "PINV"+unique, "purchase_invoice_"+unique+"@example.com").Scan(&partyID); err != nil {
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
    'faz3_purchase_invoice_test'
)
RETURNING unit_id::text;
`, tenantID, "PINV-UNIT-"+unique, "Purchase Invoice Unit "+unique).Scan(&unitID); err != nil {
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
    'faz3_purchase_invoice_test'
)
RETURNING item_id::text;
`, tenantID, "PINV-ITEM-"+unique, "Purchase Invoice Item "+unique, unitID, "PINV-BAR-"+unique, "PINV-SKU-"+unique).Scan(&itemID); err != nil {
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
    'faz3_purchase_invoice_test'
)
RETURNING warehouse_id::text;
`, tenantID, "PINV-WH-"+unique, "Purchase Invoice Warehouse "+unique).Scan(&warehouseID); err != nil {
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
    'faz3_purchase_invoice_test'
)
RETURNING purchase_order_id::text;
`, tenantID, "PINV-PO-"+unique, vendorID, partyID).Scan(&purchaseOrderID); err != nil {
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
    'faz3_purchase_invoice_test'
)
RETURNING purchase_order_line_id::text;
`, tenantID, purchaseOrderID, itemID, unitID, "Purchase invoice fixture order line "+unique).Scan(&purchaseOrderLineID); err != nil {
		t.Fatalf("fixture purchase order line failed: %v", err)
	}

	var purchaseReceiptID string
	if err := tx.QueryRow(ctx, `
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
    $1,
    $2,
    $3,
    $4,
    $5,
    $6,
    CURRENT_DATE,
    CURRENT_DATE,
    'draft',
    'faz3_purchase_invoice_test'
)
RETURNING purchase_receipt_id::text;
`, tenantID, "PINV-RCPT-"+unique, purchaseOrderID, vendorID, partyID, warehouseID).Scan(&purchaseReceiptID); err != nil {
		t.Fatalf("fixture purchase receipt failed: %v", err)
	}

	var purchaseReceiptLineID string
	if err := tx.QueryRow(ctx, `
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
    $1,
    $2,
    $3,
    1,
    $4,
    $5,
    $6,
    1.000000,
    'faz3_purchase_invoice_test'
)
RETURNING purchase_receipt_line_id::text;
`, tenantID, purchaseReceiptID, purchaseOrderLineID, itemID, unitID, "Purchase invoice fixture receipt line "+unique).Scan(&purchaseReceiptLineID); err != nil {
		t.Fatalf("fixture purchase receipt line failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("fixture commit failed: %v", err)
	}

	return partyID, vendorID, unitID, itemID, warehouseID, purchaseOrderID, purchaseOrderLineID, purchaseReceiptID, purchaseReceiptLineID
}

func cleanupPurchaseInvoiceFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, purchaseInvoiceID string, purchaseInvoiceLineID string, purchaseReceiptID string, purchaseReceiptLineID string, purchaseOrderID string, purchaseOrderLineID string, warehouseID string, vendorID string, partyID string, itemID string, unitID string) {
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

	if purchaseInvoiceLineID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_purchase_invoice_lines WHERE purchase_invoice_line_id = $1;", purchaseInvoiceLineID); err != nil {
			t.Logf("cleanup purchase invoice line failed: %v", err)
			return
		}
	}

	if purchaseInvoiceID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_purchase_invoices WHERE purchase_invoice_id = $1;", purchaseInvoiceID); err != nil {
			t.Logf("cleanup purchase invoice failed: %v", err)
			return
		}
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
