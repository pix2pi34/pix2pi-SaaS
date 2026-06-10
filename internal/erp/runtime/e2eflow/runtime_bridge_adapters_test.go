package e2eflow

import (
	"context"
	"errors"
	"testing"
)

func TestRuntimeBridgeDocumentAdapterSuccess(t *testing.T) {
	called := false

	adapter := NewRuntimeBridgeDocumentAdapter(func(ctx context.Context, plan RuntimeFlowPlan) error {
		called = true

		if plan.TenantID != "tenant_7" {
			t.Fatalf("expected tenant_7, got %s", plan.TenantID)
		}

		return nil
	})

	plan, err := BuildRuntimeFlowPlan(validRuntimeFlowRequest())
	if err != nil {
		t.Fatalf("build plan: %v", err)
	}

	if err := adapter.PersistDocument(context.Background(), plan); err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !called {
		t.Fatal("expected bridge handler to be called")
	}
}

func TestRuntimeBridgeDocumentAdapterHandlerRequired(t *testing.T) {
	adapter := NewRuntimeBridgeDocumentAdapter(nil)

	plan, err := BuildRuntimeFlowPlan(validRuntimeFlowRequest())
	if err != nil {
		t.Fatalf("build plan: %v", err)
	}

	err = adapter.PersistDocument(context.Background(), plan)
	if !errors.Is(err, ErrRuntimeBridgeHandlerRequired) {
		t.Fatalf("expected ErrRuntimeBridgeHandlerRequired, got %v", err)
	}
}

func TestRuntimeBridgeStepAdapterRegistrySalesInvoiceFlow(t *testing.T) {
	req := validRuntimeFlowRequest()
	req.TransactionKind = TransactionKindSalesInvoice

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("build plan: %v", err)
	}

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
		t.Fatalf("create registry: %v", err)
	}

	runner := NewAdapterRuntimeFlowStepRunner(registry, nil, true)

	for _, step := range plan.Steps {
		completedStep, err := runner.RunStep(context.Background(), plan, step)
		if err != nil {
			t.Fatalf("run step %s: %v", step.Kind, err)
		}

		if completedStep.Status != FlowStepStatusCompleted {
			t.Fatalf("expected completed step, got %s", completedStep.Status)
		}
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
}

func TestRuntimeBridgeStepAdapterRegistryCashReceiptFlow(t *testing.T) {
	req := validRuntimeFlowRequest()
	req.TransactionKind = TransactionKindCashReceipt
	req.Source.SourceModule = "cashbank"
	req.Source.SourceDocumentType = "payment"
	req.Source.SourceDocumentNo = "PAY-2026-000001"
	req.IdempotencyKey = "tenant_7:cash_receipt:PAY-2026-000001"

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("build plan: %v", err)
	}

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
		t.Fatalf("create registry: %v", err)
	}

	runner := NewAdapterRuntimeFlowStepRunner(registry, nil, true)

	for _, step := range plan.Steps {
		completedStep, err := runner.RunStep(context.Background(), plan, step)
		if err != nil {
			t.Fatalf("run step %s: %v", step.Kind, err)
		}

		if completedStep.Status != FlowStepStatusCompleted {
			t.Fatalf("expected completed step, got %s", completedStep.Status)
		}
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
}

func TestRuntimeBridgeStepAdapterPropagatesHandlerError(t *testing.T) {
	req := validRuntimeFlowRequest()
	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("build plan: %v", err)
	}

	registry, err := NewRuntimeBridgeStepAdapterRegistry(RuntimeBridgeHandlers{
		PersistDocument: func(ctx context.Context, plan RuntimeFlowPlan) error {
			return nil
		},
		CalculateTax: func(ctx context.Context, plan RuntimeFlowPlan) error {
			return ErrFlowStepKindInvalid
		},
		PostJournal: func(ctx context.Context, plan RuntimeFlowPlan) error {
			return nil
		},
		PostLedger: func(ctx context.Context, plan RuntimeFlowPlan) error {
			return nil
		},
		PublishRuntimeEvent: func(ctx context.Context, plan RuntimeFlowPlan) error {
			return nil
		},
	})
	if err != nil {
		t.Fatalf("create registry: %v", err)
	}

	runner := NewAdapterRuntimeFlowStepRunner(registry, nil, true)

	step := RuntimeFlowStep{
		StepNo: 3,
		Kind:   FlowStepCalculateTax,
		Status: FlowStepStatusPending,
	}

	failedStep, err := runner.RunStep(context.Background(), plan, step)
	if !errors.Is(err, ErrFlowStepKindInvalid) {
		t.Fatalf("expected ErrFlowStepKindInvalid, got %v", err)
	}

	if failedStep.Status != FlowStepStatusFailed {
		t.Fatalf("expected failed step, got %s", failedStep.Status)
	}
}
