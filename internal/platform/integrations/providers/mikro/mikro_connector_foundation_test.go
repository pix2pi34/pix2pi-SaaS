package mikro

import (
	"errors"
	"testing"
)

func logOK(t *testing.T, code string, message string) {
	t.Helper()
	t.Logf("%s %s / OK ✅", code, message)
}

func validRequest(operation string) FoundationRequest {
	return FoundationRequest{
		TenantID:      "tenant_7",
		ActorUserID:   "user_ops_1",
		CorrelationID: "corr-7-8m-foundation",
		Operation:     operation,
		RequestedMode: ConnectorModeDryRunContract,
	}
}

func TestMikroConnectorFoundationMetadata(t *testing.T) {
	foundation := NewFoundation()

	if err := foundation.Validate(); err != nil {
		t.Fatalf("foundation validation failed: %v", err)
	}
	logOK(t, "7-8M", "Mikro Connector Module Foundation root validation")
	logOK(t, "7-8M.1", "foundation metadata validation")
	logOK(t, "7-8M.1.1", "phase is FAZ_7_8M")
	logOK(t, "7-8M.1.2", "provider identity is mikro")
	logOK(t, "7-8M.1.3", "provider name is Mikro")
	logOK(t, "7-8M.1.4", "module status is READY")
	logOK(t, "7-8M.1.5", "connector mode is DRY_RUN_CONTRACT_ONLY")

	if foundation.Phase != Phase {
		t.Fatalf("phase mismatch")
	}
	if foundation.ProviderID != ProviderID {
		t.Fatalf("provider id mismatch")
	}
	if foundation.ProviderName != ProviderName {
		t.Fatalf("provider name mismatch")
	}
	if foundation.ModuleStatus != ModuleStatusReady {
		t.Fatalf("module status mismatch")
	}
	if foundation.ConnectorMode != ConnectorModeDryRunContract {
		t.Fatalf("connector mode mismatch")
	}
}

func TestMikroConnectorClosedRealOperations(t *testing.T) {
	foundation := NewFoundation()

	if foundation.RealProviderAPIStatus != MikroRealProviderAPIStatus {
		t.Fatalf("real provider api must stay closed")
	}
	logOK(t, "7-8M.2", "real operation gates validation")
	logOK(t, "7-8M.2.1", "real Mikro provider API is closed")

	if foundation.RealFileDeliveryStatus != MikroRealFileDeliveryStatus {
		t.Fatalf("real file delivery must stay closed")
	}
	logOK(t, "7-8M.2.2", "real Mikro file delivery is closed")

	if foundation.RealERPWriteStatus != MikroRealERPWriteStatus {
		t.Fatalf("real ERP write must stay closed")
	}
	logOK(t, "7-8M.2.3", "real ERP write is closed")

	if foundation.ProviderLiveHandoffGate != MikroProviderLiveHandoffGate {
		t.Fatalf("provider live handoff gate must stay closed until final closure")
	}
	logOK(t, "7-8M.2.4", "provider live handoff gate is closed until Mikro final closure")

	reqAPI := validRequest("INVOICE_EXPORT")
	reqAPI.RealProviderAPIEnabled = true
	decisionAPI, err := foundation.Evaluate(reqAPI)
	if err != nil {
		t.Fatalf("real api decision should deny without runtime error: %v", err)
	}
	if decisionAPI.Allowed || decisionAPI.Reason != DecisionDeniedRealAPICall {
		t.Fatalf("real api request must be denied")
	}
	logOK(t, "7-8M.2.5", "real Mikro API request is denied")

	reqDelivery := validRequest("INVOICE_EXPORT")
	reqDelivery.RealFileDeliveryEnabled = true
	decisionDelivery, err := foundation.Evaluate(reqDelivery)
	if err != nil {
		t.Fatalf("real file delivery decision should deny without runtime error: %v", err)
	}
	if decisionDelivery.Allowed || decisionDelivery.Reason != DecisionDeniedFileDelivery {
		t.Fatalf("real file delivery request must be denied")
	}
	logOK(t, "7-8M.2.6", "real Mikro file delivery request is denied")

	reqERP := validRequest("INVOICE_EXPORT")
	reqERP.RealERPWriteEnabled = true
	decisionERP, err := foundation.Evaluate(reqERP)
	if err != nil {
		t.Fatalf("real ERP write decision should deny without runtime error: %v", err)
	}
	if decisionERP.Allowed || decisionERP.Reason != DecisionDeniedERPWrite {
		t.Fatalf("real ERP write request must be denied")
	}
	logOK(t, "7-8M.2.7", "real ERP write request is denied")
}

func TestMikroConnectorDryRunDecisionRuntime(t *testing.T) {
	foundation := NewFoundation()

	decision, err := foundation.Evaluate(validRequest("INVOICE_EXPORT"))
	if err != nil {
		t.Fatalf("dry-run decision failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("dry-run operation must be allowed")
	}
	if decision.Reason != DecisionAllowedDryRunReady {
		t.Fatalf("unexpected dry-run decision reason")
	}
	logOK(t, "7-8M.3", "dry-run decision runtime validation")
	logOK(t, "7-8M.3.1", "INVOICE_EXPORT dry-run is allowed")
	logOK(t, "7-8M.3.2", "decision reason is MIKRO_DRY_RUN_FOUNDATION_READY")

	if decision.AuditFields["tenant_id"] != "tenant_7" {
		t.Fatalf("tenant audit field missing")
	}
	if decision.AuditFields["correlation_id"] != "corr-7-8m-foundation" {
		t.Fatalf("correlation audit field missing")
	}
	if decision.AuditFields["actor_user_id"] != "user_ops_1" {
		t.Fatalf("actor audit field missing")
	}
	logOK(t, "7-8M.3.3", "tenant audit field is present")
	logOK(t, "7-8M.3.4", "correlation audit field is present")
	logOK(t, "7-8M.3.5", "actor audit field is present")

	missingTenant := validRequest("INVOICE_EXPORT")
	missingTenant.TenantID = ""
	_, err = foundation.Evaluate(missingTenant)
	if err == nil {
		t.Fatalf("missing tenant must fail")
	}
	logOK(t, "7-8M.3.6", "missing tenant is rejected")

	unsupported := validRequest("UNKNOWN_OPERATION")
	unsupportedDecision, err := foundation.Evaluate(unsupported)
	if err != nil {
		t.Fatalf("unsupported operation should deny without runtime error: %v", err)
	}
	if unsupportedDecision.Allowed || unsupportedDecision.Reason != DecisionDeniedUnsupported {
		t.Fatalf("unsupported operation must be denied")
	}
	logOK(t, "7-8M.3.7", "unsupported operation is denied")

	live := validRequest("INVOICE_EXPORT")
	live.RequestedMode = "PROVIDER_LIVE"
	liveDecision, err := foundation.Evaluate(live)
	if err != nil {
		t.Fatalf("provider live mode should deny without runtime error: %v", err)
	}
	if liveDecision.Allowed || liveDecision.Reason != DecisionDeniedProviderLive {
		t.Fatalf("provider live mode must be denied")
	}
	logOK(t, "7-8M.3.8", "provider live mode is denied")
}

func TestMikroConnectorSecretAndCapabilityGuards(t *testing.T) {
	foundation := NewFoundation()

	if !foundation.Supports("CUSTOMER_EXPORT") {
		t.Fatalf("CUSTOMER_EXPORT capability must exist")
	}
	if !foundation.Supports("VENDOR_EXPORT") {
		t.Fatalf("VENDOR_EXPORT capability must exist")
	}
	if !foundation.Supports("PRODUCT_EXPORT") {
		t.Fatalf("PRODUCT_EXPORT capability must exist")
	}
	if !foundation.Supports("ACCOUNTING_VOUCHER_EXPORT") {
		t.Fatalf("ACCOUNTING_VOUCHER_EXPORT capability must exist")
	}
	logOK(t, "7-8M.4", "capability matrix validation")
	logOK(t, "7-8M.4.1", "CUSTOMER_EXPORT capability exists")
	logOK(t, "7-8M.4.2", "VENDOR_EXPORT capability exists")
	logOK(t, "7-8M.4.3", "PRODUCT_EXPORT capability exists")
	logOK(t, "7-8M.4.4", "ACCOUNTING_VOUCHER_EXPORT capability exists")

	secretReq := validRequest("INVOICE_EXPORT")
	secretReq.ClientSecret = "real-secret-must-not-be-used"
	_, err := foundation.Evaluate(secretReq)
	if !errors.Is(err, ErrSecretForbidden) {
		t.Fatalf("secret value must be forbidden")
	}
	logOK(t, "7-8M.5", "secret guard validation")
	logOK(t, "7-8M.5.1", "client secret is rejected")

	tokenReq := validRequest("INVOICE_EXPORT")
	tokenReq.AccessToken = "real-token-must-not-be-used"
	_, err = foundation.Evaluate(tokenReq)
	if !errors.Is(err, ErrSecretForbidden) {
		t.Fatalf("access token must be forbidden")
	}
	logOK(t, "7-8M.5.2", "access token is rejected")

	endpointReq := validRequest("INVOICE_EXPORT")
	endpointReq.RealProviderEndpoint = "https://real-mikro-provider.example"
	_, err = foundation.Evaluate(endpointReq)
	if !errors.Is(err, ErrSecretForbidden) {
		t.Fatalf("real provider endpoint must be forbidden")
	}
	logOK(t, "7-8M.5.3", "real provider endpoint is rejected")
}
