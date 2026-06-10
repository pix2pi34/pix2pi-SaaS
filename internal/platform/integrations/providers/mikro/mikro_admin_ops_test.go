package mikro

import (
	"errors"
	"testing"
)

func logMikroAdminOpsOK(t *testing.T, code string, message string) {
	t.Helper()
	t.Logf("%s %s / OK ✅", code, message)
}

func validMikroAdminOpsPackage(t *testing.T) MikroDryRunPackage {
	t.Helper()

	builder := NewMikroFileGenerationBuilder()
	pkg, decision, err := builder.BuildDryRunPackage(validMikroFileGenerationRequest(ERPObjectSalesInvoice))
	if err != nil {
		t.Fatalf("failed to build prerequisite dry-run package: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("prerequisite dry-run package decision was not allowed")
	}
	return pkg
}

func validMikroAdminOpsValidationDecision(t *testing.T) (MikroDryRunPackage, MikroValidationDecision) {
	t.Helper()

	pkg := validMikroAdminOpsPackage(t)
	validationRuntime := NewMikroValidationRetryDLQRuntime()
	validationReq := MikroValidationRequest{
		TenantID:          "tenant_7",
		ActorUserID:       "user_ops_1",
		CorrelationID:     "corr-7-8m-5-admin-ops",
		ValidationID:      "validation-7-8m-5-001",
		RequestedMode:     MikroValidationRetryDLQMode,
		Attempt:           1,
		ProviderErrorCode: MikroProviderErrorAuthFailed,
		Package:           pkg,
	}

	decision, err := validationRuntime.Evaluate(validationReq)
	if err != nil {
		t.Fatalf("failed to build prerequisite validation decision: %v", err)
	}
	if !decision.ManualReview {
		t.Fatalf("prerequisite validation decision must require manual review")
	}
	return pkg, decision
}

func validMikroManualReviewRequestForAdminOps(t *testing.T) MikroManualReviewRequest {
	t.Helper()

	pkg, validationDecision := validMikroAdminOpsValidationDecision(t)
	return MikroManualReviewRequest{
		TenantID:           "tenant_7",
		ActorUserID:        "user_ops_1",
		CorrelationID:      "corr-7-8m-5-admin-ops",
		ReviewID:           "review-7-8m-5-001",
		RequestedMode:      MikroAdminOpsMode,
		ValidationDecision: validationDecision,
		Package:            pkg,
	}
}

func validMikroOperatorActionRequestForAdminOps(action string, currentStatus string) MikroOperatorActionRequest {
	return MikroOperatorActionRequest{
		TenantID:       "tenant_7",
		ActorUserID:    "user_ops_1",
		CorrelationID:  "corr-7-8m-5-admin-ops",
		ReviewID:       "review-7-8m-5-001",
		PackageID:      "pkg-7-8m-2-001",
		CurrentStatus:  currentStatus,
		OperatorAction: action,
		OperatorNote:   "dry-run operator action note",
		RequestedMode:  MikroAdminOpsMode,
	}
}

func TestMikroAdminOpsContractMetadata(t *testing.T) {
	runtime := NewMikroAdminOpsRuntime()
	contract := runtime.Contract

	if err := contract.Validate(); err != nil {
		t.Fatalf("admin ops contract validation failed: %v", err)
	}

	logMikroAdminOpsOK(t, "7-8M.5", "Mikro Admin / Ops / Manual Review root validation")
	logMikroAdminOpsOK(t, "7-8M.5.1", "metadata validation")
	logMikroAdminOpsOK(t, "7-8M.5.1.1", "phase is FAZ_7_8M_5")
	logMikroAdminOpsOK(t, "7-8M.5.1.2", "provider identity is mikro")
	logMikroAdminOpsOK(t, "7-8M.5.1.3", "admin ops mode is ADMIN_OPS_MANUAL_REVIEW_DRY_RUN_ONLY")
	logMikroAdminOpsOK(t, "7-8M.5.1.4", "manual review queue status is READY")
	logMikroAdminOpsOK(t, "7-8M.5.1.5", "tenant-safe review boundary status is READY")
	logMikroAdminOpsOK(t, "7-8M.5.1.6", "operator action contract status is READY")
	logMikroAdminOpsOK(t, "7-8M.5.1.7", "real manual review queue write policy is closed")

	if contract.Phase != MikroAdminOpsPhase {
		t.Fatalf("phase mismatch")
	}
	if contract.ProviderID != ProviderID {
		t.Fatalf("provider id mismatch")
	}
	if contract.AdminOpsMode != MikroAdminOpsMode {
		t.Fatalf("admin ops mode mismatch")
	}
	if contract.ManualReviewQueueStatus != MikroManualReviewQueueStatus {
		t.Fatalf("manual review queue status mismatch")
	}
	if contract.TenantSafeReviewBoundaryStatus != MikroTenantSafeReviewBoundaryStatus {
		t.Fatalf("tenant safe review boundary mismatch")
	}
	if contract.OperatorActionContractStatus != MikroOperatorActionContractStatus {
		t.Fatalf("operator action contract mismatch")
	}
}

func TestMikroAdminOpsManualReviewItemCreation(t *testing.T) {
	runtime := NewMikroAdminOpsRuntime()

	item, decision, err := runtime.CreateManualReviewItem(validMikroManualReviewRequestForAdminOps(t))
	if err != nil {
		t.Fatalf("manual review item creation failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("manual review item creation must be allowed")
	}
	if decision.Reason != MikroAdminOpsDecisionReviewItemReady {
		t.Fatalf("unexpected decision reason")
	}
	if item.ReviewStatus != MikroManualReviewStatusOpen {
		t.Fatalf("new review item must start OPEN")
	}
	if !item.ManualReviewRequired {
		t.Fatalf("manual review item must preserve manual review flag")
	}
	if item.ExternalActionTaken || item.RealProviderAction {
		t.Fatalf("dry-run item must not execute external/provider action")
	}

	logMikroAdminOpsOK(t, "7-8M.5.2", "manual review item creation validation")
	logMikroAdminOpsOK(t, "7-8M.5.2.1", "validation decision creates review item")
	logMikroAdminOpsOK(t, "7-8M.5.2.2", "review item starts OPEN")
	logMikroAdminOpsOK(t, "7-8M.5.2.3", "manual review flag is preserved")
	logMikroAdminOpsOK(t, "7-8M.5.2.4", "external action is not taken")
	logMikroAdminOpsOK(t, "7-8M.5.2.5", "real provider action is not taken")
}

func TestMikroAdminOpsOperatorActions(t *testing.T) {
	runtime := NewMikroAdminOpsRuntime()

	actions := []struct {
		code           string
		action         string
		currentStatus  string
		expectedStatus string
	}{
		{"1", MikroOperatorActionView, MikroManualReviewStatusOpen, MikroManualReviewStatusOpen},
		{"2", MikroOperatorActionAssign, MikroManualReviewStatusOpen, MikroManualReviewStatusAssigned},
		{"3", MikroOperatorActionRetry, MikroManualReviewStatusAssigned, MikroManualReviewStatusRetry},
		{"4", MikroOperatorActionDLQ, MikroManualReviewStatusAssigned, MikroManualReviewStatusDLQ},
		{"5", MikroOperatorActionResolve, MikroManualReviewStatusDLQ, MikroManualReviewStatusResolved},
		{"6", MikroOperatorActionEscalate, MikroManualReviewStatusAssigned, MikroManualReviewStatusEscalated},
	}

	logMikroAdminOpsOK(t, "7-8M.5.3", "operator action contract validation")

	for _, tc := range actions {
		req := validMikroOperatorActionRequestForAdminOps(tc.action, tc.currentStatus)
		if tc.action == MikroOperatorActionView {
			req.OperatorNote = ""
		}

		decision, err := runtime.EvaluateOperatorAction(req)
		if err != nil {
			t.Fatalf("operator action %s failed: %v", tc.action, err)
		}
		if !decision.Allowed {
			t.Fatalf("operator action %s should be allowed", tc.action)
		}
		if decision.NextStatus != tc.expectedStatus {
			t.Fatalf("operator action %s expected status %s got %s", tc.action, tc.expectedStatus, decision.NextStatus)
		}
		logMikroAdminOpsOK(t, "7-8M.5.3."+tc.code, tc.action+" action maps to "+tc.expectedStatus)
	}

	badAction := validMikroOperatorActionRequestForAdminOps("REAL_PROVIDER_RETRY", MikroManualReviewStatusOpen)
	badDecision, err := runtime.EvaluateOperatorAction(badAction)
	if err != nil {
		t.Fatalf("unsupported action should deny without runtime error: %v", err)
	}
	if badDecision.Allowed || badDecision.Reason != MikroAdminOpsDecisionUnsupportedAction {
		t.Fatalf("unsupported action must be denied")
	}
	logMikroAdminOpsOK(t, "7-8M.5.3.7", "unsupported real provider action is denied")

	badTransition := validMikroOperatorActionRequestForAdminOps(MikroOperatorActionAssign, MikroManualReviewStatusResolved)
	badTransitionDecision, err := runtime.EvaluateOperatorAction(badTransition)
	if err != nil {
		t.Fatalf("bad transition should deny without runtime error: %v", err)
	}
	if badTransitionDecision.Allowed || badTransitionDecision.Reason != MikroAdminOpsDecisionInvalidTransition {
		t.Fatalf("invalid transition must be denied")
	}
	logMikroAdminOpsOK(t, "7-8M.5.3.8", "invalid status transition is denied")
}

func TestMikroAdminOpsClosedRealOperations(t *testing.T) {
	runtime := NewMikroAdminOpsRuntime()
	contract := runtime.Contract

	if contract.RealProviderAPIStatus != MikroRealProviderAPIStatus {
		t.Fatalf("real provider API must stay closed")
	}
	if contract.RealFileDeliveryStatus != MikroRealFileDeliveryStatus {
		t.Fatalf("real file delivery must stay closed")
	}
	if contract.RealERPWriteStatus != MikroRealERPWriteStatus {
		t.Fatalf("real ERP write must stay closed")
	}
	if contract.RealDeliveryChannelStatus != MikroRealDeliveryChannelStatus {
		t.Fatalf("real delivery channel must stay closed")
	}
	if contract.RealOperatorProviderActionStatus != MikroRealOperatorProviderActionStatus {
		t.Fatalf("real operator provider action must stay closed")
	}

	logMikroAdminOpsOK(t, "7-8M.5.4", "closed real operation gates validation")
	logMikroAdminOpsOK(t, "7-8M.5.4.1", "real Mikro provider API is closed")
	logMikroAdminOpsOK(t, "7-8M.5.4.2", "real Mikro file delivery is closed")
	logMikroAdminOpsOK(t, "7-8M.5.4.3", "real ERP write is closed")
	logMikroAdminOpsOK(t, "7-8M.5.4.4", "real delivery channel is closed")
	logMikroAdminOpsOK(t, "7-8M.5.4.5", "real operator provider action is closed")

	apiReq := validMikroManualReviewRequestForAdminOps(t)
	apiReq.RealProviderAPIEnabled = true
	_, apiDecision, err := runtime.CreateManualReviewItem(apiReq)
	if err != nil {
		t.Fatalf("real api decision should deny without runtime error: %v", err)
	}
	if apiDecision.Allowed || apiDecision.Reason != MikroAdminOpsDecisionRealProviderAPI {
		t.Fatalf("real provider API must be denied")
	}
	logMikroAdminOpsOK(t, "7-8M.5.4.6", "real Mikro API request is denied")

	fileReq := validMikroOperatorActionRequestForAdminOps(MikroOperatorActionRetry, MikroManualReviewStatusAssigned)
	fileReq.RealFileDeliveryEnabled = true
	fileDecision, err := runtime.EvaluateOperatorAction(fileReq)
	if err != nil {
		t.Fatalf("real file delivery decision should deny without runtime error: %v", err)
	}
	if fileDecision.Allowed || fileDecision.Reason != MikroAdminOpsDecisionRealFileDelivery {
		t.Fatalf("real file delivery must be denied")
	}
	logMikroAdminOpsOK(t, "7-8M.5.4.7", "real Mikro file delivery request is denied")

	erpReq := validMikroOperatorActionRequestForAdminOps(MikroOperatorActionRetry, MikroManualReviewStatusAssigned)
	erpReq.RealERPWriteEnabled = true
	erpDecision, err := runtime.EvaluateOperatorAction(erpReq)
	if err != nil {
		t.Fatalf("real ERP write decision should deny without runtime error: %v", err)
	}
	if erpDecision.Allowed || erpDecision.Reason != MikroAdminOpsDecisionRealERPWrite {
		t.Fatalf("real ERP write must be denied")
	}
	logMikroAdminOpsOK(t, "7-8M.5.4.8", "real ERP write request is denied")

	operatorReq := validMikroOperatorActionRequestForAdminOps(MikroOperatorActionRetry, MikroManualReviewStatusAssigned)
	operatorReq.RealOperatorProviderActionEnabled = true
	operatorDecision, err := runtime.EvaluateOperatorAction(operatorReq)
	if err != nil {
		t.Fatalf("real operator provider action decision should deny without runtime error: %v", err)
	}
	if operatorDecision.Allowed || operatorDecision.Reason != MikroAdminOpsDecisionRealProviderAction {
		t.Fatalf("real operator provider action must be denied")
	}
	logMikroAdminOpsOK(t, "7-8M.5.4.9", "real operator provider action request is denied")
}

func TestMikroAdminOpsRequestAndSecretGuards(t *testing.T) {
	runtime := NewMikroAdminOpsRuntime()

	missingReview := validMikroManualReviewRequestForAdminOps(t)
	missingReview.ReviewID = ""
	_, _, err := runtime.CreateManualReviewItem(missingReview)
	if err == nil {
		t.Fatalf("missing review id must fail")
	}
	logMikroAdminOpsOK(t, "7-8M.5.5", "request and secret guard validation")
	logMikroAdminOpsOK(t, "7-8M.5.5.1", "missing review id is rejected")

	missingNote := validMikroOperatorActionRequestForAdminOps(MikroOperatorActionAssign, MikroManualReviewStatusOpen)
	missingNote.OperatorNote = ""
	_, err = runtime.EvaluateOperatorAction(missingNote)
	if err == nil {
		t.Fatalf("missing operator note must fail for mutating action")
	}
	logMikroAdminOpsOK(t, "7-8M.5.5.2", "missing operator note is rejected for mutating action")

	liveMode := validMikroOperatorActionRequestForAdminOps(MikroOperatorActionAssign, MikroManualReviewStatusOpen)
	liveMode.RequestedMode = "PROVIDER_LIVE"
	liveDecision, err := runtime.EvaluateOperatorAction(liveMode)
	if err != nil {
		t.Fatalf("provider live mode should deny without runtime error: %v", err)
	}
	if liveDecision.Allowed || liveDecision.Reason != MikroAdminOpsDecisionProviderLiveModeClosed {
		t.Fatalf("provider live mode must be denied")
	}
	logMikroAdminOpsOK(t, "7-8M.5.5.3", "provider live mode is denied")

	secretReq := validMikroOperatorActionRequestForAdminOps(MikroOperatorActionAssign, MikroManualReviewStatusOpen)
	secretReq.InjectedFieldName = "client_secret"
	_, err = runtime.EvaluateOperatorAction(secretReq)
	if !errors.Is(err, ErrMikroAdminOpsSecretForbidden) {
		t.Fatalf("client_secret field must be forbidden")
	}
	logMikroAdminOpsOK(t, "7-8M.5.5.4", "client_secret field is rejected")
}
