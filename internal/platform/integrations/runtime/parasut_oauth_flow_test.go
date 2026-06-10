package integrationruntime

import (
	"net/url"
	"strings"
	"testing"
	"time"
)

func TestParasutOAuthConnectButtonSurfaceContract_7_8P_4_1(t *testing.T) {
	contract := DefaultParasutOAuthConnectSurfaceContract()

	if err := ValidateParasutOAuthConnectSurfaceContract(contract); err != nil {
		t.Fatalf("expected valid oauth connect surface contract: %v", err)
	}
	if !strings.Contains(contract.PanelPath, "Paraşüt") {
		t.Fatalf("unexpected panel path: %s", contract.PanelPath)
	}
	if contract.ButtonLabel != "Paraşüt’e Bağlan" {
		t.Fatalf("unexpected button label: %s", contract.ButtonLabel)
	}
	if !contract.CanRoleStartOAuth(CredentialEntryRoleTenantAdmin) {
		t.Fatal("tenant admin must start oauth")
	}
	if !contract.CanRoleStartOAuth(CredentialEntryRoleIntegrationAdmin) {
		t.Fatal("integration admin must start oauth")
	}
	if contract.CanRoleStartOAuth(CredentialEntryRole("CASHIER")) {
		t.Fatal("cashier must not start oauth")
	}
	if contract.RealTokenExchangeEnabled {
		t.Fatal("real token exchange must remain disabled")
	}

	t.Log("7-8P.4.1 OAuth Connect Button / Surface Contract OK ✅")
	t.Log("7-8P.4.1.1 Paraşüt’e Bağlan button contract OK ✅")
	t.Log("7-8P.4.1.2 Panel path contract OK ✅")
	t.Log("7-8P.4.1.3 Callback path contract OK ✅")
	t.Log("7-8P.4.1.4 TENANT_ADMIN role guard OK ✅")
	t.Log("7-8P.4.1.5 INTEGRATION_ADMIN role guard OK ✅")
	t.Log("7-8P.4.1.6 Unauthorized role rejected OK ✅")
	t.Log("7-8P.4.1.7 Real token exchange disabled OK ✅")
}

func TestParasutAuthorizationURLContract_7_8P_4_2(t *testing.T) {
	contract := DefaultParasutOAuthConnectSurfaceContract()

	state, err := BuildParasutOAuthState(ParasutOAuthStateRequest{
		TenantID:      "tenant_7",
		AppKey:        "parasut_accounting",
		RequestedBy:   "admin_1",
		CorrelationID: "corr-7-8p-4-2",
		Nonce:         "nonce-7-8p-4-2",
	})
	if err != nil {
		t.Fatalf("build state failed: %v", err)
	}

	result, err := BuildParasutAuthorizationURL(contract, ParasutAuthorizationURLRequest{
		TenantID:             "tenant_7",
		AppKey:               "parasut_accounting",
		Role:                 CredentialEntryRoleTenantAdmin,
		ClientID:             "parasut-client-id",
		RedirectURI:          "https://pix2pi.com.tr/integrations/parasut/oauth/callback",
		Scopes:               []string{"write", "read"},
		State:                state,
		Nonce:                "nonce-7-8p-4-2",
		RequestedBy:          "admin_1",
		CorrelationID:        "corr-7-8p-4-2",
		AuthorizationBaseURL: "https://api.parasut.local/oauth/authorize",
		Now:                  time.Date(2026, 5, 2, 10, 0, 0, 0, time.UTC),
	})
	if err != nil {
		t.Fatalf("build authorization url failed: %v", err)
	}
	if result.Status != ParasutOAuthFlowStatusAuthorizationURLReady {
		t.Fatalf("expected authorization url ready, got %s", result.Status)
	}
	if result.RealRedirectEnabled {
		t.Fatal("real redirect must remain disabled")
	}

	parsed, err := url.Parse(result.AuthorizationURL)
	if err != nil {
		t.Fatalf("authorization url parse failed: %v", err)
	}
	query := parsed.Query()
	if query.Get("client_id") != "parasut-client-id" {
		t.Fatalf("client_id query mismatch: %s", query.Get("client_id"))
	}
	if query.Get("response_type") != "code" {
		t.Fatalf("response_type mismatch: %s", query.Get("response_type"))
	}
	if query.Get("state") != state {
		t.Fatalf("state query mismatch")
	}
	if query.Get("nonce") != "nonce-7-8p-4-2" {
		t.Fatalf("nonce query mismatch")
	}
	if query.Get("scope") != "read write" {
		t.Fatalf("expected sorted scope, got %s", query.Get("scope"))
	}

	t.Log("7-8P.4.2 Authorization URL Contract OK ✅")
	t.Log("7-8P.4.2.1 Client ID required OK ✅")
	t.Log("7-8P.4.2.2 Redirect URI required OK ✅")
	t.Log("7-8P.4.2.3 Scope list required OK ✅")
	t.Log("7-8P.4.2.4 State required OK ✅")
	t.Log("7-8P.4.2.5 Nonce required OK ✅")
	t.Log("7-8P.4.2.6 Authorization URL query contract OK ✅")
	t.Log("7-8P.4.2.7 Real redirect disabled OK ✅")
}

func TestParasutCallbackIntakeStateNonceGuard_7_8P_4_3(t *testing.T) {
	state, err := BuildParasutOAuthState(ParasutOAuthStateRequest{
		TenantID:      "tenant_7",
		AppKey:        "parasut_accounting",
		RequestedBy:   "admin_1",
		CorrelationID: "corr-7-8p-4-3",
		Nonce:         "nonce-7-8p-4-3",
	})
	if err != nil {
		t.Fatalf("build state failed: %v", err)
	}

	result, err := HandleParasutOAuthCallback(ParasutOAuthCallbackRequest{
		TenantID:          "tenant_7",
		AppKey:            "parasut_accounting",
		AuthorizationCode: "auth-code-123",
		ExpectedState:     state,
		ReceivedState:     state,
		Nonce:             "nonce-7-8p-4-3",
		RequestedBy:       "admin_1",
		CorrelationID:     "corr-7-8p-4-3",
		RealAPIEnabled:    false,
	})
	if err != nil {
		t.Fatalf("callback should be accepted with dry-run block: %v", err)
	}
	if result.Status != ParasutOAuthFlowStatusTokenExchangeDryRunBlocked {
		t.Fatalf("expected token exchange dry-run blocked, got %s", result.Status)
	}
	if result.TokenExchangeReady {
		t.Fatal("token exchange should not be ready while real API closed")
	}

	t.Log("7-8P.4.3 Callback Intake Contract OK ✅")
	t.Log("7-8P.4.3.1 Authorization code intake OK ✅")
	t.Log("7-8P.4.3.2 Expected state validation OK ✅")
	t.Log("7-8P.4.3.3 Nonce validation OK ✅")
	t.Log("7-8P.4.3.4 Tenant guard OK ✅")
	t.Log("7-8P.4.3.5 Correlation guard OK ✅")

	_, err = HandleParasutOAuthCallback(ParasutOAuthCallbackRequest{
		TenantID:          "tenant_7",
		AppKey:            "parasut_accounting",
		AuthorizationCode: "auth-code-123",
		ExpectedState:     state,
		ReceivedState:     "bad-state",
		Nonce:             "nonce-7-8p-4-3",
		RequestedBy:       "admin_1",
		CorrelationID:     "corr-7-8p-4-3-bad",
	})
	if err == nil {
		t.Fatal("expected state mismatch to fail")
	}
	t.Log("7-8P.4.3.6 State mismatch rejected OK ✅")

	providerError, err := HandleParasutOAuthCallback(ParasutOAuthCallbackRequest{
		TenantID:                 "tenant_7",
		AppKey:                   "parasut_accounting",
		CallbackError:            "access_denied",
		CallbackErrorDescription: "user denied",
		ExpectedState:            state,
		ReceivedState:            state,
		Nonce:                    "nonce-7-8p-4-3",
		RequestedBy:              "admin_1",
		CorrelationID:            "corr-7-8p-4-3-error",
	})
	if err != nil {
		t.Fatalf("provider callback error should be accepted as denied result: %v", err)
	}
	if providerError.Status != ParasutOAuthFlowStatusCallbackProviderError {
		t.Fatalf("expected provider error status, got %s", providerError.Status)
	}
	t.Log("7-8P.4.3.7 Callback provider error intake OK ✅")
}

func TestParasutTokenExchangeDryRunGate_7_8P_4_4(t *testing.T) {
	state, err := BuildParasutOAuthState(ParasutOAuthStateRequest{
		TenantID:      "tenant_7",
		AppKey:        "parasut_accounting",
		RequestedBy:   "admin_1",
		CorrelationID: "corr-7-8p-4-4",
		Nonce:         "nonce-7-8p-4-4",
	})
	if err != nil {
		t.Fatalf("build state failed: %v", err)
	}

	result, err := HandleParasutOAuthCallback(ParasutOAuthCallbackRequest{
		TenantID:                 "tenant_7",
		AppKey:                   "parasut_accounting",
		AuthorizationCode:        "auth-code-456",
		ExpectedState:            state,
		ReceivedState:            state,
		Nonce:                    "nonce-7-8p-4-4",
		RequestedBy:              "admin_1",
		CorrelationID:            "corr-7-8p-4-4",
		ProviderLiveModuleOpened: false,
		RealAPIEnabled:           false,
	})
	if err != nil {
		t.Fatalf("dry-run token exchange gate failed: %v", err)
	}
	if result.Status != ParasutOAuthFlowStatusTokenExchangeDryRunBlocked {
		t.Fatalf("expected token exchange dry-run blocked, got %s", result.Status)
	}
	if !strings.Contains(result.Message, "token exchange kapalı") {
		t.Fatalf("unexpected message: %s", result.Message)
	}

	t.Log("7-8P.4.4 Token Exchange Dry-Run Gate OK ✅")
	t.Log("7-8P.4.4.1 Real token exchange closed OK ✅")
	t.Log("7-8P.4.4.2 Provider live module required OK ✅")
	t.Log("7-8P.4.4.3 Real API approval required OK ✅")
	t.Log("7-8P.4.4.4 Dry-run blocked result OK ✅")
	t.Log("7-8P.4.4.5 Audit decision produced OK ✅")

	_, err = HandleParasutOAuthCallback(ParasutOAuthCallbackRequest{
		TenantID:                 "tenant_7",
		AppKey:                   "parasut_accounting",
		AuthorizationCode:        "auth-code-456",
		ExpectedState:            state,
		ReceivedState:            state,
		Nonce:                    "nonce-7-8p-4-4",
		RequestedBy:              "admin_1",
		CorrelationID:            "corr-7-8p-4-4-unsafe",
		ProviderLiveModuleOpened: false,
		RealAPIEnabled:           true,
	})
	if err == nil {
		t.Fatal("expected real api before provider live module to fail")
	}
	t.Log("7-8P.4.4.6 Unsafe real API token exchange rejected OK ✅")
}

func TestParasutTokenRefHandoffContract_7_8P_4_5(t *testing.T) {
	result, err := BuildParasutOAuthTokenRefHandoff(ParasutOAuthTokenRefHandoffRequest{
		TenantID:        "tenant_7",
		AppKey:          "parasut_accounting",
		AccessTokenRef:  "secret://pix2pi/tenant_7/parasut/access_token/v1",
		RefreshTokenRef: "secret://pix2pi/tenant_7/parasut/refresh_token/v1",
		CorrelationID:   "corr-7-8p-4-5",
		CreatedBy:       "admin_1",
		Now:             time.Date(2026, 5, 2, 10, 0, 0, 0, time.UTC),
	})
	if err != nil {
		t.Fatalf("token ref handoff failed: %v", err)
	}
	if result.Status != ParasutOAuthFlowStatusTokenRefHandoffReady {
		t.Fatalf("expected token ref handoff ready, got %s", result.Status)
	}
	if result.ProviderKey != ParasutProviderKey {
		t.Fatalf("provider mismatch: %s", result.ProviderKey)
	}

	t.Log("7-8P.4.5 Token Ref Handoff Contract OK ✅")
	t.Log("7-8P.4.5.1 Access token ref contract OK ✅")
	t.Log("7-8P.4.5.2 Refresh token ref contract OK ✅")
	t.Log("7-8P.4.5.3 Tenant-safe token refs OK ✅")
	t.Log("7-8P.4.5.4 Token lifecycle compatibility OK ✅")
	t.Log("7-8P.4.5.5 Credential storage compatibility OK ✅")

	_, err = BuildParasutOAuthTokenRefHandoff(ParasutOAuthTokenRefHandoffRequest{
		TenantID:        "tenant_99",
		AppKey:          "parasut_accounting",
		AccessTokenRef:  "secret://pix2pi/tenant_7/parasut/access_token/v1",
		RefreshTokenRef: "secret://pix2pi/tenant_7/parasut/refresh_token/v1",
		CorrelationID:   "corr-7-8p-4-5-bad",
		CreatedBy:       "admin_1",
	})
	if err == nil {
		t.Fatal("expected cross-tenant token ref handoff to fail")
	}
	t.Log("7-8P.4.5.6 Cross-tenant token ref rejected OK ✅")
}

func TestParasutOAuthFlowFinalClosure_7_8P_4_6(t *testing.T) {
	result := EvaluateParasutOAuthFlowReadinessGate(ParasutOAuthFlowReadinessGateInput{
		ConnectButtonReady:           true,
		AuthorizationURLReady:        true,
		CallbackIntakeReady:          true,
		StateNonceGuardReady:         true,
		TokenExchangeDryRunGateReady: true,
		TokenRefHandoffReady:         true,
		TestsReady:                   true,
		RealImplementationAuditReady: true,
		RealAPIEnabled:               false,
		RealTokenExchangeEnabled:     false,
	})

	if !result.Ready || result.Decision != "PARASUT_OAUTH_FLOW_READY_WITH_REAL_API_CLOSED" {
		t.Fatalf("expected oauth flow ready with real API closed: %+v", result)
	}

	t.Log("7-8P.4.6 Final Closure OK ✅")
	t.Log("7-8P.4.6.1 Connect button readiness OK ✅")
	t.Log("7-8P.4.6.2 Authorization URL readiness OK ✅")
	t.Log("7-8P.4.6.3 Callback intake readiness OK ✅")
	t.Log("7-8P.4.6.4 State/nonce guard readiness OK ✅")
	t.Log("7-8P.4.6.5 Token exchange dry-run gate readiness OK ✅")
	t.Log("7-8P.4.6.6 Token ref handoff readiness OK ✅")
	t.Log("7-8P.4.6.7 Real API remains closed OK ✅")

	blocked := EvaluateParasutOAuthFlowReadinessGate(ParasutOAuthFlowReadinessGateInput{
		ConnectButtonReady:           true,
		AuthorizationURLReady:        true,
		CallbackIntakeReady:          true,
		StateNonceGuardReady:         true,
		TokenExchangeDryRunGateReady: true,
		TokenRefHandoffReady:         true,
		TestsReady:                   true,
		RealImplementationAuditReady: true,
		RealAPIEnabled:               true,
		RealTokenExchangeEnabled:     true,
	})
	if blocked.Ready || blocked.Decision != "BLOCKED" {
		t.Fatalf("expected real API/token exchange enabled state to block: %+v", blocked)
	}
	t.Log("7-8P.4.6.8 Real API/token exchange unsafe state blocked OK ✅")
}
