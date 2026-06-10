package apisurface

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/e2eflow"
	"github.com/jackc/pgx/v5/pgxpool"
)

type apiSurfaceE2ESmokePublisher struct {
	completedCalled bool
	failedCalled    bool
}

func (p *apiSurfaceE2ESmokePublisher) PublishFlowCompleted(ctx context.Context, result e2eflow.RuntimeFlowResult) error {
	p.completedCalled = true
	return nil
}

func (p *apiSurfaceE2ESmokePublisher) PublishFlowFailed(ctx context.Context, plan e2eflow.RuntimeFlowPlan, cause error) error {
	p.failedCalled = true
	return nil
}

func apiSurfaceE2ESmokeDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping api e2e http smoke test")
	}

	return dsn
}

func TestRuntimeFlowAPIHTTPHandlerE2ESmokeSalesInvoice(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, apiSurfaceE2ESmokeDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	tenantID := "tenant_7"
	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	sourceNo := "API-E2E-SALES-" + unique

	cleanupRuntimeFlowAPIE2ESmokeFixture(t, pool, tenantID, sourceNo)
	defer cleanupRuntimeFlowAPIE2ESmokeFixture(t, pool, tenantID, sourceNo)

	documentCalled := 0
	taxCalled := 0
	cashBankCalled := 0
	journalCalled := 0
	ledgerCalled := 0
	runtimeEventCalled := 0

	registry, err := e2eflow.NewRuntimeBridgeStepAdapterRegistry(e2eflow.RuntimeBridgeHandlers{
		PersistDocument: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			documentCalled++
			return nil
		},
		CalculateTax: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			taxCalled++
			return nil
		},
		ExecuteCashBankPayment: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			cashBankCalled++
			return nil
		},
		PostJournal: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			journalCalled++
			return nil
		},
		PostLedger: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			ledgerCalled++
			return nil
		},
		PublishRuntimeEvent: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			runtimeEventCalled++
			return nil
		},
	})
	if err != nil {
		t.Fatalf("create bridge registry: %v", err)
	}

	flowPublisher := &apiSurfaceE2ESmokePublisher{}

	orchestrator := e2eflow.NewDefaultRuntimeE2EOrchestrator(
		e2eflow.NewDefaultRuntimeFlowPlanner(),
		e2eflow.NewAdapterRuntimeFlowStepRunner(registry, nil, true),
		e2eflow.NewPostgresRuntimeFlowStore(pool),
		flowPublisher,
	)

	service := NewDefaultRuntimeFlowAPIService(orchestrator)
	handler := NewRuntimeFlowHTTPHandler(service)

	apiReq := validRuntimeFlowAPIRequest()
	apiReq.TenantID = tenantID
	apiReq.RequestID = "req-api-sales-" + unique
	apiReq.ActorID = "user-api-smoke"
	apiReq.TransactionKind = string(e2eflow.TransactionKindSalesInvoice)
	apiReq.Source.SourceModule = "sales"
	apiReq.Source.SourceDocumentType = "invoice"
	apiReq.Source.SourceDocumentID = ""
	apiReq.Source.SourceDocumentNo = sourceNo
	apiReq.Money.TotalAmount = 120
	apiReq.Money.CurrencyCode = "TRY"
	apiReq.Money.ExchangeRate = 1
	apiReq.IdempotencyKey = tenantID + ":sales_invoice:" + sourceNo
	apiReq.CorrelationID = "corr-api-sales-" + unique

	body, err := json.Marshal(apiReq)
	if err != nil {
		t.Fatalf("marshal api request: %v", err)
	}

	httpReq := httptest.NewRequest(http.MethodPost, RuntimeFlowAPIPath, bytes.NewReader(body))
	httpRec := httptest.NewRecorder()

	handler.ServeHTTP(httpRec, httpReq)

	if httpRec.Code != http.StatusOK {
		t.Fatalf("expected HTTP 200, got %d body=%s", httpRec.Code, httpRec.Body.String())
	}

	var apiResp RuntimeFlowAPIResponse
	if err := json.Unmarshal(httpRec.Body.Bytes(), &apiResp); err != nil {
		t.Fatalf("decode api response: %v", err)
	}

	if !apiResp.OK {
		t.Fatal("expected api OK response")
	}

	if apiResp.Status != "completed" {
		t.Fatalf("expected completed status, got %s", apiResp.Status)
	}

	if apiResp.StepCount != 6 {
		t.Fatalf("expected 6 steps, got %d", apiResp.StepCount)
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

	if runtimeEventCalled != 1 {
		t.Fatalf("expected runtime event called 1, got %d", runtimeEventCalled)
	}

	if !flowPublisher.completedCalled {
		t.Fatal("expected flow completed publisher")
	}

	if flowPublisher.failedCalled {
		t.Fatal("flow failed publisher should not be called")
	}

	flowStatus, completedStepCount := readRuntimeFlowAPIE2ESmokeStatus(t, pool, tenantID, sourceNo)

	if flowStatus != "completed" {
		t.Fatalf("expected DB completed flow, got %s", flowStatus)
	}

	if completedStepCount != 6 {
		t.Fatalf("expected 6 completed DB steps, got %d", completedStepCount)
	}
}

func TestRuntimeFlowAPIHTTPHandlerE2ESmokeCashReceipt(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, apiSurfaceE2ESmokeDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	tenantID := "tenant_7"
	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	sourceNo := "API-E2E-CASH-" + unique

	cleanupRuntimeFlowAPIE2ESmokeFixture(t, pool, tenantID, sourceNo)
	defer cleanupRuntimeFlowAPIE2ESmokeFixture(t, pool, tenantID, sourceNo)

	documentCalled := 0
	taxCalled := 0
	cashBankCalled := 0
	journalCalled := 0
	ledgerCalled := 0
	runtimeEventCalled := 0

	registry, err := e2eflow.NewRuntimeBridgeStepAdapterRegistry(e2eflow.RuntimeBridgeHandlers{
		PersistDocument: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			documentCalled++
			return nil
		},
		CalculateTax: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			taxCalled++
			return nil
		},
		ExecuteCashBankPayment: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			cashBankCalled++
			return nil
		},
		PostJournal: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			journalCalled++
			return nil
		},
		PostLedger: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			ledgerCalled++
			return nil
		},
		PublishRuntimeEvent: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			runtimeEventCalled++
			return nil
		},
	})
	if err != nil {
		t.Fatalf("create bridge registry: %v", err)
	}

	flowPublisher := &apiSurfaceE2ESmokePublisher{}

	orchestrator := e2eflow.NewDefaultRuntimeE2EOrchestrator(
		e2eflow.NewDefaultRuntimeFlowPlanner(),
		e2eflow.NewAdapterRuntimeFlowStepRunner(registry, nil, true),
		e2eflow.NewPostgresRuntimeFlowStore(pool),
		flowPublisher,
	)

	service := NewDefaultRuntimeFlowAPIService(orchestrator)
	handler := NewRuntimeFlowHTTPHandler(service)

	apiReq := validRuntimeFlowAPIRequest()
	apiReq.TenantID = tenantID
	apiReq.RequestID = "req-api-cash-" + unique
	apiReq.ActorID = "user-api-smoke"
	apiReq.TransactionKind = string(e2eflow.TransactionKindCashReceipt)
	apiReq.Source.SourceModule = "cashbank"
	apiReq.Source.SourceDocumentType = "payment"
	apiReq.Source.SourceDocumentID = ""
	apiReq.Source.SourceDocumentNo = sourceNo
	apiReq.Money.TotalAmount = 500
	apiReq.Money.CurrencyCode = "TRY"
	apiReq.Money.ExchangeRate = 1
	apiReq.IdempotencyKey = tenantID + ":cash_receipt:" + sourceNo
	apiReq.CorrelationID = "corr-api-cash-" + unique

	body, err := json.Marshal(apiReq)
	if err != nil {
		t.Fatalf("marshal api request: %v", err)
	}

	httpReq := httptest.NewRequest(http.MethodPost, RuntimeFlowAPIPath, bytes.NewReader(body))
	httpRec := httptest.NewRecorder()

	handler.ServeHTTP(httpRec, httpReq)

	if httpRec.Code != http.StatusOK {
		t.Fatalf("expected HTTP 200, got %d body=%s", httpRec.Code, httpRec.Body.String())
	}

	var apiResp RuntimeFlowAPIResponse
	if err := json.Unmarshal(httpRec.Body.Bytes(), &apiResp); err != nil {
		t.Fatalf("decode api response: %v", err)
	}

	if !apiResp.OK {
		t.Fatal("expected api OK response")
	}

	if apiResp.Status != "completed" {
		t.Fatalf("expected completed status, got %s", apiResp.Status)
	}

	if apiResp.StepCount != 5 {
		t.Fatalf("expected 5 steps, got %d", apiResp.StepCount)
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

	if runtimeEventCalled != 1 {
		t.Fatalf("expected runtime event called 1, got %d", runtimeEventCalled)
	}

	if !flowPublisher.completedCalled {
		t.Fatal("expected flow completed publisher")
	}

	if flowPublisher.failedCalled {
		t.Fatal("flow failed publisher should not be called")
	}

	flowStatus, completedStepCount := readRuntimeFlowAPIE2ESmokeStatus(t, pool, tenantID, sourceNo)

	if flowStatus != "completed" {
		t.Fatalf("expected DB completed flow, got %s", flowStatus)
	}

	if completedStepCount != 5 {
		t.Fatalf("expected 5 completed DB steps, got %d", completedStepCount)
	}
}

func cleanupRuntimeFlowAPIE2ESmokeFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string) {
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

func readRuntimeFlowAPIE2ESmokeStatus(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string) (string, int) {
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
