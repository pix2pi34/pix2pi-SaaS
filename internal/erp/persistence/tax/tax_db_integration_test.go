package tax_test

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

func taxIntegrationDSN(t *testing.T) string {
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

func taxPSQL(t *testing.T, dsn string, sql string) string {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("psql failed\nsql:\n%s\nerror: %v\noutput:\n%s", sql, err, string(out))
	}

	return strings.TrimSpace(string(out))
}

func taxPSQLMustFail(t *testing.T, dsn string, sql string) {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err == nil {
		t.Fatalf("expected psql failure but command succeeded\nsql:\n%s\noutput:\n%s", sql, string(out))
	}
}

func TestTaxDBTablesExist(t *testing.T) {
	dsn := taxIntegrationDSN(t)

	got := taxPSQL(t, dsn, `
SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'erp_tax_codes',
    'erp_tax_rates',
    'erp_tax_transactions'
  );
`)

	if got != "3" {
		t.Fatalf("expected 3 tax tables, got %s", got)
	}
}

func TestTaxDBIndexesExist(t *testing.T) {
	dsn := taxIntegrationDSN(t)

	got := taxPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'ux_erp_tax_codes_tenant_code',
    'ix_erp_tax_codes_tenant_type',
    'ix_erp_tax_codes_tenant_account',
    'ix_erp_tax_codes_tenant_active',
    'ix_erp_tax_codes_tenant_withholding',

    'ux_erp_tax_rates_tenant_code_rate_valid',
    'ix_erp_tax_rates_tenant_code',
    'ix_erp_tax_rates_tenant_tax_code_id',
    'ix_erp_tax_rates_tenant_valid',
    'ix_erp_tax_rates_tenant_default',
    'ix_erp_tax_rates_tenant_active',

    'ix_erp_tax_transactions_tenant_code_date',
    'ix_erp_tax_transactions_tenant_type',
    'ix_erp_tax_transactions_tenant_fiscal',
    'ix_erp_tax_transactions_tenant_source',
    'ix_erp_tax_transactions_tenant_journal',
    'ix_erp_tax_transactions_tenant_party',
    'ix_erp_tax_transactions_tenant_customer',
    'ix_erp_tax_transactions_tenant_vendor',
    'ix_erp_tax_transactions_tenant_direction',
    'ix_erp_tax_transactions_tenant_status'
  );
`)

	if got != "21" {
		t.Fatalf("expected 21 tax indexes, got %s", got)
	}
}

func TestTaxDBRLSEnabledAndForced(t *testing.T) {
	dsn := taxIntegrationDSN(t)

	got := taxPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN (
    'erp_tax_codes',
    'erp_tax_rates',
    'erp_tax_transactions'
  )
  AND c.relrowsecurity = true
  AND c.relforcerowsecurity = true;
`)

	if got != "3" {
		t.Fatalf("expected RLS enabled and forced on 3 tax tables, got %s", got)
	}
}

func TestTaxDBTenantPoliciesExist(t *testing.T) {
	dsn := taxIntegrationDSN(t)

	got := taxPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_policy p
JOIN pg_class c ON c.oid = p.polrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND p.polname IN (
    'erp_tax_codes_tenant_isolation_policy',
    'erp_tax_rates_tenant_isolation_policy',
    'erp_tax_transactions_tenant_isolation_policy'
  );
`)

	if got != "3" {
		t.Fatalf("expected 3 tenant isolation policies, got %s", got)
	}
}

func TestTaxDBAccountingChecksWork(t *testing.T) {
	dsn := taxIntegrationDSN(t)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	taxCode := "KDV20-" + unique[len(unique)-6:]

	taxCodeID, taxRateID := createTaxFixture(t, dsn, unique, taxCode)
	defer cleanupTaxFixture(t, dsn, taxCode)

	transactionID := taxPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_tax_transactions (
    tenant_id,
    tax_code_id,
    tax_rate_id,
    tax_code,
    tax_name,
    tax_type,
    source_module,
    source_document_type,
    transaction_date,
    fiscal_year,
    fiscal_period,
    base_amount,
    rate_percent,
    tax_amount,
    withholding_amount,
    payable_amount,
    recoverable_amount,
    currency_code,
    exchange_rate,
    local_base_amount,
    local_tax_amount,
    direction,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    '%s',
    '%s',
    'KDV 20 Test %s',
    'vat',
    'sales',
    'invoice',
    CURRENT_DATE,
    2026,
    '2026-04',
    100.00,
    20.00,
    20.00,
    0.00,
    20.00,
    0.00,
    'TRY',
    1,
    100.00,
    20.00,
    'payable',
    'posted',
    'faz3_tax_test'
)
RETURNING tax_transaction_id;
`, taxCodeID, taxRateID, taxCode, unique))

	if transactionID == "" {
		t.Fatal("expected tax_transaction_id")
	}

	transactionCount := taxPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_tax_transactions
WHERE tax_transaction_id = '%s';
`, transactionID))

	if transactionCount != "1" {
		t.Fatalf("expected 1 tax transaction, got %s", transactionCount)
	}

	taxPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_tax_rates (
    tenant_id,
    tax_code_id,
    tax_code,
    rate_percent,
    valid_from,
    is_default,
    is_active,
    status
)
VALUES (
    'tenant_7',
    '%s',
    '%s',
    120.00,
    CURRENT_DATE,
    false,
    true,
    'active'
);
`, taxCodeID, taxCode))

	taxPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_tax_transactions (
    tenant_id,
    tax_code,
    tax_type,
    source_module,
    transaction_date,
    fiscal_year,
    fiscal_period,
    base_amount,
    rate_percent,
    tax_amount,
    direction
)
VALUES (
    'tenant_7',
    '%s',
    'vat',
    'sales',
    CURRENT_DATE,
    2026,
    '2026-04',
    100.00,
    20.00,
    20.00,
    'wrong'
);
`, taxCode))
}

func TestTaxDBTenantIsolationWorks(t *testing.T) {
	dsn := taxIntegrationDSN(t)

	isSuperUser := taxPSQL(t, dsn, `
SELECT rolsuper
FROM pg_roles
WHERE rolname = current_user;
`)

	if isSuperUser == "t" {
		t.Skip("current DB user is superuser; PostgreSQL superuser bypasses RLS behavior checks")
	}

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	taxCode := "KDV-RLS-" + unique[len(unique)-6:]

	taxCodeID, taxRateID := createTaxFixture(t, dsn, unique, taxCode)
	defer cleanupTaxFixture(t, dsn, taxCode)

	transactionID := taxPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_tax_transactions (
    tenant_id,
    tax_code_id,
    tax_rate_id,
    tax_code,
    tax_name,
    tax_type,
    source_module,
    source_document_type,
    transaction_date,
    fiscal_year,
    fiscal_period,
    base_amount,
    rate_percent,
    tax_amount,
    withholding_amount,
    payable_amount,
    recoverable_amount,
    currency_code,
    exchange_rate,
    local_base_amount,
    local_tax_amount,
    direction,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    '%s',
    '%s',
    'KDV RLS Test %s',
    'vat',
    'sales',
    'invoice',
    CURRENT_DATE,
    2026,
    '2026-04',
    100.00,
    20.00,
    20.00,
    0.00,
    20.00,
    0.00,
    'TRY',
    1,
    100.00,
    20.00,
    'payable',
    'posted',
    'faz3_tax_rls_test'
)
RETURNING tax_transaction_id;
`, taxCodeID, taxRateID, taxCode, unique))

	visibleForTenant7 := taxPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_tax_transactions
WHERE tax_transaction_id = '%s';
`, transactionID))

	if visibleForTenant7 != "1" {
		t.Fatalf("expected tenant_7 to see inserted tax transaction, got %s", visibleForTenant7)
	}

	visibleForTenant99 := taxPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_99';
SELECT COUNT(*)
FROM erp_tax_transactions
WHERE tax_transaction_id = '%s';
`, transactionID))

	if visibleForTenant99 != "0" {
		t.Fatalf("expected tenant_99 not to see tenant_7 tax transaction, got %s", visibleForTenant99)
	}

	taxPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_tax_codes (
    tenant_id,
    tax_code,
    tax_name,
    tax_type,
    is_recoverable,
    is_payable,
    is_withholding,
    is_active,
    status
)
VALUES (
    'tenant_99',
    'BAD-%s',
    'Bad Tenant Tax',
    'vat',
    false,
    true,
    false,
    true,
    'active'
);
`, unique))
}

func createTaxFixture(t *testing.T, dsn string, unique string, taxCode string) (string, string) {
	t.Helper()

	taxCodeID := taxPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_tax_codes (
    tenant_id,
    tax_code,
    tax_name,
    tax_type,
    account_code,
    account_name,
    is_recoverable,
    is_payable,
    is_withholding,
    is_active,
    description,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    'KDV Test %s',
    'vat',
    '391.01.20',
    'Hesaplanan KDV',
    false,
    true,
    false,
    true,
    'Tax fixture %s',
    'active',
    'faz3_tax_test'
)
RETURNING tax_code_id;
`, taxCode, unique, unique))

	taxRateID := taxPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_tax_rates (
    tenant_id,
    tax_code_id,
    tax_code,
    rate_percent,
    valid_from,
    is_default,
    is_active,
    description,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    '%s',
    20.00,
    CURRENT_DATE,
    true,
    true,
    'Tax rate fixture %s',
    'active',
    'faz3_tax_test'
)
RETURNING tax_rate_id;
`, taxCodeID, taxCode, unique))

	return taxCodeID, taxRateID
}

func cleanupTaxFixture(t *testing.T, dsn string, taxCode string) {
	t.Helper()

	cleanupSQL := fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

DELETE FROM erp_tax_transactions
WHERE tenant_id = 'tenant_7'
  AND tax_code = '%s';

DELETE FROM erp_tax_rates
WHERE tenant_id = 'tenant_7'
  AND tax_code = '%s';

DELETE FROM erp_tax_codes
WHERE tenant_id = 'tenant_7'
  AND tax_code = '%s';
`, taxCode, taxCode, taxCode)

	_ = exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", cleanupSQL).Run()
}
