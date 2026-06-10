package refundcancelflow

import "testing"

func TestRefundCancelFlowPassesInternalReadiness(t *testing.T) {
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

	if !report.InternalRefundCancelFlowReady {
		t.Fatal("internal refund/cancel flow readiness must be true")
	}

	if report.ProductionRefundEnabled {
		t.Fatal("production refund must remain disabled")
	}

	if report.RealMoneyRefundEnabled {
		t.Fatal("real money refund must remain disabled")
	}

	if report.AutoCancelEnabled {
		t.Fatal("auto cancel must remain disabled")
	}

	if report.AutoCustomerNotificationEnabled {
		t.Fatal("auto customer notification must remain disabled")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestRefundCancelFlowBlocksRealMoneyRefund(t *testing.T) {
	input := validFlowInput()
	input.RealMoneyRefundEnabled = true

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

func TestRefundCancelFlowRequiresManualApproval(t *testing.T) {
	input := validFlowInput()
	input.Steps[0].RequiresManualApproval = false

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

func TestRefundCancelFlowRequiresDeferredReason(t *testing.T) {
	input := validFlowInput()

	for idx := range input.Steps {
		if input.Steps[idx].DeferredToProviderLive || input.Steps[idx].DeferredToEDocumentModule {
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
	input := FlowInput{RequiredStepKeys: []string{"refund_request_validate", "cancel_request_validate"}}
	keys := RequiredStepKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "cancel_request_validate" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validFlowInput() FlowInput {
	return FlowInput{
		Phase:                           "FAZ_5_18_2_5",
		Target:                          "FAZ_5_R_REFUND_CANCEL_COMMERCIAL_FLOW",
		InternalRefundCancelFlowReady:   true,
		ProductionRefundEnabled:         false,
		RealMoneyRefundEnabled:          false,
		AutoCancelEnabled:               false,
		AutoCustomerNotificationEnabled: false,
		RequiredStepKeys: []string{
			"refund_request_validate",
			"refund_eligibility_validate",
			"refund_amount_calculate",
			"cancel_request_validate",
			"credit_note_deferred_marker",
			"payment_refund_provider_deferred_marker",
			"tenant_entitlement_adjustment_policy",
			"manual_approval_queue",
			"accounting_reversal_handoff",
			"customer_notification_block_policy",
		},
		RequiredEvents: []RefundCancelEvent{
			EventRefundRequestReceived,
			EventRefundEligibilityValidated,
			EventRefundAmountCalculated,
			EventCancelRequestValidated,
			EventCreditNoteDeferred,
			EventPaymentRefundDeferred,
			EventTenantEntitlementAdjusted,
			EventManualApprovalQueued,
			EventAccountingReversalReady,
			EventCustomerNotifyBlocked,
		},
		RequireInternalReady:                 true,
		RequireEvidence:                      true,
		RequireCounterBasedAudit:             true,
		RequireNoRequiredFail:                true,
		RequireNoOptionalWarn:                true,
		RequireTenantID:                      true,
		RequireInvoiceID:                     true,
		RequirePaymentAttemptID:              true,
		RequireRefundRequestID:               true,
		RequireIdempotencyKey:                true,
		RequireAuditTrail:                    true,
		RequireEligibilityPolicy:             true,
		RequireAmountCalculation:             true,
		RequireManualApproval:                true,
		RequireBillingOwner:                  true,
		RequireAccountingReversal:            true,
		RequireCreditNoteHandoff:             true,
		RequireProviderRefundHandoff:         true,
		RequireCustomerTemplate:              true,
		RequireProductionRefundBlock:         true,
		RequireRealMoneyMovementBlock:        true,
		RequireAutoCancelBlock:               true,
		RequireAutoCustomerNotificationBlock: true,
		AllowProviderLiveDeferred:            true,
		AllowEDocumentDeferred:               true,
		Steps: []RefundCancelStep{
			step("refund_request_validate", EventRefundRequestReceived, "Refund Request Validate"),
			step("refund_eligibility_validate", EventRefundEligibilityValidated, "Refund Eligibility Validate"),
			step("refund_amount_calculate", EventRefundAmountCalculated, "Refund Amount Calculate"),
			step("cancel_request_validate", EventCancelRequestValidated, "Cancel Request Validate"),
			eDocumentDeferred("credit_note_deferred_marker", EventCreditNoteDeferred, "Credit Note Deferred Marker"),
			providerDeferred("payment_refund_provider_deferred_marker", EventPaymentRefundDeferred, "Payment Refund Provider Deferred Marker"),
			step("tenant_entitlement_adjustment_policy", EventTenantEntitlementAdjusted, "Tenant Entitlement Adjustment Policy"),
			step("manual_approval_queue", EventManualApprovalQueued, "Manual Approval Queue"),
			step("accounting_reversal_handoff", EventAccountingReversalReady, "Accounting Reversal Handoff"),
			step("customer_notification_block_policy", EventCustomerNotifyBlocked, "Customer Notification Block Policy"),
		},
	}
}

func step(key string, event RefundCancelEvent, title string) RefundCancelStep {
	return RefundCancelStep{
		Key:                             key,
		Event:                           event,
		Title:                           title,
		Owner:                           "billing_ops",
		Status:                          StatusReady,
		Required:                        true,
		InternalReady:                   true,
		HasEvidence:                     true,
		HasCounterBasedAudit:            true,
		RequiredFailCount:               0,
		OptionalWarnCount:               0,
		ProductionRefundEnabled:         false,
		RealMoneyRefundEnabled:          false,
		AutoCancelEnabled:               false,
		AutoCustomerNotificationEnabled: false,
		RequiresTenantID:                true,
		RequiresInvoiceID:               true,
		RequiresPaymentAttemptID:        true,
		RequiresRefundRequestID:         true,
		RequiresIdempotencyKey:          true,
		RequiresAuditTrail:              true,
		RequiresEligibilityPolicy:       true,
		RequiresAmountCalculation:       true,
		RequiresManualApproval:          true,
		RequiresBillingOwner:            true,
		RequiresAccountingReversal:      true,
		RequiresCreditNoteHandoff:       true,
		RequiresProviderRefundHandoff:   true,
		RequiresCustomerTemplate:        true,
		BlocksProductionRefund:          true,
		BlocksRealMoneyMovement:         true,
		BlocksAutoCancel:                true,
		BlocksAutoCustomerNotification:  true,
		DeferredToProviderLive:          false,
		DeferredToEDocumentModule:       false,
	}
}

func providerDeferred(key string, event RefundCancelEvent, title string) RefundCancelStep {
	s := step(key, event, title)
	s.Status = StatusPendingNext
	s.InternalReady = false
	s.DeferredToProviderLive = true
	s.DeferredReason = "Gerçek para iadesi provider-specific live payment/refund modülünde açılacak"
	return s
}

func eDocumentDeferred(key string, event RefundCancelEvent, title string) RefundCancelStep {
	s := step(key, event, title)
	s.Status = StatusPendingNext
	s.InternalReady = false
	s.DeferredToEDocumentModule = true
	s.DeferredReason = "İade/iptal e-Belge veya mahsup belgesi e-document provider/live modülünde açılacak"
	return s
}
