package ledger_test

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

func TestLedgerMigrationCreatesCoreTables(t *testing.T) {
	sql := readMigration(t, "20260425_097001_erp_ledger.up.sql")

	expectedTables := []string{
		"CREATE TABLE IF NOT EXISTS erp_account_movements",
		"CREATE TABLE IF NOT EXISTS erp_ledger_balances",
	}

	for _, table := range expectedTables {
		assertContains(t, sql, table)
	}
}

func TestLedgerMigrationHasTenantAndAuditColumns(t *testing.T) {
	sql := readMigration(t, "20260425_097001_erp_ledger.up.sql")

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

func TestLedgerMigrationHasMovementFields(t *testing.T) {
	sql := readMigration(t, "20260425_097001_erp_ledger.up.sql")

	expectedFields := []string{
		"journal_entry_id UUID NOT NULL REFERENCES erp_journal_entries",
		"journal_line_id UUID NOT NULL REFERENCES erp_journal_lines",
		"movement_date DATE NOT NULL DEFAULT CURRENT_DATE",
		"posting_date DATE NOT NULL DEFAULT CURRENT_DATE",
		"fiscal_year INTEGER NOT NULL",
		"fiscal_period TEXT NOT NULL",
		"account_code TEXT NOT NULL",
		"debit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"credit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"local_debit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"local_credit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"direction TEXT NOT NULL",
		"source_module TEXT NOT NULL DEFAULT 'manual'",
		"source_document_type TEXT",
		"source_document_id UUID",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestLedgerMigrationHasBalanceFields(t *testing.T) {
	sql := readMigration(t, "20260425_097001_erp_ledger.up.sql")

	expectedFields := []string{
		"opening_debit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"opening_credit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"period_debit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"period_credit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"closing_debit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"closing_credit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"balance_side TEXT NOT NULL DEFAULT 'zero'",
		"balance_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"calculated_at TIMESTAMPTZ",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestLedgerMigrationHasAccountingChecks(t *testing.T) {
	sql := readMigration(t, "20260425_097001_erp_ledger.up.sql")

	expectedChecks := []string{
		"erp_account_movements_direction_chk",
		"direction IN ('debit', 'credit')",
		"erp_account_movements_amount_chk",
		"(direction = 'debit' AND debit_amount > 0 AND credit_amount = 0",
		"(direction = 'credit' AND credit_amount > 0 AND debit_amount = 0",
		"erp_ledger_balances_balance_side_chk",
		"balance_side IN ('debit', 'credit', 'zero')",
		"erp_ledger_balances_amount_chk",
	}

	for _, check := range expectedChecks {
		assertContains(t, sql, check)
	}
}

func TestLedgerMigrationHasTenantIndexes(t *testing.T) {
	sql := readMigration(t, "20260425_097001_erp_ledger.up.sql")

	expectedIndexes := []string{
		"ux_erp_account_movements_tenant_journal_line",
		"ix_erp_account_movements_tenant_account_date",
		"ix_erp_account_movements_tenant_fiscal",
		"ix_erp_account_movements_tenant_source",
		"ix_erp_account_movements_tenant_party",
		"ix_erp_account_movements_tenant_customer",
		"ix_erp_account_movements_tenant_vendor",
		"ix_erp_account_movements_tenant_item",
		"ux_erp_ledger_balances_tenant_period_account_dims",
		"ix_erp_ledger_balances_tenant_account",
		"ix_erp_ledger_balances_tenant_fiscal",
		"ix_erp_ledger_balances_tenant_party",
		"ix_erp_ledger_balances_tenant_customer",
		"ix_erp_ledger_balances_tenant_vendor",
	}

	for _, index := range expectedIndexes {
		assertContains(t, sql, index)
	}
}

func TestLedgerMigrationEnablesForcedRLS(t *testing.T) {
	sql := readMigration(t, "20260425_097001_erp_ledger.up.sql")

	expectedRLS := []string{
		"ALTER TABLE erp_account_movements ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_ledger_balances ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_account_movements FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_ledger_balances FORCE ROW LEVEL SECURITY",
	}

	for _, rls := range expectedRLS {
		assertContains(t, sql, rls)
	}
}

func TestLedgerMigrationHasTenantIsolationPolicies(t *testing.T) {
	sql := readMigration(t, "20260425_097001_erp_ledger.up.sql")

	expectedPolicies := []string{
		"erp_account_movements_tenant_isolation_policy",
		"erp_ledger_balances_tenant_isolation_policy",
		"tenant_id = current_setting('app.tenant_id', true)",
	}

	for _, policy := range expectedPolicies {
		assertContains(t, sql, policy)
	}
}

func TestLedgerRollbackDropsTablesInSafeOrder(t *testing.T) {
	sql := readMigration(t, "20260425_097001_erp_ledger.down.sql")

	expectedDrops := []string{
		"DROP TABLE IF EXISTS erp_ledger_balances",
		"DROP TABLE IF EXISTS erp_account_movements",
	}

	for _, drop := range expectedDrops {
		assertContains(t, sql, drop)
	}
}
