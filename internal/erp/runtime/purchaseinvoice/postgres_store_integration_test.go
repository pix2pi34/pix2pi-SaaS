package purchaseinvoice

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

func postgresPurchaseInvoiceStoreTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping purchase invoice postgres store integration test")
	}

	return dsn
}

func TestPostgresPurchaseInvoiceStorePersistAndMarkPosted(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresPurchaseInvoiceStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresPurchaseInvoiceStore(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	invoiceNo := "PINV-RUNTIME-" + unique

	headerTable := detectPurchaseInvoiceHeaderTableForTest(t, pool)
	lineTable := detectPurchaseInvoiceLineTableForTest(t, pool)

	partyID, vendorID := createRuntimePurchaseInvoiceVendorFixture(t, pool, "tenant_7", unique)
	defer cleanupRuntimePurchaseInvoiceVendorFixture(t, pool, "tenant_7", partyID, vendorID)

	unitID := createRuntimePurchaseInvoiceUnitFixture(t, pool, "tenant_7", unique)
	defer cleanupRuntimePurchaseInvoiceUnitFixture(t, pool, "tenant_7", unitID)

	itemID := createRuntimePurchaseInvoiceItemFixture(t, pool, "tenant_7", unitID, unique)
	defer cleanupRuntimePurchaseInvoiceItemFixture(t, pool, "tenant_7", itemID)

	cleanupRuntimePurchaseInvoiceFixture(t, pool, headerTable, lineTable, "tenant_7", invoiceNo)
	defer cleanupRuntimePurchaseInvoiceFixture(t, pool, headerTable, lineTable, "tenant_7", invoiceNo)

	req := validPurchaseInvoiceRequest()
	req.Tenant.TenantID = "tenant_7"
	req.Tenant.RequestID = "req-" + unique
	req.InvoiceNo = invoiceNo
	req.Vendor.PartyID = partyID
	req.Vendor.VendorID = vendorID
	req.Vendor.VendorCode = "SATICI-" + unique[len(unique)-6:]
	req.Vendor.VendorName = "Runtime Test Tedarikci " + unique[len(unique)-6:]
	req.Fiscal.FiscalYear = 2026
	req.Fiscal.FiscalPeriod = "2026-04"
	req.Fiscal.InvoiceDate = time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC)
	req.Fiscal.PostingDate = time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC)
	req.Money.CurrencyCode = "TRY"
	req.Money.ExchangeRate = 1
	req.Lines[0].Item.ItemID = itemID
	req.Lines[0].Item.ProductID = ""
	req.Lines[0].Item.UnitID = unitID
	req.Lines[0].Item.ItemCode = "URUN-" + unique[len(unique)-6:]
	req.Lines[0].Item.ItemName = "Runtime Test Urun " + unique[len(unique)-6:]
	req.Description = "Runtime purchase invoice integration " + unique

	draft, err := BuildPurchaseInvoiceDraft(req)
	if err != nil {
		t.Fatalf("build purchase invoice draft: %v", err)
	}

	persistedDraft, err := store.PersistPurchaseInvoiceDraft(ctx, draft)
	if err != nil {
		t.Fatalf("persist purchase invoice draft: %v", err)
	}

	if persistedDraft.Status != InvoiceStatusDraft {
		t.Fatalf("expected draft status, got %s", persistedDraft.Status)
	}

	headerCount := countRuntimePurchaseInvoiceHeaders(t, pool, headerTable, "tenant_7", invoiceNo)
	if headerCount != 1 {
		t.Fatalf("expected 1 purchase invoice header, got %d", headerCount)
	}

	lineCount := countRuntimePurchaseInvoiceLines(t, pool, headerTable, lineTable, "tenant_7", invoiceNo)
	if lineCount < 1 {
		t.Fatalf("expected at least 1 purchase invoice line, got %d", lineCount)
	}

	postedDraft, err := store.MarkPurchaseInvoicePosted(ctx, persistedDraft)
	if err != nil {
		t.Fatalf("mark purchase invoice posted: %v", err)
	}

	if postedDraft.Status != InvoiceStatusPosted {
		t.Fatalf("expected posted status, got %s", postedDraft.Status)
	}

	status := getRuntimePurchaseInvoiceStatus(t, pool, headerTable, "tenant_7", invoiceNo)
	if status == "" {
		t.Log("purchase invoice status column yok veya bos; status check atlandi")
	}
}

func TestPostgresPurchaseInvoiceStoreValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresPurchaseInvoiceStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresPurchaseInvoiceStore(pool)

	req := validPurchaseInvoiceRequest()
	req.Tenant.TenantID = ""

	draft := PurchaseInvoiceDraft{
		TenantID:  req.Tenant.TenantID,
		InvoiceNo: req.InvoiceNo,
		Status:    InvoiceStatusDraft,
		Fiscal:    req.Fiscal,
		Vendor:    req.Vendor,
		Money:     req.Money,
	}

	_, err = store.PersistPurchaseInvoiceDraft(ctx, draft)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func detectPurchaseInvoiceHeaderTableForTest(t *testing.T, pool *pgxpool.Pool) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("detect header table begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	tableName, err := detectPurchaseInvoiceHeaderTable(ctx, tx)
	if err != nil {
		t.Skipf("purchase invoice header table bulunamadi: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("detect header table commit failed: %v", err)
	}

	return tableName
}

func detectPurchaseInvoiceLineTableForTest(t *testing.T, pool *pgxpool.Pool) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("detect line table begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	tableName, err := detectPurchaseInvoiceLineTable(ctx, tx)
	if err != nil {
		t.Skipf("purchase invoice line table bulunamadi: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("detect line table commit failed: %v", err)
	}

	return tableName
}

func createRuntimePurchaseInvoiceVendorFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) (string, string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("vendor fixture begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("vendor fixture set tenant failed: %v", err)
	}

	partyID := createRuntimePurchaseInvoicePartyFixture(t, ctx, tx, tenantID, unique)
	vendorID := createRuntimePurchaseInvoiceVendorRowFixture(t, ctx, tx, tenantID, partyID, unique)

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("vendor fixture commit failed: %v", err)
	}

	return partyID, vendorID
}

func createRuntimePurchaseInvoicePartyFixture(t *testing.T, ctx context.Context, tx pgx.Tx, tenantID string, unique string) string {
	t.Helper()

	tableName := detectOptionalPurchaseInvoiceTable(t, ctx, tx, []string{"erp_parties", "erp_party", "parties"})
	if tableName == "" {
		return ""
	}

	columns, err := loadPurchaseInvoiceTableColumns(ctx, tx, tableName)
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
	name := "Runtime Test Tedarikci " + unique[len(unique)-6:]

	add("tenant_id", tenantID)
	add("party_code", code)
	add("code", code)
	add("party_no", code)
	add("party_name", name)
	add("name", name)
	add("display_name", name)
	add("title", name)

	if _, ok := columns["party_type"]; ok {
		partyType, err := purchaseInvoiceAllowedValueForColumn(ctx, tx, tableName, "party_type", []string{"organization", "company", "business", "person"}, "organization")
		if err != nil {
			t.Fatalf("party_type detect failed: %v", err)
		}
		add("party_type", partyType)
	}

	add("tax_no", "1234567890")
	add("tax_number", "1234567890")
	add("tax_office", "Istanbul")
	add("is_active", true)

	if _, ok := columns["status"]; ok {
		status, err := purchaseInvoiceAllowedValueForColumn(ctx, tx, tableName, "status", []string{"active", "enabled", "draft", "created"}, "active")
		if err != nil {
			t.Fatalf("party status detect failed: %v", err)
		}
		add("status", status)
	}

	add("description", "Runtime purchase invoice party fixture "+unique)
	add("created_by", "faz3_purchaseinvoice_runtime_test")
	add("updated_by", "faz3_purchaseinvoice_runtime_test")

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

	sql := buildPurchaseInvoiceInsertSQL(tableName, names, " RETURNING "+idColumn+"::text")

	var partyID string
	if err := tx.QueryRow(ctx, sql, values...).Scan(&partyID); err != nil {
		t.Fatalf("party fixture insert failed: %v", err)
	}

	return partyID
}

func createRuntimePurchaseInvoiceVendorRowFixture(t *testing.T, ctx context.Context, tx pgx.Tx, tenantID string, partyID string, unique string) string {
	t.Helper()

	tableName := detectOptionalPurchaseInvoiceTable(t, ctx, tx, []string{"erp_vendors", "erp_vendor", "vendors"})
	if tableName == "" {
		t.Fatal("vendor table bulunamadi")
	}

	columns, err := loadPurchaseInvoiceTableColumns(ctx, tx, tableName)
	if err != nil {
		t.Fatalf("vendor fixture load columns failed: %v", err)
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
		values = append(values, purchaseInvoiceNullableUUID(columns[column], value))
	}

	code := "SATICI-" + unique[len(unique)-6:]
	name := "Runtime Test Tedarikci " + unique[len(unique)-6:]

	add("tenant_id", tenantID)
	addUUID("party_id", partyID)
	add("vendor_code", code)
	add("code", code)
	add("account_code", code)
	add("vendor_name", name)
	add("name", name)
	add("account_name", name)
	add("display_name", name)
	add("tax_no", "1234567890")
	add("tax_number", "1234567890")
	add("tax_office", "Istanbul")
	add("is_active", true)

	if _, ok := columns["status"]; ok {
		status, err := purchaseInvoiceAllowedValueForColumn(ctx, tx, tableName, "status", []string{"active", "enabled", "draft", "created"}, "active")
		if err != nil {
			t.Fatalf("vendor status detect failed: %v", err)
		}
		add("status", status)
	}

	add("description", "Runtime purchase invoice vendor fixture "+unique)
	add("created_by", "faz3_purchaseinvoice_runtime_test")
	add("updated_by", "faz3_purchaseinvoice_runtime_test")

	idColumn := ""
	for _, candidate := range []string{"vendor_id", "id"} {
		if _, ok := columns[candidate]; ok {
			idColumn = candidate
			break
		}
	}

	if idColumn == "" {
		t.Fatal("vendor id column bulunamadi")
	}

	sql := buildPurchaseInvoiceInsertSQL(tableName, names, " RETURNING "+idColumn+"::text")

	var vendorID string
	if err := tx.QueryRow(ctx, sql, values...).Scan(&vendorID); err != nil {
		t.Fatalf("vendor fixture insert failed: %v", err)
	}

	return vendorID
}

func createRuntimePurchaseInvoiceUnitFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) string {
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

	tableName := detectOptionalPurchaseInvoiceTable(t, ctx, tx, []string{"erp_units", "erp_unit", "units"})
	if tableName == "" {
		t.Fatal("unit table bulunamadi")
	}

	columns, err := loadPurchaseInvoiceTableColumns(ctx, tx, tableName)
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

	if _, ok := columns["unit_type"]; ok {
		unitType, err := purchaseInvoiceAllowedValueForColumn(ctx, tx, tableName, "unit_type", []string{"quantity", "unit", "piece"}, "quantity")
		if err != nil {
			t.Fatalf("unit_type detect failed: %v", err)
		}
		add("unit_type", unitType)
	}

	add("decimal_precision", 2)
	add("decimal_places", 2)
	add("is_base_unit", true)
	add("is_active", true)

	if _, ok := columns["status"]; ok {
		status, err := purchaseInvoiceAllowedValueForColumn(ctx, tx, tableName, "status", []string{"active", "enabled", "draft", "created"}, "active")
		if err != nil {
			t.Fatalf("unit status detect failed: %v", err)
		}
		add("status", status)
	}

	add("description", "Runtime purchase invoice unit fixture "+unique)
	add("created_by", "faz3_purchaseinvoice_runtime_test")
	add("updated_by", "faz3_purchaseinvoice_runtime_test")

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

	sql := buildPurchaseInvoiceInsertSQL(tableName, names, " RETURNING "+idColumn+"::text")

	var unitID string
	if err := tx.QueryRow(ctx, sql, values...).Scan(&unitID); err != nil {
		t.Fatalf("unit fixture insert failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("unit fixture commit failed: %v", err)
	}

	return unitID
}

func createRuntimePurchaseInvoiceItemFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unitID string, unique string) string {
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

	tableName := detectOptionalPurchaseInvoiceTable(t, ctx, tx, []string{"erp_items", "erp_item", "items"})
	if tableName == "" {
		t.Fatal("item table bulunamadi")
	}

	columns, err := loadPurchaseInvoiceTableColumns(ctx, tx, tableName)
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

	addUUID := func(column string, value string) {
		if _, ok := columns[column]; !ok {
			return
		}
		names = append(names, column)
		values = append(values, purchaseInvoiceNullableUUID(columns[column], value))
	}

	code := "URUN-" + unique[len(unique)-6:]
	name := "Runtime Test Urun " + unique[len(unique)-6:]

	add("tenant_id", tenantID)
	addUUID("base_unit_id", unitID)
	add("item_code", code)
	add("code", code)
	add("sku", code)
	add("product_code", code)
	add("item_name", name)
	add("name", name)
	add("product_name", name)

	if _, ok := columns["item_type"]; ok {
		itemType, err := purchaseInvoiceAllowedValueForColumn(ctx, tx, tableName, "item_type", []string{"stock", "product", "inventory", "goods", "service"}, "stock")
		if err != nil {
			t.Fatalf("item_type detect failed: %v", err)
		}
		add("item_type", itemType)
	}

	add("unit_code", "ADET")
	add("base_unit_code", "ADET")
	add("vat_rate", 20)
	add("is_inventory_tracked", true)
	add("is_sales_allowed", true)
	add("is_purchase_allowed", true)
	add("is_active", true)

	if _, ok := columns["status"]; ok {
		status, err := purchaseInvoiceAllowedValueForColumn(ctx, tx, tableName, "status", []string{"active", "enabled", "draft", "created"}, "active")
		if err != nil {
			t.Fatalf("item status detect failed: %v", err)
		}
		add("status", status)
	}

	add("description", "Runtime purchase invoice item fixture "+unique)
	add("created_by", "faz3_purchaseinvoice_runtime_test")
	add("updated_by", "faz3_purchaseinvoice_runtime_test")

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

	sql := buildPurchaseInvoiceInsertSQL(tableName, names, " RETURNING "+idColumn+"::text")

	var itemID string
	if err := tx.QueryRow(ctx, sql, values...).Scan(&itemID); err != nil {
		t.Fatalf("item fixture insert failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("item fixture commit failed: %v", err)
	}

	return itemID
}

func cleanupRuntimePurchaseInvoiceFixture(t *testing.T, pool *pgxpool.Pool, headerTable string, lineTable string, tenantID string, invoiceNo string) {
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
		deletePurchaseInvoiceLinesForInvoice(t, ctx, tx, headerTable, lineTable, tenantID, invoiceNo)
	}

	if strings.TrimSpace(headerTable) != "" {
		headerColumns, err := loadPurchaseInvoiceTableColumns(ctx, tx, headerTable)
		if err == nil {
			whereParts := []string{"tenant_id = $1"}
			args := []any{tenantID}
			addPurchaseInvoiceNoWhere(headerColumns, invoiceNo, &args, &whereParts)

			if len(whereParts) > 1 {
				sql := fmt.Sprintf("DELETE FROM %s WHERE %s;", headerTable, strings.Join(whereParts, " AND "))
				if _, err := tx.Exec(ctx, sql, args...); err != nil {
					t.Logf("cleanup purchase invoice header failed: %v", err)
				}
			}
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
	}
}

func deletePurchaseInvoiceLinesForInvoice(t *testing.T, ctx context.Context, tx pgx.Tx, headerTable string, lineTable string, tenantID string, invoiceNo string) {
	t.Helper()

	lineColumns, err := loadPurchaseInvoiceTableColumns(ctx, tx, lineTable)
	if err != nil {
		t.Logf("cleanup load line columns failed: %v", err)
		return
	}

	whereParts := []string{"tenant_id = $1"}
	args := []any{tenantID}

	if _, ok := lineColumns["invoice_no"]; ok {
		args = append(args, invoiceNo)
		whereParts = append(whereParts, fmt.Sprintf("invoice_no = $%d", len(args)))
	} else if _, ok := lineColumns["purchase_invoice_no"]; ok {
		args = append(args, invoiceNo)
		whereParts = append(whereParts, fmt.Sprintf("purchase_invoice_no = $%d", len(args)))
	} else {
		invoiceID := findRuntimePurchaseInvoiceID(t, ctx, tx, headerTable, tenantID, invoiceNo)
		if invoiceID == "" {
			return
		}

		if _, ok := lineColumns["purchase_invoice_id"]; ok {
			args = append(args, invoiceID)
			whereParts = append(whereParts, fmt.Sprintf("purchase_invoice_id = $%d", len(args)))
		} else if _, ok := lineColumns["invoice_id"]; ok {
			args = append(args, invoiceID)
			whereParts = append(whereParts, fmt.Sprintf("invoice_id = $%d", len(args)))
		}
	}

	if len(whereParts) <= 1 {
		return
	}

	sql := fmt.Sprintf("DELETE FROM %s WHERE %s;", lineTable, strings.Join(whereParts, " AND "))

	if _, err := tx.Exec(ctx, sql, args...); err != nil {
		t.Logf("cleanup purchase invoice lines failed: %v", err)
	}
}

func findRuntimePurchaseInvoiceID(t *testing.T, ctx context.Context, tx pgx.Tx, headerTable string, tenantID string, invoiceNo string) string {
	t.Helper()

	headerColumns, err := loadPurchaseInvoiceTableColumns(ctx, tx, headerTable)
	if err != nil {
		return ""
	}

	idColumn := purchaseInvoiceIDColumn(headerColumns)
	if idColumn == "" {
		return ""
	}

	whereParts := []string{"tenant_id = $1"}
	args := []any{tenantID}
	addPurchaseInvoiceNoWhere(headerColumns, invoiceNo, &args, &whereParts)

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

func cleanupRuntimePurchaseInvoiceVendorFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, partyID string, vendorID string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Logf("vendor cleanup begin failed: %v", err)
		return
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Logf("vendor cleanup set tenant failed: %v", err)
		return
	}

	vendorTable := detectOptionalPurchaseInvoiceTable(t, ctx, tx, []string{"erp_vendors", "erp_vendor", "vendors"})
	if vendorTable != "" && strings.TrimSpace(vendorID) != "" {
		columns, err := loadPurchaseInvoiceTableColumns(ctx, tx, vendorTable)
		if err == nil {
			for _, candidate := range []string{"vendor_id", "id"} {
				if _, ok := columns[candidate]; ok {
					_, _ = tx.Exec(ctx, fmt.Sprintf("DELETE FROM %s WHERE tenant_id = $1 AND %s = $2;", vendorTable, candidate), tenantID, vendorID)
					break
				}
			}
		}
	}

	partyTable := detectOptionalPurchaseInvoiceTable(t, ctx, tx, []string{"erp_parties", "erp_party", "parties"})
	if partyTable != "" && strings.TrimSpace(partyID) != "" {
		columns, err := loadPurchaseInvoiceTableColumns(ctx, tx, partyTable)
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
		t.Logf("vendor cleanup commit failed: %v", err)
	}
}

func cleanupRuntimePurchaseInvoiceUnitFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unitID string) {
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

	tableName := detectOptionalPurchaseInvoiceTable(t, ctx, tx, []string{"erp_units", "erp_unit", "units"})
	if tableName == "" {
		return
	}

	columns, err := loadPurchaseInvoiceTableColumns(ctx, tx, tableName)
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

func cleanupRuntimePurchaseInvoiceItemFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, itemID string) {
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

	tableName := detectOptionalPurchaseInvoiceTable(t, ctx, tx, []string{"erp_items", "erp_item", "items"})
	if tableName == "" {
		return
	}

	columns, err := loadPurchaseInvoiceTableColumns(ctx, tx, tableName)
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

func countRuntimePurchaseInvoiceHeaders(t *testing.T, pool *pgxpool.Pool, tableName string, tenantID string, invoiceNo string) int {
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

	columns, err := loadPurchaseInvoiceTableColumns(ctx, tx, tableName)
	if err != nil {
		t.Fatalf("count header load columns failed: %v", err)
	}

	whereParts := []string{"tenant_id = $1"}
	args := []any{tenantID}
	addPurchaseInvoiceNoWhere(columns, invoiceNo, &args, &whereParts)

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

func countRuntimePurchaseInvoiceLines(t *testing.T, pool *pgxpool.Pool, headerTable string, lineTable string, tenantID string, invoiceNo string) int {
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

	columns, err := loadPurchaseInvoiceTableColumns(ctx, tx, lineTable)
	if err != nil {
		t.Fatalf("count line load columns failed: %v", err)
	}

	whereParts := []string{"tenant_id = $1"}
	args := []any{tenantID}

	if _, ok := columns["invoice_no"]; ok {
		args = append(args, invoiceNo)
		whereParts = append(whereParts, fmt.Sprintf("invoice_no = $%d", len(args)))
	} else if _, ok := columns["purchase_invoice_no"]; ok {
		args = append(args, invoiceNo)
		whereParts = append(whereParts, fmt.Sprintf("purchase_invoice_no = $%d", len(args)))
	} else {
		invoiceID := findRuntimePurchaseInvoiceID(t, ctx, tx, headerTable, tenantID, invoiceNo)
		if invoiceID != "" {
			if _, ok := columns["purchase_invoice_id"]; ok {
				args = append(args, invoiceID)
				whereParts = append(whereParts, fmt.Sprintf("purchase_invoice_id = $%d", len(args)))
			} else if _, ok := columns["invoice_id"]; ok {
				args = append(args, invoiceID)
				whereParts = append(whereParts, fmt.Sprintf("invoice_id = $%d", len(args)))
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

func getRuntimePurchaseInvoiceStatus(t *testing.T, pool *pgxpool.Pool, tableName string, tenantID string, invoiceNo string) string {
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

	columns, err := loadPurchaseInvoiceTableColumns(ctx, tx, tableName)
	if err != nil {
		t.Fatalf("status load columns failed: %v", err)
	}

	statusColumn := purchaseInvoiceStatusColumn(columns)
	if strings.TrimSpace(statusColumn) == "" {
		return ""
	}

	whereParts := []string{"tenant_id = $1"}
	args := []any{tenantID}
	addPurchaseInvoiceNoWhere(columns, invoiceNo, &args, &whereParts)

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

func detectOptionalPurchaseInvoiceTable(t *testing.T, ctx context.Context, tx pgx.Tx, candidates []string) string {
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

func purchaseInvoiceAllowedValueForColumn(ctx context.Context, tx pgx.Tx, tableName string, columnName string, candidates []string, fallback string) (string, error) {
	values, err := purchaseInvoiceConstraintValuesForColumn(ctx, tx, tableName, columnName)
	if err != nil {
		return "", err
	}

	if len(values) == 0 {
		return fallback, nil
	}

	for _, candidate := range candidates {
		if purchaseInvoiceContainsValue(values, candidate) {
			return candidate, nil
		}
	}

	return values[0], nil
}
