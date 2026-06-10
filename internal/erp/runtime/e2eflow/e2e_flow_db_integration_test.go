package e2eflow

import (
	"context"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func e2eFlowDBTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping e2e flow DB integration test")
	}

	return dsn
}

func TestE2EFlowDBSchemaAndRLS(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, e2eFlowDBTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	var tableCount int
	if err := pool.QueryRow(ctx, `
SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('erp_runtime_flows', 'erp_runtime_flow_steps');
`).Scan(&tableCount); err != nil {
		t.Fatalf("table count query failed: %v", err)
	}

	if tableCount != 2 {
		t.Fatalf("expected 2 e2e flow tables, got %d", tableCount)
	}

	var rlsCount int
	if err := pool.QueryRow(ctx, `
SELECT COUNT(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN ('erp_runtime_flows', 'erp_runtime_flow_steps')
  AND c.relrowsecurity = true
  AND c.relforcerowsecurity = true;
`).Scan(&rlsCount); err != nil {
		t.Fatalf("rls count query failed: %v", err)
	}

	if rlsCount != 2 {
		t.Fatalf("expected 2 RLS forced tables, got %d", rlsCount)
	}

	var policyCount int
	if err := pool.QueryRow(ctx, `
SELECT COUNT(*)
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('erp_runtime_flows', 'erp_runtime_flow_steps');
`).Scan(&policyCount); err != nil {
		t.Fatalf("policy count query failed: %v", err)
	}

	if policyCount < 2 {
		t.Fatalf("expected at least 2 tenant policies, got %d", policyCount)
	}
}

func TestE2EFlowDBPersistLifecycleWorks(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, e2eFlowDBTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	tenantID := "tenant_7"
	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	sourceNo := "E2E-FLOW-" + unique

	cleanupE2EFlowDBFixture(t, pool, tenantID, sourceNo)
	defer cleanupE2EFlowDBFixture(t, pool, tenantID, sourceNo)

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("begin tx: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("set tenant: %v", err)
	}

	var flowID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_runtime_flows (
	tenant_id,
	request_id,
	transaction_kind,
	source_module,
	source_document_type,
	source_document_no,
	total_amount,
	currency_code,
	exchange_rate,
	idempotency_key,
	correlation_id,
	flow_status,
	description,
	created_by,
	updated_by
) VALUES (
	$1, $2, 'sales_invoice', 'sales', 'invoice', $3,
	120, 'TRY', 1,
	$4, $5,
	'draft',
	'e2e flow db lifecycle test',
	'faz3_11_1e_test',
	'faz3_11_1e_test'
)
RETURNING flow_id::text;
`,
		tenantID,
		"req-"+unique,
		sourceNo,
		tenantID+":sales_invoice:"+sourceNo,
		"corr-"+unique,
	).Scan(&flowID); err != nil {
		t.Fatalf("insert flow failed: %v", err)
	}

	stepKinds := []FlowStepKind{
		FlowStepValidateRequest,
		FlowStepPersistDocument,
		FlowStepCalculateTax,
		FlowStepPostJournal,
		FlowStepPostLedger,
		FlowStepPublishEvent,
	}

	for index, stepKind := range stepKinds {
		if _, err := tx.Exec(ctx, `
INSERT INTO erp_runtime_flow_steps (
	tenant_id,
	flow_id,
	step_no,
	step_kind,
	step_status,
	message,
	created_by,
	updated_by
) VALUES (
	$1, $2, $3, $4, 'pending', 'created by integration test', 'faz3_11_1e_test', 'faz3_11_1e_test'
);
`, tenantID, flowID, index+1, string(stepKind)); err != nil {
			t.Fatalf("insert step %d failed: %v", index+1, err)
		}
	}

	if _, err := tx.Exec(ctx, `
UPDATE erp_runtime_flows
SET flow_status = 'running',
    started_at = now(),
    updated_at = now()
WHERE tenant_id = $1
  AND flow_id = $2;
`, tenantID, flowID); err != nil {
		t.Fatalf("mark running failed: %v", err)
	}

	if _, err := tx.Exec(ctx, `
UPDATE erp_runtime_flow_steps
SET step_status = 'completed',
    started_at = COALESCE(started_at, now()),
    completed_at = now(),
    message = 'completed',
    updated_at = now()
WHERE tenant_id = $1
  AND flow_id = $2;
`, tenantID, flowID); err != nil {
		t.Fatalf("mark steps completed failed: %v", err)
	}

	if _, err := tx.Exec(ctx, `
UPDATE erp_runtime_flows
SET flow_status = 'completed',
    completed_at = now(),
    updated_at = now()
WHERE tenant_id = $1
  AND flow_id = $2;
`, tenantID, flowID); err != nil {
		t.Fatalf("mark completed failed: %v", err)
	}

	var flowStatus string
	var stepCount int
	if err := tx.QueryRow(ctx, `
SELECT f.flow_status, COUNT(s.flow_step_id)
FROM erp_runtime_flows f
JOIN erp_runtime_flow_steps s ON s.flow_id = f.flow_id AND s.tenant_id = f.tenant_id
WHERE f.tenant_id = $1
  AND f.flow_id = $2
GROUP BY f.flow_status;
`, tenantID, flowID).Scan(&flowStatus, &stepCount); err != nil {
		t.Fatalf("verify flow failed: %v", err)
	}

	if flowStatus != "completed" {
		t.Fatalf("expected completed flow status, got %s", flowStatus)
	}

	if stepCount != 6 {
		t.Fatalf("expected 6 flow steps, got %d", stepCount)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("commit tx: %v", err)
	}
}

func TestE2EFlowDBTenantIsolationWorks(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, e2eFlowDBTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	if currentUserBypassesRLS(t, pool) {
		t.Skip("current DB user is superuser or bypassrls; PostgreSQL bypasses RLS behavior checks")
	}

	tenantA := "tenant_7"
	tenantB := "tenant_99"
	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	sourceA := "E2E-RLS-A-" + unique
	sourceB := "E2E-RLS-B-" + unique

	cleanupE2EFlowDBFixture(t, pool, tenantA, sourceA)
	cleanupE2EFlowDBFixture(t, pool, tenantB, sourceB)

	defer cleanupE2EFlowDBFixture(t, pool, tenantA, sourceA)
	defer cleanupE2EFlowDBFixture(t, pool, tenantB, sourceB)

	insertE2EFlowFixture(t, pool, tenantA, sourceA, unique+"a")
	insertE2EFlowFixture(t, pool, tenantB, sourceB, unique+"b")

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("begin tenant isolation tx: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantA); err != nil {
		t.Fatalf("set tenant A: %v", err)
	}

	var visibleCount int
	if err := tx.QueryRow(ctx, `
SELECT COUNT(*)
FROM erp_runtime_flows
WHERE source_document_no IN ($1, $2);
`, sourceA, sourceB).Scan(&visibleCount); err != nil {
		t.Fatalf("visible count query failed: %v", err)
	}

	if visibleCount != 1 {
		t.Fatalf("expected tenant A to see only 1 flow, got %d", visibleCount)
	}

	var tenantBVisibleCount int
	if err := tx.QueryRow(ctx, `
SELECT COUNT(*)
FROM erp_runtime_flows
WHERE source_document_no = $1;
`, sourceB).Scan(&tenantBVisibleCount); err != nil {
		t.Fatalf("tenant B visibility query failed: %v", err)
	}

	if tenantBVisibleCount != 0 {
		t.Fatalf("expected tenant B flow to be invisible, got %d", tenantBVisibleCount)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("commit tenant isolation tx: %v", err)
	}
}

func insertE2EFlowFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string, unique string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("fixture begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("fixture set tenant failed: %v", err)
	}

	var flowID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_runtime_flows (
	tenant_id,
	request_id,
	transaction_kind,
	source_module,
	source_document_type,
	source_document_no,
	total_amount,
	currency_code,
	exchange_rate,
	idempotency_key,
	flow_status,
	created_by,
	updated_by
) VALUES (
	$1, $2, 'sales_invoice', 'sales', 'invoice', $3,
	120, 'TRY', 1,
	$4, 'draft',
	'faz3_11_1e_rls_test',
	'faz3_11_1e_rls_test'
)
RETURNING flow_id::text;
`,
		tenantID,
		"req-"+unique,
		sourceNo,
		tenantID+":sales_invoice:"+sourceNo,
	).Scan(&flowID); err != nil {
		t.Fatalf("fixture insert flow failed: %v", err)
	}

	if _, err := tx.Exec(ctx, `
INSERT INTO erp_runtime_flow_steps (
	tenant_id,
	flow_id,
	step_no,
	step_kind,
	step_status,
	created_by,
	updated_by
) VALUES (
	$1, $2, 1, 'validate_request', 'pending',
	'faz3_11_1e_rls_test',
	'faz3_11_1e_rls_test'
);
`, tenantID, flowID); err != nil {
		t.Fatalf("fixture insert flow step failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("fixture commit failed: %v", err)
	}
}

func cleanupE2EFlowDBFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string) {
	t.Helper()

	if strings.TrimSpace(sourceNo) == "" {
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Logf("cleanup begin failed: %v", err)
		return
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Logf("cleanup set tenant failed: %v", err)
		return
	}

	if _, err := tx.Exec(ctx, `
DELETE FROM erp_runtime_flows
WHERE tenant_id = $1
  AND source_document_no = $2;
`, tenantID, sourceNo); err != nil {
		t.Logf("cleanup e2e flow failed: %v", err)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
	}
}

func currentUserBypassesRLS(t *testing.T, pool *pgxpool.Pool) bool {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	var bypass bool
	if err := pool.QueryRow(ctx, `
SELECT rolsuper OR rolbypassrls
FROM pg_roles
WHERE rolname = current_user;
`).Scan(&bypass); err != nil {
		t.Fatalf("check current user bypass rls failed: %v", err)
	}

	return bypass
}
