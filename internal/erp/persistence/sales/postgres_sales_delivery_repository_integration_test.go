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

func postgresSalesDeliveryRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping sales delivery repository integration test")
	}

	return dsn
}

func TestPostgresSalesDeliveryRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresSalesDeliveryRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	deliveryRepo := NewPostgresSalesDeliveryRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	partyID, customerID, unitID, itemID, warehouseID, salesOrderID, salesOrderLineID := createSalesDeliveryFixture(t, pool, "tenant_7", unique)

	deliveryNo := "DEL-REPO-" + unique
	deliveryDate := time.Now().UTC()

	delivery, err := deliveryRepo.CreateSalesDelivery(ctx, CreateSalesDeliveryInput{
		TenantID:     "tenant_7",
		DeliveryNo:   deliveryNo,
		SalesOrderID: salesOrderID,
		CustomerID:   customerID,
		PartyID:      partyID,
		WarehouseID:  warehouseID,
		DocumentDate: time.Now().UTC(),
		DeliveryDate: &deliveryDate,
		Note:         "FAZ3 sales delivery repository test " + unique,
		CreatedBy:    "faz3_test",
	})
	if err != nil {
		cleanupSalesDeliveryFixture(t, pool, "tenant_7", "", "", salesOrderID, salesOrderLineID, warehouseID, customerID, partyID, itemID, unitID)
		t.Fatalf("create sales delivery: %v", err)
	}

	line, err := deliveryRepo.CreateSalesDeliveryLine(ctx, CreateSalesDeliveryLineInput{
		TenantID:         "tenant_7",
		DeliveryID:       delivery.DeliveryID,
		SalesOrderLineID: salesOrderLineID,
		LineNo:           1,
		ItemID:           itemID,
		UnitID:           unitID,
		Description:      "FAZ3 sales delivery line test " + unique,
		Quantity:         1,
		CreatedBy:        "faz3_test",
	})
	if err != nil {
		cleanupSalesDeliveryFixture(t, pool, "tenant_7", delivery.DeliveryID, "", salesOrderID, salesOrderLineID, warehouseID, customerID, partyID, itemID, unitID)
		t.Fatalf("create sales delivery line: %v", err)
	}

	defer cleanupSalesDeliveryFixture(t, pool, "tenant_7", delivery.DeliveryID, line.DeliveryLineID, salesOrderID, salesOrderLineID, warehouseID, customerID, partyID, itemID, unitID)

	if delivery.DeliveryID == "" {
		t.Fatal("expected delivery_id")
	}

	if delivery.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", delivery.TenantID)
	}

	if delivery.DeliveryNo != deliveryNo {
		t.Fatalf("expected delivery_no %s, got %s", deliveryNo, delivery.DeliveryNo)
	}

	if delivery.SalesOrderID != salesOrderID {
		t.Fatalf("expected sales_order_id %s, got %s", salesOrderID, delivery.SalesOrderID)
	}

	if delivery.WarehouseID != warehouseID {
		t.Fatalf("expected warehouse_id %s, got %s", warehouseID, delivery.WarehouseID)
	}

	if line.DeliveryLineID == "" {
		t.Fatal("expected delivery_line_id")
	}

	if line.DeliveryID != delivery.DeliveryID {
		t.Fatalf("expected delivery_id %s, got %s", delivery.DeliveryID, line.DeliveryID)
	}

	got, err := deliveryRepo.GetSalesDeliveryByID(ctx, "tenant_7", delivery.DeliveryID)
	if err != nil {
		t.Fatalf("get sales delivery: %v", err)
	}

	if got.DeliveryID != delivery.DeliveryID {
		t.Fatalf("expected delivery_id %s, got %s", delivery.DeliveryID, got.DeliveryID)
	}

	list, err := deliveryRepo.ListSalesDeliveries(ctx, "tenant_7", ListSalesDeliveriesFilter{
		CustomerID:   customerID,
		SalesOrderID: salesOrderID,
		WarehouseID:  warehouseID,
		Query:        unique,
		Status:       SalesDeliveryStatusDraft,
		Limit:        10,
	})
	if err != nil {
		t.Fatalf("list sales deliveries: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 sales delivery in list, got %d", len(list))
	}

	lines, err := deliveryRepo.ListSalesDeliveryLines(ctx, "tenant_7", delivery.DeliveryID)
	if err != nil {
		t.Fatalf("list sales delivery lines: %v", err)
	}

	if len(lines) != 1 {
		t.Fatalf("expected 1 sales delivery line, got %d", len(lines))
	}

	_, err = deliveryRepo.GetSalesDeliveryByID(ctx, "tenant_99", delivery.DeliveryID)
	if !errors.Is(err, ErrSalesDeliveryNotFound) {
		t.Fatalf("expected ErrSalesDeliveryNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresSalesDeliveryRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresSalesDeliveryRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresSalesDeliveryRepository(pool)

	_, err = repo.CreateSalesDelivery(ctx, CreateSalesDeliveryInput{
		TenantID:   "tenant_7",
		DeliveryNo: "DEL-001",
		CustomerID: "customer-id",
		PartyID:    "party-id",
	})

	if !errors.Is(err, ErrWarehouseIDRequired) {
		t.Fatalf("expected ErrWarehouseIDRequired, got %v", err)
	}
}

func createSalesDeliveryFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) (string, string, string, string, string, string, string) {
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
    'faz3_sales_delivery_test'
)
RETURNING party_id::text;
`, tenantID, "Delivery Fixture "+unique, "Delivery Fixture Ltd "+unique, "DEL"+unique, "delivery_"+unique+"@example.com").Scan(&partyID); err != nil {
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
    'faz3_sales_delivery_test'
)
RETURNING customer_id::text;
`, tenantID, partyID, "DEL-CUST-"+unique).Scan(&customerID); err != nil {
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
    'faz3_sales_delivery_test'
)
RETURNING unit_id::text;
`, tenantID, "DEL-UNIT-"+unique, "Delivery Unit "+unique).Scan(&unitID); err != nil {
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
    'faz3_sales_delivery_test'
)
RETURNING item_id::text;
`, tenantID, "DEL-ITEM-"+unique, "Delivery Item "+unique, unitID, "DEL-BAR-"+unique, "DEL-SKU-"+unique).Scan(&itemID); err != nil {
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
    'faz3_sales_delivery_test'
)
RETURNING warehouse_id::text;
`, tenantID, "DEL-WH-"+unique, "Delivery Warehouse "+unique).Scan(&warehouseID); err != nil {
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
    'faz3_sales_delivery_test'
)
RETURNING sales_order_id::text;
`, tenantID, "DEL-SO-"+unique, customerID, partyID).Scan(&salesOrderID); err != nil {
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
    'faz3_sales_delivery_test'
)
RETURNING sales_order_line_id::text;
`, tenantID, salesOrderID, itemID, unitID, "Delivery fixture sales order line "+unique).Scan(&salesOrderLineID); err != nil {
		t.Fatalf("fixture sales order line failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("fixture commit failed: %v", err)
	}

	return partyID, customerID, unitID, itemID, warehouseID, salesOrderID, salesOrderLineID
}

func cleanupSalesDeliveryFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, deliveryID string, deliveryLineID string, salesOrderID string, salesOrderLineID string, warehouseID string, customerID string, partyID string, itemID string, unitID string) {
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
