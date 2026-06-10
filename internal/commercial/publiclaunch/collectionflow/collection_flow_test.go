package collectionflow

import "testing"

func TestCollectionFailedPaymentFlowPassesInternalReadiness(t *testing.T) {
	input := validFlowInput()

	report, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}

	if report.Status != "PASS" {
		t.Fatalf("expected PASS got %s findings=%v", report.Status, report.Findings)
	}

	if report.RequiredFailCount != 0 {
		t.Fatalf("expected zero required fails got %d", report.RequiredFailCount)
	}

	if !report.InternalCollectionFlowReady {
		t.Fatal("internal collection flow readiness must be true")
	}

	if report.ProductionPaymentEnabled {
		t.Fatal("production payment must remain disabled")
	}

	if report.RealCustomerChargingEnabled {
		t.Fatal("real customer charging must remain disabled")
	}

	if report.AutoTenantSuspensionEnabled {
		t.Fatal("auto tenant suspension must remain disabled")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestCollectionFailedPaymentFlowBlocksRealCustomerCharging(t *testing.T) {
	input := validFlowInput()
	input.RealCustomerChargingEnabled = true

	report, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}

	if report.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", report.Status)
	}

	if report.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
}

func TestCollectionFailedPaymentFlowRequiresIdempotencyKey(t *testing.T) {
	input := validFlowInput()
	input.Steps[0].RequiresIdempotencyKey = false

	report, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}

	if report.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", report.Status)
	}

	if report.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
}

func TestCollectionFailedPaymentFlowRequiresDeferredReason(t *testing.T) {
	input := validFlowInput()

	for idx := range input.Steps {
		if input.Steps[idx].DeferredToProviderLive {
			input.Steps[idx].DeferredReason = ""
		}
	}

	report, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}

	if report.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", report.Status)
	}

	if report.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
}

func TestRequiredStepKeysSorted(t *testing.T) {
	input := FlowInput{RequiredStepKeys: []string{"payment_failed_capture", "collection_attempt_create"}}
	keys := RequiredStepKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "collection_attempt_create" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validFlowInput() FlowInput {
	return FlowInput{
		Phase:                       "FAZ_5_18_2_3",
		Target:                      "FAZ_5_R_COLLECTION_FAILED_PAYMENT_FLOW",
		InternalCollectionFlowReady: true,
		ProductionPaymentEnabled:    false,
		RealCustomerChargingEnabled: false,
		AutoTenantSuspensionEnabled: false,
		RequiredStepKeys: []string{
			"invoice_due_marker",
			"collection_attempt_create",
			"payment_failed_capture",
			"retry_schedule_policy",
			"grace_period_policy",
			"manual_review_queue",
			"tenant_action_block_policy",
			"provider_live_deferred_marker",
		},
		RequiredEvents: []CollectionEvent{
			EventInvoiceDue,
			EventCollectionAttempt,
			EventPaymentFailed,
			EventRetryScheduled,
			EventGracePeriodStarted,
			EventManualReviewQueued,
			EventTenantActionBlocked,
		},
		RequireInternalReady:             true,
		RequireEvidence:                  true,
		RequireCounterBasedAudit:         true,
		RequireNoRequiredFail:            true,
		RequireNoOptionalWarn:            true,
		RequireTenantID:                  true,
		RequireInvoiceID:                 true,
		RequireAttemptID:                 true,
		RequireIdempotencyKey:            true,
		RequireAuditTrail:                true,
		RequireRetryPolicy:               true,
		RequireDunningTemplate:           true,
		RequireManualReview:              true,
		RequireBillingOwner:              true,
		RequireProductionChargingBlock:   true,
		RequireAutoTenantSuspensionBlock: true,
		AllowProviderLiveDeferred:        true,
		Steps: []CollectionStep{
			step("invoice_due_marker", EventInvoiceDue, "Invoice Due Marker"),
			step("collection_attempt_create", EventCollectionAttempt, "Collection Attempt Create"),
			step("payment_failed_capture", EventPaymentFailed, "Payment Failed Capture"),
			step("retry_schedule_policy", EventRetryScheduled, "Retry Schedule Policy"),
			step("grace_period_policy", EventGracePeriodStarted, "Grace Period Policy"),
			step("manual_review_queue", EventManualReviewQueued, "Manual Review Queue"),
			step("tenant_action_block_policy", EventTenantActionBlocked, "Tenant Action Block Policy"),
			deferred("provider_live_deferred_marker", EventCollectionAttempt, "Provider Live Deferred Marker", "Gerçek ödeme sağlayıcı production entegrasyonu provider-specific live module içinde açılacak"),
		},
	}
}

func step(key string, event CollectionEvent, title string) CollectionStep {
	return CollectionStep{
		Key:                         key,
		Event:                       event,
		Title:                       title,
		Owner:                       "billing_ops",
		Status:                      StatusReady,
		Required:                    true,
		InternalReady:               true,
		HasEvidence:                 true,
		HasCounterBasedAudit:        true,
		RequiredFailCount:           0,
		OptionalWarnCount:           0,
		ProductionPaymentEnabled:    false,
		RealCustomerChargingEnabled: false,
		AutoTenantSuspensionEnabled: false,
		RequiresTenantID:            true,
		RequiresInvoiceID:           true,
		RequiresAttemptID:           true,
		RequiresIdempotencyKey:      true,
		RequiresAuditTrail:          true,
		RequiresRetryPolicy:         true,
		RequiresDunningTemplate:     true,
		RequiresManualReview:        true,
		RequiresBillingOwner:        true,
		BlocksProductionCharging:    true,
		BlocksAutoTenantSuspension:  true,
		MaxRetryCount:               3,
		GracePeriodDays:             7,
		DeferredToProviderLive:      false,
	}
}

func deferred(key string, event CollectionEvent, title string, reason string) CollectionStep {
	s := step(key, event, title)
	s.Status = StatusPendingNext
	s.InternalReady = false
	s.DeferredToProviderLive = true
	s.DeferredReason = reason
	return s
}
