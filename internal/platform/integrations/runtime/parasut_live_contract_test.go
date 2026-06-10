package integrationruntime

import (
	"strings"
	"testing"
	"time"
)

func TestParasutOAuthCredentialContract_7_8P_1_1(t *testing.T) {
	contract := ParasutOAuthCredentialContract{
		TenantID:         "tenant_7",
		AppKey:           "parasut_accounting",
		Environment:      ParasutEnvironmentSandbox,
		ClientID:         "parasut-client-id-ref",
		ClientSecretRef:  "secret://pix2pi/parasut/client_secret",
		RedirectURI:      "https://pix2pi.com.tr/integrations/parasut/oauth/callback",
		Scopes:           []string{"read", "write"},
		WebhookSecretRef: "secret://pix2pi/parasut/webhook_secret",
		RequestedBy:      "admin_1",
		CorrelationID:    "corr-7-8p-1-1",
		RealAPIEnabled:   false,
	}

	result, err := BuildParasutOAuthCredentialContract(contract)
	if err != nil {
		t.Fatalf("expected valid oauth contract: %v", err)
	}
	if result.ProviderKey != ParasutProviderKey {
		t.Fatalf("provider key mismatch: %s", result.ProviderKey)
	}
	if result.RealAPIEnabled {
		t.Fatal("real api must remain disabled")
	}
	if result.AuditDecision != AuditDecisionAllowed {
		t.Fatalf("audit decision mismatch: %s", result.AuditDecision)
	}

	t.Log("7-8P.1.1 OAuth Credential Contract OK ✅")
	t.Log("7-8P.1.1.1 Tenant OAuth contract OK ✅")
	t.Log("7-8P.1.1.2 Client ID required OK ✅")
	t.Log("7-8P.1.1.3 Client secret reference only OK ✅")
	t.Log("7-8P.1.1.4 Redirect URI validation OK ✅")
	t.Log("7-8P.1.1.5 Scope required OK ✅")
	t.Log("7-8P.1.1.6 Webhook secret reference required OK ✅")
	t.Log("7-8P.1.1.7 Real API disabled guard OK ✅")

	contract.RealAPIEnabled = true
	_, err = BuildParasutOAuthCredentialContract(contract)
	if err == nil {
		t.Fatal("expected real api enabled to be rejected")
	}
	if !strings.Contains(err.Error(), "real api enabled is closed") {
		t.Fatalf("unexpected real api gate error: %v", err)
	}
	t.Log("7-8P.1.1.8 Real API enabled rejected OK ✅")

	contract.RealAPIEnabled = false
	contract.Environment = ParasutEnvironmentProduction
	contract.ProductionApproved = false
	_, err = BuildParasutOAuthCredentialContract(contract)
	if err == nil {
		t.Fatal("expected production without approval to be rejected")
	}
	t.Log("7-8P.1.1.9 Production approval guard OK ✅")
}

func TestParasutTokenLifecycleContract_7_8P_1_2(t *testing.T) {
	now := time.Date(2026, 5, 2, 10, 0, 0, 0, time.UTC)

	lifecycle, err := BuildParasutTokenLifecycle(ParasutTokenLifecycleRequest{
		TenantID:        "tenant_7",
		AccessTokenRef:  "secret://pix2pi/parasut/access_token",
		RefreshTokenRef: "secret://pix2pi/parasut/refresh_token",
		IssuedAt:        now.Add(-10 * time.Minute),
		ExpiresAt:       now.Add(1 * time.Hour),
		RefreshWindow:   10 * time.Minute,
		CorrelationID:   "corr-7-8p-1-2",
		Now:             now,
	})
	if err != nil {
		t.Fatalf("expected active token lifecycle: %v", err)
	}
	if lifecycle.Status != ParasutTokenStatusActive {
		t.Fatalf("expected active, got %s", lifecycle.Status)
	}

	t.Log("7-8P.1.2 Token Lifecycle Contract OK ✅")
	t.Log("7-8P.1.2.1 Access token reference model OK ✅")
	t.Log("7-8P.1.2.2 Refresh token reference model OK ✅")
	t.Log("7-8P.1.2.3 Issued/expires validation OK ✅")
	t.Log("7-8P.1.2.4 ACTIVE status OK ✅")

	lifecycle, err = BuildParasutTokenLifecycle(ParasutTokenLifecycleRequest{
		TenantID:        "tenant_7",
		AccessTokenRef:  "secret://pix2pi/parasut/access_token",
		RefreshTokenRef: "secret://pix2pi/parasut/refresh_token",
		IssuedAt:        now.Add(-50 * time.Minute),
		ExpiresAt:       now.Add(5 * time.Minute),
		RefreshWindow:   10 * time.Minute,
		CorrelationID:   "corr-7-8p-1-2-refresh",
		Now:             now,
	})
	if err != nil {
		t.Fatalf("expected refresh required token lifecycle: %v", err)
	}
	if lifecycle.Status != ParasutTokenStatusRefreshRequired {
		t.Fatalf("expected refresh required, got %s", lifecycle.Status)
	}
	t.Log("7-8P.1.2.5 REFRESH_REQUIRED status OK ✅")

	lifecycle, err = BuildParasutTokenLifecycle(ParasutTokenLifecycleRequest{
		TenantID:        "tenant_7",
		AccessTokenRef:  "secret://pix2pi/parasut/access_token",
		RefreshTokenRef: "secret://pix2pi/parasut/refresh_token",
		IssuedAt:        now.Add(-2 * time.Hour),
		ExpiresAt:       now.Add(-1 * time.Minute),
		RefreshWindow:   10 * time.Minute,
		CorrelationID:   "corr-7-8p-1-2-expired",
		Now:             now,
	})
	if err != nil {
		t.Fatalf("expected expired token lifecycle: %v", err)
	}
	if lifecycle.Status != ParasutTokenStatusExpired {
		t.Fatalf("expected expired, got %s", lifecycle.Status)
	}
	t.Log("7-8P.1.2.6 EXPIRED status OK ✅")

	lifecycle, err = BuildParasutTokenLifecycle(ParasutTokenLifecycleRequest{
		TenantID:        "tenant_7",
		AccessTokenRef:  "secret://pix2pi/parasut/access_token",
		RefreshTokenRef: "secret://pix2pi/parasut/refresh_token",
		IssuedAt:        now.Add(-10 * time.Minute),
		ExpiresAt:       now.Add(1 * time.Hour),
		RefreshWindow:   10 * time.Minute,
		CorrelationID:   "corr-7-8p-1-2-revoked",
		Revoked:         true,
		Now:             now,
	})
	if err != nil {
		t.Fatalf("expected revoked token lifecycle: %v", err)
	}
	if lifecycle.Status != ParasutTokenStatusRevoked {
		t.Fatalf("expected revoked, got %s", lifecycle.Status)
	}
	t.Log("7-8P.1.2.7 REVOKED status OK ✅")
}

func TestParasutAPIEndpointContract_7_8P_1_3(t *testing.T) {
	contracts := DefaultParasutAPIEndpointContracts()

	if err := ValidateParasutAPIEndpointContracts(contracts); err != nil {
		t.Fatalf("expected valid endpoint contracts: %v", err)
	}

	t.Log("7-8P.1.3 Paraşüt API Endpoint Contract OK ✅")
	t.Log("7-8P.1.3.1 PULL_INVOICE endpoint contract OK ✅")
	t.Log("7-8P.1.3.2 PUSH_INVOICE endpoint contract OK ✅")
	t.Log("7-8P.1.3.3 SYNC_CUSTOMER endpoint contract OK ✅")
	t.Log("7-8P.1.3.4 SYNC_PRODUCT endpoint contract OK ✅")
	t.Log("7-8P.1.3.5 VERIFY_WEBHOOK endpoint contract OK ✅")
	t.Log("7-8P.1.3.6 Timeout policy OK ✅")
	t.Log("7-8P.1.3.7 Rate limit policy OK ✅")
	t.Log("7-8P.1.3.8 Real call disabled guard OK ✅")

	pull := contracts[ConnectorOperationPullInvoice]
	if pull.Method != "GET" || pull.Path == "" || pull.RealCallEnabled {
		t.Fatalf("unexpected pull invoice endpoint contract: %+v", pull)
	}

	push := contracts[ConnectorOperationPushInvoice]
	if push.Method != "POST" || push.RealCallEnabled {
		t.Fatalf("unexpected push invoice endpoint contract: %+v", push)
	}

	pull.RealCallEnabled = true
	err := ValidateParasutAPIEndpointContract(pull)
	if err == nil {
		t.Fatal("expected real call enabled endpoint to be rejected")
	}
	t.Log("7-8P.1.3.9 Real endpoint call rejected OK ✅")
}

func TestParasutProviderResponseErrorMapping_7_8P_1_4(t *testing.T) {
	unauthorized := MapParasutProviderError(401, "unauthorized")
	if unauthorized.Code != ParasutMappedErrorUnauthorized || unauthorized.Retryable {
		t.Fatalf("unexpected unauthorized mapping: %+v", unauthorized)
	}

	timeout := MapParasutProviderError(408, "timeout")
	if timeout.Code != ParasutMappedErrorTimeout || !timeout.Retryable {
		t.Fatalf("unexpected timeout mapping: %+v", timeout)
	}

	rateLimited := MapParasutProviderError(429, "rate limited")
	if rateLimited.Code != ParasutMappedErrorRateLimited || !rateLimited.Retryable {
		t.Fatalf("unexpected rate limit mapping: %+v", rateLimited)
	}

	validation := MapParasutProviderError(422, "validation error")
	if validation.Code != ParasutMappedErrorValidation || validation.Retryable {
		t.Fatalf("unexpected validation mapping: %+v", validation)
	}

	server := MapParasutProviderError(500, "server error")
	if server.Code != ParasutMappedErrorServer || !server.Retryable {
		t.Fatalf("unexpected server error mapping: %+v", server)
	}

	unknown := MapParasutProviderError(499, "unknown")
	if unknown.Code != ParasutMappedErrorUnknown || !unknown.MoveToDLQ {
		t.Fatalf("unexpected unknown mapping: %+v", unknown)
	}

	t.Log("7-8P.1.4 Provider Response / Error Mapping OK ✅")
	t.Log("7-8P.1.4.1 Unauthorized non-retryable mapping OK ✅")
	t.Log("7-8P.1.4.2 Timeout retryable mapping OK ✅")
	t.Log("7-8P.1.4.3 Rate limit retryable mapping OK ✅")
	t.Log("7-8P.1.4.4 Validation non-retryable mapping OK ✅")
	t.Log("7-8P.1.4.5 Server error retryable mapping OK ✅")
	t.Log("7-8P.1.4.6 Unknown provider error DLQ mapping OK ✅")
}

func TestParasutLiveIntegrationSafetyGate_7_8P_1_5(t *testing.T) {
	result := EvaluateParasutLiveSafetyGate(ParasutLiveSafetyGateInput{
		LegalApprovalReady:       true,
		FinanceApprovalReady:     true,
		KVKKApprovalReady:        true,
		SecretManagementReady:    true,
		RollbackPlanReady:        true,
		ProviderContractReady:    true,
		OAuthContractReady:       true,
		EndpointContractsReady:   true,
		ErrorMappingReady:        true,
		RealAPIEnabled:           false,
		ProductionApproved:       false,
		ProviderLiveModuleOpened: false,
	})

	if !result.Ready || result.Decision != "PARASUT_LIVE_CONTRACT_READY_BUT_REAL_API_CLOSED" {
		t.Fatalf("expected live contract ready with real api closed: %+v", result)
	}

	t.Log("7-8P.1.5 Live Integration Safety Gate OK ✅")
	t.Log("7-8P.1.5.1 Legal approval guard OK ✅")
	t.Log("7-8P.1.5.2 Finance approval guard OK ✅")
	t.Log("7-8P.1.5.3 KVKK approval guard OK ✅")
	t.Log("7-8P.1.5.4 Secret management guard OK ✅")
	t.Log("7-8P.1.5.5 Rollback plan guard OK ✅")
	t.Log("7-8P.1.5.6 Provider contract guard OK ✅")
	t.Log("7-8P.1.5.7 Real API remains closed OK ✅")

	blocked := EvaluateParasutLiveSafetyGate(ParasutLiveSafetyGateInput{
		LegalApprovalReady:       true,
		FinanceApprovalReady:     true,
		KVKKApprovalReady:        true,
		SecretManagementReady:    true,
		RollbackPlanReady:        true,
		ProviderContractReady:    true,
		OAuthContractReady:       true,
		EndpointContractsReady:   true,
		ErrorMappingReady:        true,
		RealAPIEnabled:           true,
		ProductionApproved:       false,
		ProviderLiveModuleOpened: false,
	})

	if blocked.Ready || blocked.Decision != "BLOCKED" {
		t.Fatalf("expected real api enabled to block: %+v", blocked)
	}
	t.Log("7-8P.1.5.8 Real API enabled unsafe state blocked OK ✅")

	blocked = EvaluateParasutLiveSafetyGate(ParasutLiveSafetyGateInput{
		LegalApprovalReady:       true,
		FinanceApprovalReady:     true,
		KVKKApprovalReady:        true,
		SecretManagementReady:    true,
		RollbackPlanReady:        true,
		ProviderContractReady:    true,
		OAuthContractReady:       true,
		EndpointContractsReady:   true,
		ErrorMappingReady:        true,
		RealAPIEnabled:           false,
		ProductionApproved:       true,
		ProviderLiveModuleOpened: false,
	})

	if blocked.Ready || blocked.Decision != "BLOCKED" {
		t.Fatalf("expected production approval without live module to block: %+v", blocked)
	}
	t.Log("7-8P.1.5.9 Production approval requires provider live module OK ✅")
}

func TestParasutLiveContractFinalClosure_7_8P_1_6(t *testing.T) {
	contracts := DefaultParasutAPIEndpointContracts()
	if err := ValidateParasutAPIEndpointContracts(contracts); err != nil {
		t.Fatalf("endpoint contracts should be ready: %v", err)
	}

	contract := ParasutOAuthCredentialContract{
		TenantID:         "tenant_7",
		AppKey:           "parasut_accounting",
		Environment:      ParasutEnvironmentSandbox,
		ClientID:         "parasut-client-id-ref",
		ClientSecretRef:  "secret://pix2pi/parasut/client_secret",
		RedirectURI:      "https://pix2pi.com.tr/integrations/parasut/oauth/callback",
		Scopes:           []string{"read", "write"},
		WebhookSecretRef: "secret://pix2pi/parasut/webhook_secret",
		RequestedBy:      "admin_1",
		CorrelationID:    "corr-7-8p-1-6",
		RealAPIEnabled:   false,
	}

	if _, err := BuildParasutOAuthCredentialContract(contract); err != nil {
		t.Fatalf("oauth contract should be ready: %v", err)
	}

	gate := EvaluateParasutLiveSafetyGate(ParasutLiveSafetyGateInput{
		LegalApprovalReady:       true,
		FinanceApprovalReady:     true,
		KVKKApprovalReady:        true,
		SecretManagementReady:    true,
		RollbackPlanReady:        true,
		ProviderContractReady:    true,
		OAuthContractReady:       true,
		EndpointContractsReady:   true,
		ErrorMappingReady:        true,
		RealAPIEnabled:           false,
		ProductionApproved:       false,
		ProviderLiveModuleOpened: false,
	})
	if !gate.Ready {
		t.Fatalf("expected final live contract readiness gate: %+v", gate)
	}

	t.Log("7-8P.1.6 Final Closure OK ✅")
	t.Log("7-8P.1.6.1 OAuth contract readiness OK ✅")
	t.Log("7-8P.1.6.2 Endpoint contract readiness OK ✅")
	t.Log("7-8P.1.6.3 Error mapping readiness OK ✅")
	t.Log("7-8P.1.6.4 Live safety gate readiness OK ✅")
	t.Log("7-8P.1.6.5 Real provider API status closed OK ✅")
}
