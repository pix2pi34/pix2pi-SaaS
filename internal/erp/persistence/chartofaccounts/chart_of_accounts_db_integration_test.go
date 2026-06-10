package chartofaccounts_test

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

func chartOfAccountsIntegrationDSN(t *testing.T) string {
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

func chartOfAccountsPSQL(t *testing.T, dsn string, sql string) string {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("psql failed\nsql:\n%s\nerror: %v\noutput:\n%s", sql, err, string(out))
	}

	return strings.TrimSpace(string(out))
}

func chartOfAccountsPSQLMustFail(t *testing.T, dsn string, sql string) {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err == nil {
		t.Fatalf("expected psql failure but command succeeded\nsql:\n%s\noutput:\n%s", sql, string(out))
	}
}

func TestChartOfAccountsDBTablesExist(t *testing.T) {
	dsn := chartOfAccountsIntegrationDSN(t)

	got := chartOfAccountsPSQL(t, dsn, `
SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'erp_chart_accounts',
    'erp_account_mapping_rules'
  );
`)

	if got != "2" {
		t.Fatalf("expected 2 chart of accounts tables, got %s", got)
	}
}

func TestChartOfAccountsDBIndexesExist(t *testing.T) {
	dsn := chartOfAccountsIntegrationDSN(t)

	got := chartOfAccountsPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'ux_erp_chart_accounts_tenant_code',
    'ix_erp_chart_accounts_tenant_parent',
    'ix_erp_chart_accounts_tenant_type',
    'ix_erp_chart_accounts_tenant_class_group',
    'ix_erp_chart_accounts_tenant_postable',
    'ix_erp_chart_accounts_tenant_active',
    'ix_erp_chart_accounts_tenant_tax',

    'ux_erp_account_mapping_rules_tenant_key',
    'ix_erp_account_mapping_rules_tenant_source',
    'ix_erp_account_mapping_rules_tenant_event_line',
    'ix_erp_account_mapping_rules_tenant_account',
    'ix_erp_account_mapping_rules_tenant_vat',
    'ix_erp_account_mapping_rules_tenant_priority',
    'ix_erp_account_mapping_rules_tenant_default'
  );
`)

	if got != "14" {
		t.Fatalf("expected 14 chart of accounts indexes, got %s", got)
	}
}

func TestChartOfAccountsDBRLSEnabledAndForced(t *testing.T) {
	dsn := chartOfAccountsIntegrationDSN(t)

	got := chartOfAccountsPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN (
    'erp_chart_accounts',
    'erp_account_mapping_rules'
  )
  AND c.relrowsecurity = true
  AND c.relforcerowsecurity = true;
`)

	if got != "2" {
		t.Fatalf("expected RLS enabled and forced on 2 chart of accounts tables, got %s", got)
	}
}

func TestChartOfAccountsDBTenantPoliciesExist(t *testing.T) {
	dsn := chartOfAccountsIntegrationDSN(t)

	got := chartOfAccountsPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_policy p
JOIN pg_class c ON c.oid = p.polrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND p.polname IN (
    'erp_chart_accounts_tenant_isolation_policy',
    'erp_account_mapping_rules_tenant_isolation_policy'
  );
`)

	if got != "2" {
		t.Fatalf("expected 2 tenant isolation policies, got %s", got)
	}
}

func TestChartOfAccountsDBAccountingChecksWork(t *testing.T) {
	dsn := chartOfAccountsIntegrationDSN(t)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	accountCode := "120." + unique[len(unique)-6:]
	mappingKey := "sales.customer.receivable." + unique

	chartAccountID := chartOfAccountsPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_chart_accounts (
    tenant_id,
    account_code,
    account_name,
    parent_account_code,
    account_level,
    account_class,
    account_group,
    account_type,
    normal_balance,
    is_postable,
    is_active,
    currency_code,
    tax_code,
    vat_rate,
    description,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    'Alicilar Test %s',
    '120',
    2,
    '1',
    '12',
    'asset',
    'debit',
    true,
    true,
    'TRY',
    'KDV20',
    20.00,
    'Chart account DB integration test %s',
    'active',
    'faz3_chartofaccounts_test'
)
RETURNING chart_account_id;
`, accountCode, unique, unique))

	mappingRuleID := chartOfAccountsPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_account_mapping_rules (
    tenant_id,
    mapping_key,
    source_module,
    source_document_type,
    event_type,
    line_type,
    account_code,
    account_name,
    vat_rate,
    priority,
    is_default,
    is_active,
    description,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    'sales',
    'invoice',
    'sales.invoice.posted',
    'receivable',
    '%s',
    'Alicilar Test %s',
    20.00,
    100,
    true,
    true,
    'Mapping rule DB integration test %s',
    'active',
    'faz3_chartofaccounts_test'
)
RETURNING account_mapping_rule_id;
`, mappingKey, accountCode, unique, unique))

	defer cleanupChartOfAccountsFixture(t, dsn, accountCode, mappingKey)

	if chartAccountID == "" {
		t.Fatal("expected chart_account_id")
	}

	if mappingRuleID == "" {
		t.Fatal("expected account_mapping_rule_id")
	}

	accountCount := chartOfAccountsPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_chart_accounts
WHERE account_code = '%s';
`, accountCode))

	if accountCount != "1" {
		t.Fatalf("expected 1 chart account, got %s", accountCount)
	}

	ruleCount := chartOfAccountsPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_account_mapping_rules
WHERE mapping_key = '%s';
`, mappingKey))

	if ruleCount != "1" {
		t.Fatalf("expected 1 mapping rule, got %s", ruleCount)
	}

	chartOfAccountsPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_chart_accounts (
    tenant_id,
    account_code,
    account_name,
    account_type,
    normal_balance,
    vat_rate
)
VALUES (
    'tenant_7',
    'BAD.%s',
    'Bad Account',
    'asset',
    'debit',
    120.00
);
`, unique))
}

func TestChartOfAccountsDBTenantIsolationWorks(t *testing.T) {
	dsn := chartOfAccountsIntegrationDSN(t)

	isSuperUser := chartOfAccountsPSQL(t, dsn, `
SELECT rolsuper
FROM pg_roles
WHERE rolname = current_user;
`)

	if isSuperUser == "t" {
		t.Skip("current DB user is superuser; PostgreSQL superuser bypasses RLS behavior checks")
	}

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	accountCode := "320." + unique[len(unique)-6:]
	mappingKey := "procurement.vendor.payable." + unique

	chartAccountID := chartOfAccountsPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_chart_accounts (
    tenant_id,
    account_code,
    account_name,
    account_level,
    account_class,
    account_group,
    account_type,
    normal_balance,
    is_postable,
    is_active,
    currency_code,
    description,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    'Saticilar Test %s',
    2,
    '3',
    '32',
    'liability',
    'credit',
    true,
    true,
    'TRY',
    'Tenant isolation chart account test %s',
    'active',
    'faz3_chartofaccounts_rls_test'
)
RETURNING chart_account_id;
`, accountCode, unique, unique))

	chartOfAccountsPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_account_mapping_rules (
    tenant_id,
    mapping_key,
    source_module,
    source_document_type,
    event_type,
    line_type,
    account_code,
    account_name,
    priority,
    is_default,
    is_active,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    'procurement',
    'purchase_invoice',
    'purchase.invoice.posted',
    'payable',
    '%s',
    'Saticilar Test %s',
    100,
    true,
    true,
    'active',
    'faz3_chartofaccounts_rls_test'
);
`, mappingKey, accountCode, unique))

	defer cleanupChartOfAccountsFixture(t, dsn, accountCode, mappingKey)

	visibleForTenant7 := chartOfAccountsPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_chart_accounts
WHERE chart_account_id = '%s';
`, chartAccountID))

	if visibleForTenant7 != "1" {
		t.Fatalf("expected tenant_7 to see inserted chart account, got %s", visibleForTenant7)
	}

	visibleForTenant99 := chartOfAccountsPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_99';
SELECT COUNT(*)
FROM erp_chart_accounts
WHERE chart_account_id = '%s';
`, chartAccountID))

	if visibleForTenant99 != "0" {
		t.Fatalf("expected tenant_99 not to see tenant_7 chart account, got %s", visibleForTenant99)
	}

	chartOfAccountsPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_chart_accounts (
    tenant_id,
    account_code,
    account_name,
    account_type,
    normal_balance
)
VALUES (
    'tenant_99',
    'BAD.%s',
    'Bad Tenant Account',
    'asset',
    'debit'
);
`, unique))
}

func cleanupChartOfAccountsFixture(t *testing.T, dsn string, accountCode string, mappingKey string) {
	t.Helper()

	cleanupSQL := fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

DELETE FROM erp_account_mapping_rules
WHERE tenant_id = 'tenant_7'
  AND mapping_key = '%s';

DELETE FROM erp_chart_accounts
WHERE tenant_id = 'tenant_7'
  AND account_code = '%s';
`, mappingKey, accountCode)

	_ = exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", cleanupSQL).Run()
}
