package taxcalc

import (
	"context"
	"errors"
	"fmt"
	"regexp"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ TaxStore = (*PostgresTaxStore)(nil)

type PostgresTaxStore struct {
	pool *pgxpool.Pool
}

type taxcalcColumnInfo struct {
	Name     string
	DataType string
	UDTName  string
}

func NewPostgresTaxStore(pool *pgxpool.Pool) *PostgresTaxStore {
	return &PostgresTaxStore{pool: pool}
}

func (s *PostgresTaxStore) PersistTaxDraft(ctx context.Context, draft TaxCalculationDraft) (TaxCalculationDraft, error) {
	if err := ValidateTaxCalculationDraft(draft); err != nil {
		return TaxCalculationDraft{}, err
	}

	tx, err := s.beginTenantTx(ctx, draft.TenantID)
	if err != nil {
		return TaxCalculationDraft{}, err
	}
	defer tx.Rollback(ctx)

	tableName, err := detectTaxCalculationTable(ctx, tx)
	if err != nil {
		return TaxCalculationDraft{}, err
	}

	columns, err := loadTaxcalcTableColumns(ctx, tx, tableName)
	if err != nil {
		return TaxCalculationDraft{}, err
	}

	for _, line := range draft.Lines {
		if err := insertTaxLine(ctx, tx, tableName, columns, draft, line, TaxCalculationStatusDraft); err != nil {
			return TaxCalculationDraft{}, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return TaxCalculationDraft{}, err
	}

	draft.Status = TaxCalculationStatusDraft
	for i := range draft.Lines {
		draft.Lines[i].Status = TaxCalculationStatusDraft
	}

	return draft, nil
}

func (s *PostgresTaxStore) MarkTaxPosted(ctx context.Context, draft TaxCalculationDraft) (TaxCalculationDraft, error) {
	if err := ValidateTaxCalculationDraft(draft); err != nil {
		return TaxCalculationDraft{}, err
	}

	tx, err := s.beginTenantTx(ctx, draft.TenantID)
	if err != nil {
		return TaxCalculationDraft{}, err
	}
	defer tx.Rollback(ctx)

	tableName, err := detectTaxCalculationTable(ctx, tx)
	if err != nil {
		return TaxCalculationDraft{}, err
	}

	columns, err := loadTaxcalcTableColumns(ctx, tx, tableName)
	if err != nil {
		return TaxCalculationDraft{}, err
	}

	statusColumn := taxcalcStatusColumn(columns)
	if statusColumn != "" {
		args := []any{draft.TenantID}
		setParts := make([]string, 0)
		whereParts := []string{"tenant_id = $1"}

		dbStatus, err := taxcalcDBStatus(ctx, tx, tableName, statusColumn, TaxCalculationStatusPosted)
		if err != nil {
			return TaxCalculationDraft{}, err
		}

		args = append(args, dbStatus)
		setParts = append(setParts, fmt.Sprintf("%s = $%d", statusColumn, len(args)))

		if _, ok := columns["updated_at"]; ok {
			setParts = append(setParts, "updated_at = now()")
		}

		if _, ok := columns["updated_by"]; ok {
			args = append(args, "runtime")
			setParts = append(setParts, fmt.Sprintf("updated_by = $%d", len(args)))
		}

		if _, ok := columns["posted_at"]; ok {
			setParts = append(setParts, "posted_at = now()")
		}

		if _, ok := columns["calculated_at"]; ok {
			setParts = append(setParts, "calculated_at = now()")
		}

		addTaxcalcSourceWhere(columns, draft, &args, &whereParts)

		if _, ok := columns["deleted_at"]; ok {
			whereParts = append(whereParts, "deleted_at IS NULL")
		}

		if len(whereParts) <= 1 {
			return TaxCalculationDraft{}, ErrTaxPersistFailed
		}

		sql := fmt.Sprintf(`
UPDATE %s
SET %s
WHERE %s;
`, tableName, strings.Join(setParts, ", "), strings.Join(whereParts, " AND "))

		commandTag, err := tx.Exec(ctx, sql, args...)
		if err != nil {
			return TaxCalculationDraft{}, err
		}

		if commandTag.RowsAffected() == 0 {
			return TaxCalculationDraft{}, ErrTaxNotFound
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return TaxCalculationDraft{}, err
	}

	draft.Status = TaxCalculationStatusPosted
	for i := range draft.Lines {
		draft.Lines[i].Status = TaxCalculationStatusPosted
	}

	return draft, nil
}

func (s *PostgresTaxStore) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

func detectTaxCalculationTable(ctx context.Context, tx pgx.Tx) (string, error) {
	candidates := []string{
		"erp_tax_calculations",
		"erp_tax_transactions",
		"erp_tax_lines",
		"erp_tax_entries",
		"erp_tax_records",
	}

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

	return "", ErrTaxPersistFailed
}

func loadTaxcalcTableColumns(ctx context.Context, tx pgx.Tx, tableName string) (map[string]taxcalcColumnInfo, error) {
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

	columns := make(map[string]taxcalcColumnInfo)

	for rows.Next() {
		var col taxcalcColumnInfo
		if err := rows.Scan(&col.Name, &col.DataType, &col.UDTName); err != nil {
			return nil, err
		}

		columns[col.Name] = col
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if len(columns) == 0 {
		return nil, ErrTaxPersistFailed
	}

	return columns, nil
}

func insertTaxLine(
	ctx context.Context,
	tx pgx.Tx,
	tableName string,
	columns map[string]taxcalcColumnInfo,
	draft TaxCalculationDraft,
	line TaxLineDraft,
	status TaxCalculationStatus,
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
		values = append(values, taxcalcNullableUUID(columns[column], value))
	}

	add("tenant_id", draft.TenantID)

	add("transaction_type", string(draft.TransactionType))
	add("tax_transaction_type", string(draft.TransactionType))
	add("tax_type", taxcalcDBTaxType(line))
	add("direction", taxcalcDBDirection(draft.TransactionType))
	add("tax_direction", taxcalcDBDirection(draft.TransactionType))

	add("source_module", draft.Source.SourceModule)
	add("source_document_type", draft.Source.SourceDocumentType)
	addUUID("source_document_id", draft.Source.SourceDocumentID)
	add("source_document_no", draft.Source.SourceDocumentNo)

	add("fiscal_year", draft.Fiscal.FiscalYear)
	add("fiscal_period", draft.Fiscal.FiscalPeriod)

	add("calculation_date", draft.Fiscal.CalculationDate)
	add("tax_date", draft.Fiscal.CalculationDate)
	add("posting_date", draft.Fiscal.CalculationDate)

	addUUID("tax_code_id", line.TaxCodeID)
	add("tax_code", line.TaxCode)
	add("tax_name", line.TaxName)
	add("tax_rate", line.TaxRate)
	add("rate", line.TaxRate)

	add("base_amount", line.BaseAmount)
	add("tax_base_amount", line.BaseAmount)
	add("taxable_amount", line.BaseAmount)

	add("tax_amount", line.TaxAmount)

	add("withholding_amount", line.WithholdingAmount)
	add("net_tax_amount", line.NetTaxAmount)

	add("gross_amount", line.GrossAmount)
	add("payable_amount", line.PayableAmount)

	add("local_base_amount", line.LocalBaseAmount)
	add("local_tax_amount", line.LocalTaxAmount)

	add("local_withholding_amount", line.LocalWithholdingAmount)
	add("local_net_tax_amount", line.LocalNetTaxAmount)

	add("local_gross_amount", line.LocalGrossAmount)
	add("local_payable_amount", line.LocalPayableAmount)

	add("currency_code", taxcalcDefaultCurrency(line.CurrencyCode))
	add("exchange_rate", taxcalcDefaultExchangeRate(line.ExchangeRate))

	add("description", taxcalcNullableString(line.Description))

	statusColumn := taxcalcStatusColumn(columns)
	if statusColumn != "" {
		dbStatus, err := taxcalcDBStatus(ctx, tx, tableName, statusColumn, status)
		if err != nil {
			return err
		}

		add(statusColumn, dbStatus)
	}

	add("created_by", "runtime")
	add("updated_by", "runtime")

	if len(names) == 0 {
		return ErrTaxPersistFailed
	}

	sql := buildTaxcalcInsertSQL(tableName, names)

	_, err := tx.Exec(ctx, sql, values...)
	return err
}

func buildTaxcalcInsertSQL(table string, columns []string) string {
	placeholders := make([]string, 0, len(columns))

	for i := range columns {
		placeholders = append(placeholders, fmt.Sprintf("$%d", i+1))
	}

	return fmt.Sprintf(
		"INSERT INTO %s (%s) VALUES (%s);",
		table,
		strings.Join(columns, ", "),
		strings.Join(placeholders, ", "),
	)
}

func addTaxcalcSourceWhere(columns map[string]taxcalcColumnInfo, draft TaxCalculationDraft, args *[]any, whereParts *[]string) {
	if _, ok := columns["source_document_no"]; ok && strings.TrimSpace(draft.Source.SourceDocumentNo) != "" {
		*args = append(*args, draft.Source.SourceDocumentNo)
		*whereParts = append(*whereParts, fmt.Sprintf("source_document_no = $%d", len(*args)))
		return
	}

	if _, ok := columns["source_document_id"]; ok && strings.TrimSpace(draft.Source.SourceDocumentID) != "" {
		*args = append(*args, taxcalcNullableUUID(columns["source_document_id"], draft.Source.SourceDocumentID))
		*whereParts = append(*whereParts, fmt.Sprintf("source_document_id = $%d", len(*args)))
		return
	}

	if _, ok := columns["tax_code"]; ok && len(draft.Lines) > 0 {
		*args = append(*args, draft.Lines[0].TaxCode)
		*whereParts = append(*whereParts, fmt.Sprintf("tax_code = $%d", len(*args)))
	}
}

func taxcalcDBDirection(transactionType TransactionType) string {
	switch transactionType {
	case TransactionTypeSale:
		return "payable"
	case TransactionTypePurchase, TransactionTypeExpense:
		return "recoverable"
	case TransactionTypeReturn:
		return "neutral"
	default:
		return "payable"
	}
}

func taxcalcDBTaxType(line TaxLineDraft) string {
	if line.WithholdingAmount > 0 {
		return "withholding"
	}

	if line.TaxAmount == 0 {
		return "vat"
	}

	return "vat"
}

func taxcalcStatusColumn(columns map[string]taxcalcColumnInfo) string {
	if _, ok := columns["calculation_status"]; ok {
		return "calculation_status"
	}

	if _, ok := columns["tax_status"]; ok {
		return "tax_status"
	}

	if _, ok := columns["status"]; ok {
		return "status"
	}

	return ""
}

func taxcalcDBStatus(ctx context.Context, tx pgx.Tx, tableName string, columnName string, status TaxCalculationStatus) (string, error) {
	var definition string

	err := tx.QueryRow(ctx, `
SELECT pg_get_constraintdef(c.oid)
FROM pg_constraint c
WHERE c.conrelid = to_regclass('public.' || $1)
  AND pg_get_constraintdef(c.oid) ILIKE '%' || $2 || '%'
LIMIT 1;
`, tableName, columnName).Scan(&definition)

	if errors.Is(err, pgx.ErrNoRows) {
		return string(status), nil
	}

	if err != nil {
		return "", err
	}

	values := taxcalcConstraintValues(definition)
	if len(values) == 0 {
		return string(status), nil
	}

	if status == TaxCalculationStatusDraft {
		for _, candidate := range []string{"draft", "pending", "created", "open", "active"} {
			if containsTaxcalcValue(values, candidate) {
				return candidate, nil
			}
		}
	}

	if status == TaxCalculationStatusPosted {
		for _, candidate := range []string{"posted", "calculated", "confirmed", "active"} {
			if containsTaxcalcValue(values, candidate) {
				return candidate, nil
			}
		}
	}

	return values[0], nil
}

func taxcalcConstraintValues(definition string) []string {
	matches := regexp.MustCompile(`'([^']+)'`).FindAllStringSubmatch(definition, -1)

	values := make([]string, 0, len(matches))
	for _, match := range matches {
		if len(match) > 1 {
			values = append(values, match[1])
		}
	}

	return values
}

func containsTaxcalcValue(values []string, candidate string) bool {
	for _, value := range values {
		if value == candidate {
			return true
		}
	}

	return false
}

func taxcalcNullableString(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}

func taxcalcDefaultCurrency(value string) string {
	if strings.TrimSpace(value) == "" {
		return "TRY"
	}

	return strings.ToUpper(strings.TrimSpace(value))
}

func taxcalcDefaultExchangeRate(value float64) float64 {
	if value <= 0 {
		return 1
	}

	return value
}

func taxcalcNullableUUID(column taxcalcColumnInfo, value string) any {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}

	if column.UDTName == "uuid" && !taxcalcIsUUID(trimmed) {
		return nil
	}

	return trimmed
}

func taxcalcIsUUID(value string) bool {
	matched, _ := regexp.MatchString(`^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$`, value)
	return matched
}
