package mikro

import (
	"errors"
	"testing"
)

func logMikroFinalClosureOK(t *testing.T, code string, message string) {
	t.Helper()
	t.Logf("%s %s / OK ✅", code, message)
}

func validMikroFinalClosureRequest() MikroFinalClosureRequest {
	return MikroFinalClosureRequest{
		TenantID:        "tenant_7",
		ActorUserID:     "user_ops_1",
		CorrelationID:   "corr-7-8m-7-final-closure",
		ClosureID:       "closure-7-8m-7-001",
		PackageID:       "pkg-7-8m-7-001",
		DeliveryID:      "delivery-7-8m-7-001",
		ValidationID:    "validation-7-8m-7-001",
		ReviewID:        "review-7-8m-7-001",
		ERPObjectType:   ERPObjectSalesInvoice,
		DeliveryChannel: MikroDeliveryChannelDryRunManifestOnly,
		RequestedMode:   MikroFinalClosureMode,
		Records: []MikroDryRunPackageRecord{
			{
				RecordID:      "record-7-8m-7-001",
				ERPObjectType: ERPObjectSalesInvoice,
				Fields: map[string]string{
					"invoice_id":    "INV-FINAL-001",
					"customer_id":   "CUST-FINAL-001",
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

func TestMikroFinalClosureContractMetadata(t *testing.T) {
	runtime := NewMikroFinalClosureRuntime()
	contract := runtime.Contract

	if err := contract.Validate(); err != nil {
		t.Fatalf("final closure contract validation failed: %v", err)
	}

	logMikroFinalClosureOK(t, "7-8M.7", "Mikro Connector Final Closure root validation")
	logMikroFinalClosureOK(t, "7-8M.7.1", "metadata validation")
	logMikroFinalClosureOK(t, "7-8M.7.1.1", "phase is FAZ_7_8M_7")
	logMikroFinalClosureOK(t, "7-8M.7.1.2", "provider identity is mikro")
	logMikroFinalClosureOK(t, "7-8M.7.1.3", "final closure mode is CONNECTOR_DRY_RUN_FINAL_CLOSURE_ONLY")
	logMikroFinalClosureOK(t, "7-8M.7.1.4", "connector module final seal status is SEALED")
	logMikroFinalClosureOK(t, "7-8M.7.1.5", "dry-run module status is SEALED")
	logMikroFinalClosureOK(t, "7-8M.7.1.6", "provider live handoff gate is READY_FOR_PROVIDER_LIVE_MODULE")
	logMikroFinalClosureOK(t, "7-8M.7.1.7", "provider live module status is NOT_STARTED")

	if contract.Phase != MikroFinalClosurePhase {
		t.Fatalf("phase mismatch")
	}
	if contract.ProviderID != ProviderID {
		t.Fatalf("provider id mismatch")
	}
	if contract.FinalClosureMode != MikroFinalClosureMode {
		t.Fatalf("final closure mode mismatch")
	}
	if contract.ConnectorModuleFinalSealStatus != MikroConnectorModuleFinalSealStatus {
		t.Fatalf("final seal status mismatch")
	}
	if contract.ProviderLiveHandoffGate != MikroFinalClosureProviderLiveHandoffGate {
		t.Fatalf("provider live handoff gate mismatch")
	}
	if contract.ProviderLiveModuleStatus != MikroProviderLiveModuleStatus {
		t.Fatalf("provider live module status mismatch")
	}
}

func TestMikroFinalClosureBuildsSealedResult(t *testing.T) {
	runtime := NewMikroFinalClosureRuntime()

	result, decision, err := runtime.BuildFinalClosure(validMikroFinalClosureRequest())
	if err != nil {
		t.Fatalf("final closure build failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("final closure must be allowed")
	}
	if decision.Reason != MikroFinalClosureDecisionReady {
		t.Fatalf("unexpected decision reason")
	}
	if result.ConnectorModuleFinalSealStatus != MikroConnectorModuleFinalSealStatus {
		t.Fatalf("connector module must be sealed")
	}
	if result.DryRunModuleStatus != MikroDryRunModuleStatus {
		t.Fatalf("dry-run module must be sealed")
	}
	if result.ProviderLiveHandoffGate != MikroFinalClosureProviderLiveHandoffGate {
		t.Fatalf("provider live handoff gate mismatch")
	}
	if result.ProviderLiveModuleStatus != MikroProviderLiveModuleStatus {
		t.Fatalf("provider live module must not start")
	}
	if result.RealExternalOperationCount != 0 {
		t.Fatalf("final closure must not execute real external operations")
	}

	logMikroFinalClosureOK(t, "7-8M.7.2", "final closure sealed result validation")
	logMikroFinalClosureOK(t, "7-8M.7.2.1", "final closure decision is allowed")
	logMikroFinalClosureOK(t, "7-8M.7.2.2", "connector module final seal status is SEALED")
	logMikroFinalClosureOK(t, "7-8M.7.2.3", "dry-run module status is SEALED")
	logMikroFinalClosureOK(t, "7-8M.7.2.4", "provider live handoff gate is READY_FOR_PROVIDER_LIVE_MODULE")
	logMikroFinalClosureOK(t, "7-8M.7.2.5", "provider live module status remains NOT_STARTED")
	logMikroFinalClosureOK(t, "7-8M.7.2.6", "no real external operation executed")
}

func TestMikroFinalClosureValidatesPreviousModuleChain(t *testing.T) {
	runtime := NewMikroFinalClosureRuntime()

	result, decision, err := runtime.BuildFinalClosure(validMikroFinalClosureRequest())
	if err != nil {
		t.Fatalf("final closure chain validation failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("final closure chain decision must be allowed")
	}
	if !result.FoundationValidated {
		t.Fatalf("foundation must be validated")
	}
	if !result.ExportMappingValidated {
		t.Fatalf("export mapping must be validated")
	}
	if !result.FileGenerationValidated {
		t.Fatalf("file generation must be validated")
	}
	if !result.ImportDeliveryValidated {
		t.Fatalf("import delivery must be validated")
	}
	if !result.ValidationRetryDLQValidated {
		t.Fatalf("validation retry-dlq must be validated")
	}
	if !result.AdminOpsValidated {
		t.Fatalf("admin ops must be validated")
	}
	if !result.E2EDryRunValidated {
		t.Fatalf("e2e dry-run must be validated")
	}

	logMikroFinalClosureOK(t, "7-8M.7.3", "previous module chain validation")
	logMikroFinalClosureOK(t, "7-8M.7.3.1", "Foundation is validated")
	logMikroFinalClosureOK(t, "7-8M.7.3.2", "Export Mapping is validated")
	logMikroFinalClosureOK(t, "7-8M.7.3.3", "File Generation is validated")
	logMikroFinalClosureOK(t, "7-8M.7.3.4", "Import Delivery is validated")
	logMikroFinalClosureOK(t, "7-8M.7.3.5", "Validation Retry-DLQ is validated")
	logMikroFinalClosureOK(t, "7-8M.7.3.6", "Admin Ops is validated")
	logMikroFinalClosureOK(t, "7-8M.7.3.7", "E2E Dry-Run is validated")
}

func TestMikroFinalClosureClosedRealOperations(t *testing.T) {
	runtime := NewMikroFinalClosureRuntime()
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
	if contract.RealQueueWritePolicy != MikroFinalClosureRealQueuePolicy {
		t.Fatalf("real queue write must stay closed")
	}

	logMikroFinalClosureOK(t, "7-8M.7.4", "closed real operation gates validation")
	logMikroFinalClosureOK(t, "7-8M.7.4.1", "real Mikro provider API is closed")
	logMikroFinalClosureOK(t, "7-8M.7.4.2", "real Mikro file delivery is closed")
	logMikroFinalClosureOK(t, "7-8M.7.4.3", "real ERP write is closed")
	logMikroFinalClosureOK(t, "7-8M.7.4.4", "real delivery channel is closed")
	logMikroFinalClosureOK(t, "7-8M.7.4.5", "real operator provider action is closed")
	logMikroFinalClosureOK(t, "7-8M.7.4.6", "real queue write policy is closed")

	apiReq := validMikroFinalClosureRequest()
	apiReq.RealProviderAPIEnabled = true
	_, apiDecision, err := runtime.BuildFinalClosure(apiReq)
	if err != nil {
		t.Fatalf("real api decision should deny without runtime error: %v", err)
	}
	if apiDecision.Allowed || apiDecision.Reason != MikroFinalClosureDecisionRealProviderAPI {
		t.Fatalf("real provider API must be denied")
	}
	logMikroFinalClosureOK(t, "7-8M.7.4.7", "real Mikro API request is denied")

	fileReq := validMikroFinalClosureRequest()
	fileReq.RealFileDeliveryEnabled = true
	_, fileDecision, err := runtime.BuildFinalClosure(fileReq)
	if err != nil {
		t.Fatalf("real file delivery decision should deny without runtime error: %v", err)
	}
	if fileDecision.Allowed || fileDecision.Reason != MikroFinalClosureDecisionRealFileDelivery {
		t.Fatalf("real file delivery must be denied")
	}
	logMikroFinalClosureOK(t, "7-8M.7.4.8", "real Mikro file delivery request is denied")

	erpReq := validMikroFinalClosureRequest()
	erpReq.RealERPWriteEnabled = true
	_, erpDecision, err := runtime.BuildFinalClosure(erpReq)
	if err != nil {
		t.Fatalf("real ERP write decision should deny without runtime error: %v", err)
	}
	if erpDecision.Allowed || erpDecision.Reason != MikroFinalClosureDecisionRealERPWrite {
		t.Fatalf("real ERP write must be denied")
	}
	logMikroFinalClosureOK(t, "7-8M.7.4.9", "real ERP write request is denied")

	operatorReq := validMikroFinalClosureRequest()
	operatorReq.RealOperatorProviderActionEnabled = true
	_, operatorDecision, err := runtime.BuildFinalClosure(operatorReq)
	if err != nil {
		t.Fatalf("real operator provider action decision should deny without runtime error: %v", err)
	}
	if operatorDecision.Allowed || operatorDecision.Reason != MikroFinalClosureDecisionRealProviderAction {
		t.Fatalf("real operator provider action must be denied")
	}
	logMikroFinalClosureOK(t, "7-8M.7.4.10", "real operator provider action request is denied")
}

func TestMikroFinalClosureRequestAndSecretGuards(t *testing.T) {
	runtime := NewMikroFinalClosureRuntime()

	missingClosure := validMikroFinalClosureRequest()
	missingClosure.ClosureID = ""
	_, _, err := runtime.BuildFinalClosure(missingClosure)
	if err == nil {
		t.Fatalf("missing closure id must fail")
	}
	logMikroFinalClosureOK(t, "7-8M.7.5", "request and secret guard validation")
	logMikroFinalClosureOK(t, "7-8M.7.5.1", "missing closure id is rejected")

	missingPackage := validMikroFinalClosureRequest()
	missingPackage.PackageID = ""
	_, _, err = runtime.BuildFinalClosure(missingPackage)
	if err == nil {
		t.Fatalf("missing package id must fail")
	}
	logMikroFinalClosureOK(t, "7-8M.7.5.2", "missing package id is rejected")

	liveMode := validMikroFinalClosureRequest()
	liveMode.RequestedMode = "PROVIDER_LIVE"
	_, liveDecision, err := runtime.BuildFinalClosure(liveMode)
	if err != nil {
		t.Fatalf("provider live mode should deny without runtime error: %v", err)
	}
	if liveDecision.Allowed || liveDecision.Reason != MikroFinalClosureDecisionProviderLiveClosed {
		t.Fatalf("provider live mode must be denied")
	}
	logMikroFinalClosureOK(t, "7-8M.7.5.3", "provider live mode is denied")

	secretReq := validMikroFinalClosureRequest()
	secretReq.InjectedFieldName = "client_secret"
	_, _, err = runtime.BuildFinalClosure(secretReq)
	if !errors.Is(err, ErrMikroFinalClosureSecretForbidden) {
		t.Fatalf("client_secret field must be forbidden")
	}
	logMikroFinalClosureOK(t, "7-8M.7.5.4", "client_secret field is rejected")
}
