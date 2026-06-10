package e2eflow

import (
	"errors"
	"testing"
	"time"
)

func validRuntimeFlowRequest() RuntimeFlowRequest {
	return RuntimeFlowRequest{
		Tenant: TenantContext{
			TenantID:  "tenant_7",
			RequestID: "req-123",
			ActorID:   "user-1",
			ActorType: "user",
		},
		TransactionKind: TransactionKindSalesInvoice,
		Source: SourceDocumentRef{
			SourceModule:       "sales",
			SourceDocumentType: "invoice",
			SourceDocumentID:   "invoice-1",
			SourceDocumentNo:   "INV-2026-000001",
		},
		Money: MoneySummary{
			TotalAmount:  120,
			CurrencyCode: "try",
			ExchangeRate: 1,
		},
		IdempotencyKey: "tenant_7:sales_invoice:INV-2026-000001",
		CorrelationID:  "corr-123",
		Description:    "runtime e2e flow test",
		Metadata: map[string]string{
			"source": "faz3_11_1a_test",
		},
	}
}

func TestValidateRuntimeFlowRequestSuccess(t *testing.T) {
	req := validRuntimeFlowRequest()

	if err := ValidateRuntimeFlowRequest(req); err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateRuntimeFlowRequestTenantRequired(t *testing.T) {
	req := validRuntimeFlowRequest()
	req.Tenant.TenantID = ""

	err := ValidateRuntimeFlowRequest(req)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateRuntimeFlowRequestKindInvalid(t *testing.T) {
	req := validRuntimeFlowRequest()
	req.TransactionKind = TransactionKind("wrong")

	err := ValidateRuntimeFlowRequest(req)
	if !errors.Is(err, ErrTransactionKindInvalid) {
		t.Fatalf("expected ErrTransactionKindInvalid, got %v", err)
	}
}

func TestValidateRuntimeFlowRequestSourceRequired(t *testing.T) {
	req := validRuntimeFlowRequest()
	req.Source.SourceDocumentID = ""
	req.Source.SourceDocumentNo = ""

	err := ValidateRuntimeFlowRequest(req)
	if !errors.Is(err, ErrSourceDocumentRequired) {
		t.Fatalf("expected ErrSourceDocumentRequired, got %v", err)
	}
}

func TestValidateRuntimeFlowRequestMoneyInvalid(t *testing.T) {
	req := validRuntimeFlowRequest()
	req.Money.TotalAmount = 0

	err := ValidateRuntimeFlowRequest(req)
	if !errors.Is(err, ErrTotalAmountInvalid) {
		t.Fatalf("expected ErrTotalAmountInvalid, got %v", err)
	}
}

func TestValidateRuntimeFlowRequestIdempotencyRequired(t *testing.T) {
	req := validRuntimeFlowRequest()
	req.IdempotencyKey = ""

	err := ValidateRuntimeFlowRequest(req)
	if !errors.Is(err, ErrIdempotencyKeyRequired) {
		t.Fatalf("expected ErrIdempotencyKeyRequired, got %v", err)
	}
}

func TestBuildRuntimeFlowPlanSalesInvoice(t *testing.T) {
	req := validRuntimeFlowRequest()

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if plan.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", plan.TenantID)
	}

	if plan.Status != FlowStatusDraft {
		t.Fatalf("expected draft status, got %s", plan.Status)
	}

	if plan.Money.CurrencyCode != "TRY" {
		t.Fatalf("expected TRY, got %s", plan.Money.CurrencyCode)
	}

	if len(plan.Steps) != 6 {
		t.Fatalf("expected 6 steps, got %d", len(plan.Steps))
	}

	if plan.Steps[0].Kind != FlowStepValidateRequest {
		t.Fatalf("expected first step validate_request, got %s", plan.Steps[0].Kind)
	}

	if plan.Steps[2].Kind != FlowStepCalculateTax {
		t.Fatalf("expected third step calculate_tax, got %s", plan.Steps[2].Kind)
	}

	if err := ValidateRuntimeFlowPlan(plan); err != nil {
		t.Fatalf("expected valid plan, got %v", err)
	}
}

func TestBuildRuntimeFlowPlanCashReceipt(t *testing.T) {
	req := validRuntimeFlowRequest()
	req.TransactionKind = TransactionKindCashReceipt
	req.Source.SourceModule = "cashbank"
	req.Source.SourceDocumentType = "payment"
	req.Source.SourceDocumentNo = "PAY-2026-000001"
	req.IdempotencyKey = "tenant_7:cash_receipt:PAY-2026-000001"

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if len(plan.Steps) != 5 {
		t.Fatalf("expected 5 steps, got %d", len(plan.Steps))
	}

	if plan.Steps[1].Kind != FlowStepCashBankPayment {
		t.Fatalf("expected second step cashbank_payment, got %s", plan.Steps[1].Kind)
	}

	for _, step := range plan.Steps {
		if step.Kind == FlowStepCalculateTax {
			t.Fatal("cash receipt flow should not include calculate_tax step")
		}
	}
}

func TestCompleteRuntimeFlowPlanSuccess(t *testing.T) {
	req := validRuntimeFlowRequest()

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("expected build success, got %v", err)
	}

	completedAt := time.Date(2026, 4, 26, 8, 0, 0, 0, time.UTC)

	completedPlan, err := CompleteRuntimeFlowPlan(plan, completedAt)
	if err != nil {
		t.Fatalf("expected complete success, got %v", err)
	}

	if completedPlan.Status != FlowStatusCompleted {
		t.Fatalf("expected completed status, got %s", completedPlan.Status)
	}

	for _, step := range completedPlan.Steps {
		if step.Status != FlowStepStatusCompleted {
			t.Fatalf("expected completed step, got %s", step.Status)
		}

		if !step.CompletedAt.Equal(completedAt) {
			t.Fatalf("expected completed_at %v, got %v", completedAt, step.CompletedAt)
		}
	}
}

func TestBuildRuntimeFlowResultSuccess(t *testing.T) {
	req := validRuntimeFlowRequest()

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("expected build success, got %v", err)
	}

	completedAt := time.Date(2026, 4, 26, 8, 0, 0, 0, time.UTC)

	completedPlan, err := CompleteRuntimeFlowPlan(plan, completedAt)
	if err != nil {
		t.Fatalf("expected complete success, got %v", err)
	}

	result, err := BuildRuntimeFlowResult(req, completedPlan, "runtime flow completed")
	if err != nil {
		t.Fatalf("expected result success, got %v", err)
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}

	if result.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", result.TenantID)
	}

	if result.Status != FlowStatusCompleted {
		t.Fatalf("expected completed status, got %s", result.Status)
	}

	if result.StepCount != 6 {
		t.Fatalf("expected step count 6, got %d", result.StepCount)
	}

	if !result.CompletedAt.Equal(completedAt) {
		t.Fatalf("expected completed_at %v, got %v", completedAt, result.CompletedAt)
	}
}

func TestBuildRuntimeFlowResultStatusInvalid(t *testing.T) {
	req := validRuntimeFlowRequest()

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("expected build success, got %v", err)
	}

	_, err = BuildRuntimeFlowResult(req, plan, "runtime flow completed")
	if !errors.Is(err, ErrFlowStatusInvalid) {
		t.Fatalf("expected ErrFlowStatusInvalid, got %v", err)
	}
}
