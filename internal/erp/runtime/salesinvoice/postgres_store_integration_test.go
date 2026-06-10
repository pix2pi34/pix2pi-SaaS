package salesinvoice

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

func postgresSalesInvoiceStoreTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping sales invoice postgres store integration test")
	}

	return dsn
}

func TestPostgresSalesInvoiceStorePersistAndMarkPosted(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresSalesInvoiceStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresSalesInvoiceStore(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	invoiceNo := "INV-RUNTIME-" + unique

	headerTable := detectSalesInvoiceHeaderTableForTest(t, pool)
	lineTable := detectSalesInvoiceLineTableForTest(t, pool)

	partyID, customerID := createRuntimeSalesInvoiceCustomerFixture(t, pool, "tenant_7", unique)
	defer cleanupRuntimeSalesInvoiceCustomerFixture(t, pool, "tenant_7", partyID, customerID)

	unitID := createRuntimeSalesInvoiceUnitFixture(t, pool, "tenant_7", unique)
	defer cleanupRuntimeSalesInvoiceUnitFixture(t, pool, "tenant_7", unitID)

	itemID := createRuntimeSalesInvoiceItemFixture(t, pool, "tenant_7", unitID, unique)
	defer cleanupRuntimeSalesInvoiceItemFixture(t, pool, "tenant_7", itemID)

	cleanupRuntimeSalesInvoiceFixture(t, pool, headerTable, lineTable, "tenant_7", invoiceNo)
	defer cleanupRuntimeSalesInvoiceFixture(t, pool, headerTable, lineTable, "tenant_7", invoiceNo)

	req := validSalesInvoiceRequest()
	req.Tenant.TenantID = "tenant_7"
	req.Tenant.RequestID = "req-" + unique
	req.InvoiceNo = invoiceNo
	req.Customer.PartyID = partyID
	req.Customer.CustomerID = customerID
	req.Customer.CustomerCode = "CARI-" + unique[len(unique)-6:]
	req.Customer.CustomerName = "Runtime Test Musteri " + unique[len(unique)-6:]
	req.Fiscal.FiscalYear = 2026
	req.Fiscal.FiscalPeriod = "2026-04"
	req.Fiscal.InvoiceDate = time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC)
	req.Fiscal.PostingDate = time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC)
	req.Money.CurrencyCode = "TRY"
	req.Money.ExchangeRate = 1
	req.Lines[0].Product.ItemID = itemID
	req.Lines[0].Product.ProductID = ""
	req.Lines[0].Product.UnitID = unitID
	req.Lines[0].Product.ProductCode = "URUN-" + unique[len(unique)-6:]
	req.Lines[0].Product.ProductName = "Runtime Test Urun " + unique[len(unique)-6:]
	req.Description = "Runtime sales invoice integration " + unique

	draft, err := BuildSalesInvoiceDraft(req)
	if err != nil {
		t.Fatalf("build sales invoice draft: %v", err)
	}

	persistedDraft, err := store.PersistSalesInvoiceDraft(ctx, draft)
	if err != nil {
		t.Fatalf("persist sales invoice draft: %v", err)
	}

	if persistedDraft.Status != InvoiceStatusDraft {
		t.Fatalf("expected draft status, got %s", persistedDraft.Status)
	}

	headerCount := countRuntimeSalesInvoiceHeaders(t, pool, headerTable, "tenant_7", invoiceNo)
	if headerCount != 1 {
		t.Fatalf("expected 1 sales invoice header, got %d", headerCount)
	}

	lineCount := countRuntimeSalesInvoiceLines(t, pool, headerTable, lineTable, "tenant_7", invoiceNo)
	if lineCount < 1 {
		t.Fatalf("expected at least 1 sales invoice line, got %d", lineCount)
	}

	postedDraft, err := store.MarkSalesInvoicePosted(ctx, persistedDraft)
	if err != nil {
		t.Fatalf("mark sales invoice posted: %v", err)
	}

	if postedDraft.Status != InvoiceStatusPosted {
		t.Fatalf("expected posted status, got %s", postedDraft.Status)
	}

	status := getRuntimeSalesInvoiceStatus(t, pool, headerTable, "tenant_7", invoiceNo)
	if status == "" {
		t.Log("sales invoice status column yok veya bos; status check atlandi")
	}
}

func TestPostgresSalesInvoiceStoreValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresSalesInvoiceStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresSalesInvoiceStore(pool)

	req := validSalesInvoiceRequest()
	req.Tenant.TenantID = ""

	draft := SalesInvoiceDraft{
		TenantID:  req.Tenant.TenantID,
		InvoiceNo: req.InvoiceNo,
		Status:    InvoiceStatusDraft,
		Fiscal:    req.Fiscal,
		Customer:  req.Customer,
		Money:     req.Money,
	}

	_, err = store.PersistSalesInvoiceDraft(ctx, draft)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func detectSalesInvoiceHeaderTableForTest(t *testing.T, pool *pgxpool.Pool) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("detect header table begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	tableName, err := detectSalesInvoiceHeaderTable(ctx, tx)
	if err != nil {
		t.Skipf("sales invoice header table bulunamadi: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("detect header table commit failed: %v", err)
	}

	return tableName
}

func detectSalesInvoiceLineTableForTest(t *testing.T, pool *pgxpool.Pool) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("detect line table begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	tableName, err := detectSalesInvoiceLineTable(ctx, tx)
	if err != nil {
		t.Skipf("sales invoice line table bulunamadi: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("detect line table commit failed: %v", err)
	}

	return tableName
}

func createRuntimeSalesInvoiceCustomerFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) (string, string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("customer fixture begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("customer fixture set tenant failed: %v", err)
	}

	partyID := createRuntimeSalesInvoicePartyFixture(t, ctx, tx, tenantID, unique)
	customerID := createRuntimeSalesInvoiceCustomerRowFixture(t, ctx, tx, tenantID, partyID, unique)

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("customer fixture commit failed: %v", err)
	}

	return partyID, customerID
}

func createRuntimeSalesInvoicePartyFixture(t *testing.T, ctx context.Context, tx pgx.Tx, tenantID string, unique string) string {
	t.Helper()

	tableName := detectOptionalSalesInvoiceTable(t, ctx, tx, []string{"erp_parties", "erp_party", "parties"})
	if tableName == "" {
		return ""
	}

	columns, err := loadSalesInvoiceTableColumns(ctx, tx, tableName)
	if err != nil {
		t.Fatalf("party fixture load columns failed: %v", err)
	}

	names := make([]string, 0)
	values := make([]any, 0)

	add := func(column string, value any) {
		if _, ok := columns[column]; !ok {
			return
		}
		names = append(names, column)
		values = append(values, value)
	}

	code := "PTY-" + unique[len(unique)-6:]
	name := "Runtime Test Cari " + unique[len(unique)-6:]

	add("tenant_id", tenantID)
	add("party_code", code)
	add("code", code)
	add("party_no", code)
	add("party_name", name)
	add("name", name)
	add("display_name", name)
	add("title", name)
	add("party_type", "organization")
	add("type", "organization")
	add("tax_no", "1234567890")
	add("tax_number", "1234567890")
	add("tax_office", "Istanbul")
	add("is_active", true)
	add("status", "active")
	add("description", "Runtime sales invoice party fixture "+unique)
	add("created_by", "faz3_salesinvoice_runtime_test")
	add("updated_by", "faz3_salesinvoice_runtime_test")

	idColumn := ""
	for _, candidate := range []string{"party_id", "id"} {
		if _, ok := columns[candidate]; ok {
			idColumn = candidate
			break
		}
	}

	if idColumn == "" {
		return ""
	}

	sql := buildSalesInvoiceInsertSQL(tableName, names, " RETURNING "+idColumn+"::text")

	var partyID string
	if err := tx.QueryRow(ctx, sql, values...).Scan(&partyID); err != nil {
		t.Fatalf("party fixture insert failed: %v", err)
	}

	return partyID
}

func createRuntimeSalesInvoiceCustomerRowFixture(t *testing.T, ctx context.Context, tx pgx.Tx, tenantID string, partyID string, unique string) string {
	t.Helper()

	tableName := detectOptionalSalesInvoiceTable(t, ctx, tx, []string{"erp_customers", "erp_customer", "customers"})
	if tableName == "" {
		t.Fatal("customer table bulunamadi")
	}

	columns, err := loadSalesInvoiceTableColumns(ctx, tx, tableName)
	if err != nil {
		t.Fatalf("customer fixture load columns failed: %v", err)
	}

	names := make([]string, 0)
	values := make([]any, 0)

	add := func(column string, value any) {
		if _, ok := columns[column]; !ok {
			return
		}
		names = append(names, column)
		values = append(values, value)
	}

	addUUID := func(column string, value string) {
		if _, ok := columns[column]; !ok {
			return
		}
		names = append(names, column)
		values = append(values, salesInvoiceNullableUUID(columns[column], value))
	}

	code := "CARI-" + unique[len(unique)-6:]
	name := "Runtime Test Musteri " + unique[len(unique)-6:]

	add("tenant_id", tenantID)
	addUUID("party_id", partyID)
	add("customer_code", code)
	add("code", code)
	add("account_code", code)
	add("customer_name", name)
	add("name", name)
	add("account_name", name)
	add("display_name", name)
	add("tax_no", "1234567890")
	add("tax_number", "1234567890")
	add("tax_office", "Istanbul")
	add("is_active", true)
	add("status", "active")
	add("description", "Runtime sales invoice customer fixture "+unique)
	add("created_by", "faz3_salesinvoice_runtime_test")
	add("updated_by", "faz3_salesinvoice_runtime_test")

	idColumn := ""
	for _, candidate := range []string{"customer_id", "id"} {
		if _, ok := columns[candidate]; ok {
			idColumn = candidate
			break
		}
	}

	if idColumn == "" {
		t.Fatal("customer id column bulunamadi")
	}

	sql := buildSalesInvoiceInsertSQL(tableName, names, " RETURNING "+idColumn+"::text")

	var customerID string
	if err := tx.QueryRow(ctx, sql, values...).Scan(&customerID); err != nil {
		t.Fatalf("customer fixture insert failed: %v", err)
	}

	return customerID
}

func createRuntimeSalesInvoiceUnitFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("unit fixture begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("unit fixture set tenant failed: %v", err)
	}

	tableName := detectOptionalSalesInvoiceTable(t, ctx, tx, []string{"erp_units", "erp_unit", "units"})
	if tableName == "" {
		t.Fatal("unit table bulunamadi")
	}

	columns, err := loadSalesInvoiceTableColumns(ctx, tx, tableName)
	if err != nil {
		t.Fatalf("unit fixture load columns failed: %v", err)
	}

	names := make([]string, 0)
	values := make([]any, 0)

	add := func(column string, value any) {
		if _, ok := columns[column]; !ok {
			return
		}

		names = append(names, column)
		values = append(values, value)
	}

	code := "ADET" + unique[len(unique)-4:]
	name := "Runtime Test Birim " + unique[len(unique)-4:]

	add("tenant_id", tenantID)
	add("unit_code", code)
	add("code", code)
	add("symbol", "ADT")
	add("unit_name", name)
	add("name", name)
	add("description", "Runtime sales invoice unit fixture "+unique)
	add("decimal_places", 2)
	add("precision", 2)
	add("is_active", true)

	if _, ok := columns["status"]; ok {
		status, err := salesInvoiceAllowedValueForColumn(ctx, tx, tableName, "status", []string{"active", "enabled", "draft", "created"}, "active")
		if err != nil {
			t.Fatalf("unit status value detect failed: %v", err)
		}
		add("status", status)
	}

	add("created_by", "faz3_salesinvoice_runtime_test")
	add("updated_by", "faz3_salesinvoice_runtime_test")

	idColumn := ""
	for _, candidate := range []string{"unit_id", "id"} {
		if _, ok := columns[candidate]; ok {
			idColumn = candidate
			break
		}
	}

	if idColumn == "" {
		t.Fatal("unit id column bulunamadi")
	}

	if len(names) == 0 {
		t.Fatal("unit fixture no insert columns")
	}

	sql := buildSalesInvoiceInsertSQL(tableName, names, " RETURNING "+idColumn+"::text")

	var unitID string
	if err := tx.QueryRow(ctx, sql, values...).Scan(&unitID); err != nil {
		t.Fatalf("unit fixture insert failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("unit fixture commit failed: %v", err)
	}

	return unitID
}

func cleanupRuntimeSalesInvoiceUnitFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unitID string) {
	t.Helper()

	if strings.TrimSpace(unitID) == "" {
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Logf("unit cleanup begin failed: %v", err)
		return
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Logf("unit cleanup set tenant failed: %v", err)
		return
	}

	tableName := detectOptionalSalesInvoiceTable(t, ctx, tx, []string{"erp_units", "erp_unit", "units"})
	if tableName == "" {
		return
	}

	columns, err := loadSalesInvoiceTableColumns(ctx, tx, tableName)
	if err != nil {
		return
	}

	for _, candidate := range []string{"unit_id", "id"} {
		if _, ok := columns[candidate]; ok {
			_, _ = tx.Exec(ctx, fmt.Sprintf("DELETE FROM %s WHERE tenant_id = $1 AND %s = $2;", tableName, candidate), tenantID, unitID)
			break
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("unit cleanup commit failed: %v", err)
	}
}

func createRuntimeSalesInvoiceItemFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unitID string, unique string) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("item fixture begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("item fixture set tenant failed: %v", err)
	}

	tableName := detectOptionalSalesInvoiceTable(t, ctx, tx, []string{"erp_items", "erp_item", "items"})
	if tableName == "" {
		t.Fatal("item table bulunamadi")
	}

	columns, err := loadSalesInvoiceTableColumns(ctx, tx, tableName)
	if err != nil {
		t.Fatalf("item fixture load columns failed: %v", err)
	}

	names := make([]string, 0)
	values := make([]any, 0)

	add := func(column string, value any) {
		if _, ok := columns[column]; !ok {
			return
		}

		names = append(names, column)
		values = append(values, value)
	}

	code := "URUN-" + unique[len(unique)-6:]
	name := "Runtime Test Urun " + unique[len(unique)-6:]

	add("tenant_id", tenantID)
	addUUID := func(column string, value string) {
		if _, ok := columns[column]; !ok {
			return
		}

		names = append(names, column)
		values = append(values, salesInvoiceNullableUUID(columns[column], value))
	}

	addUUID("base_unit_id", unitID)
	add("item_code", code)
	add("code", code)
	add("sku", code)
	add("product_code", code)

	add("item_name", name)
	add("name", name)
	add("product_name", name)
	add("description", "Runtime sales invoice item fixture "+unique)

	if _, ok := columns["item_type"]; ok {
		itemType, err := salesInvoiceAllowedValueForColumn(ctx, tx, tableName, "item_type", []string{"product", "stock", "inventory", "goods", "service"}, "product")
		if err != nil {
			t.Fatalf("item_type value detect failed: %v", err)
		}
		add("item_type", itemType)
	}

	if _, ok := columns["type"]; ok {
		itemType, err := salesInvoiceAllowedValueForColumn(ctx, tx, tableName, "type", []string{"product", "stock", "inventory", "goods", "service"}, "product")
		if err != nil {
			t.Fatalf("type value detect failed: %v", err)
		}
		add("type", itemType)
	}

	add("unit_code", "ADET")
	add("base_unit_code", "ADET")
	add("sales_unit_code", "ADET")
	add("purchase_unit_code", "ADET")

	add("currency_code", "TRY")
	add("sales_price", 50)
	add("purchase_price", 0)
	add("unit_price", 50)
	add("tax_code", "KDV20")
	add("tax_rate", 20)

	add("is_active", true)

	if _, ok := columns["status"]; ok {
		status, err := salesInvoiceAllowedValueForColumn(ctx, tx, tableName, "status", []string{"active", "enabled", "draft", "created"}, "active")
		if err != nil {
			t.Fatalf("item status value detect failed: %v", err)
		}
		add("status", status)
	}

	add("created_by", "faz3_salesinvoice_runtime_test")
	add("updated_by", "faz3_salesinvoice_runtime_test")

	idColumn := ""
	for _, candidate := range []string{"item_id", "product_id", "id"} {
		if _, ok := columns[candidate]; ok {
			idColumn = candidate
			break
		}
	}

	if idColumn == "" {
		t.Fatal("item id column bulunamadi")
	}

	if len(names) == 0 {
		t.Fatal("item fixture no insert columns")
	}

	sql := buildSalesInvoiceInsertSQL(tableName, names, " RETURNING "+idColumn+"::text")

	var itemID string
	if err := tx.QueryRow(ctx, sql, values...).Scan(&itemID); err != nil {
		t.Fatalf("item fixture insert failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("item fixture commit failed: %v", err)
	}

	return itemID
}

func cleanupRuntimeSalesInvoiceItemFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, itemID string) {
	t.Helper()

	if strings.TrimSpace(itemID) == "" {
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Logf("item cleanup begin failed: %v", err)
		return
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Logf("item cleanup set tenant failed: %v", err)
		return
	}

	tableName := detectOptionalSalesInvoiceTable(t, ctx, tx, []string{"erp_items", "erp_item", "items"})
	if tableName == "" {
		return
	}

	columns, err := loadSalesInvoiceTableColumns(ctx, tx, tableName)
	if err != nil {
		return
	}

	for _, candidate := range []string{"item_id", "product_id", "id"} {
		if _, ok := columns[candidate]; ok {
			_, _ = tx.Exec(ctx, fmt.Sprintf("DELETE FROM %s WHERE tenant_id = $1 AND %s = $2;", tableName, candidate), tenantID, itemID)
			break
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("item cleanup commit failed: %v", err)
	}
}

func salesInvoiceAllowedValueForColumn(ctx context.Context, tx pgx.Tx, tableName string, columnName string, candidates []string, fallback string) (string, error) {
	values, err := salesInvoiceConstraintValuesForColumn(ctx, tx, tableName, columnName)
	if err != nil {
		return "", err
	}

	if len(values) == 0 {
		return fallback, nil
	}

	for _, candidate := range candidates {
		if salesInvoiceContainsValue(values, candidate) {
			return candidate, nil
		}
	}

	return values[0], nil
}

func cleanupRuntimeSalesInvoiceCustomerFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, partyID string, customerID string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Logf("customer cleanup begin failed: %v", err)
		return
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Logf("customer cleanup set tenant failed: %v", err)
		return
	}

	customerTable := detectOptionalSalesInvoiceTable(t, ctx, tx, []string{"erp_customers", "erp_customer", "customers"})
	if customerTable != "" && strings.TrimSpace(customerID) != "" {
		columns, err := loadSalesInvoiceTableColumns(ctx, tx, customerTable)
		if err == nil {
			for _, candidate := range []string{"customer_id", "id"} {
				if _, ok := columns[candidate]; ok {
					_, _ = tx.Exec(ctx, fmt.Sprintf("DELETE FROM %s WHERE tenant_id = $1 AND %s = $2;", customerTable, candidate), tenantID, customerID)
					break
				}
			}
		}
	}

	partyTable := detectOptionalSalesInvoiceTable(t, ctx, tx, []string{"erp_parties", "erp_party", "parties"})
	if partyTable != "" && strings.TrimSpace(partyID) != "" {
		columns, err := loadSalesInvoiceTableColumns(ctx, tx, partyTable)
		if err == nil {
			for _, candidate := range []string{"party_id", "id"} {
				if _, ok := columns[candidate]; ok {
					_, _ = tx.Exec(ctx, fmt.Sprintf("DELETE FROM %s WHERE tenant_id = $1 AND %s = $2;", partyTable, candidate), tenantID, partyID)
					break
				}
			}
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("customer cleanup commit failed: %v", err)
	}
}

func detectOptionalSalesInvoiceTable(t *testing.T, ctx context.Context, tx pgx.Tx, candidates []string) string {
	t.Helper()

	for _, tableName := range candidates {
		var exists bool
		if err := tx.QueryRow(ctx, `
SELECT EXISTS (
	SELECT 1
	FROM information_schema.tables
	WHERE table_schema = 'public'
	  AND table_name = $1
);
`, tableName).Scan(&exists); err != nil {
			t.Fatalf("optional table detect failed: %v", err)
		}

		if exists {
			return tableName
		}
	}

	return ""
}

func cleanupRuntimeSalesInvoiceFixture(t *testing.T, pool *pgxpool.Pool, headerTable string, lineTable string, tenantID string, invoiceNo string) {
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

	if strings.TrimSpace(lineTable) != "" {
		deleteSalesInvoiceLinesForInvoice(t, ctx, tx, headerTable, lineTable, tenantID, invoiceNo)
	}

	if strings.TrimSpace(headerTable) != "" {
		headerColumns, err := loadSalesInvoiceTableColumns(ctx, tx, headerTable)
		if err == nil {
			whereParts := []string{"tenant_id = $1"}
			args := []any{tenantID}
			addSalesInvoiceNoWhere(headerColumns, invoiceNo, &args, &whereParts)

			if len(whereParts) > 1 {
				sql := fmt.Sprintf("DELETE FROM %s WHERE %s;", headerTable, strings.Join(whereParts, " AND "))
				if _, err := tx.Exec(ctx, sql, args...); err != nil {
					t.Logf("cleanup sales invoice header failed: %v", err)
				}
			}
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
	}
}

func deleteSalesInvoiceLinesForInvoice(t *testing.T, ctx context.Context, tx pgx.Tx, headerTable string, lineTable string, tenantID string, invoiceNo string) {
	t.Helper()

	lineColumns, err := loadSalesInvoiceTableColumns(ctx, tx, lineTable)
	if err != nil {
		t.Logf("cleanup load line columns failed: %v", err)
		return
	}

	whereParts := []string{"tenant_id = $1"}
	args := []any{tenantID}

	if _, ok := lineColumns["invoice_no"]; ok {
		args = append(args, invoiceNo)
		whereParts = append(whereParts, fmt.Sprintf("invoice_no = $%d", len(args)))
	} else if _, ok := lineColumns["sales_invoice_no"]; ok {
		args = append(args, invoiceNo)
		whereParts = append(whereParts, fmt.Sprintf("sales_invoice_no = $%d", len(args)))
	} else if _, ok := lineColumns["document_no"]; ok {
		args = append(args, invoiceNo)
		whereParts = append(whereParts, fmt.Sprintf("document_no = $%d", len(args)))
	} else {
		invoiceID := findRuntimeSalesInvoiceID(t, ctx, tx, headerTable, tenantID, invoiceNo)
		if invoiceID == "" {
			return
		}

		if _, ok := lineColumns["sales_invoice_id"]; ok {
			args = append(args, invoiceID)
			whereParts = append(whereParts, fmt.Sprintf("sales_invoice_id = $%d", len(args)))
		} else if _, ok := lineColumns["invoice_id"]; ok {
			args = append(args, invoiceID)
			whereParts = append(whereParts, fmt.Sprintf("invoice_id = $%d", len(args)))
		} else if _, ok := lineColumns["document_id"]; ok {
			args = append(args, invoiceID)
			whereParts = append(whereParts, fmt.Sprintf("document_id = $%d", len(args)))
		}
	}

	if len(whereParts) <= 1 {
		return
	}

	sql := fmt.Sprintf("DELETE FROM %s WHERE %s;", lineTable, strings.Join(whereParts, " AND "))

	if _, err := tx.Exec(ctx, sql, args...); err != nil {
		t.Logf("cleanup sales invoice lines failed: %v", err)
	}
}

func findRuntimeSalesInvoiceID(t *testing.T, ctx context.Context, tx pgx.Tx, headerTable string, tenantID string, invoiceNo string) string {
	t.Helper()

	headerColumns, err := loadSalesInvoiceTableColumns(ctx, tx, headerTable)
	if err != nil {
		return ""
	}

	idColumn := salesInvoiceIDColumn(headerColumns)
	if idColumn == "" {
		return ""
	}

	whereParts := []string{"tenant_id = $1"}
	args := []any{tenantID}
	addSalesInvoiceNoWhere(headerColumns, invoiceNo, &args, &whereParts)

	if len(whereParts) <= 1 {
		return ""
	}

	query := fmt.Sprintf("SELECT %s::text FROM %s WHERE %s LIMIT 1;", idColumn, headerTable, strings.Join(whereParts, " AND "))

	var invoiceID string
	if err := tx.QueryRow(ctx, query, args...).Scan(&invoiceID); err != nil {
		return ""
	}

	return invoiceID
}

func countRuntimeSalesInvoiceHeaders(t *testing.T, pool *pgxpool.Pool, tableName string, tenantID string, invoiceNo string) int {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("count header begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("count header set tenant failed: %v", err)
	}

	columns, err := loadSalesInvoiceTableColumns(ctx, tx, tableName)
	if err != nil {
		t.Fatalf("count header load columns failed: %v", err)
	}

	whereParts := []string{"tenant_id = $1"}
	args := []any{tenantID}
	addSalesInvoiceNoWhere(columns, invoiceNo, &args, &whereParts)

	query := fmt.Sprintf("SELECT COUNT(*) FROM %s WHERE %s;", tableName, strings.Join(whereParts, " AND "))

	var count int
	if err := tx.QueryRow(ctx, query, args...).Scan(&count); err != nil {
		t.Fatalf("count header query failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("count header commit failed: %v", err)
	}

	return count
}

func countRuntimeSalesInvoiceLines(t *testing.T, pool *pgxpool.Pool, headerTable string, lineTable string, tenantID string, invoiceNo string) int {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("count line begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("count line set tenant failed: %v", err)
	}

	columns, err := loadSalesInvoiceTableColumns(ctx, tx, lineTable)
	if err != nil {
		t.Fatalf("count line load columns failed: %v", err)
	}

	whereParts := []string{"tenant_id = $1"}
	args := []any{tenantID}

	if _, ok := columns["invoice_no"]; ok {
		args = append(args, invoiceNo)
		whereParts = append(whereParts, fmt.Sprintf("invoice_no = $%d", len(args)))
	} else if _, ok := columns["sales_invoice_no"]; ok {
		args = append(args, invoiceNo)
		whereParts = append(whereParts, fmt.Sprintf("sales_invoice_no = $%d", len(args)))
	} else if _, ok := columns["document_no"]; ok {
		args = append(args, invoiceNo)
		whereParts = append(whereParts, fmt.Sprintf("document_no = $%d", len(args)))
	} else {
		invoiceID := findRuntimeSalesInvoiceID(t, ctx, tx, headerTable, tenantID, invoiceNo)
		if invoiceID != "" {
			if _, ok := columns["sales_invoice_id"]; ok {
				args = append(args, invoiceID)
				whereParts = append(whereParts, fmt.Sprintf("sales_invoice_id = $%d", len(args)))
			} else if _, ok := columns["invoice_id"]; ok {
				args = append(args, invoiceID)
				whereParts = append(whereParts, fmt.Sprintf("invoice_id = $%d", len(args)))
			} else if _, ok := columns["document_id"]; ok {
				args = append(args, invoiceID)
				whereParts = append(whereParts, fmt.Sprintf("document_id = $%d", len(args)))
			}
		}
	}

	query := fmt.Sprintf("SELECT COUNT(*) FROM %s WHERE %s;", lineTable, strings.Join(whereParts, " AND "))

	var count int
	if err := tx.QueryRow(ctx, query, args...).Scan(&count); err != nil {
		t.Fatalf("count line query failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("count line commit failed: %v", err)
	}

	return count
}

func getRuntimeSalesInvoiceStatus(t *testing.T, pool *pgxpool.Pool, tableName string, tenantID string, invoiceNo string) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("status begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("status set tenant failed: %v", err)
	}

	columns, err := loadSalesInvoiceTableColumns(ctx, tx, tableName)
	if err != nil {
		t.Fatalf("status load columns failed: %v", err)
	}

	statusColumn := salesInvoiceStatusColumn(columns)
	if strings.TrimSpace(statusColumn) == "" {
		return ""
	}

	whereParts := []string{"tenant_id = $1"}
	args := []any{tenantID}
	addSalesInvoiceNoWhere(columns, invoiceNo, &args, &whereParts)

	query := fmt.Sprintf(`
SELECT %s
FROM %s
WHERE %s
LIMIT 1;
`, statusColumn, tableName, strings.Join(whereParts, " AND "))

	var status string
	if err := tx.QueryRow(ctx, query, args...).Scan(&status); err != nil {
		t.Fatalf("status query failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("status commit failed: %v", err)
	}

	return status
}
