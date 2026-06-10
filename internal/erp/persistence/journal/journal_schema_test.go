package journal_test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func repoRoot(t *testing.T) string {
	t.Helper()

	dir, err := os.Getwd()
	if err != nil {
		t.Fatalf("get working dir: %v", err)
	}

	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir
		}

		parent := filepath.Dir(dir)
		if parent == dir {
			t.Fatal("repo root not found: go.mod missing")
		}

		dir = parent
	}
}

func readMigration(t *testing.T, name string) string {
	t.Helper()

	path := filepath.Join(repoRoot(t), "db", "migrations", name)

	b, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read migration %s: %v", name, err)
	}

	return string(b)
}

func assertContains(t *testing.T, body string, expected string) {
	t.Helper()

	if !strings.Contains(body, expected) {
		t.Fatalf("migration missing expected SQL fragment:\n%s", expected)
	}
}

func TestJournalMigrationCreatesCoreTables(t *testing.T) {
	sql := readMigration(t, "20260425_096001_erp_journal.up.sql")

	expectedTables := []string{
		"CREATE TABLE IF NOT EXISTS erp_journal_entries",
		"CREATE TABLE IF NOT EXISTS erp_journal_lines",
	}

	for _, table := range expectedTables {
		assertContains(t, sql, table)
	}
}

func TestJournalMigrationHasTenantAndAuditColumns(t *testing.T) {
	sql := readMigration(t, "20260425_096001_erp_journal.up.sql")

	expectedColumns := []string{
		"tenant_id TEXT NOT NULL",
		"created_at TIMESTAMPTZ NOT NULL DEFAULT now()",
		"updated_at TIMESTAMPTZ NOT NULL DEFAULT now()",
		"deleted_at TIMESTAMPTZ",
		"created_by TEXT",
		"updated_by TEXT",
	}

	for _, column := range expectedColumns {
		assertContains(t, sql, column)
	}
}

func TestJournalMigrationHasHeaderFields(t *testing.T) {
	sql := readMigration(t, "20260425_096001_erp_journal.up.sql")

	expectedFields := []string{
		"journal_no TEXT NOT NULL",
		"journal_date DATE NOT NULL DEFAULT CURRENT_DATE",
		"posting_date DATE",
		"fiscal_year INTEGER",
		"fiscal_period TEXT",
		"source_module TEXT NOT NULL DEFAULT 'manual'",
		"source_document_type TEXT",
		"source_document_id UUID",
		"currency_code TEXT NOT NULL DEFAULT 'TRY'",
		"exchange_rate NUMERIC(18, 6) NOT NULL DEFAULT 1",
		"total_debit NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"total_credit NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"status TEXT NOT NULL DEFAULT 'draft'",
		"posted_at TIMESTAMPTZ",
		"reversal_journal_entry_id UUID REFERENCES erp_journal_entries",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestJournalMigrationHasLineFields(t *testing.T) {
	sql := readMigration(t, "20260425_096001_erp_journal.up.sql")

	expectedFields := []string{
		"journal_entry_id UUID NOT NULL REFERENCES erp_journal_entries",
		"line_no INTEGER NOT NULL",
		"account_code TEXT NOT NULL",
		"account_name TEXT",
		"debit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"credit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"local_debit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"local_credit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"party_id UUID REFERENCES erp_parties",
		"customer_id UUID REFERENCES erp_customers",
		"vendor_id UUID REFERENCES erp_vendors",
		"item_id UUID REFERENCES erp_items",
		"cost_center_code TEXT",
		"project_code TEXT",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestJournalMigrationHasAccountingChecks(t *testing.T) {
	sql := readMigration(t, "20260425_096001_erp_journal.up.sql")

	expectedChecks := []string{
		"erp_journal_entries_posted_balance_chk",
		"status <> 'posted'",
		"OR total_debit = total_credit",
		"erp_journal_lines_amount_chk",
		"(debit_amount > 0 AND credit_amount = 0)",
		"(credit_amount > 0 AND debit_amount = 0)",
		"(local_debit_amount > 0 AND local_credit_amount = 0)",
		"(local_credit_amount > 0 AND local_debit_amount = 0)",
	}

	for _, check := range expectedChecks {
		assertContains(t, sql, check)
	}
}

func TestJournalMigrationHasTenantIndexes(t *testing.T) {
	sql := readMigration(t, "20260425_096001_erp_journal.up.sql")

	expectedIndexes := []string{
		"ux_erp_journal_entries_tenant_no",
		"ix_erp_journal_entries_tenant_date",
		"ix_erp_journal_entries_tenant_posting_date",
		"ix_erp_journal_entries_tenant_status",
		"ix_erp_journal_entries_tenant_source",
		"ix_erp_journal_entries_tenant_fiscal",
		"ux_erp_journal_lines_tenant_entry_line",
		"ix_erp_journal_lines_tenant_account",
		"ix_erp_journal_lines_tenant_party",
		"ix_erp_journal_lines_tenant_customer",
		"ix_erp_journal_lines_tenant_vendor",
		"ix_erp_journal_lines_tenant_item",
		"ix_erp_journal_lines_tenant_cost_center",
		"ix_erp_journal_lines_tenant_project",
	}

	for _, index := range expectedIndexes {
		assertContains(t, sql, index)
	}
}

func TestJournalMigrationEnablesForcedRLS(t *testing.T) {
	sql := readMigration(t, "20260425_096001_erp_journal.up.sql")

	expectedRLS := []string{
		"ALTER TABLE erp_journal_entries ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_journal_lines ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_journal_entries FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_journal_lines FORCE ROW LEVEL SECURITY",
	}

	for _, rls := range expectedRLS {
		assertContains(t, sql, rls)
	}
}

func TestJournalMigrationHasTenantIsolationPolicies(t *testing.T) {
	sql := readMigration(t, "20260425_096001_erp_journal.up.sql")

	expectedPolicies := []string{
		"erp_journal_entries_tenant_isolation_policy",
		"erp_journal_lines_tenant_isolation_policy",
		"tenant_id = current_setting('app.tenant_id', true)",
	}

	for _, policy := range expectedPolicies {
		assertContains(t, sql, policy)
	}
}

func TestJournalRollbackDropsTablesInSafeOrder(t *testing.T) {
	sql := readMigration(t, "20260425_096001_erp_journal.down.sql")

	expectedDrops := []string{
		"DROP TABLE IF EXISTS erp_journal_lines",
		"DROP TABLE IF EXISTS erp_journal_entries",
	}

	for _, drop := range expectedDrops {
		assertContains(t, sql, drop)
	}
}
