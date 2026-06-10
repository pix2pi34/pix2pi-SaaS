package cashbank_test

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

func TestCashBankMigrationCreatesCoreTables(t *testing.T) {
	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")

	expectedTables := []string{
		"CREATE TABLE IF NOT EXISTS erp_cash_accounts",
		"CREATE TABLE IF NOT EXISTS erp_bank_accounts",
		"CREATE TABLE IF NOT EXISTS erp_payment_transactions",
	}

	for _, table := range expectedTables {
		assertContains(t, sql, table)
	}
}

func TestCashBankMigrationHasTenantAndAuditColumns(t *testing.T) {
	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")

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

func TestCashBankMigrationHasAccountFields(t *testing.T) {
	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")

	expectedFields := []string{
		"cash_code TEXT NOT NULL",
		"cash_name TEXT NOT NULL",
		"bank_code TEXT NOT NULL",
		"bank_name TEXT NOT NULL",
		"iban TEXT",
		"account_no TEXT",
		"account_code TEXT",
		"currency_code TEXT NOT NULL DEFAULT 'TRY'",
		"opening_balance NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"current_balance NUMERIC(18, 2) NOT NULL DEFAULT 0",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestCashBankMigrationHasPaymentFields(t *testing.T) {
	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")

	expectedFields := []string{
		"payment_no TEXT NOT NULL",
		"payment_date DATE NOT NULL DEFAULT CURRENT_DATE",
		"payment_type TEXT NOT NULL",
		"payment_direction TEXT NOT NULL",
		"payment_method TEXT NOT NULL",
		"cash_account_id UUID REFERENCES erp_cash_accounts",
		"bank_account_id UUID REFERENCES erp_bank_accounts",
		"journal_entry_id UUID REFERENCES erp_journal_entries",
		"amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"local_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"fee_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"net_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestCashBankMigrationHasAccountingChecks(t *testing.T) {
	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")

	expectedChecks := []string{
		"erp_payment_transactions_payment_type_chk",
		"payment_type IN ('collection', 'payment', 'transfer', 'refund', 'fee', 'adjustment')",
		"erp_payment_transactions_direction_chk",
		"payment_direction IN ('in', 'out', 'neutral')",
		"erp_payment_transactions_method_chk",
		"payment_method IN ('cash', 'bank_transfer', 'credit_card', 'debit_card', 'pos', 'check', 'promissory_note', 'other')",
		"erp_payment_transactions_account_presence_chk",
	}

	for _, check := range expectedChecks {
		assertContains(t, sql, check)
	}
}

func TestCashBankMigrationHasTenantIndexes(t *testing.T) {
	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")

	expectedIndexes := []string{
		"ux_erp_cash_accounts_tenant_code",
		"ix_erp_cash_accounts_tenant_account",
		"ux_erp_bank_accounts_tenant_code",
		"ix_erp_bank_accounts_tenant_iban",
		"ux_erp_payment_transactions_tenant_no",
		"ix_erp_payment_transactions_tenant_date",
		"ix_erp_payment_transactions_tenant_type",
		"ix_erp_payment_transactions_tenant_direction",
		"ix_erp_payment_transactions_tenant_method",
		"ix_erp_payment_transactions_tenant_cash",
		"ix_erp_payment_transactions_tenant_bank",
		"ix_erp_payment_transactions_tenant_source",
	}

	for _, index := range expectedIndexes {
		assertContains(t, sql, index)
	}
}

func TestCashBankMigrationEnablesForcedRLS(t *testing.T) {
	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")

	expectedRLS := []string{
		"ALTER TABLE erp_cash_accounts ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_bank_accounts ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_payment_transactions ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_cash_accounts FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_bank_accounts FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_payment_transactions FORCE ROW LEVEL SECURITY",
	}

	for _, rls := range expectedRLS {
		assertContains(t, sql, rls)
	}
}

func TestCashBankMigrationHasTenantIsolationPolicies(t *testing.T) {
	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")

	expectedPolicies := []string{
		"erp_cash_accounts_tenant_isolation_policy",
		"erp_bank_accounts_tenant_isolation_policy",
		"erp_payment_transactions_tenant_isolation_policy",
		"tenant_id = current_setting('app.tenant_id', true)",
	}

	for _, policy := range expectedPolicies {
		assertContains(t, sql, policy)
	}
}

func TestCashBankRollbackDropsTablesInSafeOrder(t *testing.T) {
	sql := readMigration(t, "20260425_0910001_erp_cashbank.down.sql")

	expectedDrops := []string{
		"DROP TABLE IF EXISTS erp_payment_transactions",
		"DROP TABLE IF EXISTS erp_bank_accounts",
		"DROP TABLE IF EXISTS erp_cash_accounts",
	}

	for _, drop := range expectedDrops {
		assertContains(t, sql, drop)
	}
}
