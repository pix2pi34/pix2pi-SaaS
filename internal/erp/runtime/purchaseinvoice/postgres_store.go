package purchaseinvoice

import (
	"context"
	"errors"
	"fmt"
	"regexp"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ PurchaseInvoiceStore = (*PostgresPurchaseInvoiceStore)(nil)

type PostgresPurchaseInvoiceStore struct {
	pool *pgxpool.Pool
}

type purchaseInvoiceColumnInfo struct {
	Name     string
	DataType string
	UDTName  string
}

func NewPostgresPurchaseInvoiceStore(pool *pgxpool.Pool) *PostgresPurchaseInvoiceStore {
	return &PostgresPurchaseInvoiceStore{pool: pool}
}

func (s *PostgresPurchaseInvoiceStore) PersistPurchaseInvoiceDraft(ctx context.Context, draft PurchaseInvoiceDraft) (PurchaseInvoiceDraft, error) {
	if err := ValidatePurchaseInvoiceDraft(draft); err != nil {
		return PurchaseInvoiceDraft{}, err
	}

	tx, err := s.beginTenantTx(ctx, draft.TenantID)
	if err != nil {
		return PurchaseInvoiceDraft{}, err
	}
	defer tx.Rollback(ctx)

	headerTable, err := detectPurchaseInvoiceHeaderTable(ctx, tx)
	if err != nil {
		return PurchaseInvoiceDraft{}, err
	}

	lineTable, err := detectPurchaseInvoiceLineTable(ctx, tx)
	if err != nil {
		return PurchaseInvoiceDraft{}, err
	}

	headerColumns, err := loadPurchaseInvoiceTableColumns(ctx, tx, headerTable)
	if err != nil {
		return PurchaseInvoiceDraft{}, err
	}

	lineColumns, err := loadPurchaseInvoiceTableColumns(ctx, tx, lineTable)
	if err != nil {
		return PurchaseInvoiceDraft{}, err
	}

	invoiceID, err := insertPurchaseInvoiceHeader(ctx, tx, headerTable, headerColumns, draft, InvoiceStatusDraft)
	if err != nil {
		return PurchaseInvoiceDraft{}, err
	}

	for _, line := range draft.Lines {
		if err := insertPurchaseInvoiceLine(ctx, tx, lineTable, lineColumns, draft, invoiceID, line); err != nil {
			return PurchaseInvoiceDraft{}, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return PurchaseInvoiceDraft{}, err
	}

	draft.Status = InvoiceStatusDraft
	return draft, nil
}

func (s *PostgresPurchaseInvoiceStore) MarkPurchaseInvoicePosted(ctx context.Context, draft PurchaseInvoiceDraft) (PurchaseInvoiceDraft, error) {
	if err := ValidatePurchaseInvoiceDraft(draft); err != nil {
		return PurchaseInvoiceDraft{}, err
	}

	tx, err := s.beginTenantTx(ctx, draft.TenantID)
	if err != nil {
		return PurchaseInvoiceDraft{}, err
	}
	defer tx.Rollback(ctx)

	headerTable, err := detectPurchaseInvoiceHeaderTable(ctx, tx)
	if err != nil {
		return PurchaseInvoiceDraft{}, err
	}

	headerColumns, err := loadPurchaseInvoiceTableColumns(ctx, tx, headerTable)
	if err != nil {
		return PurchaseInvoiceDraft{}, err
	}

	statusColumn := purchaseInvoiceStatusColumn(headerColumns)
	if statusColumn != "" {
		dbStatus, err := purchaseInvoiceDBStatus(ctx, tx, headerTable, statusColumn, InvoiceStatusPosted)
		if err != nil {
			return PurchaseInvoiceDraft{}, err
		}

		args := []any{draft.TenantID, dbStatus}
		setParts := []string{fmt.Sprintf("%s = $2", statusColumn)}
		whereParts := []string{"tenant_id = $1"}

		if _, ok := headerColumns["updated_at"]; ok {
			setParts = append(setParts, "updated_at = now()")
		}

		if _, ok := headerColumns["posted_at"]; ok {
			setParts = append(setParts, "posted_at = now()")
		}

		if _, ok := headerColumns["updated_by"]; ok {
			args = append(args, "runtime")
			setParts = append(setParts, fmt.Sprintf("updated_by = $%d", len(args)))
		}

		if _, ok := headerColumns["posted_by"]; ok {
			args = append(args, "runtime")
			setParts = append(setParts, fmt.Sprintf("posted_by = $%d", len(args)))
		}

		addPurchaseInvoiceNoWhere(headerColumns, draft.InvoiceNo, &args, &whereParts)

		if _, ok := headerColumns["deleted_at"]; ok {
			whereParts = append(whereParts, "deleted_at IS NULL")
		}

		if len(whereParts) <= 1 {
			return PurchaseInvoiceDraft{}, ErrPurchaseInvoicePersistFailed
		}

		sql := fmt.Sprintf(`
UPDATE %s
SET %s
WHERE %s;
`, headerTable, strings.Join(setParts, ", "), strings.Join(whereParts, " AND "))

		commandTag, err := tx.Exec(ctx, sql, args...)
		if err != nil {
			return PurchaseInvoiceDraft{}, err
		}

		if commandTag.RowsAffected() == 0 {
			return PurchaseInvoiceDraft{}, ErrPurchaseInvoiceNotFound
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return PurchaseInvoiceDraft{}, err
	}

	draft.Status = InvoiceStatusPosted
	return draft, nil
}

func (s *PostgresPurchaseInvoiceStore) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		_ = tx.Rollback(ctx)
		return nil, err
	}

	return tx, nil
}

func detectPurchaseInvoiceHeaderTable(ctx context.Context, tx pgx.Tx) (string, error) {
	return detectPurchaseInvoiceTable(ctx, tx, []string{
		"erp_purchase_invoices",
		"erp_purchase_invoice_headers",
	})
}

func detectPurchaseInvoiceLineTable(ctx context.Context, tx pgx.Tx) (string, error) {
	return detectPurchaseInvoiceTable(ctx, tx, []string{
		"erp_purchase_invoice_lines",
	})
}

func detectPurchaseInvoiceTable(ctx context.Context, tx pgx.Tx, candidates []string) (string, error) {
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
			return "", err
		}

		if exists {
			return tableName, nil
		}
	}

	return "", ErrPurchaseInvoicePersistFailed
}

func loadPurchaseInvoiceTableColumns(ctx context.Context, tx pgx.Tx, tableName string) (map[string]purchaseInvoiceColumnInfo, error) {
	rows, err := tx.Query(ctx, `
SELECT column_name, data_type, udt_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = $1;
`, tableName)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	columns := make(map[string]purchaseInvoiceColumnInfo)

	for rows.Next() {
		var col purchaseInvoiceColumnInfo
		if err := rows.Scan(&col.Name, &col.DataType, &col.UDTName); err != nil {
			return nil, err
		}

		columns[col.Name] = col
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if len(columns) == 0 {
		return nil, ErrPurchaseInvoicePersistFailed
	}

	return columns, nil
}

func insertPurchaseInvoiceHeader(
	ctx context.Context,
	tx pgx.Tx,
	tableName string,
	columns map[string]purchaseInvoiceColumnInfo,
	draft PurchaseInvoiceDraft,
	status InvoiceStatus,
) (string, error) {
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

	add("tenant_id", draft.TenantID)

	add("invoice_no", draft.InvoiceNo)
	add("purchase_invoice_no", draft.InvoiceNo)
	add("document_no", draft.InvoiceNo)

	if _, ok := columns["invoice_type"]; ok {
		invoiceType, err := purchaseInvoiceDBType(ctx, tx, tableName, "invoice_type")
		if err != nil {
			return "", err
		}
		add("invoice_type", invoiceType)
	}

	if _, ok := columns["document_type"]; ok {
		documentType, err := purchaseInvoiceDBType(ctx, tx, tableName, "document_type")
		if err != nil {
			return "", err
		}
		add("document_type", documentType)
	}

	statusColumn := purchaseInvoiceStatusColumn(columns)
	if statusColumn != "" {
		dbStatus, err := purchaseInvoiceDBStatus(ctx, tx, tableName, statusColumn, status)
		if err != nil {
			return "", err
		}
		add(statusColumn, dbStatus)
	}

	add("invoice_date", draft.Fiscal.InvoiceDate)
	add("document_date", draft.Fiscal.InvoiceDate)
	add("issue_date", draft.Fiscal.InvoiceDate)
	add("posting_date", draft.Fiscal.PostingDate)

	add("fiscal_year", draft.Fiscal.FiscalYear)
	add("fiscal_period", draft.Fiscal.FiscalPeriod)

	addUUID("party_id", purchaseInvoicePartyID(draft.Vendor))
	addUUID("vendor_id", draft.Vendor.VendorID)
	add("vendor_code", draft.Vendor.VendorCode)
	add("vendor_name", draft.Vendor.VendorName)
	add("tax_no", draft.Vendor.TaxNo)
	add("tax_office", draft.Vendor.TaxOffice)

	add("currency_code", purchaseInvoiceDefaultCurrency(draft.Money.CurrencyCode))
	add("exchange_rate", purchaseInvoiceDefaultExchangeRate(draft.Money.ExchangeRate))

	add("total_gross_amount", draft.TotalGrossAmount)
	add("gross_amount", draft.TotalGrossAmount)
	add("subtotal_amount", draft.TotalGrossAmount)

	add("total_discount_amount", draft.TotalDiscountAmount)
	add("discount_amount", draft.TotalDiscountAmount)

	add("total_taxable_amount", draft.TotalTaxableAmount)
	add("taxable_amount", draft.TotalTaxableAmount)

	add("total_tax_amount", draft.TotalTaxAmount)
	add("tax_amount", draft.TotalTaxAmount)
	add("vat_amount", draft.TotalTaxAmount)

	add("total_invoice_amount", draft.TotalInvoiceAmount)
	add("invoice_total", draft.TotalInvoiceAmount)
	add("total_amount", draft.TotalInvoiceAmount)
	add("grand_total", draft.TotalInvoiceAmount)

	add("local_total_gross_amount", draft.LocalTotalGrossAmount)
	add("local_total_discount_amount", draft.LocalTotalDiscountAmount)
	add("local_total_taxable_amount", draft.LocalTotalTaxableAmount)
	add("local_total_tax_amount", draft.LocalTotalTaxAmount)
	add("local_total_invoice_amount", draft.LocalTotalInvoiceAmount)

	add("description", purchaseInvoiceNullableString(draft.Description))

	add("created_by", "runtime")
	add("updated_by", "runtime")

	if len(names) == 0 {
		return "", ErrPurchaseInvoicePersistFailed
	}

	returningColumn := purchaseInvoiceIDColumn(columns)
	returning := ""
	if returningColumn != "" {
		returning = " RETURNING " + returningColumn + "::text"
	}

	sql := buildPurchaseInvoiceInsertSQL(tableName, names, returning)

	if returning == "" {
		if _, err := tx.Exec(ctx, sql, values...); err != nil {
			return "", err
		}

		return "", nil
	}

	var invoiceID string
	if err := tx.QueryRow(ctx, sql, values...).Scan(&invoiceID); err != nil {
		return "", err
	}

	return invoiceID, nil
}

func insertPurchaseInvoiceLine(
	ctx context.Context,
	tx pgx.Tx,
	tableName string,
	columns map[string]purchaseInvoiceColumnInfo,
	draft PurchaseInvoiceDraft,
	invoiceID string,
	line PurchaseInvoiceLineDraft,
) error {
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

	add("tenant_id", draft.TenantID)

	addUUID("purchase_invoice_id", invoiceID)
	addUUID("invoice_id", invoiceID)
	addUUID("document_id", invoiceID)

	add("invoice_no", draft.InvoiceNo)
	add("purchase_invoice_no", draft.InvoiceNo)
	add("document_no", draft.InvoiceNo)

	add("line_no", line.LineNo)

	addUUID("item_id", purchaseInvoiceItemID(line.Item))
	addUUID("product_id", purchaseInvoiceProductID(line.Item))
	add("item_code", line.Item.ItemCode)
	add("product_code", line.Item.ItemCode)
	add("item_name", line.Item.ItemName)
	add("product_name", line.Item.ItemName)

	addUUID("unit_id", purchaseInvoiceUnitID(line.Item))
	add("unit_code", line.Item.UnitCode)

	add("quantity", line.Quantity)
	add("unit_price", line.UnitPrice)

	add("gross_line_amount", line.GrossLineAmount)
	add("line_gross_amount", line.GrossLineAmount)

	add("discount_amount", line.DiscountAmount)
	add("taxable_amount", line.TaxableAmount)

	add("tax_code", line.TaxCode)
	add("tax_rate", line.TaxRate)
	add("tax_amount", line.TaxAmount)
	add("vat_amount", line.TaxAmount)

	add("line_total_amount", line.LineTotalAmount)
	add("total_amount", line.LineTotalAmount)

	add("local_gross_line_amount", line.LocalGrossLineAmount)
	add("local_discount_amount", line.LocalDiscountAmount)
	add("local_taxable_amount", line.LocalTaxableAmount)
	add("local_tax_amount", line.LocalTaxAmount)
	add("local_line_total_amount", line.LocalLineTotalAmount)

	add("description", purchaseInvoiceNullableString(line.Description))

	add("created_by", "runtime")
	add("updated_by", "runtime")

	if len(names) == 0 {
		return ErrPurchaseInvoicePersistFailed
	}

	sql := buildPurchaseInvoiceInsertSQL(tableName, names, "")

	_, err := tx.Exec(ctx, sql, values...)
	return err
}

func buildPurchaseInvoiceInsertSQL(table string, columns []string, returning string) string {
	placeholders := make([]string, 0, len(columns))

	for i := range columns {
		placeholders = append(placeholders, fmt.Sprintf("$%d", i+1))
	}

	return fmt.Sprintf(
		"INSERT INTO %s (%s) VALUES (%s)%s;",
		table,
		strings.Join(columns, ", "),
		strings.Join(placeholders, ", "),
		returning,
	)
}

func addPurchaseInvoiceNoWhere(columns map[string]purchaseInvoiceColumnInfo, invoiceNo string, args *[]any, whereParts *[]string) {
	if _, ok := columns["invoice_no"]; ok {
		*args = append(*args, invoiceNo)
		*whereParts = append(*whereParts, fmt.Sprintf("invoice_no = $%d", len(*args)))
		return
	}

	if _, ok := columns["purchase_invoice_no"]; ok {
		*args = append(*args, invoiceNo)
		*whereParts = append(*whereParts, fmt.Sprintf("purchase_invoice_no = $%d", len(*args)))
		return
	}

	if _, ok := columns["document_no"]; ok {
		*args = append(*args, invoiceNo)
		*whereParts = append(*whereParts, fmt.Sprintf("document_no = $%d", len(*args)))
	}
}

func purchaseInvoiceIDColumn(columns map[string]purchaseInvoiceColumnInfo) string {
	for _, candidate := range []string{"purchase_invoice_id", "invoice_id", "document_id"} {
		if _, ok := columns[candidate]; ok {
			return candidate
		}
	}

	return ""
}

func purchaseInvoiceStatusColumn(columns map[string]purchaseInvoiceColumnInfo) string {
	for _, candidate := range []string{"invoice_status", "document_status", "status"} {
		if _, ok := columns[candidate]; ok {
			return candidate
		}
	}

	return ""
}

func purchaseInvoiceDBType(ctx context.Context, tx pgx.Tx, tableName string, columnName string) (string, error) {
	values, err := purchaseInvoiceConstraintValuesForColumn(ctx, tx, tableName, columnName)
	if err != nil {
		return "", err
	}

	if len(values) == 0 {
		return "purchase_invoice", nil
	}

	for _, candidate := range []string{"purchase_invoice", "invoice", "purchase", "standard"} {
		if purchaseInvoiceContainsValue(values, candidate) {
			return candidate, nil
		}
	}

	return values[0], nil
}

func purchaseInvoiceDBStatus(ctx context.Context, tx pgx.Tx, tableName string, columnName string, status InvoiceStatus) (string, error) {
	switch status {
	case InvoiceStatusDraft:
		return "draft", nil
	case InvoiceStatusPosted:
		return "received", nil
	case InvoiceStatusCancelled:
		return purchaseInvoiceAllowedStatusOrFallback(ctx, tx, tableName, columnName, []string{"cancelled", "canceled", "void"}, "received")
	case InvoiceStatusReversed:
		return purchaseInvoiceAllowedStatusOrFallback(ctx, tx, tableName, columnName, []string{"reversed", "cancelled", "canceled"}, "received")
	default:
		return "draft", nil
	}
}

func purchaseInvoiceAllowedStatusOrFallback(ctx context.Context, tx pgx.Tx, tableName string, columnName string, candidates []string, fallback string) (string, error) {
	values, err := purchaseInvoiceConstraintValuesForColumn(ctx, tx, tableName, columnName)
	if err != nil {
		return "", err
	}

	for _, candidate := range candidates {
		if purchaseInvoiceContainsValue(values, candidate) {
			return candidate, nil
		}
	}

	return fallback, nil
}

func purchaseInvoiceConstraintValuesForColumn(ctx context.Context, tx pgx.Tx, tableName string, columnName string) ([]string, error) {
	var definition string

	err := tx.QueryRow(ctx, `
SELECT pg_get_constraintdef(c.oid)
FROM pg_constraint c
WHERE c.conrelid = to_regclass('public.' || $1)
  AND pg_get_constraintdef(c.oid) ILIKE '%' || $2 || '%'
LIMIT 1;
`, tableName, columnName).Scan(&definition)

	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}

	if err != nil {
		return nil, err
	}

	return purchaseInvoiceConstraintValues(definition), nil
}

func purchaseInvoiceConstraintValues(definition string) []string {
	matches := regexp.MustCompile(`'([^']+)'`).FindAllStringSubmatch(definition, -1)

	values := make([]string, 0, len(matches))
	for _, match := range matches {
		if len(match) > 1 {
			values = append(values, match[1])
		}
	}

	return values
}

func purchaseInvoiceContainsValue(values []string, candidate string) bool {
	for _, value := range values {
		if value == candidate {
			return true
		}
	}

	return false
}

func purchaseInvoicePartyID(vendor VendorRef) string {
	if strings.TrimSpace(vendor.PartyID) != "" {
		return vendor.PartyID
	}

	if strings.TrimSpace(vendor.VendorID) != "" {
		return vendor.VendorID
	}

	return ""
}

func purchaseInvoiceItemID(item ItemRef) string {
	if strings.TrimSpace(item.ItemID) != "" {
		return item.ItemID
	}

	if strings.TrimSpace(item.ProductID) != "" {
		return item.ProductID
	}

	return ""
}

func purchaseInvoiceProductID(item ItemRef) string {
	if strings.TrimSpace(item.ProductID) != "" {
		return item.ProductID
	}

	return ""
}

func purchaseInvoiceUnitID(item ItemRef) string {
	if strings.TrimSpace(item.UnitID) != "" {
		return item.UnitID
	}

	return ""
}

func purchaseInvoiceNullableString(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}

func purchaseInvoiceDefaultCurrency(value string) string {
	if strings.TrimSpace(value) == "" {
		return "TRY"
	}

	return strings.ToUpper(strings.TrimSpace(value))
}

func purchaseInvoiceDefaultExchangeRate(value float64) float64 {
	if value <= 0 {
		return 1
	}

	return value
}

func purchaseInvoiceNullableUUID(column purchaseInvoiceColumnInfo, value string) any {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}

	if column.UDTName == "uuid" && !purchaseInvoiceIsUUID(trimmed) {
		return nil
	}

	return trimmed
}

func purchaseInvoiceIsUUID(value string) bool {
	matched, _ := regexp.MatchString(`^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$`, value)
	return matched
}
