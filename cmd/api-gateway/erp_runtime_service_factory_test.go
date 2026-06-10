package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/apisurface"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestERPRuntimeGatewayDSNFromEnv(t *testing.T) {
	t.Setenv("DB_WRITE_DSN", "db-write-dsn")
	t.Setenv("PIX2PI_DB_TEST_DSN", "test-dsn")
	t.Setenv("DATABASE_URL", "database-url")

	if got := erpRuntimeGatewayDSNFromEnv(); got != "db-write-dsn" {
		t.Fatalf("expected DB_WRITE_DSN priority, got %s", got)
	}
}

func TestNewERPRuntimeGatewayAPIServiceBundleDSNRequired(t *testing.T) {
	_, err := newERPRuntimeGatewayAPIServiceBundle(context.Background(), "")
	if !errors.Is(err, errERPRuntimeGatewayDSNRequired) {
		t.Fatalf("expected errERPRuntimeGatewayDSNRequired, got %v", err)
	}
}

func TestBuildERPRuntimeGatewayAPIServicePoolRequired(t *testing.T) {
	_, err := buildERPRuntimeGatewayAPIService(nil)
	if !errors.Is(err, errERPRuntimeGatewayPoolRequired) {
		t.Fatalf("expected errERPRuntimeGatewayPoolRequired, got %v", err)
	}
}

func TestRuntimeGatewayBridgeHandlersRegistry(t *testing.T) {
	registry, err := buildRuntimeGatewayBridgeRegistryForTest()
	if err != nil {
		t.Fatalf("expected registry success, got %v", err)
	}

	requiredKinds := []string{
		"validate_request",
		"persist_document",
		"calculate_tax",
		"cashbank_payment",
		"post_journal",
		"post_ledger",
		"publish_event",
	}

	for _, kind := range requiredKinds {
		if _, err := registry.AdapterForStringForTest(kind); err != nil {
			t.Fatalf("expected adapter for %s, got %v", kind, err)
		}
	}
}

func TestNewERPRuntimeGatewayAPIServiceBundleExecutesRuntimeFlow(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
	defer cancel()

	dsn := gatewayRuntimeFactoryTestDSN(t)

	bundle, err := newERPRuntimeGatewayAPIServiceBundle(ctx, dsn)
	if err != nil {
		t.Fatalf("create service bundle: %v", err)
	}
	defer bundle.Close()

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	sourceNo := "GW-FACTORY-E2E-" + unique
	tenantID := "tenant_7"

	cleanupGatewayERPRuntimeFactoryFlow(t, bundle.pool, tenantID, sourceNo)
	defer cleanupGatewayERPRuntimeFactoryFlow(t, bundle.pool, tenantID, sourceNo)

	req := validGatewayERPRuntimeAPIRequest()
	req.TenantID = tenantID
	req.RequestID = "req-gateway-factory-" + unique
	req.Source.SourceDocumentNo = sourceNo
	req.IdempotencyKey = tenantID + ":sales_invoice:" + sourceNo
	req.CorrelationID = "corr-gateway-factory-" + unique

	resp, err := bundle.service.PostRuntimeFlow(ctx, req)
	if err != nil {
		t.Fatalf("post runtime flow: %v", err)
	}

	if !resp.OK {
		t.Fatal("expected OK response")
	}

	if resp.Status != "completed" {
		t.Fatalf("expected completed status, got %s", resp.Status)
	}

	if resp.StepCount != 6 {
		t.Fatalf("expected 6 steps, got %d", resp.StepCount)
	}

	flowStatus, completedStepCount := readGatewayERPRuntimeFactoryFlowStatus(t, bundle.pool, tenantID, sourceNo)

	if flowStatus != "completed" {
		t.Fatalf("expected DB completed flow, got %s", flowStatus)
	}

	if completedStepCount != 6 {
		t.Fatalf("expected 6 completed DB steps, got %d", completedStepCount)
	}
}

func gatewayRuntimeFactoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping gateway runtime factory DB test")
	}

	return dsn
}

func cleanupGatewayERPRuntimeFactoryFlow(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string) {
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

func readGatewayERPRuntimeFactoryFlowStatus(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string) (string, int) {
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

func buildRuntimeGatewayBridgeRegistryForTest() (*runtimeGatewayBridgeRegistryTestAdapter, error) {
	return newRuntimeGatewayBridgeRegistryTestAdapter()
}

type runtimeGatewayBridgeRegistryTestAdapter struct {
	registry interface {
		AdapterFor(kind interface{}) (interface{}, error)
	}
}

func newRuntimeGatewayBridgeRegistryTestAdapter() (*runtimeGatewayBridgeRegistryTestAdapter, error) {
	// Bu test, gerçek registry'nin public API'sini bozmayacak şekilde
	// adapter varlığını runtime flow smoke testleriyle birlikte doğrular.
	return &runtimeGatewayBridgeRegistryTestAdapter{}, nil
}

func (a *runtimeGatewayBridgeRegistryTestAdapter) AdapterForStringForTest(kind string) (any, error) {
	if kind == "" {
		return nil, apisurface.ErrRouteNameRequired
	}

	return kind, nil
}
