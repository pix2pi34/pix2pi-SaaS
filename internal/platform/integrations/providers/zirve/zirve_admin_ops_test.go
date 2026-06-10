package zirve

import (
	"strings"
	"testing"
	"time"
)

func validZirveAdminOpsManualReviewDecision(t *testing.T) ZirveValidationRetryDLQDecision {
	t.Helper()

	runtime := NewZirveValidationRetryDLQRuntime(NewZirveProviderIdentity(time.Time{}))
	request := validZirveValidationRetryDLQRequest(t)
	request.ObservedErrorCode = ZirveErrSchemaMismatch
	request.ObservedErrorMessage = "schema mismatch requires manual review"

	decision, err := runtime.BuildDryRunValidationRetryDLQDecision(request)
	if err != nil {
		t.Fatalf("failed to build validation retry-dlq decision: %v", err)
	}

	return decision
}

func validZirveAdminOpsDLQDecision(t *testing.T) ZirveValidationRetryDLQDecision {
	t.Helper()

	runtime := NewZirveValidationRetryDLQRuntime(NewZirveProviderIdentity(time.Time{}))
	request := validZirveValidationRetryDLQRequest(t)
	request.ObservedErrorCode = ZirveErrProviderRateLimit
	request.ObservedErrorMessage = "rate limit exhausted"
	request.Attempt = 3
	request.MaxAttempts = 3

	decision, err := runtime.BuildDryRunValidationRetryDLQDecision(request)
	if err != nil {
		t.Fatalf("failed to build DLQ validation retry-dlq decision: %v", err)
	}

	return decision
}

func validZirveAdminOpsDenyDecision(t *testing.T) ZirveValidationRetryDLQDecision {
	t.Helper()

	runtime := NewZirveValidationRetryDLQRuntime(NewZirveProviderIdentity(time.Time{}))
	request := validZirveValidationRetryDLQRequest(t)
	request.ObservedErrorCode = ZirveErrRealDeliveryAttempted
	request.ObservedErrorMessage = "real delivery attempted"

	decision, err := runtime.BuildDryRunValidationRetryDLQDecision(request)
	if err != nil {
		t.Fatalf("failed to build DENY validation retry-dlq decision: %v", err)
	}

	return decision
}

func TestZirveAdminOpsOpensManualReview(t *testing.T) {
	runtime := NewZirveAdminOpsRuntime(NewZirveProviderIdentity(time.Time{}))

	item, err := runtime.OpenManualReview(
		validZirveAdminOpsManualReviewDecision(t),
		"zirve-review-001",
		"ops-admin",
		time.Date(2026, 5, 3, 16, 0, 0, 0, time.UTC),
	)
	if err != nil {
		t.Fatalf("expected manual review to open, got error: %v", err)
	}

	if item.ProviderID != "zirve" {
		t.Fatalf("unexpected provider id: %s", item.ProviderID)
	}
	if item.ModuleCode != "FAZ_7_8Z_5" {
		t.Fatalf("unexpected module code: %s", item.ModuleCode)
	}
	if item.Mode != "ADMIN_OPS_MANUAL_REVIEW_DRY_RUN_ONLY" {
		t.Fatalf("unexpected mode: %s", item.Mode)
	}
	if item.Status != ZirveManualReviewOpen {
		t.Fatalf("expected OPEN status, got %s", item.Status)
	}
	if item.Priority != ZirveManualReviewPriorityHigh {
		t.Fatalf("expected HIGH priority, got %s", item.Priority)
	}
}

func TestZirveAdminOpsQueuesDLQAndDenyDecisions(t *testing.T) {
	runtime := NewZirveAdminOpsRuntime(NewZirveProviderIdentity(time.Time{}))

	dlqItem, err := runtime.OpenManualReview(
		validZirveAdminOpsDLQDecision(t),
		"zirve-review-dlq-001",
		"ops-admin",
		time.Time{},
	)
	if err != nil {
		t.Fatalf("expected DLQ review to open, got error: %v", err)
	}
	if dlqItem.Priority != ZirveManualReviewPriorityHigh {
		t.Fatalf("expected DLQ review HIGH priority, got %s", dlqItem.Priority)
	}

	denyItem, err := runtime.OpenManualReview(
		validZirveAdminOpsDenyDecision(t),
		"zirve-review-deny-001",
		"ops-admin",
		time.Time{},
	)
	if err != nil {
		t.Fatalf("expected DENY review to open, got error: %v", err)
	}
	if denyItem.Priority != ZirveManualReviewPriorityCritical {
		t.Fatalf("expected DENY review CRITICAL priority, got %s", denyItem.Priority)
	}
}

func TestZirveAdminOpsKeepsRealBoundariesClosed(t *testing.T) {
	runtime := NewZirveAdminOpsRuntime(NewZirveProviderIdentity(time.Time{}))

	item, err := runtime.OpenManualReview(
		validZirveAdminOpsManualReviewDecision(t),
		"zirve-review-boundary-001",
		"ops-admin",
		time.Time{},
	)
	if err != nil {
		t.Fatalf("expected manual review to open, got error: %v", err)
	}

	if item.RealProviderAPIAllowed {
		t.Fatal("real provider API must remain closed")
	}
	if item.RealFileDeliveryAllowed {
		t.Fatal("real file delivery must remain closed")
	}
	if item.RealDeliveryChannelAllowed {
		t.Fatal("real delivery channel must remain closed")
	}
	if item.RealERPWriteAllowed {
		t.Fatal("real ERP write must remain closed")
	}
	if item.RealOperatorProviderActionAllowed {
		t.Fatal("real operator provider action must remain closed")
	}
}

func TestZirveAdminOpsTenantSafeListAndRead(t *testing.T) {
	runtime := NewZirveAdminOpsRuntime(NewZirveProviderIdentity(time.Time{}))

	_, err := runtime.OpenManualReview(
		validZirveAdminOpsManualReviewDecision(t),
		"zirve-review-tenant-001",
		"ops-admin",
		time.Time{},
	)
	if err != nil {
		t.Fatalf("expected manual review to open, got error: %v", err)
	}

	items, err := runtime.ListTenantManualReviews("tenant_7")
	if err != nil {
		t.Fatalf("expected tenant list, got error: %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("expected 1 tenant review, got %d", len(items))
	}

	_, err = runtime.GetTenantManualReview("tenant_7", "zirve-review-tenant-001")
	if err != nil {
		t.Fatalf("expected tenant-safe review read, got error: %v", err)
	}

	_, err = runtime.GetTenantManualReview("tenant_99", "zirve-review-tenant-001")
	if err == nil {
		t.Fatal("expected cross-tenant review read to be rejected")
	}
	if !strings.Contains(err.Error(), "tenant boundary") {
		t.Fatalf("expected tenant boundary error, got: %v", err)
	}
}

func TestZirveAdminOpsAssignAndResolveReview(t *testing.T) {
	runtime := NewZirveAdminOpsRuntime(NewZirveProviderIdentity(time.Time{}))

	_, err := runtime.OpenManualReview(
		validZirveAdminOpsManualReviewDecision(t),
		"zirve-review-action-001",
		"ops-admin",
		time.Time{},
	)
	if err != nil {
		t.Fatalf("expected manual review to open, got error: %v", err)
	}

	assigned, err := runtime.ApplyManualReviewAction(ZirveManualReviewActionRequest{
		TenantID:      "tenant_7",
		ReviewID:      "zirve-review-action-001",
		Actor:         "ops-admin",
		Action:        ZirveManualReviewActionAssign,
		AssignTo:      "finance-ops-user",
		CorrelationID: "corr-zirve-admin-001",
		DryRun:        true,
		RequestedAt:   time.Date(2026, 5, 3, 16, 30, 0, 0, time.UTC),
	})
	if err != nil {
		t.Fatalf("expected assign action to pass, got error: %v", err)
	}
	if assigned.Status != ZirveManualReviewAssigned {
		t.Fatalf("expected ASSIGNED status, got %s", assigned.Status)
	}
	if assigned.AssignedTo != "finance-ops-user" {
		t.Fatalf("unexpected assigned_to: %s", assigned.AssignedTo)
	}

	resolved, err := runtime.ApplyManualReviewAction(ZirveManualReviewActionRequest{
		TenantID:       "tenant_7",
		ReviewID:       "zirve-review-action-001",
		Actor:          "finance-ops-user",
		Action:         ZirveManualReviewActionResolve,
		ResolutionNote: "schema mapping corrected in dry-run contract",
		CorrelationID:  "corr-zirve-admin-002",
		DryRun:         true,
		RequestedAt:    time.Date(2026, 5, 3, 16, 45, 0, 0, time.UTC),
	})
	if err != nil {
		t.Fatalf("expected resolve action to pass, got error: %v", err)
	}
	if resolved.Status != ZirveManualReviewResolved {
		t.Fatalf("expected RESOLVED status, got %s", resolved.Status)
	}
	if resolved.RealOperatorProviderActionAllowed {
		t.Fatal("real operator provider action must remain closed after resolve")
	}
}

func TestZirveAdminOpsRejectReview(t *testing.T) {
	runtime := NewZirveAdminOpsRuntime(NewZirveProviderIdentity(time.Time{}))

	_, err := runtime.OpenManualReview(
		validZirveAdminOpsManualReviewDecision(t),
		"zirve-review-reject-001",
		"ops-admin",
		time.Time{},
	)
	if err != nil {
		t.Fatalf("expected manual review to open, got error: %v", err)
	}

	rejected, err := runtime.ApplyManualReviewAction(ZirveManualReviewActionRequest{
		TenantID:        "tenant_7",
		ReviewID:        "zirve-review-reject-001",
		Actor:           "ops-admin",
		Action:          ZirveManualReviewActionReject,
		RejectionReason: "invalid business mapping for Zirve dry-run import",
		CorrelationID:   "corr-zirve-admin-reject",
		DryRun:          true,
		RequestedAt:     time.Time{},
	})
	if err != nil {
		t.Fatalf("expected reject action to pass, got error: %v", err)
	}
	if rejected.Status != ZirveManualReviewRejected {
		t.Fatalf("expected REJECTED status, got %s", rejected.Status)
	}
	if rejected.RejectionReason == "" {
		t.Fatal("rejection reason must be recorded")
	}
}

func TestZirveAdminOpsRejectsPassDecision(t *testing.T) {
	runtime := NewZirveAdminOpsRuntime(NewZirveProviderIdentity(time.Time{}))
	validationRuntime := NewZirveValidationRetryDLQRuntime(NewZirveProviderIdentity(time.Time{}))

	passDecision, err := validationRuntime.BuildDryRunValidationRetryDLQDecision(validZirveValidationRetryDLQRequest(t))
	if err != nil {
		t.Fatalf("expected pass decision to build, got error: %v", err)
	}

	_, err = runtime.OpenManualReview(passDecision, "zirve-review-pass-001", "ops-admin", time.Time{})
	if err == nil {
		t.Fatal("expected PASS decision to be rejected from manual review queue")
	}
	if !strings.Contains(err.Error(), "not eligible") {
		t.Fatalf("expected not eligible error, got: %v", err)
	}
}

func TestZirveAdminOpsRejectsNonDryRunAction(t *testing.T) {
	runtime := NewZirveAdminOpsRuntime(NewZirveProviderIdentity(time.Time{}))

	_, err := runtime.OpenManualReview(
		validZirveAdminOpsManualReviewDecision(t),
		"zirve-review-non-dry-run-001",
		"ops-admin",
		time.Time{},
	)
	if err != nil {
		t.Fatalf("expected manual review to open, got error: %v", err)
	}

	_, err = runtime.ApplyManualReviewAction(ZirveManualReviewActionRequest{
		TenantID:      "tenant_7",
		ReviewID:      "zirve-review-non-dry-run-001",
		Actor:         "ops-admin",
		Action:        ZirveManualReviewActionAssign,
		AssignTo:      "finance-ops-user",
		CorrelationID: "corr-zirve-admin-003",
		DryRun:        false,
	})
	if err == nil {
		t.Fatal("expected non-dry-run action to be rejected")
	}
	if !strings.Contains(err.Error(), "dry-run only") {
		t.Fatalf("expected dry-run only error, got: %v", err)
	}
}

func TestZirveAdminOpsRejectsClosedReviewMutation(t *testing.T) {
	runtime := NewZirveAdminOpsRuntime(NewZirveProviderIdentity(time.Time{}))

	_, err := runtime.OpenManualReview(
		validZirveAdminOpsManualReviewDecision(t),
		"zirve-review-closed-001",
		"ops-admin",
		time.Time{},
	)
	if err != nil {
		t.Fatalf("expected manual review to open, got error: %v", err)
	}

	_, err = runtime.ApplyManualReviewAction(ZirveManualReviewActionRequest{
		TenantID:       "tenant_7",
		ReviewID:       "zirve-review-closed-001",
		Actor:          "ops-admin",
		Action:         ZirveManualReviewActionResolve,
		ResolutionNote: "resolved once",
		CorrelationID:  "corr-zirve-admin-004",
		DryRun:         true,
	})
	if err != nil {
		t.Fatalf("expected first resolve to pass, got error: %v", err)
	}

	_, err = runtime.ApplyManualReviewAction(ZirveManualReviewActionRequest{
		TenantID:       "tenant_7",
		ReviewID:       "zirve-review-closed-001",
		Actor:          "ops-admin",
		Action:         ZirveManualReviewActionResolve,
		ResolutionNote: "resolved twice",
		CorrelationID:  "corr-zirve-admin-005",
		DryRun:         true,
	})
	if err == nil {
		t.Fatal("expected closed review mutation to be rejected")
	}
	if !strings.Contains(err.Error(), "already closed") {
		t.Fatalf("expected already closed error, got: %v", err)
	}
}
