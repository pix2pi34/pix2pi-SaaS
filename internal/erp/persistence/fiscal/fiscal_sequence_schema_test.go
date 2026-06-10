package fiscal_test

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

func TestFiscalSequenceMigrationCreatesCoreTables(t *testing.T) {
	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")

	expectedTables := []string{
		"CREATE TABLE IF NOT EXISTS erp_fiscal_years",
		"CREATE TABLE IF NOT EXISTS erp_fiscal_periods",
		"CREATE TABLE IF NOT EXISTS erp_document_sequences",
		"CREATE TABLE IF NOT EXISTS erp_document_number_allocations",
	}

	for _, table := range expectedTables {
		assertContains(t, sql, table)
	}
}

func TestFiscalSequenceMigrationHasTenantAndAuditColumns(t *testing.T) {
	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")

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

func TestFiscalSequenceMigrationHasFiscalFields(t *testing.T) {
	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")

	expectedFields := []string{
		"fiscal_year INTEGER NOT NULL",
		"year_start_date DATE NOT NULL",
		"year_end_date DATE NOT NULL",
		"fiscal_period TEXT NOT NULL",
		"period_no INTEGER NOT NULL",
		"period_start_date DATE NOT NULL",
		"period_end_date DATE NOT NULL",
		"closed_at TIMESTAMPTZ",
		"closed_by TEXT",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestFiscalSequenceMigrationHasSequenceFields(t *testing.T) {
	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")

	expectedFields := []string{
		"document_module TEXT NOT NULL",
		"document_type TEXT NOT NULL",
		"prefix TEXT NOT NULL DEFAULT ''",
		"suffix TEXT NOT NULL DEFAULT ''",
		"current_no BIGINT NOT NULL DEFAULT 0",
		"min_no BIGINT NOT NULL DEFAULT 1",
		"max_no BIGINT",
		"padding INTEGER NOT NULL DEFAULT 6",
		"reset_policy TEXT NOT NULL DEFAULT 'yearly'",
		"document_no TEXT NOT NULL",
		"allocated_no BIGINT NOT NULL",
		"allocation_status TEXT NOT NULL DEFAULT 'allocated'",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestFiscalSequenceMigrationHasChecks(t *testing.T) {
	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")

	expectedChecks := []string{
		"erp_fiscal_years_year_chk",
		"fiscal_year >= 2000 AND fiscal_year <= 2100",
		"erp_fiscal_periods_period_no_chk",
		"period_no >= 1 AND period_no <= 13",
		"erp_document_sequences_module_chk",
		"document_module IN ('sales', 'procurement', 'journal', 'ledger', 'cashbank', 'inventory', 'tax', 'system')",
		"erp_document_sequences_reset_policy_chk",
		"reset_policy IN ('never', 'yearly', 'monthly', 'daily')",
		"erp_document_number_allocations_status_chk",
		"allocation_status IN ('allocated', 'confirmed', 'cancelled')",
	}

	for _, check := range expectedChecks {
		assertContains(t, sql, check)
	}
}

func TestFiscalSequenceMigrationHasTenantIndexes(t *testing.T) {
	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")

	expectedIndexes := []string{
		"ux_erp_fiscal_years_tenant_year",
		"ix_erp_fiscal_years_tenant_status",
		"ux_erp_fiscal_periods_tenant_period",
		"ux_erp_fiscal_periods_tenant_year_no",
		"ix_erp_fiscal_periods_tenant_status",
		"ux_erp_document_sequences_tenant_module_type_year",
		"ix_erp_document_sequences_tenant_module",
		"ix_erp_document_sequences_tenant_active",
		"ux_erp_document_number_allocations_tenant_no",
		"ix_erp_document_number_allocations_tenant_sequence",
		"ix_erp_document_number_allocations_tenant_fiscal",
		"ix_erp_document_number_allocations_tenant_status",
	}

	for _, index := range expectedIndexes {
		assertContains(t, sql, index)
	}
}

func TestFiscalSequenceMigrationEnablesForcedRLS(t *testing.T) {
	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")

	expectedRLS := []string{
		"ALTER TABLE erp_fiscal_years ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_fiscal_periods ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_document_sequences ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_document_number_allocations ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_fiscal_years FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_fiscal_periods FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_document_sequences FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_document_number_allocations FORCE ROW LEVEL SECURITY",
	}

	for _, rls := range expectedRLS {
		assertContains(t, sql, rls)
	}
}

func TestFiscalSequenceMigrationHasTenantIsolationPolicies(t *testing.T) {
	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")

	expectedPolicies := []string{
		"erp_fiscal_years_tenant_isolation_policy",
		"erp_fiscal_periods_tenant_isolation_policy",
		"erp_document_sequences_tenant_isolation_policy",
		"erp_document_number_allocations_tenant_isolation_policy",
		"tenant_id = current_setting('app.tenant_id', true)",
	}

	for _, policy := range expectedPolicies {
		assertContains(t, sql, policy)
	}
}

func TestFiscalSequenceRollbackDropsTablesInSafeOrder(t *testing.T) {
	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.down.sql")

	expectedDrops := []string{
		"DROP TABLE IF EXISTS erp_document_number_allocations",
		"DROP TABLE IF EXISTS erp_document_sequences",
		"DROP TABLE IF EXISTS erp_fiscal_periods",
		"DROP TABLE IF EXISTS erp_fiscal_years",
	}

	for _, drop := range expectedDrops {
		assertContains(t, sql, drop)
	}
}
