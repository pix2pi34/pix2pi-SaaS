package chartofaccounts_test

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

func TestChartOfAccountsMigrationCreatesCoreTables(t *testing.T) {
	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")

	expectedTables := []string{
		"CREATE TABLE IF NOT EXISTS erp_chart_accounts",
		"CREATE TABLE IF NOT EXISTS erp_account_mapping_rules",
	}

	for _, table := range expectedTables {
		assertContains(t, sql, table)
	}
}

func TestChartOfAccountsMigrationHasTenantAndAuditColumns(t *testing.T) {
	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")

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

func TestChartOfAccountsMigrationHasAccountFields(t *testing.T) {
	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")

	expectedFields := []string{
		"account_code TEXT NOT NULL",
		"account_name TEXT NOT NULL",
		"parent_account_code TEXT",
		"account_level INTEGER NOT NULL DEFAULT 1",
		"account_class TEXT",
		"account_group TEXT",
		"account_type TEXT NOT NULL",
		"normal_balance TEXT NOT NULL",
		"is_postable BOOLEAN NOT NULL DEFAULT true",
		"is_active BOOLEAN NOT NULL DEFAULT true",
		"currency_code TEXT NOT NULL DEFAULT 'TRY'",
		"tax_code TEXT",
		"vat_rate NUMERIC(5, 2)",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestChartOfAccountsMigrationHasMappingFields(t *testing.T) {
	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")

	expectedFields := []string{
		"mapping_key TEXT NOT NULL",
		"source_module TEXT NOT NULL",
		"source_document_type TEXT",
		"event_type TEXT",
		"line_type TEXT",
		"account_code TEXT NOT NULL",
		"priority INTEGER NOT NULL DEFAULT 100",
		"is_default BOOLEAN NOT NULL DEFAULT false",
		"is_active BOOLEAN NOT NULL DEFAULT true",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestChartOfAccountsMigrationHasAccountingChecks(t *testing.T) {
	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")

	expectedChecks := []string{
		"erp_chart_accounts_account_type_chk",
		"account_type IN (",
		"'asset'",
		"'liability'",
		"'equity'",
		"'revenue'",
		"'expense'",
		"erp_chart_accounts_normal_balance_chk",
		"normal_balance IN ('debit', 'credit', 'zero')",
		"erp_account_mapping_rules_source_module_chk",
		"source_module IN ('manual', 'sales', 'procurement', 'payment', 'inventory', 'tax', 'export', 'system')",
	}

	for _, check := range expectedChecks {
		assertContains(t, sql, check)
	}
}

func TestChartOfAccountsMigrationHasTenantIndexes(t *testing.T) {
	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")

	expectedIndexes := []string{
		"ux_erp_chart_accounts_tenant_code",
		"ix_erp_chart_accounts_tenant_parent",
		"ix_erp_chart_accounts_tenant_type",
		"ix_erp_chart_accounts_tenant_class_group",
		"ix_erp_chart_accounts_tenant_postable",
		"ix_erp_chart_accounts_tenant_tax",
		"ux_erp_account_mapping_rules_tenant_key",
		"ix_erp_account_mapping_rules_tenant_source",
		"ix_erp_account_mapping_rules_tenant_event_line",
		"ix_erp_account_mapping_rules_tenant_account",
		"ix_erp_account_mapping_rules_tenant_priority",
	}

	for _, index := range expectedIndexes {
		assertContains(t, sql, index)
	}
}

func TestChartOfAccountsMigrationEnablesForcedRLS(t *testing.T) {
	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")

	expectedRLS := []string{
		"ALTER TABLE erp_chart_accounts ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_account_mapping_rules ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_chart_accounts FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_account_mapping_rules FORCE ROW LEVEL SECURITY",
	}

	for _, rls := range expectedRLS {
		assertContains(t, sql, rls)
	}
}

func TestChartOfAccountsMigrationHasTenantIsolationPolicies(t *testing.T) {
	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")

	expectedPolicies := []string{
		"erp_chart_accounts_tenant_isolation_policy",
		"erp_account_mapping_rules_tenant_isolation_policy",
		"tenant_id = current_setting('app.tenant_id', true)",
	}

	for _, policy := range expectedPolicies {
		assertContains(t, sql, policy)
	}
}

func TestChartOfAccountsRollbackDropsTablesInSafeOrder(t *testing.T) {
	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.down.sql")

	expectedDrops := []string{
		"DROP TABLE IF EXISTS erp_account_mapping_rules",
		"DROP TABLE IF EXISTS erp_chart_accounts",
	}

	for _, drop := range expectedDrops {
		assertContains(t, sql, drop)
	}
}
