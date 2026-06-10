package tenantfreeze

import "testing"

func TestTenantFreezeFlowPassesInternalReadiness(t *testing.T) {
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

	if !report.InternalTenantFreezeReady {
		t.Fatal("internal tenant freeze readiness must be true")
	}

	if report.ProductionFreezeEnabled {
		t.Fatal("production freeze must remain disabled")
	}

	if report.RealTenantFreezeEnabled {
		t.Fatal("real tenant freeze must remain disabled")
	}

	if report.AutoAccessCutoffEnabled {
		t.Fatal("auto access cutoff must remain disabled")
	}

	if report.AutoUnfreezeEnabled {
		t.Fatal("auto unfreeze must remain disabled")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestTenantFreezeFlowBlocksProductionFreeze(t *testing.T) {
	input := validFlowInput()
	input.ProductionFreezeEnabled = true

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

func TestTenantFreezeFlowRequiresEligibilityPolicy(t *testing.T) {
	input := validFlowInput()
	input.Steps[0].RequiresFreezeEligibilityPolicy = false

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

func TestTenantFreezeFlowRequiresDeferredReason(t *testing.T) {
	input := validFlowInput()

	for idx := range input.Steps {
		if input.Steps[idx].DeferredToProductionApproval {
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
	input := FlowInput{RequiredStepKeys: []string{"billing_status_check", "freeze_request_intake"}}
	keys := RequiredStepKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "billing_status_check" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validFlowInput() FlowInput {
	return FlowInput{
		Phase:                     "FAZ_5_18_5_3",
		Target:                    "FAZ_5_R_TENANT_FREEZE_FLOW",
		InternalTenantFreezeReady: true,
		ProductionFreezeEnabled:   false,
		RealTenantFreezeEnabled:   false,
		AutoAccessCutoffEnabled:   false,
		AutoUnfreezeEnabled:       false,
		RequiredStepKeys: []string{
			"freeze_request_intake",
			"billing_status_check",
			"unpaid_invoice_check",
			"freeze_eligibility_check",
			"owner_approval_queue",
			"entitlement_freeze_plan",
			"access_limit_policy",
			"notification_block_policy",
			"unfreeze_path_define",
			"production_freeze_deferred_marker",
		},
		RequiredEvents: []FreezeEvent{
			EventFreezeRequestReceived,
			EventBillingStatusChecked,
			EventUnpaidInvoiceChecked,
			EventFreezeEligibilityChecked,
			EventOwnerApprovalQueued,
			EventEntitlementFreezePlanned,
			EventAccessLimitPolicyReady,
			EventNotificationBlocked,
			EventUnfreezePathDefined,
			EventProductionFreezeDeferred,
		},
		RequireInternalReady:            true,
		RequireEvidence:                 true,
		RequireCounterBasedAudit:        true,
		RequireNoRequiredFail:           true,
		RequireNoOptionalWarn:           true,
		RequireTenantID:                 true,
		RequireFreezeRequestID:          true,
		RequireBillingStatusCheck:       true,
		RequireUnpaidInvoiceCheck:       true,
		RequireFreezeEligibilityPolicy:  true,
		RequireOwnerApproval:            true,
		RequireEntitlementFreeze:        true,
		RequireAccessLimitPolicy:        true,
		RequireNotificationTemplate:     true,
		RequireUnfreezePath:             true,
		RequireAuditTrail:               true,
		RequireRollbackPlan:             true,
		RequireSupportHandoff:           true,
		RequireProductionFreezeBlock:    true,
		RequireRealTenantFreezeBlock:    true,
		RequireAutoAccessCutoffBlock:    true,
		RequireAutoUnfreezeBlock:        true,
		AllowProductionApprovalDeferred: true,
		Steps: []FreezeStep{
			step("freeze_request_intake", EventFreezeRequestReceived, "Freeze Request Intake"),
			step("billing_status_check", EventBillingStatusChecked, "Billing Status Check"),
			step("unpaid_invoice_check", EventUnpaidInvoiceChecked, "Unpaid Invoice Check"),
			step("freeze_eligibility_check", EventFreezeEligibilityChecked, "Freeze Eligibility Check"),
			step("owner_approval_queue", EventOwnerApprovalQueued, "Owner Approval Queue"),
			step("entitlement_freeze_plan", EventEntitlementFreezePlanned, "Entitlement Freeze Plan"),
			step("access_limit_policy", EventAccessLimitPolicyReady, "Access Limit Policy"),
			step("notification_block_policy", EventNotificationBlocked, "Notification Block Policy"),
			step("unfreeze_path_define", EventUnfreezePathDefined, "Unfreeze Path Define"),
			deferred("production_freeze_deferred_marker", EventProductionFreezeDeferred, "Production Freeze Deferred Marker"),
		},
	}
}

func step(key string, event FreezeEvent, title string) FreezeStep {
	return FreezeStep{
		Key:                             key,
		Event:                           event,
		Title:                           title,
		Owner:                           "tenant_lifecycle_ops",
		Status:                          StatusReady,
		Required:                        true,
		InternalReady:                   true,
		HasEvidence:                     true,
		HasCounterBasedAudit:            true,
		RequiredFailCount:               0,
		OptionalWarnCount:               0,
		ProductionFreezeEnabled:         false,
		RealTenantFreezeEnabled:         false,
		AutoAccessCutoffEnabled:         false,
		AutoUnfreezeEnabled:             false,
		RequiresTenantID:                true,
		RequiresFreezeRequestID:         true,
		RequiresBillingStatusCheck:      true,
		RequiresUnpaidInvoiceCheck:      true,
		RequiresFreezeEligibilityPolicy: true,
		RequiresOwnerApproval:           true,
		RequiresEntitlementFreeze:       true,
		RequiresAccessLimitPolicy:       true,
		RequiresNotificationTemplate:    true,
		RequiresUnfreezePath:            true,
		RequiresAuditTrail:              true,
		RequiresRollbackPlan:            true,
		RequiresSupportHandoff:          true,
		BlocksProductionFreeze:          true,
		BlocksRealTenantFreeze:          true,
		BlocksAutoAccessCutoff:          true,
		BlocksAutoUnfreeze:              true,
		DeferredToProductionApproval:    false,
	}
}

func deferred(key string, event FreezeEvent, title string) FreezeStep {
	s := step(key, event, title)
	s.Status = StatusPendingNext
	s.InternalReady = false
	s.DeferredToProductionApproval = true
	s.DeferredReason = "Gerçek tenant dondurma production approval ve tenant lifecycle final gate sonrası açılacak"
	return s
}
