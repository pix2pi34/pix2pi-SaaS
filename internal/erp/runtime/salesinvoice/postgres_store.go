package salesinvoice

import (
	"context"
	"errors"
	"fmt"
	"regexp"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ SalesInvoiceStore = (*PostgresSalesInvoiceStore)(nil)

type PostgresSalesInvoiceStore struct {
	pool *pgxpool.Pool
}

type salesInvoiceColumnInfo struct {
	Name     string
	DataType string
	UDTName  string
}

func NewPostgresSalesInvoiceStore(pool *pgxpool.Pool) *PostgresSalesInvoiceStore {
	return &PostgresSalesInvoiceStore{pool: pool}
}

func (s *PostgresSalesInvoiceStore) PersistSalesInvoiceDraft(ctx context.Context, draft SalesInvoiceDraft) (SalesInvoiceDraft, error) {
	if err := ValidateSalesInvoiceDraft(draft); err != nil {
		return SalesInvoiceDraft{}, err
	}

	tx, err := s.beginTenantTx(ctx, draft.TenantID)
	if err != nil {
		return SalesInvoiceDraft{}, err
	}
	defer tx.Rollback(ctx)

	headerTable, err := detectSalesInvoiceHeaderTable(ctx, tx)
	if err != nil {
		return SalesInvoiceDraft{}, err
	}

	lineTable, err := detectSalesInvoiceLineTable(ctx, tx)
	if err != nil {
		return SalesInvoiceDraft{}, err
	}

	headerColumns, err := loadSalesInvoiceTableColumns(ctx, tx, headerTable)
	if err != nil {
		return SalesInvoiceDraft{}, err
	}

	lineColumns, err := loadSalesInvoiceTableColumns(ctx, tx, lineTable)
	if err != nil {
		return SalesInvoiceDraft{}, err
	}

	invoiceID, err := insertSalesInvoiceHeader(ctx, tx, headerTable, headerColumns, draft, InvoiceStatusDraft)
	if err != nil {
		return SalesInvoiceDraft{}, err
	}

	for _, line := range draft.Lines {
		if err := insertSalesInvoiceLine(ctx, tx, lineTable, lineColumns, draft, invoiceID, line); err != nil {
			return SalesInvoiceDraft{}, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return SalesInvoiceDraft{}, err
	}

	draft.Status = InvoiceStatusDraft
	return draft, nil
}

func (s *PostgresSalesInvoiceStore) MarkSalesInvoicePosted(ctx context.Context, draft SalesInvoiceDraft) (SalesInvoiceDraft, error) {
	if err := ValidateSalesInvoiceDraft(draft); err != nil {
		return SalesInvoiceDraft{}, err
	}

	tx, err := s.beginTenantTx(ctx, draft.TenantID)
	if err != nil {
		return SalesInvoiceDraft{}, err
	}
	defer tx.Rollback(ctx)

	headerTable, err := detectSalesInvoiceHeaderTable(ctx, tx)
	if err != nil {
		return SalesInvoiceDraft{}, err
	}

	headerColumns, err := loadSalesInvoiceTableColumns(ctx, tx, headerTable)
	if err != nil {
		return SalesInvoiceDraft{}, err
	}

	statusColumn := salesInvoiceStatusColumn(headerColumns)
	if statusColumn != "" {
		dbStatus, err := salesInvoiceDBStatus(ctx, tx, headerTable, statusColumn, InvoiceStatusPosted)
		if err != nil {
			return SalesInvoiceDraft{}, err
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

		addSalesInvoiceNoWhere(headerColumns, draft.InvoiceNo, &args, &whereParts)

		if _, ok := headerColumns["deleted_at"]; ok {
			whereParts = append(whereParts, "deleted_at IS NULL")
		}

		if len(whereParts) <= 1 {
			return SalesInvoiceDraft{}, ErrSalesInvoicePersistFailed
		}

		sql := fmt.Sprintf(`
UPDATE %s
SET %s
WHERE %s;
`, headerTable, strings.Join(setParts, ", "), strings.Join(whereParts, " AND "))

		commandTag, err := tx.Exec(ctx, sql, args...)
		if err != nil {
			return SalesInvoiceDraft{}, err
		}

		if commandTag.RowsAffected() == 0 {
			return SalesInvoiceDraft{}, ErrSalesInvoiceNotFound
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return SalesInvoiceDraft{}, err
	}

	draft.Status = InvoiceStatusPosted
	return draft, nil
}

func (s *PostgresSalesInvoiceStore) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

func detectSalesInvoiceHeaderTable(ctx context.Context, tx pgx.Tx) (string, error) {
	candidates := []string{
		"erp_sales_invoices",
		"erp_sales_invoice_headers",
		"erp_invoices",
		"erp_invoice_headers",
	}

	return detectSalesInvoiceTable(ctx, tx, candidates)
}

func detectSalesInvoiceLineTable(ctx context.Context, tx pgx.Tx) (string, error) {
	candidates := []string{
		"erp_sales_invoice_lines",
		"erp_invoice_lines",
	}

	return detectSalesInvoiceTable(ctx, tx, candidates)
}

func detectSalesInvoiceTable(ctx context.Context, tx pgx.Tx, candidates []string) (string, error) {
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

	return "", ErrSalesInvoicePersistFailed
}

func loadSalesInvoiceTableColumns(ctx context.Context, tx pgx.Tx, tableName string) (map[string]salesInvoiceColumnInfo, error) {
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

	columns := make(map[string]salesInvoiceColumnInfo)

	for rows.Next() {
		var col salesInvoiceColumnInfo
		if err := rows.Scan(&col.Name, &col.DataType, &col.UDTName); err != nil {
			return nil, err
		}

		columns[col.Name] = col
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if len(columns) == 0 {
		return nil, ErrSalesInvoicePersistFailed
	}

	return columns, nil
}

func insertSalesInvoiceHeader(
	ctx context.Context,
	tx pgx.Tx,
	tableName string,
	columns map[string]salesInvoiceColumnInfo,
	draft SalesInvoiceDraft,
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
		values = append(values, salesInvoiceNullableUUID(columns[column], value))
	}

	add("tenant_id", draft.TenantID)

	add("invoice_no", draft.InvoiceNo)
	add("sales_invoice_no", draft.InvoiceNo)
	add("document_no", draft.InvoiceNo)

	if _, ok := columns["invoice_type"]; ok {
		invoiceType, err := salesInvoiceDBType(ctx, tx, tableName, "invoice_type")
		if err != nil {
			return "", err
		}
		add("invoice_type", invoiceType)
	}

	if _, ok := columns["document_type"]; ok {
		documentType, err := salesInvoiceDBType(ctx, tx, tableName, "document_type")
		if err != nil {
			return "", err
		}
		add("document_type", documentType)
	}

	statusColumn := salesInvoiceStatusColumn(columns)
	if statusColumn != "" {
		dbStatus, err := salesInvoiceDBStatus(ctx, tx, tableName, statusColumn, status)
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

	addUUID("party_id", salesInvoicePartyID(draft.Customer))
	addUUID("customer_id", draft.Customer.CustomerID)
	add("customer_code", draft.Customer.CustomerCode)
	add("customer_name", draft.Customer.CustomerName)
	add("tax_no", draft.Customer.TaxNo)
	add("tax_office", draft.Customer.TaxOffice)

	add("currency_code", salesInvoiceDefaultCurrency(draft.Money.CurrencyCode))
	add("exchange_rate", salesInvoiceDefaultExchangeRate(draft.Money.ExchangeRate))

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

	add("description", salesInvoiceNullableString(draft.Description))

	add("created_by", "runtime")
	add("updated_by", "runtime")

	if len(names) == 0 {
		return "", ErrSalesInvoicePersistFailed
	}

	returningColumn := salesInvoiceIDColumn(columns)
	returning := ""
	if returningColumn != "" {
		returning = " RETURNING " + returningColumn + "::text"
	}

	sql := buildSalesInvoiceInsertSQL(tableName, names, returning)

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

func insertSalesInvoiceLine(
	ctx context.Context,
	tx pgx.Tx,
	tableName string,
	columns map[string]salesInvoiceColumnInfo,
	draft SalesInvoiceDraft,
	invoiceID string,
	line SalesInvoiceLineDraft,
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
		values = append(values, salesInvoiceNullableUUID(columns[column], value))
	}

	add("tenant_id", draft.TenantID)

	addUUID("sales_invoice_id", invoiceID)
	addUUID("invoice_id", invoiceID)
	addUUID("document_id", invoiceID)

	add("invoice_no", draft.InvoiceNo)
	add("sales_invoice_no", draft.InvoiceNo)
	add("document_no", draft.InvoiceNo)

	add("line_no", line.LineNo)

	addUUID("item_id", salesInvoiceItemID(line.Product))
	addUUID("product_id", salesInvoiceProductID(line.Product))
	add("product_code", line.Product.ProductCode)
	add("product_name", line.Product.ProductName)
	addUUID("unit_id", salesInvoiceUnitID(line.Product))
	add("unit_code", line.Product.UnitCode)

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

	add("description", salesInvoiceNullableString(line.Description))

	add("created_by", "runtime")
	add("updated_by", "runtime")

	if len(names) == 0 {
		return ErrSalesInvoicePersistFailed
	}

	sql := buildSalesInvoiceInsertSQL(tableName, names, "")

	_, err := tx.Exec(ctx, sql, values...)
	return err
}

func buildSalesInvoiceInsertSQL(table string, columns []string, returning string) string {
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

func addSalesInvoiceNoWhere(columns map[string]salesInvoiceColumnInfo, invoiceNo string, args *[]any, whereParts *[]string) {
	if _, ok := columns["invoice_no"]; ok {
		*args = append(*args, invoiceNo)
		*whereParts = append(*whereParts, fmt.Sprintf("invoice_no = $%d", len(*args)))
		return
	}

	if _, ok := columns["sales_invoice_no"]; ok {
		*args = append(*args, invoiceNo)
		*whereParts = append(*whereParts, fmt.Sprintf("sales_invoice_no = $%d", len(*args)))
		return
	}

	if _, ok := columns["document_no"]; ok {
		*args = append(*args, invoiceNo)
		*whereParts = append(*whereParts, fmt.Sprintf("document_no = $%d", len(*args)))
	}
}

func salesInvoiceIDColumn(columns map[string]salesInvoiceColumnInfo) string {
	for _, candidate := range []string{"sales_invoice_id", "invoice_id", "document_id"} {
		if _, ok := columns[candidate]; ok {
			return candidate
		}
	}

	return ""
}

func salesInvoiceStatusColumn(columns map[string]salesInvoiceColumnInfo) string {
	for _, candidate := range []string{"invoice_status", "document_status", "status"} {
		if _, ok := columns[candidate]; ok {
			return candidate
		}
	}

	return ""
}

func salesInvoiceDBType(ctx context.Context, tx pgx.Tx, tableName string, columnName string) (string, error) {
	values, err := salesInvoiceConstraintValuesForColumn(ctx, tx, tableName, columnName)
	if err != nil {
		return "", err
	}

	if len(values) == 0 {
		return "sales_invoice", nil
	}

	for _, candidate := range []string{"sales_invoice", "invoice", "sales", "standard"} {
		if salesInvoiceContainsValue(values, candidate) {
			return candidate, nil
		}
	}

	return values[0], nil
}

func salesInvoiceDBStatus(ctx context.Context, tx pgx.Tx, tableName string, columnName string, status InvoiceStatus) (string, error) {
	switch status {
	case InvoiceStatusDraft:
		return "draft", nil
	case InvoiceStatusPosted:
		return "issued", nil
	case InvoiceStatusCancelled:
		return salesInvoiceAllowedStatusOrFallback(ctx, tx, tableName, columnName, []string{"cancelled", "canceled", "void"}, "issued")
	case InvoiceStatusReversed:
		return salesInvoiceAllowedStatusOrFallback(ctx, tx, tableName, columnName, []string{"reversed", "cancelled", "canceled"}, "issued")
	default:
		return "draft", nil
	}
}

func salesInvoiceAllowedStatusOrFallback(ctx context.Context, tx pgx.Tx, tableName string, columnName string, candidates []string, fallback string) (string, error) {
	values, err := salesInvoiceConstraintValuesForColumn(ctx, tx, tableName, columnName)
	if err != nil {
		return "", err
	}

	for _, candidate := range candidates {
		if salesInvoiceContainsValue(values, candidate) {
			return candidate, nil
		}
	}

	return fallback, nil
}

func salesInvoiceConstraintValuesForColumn(ctx context.Context, tx pgx.Tx, tableName string, columnName string) ([]string, error) {
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

	return salesInvoiceConstraintValues(definition), nil
}

func salesInvoiceConstraintValues(definition string) []string {
	matches := regexp.MustCompile(`'([^']+)'`).FindAllStringSubmatch(definition, -1)

	values := make([]string, 0, len(matches))
	for _, match := range matches {
		if len(match) > 1 {
			values = append(values, match[1])
		}
	}

	return values
}

func salesInvoiceContainsValue(values []string, candidate string) bool {
	for _, value := range values {
		if value == candidate {
			return true
		}
	}

	return false
}

func salesInvoiceProductID(product ProductRef) string {
	if strings.TrimSpace(product.ProductID) != "" {
		return product.ProductID
	}

	return ""
}

func salesInvoiceUnitID(product ProductRef) string {
	if strings.TrimSpace(product.UnitID) != "" {
		return product.UnitID
	}

	return ""
}

func salesInvoiceItemID(product ProductRef) string {
	if strings.TrimSpace(product.ItemID) != "" {
		return product.ItemID
	}

	if strings.TrimSpace(product.ProductID) != "" {
		return product.ProductID
	}

	return ""
}

func salesInvoicePartyID(customer CustomerRef) string {
	if strings.TrimSpace(customer.PartyID) != "" {
		return customer.PartyID
	}

	if strings.TrimSpace(customer.CustomerID) != "" {
		return customer.CustomerID
	}

	return ""
}

func salesInvoiceNullableString(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}

func salesInvoiceDefaultCurrency(value string) string {
	if strings.TrimSpace(value) == "" {
		return "TRY"
	}

	return strings.ToUpper(strings.TrimSpace(value))
}

func salesInvoiceDefaultExchangeRate(value float64) float64 {
	if value <= 0 {
		return 1
	}

	return value
}

func salesInvoiceNullableUUID(column salesInvoiceColumnInfo, value string) any {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}

	if column.UDTName == "uuid" && !salesInvoiceIsUUID(trimmed) {
		return nil
	}

	return trimmed
}

func salesInvoiceIsUUID(value string) bool {
	matched, _ := regexp.MatchString(`^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$`, value)
	return matched
}
