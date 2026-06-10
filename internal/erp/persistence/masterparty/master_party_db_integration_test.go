package masterparty_test

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

func masterPartyIntegrationDSN(t *testing.T) string {
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

func masterPartyPSQL(t *testing.T, dsn string, sql string) string {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("psql failed\nsql:\n%s\nerror: %v\noutput:\n%s", sql, err, string(out))
	}

	return strings.TrimSpace(string(out))
}

func masterPartyPSQLMustFail(t *testing.T, dsn string, sql string) {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err == nil {
		t.Fatalf("expected psql failure but command succeeded\nsql:\n%s\noutput:\n%s", sql, string(out))
	}
}

func TestMasterPartyDBTablesExist(t *testing.T) {
	dsn := masterPartyIntegrationDSN(t)

	got := masterPartyPSQL(t, dsn, `
SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'erp_parties',
    'erp_customers',
    'erp_vendors',
    'erp_contacts',
    'erp_addresses'
  );
`)

	if got != "5" {
		t.Fatalf("expected 5 master party tables, got %s", got)
	}
}

func TestMasterPartyDBIndexesExist(t *testing.T) {
	dsn := masterPartyIntegrationDSN(t)

	got := masterPartyPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'ux_erp_parties_tenant_tax_no',
    'ix_erp_parties_tenant_display_name',
    'ix_erp_parties_tenant_status',
    'ux_erp_customers_tenant_code',
    'ux_erp_customers_tenant_party',
    'ix_erp_customers_tenant_status',
    'ux_erp_vendors_tenant_code',
    'ux_erp_vendors_tenant_party',
    'ix_erp_vendors_tenant_status',
    'ix_erp_contacts_tenant_party',
    'ux_erp_contacts_one_primary_per_party',
    'ix_erp_addresses_tenant_party',
    'ux_erp_addresses_one_primary_per_party'
  );
`)

	if got != "13" {
		t.Fatalf("expected 13 master party indexes, got %s", got)
	}
}

func TestMasterPartyDBRLSEnabledAndForced(t *testing.T) {
	dsn := masterPartyIntegrationDSN(t)

	got := masterPartyPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN (
    'erp_parties',
    'erp_customers',
    'erp_vendors',
    'erp_contacts',
    'erp_addresses'
  )
  AND c.relrowsecurity = true
  AND c.relforcerowsecurity = true;
`)

	if got != "5" {
		t.Fatalf("expected RLS enabled and forced on 5 tables, got %s", got)
	}
}

func TestMasterPartyDBTenantPoliciesExist(t *testing.T) {
	dsn := masterPartyIntegrationDSN(t)

	got := masterPartyPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_policy p
JOIN pg_class c ON c.oid = p.polrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND p.polname IN (
    'erp_parties_tenant_isolation_policy',
    'erp_customers_tenant_isolation_policy',
    'erp_vendors_tenant_isolation_policy',
    'erp_contacts_tenant_isolation_policy',
    'erp_addresses_tenant_isolation_policy'
  );
`)

	if got != "5" {
		t.Fatalf("expected 5 tenant isolation policies, got %s", got)
	}
}

func TestMasterPartyDBTenantIsolationWorks(t *testing.T) {
	dsn := masterPartyIntegrationDSN(t)

	isSuperUser := masterPartyPSQL(t, dsn, `
SELECT rolsuper
FROM pg_roles
WHERE rolname = current_user;
`)

	if isSuperUser == "t" {
		t.Skip("current DB user is superuser; PostgreSQL superuser bypasses RLS behavior checks")
	}

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	taxNo := "TST" + unique
	email := "faz3_" + unique + "@example.com"

	insertSQL := fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_parties (
    tenant_id,
    party_type,
    display_name,
    legal_name,
    tax_no,
    tax_office,
    phone,
    email,
    source,
    created_by
)
VALUES (
    'tenant_7',
    'organization',
    'FAZ3 Master Party Test %s',
    'FAZ3 Master Party Test Ltd',
    '%s',
    'Test Vergi Dairesi',
    '05000000000',
    '%s',
    'integration_test',
    'faz3_test'
)
RETURNING party_id;
`, unique, taxNo, email)

	partyID := masterPartyPSQL(t, dsn, insertSQL)

	defer func() {
		cleanupSQL := fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
DELETE FROM erp_parties WHERE party_id = '%s';
`, partyID)

		_ = exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", cleanupSQL).Run()
	}()

	visibleForTenant7 := masterPartyPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*) FROM erp_parties WHERE party_id = '%s';
`, partyID))

	if visibleForTenant7 != "1" {
		t.Fatalf("expected tenant_7 to see inserted party, got %s", visibleForTenant7)
	}

	visibleForTenant99 := masterPartyPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_99';
SELECT COUNT(*) FROM erp_parties WHERE party_id = '%s';
`, partyID))

	if visibleForTenant99 != "0" {
		t.Fatalf("expected tenant_99 not to see tenant_7 party, got %s", visibleForTenant99)
	}

	mismatchSQL := fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_parties (
    tenant_id,
    party_type,
    display_name,
    tax_no,
    tax_office
)
VALUES (
    'tenant_99',
    'organization',
    'FAZ3 RLS Mismatch Test %s',
    'BAD%s',
    'Test Vergi Dairesi'
);
`, unique, unique)

	masterPartyPSQLMustFail(t, dsn, mismatchSQL)
}
