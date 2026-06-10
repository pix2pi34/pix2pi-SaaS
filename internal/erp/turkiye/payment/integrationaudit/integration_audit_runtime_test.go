package integrationaudit

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:               true,
		Mode:                         RuntimeModeSimulation,
		RealProviderGateOpen:         false,
		ProductionApproved:           false,
		IdempotencyRequired:          true,
		EvidenceHashRequired:         true,
		ArtifactPathRequired:         true,
		FailBlocksClosure:            true,
		WarnRequiresReview:           true,
		MinimumPassCountForReadiness: 20,
		RequiredScopes: []AuditScope{
			ScopePOSProviderRuntime,
			ScopeBankCollectionRuntime,
			ScopeReconciliationRuntime,
			ScopeRefundCancelRuntime,
			ScopePaymentStatusSync,
			ScopePaymentErrorRetryRuntime,
			ScopePaymentIntegrationE2E,
		},
		AllowedProviderCodes: []string{
			"SIM_BANK_POS",
			"SIM_BANK",
			"SIM_MARKETPLACE",
			"INTERNAL_AUDIT",
		},
	}
}

func validEvent(scope AuditScope, passCount int) IntegrationAuditEvent {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return IntegrationAuditEvent{
		TenantID:             "tenant-001",
		CorrelationID:        "corr-001",
		RequestID:            "req-001",
		IdempotencyKey:       "idem-" + string(scope),
		AuditEventID:         "audit-" + string(scope),
		Scope:                scope,
		Source:               SourceRealAudit,
		Status:               EventStatusPass,
		ProviderCode:         "INTERNAL_AUDIT",
		PaymentTransactionID: "pay-001",
		TransactionNo:        "PAY-001",
		CheckName:            "real implementation audit",
		ArtifactPath:         "internal/erp/turkiye/payment/" + string(scope),
		EvidenceFilePath:     "docs/faz3/evidence/" + string(scope) + ".md",
		EvidenceHash:         "sha256:" + string(scope),
		PassCount:            passCount,
		FailCount:            0,
		WarnCount:            0,
		OccurredAt:           now,
	}
}

func validBundle() EvidenceBundle {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return EvidenceBundle{
		TenantID:      "tenant-001",
		CorrelationID: "corr-001",
		RequestID:     "req-001",
		BundleID:      "bundle-payment-runtime-001",
		Events: []IntegrationAuditEvent{
			validEvent(ScopePOSProviderRuntime, 32),
			validEvent(ScopeBankCollectionRuntime, 32),
			validEvent(ScopeReconciliationRuntime, 42),
			validEvent(ScopeRefundCancelRuntime, 49),
			validEvent(ScopePaymentStatusSync, 38),
			validEvent(ScopePaymentErrorRetryRuntime, 39),
			validEvent(ScopePaymentIntegrationE2E, 25),
		},
		PreparedAt: now,
	}
}

func TestRuntimeRejectsProductionWithoutApproval(t *testing.T) {
	cfg := validConfig()
	cfg.Mode = RuntimeModeProduction
	cfg.RealProviderGateOpen = false
	cfg.ProductionApproved = false

	if _, err := NewIntegrationAuditRuntime(cfg); err == nil {
		t.Fatal("expected production real provider gate to be closed")
	}
}

func TestRegisterAuditEventAcceptsPass(t *testing.T) {
	runtime, err := NewIntegrationAuditRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.RegisterAuditEvent(validEvent(ScopePOSProviderRuntime, 32))
	if err != nil {
		t.Fatalf("register audit event failed: %v", err)
	}

	if result.DecisionStatus != DecisionAccepted {
		t.Fatalf("expected accepted, got %s", result.DecisionStatus)
	}
	if !result.Accepted {
		t.Fatal("expected accepted true")
	}
	if result.BlocksClosure {
		t.Fatal("expected not blocking closure")
	}
}

func TestRegisterAuditEventRejectsPassWithFailCount(t *testing.T) {
	runtime, err := NewIntegrationAuditRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	event := validEvent(ScopePOSProviderRuntime, 32)
	event.FailCount = 1

	result, err := runtime.RegisterAuditEvent(event)
	if err == nil {
		t.Fatal("expected PASS with fail_count error")
	}
	if result.DecisionStatus != DecisionRejected {
		t.Fatalf("expected rejected, got %s", result.DecisionStatus)
	}
	if !result.BlocksClosure {
		t.Fatal("expected closure block")
	}
}

func TestRegisterAuditEventHandlesWarnReview(t *testing.T) {
	runtime, err := NewIntegrationAuditRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	event := validEvent(ScopeBankCollectionRuntime, 32)
	event.Status = EventStatusWarn
	event.WarnCount = 1

	result, err := runtime.RegisterAuditEvent(event)
	if err != nil {
		t.Fatalf("register warn audit event failed: %v", err)
	}

	if result.DecisionStatus != DecisionReviewNeeded {
		t.Fatalf("expected review needed, got %s", result.DecisionStatus)
	}
	if !result.ReviewRequired {
		t.Fatal("expected review required")
	}
}

func TestRegisterAuditEventHandlesFailBlock(t *testing.T) {
	runtime, err := NewIntegrationAuditRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	event := validEvent(ScopeBankCollectionRuntime, 0)
	event.Status = EventStatusFail
	event.FailCount = 1

	result, err := runtime.RegisterAuditEvent(event)
	if err != nil {
		t.Fatalf("register fail audit event should return result without validation error: %v", err)
	}

	if result.DecisionStatus != DecisionRejected {
		t.Fatalf("expected rejected, got %s", result.DecisionStatus)
	}
	if !result.BlocksClosure {
		t.Fatal("expected closure block")
	}
}

func TestEvaluateEvidenceBundleReady(t *testing.T) {
	runtime, err := NewIntegrationAuditRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.EvaluateEvidenceBundle(validBundle())
	if err != nil {
		t.Fatalf("evaluate bundle failed: %v", err)
	}

	if result.DecisionStatus != DecisionReady {
		t.Fatalf("expected ready, got %s", result.DecisionStatus)
	}
	if !result.ReadyForClosure {
		t.Fatal("expected ready for closure")
	}
	if result.TotalFailCount != 0 {
		t.Fatalf("expected zero fail count, got %d", result.TotalFailCount)
	}
	if len(result.MissingScopes) != 0 {
		t.Fatalf("expected no missing scopes, got %d", len(result.MissingScopes))
	}
}

func TestEvaluateEvidenceBundleDetectsMissingScope(t *testing.T) {
	runtime, err := NewIntegrationAuditRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	bundle := validBundle()
	bundle.Events = bundle.Events[:len(bundle.Events)-1]

	result, err := runtime.EvaluateEvidenceBundle(bundle)
	if err == nil {
		t.Fatal("expected missing scope error")
	}
	if result.ErrorCode != "REQUIRED_AUDIT_SCOPE_MISSING" {
		t.Fatalf("expected REQUIRED_AUDIT_SCOPE_MISSING, got %s", result.ErrorCode)
	}
	if !result.ReviewRequired {
		t.Fatal("expected review required")
	}
}

func TestEvaluateEvidenceBundleDetectsFailEvent(t *testing.T) {
	runtime, err := NewIntegrationAuditRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	bundle := validBundle()
	bundle.Events[0].Status = EventStatusFail
	bundle.Events[0].PassCount = 0
	bundle.Events[0].FailCount = 1

	result, err := runtime.EvaluateEvidenceBundle(bundle)
	if err == nil {
		t.Fatal("expected fail event error")
	}
	if result.DecisionStatus != DecisionRejected {
		t.Fatalf("expected rejected, got %s", result.DecisionStatus)
	}
	if !result.ReviewRequired {
		t.Fatal("expected review required")
	}
}

func TestEvaluateEvidenceBundleRejectsLowPassCount(t *testing.T) {
	cfg := validConfig()
	cfg.MinimumPassCountForReadiness = 1000

	runtime, err := NewIntegrationAuditRuntime(cfg)
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.EvaluateEvidenceBundle(validBundle())
	if err == nil {
		t.Fatal("expected low pass count error")
	}
	if result.ErrorCode != "MINIMUM_PASS_COUNT_NOT_MET" {
		t.Fatalf("expected MINIMUM_PASS_COUNT_NOT_MET, got %s", result.ErrorCode)
	}
}

func TestRegisterAuditEventRejectsMissingEvidenceHash(t *testing.T) {
	runtime, err := NewIntegrationAuditRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	event := validEvent(ScopePOSProviderRuntime, 32)
	event.EvidenceHash = ""

	result, err := runtime.RegisterAuditEvent(event)
	if err == nil {
		t.Fatal("expected evidence hash error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}
