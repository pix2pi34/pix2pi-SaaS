package refundcancel

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		Mode:                           RuntimeModeSimulation,
		RealPaymentGateOpen:            false,
		ProductionApproved:             false,
		DefaultCurrencyCode:            "TRY",
		IdempotencyRequired:            true,
		ProviderPayloadHashRequired:    true,
		ReasonRequired:                 true,
		PartialRefundAllowed:           true,
		FullRefundAllowed:              true,
		VoidAllowedBeforeSettlement:    true,
		CancelAllowedBeforeCapture:     true,
		ReversalAllowedAfterSettlement: true,
		AllowedChannels: []PaymentChannel{
			ChannelPOS,
			ChannelVirtualPOS,
			ChannelBankTransfer,
			ChannelBankCollection,
			ChannelMarketplaceSettlement,
		},
		AllowedProviderCodes: []string{
			"SIM_BANK_POS",
			"SIM_BANK",
			"SIM_MARKETPLACE",
		},
	}
}

func validRequest() RefundCancelRequest {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return RefundCancelRequest{
		TenantID:                   "tenant-001",
		CorrelationID:              "corr-001",
		RequestID:                  "req-001",
		IdempotencyKey:             "idem-001",
		PaymentTransactionID:       "pay-001",
		TransactionNo:              "PAY-001",
		Channel:                    ChannelPOS,
		ProviderCode:               "SIM_BANK_POS",
		ProviderTransactionID:      "provider-pay-001",
		ProviderPayloadHash:        "sha256:provider",
		SourceDocumentType:         "SALES_INVOICE",
		SourceDocumentID:           "inv-001",
		SourceDocumentNo:           "INV-001",
		OriginalAmountKurus:        100000,
		RequestedAmountKurus:       25000,
		AlreadyRefundedAmountKurus: 0,
		CurrencyCode:               "TRY",
		Settled:                    false,
		Captured:                   true,
		Authorized:                 true,
		ReasonCode:                 "CUSTOMER_RETURN",
		ReasonText:                 "Musteri iadesi",
		RequestedBy:                "user-001",
		RequestedAt:                now,
	}
}

func TestRuntimeRejectsProductionWithoutApproval(t *testing.T) {
	cfg := validConfig()
	cfg.Mode = RuntimeModeProduction
	cfg.RealPaymentGateOpen = false
	cfg.ProductionApproved = false

	if _, err := NewRefundCancelRuntime(cfg); err == nil {
		t.Fatal("expected production real payment gate to be closed")
	}
}

func TestPrepareAndRegisterRefundAccepted(t *testing.T) {
	runtime, err := NewRefundCancelRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	queued, err := runtime.PrepareRefund(validRequest())
	if err != nil {
		t.Fatalf("prepare refund failed: %v", err)
	}
	if queued.DecisionStatus != DecisionQueued {
		t.Fatalf("expected queued, got %s", queued.DecisionStatus)
	}
	if queued.LifecycleStatus != LifecycleRefundQueued {
		t.Fatalf("expected refund queued, got %s", queued.LifecycleStatus)
	}

	accepted, err := runtime.RegisterRefundAccepted(validRequest())
	if err != nil {
		t.Fatalf("register refund accepted failed: %v", err)
	}
	if accepted.DecisionStatus != DecisionAccepted {
		t.Fatalf("expected accepted, got %s", accepted.DecisionStatus)
	}
	if accepted.LifecycleStatus != LifecycleRefundAccepted {
		t.Fatalf("expected refund accepted, got %s", accepted.LifecycleStatus)
	}
}

func TestRefundRejectsAmountExceedingRemaining(t *testing.T) {
	runtime, err := NewRefundCancelRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.AlreadyRefundedAmountKurus = 90000
	req.RequestedAmountKurus = 25000

	result, err := runtime.PrepareRefund(req)
	if err == nil {
		t.Fatal("expected remaining refundable error")
	}
	if result.ErrorCode != "REFUND_VALIDATION_FAILED" {
		t.Fatalf("expected REFUND_VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestRefundRequiresCapturedPayment(t *testing.T) {
	runtime, err := NewRefundCancelRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.Captured = false

	result, err := runtime.PrepareRefund(req)
	if err == nil {
		t.Fatal("expected captured payment error")
	}
	if result.DecisionStatus != DecisionRejected {
		t.Fatalf("expected rejected, got %s", result.DecisionStatus)
	}
}

func TestPrepareAndRegisterCancelAccepted(t *testing.T) {
	runtime, err := NewRefundCancelRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.Captured = false
	req.Authorized = true
	req.Settled = false

	queued, err := runtime.PrepareCancel(req)
	if err != nil {
		t.Fatalf("prepare cancel failed: %v", err)
	}
	if queued.LifecycleStatus != LifecycleCancelQueued {
		t.Fatalf("expected cancel queued, got %s", queued.LifecycleStatus)
	}

	accepted, err := runtime.RegisterCancelAccepted(req)
	if err != nil {
		t.Fatalf("register cancel accepted failed: %v", err)
	}
	if accepted.LifecycleStatus != LifecycleCancelAccepted {
		t.Fatalf("expected cancel accepted, got %s", accepted.LifecycleStatus)
	}
}

func TestCancelRejectsCapturedPayment(t *testing.T) {
	runtime, err := NewRefundCancelRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.Captured = true
	req.Authorized = true

	result, err := runtime.PrepareCancel(req)
	if err == nil {
		t.Fatal("expected cancel after capture error")
	}
	if result.ErrorCode != "CANCEL_VALIDATION_FAILED" {
		t.Fatalf("expected CANCEL_VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestPrepareAndRegisterVoidAccepted(t *testing.T) {
	runtime, err := NewRefundCancelRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.Captured = true
	req.Settled = false

	queued, err := runtime.PrepareVoid(req)
	if err != nil {
		t.Fatalf("prepare void failed: %v", err)
	}
	if queued.LifecycleStatus != LifecycleVoidQueued {
		t.Fatalf("expected void queued, got %s", queued.LifecycleStatus)
	}

	accepted, err := runtime.RegisterVoidAccepted(req)
	if err != nil {
		t.Fatalf("register void accepted failed: %v", err)
	}
	if accepted.LifecycleStatus != LifecycleVoidAccepted {
		t.Fatalf("expected void accepted, got %s", accepted.LifecycleStatus)
	}
}

func TestVoidRejectsSettledPayment(t *testing.T) {
	runtime, err := NewRefundCancelRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.Captured = true
	req.Settled = true

	result, err := runtime.PrepareVoid(req)
	if err == nil {
		t.Fatal("expected void after settlement error")
	}
	if result.ErrorCode != "VOID_VALIDATION_FAILED" {
		t.Fatalf("expected VOID_VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestPrepareAndRegisterReversalAccepted(t *testing.T) {
	runtime, err := NewRefundCancelRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.Settled = true
	req.Captured = true

	queued, err := runtime.PrepareReversal(req)
	if err != nil {
		t.Fatalf("prepare reversal failed: %v", err)
	}
	if queued.LifecycleStatus != LifecycleReversalQueued {
		t.Fatalf("expected reversal queued, got %s", queued.LifecycleStatus)
	}

	accepted, err := runtime.RegisterReversalAccepted(req)
	if err != nil {
		t.Fatalf("register reversal accepted failed: %v", err)
	}
	if accepted.LifecycleStatus != LifecycleReversalAccepted {
		t.Fatalf("expected reversal accepted, got %s", accepted.LifecycleStatus)
	}
}

func TestReasonCodeRequired(t *testing.T) {
	runtime, err := NewRefundCancelRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.ReasonCode = ""

	result, err := runtime.PrepareRefund(req)
	if err == nil {
		t.Fatal("expected reason code error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestCheckStatus(t *testing.T) {
	runtime, err := NewRefundCancelRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.CheckStatus(validRequest())
	if err != nil {
		t.Fatalf("check status failed: %v", err)
	}
	if result.LifecycleStatus != LifecycleStatusChecked {
		t.Fatalf("expected status checked, got %s", result.LifecycleStatus)
	}
}
