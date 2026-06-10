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

func postgresSalesQuotationRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping sales quotation repository integration test")
	}

	return dsn
}

func TestPostgresSalesQuotationRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresSalesQuotationRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresSalesQuotationRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	partyID, customerID, unitID, itemID := createSalesQuotationFixture(t, pool, "tenant_7", unique)

	quotationNo := "QT-REPO-" + unique

	quotation, err := repo.CreateSalesQuotation(ctx, CreateSalesQuotationInput{
		TenantID:       "tenant_7",
		QuotationNo:    quotationNo,
		CustomerID:     customerID,
		PartyID:        partyID,
		DocumentDate:   time.Now().UTC(),
		CurrencyCode:   "TRY",
		ExchangeRate:   1,
		SubtotalAmount: 100,
		DiscountAmount: 0,
		VATAmount:      20,
		TotalAmount:    120,
		Note:           "FAZ3 sales quotation repository test " + unique,
		CreatedBy:      "faz3_test",
	})
	if err != nil {
		cleanupSalesQuotationFixture(t, pool, "tenant_7", "", "", customerID, partyID, itemID, unitID)
		t.Fatalf("create sales quotation: %v", err)
	}

	line, err := repo.CreateSalesQuotationLine(ctx, CreateSalesQuotationLineInput{
		TenantID:       "tenant_7",
		QuotationID:    quotation.QuotationID,
		LineNo:         1,
		ItemID:         itemID,
		UnitID:         unitID,
		Description:    "FAZ3 sales quotation line test " + unique,
		Quantity:       1,
		UnitPrice:      100,
		DiscountRate:   0,
		DiscountAmount: 0,
		VATRate:        20,
		VATAmount:      20,
		LineTotal:      120,
		CreatedBy:      "faz3_test",
	})
	if err != nil {
		cleanupSalesQuotationFixture(t, pool, "tenant_7", quotation.QuotationID, "", customerID, partyID, itemID, unitID)
		t.Fatalf("create sales quotation line: %v", err)
	}

	defer cleanupSalesQuotationFixture(t, pool, "tenant_7", quotation.QuotationID, line.QuotationLineID, customerID, partyID, itemID, unitID)

	if quotation.QuotationID == "" {
		t.Fatal("expected quotation_id")
	}

	if quotation.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", quotation.TenantID)
	}

	if quotation.QuotationNo != quotationNo {
		t.Fatalf("expected quotation_no %s, got %s", quotationNo, quotation.QuotationNo)
	}

	if line.QuotationLineID == "" {
		t.Fatal("expected quotation_line_id")
	}

	if line.QuotationID != quotation.QuotationID {
		t.Fatalf("expected quotation_id %s, got %s", quotation.QuotationID, line.QuotationID)
	}

	got, err := repo.GetSalesQuotationByID(ctx, "tenant_7", quotation.QuotationID)
	if err != nil {
		t.Fatalf("get sales quotation: %v", err)
	}

	if got.QuotationID != quotation.QuotationID {
		t.Fatalf("expected quotation_id %s, got %s", quotation.QuotationID, got.QuotationID)
	}

	list, err := repo.ListSalesQuotations(ctx, "tenant_7", ListSalesQuotationsFilter{
		CustomerID: customerID,
		Query:      unique,
		Status:     SalesQuotationStatusDraft,
		Limit:      10,
	})
	if err != nil {
		t.Fatalf("list sales quotations: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 quotation in list, got %d", len(list))
	}

	lines, err := repo.ListSalesQuotationLines(ctx, "tenant_7", quotation.QuotationID)
	if err != nil {
		t.Fatalf("list sales quotation lines: %v", err)
	}

	if len(lines) != 1 {
		t.Fatalf("expected 1 quotation line, got %d", len(lines))
	}

	_, err = repo.GetSalesQuotationByID(ctx, "tenant_99", quotation.QuotationID)
	if !errors.Is(err, ErrSalesQuotationNotFound) {
		t.Fatalf("expected ErrSalesQuotationNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresSalesQuotationRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresSalesQuotationRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresSalesQuotationRepository(pool)

	_, err = repo.CreateSalesQuotation(ctx, CreateSalesQuotationInput{
		TenantID:     "tenant_7",
		CustomerID:   "customer-id",
		PartyID:      "party-id",
		ExchangeRate: 1,
	})

	if !errors.Is(err, ErrQuotationNoRequired) {
		t.Fatalf("expected ErrQuotationNoRequired, got %v", err)
	}
}

func createSalesQuotationFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) (string, string, string, string) {
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
    'faz3_sales_quotation_test'
)
RETURNING party_id::text;
`, tenantID, "Quotation Fixture "+unique, "Quotation Fixture Ltd "+unique, "QT"+unique, "quotation_"+unique+"@example.com").Scan(&partyID); err != nil {
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
    'faz3_sales_quotation_test'
)
RETURNING customer_id::text;
`, tenantID, partyID, "QT-CUST-"+unique).Scan(&customerID); err != nil {
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
    'faz3_sales_quotation_test'
)
RETURNING unit_id::text;
`, tenantID, "QT-UNIT-"+unique, "Quotation Unit "+unique).Scan(&unitID); err != nil {
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
    'faz3_sales_quotation_test'
)
RETURNING item_id::text;
`, tenantID, "QT-ITEM-"+unique, "Quotation Item "+unique, unitID, "QT-BAR-"+unique, "QT-SKU-"+unique).Scan(&itemID); err != nil {
		t.Fatalf("fixture item failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("fixture commit failed: %v", err)
	}

	return partyID, customerID, unitID, itemID
}

func cleanupSalesQuotationFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, quotationID string, quotationLineID string, customerID string, partyID string, itemID string, unitID string) {
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
