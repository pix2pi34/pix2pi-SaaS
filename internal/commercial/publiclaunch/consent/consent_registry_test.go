package consent

import (
	"testing"
	"time"
)

func baseInput(scope ConsentScope) DecisionInput {
	return DecisionInput{
		TenantID:        "tenant_001",
		UserID:          "user_001",
		Scope:           scope,
		DocumentVersion: "0.1.0-draft",
		IPAddress:       "127.0.0.1",
		UserAgent:       "go-test",
		Channel:         "admin_preview",
		CorrelationID:   "corr_001",
		Reason:          "test",
		Now:             time.Date(2026, 5, 9, 12, 0, 0, 0, time.UTC),
	}
}

func TestAcceptRecordsConsentWithEvidenceHash(t *testing.T) {
	registry := NewRegistry()

	decision, err := registry.Accept(baseInput(ScopeDataSupportedPlanTerms))
	if err != nil {
		t.Fatalf("accept returned error: %v", err)
	}

	if decision.Status != StatusAccepted {
		t.Fatalf("expected ACCEPTED, got %s", decision.Status)
	}

	if decision.EvidenceHash == "" {
		t.Fatal("expected evidence hash")
	}

	if !registry.IsAccepted("tenant_001", "user_001", ScopeDataSupportedPlanTerms) {
		t.Fatal("expected accepted consent")
	}
}

func TestCoreProductAllowedWithoutConsent(t *testing.T) {
	registry := NewRegistry()

	decision := registry.EvaluateGate("tenant_001", "user_001", GateCoreProduct)
	if !decision.Allowed {
		t.Fatalf("core product must be allowed, got: %#v", decision)
	}
}

func TestDataSupportedPlanBlockedWithoutConsent(t *testing.T) {
	registry := NewRegistry()

	decision := registry.EvaluateGate("tenant_001", "user_001", GateDataSupportedPlan)
	if decision.Allowed {
		t.Fatal("data supported plan must be blocked without consent")
	}

	if decision.PlanMode != "RESTRICTED_PAID_OR_DISABLED" {
		t.Fatalf("expected restricted paid route, got %s", decision.PlanMode)
	}
}

func TestDataSupportedPlanAllowedAfterConsent(t *testing.T) {
	registry := NewRegistry()

	if _, err := registry.Accept(baseInput(ScopeDataSupportedPlanTerms)); err != nil {
		t.Fatalf("accept returned error: %v", err)
	}

	decision := registry.EvaluateGate("tenant_001", "user_001", GateDataSupportedPlan)
	if !decision.Allowed {
		t.Fatalf("data supported plan should be allowed after consent, got: %#v", decision)
	}
}

func TestCommercialMessageBlockedUnlessAccepted(t *testing.T) {
	registry := NewRegistry()

	decision := registry.EvaluateGate("tenant_001", "user_001", GateCommercialElectronicMessage)
	if decision.Allowed {
		t.Fatal("commercial electronic message must be blocked without consent")
	}

	if _, err := registry.Accept(baseInput(ScopeCommercialElectronicMessage)); err != nil {
		t.Fatalf("accept returned error: %v", err)
	}

	decision = registry.EvaluateGate("tenant_001", "user_001", GateCommercialElectronicMessage)
	if !decision.Allowed {
		t.Fatal("commercial electronic message should be allowed after consent")
	}
}

func TestRevokeBlocksFeatureAgain(t *testing.T) {
	registry := NewRegistry()

	if _, err := registry.Accept(baseInput(ScopeSponsoredOfferPersonalization)); err != nil {
		t.Fatalf("accept returned error: %v", err)
	}

	if !registry.EvaluateGate("tenant_001", "user_001", GateSponsoredOfferPersonalization).Allowed {
		t.Fatal("sponsored offer should be allowed after accept")
	}

	if _, err := registry.Revoke(baseInput(ScopeSponsoredOfferPersonalization)); err != nil {
		t.Fatalf("revoke returned error: %v", err)
	}

	if registry.EvaluateGate("tenant_001", "user_001", GateSponsoredOfferPersonalization).Allowed {
		t.Fatal("sponsored offer must be blocked after revoke")
	}
}

func TestDeclineBlocksFeature(t *testing.T) {
	registry := NewRegistry()

	if _, err := registry.Decline(baseInput(ScopeNonEssentialCookies)); err != nil {
		t.Fatalf("decline returned error: %v", err)
	}

	decision := registry.EvaluateGate("tenant_001", "user_001", GateNonEssentialCookies)
	if decision.Allowed {
		t.Fatal("non essential cookies must be blocked after decline")
	}
}

func TestRequiredFieldsValidation(t *testing.T) {
	registry := NewRegistry()

	input := baseInput(ScopeAIDecisionSupport)
	input.TenantID = ""

	if _, err := registry.Accept(input); err != ErrTenantRequired {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestSnapshotIsTenantAndUserScoped(t *testing.T) {
	registry := NewRegistry()

	if _, err := registry.Accept(baseInput(ScopeDataSupportedPlanTerms)); err != nil {
		t.Fatalf("accept returned error: %v", err)
	}

	other := baseInput(ScopeCommercialElectronicMessage)
	other.UserID = "user_002"
	if _, err := registry.Accept(other); err != nil {
		t.Fatalf("accept returned error: %v", err)
	}

	snapshot := registry.Snapshot("tenant_001", "user_001")
	if len(snapshot) != 1 {
		t.Fatalf("expected one scoped decision, got %d", len(snapshot))
	}

	if snapshot[0].UserID != "user_001" {
		t.Fatalf("unexpected user in snapshot: %s", snapshot[0].UserID)
	}
}
