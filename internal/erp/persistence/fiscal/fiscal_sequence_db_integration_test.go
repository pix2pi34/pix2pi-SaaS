package fiscal_test

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

func fiscalSequenceIntegrationDSN(t *testing.T) string {
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

func fiscalSequencePSQL(t *testing.T, dsn string, sql string) string {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("psql failed\nsql:\n%s\nerror: %v\noutput:\n%s", sql, err, string(out))
	}

	return strings.TrimSpace(string(out))
}

func fiscalSequencePSQLMustFail(t *testing.T, dsn string, sql string) {
	t.Helper()

	cmd := exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
	out, err := cmd.CombinedOutput()
	if err == nil {
		t.Fatalf("expected psql failure but command succeeded\nsql:\n%s\noutput:\n%s", sql, string(out))
	}
}

func TestFiscalSequenceDBTablesExist(t *testing.T) {
	dsn := fiscalSequenceIntegrationDSN(t)

	got := fiscalSequencePSQL(t, dsn, `
SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'erp_fiscal_years',
    'erp_fiscal_periods',
    'erp_document_sequences',
    'erp_document_number_allocations'
  );
`)

	if got != "4" {
		t.Fatalf("expected 4 fiscal sequence tables, got %s", got)
	}
}

func TestFiscalSequenceDBIndexesExist(t *testing.T) {
	dsn := fiscalSequenceIntegrationDSN(t)

	got := fiscalSequencePSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'ux_erp_fiscal_years_tenant_year',
    'ix_erp_fiscal_years_tenant_status',
    'ix_erp_fiscal_years_tenant_dates',

    'ux_erp_fiscal_periods_tenant_period',
    'ux_erp_fiscal_periods_tenant_year_no',
    'ix_erp_fiscal_periods_tenant_status',
    'ix_erp_fiscal_periods_tenant_dates',

    'ux_erp_document_sequences_tenant_module_type_year',
    'ix_erp_document_sequences_tenant_module',
    'ix_erp_document_sequences_tenant_active',
    'ix_erp_document_sequences_tenant_status',

    'ux_erp_document_number_allocations_tenant_no',
    'ix_erp_document_number_allocations_tenant_sequence',
    'ix_erp_document_number_allocations_tenant_source',
    'ix_erp_document_number_allocations_tenant_fiscal',
    'ix_erp_document_number_allocations_tenant_status'
  );
`)

	if got != "16" {
		t.Fatalf("expected 16 fiscal sequence indexes, got %s", got)
	}
}

func TestFiscalSequenceDBRLSEnabledAndForced(t *testing.T) {
	dsn := fiscalSequenceIntegrationDSN(t)

	got := fiscalSequencePSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN (
    'erp_fiscal_years',
    'erp_fiscal_periods',
    'erp_document_sequences',
    'erp_document_number_allocations'
  )
  AND c.relrowsecurity = true
  AND c.relforcerowsecurity = true;
`)

	if got != "4" {
		t.Fatalf("expected RLS enabled and forced on 4 fiscal sequence tables, got %s", got)
	}
}

func TestFiscalSequenceDBTenantPoliciesExist(t *testing.T) {
	dsn := fiscalSequenceIntegrationDSN(t)

	got := fiscalSequencePSQL(t, dsn, `
SELECT COUNT(*)
FROM pg_policy p
JOIN pg_class c ON c.oid = p.polrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND p.polname IN (
    'erp_fiscal_years_tenant_isolation_policy',
    'erp_fiscal_periods_tenant_isolation_policy',
    'erp_document_sequences_tenant_isolation_policy',
    'erp_document_number_allocations_tenant_isolation_policy'
  );
`)

	if got != "4" {
		t.Fatalf("expected 4 tenant isolation policies, got %s", got)
	}
}

func TestFiscalSequenceDBAccountingChecksWork(t *testing.T) {
	dsn := fiscalSequenceIntegrationDSN(t)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	fiscalYear := 2099
	fiscalPeriod := "2099-13-" + unique[len(unique)-6:]
	documentType := "invoice_test_" + unique[len(unique)-6:]
	documentNo := "INV-" + unique

	sequenceID := createFiscalSequenceFixture(t, dsn, unique, fiscalYear, fiscalPeriod, documentType)
	defer cleanupFiscalSequenceFixture(t, dsn, fiscalYear, fiscalPeriod, documentType, documentNo)

	allocationID := fiscalSequencePSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_document_number_allocations (
    tenant_id,
    document_sequence_id,
    document_module,
    document_type,
    document_no,
    allocated_no,
    fiscal_year,
    fiscal_period,
    allocation_status,
    allocated_by,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    'sales',
    '%s',
    '%s',
    1,
    %d,
    '%s',
    'confirmed',
    'faz3_fiscal_test',
    'faz3_fiscal_test'
)
RETURNING document_number_allocation_id;
`, sequenceID, documentType, documentNo, fiscalYear, fiscalPeriod))

	if allocationID == "" {
		t.Fatal("expected document_number_allocation_id")
	}

	allocationCount := fiscalSequencePSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_document_number_allocations
WHERE document_number_allocation_id = '%s';
`, allocationID))

	if allocationCount != "1" {
		t.Fatalf("expected 1 document number allocation, got %s", allocationCount)
	}

	fiscalSequencePSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_fiscal_periods (
    tenant_id,
    fiscal_year,
    fiscal_period,
    period_no,
    period_start_date,
    period_end_date,
    status
)
VALUES (
    'tenant_7',
    %d,
    'BAD-%s',
    14,
    DATE '2099-01-01',
    DATE '2099-01-31',
    'open'
);
`, fiscalYear, unique))

	fiscalSequencePSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_document_sequences (
    tenant_id,
    document_module,
    document_type,
    fiscal_year,
    current_no,
    min_no,
    padding,
    reset_policy,
    is_active,
    status
)
VALUES (
    'tenant_7',
    'wrong',
    'bad-%s',
    %d,
    0,
    1,
    6,
    'yearly',
    true,
    'active'
);
`, unique, fiscalYear))
}

func TestFiscalSequenceDBTenantIsolationWorks(t *testing.T) {
	dsn := fiscalSequenceIntegrationDSN(t)

	isSuperUser := fiscalSequencePSQL(t, dsn, `
SELECT rolsuper
FROM pg_roles
WHERE rolname = current_user;
`)

	if isSuperUser == "t" {
		t.Skip("current DB user is superuser; PostgreSQL superuser bypasses RLS behavior checks")
	}

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	fiscalYear := 2098
	fiscalPeriod := "2098-13-" + unique[len(unique)-6:]
	documentType := "rls_invoice_" + unique[len(unique)-6:]
	documentNo := "RLS-INV-" + unique

	sequenceID := createFiscalSequenceFixture(t, dsn, unique, fiscalYear, fiscalPeriod, documentType)
	defer cleanupFiscalSequenceFixture(t, dsn, fiscalYear, fiscalPeriod, documentType, documentNo)

	allocationID := fiscalSequencePSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_document_number_allocations (
    tenant_id,
    document_sequence_id,
    document_module,
    document_type,
    document_no,
    allocated_no,
    fiscal_year,
    fiscal_period,
    allocation_status,
    allocated_by,
    created_by
)
VALUES (
    'tenant_7',
    '%s',
    'sales',
    '%s',
    '%s',
    1,
    %d,
    '%s',
    'allocated',
    'faz3_fiscal_rls_test',
    'faz3_fiscal_rls_test'
)
RETURNING document_number_allocation_id;
`, sequenceID, documentType, documentNo, fiscalYear, fiscalPeriod))

	visibleForTenant7 := fiscalSequencePSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';
SELECT COUNT(*)
FROM erp_document_number_allocations
WHERE document_number_allocation_id = '%s';
`, allocationID))

	if visibleForTenant7 != "1" {
		t.Fatalf("expected tenant_7 to see inserted allocation, got %s", visibleForTenant7)
	}

	visibleForTenant99 := fiscalSequencePSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_99';
SELECT COUNT(*)
FROM erp_document_number_allocations
WHERE document_number_allocation_id = '%s';
`, allocationID))

	if visibleForTenant99 != "0" {
		t.Fatalf("expected tenant_99 not to see tenant_7 allocation, got %s", visibleForTenant99)
	}

	fiscalSequencePSQLMustFail(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_fiscal_years (
    tenant_id,
    fiscal_year,
    year_start_date,
    year_end_date,
    status,
    created_by
)
VALUES (
    'tenant_99',
    2097,
    DATE '2097-01-01',
    DATE '2097-12-31',
    'open',
    'faz3_bad_tenant'
);
`))
}

func createFiscalSequenceFixture(t *testing.T, dsn string, unique string, fiscalYear int, fiscalPeriod string, documentType string) string {
	t.Helper()

	fiscalSequencePSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_fiscal_years (
    tenant_id,
    fiscal_year,
    year_start_date,
    year_end_date,
    status,
    description,
    created_by
)
VALUES (
    'tenant_7',
    %d,
    DATE '%d-01-01',
    DATE '%d-12-31',
    'open',
    'Fiscal year fixture %s',
    'faz3_fiscal_test'
)
ON CONFLICT (tenant_id, fiscal_year) WHERE deleted_at IS NULL
DO UPDATE SET
    status = 'open',
    updated_at = now();
`, fiscalYear, fiscalYear, fiscalYear, unique))

	fiscalSequencePSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_fiscal_periods (
    tenant_id,
    fiscal_year,
    fiscal_period,
    period_no,
    period_start_date,
    period_end_date,
    status,
    description,
    created_by
)
VALUES (
    'tenant_7',
    %d,
    '%s',
    13,
    DATE '%d-12-01',
    DATE '%d-12-31',
    'open',
    'Fiscal period fixture %s',
    'faz3_fiscal_test'
);
`, fiscalYear, fiscalPeriod, fiscalYear, fiscalYear, unique))

	sequenceID := fiscalSequencePSQL(t, dsn, fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

INSERT INTO erp_document_sequences (
    tenant_id,
    document_module,
    document_type,
    fiscal_year,
    prefix,
    suffix,
    current_no,
    min_no,
    max_no,
    padding,
    reset_policy,
    is_active,
    description,
    status,
    created_by
)
VALUES (
    'tenant_7',
    'sales',
    '%s',
    %d,
    'INV-',
    '',
    0,
    1,
    999999,
    6,
    'yearly',
    true,
    'Document sequence fixture %s',
    'active',
    'faz3_fiscal_test'
)
RETURNING document_sequence_id;
`, documentType, fiscalYear, unique))

	return sequenceID
}

func cleanupFiscalSequenceFixture(t *testing.T, dsn string, fiscalYear int, fiscalPeriod string, documentType string, documentNo string) {
	t.Helper()

	cleanupSQL := fmt.Sprintf(`
SET app.tenant_id = 'tenant_7';

DELETE FROM erp_document_number_allocations
WHERE tenant_id = 'tenant_7'
  AND (
    document_no = '%s'
    OR document_type = '%s'
    OR fiscal_period = '%s'
  );

DELETE FROM erp_document_sequences
WHERE tenant_id = 'tenant_7'
  AND document_type = '%s';

DELETE FROM erp_fiscal_periods
WHERE tenant_id = 'tenant_7'
  AND fiscal_period = '%s';

DELETE FROM erp_fiscal_years
WHERE tenant_id = 'tenant_7'
  AND fiscal_year = %d
  AND description LIKE 'Fiscal year fixture%%';
`, documentNo, documentType, fiscalPeriod, documentType, fiscalPeriod, fiscalYear)

	_ = exec.Command("psql", dsn, "-v", "ON_ERROR_STOP=1", "-Atqc", cleanupSQL).Run()
}
