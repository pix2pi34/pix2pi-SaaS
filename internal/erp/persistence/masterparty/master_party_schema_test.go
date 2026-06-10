package masterparty_test

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

func TestMasterPartyMigrationCreatesCoreTables(t *testing.T) {
	sql := readMigration(t, "20260425_090101_erp_master_party.up.sql")

	expectedTables := []string{
		"CREATE TABLE IF NOT EXISTS erp_parties",
		"CREATE TABLE IF NOT EXISTS erp_customers",
		"CREATE TABLE IF NOT EXISTS erp_vendors",
		"CREATE TABLE IF NOT EXISTS erp_contacts",
		"CREATE TABLE IF NOT EXISTS erp_addresses",
	}

	for _, table := range expectedTables {
		assertContains(t, sql, table)
	}
}

func TestMasterPartyMigrationHasTenantAndAuditColumns(t *testing.T) {
	sql := readMigration(t, "20260425_090101_erp_master_party.up.sql")

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

func TestMasterPartyMigrationHasTurkeyERPFields(t *testing.T) {
	sql := readMigration(t, "20260425_090101_erp_master_party.up.sql")

	expectedFields := []string{
		"tax_no TEXT",
		"tax_office TEXT",
		"mersis_no TEXT",
		"currency_code TEXT NOT NULL DEFAULT 'TRY'",
		"country_code TEXT NOT NULL DEFAULT 'TR'",
	}

	for _, field := range expectedFields {
		assertContains(t, sql, field)
	}
}

func TestMasterPartyMigrationHasTenantIndexes(t *testing.T) {
	sql := readMigration(t, "20260425_090101_erp_master_party.up.sql")

	expectedIndexes := []string{
		"ux_erp_parties_tenant_tax_no",
		"ux_erp_customers_tenant_code",
		"ux_erp_customers_tenant_party",
		"ux_erp_vendors_tenant_code",
		"ux_erp_vendors_tenant_party",
		"ix_erp_contacts_tenant_party",
		"ix_erp_addresses_tenant_party",
	}

	for _, index := range expectedIndexes {
		assertContains(t, sql, index)
	}
}

func TestMasterPartyMigrationEnablesForcedRLS(t *testing.T) {
	sql := readMigration(t, "20260425_090101_erp_master_party.up.sql")

	expectedRLS := []string{
		"ALTER TABLE erp_parties ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_customers ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_vendors ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_contacts ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_addresses ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_parties FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_customers FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_vendors FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_contacts FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_addresses FORCE ROW LEVEL SECURITY",
	}

	for _, rls := range expectedRLS {
		assertContains(t, sql, rls)
	}
}

func TestMasterPartyMigrationHasTenantIsolationPolicies(t *testing.T) {
	sql := readMigration(t, "20260425_090101_erp_master_party.up.sql")

	expectedPolicies := []string{
		"erp_parties_tenant_isolation_policy",
		"erp_customers_tenant_isolation_policy",
		"erp_vendors_tenant_isolation_policy",
		"erp_contacts_tenant_isolation_policy",
		"erp_addresses_tenant_isolation_policy",
		"tenant_id = current_setting('app.tenant_id', true)",
	}

	for _, policy := range expectedPolicies {
		assertContains(t, sql, policy)
	}
}

func TestMasterPartyRollbackDropsTablesInSafeOrder(t *testing.T) {
	sql := readMigration(t, "20260425_090101_erp_master_party.down.sql")

	expectedDrops := []string{
		"DROP TABLE IF EXISTS erp_addresses",
		"DROP TABLE IF EXISTS erp_contacts",
		"DROP TABLE IF EXISTS erp_vendors",
		"DROP TABLE IF EXISTS erp_customers",
		"DROP TABLE IF EXISTS erp_parties",
	}

	for _, drop := range expectedDrops {
		assertContains(t, sql, drop)
	}
}
