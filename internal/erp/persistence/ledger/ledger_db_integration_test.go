package ledger_test

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

func ledgerIntegrationDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping DB integration test")
	}

	return dsn
}

func ledgerPSQL(t *testing.T, dsn string, sql string) string {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("psql failed\nsql:\n%s\nerror: %v\noutput:\n%s", sql, err, string(out))
	}

	return strings.TrimSpace(string(out))
}

func ledgerPSQLMustFail(t *testing.T, dsn string, sql string) {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err == nil {
		t.Fatalf("expected psql failure but command succeeded\nsql:\n%s\noutput:\n%s", sql, string(out))
	}
}

func TestLedgerDBTablesExist(t *testing.T) {
	dsn := ledgerIntegrationDSN(t)

	got := ledgerPSQL(t, dsn, `
SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'erp_account_movements',
    'erp_ledger_balances'
  );
`)

	if got != "2" {
		t.Fatalf("expected 2 ledger tables, got %s", got)
	}
}

func TestLedgerDBIndexesExist(t *testing.T) {
	dsn := ledgerIntegrationDSN(t)

	got := ledgerPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'ux_erp_account_movements_tenant_journal_line',
    'ix_erp_account_movements_tenant_account_date',
    'ix_erp_account_movements_tenant_fiscal',
    'ix_erp_account_movements_tenant_source',
    'ix_erp_account_movements_tenant_party',
    'ix_erp_account_movements_tenant_customer',
    'ix_erp_account_movements_tenant_vendor',
    'ix_erp_account_movements_tenant_item',
    'ix_erp_account_movements_tenant_cost_center',
    'ix_erp_account_movements_tenant_project',

    'ux_erp_ledger_balances_tenant_period_account_dims',
    'ix_erp_ledger_balances_tenant_account',
    'ix_erp_ledger_balances_tenant_fiscal',
    'ix_erp_ledger_balances_tenant_party',
    'ix_erp_ledger_balances_tenant_customer',
    'ix_erp_ledger_balances_tenant_vendor',
    'ix_erp_ledger_balances_tenant_cost_center',
    'ix_erp_ledger_balances_tenant_project'
  );
`)

	if got != "18" {
		t.Fatalf("expected 18 ledger indexes, got %s", got)
	}
}

func TestLedgerDBRLSEnabledAndForced(t *testing.T) {
	dsn := ledgerIntegrationDSN(t)

	got := ledgerPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN (
    'erp_account_movements',
    'erp_ledger_balances'
  )
  AND c.relrowsecurity = true
  AND c.relforcerowsecurity = true;
`)

	if got != "2" {
		t.Fatalf("expected RLS enabled and forced on 2 ledger tables, got %s", got)
	}
}

func TestLedgerDBTenantPoliciesExist(t *testing.T) {
	dsn := ledgerIntegrationDSN(t)

	got := ledgerPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_policy p
JOIN pg_class c ON c.oid = p.polrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND p.polname IN (
    'erp_account_movements_tenant_isolation_policy',
    'erp_ledger_balances_tenant_isolation_policy'
  );
`)

	if got != "2" {
		t.Fatalf("expected 2 tenant isolation policies, got %s", got)
	}
}

func TestLedgerDBAccountingChecksWork(t *testing.T) {
	dsn := ledgerIntegrationDSN(t)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	journalEntryID, debitLineID, creditLineID := createLedgerJournalFixture(t, dsn, unique)

	defer cleanupLedgerFixture(t, dsn, journalEntryID)

	debitMovementID := ledgerPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_account_movements (
    tenant_id,
    journal_entry_id,
    journal_line_id,
    movement_date,
    posting_date,
    fiscal_year,
    fiscal_period,
    account_code,
    account_name,
    description,
    debit_amount,
    credit_amount,
    currency_code,
    exchange_rate,
    local_debit_amount,
    local_credit_amount,
    direction,
    source_module,
    source_document_type,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    '%s',
    CURRENT_DATE,
    CURRENT_DATE,
    2026,
    '2026-04',
    '120',
    'Alicilar',
    'Ledger debit movement %s',
    120.00,
    0.00,
    'TRY',
    1,
    120.00,
    0.00,
    'debit',
    'manual',
    'integration_test',
    'posted',
    'faz3_ledger_test'
)
RETURNING account_movement_id;
`, journalEntryID, debitLineID, unique))

	creditMovementID := ledgerPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_account_movements (
    tenant_id,
    journal_entry_id,
    journal_line_id,
    movement_date,
    posting_date,
    fiscal_year,
    fiscal_period,
    account_code,
    account_name,
    description,
    debit_amount,
    credit_amount,
    currency_code,
    exchange_rate,
    local_debit_amount,
    local_credit_amount,
    direction,
    source_module,
    source_document_type,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    '%s',
    CURRENT_DATE,
    CURRENT_DATE,
    2026,
    '2026-04',
    '600',
    'Yurt Ici Satislar',
    'Ledger credit movement %s',
    0.00,
    120.00,
    'TRY',
    1,
    0.00,
    120.00,
    'credit',
    'manual',
    'integration_test',
    'posted',
    'faz3_ledger_test'
)
RETURNING account_movement_id;
`, journalEntryID, creditLineID, unique))

	if debitMovementID == "" || creditMovementID == "" {
		t.Fatal("expected account movement ids")
	}

	balanceID := ledgerPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_ledger_balances (
    tenant_id,
    fiscal_year,
    fiscal_period,
    account_code,
    account_name,
    currency_code,
    opening_debit_amount,
    opening_credit_amount,
    period_debit_amount,
    period_credit_amount,
    closing_debit_amount,
    closing_credit_amount,
    balance_side,
    balance_amount,
    status,
    calculated_at,
    created_by
)
VALUES (
    'tenant_7',
    2026,
    '2026-04',
    '120',
    'Alicilar',
    'TRY',
    0.00,
    0.00,
    120.00,
    0.00,
    120.00,
    0.00,
    'debit',
    120.00,
    'active',
    now(),
    'faz3_ledger_test'
)
RETURNING ledger_balance_id;
`))

	if balanceID == "" {
		t.Fatal("expected ledger balance id")
	}

	movementCount := ledgerPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_account_movements
WHERE journal_entry_id = '%s';
`, journalEntryID))

	if movementCount != "2" {
		t.Fatalf("expected 2 account movements, got %s", movementCount)
	}

	ledgerPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_account_movements (
    tenant_id,
    journal_entry_id,
    journal_line_id,
    movement_date,
    posting_date,
    fiscal_year,
    fiscal_period,
    account_code,
    debit_amount,
    credit_amount,
    currency_code,
    exchange_rate,
    local_debit_amount,
    local_credit_amount,
    direction,
    source_module
)
VALUES (
    'tenant_7',
    '%s',
    '%s',
    CURRENT_DATE,
    CURRENT_DATE,
    2026,
    '2026-04',
    '999',
    120.00,
    120.00,
    'TRY',
    1,
    120.00,
    120.00,
    'debit',
    'manual'
);
`, journalEntryID, creditLineID))
}

func TestLedgerDBTenantIsolationWorks(t *testing.T) {
	dsn := ledgerIntegrationDSN(t)

	isSuperUser := ledgerPSQL(t, dsn, `
SELECT rolsuper
FROM pg_roles
WHERE rolname = current_user;
`)

	if isSuperUser == "t" {
		t.Skip("current DB user is superuser; PostgreSQL superuser bypasses RLS behavior checks")
	}

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	journalEntryID, debitLineID, _ := createLedgerJournalFixture(t, dsn, unique)

	defer cleanupLedgerFixture(t, dsn, journalEntryID)

	movementID := ledgerPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_account_movements (
    tenant_id,
    journal_entry_id,
    journal_line_id,
    movement_date,
    posting_date,
    fiscal_year,
    fiscal_period,
    account_code,
    account_name,
    description,
    debit_amount,
    credit_amount,
    currency_code,
    exchange_rate,
    local_debit_amount,
    local_credit_amount,
    direction,
    source_module,
    source_document_type,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    '%s',
    CURRENT_DATE,
    CURRENT_DATE,
    2026,
    '2026-04',
    '120',
    'Alicilar',
    'Ledger tenant isolation movement %s',
    120.00,
    0.00,
    'TRY',
    1,
    120.00,
    0.00,
    'debit',
    'manual',
    'integration_test',
    'posted',
    'faz3_ledger_rls_test'
)
RETURNING account_movement_id;
`, journalEntryID, debitLineID, unique))

	visibleForTenant7 := ledgerPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_account_movements
WHERE account_movement_id = '%s';
`, movementID))

	if visibleForTenant7 != "1" {
		t.Fatalf("expected tenant_7 to see inserted account movement, got %s", visibleForTenant7)
	}

	visibleForTenant99 := ledgerPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_99';
SELECT COUNT(*)
FROM erp_account_movements
WHERE account_movement_id = '%s';
`, movementID))

	if visibleForTenant99 != "0" {
		t.Fatalf("expected tenant_99 not to see tenant_7 account movement, got %s", visibleForTenant99)
	}

	ledgerPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_ledger_balances (
    tenant_id,
    fiscal_year,
    fiscal_period,
    account_code,
    currency_code,
    balance_side,
    balance_amount
)
VALUES (
    'tenant_99',
    2026,
    '2026-04',
    '120',
    'TRY',
    'zero',
    0.00
);
`))
}

func createLedgerJournalFixture(t *testing.T, dsn string, unique string) (string, string, string) {
	t.Helper()

	journalEntryID := ledgerPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_journal_entries (
    tenant_id,
    journal_no,
    journal_date,
    posting_date,
    fiscal_year,
    fiscal_period,
    source_module,
    source_document_type,
    currency_code,
    exchange_rate,
    description,
    total_debit,
    total_credit,
    status,
    created_by
)
VALUES (
    'tenant_7',
    'LEDGER-JRNL-%s',
    CURRENT_DATE,
    CURRENT_DATE,
    2026,
    '2026-04',
    'manual',
    'integration_test',
    'TRY',
    1,
    'Ledger fixture journal %s',
    120.00,
    120.00,
    'posted',
    'faz3_ledger_test'
)
RETURNING journal_entry_id;
`, unique, unique))

	debitLineID := ledgerPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_journal_lines (
    tenant_id,
    journal_entry_id,
    line_no,
    account_code,
    account_name,
    description,
    debit_amount,
    credit_amount,
    currency_code,
    exchange_rate,
    local_debit_amount,
    local_credit_amount,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    1,
    '120',
    'Alicilar',
    'Ledger fixture debit line %s',
    120.00,
    0.00,
    'TRY',
    1,
    120.00,
    0.00,
    'active',
    'faz3_ledger_test'
)
RETURNING journal_line_id;
`, journalEntryID, unique))

	creditLineID := ledgerPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_journal_lines (
    tenant_id,
    journal_entry_id,
    line_no,
    account_code,
    account_name,
    description,
    debit_amount,
    credit_amount,
    currency_code,
    exchange_rate,
    local_debit_amount,
    local_credit_amount,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    2,
    '600',
    'Yurt Ici Satislar',
    'Ledger fixture credit line %s',
    0.00,
    120.00,
    'TRY',
    1,
    0.00,
    120.00,
    'active',
    'faz3_ledger_test'
)
RETURNING journal_line_id;
`, journalEntryID, unique))

	return journalEntryID, debitLineID, creditLineID
}

func cleanupLedgerFixture(t *testing.T, dsn string, journalEntryID string) {
	t.Helper()

	cleanupSQL := fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

DELETE FROM erp_ledger_balances
WHERE tenant_id = 'tenant_7'
  AND account_code IN ('120', '600', '999');

DELETE FROM erp_account_movements
WHERE journal_entry_id = '%s';

DELETE FROM erp_journal_lines
WHERE journal_entry_id = '%s';

DELETE FROM erp_journal_entries
WHERE journal_entry_id = '%s';
`, journalEntryID, journalEntryID, journalEntryID)

	_ = exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", cleanupSQL).Run()
}
