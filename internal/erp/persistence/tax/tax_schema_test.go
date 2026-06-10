package tax_test

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

func TestTaxMigrationCreatesCoreTables(t *testing.T) {
	sql := readMigration(t, "20260425_099001_erp_tax.up.sql")

	expectedTables := []string{
		"CREATE TABLE IF NOT EXISTS erp_tax_codes",
		"CREATE TABLE IF NOT EXISTS erp_tax_rates",
		"CREATE TABLE IF NOT EXISTS erp_tax_transactions",
	}

	for _, table := range expectedTables {
		assertContains(t, sql, table)
	}
}

func TestTaxMigrationHasTenantAndAuditColumns(t *testing.T) {
	sql := readMigration(t, "20260425_099001_erp_tax.up.sql")

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

func TestTaxMigrationHasTaxCodeFields(t *testing.T) {
	sql := readMigration(t, "20260425_099001_erp_tax.up.sql")

	expectedFields := []string{
		"tax_code TEXT NOT NULL",
		"tax_name TEXT NOT NULL",
		"tax_type TEXT NOT NULL",
		"account_code TEXT",
		"account_name TEXT",
		"is_recoverable BOOLEAN NOT NULL DEFAULT false",
		"is_payable BOOLEAN NOT NULL DEFAULT true",
		"is_withholding BOOLEAN NOT NULL DEFAULT false",
		"is_active BOOLEAN NOT NULL DEFAULT true",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestTaxMigrationHasTaxRateFields(t *testing.T) {
	sql := readMigration(t, "20260425_099001_erp_tax.up.sql")

	expectedFields := []string{
		"tax_code_id UUID NOT NULL REFERENCES erp_tax_codes",
		"rate_percent NUMERIC(5, 2) NOT NULL DEFAULT 0",
		"withholding_numerator INTEGER",
		"withholding_denominator INTEGER",
		"valid_from DATE NOT NULL DEFAULT CURRENT_DATE",
		"valid_to DATE",
		"is_default BOOLEAN NOT NULL DEFAULT false",
		"is_active BOOLEAN NOT NULL DEFAULT true",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestTaxMigrationHasTaxTransactionFields(t *testing.T) {
	sql := readMigration(t, "20260425_099001_erp_tax.up.sql")

	expectedFields := []string{
		"source_module TEXT NOT NULL",
		"source_document_type TEXT",
		"source_document_id UUID",
		"source_line_id UUID",
		"journal_entry_id UUID REFERENCES erp_journal_entries",
		"journal_line_id UUID REFERENCES erp_journal_lines",
		"transaction_date DATE NOT NULL DEFAULT CURRENT_DATE",
		"fiscal_year INTEGER NOT NULL",
		"fiscal_period TEXT NOT NULL",
		"base_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"tax_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"withholding_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"payable_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"recoverable_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
		"direction TEXT NOT NULL",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestTaxMigrationHasAccountingChecks(t *testing.T) {
	sql := readMigration(t, "20260425_099001_erp_tax.up.sql")

	expectedChecks := []string{
		"erp_tax_codes_tax_type_chk",
		"tax_type IN ('vat', 'withholding', 'stamp', 'excise', 'income_tax', 'corporate_tax', 'other')",
		"erp_tax_rates_rate_chk",
		"rate_percent >= 0 AND rate_percent <= 100",
		"erp_tax_rates_withholding_ratio_chk",
		"erp_tax_transactions_direction_chk",
		"direction IN ('payable', 'recoverable', 'neutral')",
		"erp_tax_transactions_amount_chk",
	}

	for _, check := range expectedChecks {
		assertContains(t, sql, check)
	}
}

func TestTaxMigrationHasTenantIndexes(t *testing.T) {
	sql := readMigration(t, "20260425_099001_erp_tax.up.sql")

	expectedIndexes := []string{
		"ux_erp_tax_codes_tenant_code",
		"ix_erp_tax_codes_tenant_type",
		"ix_erp_tax_codes_tenant_account",
		"ix_erp_tax_rates_tenant_code",
		"ix_erp_tax_rates_tenant_tax_code_id",
		"ix_erp_tax_rates_tenant_valid",
		"ix_erp_tax_transactions_tenant_code_date",
		"ix_erp_tax_transactions_tenant_type",
		"ix_erp_tax_transactions_tenant_fiscal",
		"ix_erp_tax_transactions_tenant_source",
		"ix_erp_tax_transactions_tenant_journal",
		"ix_erp_tax_transactions_tenant_direction",
	}

	for _, index := range expectedIndexes {
		assertContains(t, sql, index)
	}
}

func TestTaxMigrationEnablesForcedRLS(t *testing.T) {
	sql := readMigration(t, "20260425_099001_erp_tax.up.sql")

	expectedRLS := []string{
		"ALTER TABLE erp_tax_codes ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_tax_rates ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_tax_transactions ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_tax_codes FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_tax_rates FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_tax_transactions FORCE ROW LEVEL SECURITY",
	}

	for _, rls := range expectedRLS {
		assertContains(t, sql, rls)
	}
}

func TestTaxMigrationHasTenantIsolationPolicies(t *testing.T) {
	sql := readMigration(t, "20260425_099001_erp_tax.up.sql")

	expectedPolicies := []string{
		"erp_tax_codes_tenant_isolation_policy",
		"erp_tax_rates_tenant_isolation_policy",
		"erp_tax_transactions_tenant_isolation_policy",
		"tenant_id = current_setting('app.tenant_id', true)",
	}

	for _, policy := range expectedPolicies {
		assertContains(t, sql, policy)
	}
}

func TestTaxRollbackDropsTablesInSafeOrder(t *testing.T) {
	sql := readMigration(t, "20260425_099001_erp_tax.down.sql")

	expectedDrops := []string{
		"DROP TABLE IF EXISTS erp_tax_transactions",
		"DROP TABLE IF EXISTS erp_tax_rates",
		"DROP TABLE IF EXISTS erp_tax_codes",
	}

	for _, drop := range expectedDrops {
		assertContains(t, sql, drop)
	}
}
