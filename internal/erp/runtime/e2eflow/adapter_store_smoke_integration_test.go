package e2eflow

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type smokeDocumentAdapter struct {
	called bool
}

func (a *smokeDocumentAdapter) PersistDocument(ctx context.Context, plan RuntimeFlowPlan) error {
	a.called = true
	return nil
}

type smokeTaxAdapter struct {
	called bool
}

func (a *smokeTaxAdapter) CalculateTax(ctx context.Context, plan RuntimeFlowPlan) error {
	a.called = true
	return nil
}

type smokeCashBankAdapter struct {
	called bool
}

func (a *smokeCashBankAdapter) ExecuteCashBankPayment(ctx context.Context, plan RuntimeFlowPlan) error {
	a.called = true
	return nil
}

type smokeJournalAdapter struct {
	called bool
}

func (a *smokeJournalAdapter) PostJournal(ctx context.Context, plan RuntimeFlowPlan) error {
	a.called = true
	return nil
}

type smokeLedgerAdapter struct {
	called bool
}

func (a *smokeLedgerAdapter) PostLedger(ctx context.Context, plan RuntimeFlowPlan) error {
	a.called = true
	return nil
}

type smokePublisherAdapter struct {
	called bool
}

func (a *smokePublisherAdapter) PublishRuntimeEvent(ctx context.Context, plan RuntimeFlowPlan) error {
	a.called = true
	return nil
}

type smokeFlowPublisher struct {
	completedCalled bool
	failedCalled    bool

	result RuntimeFlowResult
}

func (p *smokeFlowPublisher) PublishFlowCompleted(ctx context.Context, result RuntimeFlowResult) error {
	p.completedCalled = true
	p.result = result
	return nil
}

func (p *smokeFlowPublisher) PublishFlowFailed(ctx context.Context, plan RuntimeFlowPlan, cause error) error {
	p.failedCalled = true
	return nil
}

func adapterStoreSmokeDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping adapter store smoke test")
	}

	return dsn
}

func TestRuntimeE2EFlowAdapterStoreSmokeSalesInvoice(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, adapterStoreSmokeDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	tenantID := "tenant_7"
	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	sourceNo := "E2E-ADAPTER-SMOKE-" + unique

	cleanupAdapterStoreSmokeFixture(t, pool, tenantID, sourceNo)
	defer cleanupAdapterStoreSmokeFixture(t, pool, tenantID, sourceNo)

	documentAdapter := &smokeDocumentAdapter{}
	taxAdapter := &smokeTaxAdapter{}
	cashBankAdapter := &smokeCashBankAdapter{}
	journalAdapter := &smokeJournalAdapter{}
	ledgerAdapter := &smokeLedgerAdapter{}
	publisherAdapter := &smokePublisherAdapter{}

	registry, err := NewRuntimeStepAdapterRegistry(RuntimeStepAdapterPorts{
		Document:  documentAdapter,
		Tax:       taxAdapter,
		CashBank:  cashBankAdapter,
		Journal:   journalAdapter,
		Ledger:    ledgerAdapter,
		Publisher: publisherAdapter,
	})
	if err != nil {
		t.Fatalf("create registry: %v", err)
	}

	store := NewPostgresRuntimeFlowStore(pool)
	stepRunner := NewAdapterRuntimeFlowStepRunner(registry, nil, true)
	flowPublisher := &smokeFlowPublisher{}

	orchestrator := NewDefaultRuntimeE2EOrchestrator(
		NewDefaultRuntimeFlowPlanner(),
		stepRunner,
		store,
		flowPublisher,
	)

	req := validRuntimeFlowRequest()
	req.Tenant.TenantID = tenantID
	req.Tenant.RequestID = "req-" + unique
	req.TransactionKind = TransactionKindSalesInvoice
	req.Source.SourceModule = "sales"
	req.Source.SourceDocumentType = "invoice"
	req.Source.SourceDocumentNo = sourceNo
	req.Source.SourceDocumentID = ""
	req.Money.TotalAmount = 120
	req.Money.CurrencyCode = "TRY"
	req.Money.ExchangeRate = 1
	req.IdempotencyKey = tenantID + ":sales_invoice:" + sourceNo
	req.CorrelationID = "corr-" + unique

	result, err := orchestrator.ExecuteRuntimeFlow(ctx, req)
	if err != nil {
		t.Fatalf("execute runtime flow: %v", err)
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

	if !documentAdapter.called {
		t.Fatal("expected document adapter to be called")
	}

	if !taxAdapter.called {
		t.Fatal("expected tax adapter to be called")
	}

	if cashBankAdapter.called {
		t.Fatal("sales invoice flow should not call cashbank adapter")
	}

	if !journalAdapter.called {
		t.Fatal("expected journal adapter to be called")
	}

	if !ledgerAdapter.called {
		t.Fatal("expected ledger adapter to be called")
	}

	if !publisherAdapter.called {
		t.Fatal("expected runtime publisher adapter to be called")
	}

	if !flowPublisher.completedCalled {
		t.Fatal("expected flow completed publisher to be called")
	}

	if flowPublisher.failedCalled {
		t.Fatal("flow failed publisher should not be called")
	}

	flowStatus, completedStepCount := readAdapterStoreSmokeStatus(t, pool, tenantID, sourceNo)

	if flowStatus != "completed" {
		t.Fatalf("expected DB flow completed, got %s", flowStatus)
	}

	if completedStepCount != 6 {
		t.Fatalf("expected 6 completed DB steps, got %d", completedStepCount)
	}
}

func TestRuntimeE2EFlowAdapterStoreSmokeCashReceipt(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, adapterStoreSmokeDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	tenantID := "tenant_7"
	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	sourceNo := "E2E-CASH-SMOKE-" + unique

	cleanupAdapterStoreSmokeFixture(t, pool, tenantID, sourceNo)
	defer cleanupAdapterStoreSmokeFixture(t, pool, tenantID, sourceNo)

	documentAdapter := &smokeDocumentAdapter{}
	taxAdapter := &smokeTaxAdapter{}
	cashBankAdapter := &smokeCashBankAdapter{}
	journalAdapter := &smokeJournalAdapter{}
	ledgerAdapter := &smokeLedgerAdapter{}
	publisherAdapter := &smokePublisherAdapter{}

	registry, err := NewRuntimeStepAdapterRegistry(RuntimeStepAdapterPorts{
		Document:  documentAdapter,
		Tax:       taxAdapter,
		CashBank:  cashBankAdapter,
		Journal:   journalAdapter,
		Ledger:    ledgerAdapter,
		Publisher: publisherAdapter,
	})
	if err != nil {
		t.Fatalf("create registry: %v", err)
	}

	orchestrator := NewDefaultRuntimeE2EOrchestrator(
		NewDefaultRuntimeFlowPlanner(),
		NewAdapterRuntimeFlowStepRunner(registry, nil, true),
		NewPostgresRuntimeFlowStore(pool),
		&smokeFlowPublisher{},
	)

	req := validRuntimeFlowRequest()
	req.Tenant.TenantID = tenantID
	req.Tenant.RequestID = "req-cash-" + unique
	req.TransactionKind = TransactionKindCashReceipt
	req.Source.SourceModule = "cashbank"
	req.Source.SourceDocumentType = "payment"
	req.Source.SourceDocumentNo = sourceNo
	req.Source.SourceDocumentID = ""
	req.Money.TotalAmount = 500
	req.Money.CurrencyCode = "TRY"
	req.Money.ExchangeRate = 1
	req.IdempotencyKey = tenantID + ":cash_receipt:" + sourceNo
	req.CorrelationID = "corr-cash-" + unique

	result, err := orchestrator.ExecuteRuntimeFlow(ctx, req)
	if err != nil {
		t.Fatalf("execute cash runtime flow: %v", err)
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}

	if result.StepCount != 5 {
		t.Fatalf("expected 5 cash flow steps, got %d", result.StepCount)
	}

	if documentAdapter.called {
		t.Fatal("cash receipt flow should not call document adapter")
	}

	if taxAdapter.called {
		t.Fatal("cash receipt flow should not call tax adapter")
	}

	if !cashBankAdapter.called {
		t.Fatal("expected cashbank adapter to be called")
	}

	if !journalAdapter.called {
		t.Fatal("expected journal adapter to be called")
	}

	if !ledgerAdapter.called {
		t.Fatal("expected ledger adapter to be called")
	}

	if !publisherAdapter.called {
		t.Fatal("expected publisher adapter to be called")
	}

	flowStatus, completedStepCount := readAdapterStoreSmokeStatus(t, pool, tenantID, sourceNo)

	if flowStatus != "completed" {
		t.Fatalf("expected DB flow completed, got %s", flowStatus)
	}

	if completedStepCount != 5 {
		t.Fatalf("expected 5 completed DB steps, got %d", completedStepCount)
	}
}

func cleanupAdapterStoreSmokeFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string) {
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

func readAdapterStoreSmokeStatus(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string) (string, int) {
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
