package main

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

	"github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/apisurface"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestGatewayProtectedERPRuntimeEndpointSmokeSuccess(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
	defer cancel()

	dsn := gatewayProtectedERPRuntimeSmokeDSN(t)

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	tenantID := "tenant_7"
	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	sourceNo := "GW-PROTECTED-ERP-" + unique

	cleanupGatewayProtectedERPRuntimeSmokeFlow(t, pool, tenantID, sourceNo)
	defer cleanupGatewayProtectedERPRuntimeSmokeFlow(t, pool, tenantID, sourceNo)

	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 10,
		DefaultDailyQuota:         100,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              5000,
		QueryTimeoutMS:            5000,
	}

	handler := newGatewayHandler(cfg, &stubLimiter{}, &stubLimiter{})

	apiReq := validGatewayERPRuntimeAPIRequest()
	apiReq.TenantID = tenantID
	apiReq.RequestID = "req-gw-protected-" + unique
	apiReq.ActorID = "user-gateway-protected"
	apiReq.TransactionKind = "sales_invoice"
	apiReq.Source.SourceModule = "sales"
	apiReq.Source.SourceDocumentType = "invoice"
	apiReq.Source.SourceDocumentID = ""
	apiReq.Source.SourceDocumentNo = sourceNo
	apiReq.Money.TotalAmount = 120
	apiReq.Money.CurrencyCode = "TRY"
	apiReq.Money.ExchangeRate = 1
	apiReq.IdempotencyKey = tenantID + ":sales_invoice:" + sourceNo
	apiReq.CorrelationID = "corr-gw-protected-" + unique

	body, err := json.Marshal(apiReq)
	if err != nil {
		t.Fatalf("marshal request: %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, apisurface.RuntimeFlowAPIPath, bytes.NewReader(body))
	req.Header.Set("Authorization", "Bearer "+testTokenOlustur(t, cfg.JWTSecret, tenantID))
	req.Header.Set("X-Tenant-ID", tenantID)
	req.Header.Set("X-Request-ID", apiReq.RequestID)

	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected HTTP 200, got %d body=%s", rec.Code, rec.Body.String())
	}

	var resp apisurface.RuntimeFlowAPIResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode response: %v body=%s", err, rec.Body.String())
	}

	if !resp.OK {
		t.Fatal("expected OK response")
	}

	if resp.TenantID != tenantID {
		t.Fatalf("expected tenant %s, got %s", tenantID, resp.TenantID)
	}

	if resp.Status != "completed" {
		t.Fatalf("expected completed status, got %s", resp.Status)
	}

	if resp.StepCount != 6 {
		t.Fatalf("expected 6 steps, got %d", resp.StepCount)
	}

	flowStatus, completedStepCount := readGatewayProtectedERPRuntimeSmokeFlowStatus(t, pool, tenantID, sourceNo)

	if flowStatus != "completed" {
		t.Fatalf("expected DB completed flow, got %s", flowStatus)
	}

	if completedStepCount != 6 {
		t.Fatalf("expected 6 completed DB steps, got %d", completedStepCount)
	}
}

func TestGatewayProtectedERPRuntimeEndpointRejectsMissingBearer(t *testing.T) {
	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 10,
		DefaultDailyQuota:         100,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              5000,
		QueryTimeoutMS:            5000,
	}

	handler := newGatewayHandler(cfg, &stubLimiter{}, &stubLimiter{})

	body, err := json.Marshal(validGatewayERPRuntimeAPIRequest())
	if err != nil {
		t.Fatalf("marshal request: %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, apisurface.RuntimeFlowAPIPath, bytes.NewReader(body))
	req.Header.Set("X-Tenant-ID", "tenant_7")
	req.Header.Set("X-Request-ID", "req-missing-bearer")

	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected HTTP 401, got %d body=%s", rec.Code, rec.Body.String())
	}
}

func TestGatewayProtectedERPRuntimeEndpointRejectsTenantMismatch(t *testing.T) {
	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 10,
		DefaultDailyQuota:         100,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              5000,
		QueryTimeoutMS:            5000,
	}

	handler := newGatewayHandler(cfg, &stubLimiter{}, &stubLimiter{})

	body, err := json.Marshal(validGatewayERPRuntimeAPIRequest())
	if err != nil {
		t.Fatalf("marshal request: %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, apisurface.RuntimeFlowAPIPath, bytes.NewReader(body))
	req.Header.Set("Authorization", "Bearer "+testTokenOlustur(t, cfg.JWTSecret, "tenant_7"))
	req.Header.Set("X-Tenant-ID", "tenant_99")
	req.Header.Set("X-Request-ID", "req-tenant-mismatch")

	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("expected HTTP 403, got %d body=%s", rec.Code, rec.Body.String())
	}
}

func TestGatewayProtectedERPRuntimeEndpointRejectsWrongMethod(t *testing.T) {
	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 10,
		DefaultDailyQuota:         100,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              5000,
		QueryTimeoutMS:            5000,
	}

	handler := newGatewayHandler(cfg, &stubLimiter{}, &stubLimiter{})

	req := httptest.NewRequest(http.MethodGet, apisurface.RuntimeFlowAPIPath, nil)
	req.Header.Set("Authorization", "Bearer "+testTokenOlustur(t, cfg.JWTSecret, "tenant_7"))
	req.Header.Set("X-Tenant-ID", "tenant_7")
	req.Header.Set("X-Request-ID", "req-wrong-method")

	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("expected HTTP 405, got %d body=%s", rec.Code, rec.Body.String())
	}
}

func gatewayProtectedERPRuntimeSmokeDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping gateway protected ERP runtime smoke test")
	}

	return dsn
}

func cleanupGatewayProtectedERPRuntimeSmokeFlow(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string) {
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

func readGatewayProtectedERPRuntimeSmokeFlowStatus(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string) (string, int) {
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
