package kernel

import (
	"errors"
	"testing"
	"time"
)

func validRuntimeRequest() RuntimeRequest {
	return RuntimeRequest{
		Tenant: TenantContext{
			TenantID:  "tenant_7",
			RequestID: "req-123",
			ActorID:   "user-1",
			ActorType: "user",
		},
		Operation: RuntimeOperationPost,
		Document: DocumentRef{
			Module:       "sales",
			DocumentType: "invoice",
			DocumentID:   "doc-1",
			DocumentNo:   "INV-000001",
		},
		Money: Money{
			Amount:       100,
			CurrencyCode: "TRY",
			ExchangeRate: 1,
			LocalAmount:  100,
		},
		Fiscal: FiscalContext{
			FiscalYear:   2026,
			FiscalPeriod: "2026-04",
			PostingDate:  time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC),
		},
		Metadata: map[string]string{
			"source": "faz3_10_1a_test",
		},
	}
}

func TestValidateRuntimeRequestSuccess(t *testing.T) {
	req := validRuntimeRequest()

	if err := ValidateRuntimeRequest(req); err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateRuntimeRequestTenantRequired(t *testing.T) {
	req := validRuntimeRequest()
	req.Tenant.TenantID = ""

	err := ValidateRuntimeRequest(req)

	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateRuntimeRequestRequestIDRequired(t *testing.T) {
	req := validRuntimeRequest()
	req.Tenant.RequestID = ""

	err := ValidateRuntimeRequest(req)

	if !errors.Is(err, ErrRequestIDRequired) {
		t.Fatalf("expected ErrRequestIDRequired, got %v", err)
	}
}

func TestValidateRuntimeRequestActorRequired(t *testing.T) {
	req := validRuntimeRequest()
	req.Tenant.ActorID = ""

	err := ValidateRuntimeRequest(req)

	if !errors.Is(err, ErrActorRequired) {
		t.Fatalf("expected ErrActorRequired, got %v", err)
	}
}

func TestValidateRuntimeRequestOperationRequired(t *testing.T) {
	req := validRuntimeRequest()
	req.Operation = ""

	err := ValidateRuntimeRequest(req)

	if !errors.Is(err, ErrOperationRequired) {
		t.Fatalf("expected ErrOperationRequired, got %v", err)
	}
}

func TestValidateRuntimeRequestDocumentInvalid(t *testing.T) {
	req := validRuntimeRequest()
	req.Document.DocumentID = ""
	req.Document.DocumentNo = ""

	err := ValidateRuntimeRequest(req)

	if !errors.Is(err, ErrDocumentRefInvalid) {
		t.Fatalf("expected ErrDocumentRefInvalid, got %v", err)
	}
}

func TestValidateRuntimeRequestAmountInvalid(t *testing.T) {
	req := validRuntimeRequest()
	req.Money.Amount = -1

	err := ValidateRuntimeRequest(req)

	if !errors.Is(err, ErrAmountInvalid) {
		t.Fatalf("expected ErrAmountInvalid, got %v", err)
	}
}

func TestValidateRuntimeRequestCurrencyRequired(t *testing.T) {
	req := validRuntimeRequest()
	req.Money.CurrencyCode = ""

	err := ValidateRuntimeRequest(req)

	if !errors.Is(err, ErrCurrencyRequired) {
		t.Fatalf("expected ErrCurrencyRequired, got %v", err)
	}
}

func TestValidateRuntimeRequestFiscalYearInvalid(t *testing.T) {
	req := validRuntimeRequest()
	req.Fiscal.FiscalYear = 1999

	err := ValidateRuntimeRequest(req)

	if !errors.Is(err, ErrFiscalYearInvalid) {
		t.Fatalf("expected ErrFiscalYearInvalid, got %v", err)
	}
}

func TestNewSuccessResult(t *testing.T) {
	req := validRuntimeRequest()

	result := NewSuccessResult(req, "runtime ok")

	if !result.OK {
		t.Fatal("expected result OK")
	}

	if result.TenantID != req.Tenant.TenantID {
		t.Fatalf("expected tenant %s, got %s", req.Tenant.TenantID, result.TenantID)
	}

	if result.RequestID != req.Tenant.RequestID {
		t.Fatalf("expected request_id %s, got %s", req.Tenant.RequestID, result.RequestID)
	}

	if result.Message != "runtime ok" {
		t.Fatalf("expected message runtime ok, got %s", result.Message)
	}

	if result.OccurredAt.IsZero() {
		t.Fatal("expected occurred_at")
	}
}
