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

func postgresSalesOrderRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping sales order repository integration test")
	}

	return dsn
}

func TestPostgresSalesOrderRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresSalesOrderRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	orderRepo := NewPostgresSalesOrderRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	partyID, customerID, unitID, itemID, quotationID, quotationLineID := createSalesOrderFixture(t, pool, "tenant_7", unique)

	salesOrderNo := "SO-REPO-" + unique
	requestedDeliveryDate := time.Now().UTC().AddDate(0, 0, 3)

	order, err := orderRepo.CreateSalesOrder(ctx, CreateSalesOrderInput{
		TenantID:              "tenant_7",
		SalesOrderNo:          salesOrderNo,
		QuotationID:           quotationID,
		CustomerID:            customerID,
		PartyID:               partyID,
		DocumentDate:          time.Now().UTC(),
		RequestedDeliveryDate: &requestedDeliveryDate,
		CurrencyCode:          "TRY",
		ExchangeRate:          1,
		SubtotalAmount:        100,
		DiscountAmount:        0,
		VATAmount:             20,
		TotalAmount:           120,
		Note:                  "FAZ3 sales order repository test " + unique,
		CreatedBy:             "faz3_test",
	})
	if err != nil {
		cleanupSalesOrderFixture(t, pool, "tenant_7", "", "", quotationID, quotationLineID, customerID, partyID, itemID, unitID)
		t.Fatalf("create sales order: %v", err)
	}

	line, err := orderRepo.CreateSalesOrderLine(ctx, CreateSalesOrderLineInput{
		TenantID:          "tenant_7",
		SalesOrderID:      order.SalesOrderID,
		QuotationLineID:   quotationLineID,
		LineNo:            1,
		ItemID:            itemID,
		UnitID:            unitID,
		Description:       "FAZ3 sales order line test " + unique,
		Quantity:          1,
		DeliveredQuantity: 0,
		InvoicedQuantity:  0,
		UnitPrice:         100,
		DiscountRate:      0,
		DiscountAmount:    0,
		VATRate:           20,
		VATAmount:         20,
		LineTotal:         120,
		CreatedBy:         "faz3_test",
	})
	if err != nil {
		cleanupSalesOrderFixture(t, pool, "tenant_7", order.SalesOrderID, "", quotationID, quotationLineID, customerID, partyID, itemID, unitID)
		t.Fatalf("create sales order line: %v", err)
	}

	defer cleanupSalesOrderFixture(t, pool, "tenant_7", order.SalesOrderID, line.SalesOrderLineID, quotationID, quotationLineID, customerID, partyID, itemID, unitID)

	if order.SalesOrderID == "" {
		t.Fatal("expected sales_order_id")
	}

	if order.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", order.TenantID)
	}

	if order.SalesOrderNo != salesOrderNo {
		t.Fatalf("expected sales_order_no %s, got %s", salesOrderNo, order.SalesOrderNo)
	}

	if order.QuotationID != quotationID {
		t.Fatalf("expected quotation_id %s, got %s", quotationID, order.QuotationID)
	}

	if line.SalesOrderLineID == "" {
		t.Fatal("expected sales_order_line_id")
	}

	if line.SalesOrderID != order.SalesOrderID {
		t.Fatalf("expected sales_order_id %s, got %s", order.SalesOrderID, line.SalesOrderID)
	}

	got, err := orderRepo.GetSalesOrderByID(ctx, "tenant_7", order.SalesOrderID)
	if err != nil {
		t.Fatalf("get sales order: %v", err)
	}

	if got.SalesOrderID != order.SalesOrderID {
		t.Fatalf("expected sales_order_id %s, got %s", order.SalesOrderID, got.SalesOrderID)
	}

	list, err := orderRepo.ListSalesOrders(ctx, "tenant_7", ListSalesOrdersFilter{
		CustomerID:  customerID,
		QuotationID: quotationID,
		Query:       unique,
		Status:      SalesOrderStatusDraft,
		Limit:       10,
	})
	if err != nil {
		t.Fatalf("list sales orders: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 sales order in list, got %d", len(list))
	}

	lines, err := orderRepo.ListSalesOrderLines(ctx, "tenant_7", order.SalesOrderID)
	if err != nil {
		t.Fatalf("list sales order lines: %v", err)
	}

	if len(lines) != 1 {
		t.Fatalf("expected 1 sales order line, got %d", len(lines))
	}

	_, err = orderRepo.GetSalesOrderByID(ctx, "tenant_99", order.SalesOrderID)
	if !errors.Is(err, ErrSalesOrderNotFound) {
		t.Fatalf("expected ErrSalesOrderNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresSalesOrderRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresSalesOrderRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresSalesOrderRepository(pool)

	_, err = repo.CreateSalesOrder(ctx, CreateSalesOrderInput{
		TenantID:     "tenant_7",
		CustomerID:   "customer-id",
		PartyID:      "party-id",
		ExchangeRate: 1,
	})

	if !errors.Is(err, ErrSalesOrderNoRequired) {
		t.Fatalf("expected ErrSalesOrderNoRequired, got %v", err)
	}
}

func createSalesOrderFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) (string, string, string, string, string, string) {
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
    'faz3_sales_order_test'
)
RETURNING party_id::text;
`, tenantID, "Order Fixture "+unique, "Order Fixture Ltd "+unique, "SO"+unique, "order_"+unique+"@example.com").Scan(&partyID); err != nil {
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
    'faz3_sales_order_test'
)
RETURNING customer_id::text;
`, tenantID, partyID, "SO-CUST-"+unique).Scan(&customerID); err != nil {
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
    'faz3_sales_order_test'
)
RETURNING unit_id::text;
`, tenantID, "SO-UNIT-"+unique, "Order Unit "+unique).Scan(&unitID); err != nil {
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
    'faz3_sales_order_test'
)
RETURNING item_id::text;
`, tenantID, "SO-ITEM-"+unique, "Order Item "+unique, unitID, "SO-BAR-"+unique, "SO-SKU-"+unique).Scan(&itemID); err != nil {
		t.Fatalf("fixture item failed: %v", err)
	}

	var quotationID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_sales_quotations (
    tenant_id,
    quotation_no,
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
    'faz3_sales_order_test'
)
RETURNING quotation_id::text;
`, tenantID, "SO-QT-"+unique, customerID, partyID).Scan(&quotationID); err != nil {
		t.Fatalf("fixture quotation failed: %v", err)
	}

	var quotationLineID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_sales_quotation_lines (
    tenant_id,
    quotation_id,
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
    'faz3_sales_order_test'
)
RETURNING quotation_line_id::text;
`, tenantID, quotationID, itemID, unitID, "Order fixture quotation line "+unique).Scan(&quotationLineID); err != nil {
		t.Fatalf("fixture quotation line failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("fixture commit failed: %v", err)
	}

	return partyID, customerID, unitID, itemID, quotationID, quotationLineID
}

func cleanupSalesOrderFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, salesOrderID string, salesOrderLineID string, quotationID string, quotationLineID string, customerID string, partyID string, itemID string, unitID string) {
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

	if quotationLineID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_sales_quotation_lines WHERE quotation_line_id = $1;", quotationLineID); err != nil {
			t.Logf("cleanup quotation line failed: %v", err)
			return
		}
	}

	if quotationID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_sales_quotations WHERE quotation_id = $1;", quotationID); err != nil {
			t.Logf("cleanup quotation failed: %v", err)
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
