package statussync

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		CallbackSignatureRequired: true,
		PollEnabled:               true,
		PollIntervalSeconds:       300,
		MaxPollBatchSize:          2,
		MaxRetryCount:             3,
		AllowedDocumentTypes: []DocumentType{
			DocumentTypeEFatura,
			DocumentTypeEArsiv,
			DocumentTypeEAdisyon,
		},
		AllowedProviderCodes: []string{
			"SIM_GIB_EFATURA",
			"SIM_GIB_EARSIV",
			"SIM_GIB_EADISYON",
		},
	}
}

func validCallbackRequest() StatusSyncRequest {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
	return StatusSyncRequest{
		TenantID:            "tenant-001",
		CorrelationID:       "corr-001",
		RequestID:           "req-001",
		IdempotencyKey:      "idem-001",
		Source:              SyncSourceCallback,
		DocumentID:          "doc-001",
		DocumentNo:          "EF2026000000001",
		DocumentType:        DocumentTypeEFatura,
		ProviderCode:        "SIM_GIB_EFATURA",
		ProviderDocumentID:  "provider-doc-001",
		ProviderEnvelopeID:  "env-001",
		ProviderStatus:      ProviderStatusDelivered,
		ProviderMessage:     "delivered",
		ProviderPayloadHash: "sha256:payload",
		CallbackSignature:   "sha256:signature",
		ProviderEventTime:   now,
		ReceivedAt:          now.Add(time.Second),
	}
}

func TestHandleCallbackAcceptsStatusChange(t *testing.T) {
	runtime, err := NewStatusSyncRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.HandleCallback(validCallbackRequest(), CanonicalStatusSent)
	if err != nil {
		t.Fatalf("callback failed: %v", err)
	}

	if result.DecisionStatus != DecisionAccepted {
		t.Fatalf("expected accepted, got %s", result.DecisionStatus)
	}
	if result.NewStatus != CanonicalStatusDelivered {
		t.Fatalf("expected delivered, got %s", result.NewStatus)
	}
	if !result.StatusChanged {
		t.Fatal("expected status changed")
	}
}

func TestHandleCallbackRejectsMissingSignature(t *testing.T) {
	runtime, err := NewStatusSyncRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validCallbackRequest()
	req.CallbackSignature = ""

	result, err := runtime.HandleCallback(req, CanonicalStatusSent)
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

func TestHandlePollResultSchedulesRetryOnFailed(t *testing.T) {
	runtime, err := NewStatusSyncRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validCallbackRequest()
	req.Source = SyncSourcePoll
	req.CallbackSignature = ""
	req.ProviderStatus = ProviderStatusFailed

	result, err := runtime.HandlePollResult(req, CanonicalStatusSent)
	if err != nil {
		t.Fatalf("poll result failed: %v", err)
	}

	if result.NewStatus != CanonicalStatusFailed {
		t.Fatalf("expected failed, got %s", result.NewStatus)
	}
	if !result.Retryable {
		t.Fatal("expected retryable result")
	}
	if !result.RetryScheduled {
		t.Fatal("expected retry scheduled")
	}
	if result.RetryAfter.IsZero() {
		t.Fatal("expected retry after")
	}
}

func TestBuildPollPlanHonorsBatchAndEligibility(t *testing.T) {
	runtime, err := NewStatusSyncRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
	candidates := []PollCandidate{
		{
			TenantID:           "tenant-001",
			DocumentID:         "doc-001",
			DocumentNo:         "EF1",
			DocumentType:       DocumentTypeEFatura,
			ProviderCode:       "SIM_GIB_EFATURA",
			ProviderDocumentID: "pd-1",
			LastKnownStatus:    CanonicalStatusSent,
			RetryCount:         0,
			NextPollAt:         now.Add(-time.Minute),
		},
		{
			TenantID:           "tenant-001",
			DocumentID:         "doc-002",
			DocumentNo:         "EA1",
			DocumentType:       DocumentTypeEArsiv,
			ProviderCode:       "SIM_GIB_EARSIV",
			ProviderDocumentID: "pd-2",
			LastKnownStatus:    CanonicalStatusProviderQueued,
			RetryCount:         1,
			NextPollAt:         now.Add(-time.Minute),
		},
		{
			TenantID:           "tenant-001",
			DocumentID:         "doc-003",
			DocumentNo:         "AD1",
			DocumentType:       DocumentTypeEAdisyon,
			ProviderCode:       "SIM_GIB_EADISYON",
			ProviderDocumentID: "pd-3",
			LastKnownStatus:    CanonicalStatusProviderQueued,
			RetryCount:         1,
			NextPollAt:         now.Add(-time.Minute),
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

	runtime, err := NewStatusSyncRuntime(cfg)
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	plan := runtime.BuildPollPlan([]PollCandidate{{TenantID: "tenant-001"}}, time.Now().UTC())

	if plan.DecisionStatus != DecisionIgnored {
		t.Fatalf("expected ignored, got %s", plan.DecisionStatus)
	}
	if plan.SkippedCount != 1 {
		t.Fatalf("expected skipped count 1, got %d", plan.SkippedCount)
	}
}
