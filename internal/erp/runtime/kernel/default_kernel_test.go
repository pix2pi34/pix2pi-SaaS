package kernel

import (
	"context"
	"errors"
	"testing"
)

func TestDefaultRuntimeKernelValidateSuccess(t *testing.T) {
	kernel := NewDefaultRuntimeKernel()
	req := validRuntimeRequest()

	err := kernel.Validate(context.Background(), req)
	if err != nil {
		t.Fatalf("expected validate success, got %v", err)
	}
}

func TestDefaultRuntimeKernelValidateFailure(t *testing.T) {
	kernel := NewDefaultRuntimeKernel()
	req := validRuntimeRequest()
	req.Tenant.TenantID = ""

	err := kernel.Validate(context.Background(), req)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestDefaultRuntimeKernelExecuteSuccess(t *testing.T) {
	kernel := NewDefaultRuntimeKernel()
	req := validRuntimeRequest()

	result, err := kernel.Execute(context.Background(), req)
	if err != nil {
		t.Fatalf("expected execute success, got %v", err)
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}

	if result.TenantID != req.Tenant.TenantID {
		t.Fatalf("expected tenant_id %s, got %s", req.Tenant.TenantID, result.TenantID)
	}

	if result.RequestID != req.Tenant.RequestID {
		t.Fatalf("expected request_id %s, got %s", req.Tenant.RequestID, result.RequestID)
	}

	if result.Operation != req.Operation {
		t.Fatalf("expected operation %s, got %s", req.Operation, result.Operation)
	}

	if result.Document.DocumentNo != req.Document.DocumentNo {
		t.Fatalf("expected document_no %s, got %s", req.Document.DocumentNo, result.Document.DocumentNo)
	}

	if result.Message != "erp runtime kernel executed" {
		t.Fatalf("unexpected message: %s", result.Message)
	}

	if result.OccurredAt.IsZero() {
		t.Fatal("expected occurred_at")
	}
}

func TestDefaultRuntimeKernelExecuteValidationFailure(t *testing.T) {
	kernel := NewDefaultRuntimeKernel()
	req := validRuntimeRequest()
	req.Money.ExchangeRate = 0

	result, err := kernel.Execute(context.Background(), req)
	if !errors.Is(err, ErrAmountInvalid) {
		t.Fatalf("expected ErrAmountInvalid, got %v", err)
	}

	if result.OK {
		t.Fatal("expected non-ok zero result")
	}
}

func TestDefaultRuntimeKernelContextCancelled(t *testing.T) {
	kernel := NewDefaultRuntimeKernel()
	req := validRuntimeRequest()

	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	err := kernel.Validate(ctx, req)
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("expected context.Canceled, got %v", err)
	}
}
