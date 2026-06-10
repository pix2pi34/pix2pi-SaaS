package sales

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresSalesInvoiceRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping sales invoice repository integration test")
	}

	return dsn
}

func TestPostgresSalesInvoiceRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresSalesInvoiceRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	invoiceRepo := NewPostgresSalesInvoiceRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	partyID, customerID, unitID, itemID, warehouseID, salesOrderID, salesOrderLineID, deliveryID, deliveryLineID := createSalesInvoiceFixture(t, pool, "tenant_7", unique)

	invoiceNo := "INV-REPO-" + unique
	dueDate := time.Now().UTC().AddDate(0, 0, 7)

	invoice, err := invoiceRepo.CreateSalesInvoice(ctx, CreateSalesInvoiceInput{
		TenantID:        "tenant_7",
		SalesInvoiceNo:  invoiceNo,
		SalesOrderID:    salesOrderID,
		DeliveryID:      deliveryID,
		CustomerID:      customerID,
		PartyID:         partyID,
		InvoiceType:     SalesInvoiceTypeSales,
		DocumentDate:    time.Now().UTC(),
		DueDate:         &dueDate,
		CurrencyCode:    "TRY",
		ExchangeRate:    1,
		SubtotalAmount:  100,
		DiscountAmount:  0,
		VATAmount:       20,
		TotalAmount:     120,
		PaidAmount:      0,
		RemainingAmount: 120,
		EDocumentStatus: EDocumentStatusNone,
		Note:            "FAZ3 sales invoice repository test " + unique,
		CreatedBy:       "faz3_test",
	})
	if err != nil {
		cleanupSalesInvoiceFixture(t, pool, "tenant_7", "", "", deliveryID, deliveryLineID, salesOrderID, salesOrderLineID, warehouseID, customerID, partyID, itemID, unitID)
		t.Fatalf("create sales invoice: %v", err)
	}

	line, err := invoiceRepo.CreateSalesInvoiceLine(ctx, CreateSalesInvoiceLineInput{
		TenantID:         "tenant_7",
		SalesInvoiceID:   invoice.SalesInvoiceID,
		SalesOrderLineID: salesOrderLineID,
		DeliveryLineID:   deliveryLineID,
		LineNo:           1,
		ItemID:           itemID,
		UnitID:           unitID,
		Description:      "FAZ3 sales invoice line test " + unique,
		Quantity:         1,
		UnitPrice:        100,
		DiscountRate:     0,
		DiscountAmount:   0,
		VATRate:          20,
		VATAmount:        20,
		LineTotal:        120,
		CreatedBy:        "faz3_test",
	})
	if err != nil {
		cleanupSalesInvoiceFixture(t, pool, "tenant_7", invoice.SalesInvoiceID, "", deliveryID, deliveryLineID, salesOrderID, salesOrderLineID, warehouseID, customerID, partyID, itemID, unitID)
		t.Fatalf("create sales invoice line: %v", err)
	}

	defer cleanupSalesInvoiceFixture(t, pool, "tenant_7", invoice.SalesInvoiceID, line.SalesInvoiceLineID, deliveryID, deliveryLineID, salesOrderID, salesOrderLineID, warehouseID, customerID, partyID, itemID, unitID)

	if invoice.SalesInvoiceID == "" {
		t.Fatal("expected sales_invoice_id")
	}

	if invoice.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", invoice.TenantID)
	}

	if invoice.SalesInvoiceNo != invoiceNo {
		t.Fatalf("expected sales_invoice_no %s, got %s", invoiceNo, invoice.SalesInvoiceNo)
	}

	if invoice.SalesOrderID != salesOrderID {
		t.Fatalf("expected sales_order_id %s, got %s", salesOrderID, invoice.SalesOrderID)
	}

	if invoice.DeliveryID != deliveryID {
		t.Fatalf("expected delivery_id %s, got %s", deliveryID, invoice.DeliveryID)
	}

	if invoice.RemainingAmount != 120 {
		t.Fatalf("expected remaining_amount 120, got %v", invoice.RemainingAmount)
	}

	if line.SalesInvoiceLineID == "" {
		t.Fatal("expected sales_invoice_line_id")
	}

	if line.SalesInvoiceID != invoice.SalesInvoiceID {
		t.Fatalf("expected sales_invoice_id %s, got %s", invoice.SalesInvoiceID, line.SalesInvoiceID)
	}

	got, err := invoiceRepo.GetSalesInvoiceByID(ctx, "tenant_7", invoice.SalesInvoiceID)
	if err != nil {
		t.Fatalf("get sales invoice: %v", err)
	}

	if got.SalesInvoiceID != invoice.SalesInvoiceID {
		t.Fatalf("expected sales_invoice_id %s, got %s", invoice.SalesInvoiceID, got.SalesInvoiceID)
	}

	list, err := invoiceRepo.ListSalesInvoices(ctx, "tenant_7", ListSalesInvoicesFilter{
		CustomerID:   customerID,
		SalesOrderID: salesOrderID,
		DeliveryID:   deliveryID,
		Query:        unique,
		Status:       SalesInvoiceStatusDraft,
		Limit:        10,
	})
	if err != nil {
		t.Fatalf("list sales invoices: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 sales invoice in list, got %d", len(list))
	}

	lines, err := invoiceRepo.ListSalesInvoiceLines(ctx, "tenant_7", invoice.SalesInvoiceID)
	if err != nil {
		t.Fatalf("list sales invoice lines: %v", err)
	}

	if len(lines) != 1 {
		t.Fatalf("expected 1 sales invoice line, got %d", len(lines))
	}

	_, err = invoiceRepo.GetSalesInvoiceByID(ctx, "tenant_99", invoice.SalesInvoiceID)
	if !errors.Is(err, ErrSalesInvoiceNotFound) {
		t.Fatalf("expected ErrSalesInvoiceNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresSalesInvoiceRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresSalesInvoiceRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresSalesInvoiceRepository(pool)

	_, err = repo.CreateSalesInvoice(ctx, CreateSalesInvoiceInput{
		TenantID:        "tenant_7",
		CustomerID:      "customer-id",
		PartyID:         "party-id",
		InvoiceType:     SalesInvoiceTypeSales,
		ExchangeRate:    1,
		TotalAmount:     120,
		RemainingAmount: 120,
	})

	if !errors.Is(err, ErrSalesInvoiceNoRequired) {
		t.Fatalf("expected ErrSalesInvoiceNoRequired, got %v", err)
	}
}

func createSalesInvoiceFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) (string, string, string, string, string, string, string, string, string) {
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
    'faz3_sales_invoice_test'
)
RETURNING party_id::text;
`, tenantID, "Invoice Fixture "+unique, "Invoice Fixture Ltd "+unique, "INV"+unique, "invoice_"+unique+"@example.com").Scan(&partyID); err != nil {
		t.Fatalf("fixture party failed: %v", err)
	}

	var customerID string
	if err := tx.QueryRow(ctx, `
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
    $1,
    $2,
    $3,
    'TRY',
    true,
    'active',
    'faz3_sales_invoice_test'
)
RETURNING customer_id::text;
`, tenantID, partyID, "INV-CUST-"+unique).Scan(&customerID); err != nil {
		t.Fatalf("fixture customer failed: %v", err)
	}

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
    'faz3_sales_invoice_test'
)
RETURNING unit_id::text;
`, tenantID, "INV-UNIT-"+unique, "Invoice Unit "+unique).Scan(&unitID); err != nil {
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
    'faz3_sales_invoice_test'
)
RETURNING item_id::text;
`, tenantID, "INV-ITEM-"+unique, "Invoice Item "+unique, unitID, "INV-BAR-"+unique, "INV-SKU-"+unique).Scan(&itemID); err != nil {
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
    'faz3_sales_invoice_test'
)
RETURNING warehouse_id::text;
`, tenantID, "INV-WH-"+unique, "Invoice Warehouse "+unique).Scan(&warehouseID); err != nil {
		t.Fatalf("fixture warehouse failed: %v", err)
	}

	var salesOrderID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_sales_orders (
    tenant_id,
    sales_order_no,
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
    $1,
    $2,
    $3,
    $4,
    CURRENT_DATE,
    100.00,
    20.00,
    120.00,
    'draft',
    'faz3_sales_invoice_test'
)
RETURNING sales_order_id::text;
`, tenantID, "INV-SO-"+unique, customerID, partyID).Scan(&salesOrderID); err != nil {
		t.Fatalf("fixture sales order failed: %v", err)
	}

	var salesOrderLineID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_sales_order_lines (
    tenant_id,
    sales_order_id,
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
    'faz3_sales_invoice_test'
)
RETURNING sales_order_line_id::text;
`, tenantID, salesOrderID, itemID, unitID, "Invoice fixture sales order line "+unique).Scan(&salesOrderLineID); err != nil {
		t.Fatalf("fixture sales order line failed: %v", err)
	}

	var deliveryID string
	if err := tx.QueryRow(ctx, `
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
    $1,
    $2,
    $3,
    $4,
    $5,
    $6,
    CURRENT_DATE,
    CURRENT_DATE,
    'draft',
    'faz3_sales_invoice_test'
)
RETURNING delivery_id::text;
`, tenantID, "INV-DEL-"+unique, salesOrderID, customerID, partyID, warehouseID).Scan(&deliveryID); err != nil {
		t.Fatalf("fixture sales delivery failed: %v", err)
	}

	var deliveryLineID string
	if err := tx.QueryRow(ctx, `
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
    $1,
    $2,
    $3,
    1,
    $4,
    $5,
    $6,
    1.000000,
    'faz3_sales_invoice_test'
)
RETURNING delivery_line_id::text;
`, tenantID, deliveryID, salesOrderLineID, itemID, unitID, "Invoice fixture delivery line "+unique).Scan(&deliveryLineID); err != nil {
		t.Fatalf("fixture delivery line failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("fixture commit failed: %v", err)
	}

	return partyID, customerID, unitID, itemID, warehouseID, salesOrderID, salesOrderLineID, deliveryID, deliveryLineID
}

func cleanupSalesInvoiceFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, salesInvoiceID string, salesInvoiceLineID string, deliveryID string, deliveryLineID string, salesOrderID string, salesOrderLineID string, warehouseID string, customerID string, partyID string, itemID string, unitID string) {
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

	if salesInvoiceLineID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_sales_invoice_lines WHERE sales_invoice_line_id = $1;", salesInvoiceLineID); err != nil {
			t.Logf("cleanup invoice line failed: %v", err)
			return
		}
	}

	if salesInvoiceID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_sales_invoices WHERE sales_invoice_id = $1;", salesInvoiceID); err != nil {
			t.Logf("cleanup invoice failed: %v", err)
			return
		}
	}

	if deliveryLineID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_sales_delivery_lines WHERE delivery_line_id = $1;", deliveryLineID); err != nil {
			t.Logf("cleanup delivery line failed: %v", err)
			return
		}
	}

	if deliveryID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_sales_deliveries WHERE delivery_id = $1;", deliveryID); err != nil {
			t.Logf("cleanup delivery failed: %v", err)
			return
		}
	}

	if salesOrderLineID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_sales_order_lines WHERE sales_order_line_id = $1;", salesOrderLineID); err != nil {
			t.Logf("cleanup sales order line failed: %v", err)
			return
		}
	}

	if salesOrderID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_sales_orders WHERE sales_order_id = $1;", salesOrderID); err != nil {
			t.Logf("cleanup sales order failed: %v", err)
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

	if customerID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_customers WHERE customer_id = $1;", customerID); err != nil {
			t.Logf("cleanup customer failed: %v", err)
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
