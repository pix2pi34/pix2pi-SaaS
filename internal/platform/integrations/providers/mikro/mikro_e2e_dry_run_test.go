package mikro

import (
	"errors"
	"testing"
)

func logMikroE2EOK(t *testing.T, code string, message string) {
	t.Helper()
	t.Logf("%s %s / OK ✅", code, message)
}

func validMikroE2ERequest() MikroE2EDryRunRequest {
	return MikroE2EDryRunRequest{
		TenantID:        "tenant_7",
		ActorUserID:     "user_ops_1",
		CorrelationID:   "corr-7-8m-6-e2e",
		PackageID:       "pkg-7-8m-6-001",
		DeliveryID:      "delivery-7-8m-6-001",
		ValidationID:    "validation-7-8m-6-001",
		ReviewID:        "review-7-8m-6-001",
		ERPObjectType:   ERPObjectSalesInvoice,
		DeliveryChannel: MikroDeliveryChannelDryRunManifestOnly,
		RequestedMode:   MikroE2EDryRunMode,
		Records: []MikroDryRunPackageRecord{
			{
				RecordID:      "record-7-8m-6-001",
				ERPObjectType: ERPObjectSalesInvoice,
				Fields: map[string]string{
					"invoice_id":    "INV-E2E-001",
					"customer_id":   "CUST-E2E-001",
					"issue_date":    "2026-05-02",
					"net_total":     "10000",
					"tax_total":     "2000",
					"gross_total":   "12000",
					"currency_code": "TRY",
				},
			},
		},
	}
}

func TestMikroE2EDryRunContractMetadata(t *testing.T) {
	runtime := NewMikroE2EDryRunRuntime()
	contract := runtime.Contract

	if err := contract.Validate(); err != nil {
		t.Fatalf("e2e dry-run contract validation failed: %v", err)
	}

	logMikroE2EOK(t, "7-8M.6", "Mikro E2E Dry-Run Flow root validation")
	logMikroE2EOK(t, "7-8M.6.1", "metadata validation")
	logMikroE2EOK(t, "7-8M.6.1.1", "phase is FAZ_7_8M_6")
	logMikroE2EOK(t, "7-8M.6.1.2", "provider identity is mikro")
	logMikroE2EOK(t, "7-8M.6.1.3", "e2e mode is E2E_DRY_RUN_ONLY")
	logMikroE2EOK(t, "7-8M.6.1.4", "direction is PIX2PI_TO_MIKRO")
	logMikroE2EOK(t, "7-8M.6.1.5", "target system is MIKRO_ACCOUNTING_IMPORT_DRY_RUN")
	logMikroE2EOK(t, "7-8M.6.1.6", "chain status is READY")
	logMikroE2EOK(t, "7-8M.6.1.7", "closure preparation status is READY")

	if contract.Phase != MikroE2EDryRunPhase {
		t.Fatalf("phase mismatch")
	}
	if contract.ProviderID != ProviderID {
		t.Fatalf("provider id mismatch")
	}
	if contract.E2EMode != MikroE2EDryRunMode {
		t.Fatalf("e2e mode mismatch")
	}
	if contract.ChainStatus != MikroE2EChainStatusReady {
		t.Fatalf("chain status mismatch")
	}
	if contract.ClosurePreparationStatus != MikroE2EClosurePrepReady {
		t.Fatalf("closure prep mismatch")
	}
}

func TestMikroE2EDryRunHappyPath(t *testing.T) {
	runtime := NewMikroE2EDryRunRuntime()

	result, decision, err := runtime.Run(validMikroE2ERequest())
	if err != nil {
		t.Fatalf("e2e happy path failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("e2e happy path must be allowed")
	}
	if decision.Reason != MikroE2EDecisionReady {
		t.Fatalf("unexpected e2e decision reason")
	}
	if result.RealExternalOperationCount != 0 {
		t.Fatalf("e2e dry-run must not execute external operations")
	}
	if !result.FoundationValidated || !result.MappingValidated || !result.PackageBuilt || !result.DeliveryReceiptCreated || !result.ValidationEvaluated {
		t.Fatalf("e2e happy path did not complete required chain steps")
	}
	if result.ManualReviewItemCreated {
		t.Fatalf("happy path should not create manual review item")
	}
	if len(decision.ExecutedSteps) < 5 {
		t.Fatalf("executed steps should include core chain")
	}

	logMikroE2EOK(t, "7-8M.6.2", "happy path e2e dry-run validation")
	logMikroE2EOK(t, "7-8M.6.2.1", "foundation validation step completed")
	logMikroE2EOK(t, "7-8M.6.2.2", "export mapping step completed")
	logMikroE2EOK(t, "7-8M.6.2.3", "file generation package build completed")
	logMikroE2EOK(t, "7-8M.6.2.4", "import delivery receipt completed")
	logMikroE2EOK(t, "7-8M.6.2.5", "validation retry-DLQ step completed")
	logMikroE2EOK(t, "7-8M.6.2.6", "no real external operation executed")
}

func TestMikroE2EDryRunManualReviewFlow(t *testing.T) {
	runtime := NewMikroE2EDryRunRuntime()

	req := validMikroE2ERequest()
	req.ProviderErrorCode = MikroProviderErrorAuthFailed
	req.OperatorAction = MikroOperatorActionAssign
	req.OperatorNote = "dry-run assign for auth failure manual review"

	result, decision, err := runtime.Run(req)
	if err != nil {
		t.Fatalf("e2e manual review flow failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("manual review e2e flow must be allowed")
	}
	if decision.Reason != MikroE2EDecisionManualReviewReady {
		t.Fatalf("unexpected manual review e2e decision reason")
	}
	if !result.ManualReviewItemCreated {
		t.Fatalf("manual review item must be created")
	}
	if !result.OperatorActionEvaluated {
		t.Fatalf("operator action must be evaluated")
	}
	if result.ManualReviewItem.ReviewStatus != MikroManualReviewStatusOpen {
		t.Fatalf("manual review item should start open")
	}
	if result.OperatorActionDecision.NextStatus != MikroManualReviewStatusAssigned {
		t.Fatalf("operator action should assign review item")
	}
	if result.RealExternalOperationCount != 0 {
		t.Fatalf("manual review dry-run must not execute external operations")
	}

	logMikroE2EOK(t, "7-8M.6.3", "manual review e2e dry-run validation")
	logMikroE2EOK(t, "7-8M.6.3.1", "provider auth error maps to manual review")
	logMikroE2EOK(t, "7-8M.6.3.2", "manual review item is created")
	logMikroE2EOK(t, "7-8M.6.3.3", "operator action is evaluated")
	logMikroE2EOK(t, "7-8M.6.3.4", "ASSIGN action maps review item to ASSIGNED")
	logMikroE2EOK(t, "7-8M.6.3.5", "manual review flow executes no external operation")
}

func TestMikroE2EDryRunRetryAndDLQFlows(t *testing.T) {
	runtime := NewMikroE2EDryRunRuntime()

	retryReq := validMikroE2ERequest()
	retryReq.ProviderErrorCode = MikroProviderErrorTimeout
	retryResult, retryDecision, err := runtime.Run(retryReq)
	if err != nil {
		t.Fatalf("retry e2e flow failed: %v", err)
	}
	if !retryDecision.Allowed || retryDecision.Reason != MikroE2EDecisionRetryReady {
		t.Fatalf("retry flow must be ready")
	}
	if retryResult.ValidationDecision.Action != MikroValidationActionRetry {
		t.Fatalf("retry flow final validation action must be retry")
	}
	logMikroE2EOK(t, "7-8M.6.4", "retry and DLQ e2e dry-run validation")
	logMikroE2EOK(t, "7-8M.6.4.1", "MIKRO_TIMEOUT maps to retry e2e flow")

	dlqReq := validMikroE2ERequest()
	dlqReq.ProviderErrorCode = MikroProviderErrorFormat
	dlqReq.OperatorAction = MikroOperatorActionDLQ
	dlqReq.OperatorNote = "dry-run mark dlq for format error"
	dlqResult, dlqDecision, err := runtime.Run(dlqReq)
	if err != nil {
		t.Fatalf("DLQ e2e flow failed: %v", err)
	}
	if !dlqDecision.Allowed || dlqDecision.Reason != MikroE2EDecisionDLQReady {
		t.Fatalf("DLQ flow must be ready")
	}
	if !dlqResult.ManualReviewItemCreated {
		t.Fatalf("DLQ flow must create review item bridge")
	}
	if dlqResult.OperatorActionDecision.NextStatus != MikroManualReviewStatusDLQ {
		t.Fatalf("DLQ operator action should move to DLQ_DRY_RUN")
	}
	logMikroE2EOK(t, "7-8M.6.4.2", "MIKRO_FORMAT_ERROR maps to DLQ e2e flow")
	logMikroE2EOK(t, "7-8M.6.4.3", "DLQ e2e flow creates review item bridge")
	logMikroE2EOK(t, "7-8M.6.4.4", "MARK_DLQ_DRY_RUN action maps to DLQ_DRY_RUN")
}

func TestMikroE2EDryRunClosedRealOperations(t *testing.T) {
	runtime := NewMikroE2EDryRunRuntime()
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

	logMikroE2EOK(t, "7-8M.6.5", "closed real operation gates validation")
	logMikroE2EOK(t, "7-8M.6.5.1", "real Mikro provider API is closed")
	logMikroE2EOK(t, "7-8M.6.5.2", "real Mikro file delivery is closed")
	logMikroE2EOK(t, "7-8M.6.5.3", "real ERP write is closed")
	logMikroE2EOK(t, "7-8M.6.5.4", "real delivery channel is closed")
	logMikroE2EOK(t, "7-8M.6.5.5", "real operator provider action is closed")

	apiReq := validMikroE2ERequest()
	apiReq.RealProviderAPIEnabled = true
	_, apiDecision, err := runtime.Run(apiReq)
	if err != nil {
		t.Fatalf("real api decision should deny without runtime error: %v", err)
	}
	if apiDecision.Allowed || apiDecision.Reason != MikroE2EDecisionRealProviderAPI {
		t.Fatalf("real provider API must be denied")
	}
	logMikroE2EOK(t, "7-8M.6.5.6", "real Mikro API request is denied")

	fileReq := validMikroE2ERequest()
	fileReq.RealFileDeliveryEnabled = true
	_, fileDecision, err := runtime.Run(fileReq)
	if err != nil {
		t.Fatalf("real file delivery decision should deny without runtime error: %v", err)
	}
	if fileDecision.Allowed || fileDecision.Reason != MikroE2EDecisionRealFileDelivery {
		t.Fatalf("real file delivery must be denied")
	}
	logMikroE2EOK(t, "7-8M.6.5.7", "real Mikro file delivery request is denied")

	erpReq := validMikroE2ERequest()
	erpReq.RealERPWriteEnabled = true
	_, erpDecision, err := runtime.Run(erpReq)
	if err != nil {
		t.Fatalf("real ERP write decision should deny without runtime error: %v", err)
	}
	if erpDecision.Allowed || erpDecision.Reason != MikroE2EDecisionRealERPWrite {
		t.Fatalf("real ERP write must be denied")
	}
	logMikroE2EOK(t, "7-8M.6.5.8", "real ERP write request is denied")

	operatorReq := validMikroE2ERequest()
	operatorReq.RealOperatorProviderActionEnabled = true
	_, operatorDecision, err := runtime.Run(operatorReq)
	if err != nil {
		t.Fatalf("real operator provider action decision should deny without runtime error: %v", err)
	}
	if operatorDecision.Allowed || operatorDecision.Reason != MikroE2EDecisionRealProviderAction {
		t.Fatalf("real operator provider action must be denied")
	}
	logMikroE2EOK(t, "7-8M.6.5.9", "real operator provider action request is denied")
}

func TestMikroE2EDryRunRequestAndSecretGuards(t *testing.T) {
	runtime := NewMikroE2EDryRunRuntime()

	missingPackage := validMikroE2ERequest()
	missingPackage.PackageID = ""
	_, _, err := runtime.Run(missingPackage)
	if err == nil {
		t.Fatalf("missing package id must fail")
	}
	logMikroE2EOK(t, "7-8M.6.6", "request and secret guard validation")
	logMikroE2EOK(t, "7-8M.6.6.1", "missing package id is rejected")

	missingNote := validMikroE2ERequest()
	missingNote.ProviderErrorCode = MikroProviderErrorAuthFailed
	missingNote.OperatorAction = MikroOperatorActionAssign
	missingNote.OperatorNote = ""
	_, _, err = runtime.Run(missingNote)
	if err == nil {
		t.Fatalf("operator note must be required when operator action is provided")
	}
	logMikroE2EOK(t, "7-8M.6.6.2", "missing operator note is rejected")

	liveMode := validMikroE2ERequest()
	liveMode.RequestedMode = "PROVIDER_LIVE"
	_, liveDecision, err := runtime.Run(liveMode)
	if err != nil {
		t.Fatalf("provider live mode should deny without runtime error: %v", err)
	}
	if liveDecision.Allowed || liveDecision.Reason != MikroE2EDecisionProviderLiveClosed {
		t.Fatalf("provider live mode must be denied")
	}
	logMikroE2EOK(t, "7-8M.6.6.3", "provider live mode is denied")

	secretReq := validMikroE2ERequest()
	secretReq.InjectedFieldName = "client_secret"
	_, _, err = runtime.Run(secretReq)
	if !errors.Is(err, ErrMikroE2EDryRunSecretForbidden) {
		t.Fatalf("client_secret field must be forbidden")
	}
	logMikroE2EOK(t, "7-8M.6.6.4", "client_secret field is rejected")
}
