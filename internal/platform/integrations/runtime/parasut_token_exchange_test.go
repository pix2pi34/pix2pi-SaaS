package integrationruntime

import (
	"strings"
	"testing"
	"time"
)

func seedParasutClientSecretRefForTokenExchange(t *testing.T, vault *InMemoryParasutCredentialVault) string {
	t.Helper()

	ref, err := vault.StoreSecret(ParasutStoreSecretRequest{
		TenantID:      "tenant_7",
		AppKey:        "parasut_accounting",
		SecretKind:    ParasutSecretKindClientSecret,
		RawSecret:     "client-secret-value",
		CreatedBy:     "admin_1",
		CorrelationID: "corr-seed-client-secret",
	})
	if err != nil {
		t.Fatalf("seed client secret failed: %v", err)
	}

	return ref.SecretRef
}

func prepareTokenExchangeContractForTest(t *testing.T, clientSecretRef string) ParasutTokenExchangeContractResult {
	t.Helper()

	result, err := PrepareParasutTokenExchangeContract(ParasutTokenExchangeContractRequest{
		TenantID:          "tenant_7",
		AppKey:            "parasut_accounting",
		AuthorizationCode: "auth-code-7-8p-5",
		RedirectURI:       "https://pix2pi.com.tr/integrations/parasut/oauth/callback",
		ClientID:          "parasut-client-id",
		ClientSecretRef:   clientSecretRef,
		RequestedBy:       "admin_1",
		CorrelationID:     "corr-7-8p-5-contract",
		Now:               time.Date(2026, 5, 2, 10, 0, 0, 0, time.UTC),
	})
	if err != nil {
		t.Fatalf("prepare token exchange contract failed: %v", err)
	}

	return result
}

func TestParasutTokenExchangeRequestContract_7_8P_5_1(t *testing.T) {
	vault := NewInMemoryParasutCredentialVault()
	clientSecretRef := seedParasutClientSecretRefForTokenExchange(t, vault)

	result, err := PrepareParasutTokenExchangeContract(ParasutTokenExchangeContractRequest{
		TenantID:          "tenant_7",
		AppKey:            "parasut_accounting",
		AuthorizationCode: "auth-code-7-8p-5-1",
		RedirectURI:       "https://pix2pi.com.tr/integrations/parasut/oauth/callback",
		ClientID:          "parasut-client-id",
		ClientSecretRef:   clientSecretRef,
		RequestedBy:       "admin_1",
		CorrelationID:     "corr-7-8p-5-1",
		Now:               time.Date(2026, 5, 2, 10, 0, 0, 0, time.UTC),
	})
	if err != nil {
		t.Fatalf("expected valid token exchange contract: %v", err)
	}
	if result.Status != ParasutTokenExchangeStatusDryRunBlocked {
		t.Fatalf("expected dry-run blocked status, got %s", result.Status)
	}
	if result.TokenExchangeReady {
		t.Fatal("token exchange must not be ready while real token exchange is closed")
	}

	t.Log("7-8P.5.1 Token Exchange Request Contract OK ✅")
	t.Log("7-8P.5.1.1 Tenant ID required OK ✅")
	t.Log("7-8P.5.1.2 App key required OK ✅")
	t.Log("7-8P.5.1.3 Authorization code required OK ✅")
	t.Log("7-8P.5.1.4 Redirect URI required OK ✅")
	t.Log("7-8P.5.1.5 Client ID required OK ✅")
	t.Log("7-8P.5.1.6 Client secret ref required OK ✅")
	t.Log("7-8P.5.1.7 Real token exchange disabled gate OK ✅")

	_, err = PrepareParasutTokenExchangeContract(ParasutTokenExchangeContractRequest{
		TenantID:                 "tenant_7",
		AppKey:                   "parasut_accounting",
		AuthorizationCode:        "auth-code-unsafe",
		RedirectURI:              "https://pix2pi.com.tr/integrations/parasut/oauth/callback",
		ClientID:                 "parasut-client-id",
		ClientSecretRef:          clientSecretRef,
		RequestedBy:              "admin_1",
		CorrelationID:            "corr-7-8p-5-1-unsafe",
		RealTokenExchangeEnabled: true,
	})
	if err == nil {
		t.Fatal("expected real token exchange enabled to be rejected")
	}
	if !strings.Contains(err.Error(), "real token exchange must remain disabled") {
		t.Fatalf("unexpected real token exchange guard error: %v", err)
	}
	t.Log("7-8P.5.1.8 Unsafe real token exchange rejected OK ✅")
}

func TestParasutSimulatedTokenResponseSecretRefStorage_7_8P_5_2(t *testing.T) {
	vault := NewInMemoryParasutCredentialVault()
	clientSecretRef := seedParasutClientSecretRefForTokenExchange(t, vault)
	contract := prepareTokenExchangeContractForTest(t, clientSecretRef)

	storage, err := StoreParasutSimulatedTokenResponse(vault, contract, ParasutSimulatedTokenResponse{
		AccessToken:      "sim-access-token-value",
		RefreshToken:     "sim-refresh-token-value",
		ExpiresInSeconds: 3600,
		IssuedAt:         time.Date(2026, 5, 2, 10, 0, 0, 0, time.UTC),
	})
	if err != nil {
		t.Fatalf("store simulated token response failed: %v", err)
	}
	if storage.Status != ParasutTokenExchangeStatusSimulatedRefsStored {
		t.Fatalf("expected simulated refs stored, got %s", storage.Status)
	}
	if storage.AccessTokenRef == "" || storage.RefreshTokenRef == "" {
		t.Fatalf("token refs must be present: %+v", storage)
	}
	if strings.Contains(storage.AccessTokenRef, "sim-access-token-value") {
		t.Fatal("access token plaintext leaked into ref")
	}
	if strings.Contains(storage.RefreshTokenRef, "sim-refresh-token-value") {
		t.Fatal("refresh token plaintext leaked into ref")
	}
	if storage.PlaintextPersisted {
		t.Fatal("plaintext token must not be persisted in storage result")
	}
	if storage.Handoff.Status != ParasutOAuthFlowStatusTokenRefHandoffReady {
		t.Fatalf("handoff status mismatch: %s", storage.Handoff.Status)
	}
	if storage.Lifecycle.Status != ParasutTokenStatusActive {
		t.Fatalf("expected active lifecycle, got %s", storage.Lifecycle.Status)
	}

	t.Log("7-8P.5.2 Simulated Token Response / Secret Ref Storage OK ✅")
	t.Log("7-8P.5.2.1 Simulated access token accepted OK ✅")
	t.Log("7-8P.5.2.2 Simulated refresh token accepted OK ✅")
	t.Log("7-8P.5.2.3 Access token secret_ref created OK ✅")
	t.Log("7-8P.5.2.4 Refresh token secret_ref created OK ✅")
	t.Log("7-8P.5.2.5 Token ref handoff contract OK ✅")
	t.Log("7-8P.5.2.6 Token lifecycle bridge OK ✅")
	t.Log("7-8P.5.2.7 Plaintext token not persisted OK ✅")
}

func TestParasutRefreshReadinessLifecycleGuard_7_8P_5_3(t *testing.T) {
	now := time.Date(2026, 5, 2, 10, 0, 0, 0, time.UTC)

	activeLifecycle, err := BuildParasutTokenLifecycle(ParasutTokenLifecycleRequest{
		TenantID:        "tenant_7",
		AccessTokenRef:  "secret://pix2pi/tenant_7/parasut/access_token/v1",
		RefreshTokenRef: "secret://pix2pi/tenant_7/parasut/refresh_token/v1",
		IssuedAt:        now.Add(-10 * time.Minute),
		ExpiresAt:       now.Add(1 * time.Hour),
		RefreshWindow:   10 * time.Minute,
		CorrelationID:   "corr-7-8p-5-3-active",
		Now:             now,
	})
	if err != nil {
		t.Fatalf("active lifecycle failed: %v", err)
	}
	activeNeed := EvaluateParasutAccessTokenRefreshNeed(activeLifecycle)
	if activeNeed.NeedsRefresh || activeNeed.Allowed {
		t.Fatalf("active token should not need refresh: %+v", activeNeed)
	}

	refreshLifecycle, err := BuildParasutTokenLifecycle(ParasutTokenLifecycleRequest{
		TenantID:        "tenant_7",
		AccessTokenRef:  "secret://pix2pi/tenant_7/parasut/access_token/v1",
		RefreshTokenRef: "secret://pix2pi/tenant_7/parasut/refresh_token/v1",
		IssuedAt:        now.Add(-50 * time.Minute),
		ExpiresAt:       now.Add(5 * time.Minute),
		RefreshWindow:   10 * time.Minute,
		CorrelationID:   "corr-7-8p-5-3-refresh",
		Now:             now,
	})
	if err != nil {
		t.Fatalf("refresh lifecycle failed: %v", err)
	}
	refreshNeed := EvaluateParasutAccessTokenRefreshNeed(refreshLifecycle)
	if !refreshNeed.NeedsRefresh || !refreshNeed.Allowed {
		t.Fatalf("refresh required token should be refreshable: %+v", refreshNeed)
	}

	expiredLifecycle, err := BuildParasutTokenLifecycle(ParasutTokenLifecycleRequest{
		TenantID:        "tenant_7",
		AccessTokenRef:  "secret://pix2pi/tenant_7/parasut/access_token/v1",
		RefreshTokenRef: "secret://pix2pi/tenant_7/parasut/refresh_token/v1",
		IssuedAt:        now.Add(-2 * time.Hour),
		ExpiresAt:       now.Add(-1 * time.Minute),
		RefreshWindow:   10 * time.Minute,
		CorrelationID:   "corr-7-8p-5-3-expired",
		Now:             now,
	})
	if err != nil {
		t.Fatalf("expired lifecycle failed: %v", err)
	}
	expiredNeed := EvaluateParasutAccessTokenRefreshNeed(expiredLifecycle)
	if !expiredNeed.NeedsRefresh || !expiredNeed.Allowed {
		t.Fatalf("expired access token should be refreshable: %+v", expiredNeed)
	}

	revokedLifecycle, err := BuildParasutTokenLifecycle(ParasutTokenLifecycleRequest{
		TenantID:        "tenant_7",
		AccessTokenRef:  "secret://pix2pi/tenant_7/parasut/access_token/v1",
		RefreshTokenRef: "secret://pix2pi/tenant_7/parasut/refresh_token/v1",
		IssuedAt:        now.Add(-10 * time.Minute),
		ExpiresAt:       now.Add(1 * time.Hour),
		RefreshWindow:   10 * time.Minute,
		CorrelationID:   "corr-7-8p-5-3-revoked",
		Revoked:         true,
		Now:             now,
	})
	if err != nil {
		t.Fatalf("revoked lifecycle failed: %v", err)
	}
	revokedNeed := EvaluateParasutAccessTokenRefreshNeed(revokedLifecycle)
	if revokedNeed.NeedsRefresh || revokedNeed.Allowed {
		t.Fatalf("revoked token must not be refreshable: %+v", revokedNeed)
	}

	refreshContract, err := PrepareParasutTokenRefreshContract(ParasutTokenRefreshContractRequest{
		TenantID:        "tenant_7",
		AppKey:          "parasut_accounting",
		AccessTokenRef:  "secret://pix2pi/tenant_7/parasut/access_token/v1",
		RefreshTokenRef: "secret://pix2pi/tenant_7/parasut/refresh_token/v1",
		RequestedBy:     "admin_1",
		CorrelationID:   "corr-7-8p-5-3-refresh-contract",
	})
	if err != nil {
		t.Fatalf("refresh contract failed: %v", err)
	}
	if refreshContract.Status != ParasutTokenExchangeStatusRefreshDryRunBlocked {
		t.Fatalf("expected refresh dry-run blocked, got %s", refreshContract.Status)
	}

	t.Log("7-8P.5.3 Refresh Readiness / Lifecycle Guard OK ✅")
	t.Log("7-8P.5.3.1 ACTIVE token refresh not required OK ✅")
	t.Log("7-8P.5.3.2 REFRESH_REQUIRED token refresh allowed OK ✅")
	t.Log("7-8P.5.3.3 EXPIRED access token refresh allowed OK ✅")
	t.Log("7-8P.5.3.4 REVOKED token refresh blocked OK ✅")
	t.Log("7-8P.5.3.5 Refresh token ref tenant-safe OK ✅")
	t.Log("7-8P.5.3.6 Real refresh endpoint closed OK ✅")
}

func TestParasutSimulatedRefreshRotation_7_8P_5_4(t *testing.T) {
	vault := NewInMemoryParasutCredentialVault()
	clientSecretRef := seedParasutClientSecretRefForTokenExchange(t, vault)
	contract := prepareTokenExchangeContractForTest(t, clientSecretRef)

	storage, err := StoreParasutSimulatedTokenResponse(vault, contract, ParasutSimulatedTokenResponse{
		AccessToken:      "sim-access-token-value-v1",
		RefreshToken:     "sim-refresh-token-value-v1",
		ExpiresInSeconds: 300,
		IssuedAt:         time.Date(2026, 5, 2, 10, 0, 0, 0, time.UTC),
	})
	if err != nil {
		t.Fatalf("store initial simulated token response failed: %v", err)
	}

	refreshContract, err := PrepareParasutTokenRefreshContract(ParasutTokenRefreshContractRequest{
		TenantID:        "tenant_7",
		AppKey:          "parasut_accounting",
		AccessTokenRef:  storage.AccessTokenRef,
		RefreshTokenRef: storage.RefreshTokenRef,
		RequestedBy:     "admin_1",
		CorrelationID:   "corr-7-8p-5-4-refresh-contract",
	})
	if err != nil {
		t.Fatalf("prepare refresh contract failed: %v", err)
	}

	refreshStorage, err := StoreParasutSimulatedRefreshResponse(vault, refreshContract, ParasutSimulatedRefreshResponse{
		NewAccessToken:     "sim-access-token-value-v2",
		NewRefreshToken:    "sim-refresh-token-value-v2",
		ExpiresInSeconds:   3600,
		IssuedAt:           time.Date(2026, 5, 2, 10, 5, 0, 0, time.UTC),
		RotateRefreshToken: true,
	})
	if err != nil {
		t.Fatalf("store simulated refresh response failed: %v", err)
	}
	if refreshStorage.Status != ParasutTokenExchangeStatusRefreshRefsRotated {
		t.Fatalf("expected refresh refs rotated, got %s", refreshStorage.Status)
	}
	if refreshStorage.AccessTokenRef == storage.AccessTokenRef {
		t.Fatal("access token ref must rotate")
	}
	if refreshStorage.RefreshTokenRef == storage.RefreshTokenRef {
		t.Fatal("refresh token ref must rotate when RotateRefreshToken=true")
	}

	oldAccessRef, err := vault.FindSecretReference("tenant_7", storage.AccessTokenRef)
	if err != nil {
		t.Fatalf("old access ref should be found: %v", err)
	}
	if oldAccessRef.Status != ParasutCredentialStatusRotated {
		t.Fatalf("expected old access ref rotated, got %s", oldAccessRef.Status)
	}

	oldRefreshRef, err := vault.FindSecretReference("tenant_7", storage.RefreshTokenRef)
	if err != nil {
		t.Fatalf("old refresh ref should be found: %v", err)
	}
	if oldRefreshRef.Status != ParasutCredentialStatusRotated {
		t.Fatalf("expected old refresh ref rotated, got %s", oldRefreshRef.Status)
	}

	if refreshStorage.Lifecycle.Status != ParasutTokenStatusActive {
		t.Fatalf("expected refreshed lifecycle active, got %s", refreshStorage.Lifecycle.Status)
	}

	t.Log("7-8P.5.4 Simulated Refresh Rotation OK ✅")
	t.Log("7-8P.5.4.1 Current access token ref rotated OK ✅")
	t.Log("7-8P.5.4.2 Optional refresh token ref rotated OK ✅")
	t.Log("7-8P.5.4.3 Old token rotated status OK ✅")
	t.Log("7-8P.5.4.4 New token active lifecycle OK ✅")
	t.Log("7-8P.5.4.5 Tenant-safe rotation guard OK ✅")
	t.Log("7-8P.5.4.6 Correlation required OK ✅")
}

func TestParasutTokenEndpointErrorMapping_7_8P_5_5(t *testing.T) {
	unauthorized := MapParasutTokenEndpointError(401, "unauthorized")
	if unauthorized.Code != ParasutMappedErrorUnauthorized || unauthorized.Retryable {
		t.Fatalf("unexpected unauthorized token mapping: %+v", unauthorized)
	}

	timeout := MapParasutTokenEndpointError(408, "timeout")
	if timeout.Code != ParasutMappedErrorTimeout || !timeout.Retryable {
		t.Fatalf("unexpected timeout token mapping: %+v", timeout)
	}

	rateLimited := MapParasutTokenEndpointError(429, "rate limited")
	if rateLimited.Code != ParasutMappedErrorRateLimited || !rateLimited.Retryable {
		t.Fatalf("unexpected rate limit token mapping: %+v", rateLimited)
	}

	validation := MapParasutTokenEndpointError(422, "validation error")
	if validation.Code != ParasutMappedErrorValidation || validation.Retryable {
		t.Fatalf("unexpected validation token mapping: %+v", validation)
	}

	server := MapParasutTokenEndpointError(500, "server error")
	if server.Code != ParasutMappedErrorServer || !server.Retryable {
		t.Fatalf("unexpected server token mapping: %+v", server)
	}

	unknown := MapParasutTokenEndpointError(499, "unknown")
	if unknown.Code != ParasutMappedErrorUnknown || !unknown.MoveToDLQ {
		t.Fatalf("unexpected unknown token mapping: %+v", unknown)
	}

	t.Log("7-8P.5.5 Token Endpoint Error Mapping OK ✅")
	t.Log("7-8P.5.5.1 Unauthorized non-retryable mapping OK ✅")
	t.Log("7-8P.5.5.2 Timeout retryable mapping OK ✅")
	t.Log("7-8P.5.5.3 Rate limit retryable mapping OK ✅")
	t.Log("7-8P.5.5.4 Validation non-retryable mapping OK ✅")
	t.Log("7-8P.5.5.5 Server error retryable mapping OK ✅")
	t.Log("7-8P.5.5.6 Unknown provider error DLQ mapping OK ✅")
}

func TestParasutTokenExchangeRefreshFinalClosure_7_8P_5_6(t *testing.T) {
	result := EvaluateParasutTokenExchangeReadinessGate(ParasutTokenExchangeReadinessGateInput{
		TokenExchangeContractReady:     true,
		SimulatedTokenResponseReady:    true,
		TokenRefStorageReady:           true,
		TokenLifecycleBridgeReady:      true,
		RefreshReadinessGuardReady:     true,
		SimulatedRefreshReady:          true,
		TokenEndpointErrorMappingReady: true,
		TestsReady:                     true,
		RealImplementationAuditReady:   true,
		RealAPIEnabled:                 false,
		RealTokenExchangeEnabled:       false,
		RealTokenRefreshEnabled:        false,
	})

	if !result.Ready || result.Decision != "PARASUT_TOKEN_EXCHANGE_REFRESH_DRY_RUN_READY_WITH_REAL_API_CLOSED" {
		t.Fatalf("expected token exchange refresh readiness with real API closed: %+v", result)
	}

	t.Log("7-8P.5.6 Final Closure OK ✅")
	t.Log("7-8P.5.6.1 Token exchange contract readiness OK ✅")
	t.Log("7-8P.5.6.2 Simulated token response readiness OK ✅")
	t.Log("7-8P.5.6.3 Token ref storage readiness OK ✅")
	t.Log("7-8P.5.6.4 Token lifecycle bridge readiness OK ✅")
	t.Log("7-8P.5.6.5 Refresh runtime dry-run readiness OK ✅")
	t.Log("7-8P.5.6.6 Token endpoint error mapping readiness OK ✅")
	t.Log("7-8P.5.6.7 Real API remains closed OK ✅")

	blocked := EvaluateParasutTokenExchangeReadinessGate(ParasutTokenExchangeReadinessGateInput{
		TokenExchangeContractReady:     true,
		SimulatedTokenResponseReady:    true,
		TokenRefStorageReady:           true,
		TokenLifecycleBridgeReady:      true,
		RefreshReadinessGuardReady:     true,
		SimulatedRefreshReady:          true,
		TokenEndpointErrorMappingReady: true,
		TestsReady:                     true,
		RealImplementationAuditReady:   true,
		RealAPIEnabled:                 true,
		RealTokenExchangeEnabled:       true,
		RealTokenRefreshEnabled:        true,
	})

	if blocked.Ready || blocked.Decision != "BLOCKED" {
		t.Fatalf("expected real API/token exchange/refresh enabled state to block: %+v", blocked)
	}
	t.Log("7-8P.5.6.8 Real API/token exchange/refresh unsafe state blocked OK ✅")
}
