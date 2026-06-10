package cashbank_test

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

func cashBankIntegrationDSN(t *testing.T) string {
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

func cashBankPSQL(t *testing.T, dsn string, sql string) string {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("psql failed\nsql:\n%s\nerror: %v\noutput:\n%s", sql, err, string(out))
	}

	return strings.TrimSpace(string(out))
}

func cashBankPSQLMustFail(t *testing.T, dsn string, sql string) {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err == nil {
		t.Fatalf("expected psql failure but command succeeded\nsql:\n%s\noutput:\n%s", sql, string(out))
	}
}

func TestCashBankDBTablesExist(t *testing.T) {
	dsn := cashBankIntegrationDSN(t)

	got := cashBankPSQL(t, dsn, `
SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'erp_cash_accounts',
    'erp_bank_accounts',
    'erp_payment_transactions'
  );
`)

	if got != "3" {
		t.Fatalf("expected 3 cashbank tables, got %s", got)
	}
}

func TestCashBankDBIndexesExist(t *testing.T) {
	dsn := cashBankIntegrationDSN(t)

	got := cashBankPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'ux_erp_cash_accounts_tenant_code',
    'ix_erp_cash_accounts_tenant_account',
    'ix_erp_cash_accounts_tenant_active',

    'ux_erp_bank_accounts_tenant_code',
    'ix_erp_bank_accounts_tenant_iban',
    'ix_erp_bank_accounts_tenant_account',
    'ix_erp_bank_accounts_tenant_active',

    'ux_erp_payment_transactions_tenant_no',
    'ix_erp_payment_transactions_tenant_date',
    'ix_erp_payment_transactions_tenant_type',
    'ix_erp_payment_transactions_tenant_direction',
    'ix_erp_payment_transactions_tenant_method',
    'ix_erp_payment_transactions_tenant_cash',
    'ix_erp_payment_transactions_tenant_bank',
    'ix_erp_payment_transactions_tenant_party',
    'ix_erp_payment_transactions_tenant_customer',
    'ix_erp_payment_transactions_tenant_vendor',
    'ix_erp_payment_transactions_tenant_source',
    'ix_erp_payment_transactions_tenant_journal',
    'ix_erp_payment_transactions_tenant_status'
  );
`)

	if got != "20" {
		t.Fatalf("expected 20 cashbank indexes, got %s", got)
	}
}

func TestCashBankDBRLSEnabledAndForced(t *testing.T) {
	dsn := cashBankIntegrationDSN(t)

	got := cashBankPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN (
    'erp_cash_accounts',
    'erp_bank_accounts',
    'erp_payment_transactions'
  )
  AND c.relrowsecurity = true
  AND c.relforcerowsecurity = true;
`)

	if got != "3" {
		t.Fatalf("expected RLS enabled and forced on 3 cashbank tables, got %s", got)
	}
}

func TestCashBankDBTenantPoliciesExist(t *testing.T) {
	dsn := cashBankIntegrationDSN(t)

	got := cashBankPSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_policy p
JOIN pg_class c ON c.oid = p.polrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND p.polname IN (
    'erp_cash_accounts_tenant_isolation_policy',
    'erp_bank_accounts_tenant_isolation_policy',
    'erp_payment_transactions_tenant_isolation_policy'
  );
`)

	if got != "3" {
		t.Fatalf("expected 3 tenant isolation policies, got %s", got)
	}
}

func TestCashBankDBAccountingChecksWork(t *testing.T) {
	dsn := cashBankIntegrationDSN(t)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	cashCode := "CASH-" + unique[len(unique)-6:]
	bankCode := "BANK-" + unique[len(unique)-6:]
	paymentNo := "PAY-" + unique

	cashAccountID, bankAccountID := createCashBankFixture(t, dsn, unique, cashCode, bankCode)
	defer cleanupCashBankFixture(t, dsn, cashCode, bankCode, paymentNo)

	paymentID := cashBankPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_payment_transactions (
    tenant_id,
    payment_no,
    payment_date,
    payment_type,
    payment_direction,
    payment_method,
    cash_account_id,
    bank_account_id,
    source_module,
    source_document_type,
    currency_code,
    exchange_rate,
    amount,
    local_amount,
    fee_amount,
    local_fee_amount,
    net_amount,
    local_net_amount,
    description,
    status,
    posted_at,
    posted_by,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    CURRENT_DATE,
    'collection',
    'in',
    'cash',
    '%s',
    NULL,
    'manual',
    'integration_test',
    'TRY',
    1,
    100.00,
    100.00,
    2.00,
    2.00,
    98.00,
    98.00,
    'CashBank payment transaction test %s',
    'posted',
    now(),
    'faz3_cashbank_test',
    'faz3_cashbank_test'
)
RETURNING payment_transaction_id;
`, paymentNo, cashAccountID, unique))

	if paymentID == "" {
		t.Fatal("expected payment_transaction_id")
	}

	paymentCount := cashBankPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_payment_transactions
WHERE payment_transaction_id = '%s';
`, paymentID))

	if paymentCount != "1" {
		t.Fatalf("expected 1 payment transaction, got %s", paymentCount)
	}

	bankVisible := cashBankPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_bank_accounts
WHERE bank_account_id = '%s';
`, bankAccountID))

	if bankVisible != "1" {
		t.Fatalf("expected 1 bank account, got %s", bankVisible)
	}

	cashBankPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_cash_accounts (
    tenant_id,
    cash_code,
    cash_name,
    currency_code,
    opening_balance,
    current_balance,
    is_active,
    status
)
VALUES (
    'tenant_7',
    'BAD-CASH-%s',
    'Bad Cash',
    'TRY',
    -1.00,
    0.00,
    true,
    'active'
);
`, unique))

	cashBankPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_payment_transactions (
    tenant_id,
    payment_no,
    payment_date,
    payment_type,
    payment_direction,
    payment_method,
    source_module,
    currency_code,
    exchange_rate,
    amount,
    local_amount,
    net_amount,
    local_net_amount,
    status
)
VALUES (
    'tenant_7',
    'BAD-PAY-%s',
    CURRENT_DATE,
    'collection',
    'in',
    'cash',
    'manual',
    'TRY',
    1,
    100.00,
    100.00,
    100.00,
    100.00,
    'posted'
);
`, unique))
}

func TestCashBankDBTenantIsolationWorks(t *testing.T) {
	dsn := cashBankIntegrationDSN(t)

	isSuperUser := cashBankPSQL(t, dsn, `
SELECT rolsuper
FROM pg_roles
WHERE rolname = current_user;
`)

	if isSuperUser == "t" {
		t.Skip("current DB user is superuser; PostgreSQL superuser bypasses RLS behavior checks")
	}

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	cashCode := "CASH-RLS-" + unique[len(unique)-6:]
	bankCode := "BANK-RLS-" + unique[len(unique)-6:]
	paymentNo := "PAY-RLS-" + unique

	cashAccountID, _ := createCashBankFixture(t, dsn, unique, cashCode, bankCode)
	defer cleanupCashBankFixture(t, dsn, cashCode, bankCode, paymentNo)

	paymentID := cashBankPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_payment_transactions (
    tenant_id,
    payment_no,
    payment_date,
    payment_type,
    payment_direction,
    payment_method,
    cash_account_id,
    source_module,
    currency_code,
    exchange_rate,
    amount,
    local_amount,
    net_amount,
    local_net_amount,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    CURRENT_DATE,
    'collection',
    'in',
    'cash',
    '%s',
    'manual',
    'TRY',
    1,
    50.00,
    50.00,
    50.00,
    50.00,
    'posted',
    'faz3_cashbank_rls_test'
)
RETURNING payment_transaction_id;
`, paymentNo, cashAccountID))

	visibleForTenant7 := cashBankPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_payment_transactions
WHERE payment_transaction_id = '%s';
`, paymentID))

	if visibleForTenant7 != "1" {
		t.Fatalf("expected tenant_7 to see inserted payment transaction, got %s", visibleForTenant7)
	}

	visibleForTenant99 := cashBankPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_99';
SELECT COUNT(*)
FROM erp_payment_transactions
WHERE payment_transaction_id = '%s';
`, paymentID))

	if visibleForTenant99 != "0" {
		t.Fatalf("expected tenant_99 not to see tenant_7 payment transaction, got %s", visibleForTenant99)
	}

	cashBankPSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_cash_accounts (
    tenant_id,
    cash_code,
    cash_name,
    currency_code,
    opening_balance,
    current_balance,
    is_active,
    status
)
VALUES (
    'tenant_99',
    'BAD-RLS-CASH-%s',
    'Bad Tenant Cash',
    'TRY',
    0.00,
    0.00,
    true,
    'active'
);
`, unique))
}

func createCashBankFixture(t *testing.T, dsn string, unique string, cashCode string, bankCode string) (string, string) {
	t.Helper()

	cashAccountID := cashBankPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_cash_accounts (
    tenant_id,
    cash_code,
    cash_name,
    account_code,
    account_name,
    currency_code,
    opening_balance,
    current_balance,
    is_active,
    description,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    'Merkez Kasa %s',
    '100.01',
    'Merkez Kasa',
    'TRY',
    0.00,
    0.00,
    true,
    'Cash account fixture %s',
    'active',
    'faz3_cashbank_test'
)
RETURNING cash_account_id;
`, cashCode, unique, unique))

	bankAccountID := cashBankPSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_bank_accounts (
    tenant_id,
    bank_code,
    bank_name,
    branch_code,
    branch_name,
    iban,
    account_no,
    account_code,
    account_name,
    currency_code,
    opening_balance,
    current_balance,
    is_active,
    description,
    status,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    'Test Bankasi %s',
    '0001',
    'Merkez',
    'TR000000000000000000%s',
    'ACC-%s',
    '102.01',
    'Banka Hesabi',
    'TRY',
    0.00,
    0.00,
    true,
    'Bank account fixture %s',
    'active',
    'faz3_cashbank_test'
)
RETURNING bank_account_id;
`, bankCode, unique, unique[len(unique)-6:], unique[len(unique)-6:], unique))

	return cashAccountID, bankAccountID
}

func cleanupCashBankFixture(t *testing.T, dsn string, cashCode string, bankCode string, paymentNo string) {
	t.Helper()

	cleanupSQL := fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

DELETE FROM erp_payment_transactions
WHERE tenant_id = 'tenant_7'
  AND (
    payment_no = '%s'
    OR cash_account_id IN (
        SELECT cash_account_id FROM erp_cash_accounts WHERE tenant_id = 'tenant_7' AND cash_code = '%s'
    )
    OR bank_account_id IN (
        SELECT bank_account_id FROM erp_bank_accounts WHERE tenant_id = 'tenant_7' AND bank_code = '%s'
    )
  );

DELETE FROM erp_bank_accounts
WHERE tenant_id = 'tenant_7'
  AND bank_code = '%s';

DELETE FROM erp_cash_accounts
WHERE tenant_id = 'tenant_7'
  AND cash_code = '%s';
`, paymentNo, cashCode, bankCode, bankCode, cashCode)

	_ = exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", cleanupSQL).Run()
}
