package tenantshutdown

import "testing"

func TestTenantShutdownFlowPassesInternalReadiness(t *testing.T) {
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

	if !report.InternalTenantShutdownReady {
		t.Fatal("internal tenant shutdown readiness must be true")
	}

	if report.ProductionShutdownEnabled {
		t.Fatal("production shutdown must remain disabled")
	}

	if report.RealTenantClosureEnabled {
		t.Fatal("real tenant closure must remain disabled")
	}

	if report.DataDeletionEnabled {
		t.Fatal("data deletion must remain disabled")
	}

	if report.AutoAccessCutoffEnabled {
		t.Fatal("auto access cutoff must remain disabled")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestTenantShutdownFlowBlocksProductionShutdown(t *testing.T) {
	input := validFlowInput()
	input.ProductionShutdownEnabled = true

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

func TestTenantShutdownFlowRequiresDataExportOffer(t *testing.T) {
	input := validFlowInput()
	input.Steps[0].RequiresDataExportOffer = false

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

func TestTenantShutdownFlowRequiresDeferredReason(t *testing.T) {
	input := validFlowInput()

	for idx := range input.Steps {
		if input.Steps[idx].DeferredToDataExportFlow || input.Steps[idx].DeferredToProductionApproval {
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
	input := FlowInput{RequiredStepKeys: []string{"owner_approval_queue", "billing_status_validate"}}
	keys := RequiredStepKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "billing_status_validate" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validFlowInput() FlowInput {
	return FlowInput{
		Phase:                       "FAZ_5_18_5_4",
		Target:                      "FAZ_5_R_TENANT_SHUTDOWN_FLOW",
		InternalTenantShutdownReady: true,
		ProductionShutdownEnabled:   false,
		RealTenantClosureEnabled:    false,
		DataDeletionEnabled:         false,
		AutoAccessCutoffEnabled:     false,
		RequiredStepKeys: []string{
			"shutdown_request_intake",
			"billing_status_validate",
			"unpaid_invoice_check",
			"data_export_offer",
			"legal_hold_check",
			"owner_approval_queue",
			"tenant_access_freeze_plan",
			"billing_stop_plan",
			"final_shutdown_deferred_marker",
		},
		RequiredEvents: []ShutdownEvent{
			EventShutdownRequestReceived,
			EventBillingStatusValidated,
			EventUnpaidInvoiceChecked,
			EventDataExportOffered,
			EventLegalHoldChecked,
			EventOwnerApprovalQueued,
			EventTenantAccessFreezePlanned,
			EventBillingStopPlanned,
			EventFinalShutdownDeferred,
		},
		RequireInternalReady:            true,
		RequireEvidence:                 true,
		RequireCounterBasedAudit:        true,
		RequireNoRequiredFail:           true,
		RequireNoOptionalWarn:           true,
		RequireTenantID:                 true,
		RequireShutdownRequestID:        true,
		RequireBillingStatusCheck:       true,
		RequireUnpaidInvoiceCheck:       true,
		RequireDataExportOffer:          true,
		RequireLegalHoldCheck:           true,
		RequireOwnerApproval:            true,
		RequireSupportHandoff:           true,
		RequireCustomerTemplate:         true,
		RequireAuditTrail:               true,
		RequireRollbackWindow:           true,
		RequireBackupSnapshot:           true,
		RequireEntitlementFreeze:        true,
		RequireBillingStopPlan:          true,
		RequireProductionShutdownBlock:  true,
		RequireRealTenantClosureBlock:   true,
		RequireDataDeletionBlock:        true,
		RequireAutoAccessCutoffBlock:    true,
		AllowDataExportFlowDeferred:     true,
		AllowProductionApprovalDeferred: true,
		Steps: []ShutdownStep{
			step("shutdown_request_intake", EventShutdownRequestReceived, "Shutdown Request Intake"),
			step("billing_status_validate", EventBillingStatusValidated, "Billing Status Validate"),
			step("unpaid_invoice_check", EventUnpaidInvoiceChecked, "Unpaid Invoice Check"),
			dataExportDeferred("data_export_offer", EventDataExportOffered, "Data Export Offer"),
			step("legal_hold_check", EventLegalHoldChecked, "Legal Hold Check"),
			step("owner_approval_queue", EventOwnerApprovalQueued, "Owner Approval Queue"),
			step("tenant_access_freeze_plan", EventTenantAccessFreezePlanned, "Tenant Access Freeze Plan"),
			step("billing_stop_plan", EventBillingStopPlanned, "Billing Stop Plan"),
			productionDeferred("final_shutdown_deferred_marker", EventFinalShutdownDeferred, "Final Shutdown Deferred Marker"),
		},
	}
}

func step(key string, event ShutdownEvent, title string) ShutdownStep {
	return ShutdownStep{
		Key:                          key,
		Event:                        event,
		Title:                        title,
		Owner:                        "tenant_lifecycle_ops",
		Status:                       StatusReady,
		Required:                     true,
		InternalReady:                true,
		HasEvidence:                  true,
		HasCounterBasedAudit:         true,
		RequiredFailCount:            0,
		OptionalWarnCount:            0,
		ProductionShutdownEnabled:    false,
		RealTenantClosureEnabled:     false,
		DataDeletionEnabled:          false,
		AutoAccessCutoffEnabled:      false,
		RequiresTenantID:             true,
		RequiresShutdownRequestID:    true,
		RequiresBillingStatusCheck:   true,
		RequiresUnpaidInvoiceCheck:   true,
		RequiresDataExportOffer:      true,
		RequiresLegalHoldCheck:       true,
		RequiresOwnerApproval:        true,
		RequiresSupportHandoff:       true,
		RequiresCustomerTemplate:     true,
		RequiresAuditTrail:           true,
		RequiresRollbackWindow:       true,
		RequiresBackupSnapshot:       true,
		RequiresEntitlementFreeze:    true,
		RequiresBillingStopPlan:      true,
		BlocksProductionShutdown:     true,
		BlocksRealTenantClosure:      true,
		BlocksDataDeletion:           true,
		BlocksAutoAccessCutoff:       true,
		DeferredToDataExportFlow:     false,
		DeferredToProductionApproval: false,
	}
}

func dataExportDeferred(key string, event ShutdownEvent, title string) ShutdownStep {
	s := step(key, event, title)
	s.Status = StatusPendingNext
	s.InternalReady = false
	s.DeferredToDataExportFlow = true
	s.DeferredReason = "Veri export / devir akışı 261 — FAZ 5-18.5.5 içinde detaylandırılacak"
	return s
}

func productionDeferred(key string, event ShutdownEvent, title string) ShutdownStep {
	s := step(key, event, title)
	s.Status = StatusPendingNext
	s.InternalReady = false
	s.DeferredToProductionApproval = true
	s.DeferredReason = "Gerçek tenant kapatma production final approval ve veri export/devir tamamlanmadan açılmayacak"
	return s
}
