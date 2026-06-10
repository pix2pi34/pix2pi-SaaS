package apisurface

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/e2eflow"
)

type fakeRuntimeFlowExecutor struct {
	err error

	called bool
	gotReq e2eflow.RuntimeFlowRequest
}

func (e *fakeRuntimeFlowExecutor) ExecuteRuntimeFlow(ctx context.Context, req e2eflow.RuntimeFlowRequest) (e2eflow.RuntimeFlowResult, error) {
	e.called = true
	e.gotReq = req

	if e.err != nil {
		return e2eflow.RuntimeFlowResult{}, e.err
	}

	return e2eflow.RuntimeFlowResult{
		OK: true,

		TenantID:  req.Tenant.TenantID,
		RequestID: req.Tenant.RequestID,

		TransactionKind: req.TransactionKind,
		Source:          req.Source,

		Status:    e2eflow.FlowStatusCompleted,
		StepCount: 6,

		CompletedAt: time.Date(2026, 4, 26, 9, 0, 0, 0, time.UTC),
		Message:     "runtime flow completed",
	}, nil
}

func validRuntimeFlowAPIRequest() RuntimeFlowAPIRequest {
	return RuntimeFlowAPIRequest{
		TenantID: "tenant_7",

		RequestID: "req-123",
		ActorID:   "user-1",
		ActorType: "user",

		TransactionKind: string(e2eflow.TransactionKindSalesInvoice),

		Source: RuntimeFlowAPISource{
			SourceModule:       "sales",
			SourceDocumentType: "invoice",
			SourceDocumentNo:   "INV-2026-000001",
		},

		Money: RuntimeFlowAPIMoney{
			TotalAmount:  120,
			CurrencyCode: "try",
			ExchangeRate: 1,
		},

		IdempotencyKey: "tenant_7:sales_invoice:INV-2026-000001",
		CorrelationID:  "corr-123",

		Description: "runtime api surface test",
		Metadata: map[string]string{
			"source": "faz3_12_1a_test",
		},
	}
}

func TestValidateRuntimeFlowAPIRequestSuccess(t *testing.T) {
	req := validRuntimeFlowAPIRequest()

	if err := ValidateRuntimeFlowAPIRequest(req); err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateRuntimeFlowAPIRequestTenantRequired(t *testing.T) {
	req := validRuntimeFlowAPIRequest()
	req.TenantID = ""

	err := ValidateRuntimeFlowAPIRequest(req)
	if !errors.Is(err, ErrTenantIDRequired) {
		t.Fatalf("expected ErrTenantIDRequired, got %v", err)
	}
}

func TestValidateRuntimeFlowAPIRequestTransactionKindInvalid(t *testing.T) {
	req := validRuntimeFlowAPIRequest()
	req.TransactionKind = "wrong"

	err := ValidateRuntimeFlowAPIRequest(req)
	if !errors.Is(err, ErrTransactionKindInvalid) {
		t.Fatalf("expected ErrTransactionKindInvalid, got %v", err)
	}
}

func TestValidateRuntimeFlowAPIRequestSourceRequired(t *testing.T) {
	req := validRuntimeFlowAPIRequest()
	req.Source.SourceDocumentNo = ""
	req.Source.SourceDocumentID = ""

	err := ValidateRuntimeFlowAPIRequest(req)
	if !errors.Is(err, ErrSourceDocumentRequired) {
		t.Fatalf("expected ErrSourceDocumentRequired, got %v", err)
	}
}

func TestValidateRuntimeFlowAPIRequestMoneyInvalid(t *testing.T) {
	req := validRuntimeFlowAPIRequest()
	req.Money.TotalAmount = 0

	err := ValidateRuntimeFlowAPIRequest(req)
	if !errors.Is(err, ErrTotalAmountInvalid) {
		t.Fatalf("expected ErrTotalAmountInvalid, got %v", err)
	}
}

func TestValidateRuntimeFlowAPIRequestIdempotencyRequired(t *testing.T) {
	req := validRuntimeFlowAPIRequest()
	req.IdempotencyKey = ""

	err := ValidateRuntimeFlowAPIRequest(req)
	if !errors.Is(err, ErrIdempotencyKeyRequired) {
		t.Fatalf("expected ErrIdempotencyKeyRequired, got %v", err)
	}
}

func TestToRuntimeFlowRequestMapsToE2EFlow(t *testing.T) {
	req := validRuntimeFlowAPIRequest()

	flowReq, err := ToRuntimeFlowRequest(req)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if flowReq.Tenant.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", flowReq.Tenant.TenantID)
	}

	if flowReq.TransactionKind != e2eflow.TransactionKindSalesInvoice {
		t.Fatalf("expected sales_invoice, got %s", flowReq.TransactionKind)
	}

	if flowReq.Money.CurrencyCode != "TRY" {
		t.Fatalf("expected TRY, got %s", flowReq.Money.CurrencyCode)
	}

	if flowReq.Source.SourceDocumentNo != "INV-2026-000001" {
		t.Fatalf("expected source no INV-2026-000001, got %s", flowReq.Source.SourceDocumentNo)
	}
}

func TestBuildRuntimeFlowAPIResponse(t *testing.T) {
	result := e2eflow.RuntimeFlowResult{
		OK: true,

		TenantID:  "tenant_7",
		RequestID: "req-123",

		TransactionKind: e2eflow.TransactionKindSalesInvoice,
		Source: e2eflow.SourceDocumentRef{
			SourceModule:       "sales",
			SourceDocumentType: "invoice",
			SourceDocumentNo:   "INV-2026-000001",
		},

		Status:    e2eflow.FlowStatusCompleted,
		StepCount: 6,

		CompletedAt: time.Date(2026, 4, 26, 9, 0, 0, 0, time.UTC),
		Message:     "completed",
	}

	resp := BuildRuntimeFlowAPIResponse(result)

	if !resp.OK {
		t.Fatal("expected OK response")
	}

	if resp.Status != "completed" {
		t.Fatalf("expected completed, got %s", resp.Status)
	}

	if resp.StepCount != 6 {
		t.Fatalf("expected step count 6, got %d", resp.StepCount)
	}
}

func TestDefaultRuntimeFlowAPIServiceSuccess(t *testing.T) {
	executor := &fakeRuntimeFlowExecutor{}
	service := NewDefaultRuntimeFlowAPIService(executor)

	resp, err := service.PostRuntimeFlow(context.Background(), validRuntimeFlowAPIRequest())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !executor.called {
		t.Fatal("expected executor to be called")
	}

	if executor.gotReq.Tenant.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", executor.gotReq.Tenant.TenantID)
	}

	if !resp.OK {
		t.Fatal("expected OK response")
	}

	if resp.Status != "completed" {
		t.Fatalf("expected completed, got %s", resp.Status)
	}
}

func TestDefaultRuntimeFlowAPIServiceExecutorRequired(t *testing.T) {
	service := NewDefaultRuntimeFlowAPIService(nil)

	_, err := service.PostRuntimeFlow(context.Background(), validRuntimeFlowAPIRequest())
	if !errors.Is(err, ErrRuntimeFlowExecutorRequired) {
		t.Fatalf("expected ErrRuntimeFlowExecutorRequired, got %v", err)
	}
}

func TestDefaultRuntimeFlowAPIServiceValidationFailure(t *testing.T) {
	executor := &fakeRuntimeFlowExecutor{}
	service := NewDefaultRuntimeFlowAPIService(executor)

	req := validRuntimeFlowAPIRequest()
	req.TenantID = ""

	_, err := service.PostRuntimeFlow(context.Background(), req)
	if !errors.Is(err, ErrTenantIDRequired) {
		t.Fatalf("expected ErrTenantIDRequired, got %v", err)
	}

	if executor.called {
		t.Fatal("executor should not be called on validation failure")
	}
}

func TestDefaultRuntimeFlowAPIServiceExecutorError(t *testing.T) {
	executor := &fakeRuntimeFlowExecutor{
		err: e2eflow.ErrFlowStatusInvalid,
	}
	service := NewDefaultRuntimeFlowAPIService(executor)

	_, err := service.PostRuntimeFlow(context.Background(), validRuntimeFlowAPIRequest())
	if !errors.Is(err, e2eflow.ErrFlowStatusInvalid) {
		t.Fatalf("expected ErrFlowStatusInvalid, got %v", err)
	}
}

func TestBuildRuntimeFlowAPIErrorResponse(t *testing.T) {
	req := validRuntimeFlowAPIRequest()

	resp := BuildRuntimeFlowAPIErrorResponse(req, "TENANT_REQUIRED", ErrTenantIDRequired)

	if resp.OK {
		t.Fatal("expected false OK")
	}

	if resp.ErrorCode != "TENANT_REQUIRED" {
		t.Fatalf("expected TENANT_REQUIRED, got %s", resp.ErrorCode)
	}

	if resp.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", resp.TenantID)
	}
}
