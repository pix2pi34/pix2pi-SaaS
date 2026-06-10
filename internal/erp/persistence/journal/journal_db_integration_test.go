package journal_test

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

func journalIntegrationDSN(t *testing.T) string {
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

func journalPSQL(t *testing.T, dsn string, sql string) string {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("psql failed\nsql:\n%s\nerror: %v\noutput:\n%s", sql, err, string(out))
	}

	return strings.TrimSpace(string(out))
}

func journalPSQLMustFail(t *testing.T, dsn string, sql string) {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err == nil {
		t.Fatalf("expected psql failure but command succeeded\nsql:\n%s\noutput:\n%s", sql, string(out))
	}
}

func TestJournalDBTablesExist(t *testing.T) {
	dsn := journalIntegrationDSN(t)

	got := journalPSQL(t, dsn, `
SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'erp_journal_entries',
    'erp_journal_lines'
  );
`)

	if got != "2" {
		t.Fatalf("expected 2 journal tables, got %s", got)
	}
}

func TestJournalDBIndexesExist(t *testing.T) {
	dsn := journalIntegrationDSN(t)

	got := journalPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'ux_erp_journal_entries_tenant_no',
    'ix_erp_journal_entries_tenant_date',
    'ix_erp_journal_entries_tenant_posting_date',
    'ix_erp_journal_entries_tenant_status',
    'ix_erp_journal_entries_tenant_source',
    'ix_erp_journal_entries_tenant_fiscal',
    'ix_erp_journal_entries_tenant_reversal',

    'ux_erp_journal_lines_tenant_entry_line',
    'ix_erp_journal_lines_tenant_account',
    'ix_erp_journal_lines_tenant_party',
    'ix_erp_journal_lines_tenant_customer',
    'ix_erp_journal_lines_tenant_vendor',
    'ix_erp_journal_lines_tenant_item',
    'ix_erp_journal_lines_tenant_cost_center',
    'ix_erp_journal_lines_tenant_project'
  );
`)

	if got != "15" {
		t.Fatalf("expected 15 journal indexes, got %s", got)
	}
}

func TestJournalDBRLSEnabledAndForced(t *testing.T) {
	dsn := journalIntegrationDSN(t)

	got := journalPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN (
    'erp_journal_entries',
    'erp_journal_lines'
  )
  AND c.relrowsecurity = true
  AND c.relforcerowsecurity = true;
`)

	if got != "2" {
		t.Fatalf("expected RLS enabled and forced on 2 journal tables, got %s", got)
	}
}

func TestJournalDBTenantPoliciesExist(t *testing.T) {
	dsn := journalIntegrationDSN(t)

	got := journalPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_policy p
JOIN pg_class c ON c.oid = p.polrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND p.polname IN (
    'erp_journal_entries_tenant_isolation_policy',
    'erp_journal_lines_tenant_isolation_policy'
  );
`)

	if got != "2" {
		t.Fatalf("expected 2 tenant isolation policies, got %s", got)
	}
}

func TestJournalDBAccountingChecksWork(t *testing.T) {
	dsn := journalIntegrationDSN(t)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	journalEntryID := journalPSQL(t, dsn, fmt.Sprintf(`
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
    'JRNL-CHECK-%s',
    CURRENT_DATE,
    CURRENT_DATE,
    2026,
    '2026-04',
    'manual',
    'test',
    'TRY',
    1,
    'Journal accounting check test %s',
    100.00,
    100.00,
    'posted',
    'faz3_journal_test'
)
RETURNING journal_entry_id;
`, unique, unique))

	defer func() {
		cleanupSQL := fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
DELETE FROM erp_journal_lines WHERE journal_entry_id = '%s';
DELETE FROM erp_journal_entries WHERE journal_entry_id = '%s';
`, journalEntryID, journalEntryID)

		_ = exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", cleanupSQL).Run()
	}()

	journalPSQL(t, dsn, fmt.Sprintf(`
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
    'Borc satiri',
    100.00,
    0.00,
    'TRY',
    1,
    100.00,
    0.00,
    'active',
    'faz3_journal_test'
);
`, journalEntryID))

	journalPSQL(t, dsn, fmt.Sprintf(`
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
    'Alacak satiri',
    0.00,
    100.00,
    'TRY',
    1,
    0.00,
    100.00,
    'active',
    'faz3_journal_test'
);
`, journalEntryID))

	lineCount := journalPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_journal_lines
WHERE journal_entry_id = '%s';
`, journalEntryID))

	if lineCount != "2" {
		t.Fatalf("expected 2 journal lines, got %s", lineCount)
	}

	journalPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_journal_lines (
    tenant_id,
    journal_entry_id,
    line_no,
    account_code,
    debit_amount,
    credit_amount,
    local_debit_amount,
    local_credit_amount
)
VALUES (
    'tenant_7',
    '%s',
    3,
    '999',
    100.00,
    100.00,
    100.00,
    100.00
);
`, journalEntryID))
}

func TestJournalDBTenantIsolationWorks(t *testing.T) {
	dsn := journalIntegrationDSN(t)

	isSuperUser := journalPSQL(t, dsn, `
SELECT rolsuper
FROM pg_roles
WHERE rolname = current_user;
`)

	if isSuperUser == "t" {
		t.Skip("current DB user is superuser; PostgreSQL superuser bypasses RLS behavior checks")
	}

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	journalEntryID := journalPSQL(t, dsn, fmt.Sprintf(`
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
    'JRNL-RLS-%s',
    CURRENT_DATE,
    CURRENT_DATE,
    2026,
    '2026-04',
    'manual',
    'test',
    'TRY',
    1,
    'Journal RLS test %s',
    120.00,
    120.00,
    'posted',
    'faz3_journal_rls_test'
)
RETURNING journal_entry_id;
`, unique, unique))

	journalLineID := journalPSQL(t, dsn, fmt.Sprintf(`
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
    'Tenant isolation debit line %s',
    120.00,
    0.00,
    'TRY',
    1,
    120.00,
    0.00,
    'active',
    'faz3_journal_rls_test'
)
RETURNING journal_line_id;
`, journalEntryID, unique))

	defer func() {
		cleanupSQL := fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
DELETE FROM erp_journal_lines WHERE journal_line_id = '%s';
DELETE FROM erp_journal_entries WHERE journal_entry_id = '%s';
`, journalLineID, journalEntryID)

		_ = exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", cleanupSQL).Run()
	}()

	visibleForTenant7 := journalPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_journal_entries
WHERE journal_entry_id = '%s';
`, journalEntryID))

	if visibleForTenant7 != "1" {
		t.Fatalf("expected tenant_7 to see inserted journal entry, got %s", visibleForTenant7)
	}

	visibleForTenant99 := journalPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_99';
SELECT COUNT(*)
FROM erp_journal_entries
WHERE journal_entry_id = '%s';
`, journalEntryID))

	if visibleForTenant99 != "0" {
		t.Fatalf("expected tenant_99 not to see tenant_7 journal entry, got %s", visibleForTenant99)
	}

	journalPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_journal_entries (
    tenant_id,
    journal_no,
    journal_date,
    source_module,
    total_debit,
    total_credit,
    status
)
VALUES (
    'tenant_99',
    'BAD-JRNL-%s',
    CURRENT_DATE,
    'manual',
    0.00,
    0.00,
    'draft'
);
`, unique))
}
