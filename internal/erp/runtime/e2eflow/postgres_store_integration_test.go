package e2eflow

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresRuntimeFlowStoreTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping e2e flow postgres store integration test")
	}

	return dsn
}

func TestPostgresRuntimeFlowStorePersistAndMarkCompleted(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresRuntimeFlowStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresRuntimeFlowStore(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	req := validRuntimeFlowRequest()
	req.Tenant.TenantID = "tenant_7"
	req.Tenant.RequestID = "req-" + unique
	req.Source.SourceDocumentNo = "E2E-STORE-" + unique
	req.IdempotencyKey = "tenant_7:sales_invoice:E2E-STORE-" + unique
	req.CorrelationID = "corr-" + unique

	cleanupRuntimeFlowStoreFixture(t, pool, req.Tenant.TenantID, req.Source.SourceDocumentNo)
	defer cleanupRuntimeFlowStoreFixture(t, pool, req.Tenant.TenantID, req.Source.SourceDocumentNo)

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("build plan: %v", err)
	}

	persistedPlan, err := store.PersistFlowPlan(ctx, plan)
	if err != nil {
		t.Fatalf("persist flow plan: %v", err)
	}

	if persistedPlan.Status != FlowStatusDraft {
		t.Fatalf("expected draft status, got %s", persistedPlan.Status)
	}

	flowCount, stepCount := countRuntimeFlowStoreRows(t, pool, req.Tenant.TenantID, req.Source.SourceDocumentNo)
	if flowCount != 1 {
		t.Fatalf("expected 1 flow, got %d", flowCount)
	}

	if stepCount != 6 {
		t.Fatalf("expected 6 steps, got %d", stepCount)
	}

	completedPlan, err := CompleteRuntimeFlowPlan(persistedPlan, time.Now().UTC())
	if err != nil {
		t.Fatalf("complete plan: %v", err)
	}

	completedPlan, err = store.MarkFlowCompleted(ctx, completedPlan)
	if err != nil {
		t.Fatalf("mark flow completed: %v", err)
	}

	if completedPlan.Status != FlowStatusCompleted {
		t.Fatalf("expected completed status, got %s", completedPlan.Status)
	}

	status := getRuntimeFlowStoreStatus(t, pool, req.Tenant.TenantID, req.Source.SourceDocumentNo)
	if status != "completed" {
		t.Fatalf("expected DB completed status, got %s", status)
	}
}

func TestPostgresRuntimeFlowStoreMarkFailed(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresRuntimeFlowStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresRuntimeFlowStore(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	req := validRuntimeFlowRequest()
	req.Tenant.TenantID = "tenant_7"
	req.Tenant.RequestID = "req-fail-" + unique
	req.Source.SourceDocumentNo = "E2E-STORE-FAIL-" + unique
	req.IdempotencyKey = "tenant_7:sales_invoice:E2E-STORE-FAIL-" + unique
	req.CorrelationID = "corr-fail-" + unique

	cleanupRuntimeFlowStoreFixture(t, pool, req.Tenant.TenantID, req.Source.SourceDocumentNo)
	defer cleanupRuntimeFlowStoreFixture(t, pool, req.Tenant.TenantID, req.Source.SourceDocumentNo)

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("build plan: %v", err)
	}

	persistedPlan, err := store.PersistFlowPlan(ctx, plan)
	if err != nil {
		t.Fatalf("persist flow plan: %v", err)
	}

	failedPlan, err := store.MarkFlowFailed(ctx, persistedPlan, ErrFlowStepKindInvalid)
	if err != nil {
		t.Fatalf("mark flow failed: %v", err)
	}

	if failedPlan.Status != FlowStatusFailed {
		t.Fatalf("expected failed status, got %s", failedPlan.Status)
	}

	status := getRuntimeFlowStoreStatus(t, pool, req.Tenant.TenantID, req.Source.SourceDocumentNo)
	if status != "failed" {
		t.Fatalf("expected DB failed status, got %s", status)
	}
}

func TestPostgresRuntimeFlowStoreValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresRuntimeFlowStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresRuntimeFlowStore(pool)

	plan := RuntimeFlowPlan{
		Status: FlowStatusDraft,
	}

	_, err = store.PersistFlowPlan(ctx, plan)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func cleanupRuntimeFlowStoreFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string) {
	t.Helper()

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
		t.Logf("cleanup flow failed: %v", err)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
	}
}

func countRuntimeFlowStoreRows(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string) (int, int) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("count begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("count set tenant failed: %v", err)
	}

	var flowCount int
	var stepCount int

	if err := tx.QueryRow(ctx, `
SELECT COUNT(*)
FROM erp_runtime_flows
WHERE tenant_id = $1
  AND source_document_no = $2;
`, tenantID, sourceNo).Scan(&flowCount); err != nil {
		t.Fatalf("flow count failed: %v", err)
	}

	if err := tx.QueryRow(ctx, `
SELECT COUNT(s.flow_step_id)
FROM erp_runtime_flows f
JOIN erp_runtime_flow_steps s ON s.flow_id = f.flow_id AND s.tenant_id = f.tenant_id
WHERE f.tenant_id = $1
  AND f.source_document_no = $2;
`, tenantID, sourceNo).Scan(&stepCount); err != nil {
		t.Fatalf("step count failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("count commit failed: %v", err)
	}

	return flowCount, stepCount
}

func getRuntimeFlowStoreStatus(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("status begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("status set tenant failed: %v", err)
	}

	var status string
	if err := tx.QueryRow(ctx, `
SELECT flow_status
FROM erp_runtime_flows
WHERE tenant_id = $1
  AND source_document_no = $2
LIMIT 1;
`, tenantID, sourceNo).Scan(&status); err != nil {
		t.Fatalf("status query failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("status commit failed: %v", err)
	}

	return status
}
