package statussync

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		CallbackSignatureRequired: true,
		WebhookSignatureRequired:  true,
		PollEnabled:               true,
		ManualRecheckEnabled:      true,
		PollIntervalSeconds:       300,
		MaxPollBatchSize:          2,
		MaxRetryCount:             3,
		AllowedChannels: []PaymentChannel{
			PaymentChannelPOS,
			PaymentChannelVirtualPOS,
			PaymentChannelBankTransfer,
			PaymentChannelBankCollection,
			PaymentChannelMarketplaceSettlement,
		},
		AllowedProviderCodes: []string{
			"SIM_BANK_POS",
			"SIM_BANK",
			"SIM_MARKETPLACE",
		},
	}
}

func validRequest() PaymentStatusSyncRequest {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return PaymentStatusSyncRequest{
		TenantID:              "tenant-001",
		CorrelationID:         "corr-001",
		RequestID:             "req-001",
		IdempotencyKey:        "idem-001",
		Source:                SyncSourceCallback,
		PaymentTransactionID:  "pay-001",
		TransactionNo:         "PAY-001",
		Channel:               PaymentChannelPOS,
		ProviderCode:          "SIM_BANK_POS",
		ProviderTransactionID: "provider-pay-001",
		ProviderStatus:        ProviderStatusCaptured,
		ProviderStatusText:    "captured",
		ProviderPayloadHash:   "sha256:payload",
		AmountKurus:           100000,
		CurrencyCode:          "TRY",
		CallbackSignature:     "sha256:callback",
		WebhookSignature:      "sha256:webhook",
		ProviderEventTime:     now,
		ReceivedAt:            now.Add(time.Second),
	}
}

func TestHandleCallbackAcceptsCapturedStatus(t *testing.T) {
	runtime, err := NewPaymentStatusSyncRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.HandleCallback(validRequest(), CanonicalStatusAuthorized)
	if err != nil {
		t.Fatalf("callback failed: %v", err)
	}

	if result.DecisionStatus != DecisionAccepted {
		t.Fatalf("expected accepted, got %s", result.DecisionStatus)
	}
	if result.NewStatus != CanonicalStatusCaptured {
		t.Fatalf("expected captured, got %s", result.NewStatus)
	}
	if !result.PaymentCompleted {
		t.Fatal("expected payment completed")
	}
	if !result.StatusChanged {
		t.Fatal("expected status changed")
	}
}

func TestHandleCallbackRejectsMissingSignature(t *testing.T) {
	runtime, err := NewPaymentStatusSyncRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.CallbackSignature = ""

	result, err := runtime.HandleCallback(req, CanonicalStatusAuthorized)
	if err == nil {
		t.Fatal("expected callback signature error")
	}
	if result.DecisionStatus != DecisionRejected {
		t.Fatalf("expected rejected, got %s", result.DecisionStatus)
	}
	if result.ErrorCode != "CALLBACK_SIGNATURE_REQUIRED" {
		t.Fatalf("expected CALLBACK_SIGNATURE_REQUIRED, got %s", result.ErrorCode)
	}
}

func TestHandleWebhookAcceptsSoldAsPaid(t *testing.T) {
	runtime, err := NewPaymentStatusSyncRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.Source = SyncSourceWebhook
	req.ProviderStatus = ProviderStatusSold

	result, err := runtime.HandleWebhook(req, CanonicalStatusAuthorized)
	if err != nil {
		t.Fatalf("webhook failed: %v", err)
	}

	if result.NewStatus != CanonicalStatusPaid {
		t.Fatalf("expected PAID, got %s", result.NewStatus)
	}
	if !result.PaymentCompleted {
		t.Fatal("expected payment completed")
	}
}

func TestHandlePollResultSchedulesRetryOnFailed(t *testing.T) {
	runtime, err := NewPaymentStatusSyncRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.Source = SyncSourcePoll
	req.CallbackSignature = ""
	req.WebhookSignature = ""
	req.ProviderStatus = ProviderStatusFailed

	result, err := runtime.HandlePollResult(req, CanonicalStatusAuthorized)
	if err != nil {
		t.Fatalf("poll result failed: %v", err)
	}

	if result.NewStatus != CanonicalStatusFailed {
		t.Fatalf("expected failed, got %s", result.NewStatus)
	}
	if !result.Retryable {
		t.Fatal("expected retryable")
	}
	if !result.RetryScheduled {
		t.Fatal("expected retry scheduled")
	}
	if result.RetryAfter.IsZero() {
		t.Fatal("expected retry after")
	}
}

func TestHandleManualRecheckAcceptsBankReconciled(t *testing.T) {
	runtime, err := NewPaymentStatusSyncRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.Source = SyncSourceManualRecheck
	req.Channel = PaymentChannelBankCollection
	req.ProviderCode = "SIM_BANK"
	req.BankReferenceNo = "BANK-REF-001"
	req.StatementLineID = "STMT-001"
	req.ProviderStatus = ProviderStatusReconciled
	req.CallbackSignature = ""
	req.WebhookSignature = ""

	result, err := runtime.HandleManualRecheck(req, CanonicalStatusMatched)
	if err != nil {
		t.Fatalf("manual recheck failed: %v", err)
	}

	if result.NewStatus != CanonicalStatusReconciled {
		t.Fatalf("expected reconciled, got %s", result.NewStatus)
	}
	if !result.ReconciliationCompleted {
		t.Fatal("expected reconciliation completed")
	}
}

func TestBankCollectionRequiresBankReference(t *testing.T) {
	runtime, err := NewPaymentStatusSyncRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.Source = SyncSourcePoll
	req.Channel = PaymentChannelBankCollection
	req.ProviderCode = "SIM_BANK"
	req.BankReferenceNo = ""

	result, err := runtime.HandlePollResult(req, CanonicalStatusRegistered)
	if err == nil {
		t.Fatal("expected bank reference error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestBuildPollPlanHonorsBatchLimitAndEligibility(t *testing.T) {
	runtime, err := NewPaymentStatusSyncRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	candidates := []PaymentPollCandidate{
		{
			TenantID:              "tenant-001",
			PaymentTransactionID:  "pay-001",
			TransactionNo:         "PAY-001",
			Channel:               PaymentChannelPOS,
			ProviderCode:          "SIM_BANK_POS",
			ProviderTransactionID: "provider-001",
			LastKnownStatus:       CanonicalStatusAuthorized,
			RetryCount:            0,
			NextPollAt:            now.Add(-time.Minute),
		},
		{
			TenantID:              "tenant-001",
			PaymentTransactionID:  "pay-002",
			TransactionNo:         "PAY-002",
			Channel:               PaymentChannelBankCollection,
			ProviderCode:          "SIM_BANK",
			ProviderTransactionID: "provider-002",
			LastKnownStatus:       CanonicalStatusMatched,
			RetryCount:            1,
			NextPollAt:            now.Add(-time.Minute),
		},
		{
			TenantID:              "tenant-001",
			PaymentTransactionID:  "pay-003",
			TransactionNo:         "PAY-003",
			Channel:               PaymentChannelPOS,
			ProviderCode:          "SIM_BANK_POS",
			ProviderTransactionID: "provider-003",
			LastKnownStatus:       CanonicalStatusAuthorized,
			RetryCount:            1,
			NextPollAt:            now.Add(-time.Minute),
		},
	}

	plan := runtime.BuildPollPlan(candidates, now)

	if plan.DecisionStatus != DecisionScheduled {
		t.Fatalf("expected scheduled, got %s", plan.DecisionStatus)
	}
	if len(plan.Candidates) != 2 {
		t.Fatalf("expected 2 candidates due batch limit, got %d", len(plan.Candidates))
	}
	if plan.SkippedCount != 1 {
		t.Fatalf("expected 1 skipped, got %d", plan.SkippedCount)
	}
}

func TestBuildPollPlanRejectsDisabledPolling(t *testing.T) {
	cfg := validConfig()
	cfg.PollEnabled = false

	runtime, err := NewPaymentStatusSyncRuntime(cfg)
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	plan := runtime.BuildPollPlan([]PaymentPollCandidate{{TenantID: "tenant-001"}}, time.Now().UTC())

	if plan.DecisionStatus != DecisionIgnored {
		t.Fatalf("expected ignored, got %s", plan.DecisionStatus)
	}
	if plan.SkippedCount != 1 {
		t.Fatalf("expected skipped count 1, got %d", plan.SkippedCount)
	}
}
