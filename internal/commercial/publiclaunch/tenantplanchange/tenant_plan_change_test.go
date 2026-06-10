package tenantplanchange

import "testing"

func TestTenantPlanChangeFlowPassesInternalReadiness(t *testing.T) {
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

	if !report.InternalTenantPlanChangeReady {
		t.Fatal("internal tenant plan change readiness must be true")
	}

	if report.ProductionPlanChangeEnabled {
		t.Fatal("production plan change must remain disabled")
	}

	if report.RealCustomerPlanChangeEnabled {
		t.Fatal("real customer plan change must remain disabled")
	}

	if report.AutoEntitlementSwitchEnabled {
		t.Fatal("auto entitlement switch must remain disabled")
	}

	if report.AutoProrationBillingEnabled {
		t.Fatal("auto proration billing must remain disabled")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestTenantPlanChangeFlowBlocksProductionPlanChange(t *testing.T) {
	input := validFlowInput()
	input.ProductionPlanChangeEnabled = true

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

func TestTenantPlanChangeFlowRequiresEntitlementDiff(t *testing.T) {
	input := validFlowInput()
	input.Steps[0].RequiresEntitlementDiff = false

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

func TestTenantPlanChangeFlowRequiresDeferredReason(t *testing.T) {
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
	input := FlowInput{RequiredStepKeys: []string{"target_plan_validate", "current_plan_snapshot"}}
	keys := RequiredStepKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "current_plan_snapshot" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validFlowInput() FlowInput {
	return FlowInput{
		Phase:                         "FAZ_5_18_5_2",
		Target:                        "FAZ_5_R_TENANT_PLAN_CHANGE_FLOW",
		InternalTenantPlanChangeReady: true,
		ProductionPlanChangeEnabled:   false,
		RealCustomerPlanChangeEnabled: false,
		AutoEntitlementSwitchEnabled:  false,
		AutoProrationBillingEnabled:   false,
		RequiredStepKeys: []string{
			"plan_change_request_intake",
			"current_plan_snapshot",
			"target_plan_validate",
			"entitlement_diff_calculate",
			"billing_impact_calculate",
			"proration_policy_prepare",
			"downgrade_safety_check",
			"owner_approval_queue",
			"effective_date_schedule",
			"plan_change_deferred_marker",
		},
		RequiredEvents: []PlanChangeEvent{
			EventPlanChangeRequested,
			EventCurrentPlanSnapshotted,
			EventTargetPlanValidated,
			EventEntitlementDiffCalculated,
			EventBillingImpactCalculated,
			EventProrationPolicyPrepared,
			EventDowngradeSafetyChecked,
			EventOwnerApprovalQueued,
			EventEffectiveDateScheduled,
			EventPlanChangeDeferred,
		},
		RequireInternalReady:               true,
		RequireEvidence:                    true,
		RequireCounterBasedAudit:           true,
		RequireNoRequiredFail:              true,
		RequireNoOptionalWarn:              true,
		RequireTenantID:                    true,
		RequirePlanChangeRequestID:         true,
		RequireCurrentPlanID:               true,
		RequireTargetPlanID:                true,
		RequirePlanSnapshot:                true,
		RequireEntitlementDiff:             true,
		RequireBillingImpact:               true,
		RequireProrationPolicy:             true,
		RequireDowngradeSafetyCheck:        true,
		RequireOwnerApproval:               true,
		RequireEffectiveDate:               true,
		RequireAuditTrail:                  true,
		RequireRollbackPlan:                true,
		RequireSupportHandoff:              true,
		RequireCustomerTemplate:            true,
		RequireProductionPlanChangeBlock:   true,
		RequireRealCustomerPlanChangeBlock: true,
		RequireAutoEntitlementSwitchBlock:  true,
		RequireAutoProrationBillingBlock:   true,
		AllowProductionApprovalDeferred:    true,
		Steps: []PlanChangeStep{
			step("plan_change_request_intake", EventPlanChangeRequested, "Plan Change Request Intake"),
			step("current_plan_snapshot", EventCurrentPlanSnapshotted, "Current Plan Snapshot"),
			step("target_plan_validate", EventTargetPlanValidated, "Target Plan Validate"),
			step("entitlement_diff_calculate", EventEntitlementDiffCalculated, "Entitlement Diff Calculate"),
			step("billing_impact_calculate", EventBillingImpactCalculated, "Billing Impact Calculate"),
			step("proration_policy_prepare", EventProrationPolicyPrepared, "Proration Policy Prepare"),
			step("downgrade_safety_check", EventDowngradeSafetyChecked, "Downgrade Safety Check"),
			step("owner_approval_queue", EventOwnerApprovalQueued, "Owner Approval Queue"),
			step("effective_date_schedule", EventEffectiveDateScheduled, "Effective Date Schedule"),
			deferred("plan_change_deferred_marker", EventPlanChangeDeferred, "Plan Change Deferred Marker"),
		},
	}
}

func step(key string, event PlanChangeEvent, title string) PlanChangeStep {
	return PlanChangeStep{
		Key:                           key,
		Event:                         event,
		Title:                         title,
		Owner:                         "tenant_lifecycle_ops",
		Status:                        StatusReady,
		Required:                      true,
		InternalReady:                 true,
		HasEvidence:                   true,
		HasCounterBasedAudit:          true,
		RequiredFailCount:             0,
		OptionalWarnCount:             0,
		ProductionPlanChangeEnabled:   false,
		RealCustomerPlanChangeEnabled: false,
		AutoEntitlementSwitchEnabled:  false,
		AutoProrationBillingEnabled:   false,
		RequiresTenantID:              true,
		RequiresPlanChangeRequestID:   true,
		RequiresCurrentPlanID:         true,
		RequiresTargetPlanID:          true,
		RequiresPlanSnapshot:          true,
		RequiresEntitlementDiff:       true,
		RequiresBillingImpact:         true,
		RequiresProrationPolicy:       true,
		RequiresDowngradeSafetyCheck:  true,
		RequiresOwnerApproval:         true,
		RequiresEffectiveDate:         true,
		RequiresAuditTrail:            true,
		RequiresRollbackPlan:          true,
		RequiresSupportHandoff:        true,
		RequiresCustomerTemplate:      true,
		BlocksProductionPlanChange:    true,
		BlocksRealCustomerPlanChange:  true,
		BlocksAutoEntitlementSwitch:   true,
		BlocksAutoProrationBilling:    true,
		DeferredToProductionApproval:  false,
	}
}

func deferred(key string, event PlanChangeEvent, title string) PlanChangeStep {
	s := step(key, event, title)
	s.Status = StatusPendingNext
	s.InternalReady = false
	s.DeferredToProductionApproval = true
	s.DeferredReason = "Gerçek tenant plan değişikliği production approval ve billing/entitlement canlı geçiş gate sonrası açılacak"
	return s
}
