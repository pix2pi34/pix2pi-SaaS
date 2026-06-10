package e2eflow

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type bridgeSmokeFlowPublisher struct {
	completedCalled bool
	failedCalled    bool

	result RuntimeFlowResult
}

func (p *bridgeSmokeFlowPublisher) PublishFlowCompleted(ctx context.Context, result RuntimeFlowResult) error {
	p.completedCalled = true
	p.result = result
	return nil
}

func (p *bridgeSmokeFlowPublisher) PublishFlowFailed(ctx context.Context, plan RuntimeFlowPlan, cause error) error {
	p.failedCalled = true
	return nil
}

func bridgeStoreSmokeDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping bridge store smoke test")
	}

	return dsn
}

func TestRuntimeBridgeStoreSmokeSalesInvoice(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, bridgeStoreSmokeDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	tenantID := "tenant_7"
	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	sourceNo := "E2E-BRIDGE-SALES-" + unique

	cleanupRuntimeBridgeStoreSmokeFixture(t, pool, tenantID, sourceNo)
	defer cleanupRuntimeBridgeStoreSmokeFixture(t, pool, tenantID, sourceNo)

	documentCalled := 0
	taxCalled := 0
	cashBankCalled := 0
	journalCalled := 0
	ledgerCalled := 0
	publisherCalled := 0

	registry, err := NewRuntimeBridgeStepAdapterRegistry(RuntimeBridgeHandlers{
		PersistDocument: func(ctx context.Context, plan RuntimeFlowPlan) error {
			documentCalled++
			if plan.TransactionKind != TransactionKindSalesInvoice {
				t.Fatalf("expected sales_invoice, got %s", plan.TransactionKind)
			}
			return nil
		},
		CalculateTax: func(ctx context.Context, plan RuntimeFlowPlan) error {
			taxCalled++
			return nil
		},
		ExecuteCashBankPayment: func(ctx context.Context, plan RuntimeFlowPlan) error {
			cashBankCalled++
			return nil
		},
		PostJournal: func(ctx context.Context, plan RuntimeFlowPlan) error {
			journalCalled++
			return nil
		},
		PostLedger: func(ctx context.Context, plan RuntimeFlowPlan) error {
			ledgerCalled++
			return nil
		},
		PublishRuntimeEvent: func(ctx context.Context, plan RuntimeFlowPlan) error {
			publisherCalled++
			return nil
		},
	})
	if err != nil {
		t.Fatalf("create bridge registry: %v", err)
	}

	flowPublisher := &bridgeSmokeFlowPublisher{}

	orchestrator := NewDefaultRuntimeE2EOrchestrator(
		NewDefaultRuntimeFlowPlanner(),
		NewAdapterRuntimeFlowStepRunner(registry, nil, true),
		NewPostgresRuntimeFlowStore(pool),
		flowPublisher,
	)

	req := validRuntimeFlowRequest()
	req.Tenant.TenantID = tenantID
	req.Tenant.RequestID = "req-bridge-sales-" + unique
	req.TransactionKind = TransactionKindSalesInvoice
	req.Source.SourceModule = "sales"
	req.Source.SourceDocumentType = "invoice"
	req.Source.SourceDocumentID = ""
	req.Source.SourceDocumentNo = sourceNo
	req.Money.TotalAmount = 120
	req.Money.CurrencyCode = "TRY"
	req.Money.ExchangeRate = 1
	req.IdempotencyKey = tenantID + ":sales_invoice:" + sourceNo
	req.CorrelationID = "corr-bridge-sales-" + unique

	result, err := orchestrator.ExecuteRuntimeFlow(ctx, req)
	if err != nil {
		t.Fatalf("execute bridge sales flow: %v", err)
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}

	if result.Status != FlowStatusCompleted {
		t.Fatalf("expected completed result, got %s", result.Status)
	}

	if result.StepCount != 6 {
		t.Fatalf("expected 6 steps, got %d", result.StepCount)
	}

	if documentCalled != 1 {
		t.Fatalf("expected document called 1, got %d", documentCalled)
	}

	if taxCalled != 1 {
		t.Fatalf("expected tax called 1, got %d", taxCalled)
	}

	if cashBankCalled != 0 {
		t.Fatalf("sales invoice should not call cashbank, got %d", cashBankCalled)
	}

	if journalCalled != 1 {
		t.Fatalf("expected journal called 1, got %d", journalCalled)
	}

	if ledgerCalled != 1 {
		t.Fatalf("expected ledger called 1, got %d", ledgerCalled)
	}

	if publisherCalled != 1 {
		t.Fatalf("expected publisher called 1, got %d", publisherCalled)
	}

	if !flowPublisher.completedCalled {
		t.Fatal("expected flow completed publisher")
	}

	if flowPublisher.failedCalled {
		t.Fatal("flow failed publisher should not be called")
	}

	flowStatus, completedStepCount := readRuntimeBridgeStoreSmokeStatus(t, pool, tenantID, sourceNo)

	if flowStatus != "completed" {
		t.Fatalf("expected DB completed flow, got %s", flowStatus)
	}

	if completedStepCount != 6 {
		t.Fatalf("expected 6 completed DB steps, got %d", completedStepCount)
	}
}

func TestRuntimeBridgeStoreSmokeCashReceipt(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, bridgeStoreSmokeDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	tenantID := "tenant_7"
	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	sourceNo := "E2E-BRIDGE-CASH-" + unique

	cleanupRuntimeBridgeStoreSmokeFixture(t, pool, tenantID, sourceNo)
	defer cleanupRuntimeBridgeStoreSmokeFixture(t, pool, tenantID, sourceNo)

	documentCalled := 0
	taxCalled := 0
	cashBankCalled := 0
	journalCalled := 0
	ledgerCalled := 0
	publisherCalled := 0

	registry, err := NewRuntimeBridgeStepAdapterRegistry(RuntimeBridgeHandlers{
		PersistDocument: func(ctx context.Context, plan RuntimeFlowPlan) error {
			documentCalled++
			return nil
		},
		CalculateTax: func(ctx context.Context, plan RuntimeFlowPlan) error {
			taxCalled++
			return nil
		},
		ExecuteCashBankPayment: func(ctx context.Context, plan RuntimeFlowPlan) error {
			cashBankCalled++
			if plan.TransactionKind != TransactionKindCashReceipt {
				t.Fatalf("expected cash_receipt, got %s", plan.TransactionKind)
			}
			return nil
		},
		PostJournal: func(ctx context.Context, plan RuntimeFlowPlan) error {
			journalCalled++
			return nil
		},
		PostLedger: func(ctx context.Context, plan RuntimeFlowPlan) error {
			ledgerCalled++
			return nil
		},
		PublishRuntimeEvent: func(ctx context.Context, plan RuntimeFlowPlan) error {
			publisherCalled++
			return nil
		},
	})
	if err != nil {
		t.Fatalf("create bridge registry: %v", err)
	}

	flowPublisher := &bridgeSmokeFlowPublisher{}

	orchestrator := NewDefaultRuntimeE2EOrchestrator(
		NewDefaultRuntimeFlowPlanner(),
		NewAdapterRuntimeFlowStepRunner(registry, nil, true),
		NewPostgresRuntimeFlowStore(pool),
		flowPublisher,
	)

	req := validRuntimeFlowRequest()
	req.Tenant.TenantID = tenantID
	req.Tenant.RequestID = "req-bridge-cash-" + unique
	req.TransactionKind = TransactionKindCashReceipt
	req.Source.SourceModule = "cashbank"
	req.Source.SourceDocumentType = "payment"
	req.Source.SourceDocumentID = ""
	req.Source.SourceDocumentNo = sourceNo
	req.Money.TotalAmount = 500
	req.Money.CurrencyCode = "TRY"
	req.Money.ExchangeRate = 1
	req.IdempotencyKey = tenantID + ":cash_receipt:" + sourceNo
	req.CorrelationID = "corr-bridge-cash-" + unique

	result, err := orchestrator.ExecuteRuntimeFlow(ctx, req)
	if err != nil {
		t.Fatalf("execute bridge cash flow: %v", err)
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}

	if result.Status != FlowStatusCompleted {
		t.Fatalf("expected completed result, got %s", result.Status)
	}

	if result.StepCount != 5 {
		t.Fatalf("expected 5 steps, got %d", result.StepCount)
	}

	if documentCalled != 0 {
		t.Fatalf("cash receipt should not call document, got %d", documentCalled)
	}

	if taxCalled != 0 {
		t.Fatalf("cash receipt should not call tax, got %d", taxCalled)
	}

	if cashBankCalled != 1 {
		t.Fatalf("expected cashbank called 1, got %d", cashBankCalled)
	}

	if journalCalled != 1 {
		t.Fatalf("expected journal called 1, got %d", journalCalled)
	}

	if ledgerCalled != 1 {
		t.Fatalf("expected ledger called 1, got %d", ledgerCalled)
	}

	if publisherCalled != 1 {
		t.Fatalf("expected publisher called 1, got %d", publisherCalled)
	}

	if !flowPublisher.completedCalled {
		t.Fatal("expected flow completed publisher")
	}

	if flowPublisher.failedCalled {
		t.Fatal("flow failed publisher should not be called")
	}

	flowStatus, completedStepCount := readRuntimeBridgeStoreSmokeStatus(t, pool, tenantID, sourceNo)

	if flowStatus != "completed" {
		t.Fatalf("expected DB completed flow, got %s", flowStatus)
	}

	if completedStepCount != 5 {
		t.Fatalf("expected 5 completed DB steps, got %d", completedStepCount)
	}
}

func cleanupRuntimeBridgeStoreSmokeFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string) {
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

func readRuntimeBridgeStoreSmokeStatus(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string) (string, int) {
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
	var completedStepCount int

	if err := tx.QueryRow(ctx, `
SELECT f.flow_status,
       COUNT(s.flow_step_id) FILTER (WHERE s.step_status = 'completed')
FROM erp_runtime_flows f
JOIN erp_runtime_flow_steps s ON s.flow_id = f.flow_id AND s.tenant_id = f.tenant_id
WHERE f.tenant_id = $1
  AND f.source_document_no = $2
GROUP BY f.flow_status;
`, tenantID, sourceNo).Scan(&status, &completedStepCount); err != nil {
		t.Fatalf("status query failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("status commit failed: %v", err)
	}

	return status, completedStepCount
}
