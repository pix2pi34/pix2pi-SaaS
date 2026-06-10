package integrationruntime

import (
	"fmt"
	"net/url"
	"time"
)

type ParasutTokenExchangeRuntimeStatus string

const (
	ParasutTokenExchangeStatusRequestReady         ParasutTokenExchangeRuntimeStatus = "TOKEN_EXCHANGE_REQUEST_READY"
	ParasutTokenExchangeStatusDryRunBlocked        ParasutTokenExchangeRuntimeStatus = "TOKEN_EXCHANGE_DRY_RUN_BLOCKED"
	ParasutTokenExchangeStatusSimulatedRefsStored  ParasutTokenExchangeRuntimeStatus = "SIMULATED_TOKEN_REFS_STORED"
	ParasutTokenExchangeStatusRefreshDryRunBlocked ParasutTokenExchangeRuntimeStatus = "REFRESH_DRY_RUN_BLOCKED"
	ParasutTokenExchangeStatusRefreshRefsRotated   ParasutTokenExchangeRuntimeStatus = "SIMULATED_REFRESH_REFS_ROTATED"
)

type ParasutTokenExchangeContractRequest struct {
	TenantID                 string
	AppKey                   string
	AuthorizationCode        string
	RedirectURI              string
	ClientID                 string
	ClientSecretRef          string
	RequestedBy              string
	CorrelationID            string
	ProviderLiveModuleOpened bool
	RealTokenExchangeEnabled bool
	Now                      time.Time
}

type ParasutTokenExchangeContractResult struct {
	TenantID           string
	ProviderKey        string
	AppKey             string
	AuthorizationCode  string
	RedirectURI        string
	ClientID           string
	ClientSecretRef    string
	Status             ParasutTokenExchangeRuntimeStatus
	TokenExchangeReady bool
	Message            string
	AuditDecision      AuditDecision
	RequestedBy        string
	CorrelationID      string
	CreatedAt          time.Time
}

func PrepareParasutTokenExchangeContract(req ParasutTokenExchangeContractRequest) (ParasutTokenExchangeContractResult, error) {
	if err := validateParasutTokenExchangeContractRequest(req); err != nil {
		return ParasutTokenExchangeContractResult{AuditDecision: AuditDecisionDenied}, err
	}

	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	return ParasutTokenExchangeContractResult{
		TenantID:           normalize(req.TenantID),
		ProviderKey:        ParasutProviderKey,
		AppKey:             normalize(req.AppKey),
		AuthorizationCode:  normalize(req.AuthorizationCode),
		RedirectURI:        normalize(req.RedirectURI),
		ClientID:           normalize(req.ClientID),
		ClientSecretRef:    normalize(req.ClientSecretRef),
		Status:             ParasutTokenExchangeStatusDryRunBlocked,
		TokenExchangeReady: false,
		Message:            "Paraşüt real token exchange kapalı; simulated token response kullanılabilir.",
		AuditDecision:      AuditDecisionAllowed,
		RequestedBy:        normalize(req.RequestedBy),
		CorrelationID:      normalize(req.CorrelationID),
		CreatedAt:          now,
	}, nil
}

func validateParasutTokenExchangeContractRequest(req ParasutTokenExchangeContractRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AuthorizationCode, "authorization_code"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.RedirectURI, "redirect_uri"); err != nil {
		return err
	}
	if _, err := url.ParseRequestURI(req.RedirectURI); err != nil {
		return fmt.Errorf("%w: redirect_uri invalid", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.ClientID, "client_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.ClientSecretRef, "client_secret_ref"); err != nil {
		return err
	}
	if !isParasutSecretRefForTenant(req.TenantID, req.ClientSecretRef) {
		return fmt.Errorf("%w: client_secret_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if req.RealTokenExchangeEnabled {
		return fmt.Errorf("%w: real token exchange must remain disabled in dry-run readiness phase", ErrInvalidIntegrationRequest)
	}
	if req.ProviderLiveModuleOpened && req.RealTokenExchangeEnabled {
		return fmt.Errorf("%w: provider live module token exchange belongs to later phase", ErrInvalidIntegrationRequest)
	}
	return nil
}

type ParasutSimulatedTokenResponse struct {
	AccessToken      string
	RefreshToken     string
	ExpiresInSeconds int64
	IssuedAt         time.Time
}

type ParasutTokenExchangeStorageResult struct {
	TenantID           string
	ProviderKey        string
	AppKey             string
	AccessTokenRef     string
	RefreshTokenRef    string
	Handoff            ParasutOAuthTokenRefHandoffResult
	Lifecycle          ParasutTokenLifecycle
	Status             ParasutTokenExchangeRuntimeStatus
	PlaintextPersisted bool
	AuditDecision      AuditDecision
	CorrelationID      string
	CreatedAt          time.Time
}

func StoreParasutSimulatedTokenResponse(
	vault *InMemoryParasutCredentialVault,
	contract ParasutTokenExchangeContractResult,
	response ParasutSimulatedTokenResponse,
) (ParasutTokenExchangeStorageResult, error) {
	if vault == nil {
		return ParasutTokenExchangeStorageResult{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: credential vault required", ErrInvalidIntegrationRequest)
	}
	if err := validateParasutTokenExchangeContractResult(contract); err != nil {
		return ParasutTokenExchangeStorageResult{AuditDecision: AuditDecisionDenied}, err
	}
	if err := validateParasutSimulatedTokenResponse(response); err != nil {
		return ParasutTokenExchangeStorageResult{AuditDecision: AuditDecisionDenied}, err
	}

	issuedAt := response.IssuedAt
	if issuedAt.IsZero() {
		issuedAt = time.Now().UTC()
	}

	accessRef, err := vault.StoreSecret(ParasutStoreSecretRequest{
		TenantID:      contract.TenantID,
		AppKey:        contract.AppKey,
		SecretKind:    ParasutSecretKindAccessToken,
		RawSecret:     response.AccessToken,
		CreatedBy:     contract.RequestedBy,
		CorrelationID: contract.CorrelationID,
		Now:           issuedAt,
	})
	if err != nil {
		return ParasutTokenExchangeStorageResult{AuditDecision: AuditDecisionDenied}, err
	}

	refreshRef, err := vault.StoreSecret(ParasutStoreSecretRequest{
		TenantID:      contract.TenantID,
		AppKey:        contract.AppKey,
		SecretKind:    ParasutSecretKindRefreshToken,
		RawSecret:     response.RefreshToken,
		CreatedBy:     contract.RequestedBy,
		CorrelationID: contract.CorrelationID,
		Now:           issuedAt,
	})
	if err != nil {
		return ParasutTokenExchangeStorageResult{AuditDecision: AuditDecisionDenied}, err
	}

	handoff, err := BuildParasutOAuthTokenRefHandoff(ParasutOAuthTokenRefHandoffRequest{
		TenantID:        contract.TenantID,
		AppKey:          contract.AppKey,
		AccessTokenRef:  accessRef.SecretRef,
		RefreshTokenRef: refreshRef.SecretRef,
		CorrelationID:   contract.CorrelationID,
		CreatedBy:       contract.RequestedBy,
		Now:             issuedAt,
	})
	if err != nil {
		return ParasutTokenExchangeStorageResult{AuditDecision: AuditDecisionDenied}, err
	}

	lifecycle, err := BuildParasutTokenLifecycle(ParasutTokenLifecycleRequest{
		TenantID:        contract.TenantID,
		AccessTokenRef:  accessRef.SecretRef,
		RefreshTokenRef: refreshRef.SecretRef,
		IssuedAt:        issuedAt,
		ExpiresAt:       issuedAt.Add(time.Duration(response.ExpiresInSeconds) * time.Second),
		RefreshWindow:   10 * time.Minute,
		CorrelationID:   contract.CorrelationID,
		Now:             issuedAt,
	})
	if err != nil {
		return ParasutTokenExchangeStorageResult{AuditDecision: AuditDecisionDenied}, err
	}

	return ParasutTokenExchangeStorageResult{
		TenantID:           contract.TenantID,
		ProviderKey:        ParasutProviderKey,
		AppKey:             contract.AppKey,
		AccessTokenRef:     accessRef.SecretRef,
		RefreshTokenRef:    refreshRef.SecretRef,
		Handoff:            handoff,
		Lifecycle:          lifecycle,
		Status:             ParasutTokenExchangeStatusSimulatedRefsStored,
		PlaintextPersisted: false,
		AuditDecision:      AuditDecisionAllowed,
		CorrelationID:      contract.CorrelationID,
		CreatedAt:          issuedAt,
	}, nil
}

func validateParasutTokenExchangeContractResult(contract ParasutTokenExchangeContractResult) error {
	if err := requireNonEmpty(contract.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.AuthorizationCode, "authorization_code"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.ClientSecretRef, "client_secret_ref"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if !isParasutSecretRefForTenant(contract.TenantID, contract.ClientSecretRef) {
		return fmt.Errorf("%w: client_secret_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	return nil
}

func validateParasutSimulatedTokenResponse(response ParasutSimulatedTokenResponse) error {
	if err := requireNonEmpty(response.AccessToken, "access_token"); err != nil {
		return err
	}
	if err := requireNonEmpty(response.RefreshToken, "refresh_token"); err != nil {
		return err
	}
	if len(response.AccessToken) < 8 {
		return fmt.Errorf("%w: access_token too short", ErrInvalidIntegrationRequest)
	}
	if len(response.RefreshToken) < 8 {
		return fmt.Errorf("%w: refresh_token too short", ErrInvalidIntegrationRequest)
	}
	if response.ExpiresInSeconds <= 0 {
		return fmt.Errorf("%w: expires_in_seconds must be positive", ErrInvalidIntegrationRequest)
	}
	return nil
}

type ParasutAccessTokenRefreshNeed struct {
	NeedsRefresh bool
	Allowed      bool
	Reason       string
}

func EvaluateParasutAccessTokenRefreshNeed(lifecycle ParasutTokenLifecycle) ParasutAccessTokenRefreshNeed {
	switch lifecycle.Status {
	case ParasutTokenStatusActive:
		return ParasutAccessTokenRefreshNeed{
			NeedsRefresh: false,
			Allowed:      false,
			Reason:       "active_token_refresh_not_required",
		}
	case ParasutTokenStatusRefreshRequired:
		return ParasutAccessTokenRefreshNeed{
			NeedsRefresh: true,
			Allowed:      true,
			Reason:       "refresh_required",
		}
	case ParasutTokenStatusExpired:
		return ParasutAccessTokenRefreshNeed{
			NeedsRefresh: true,
			Allowed:      true,
			Reason:       "access_token_expired_refresh_allowed",
		}
	case ParasutTokenStatusRevoked:
		return ParasutAccessTokenRefreshNeed{
			NeedsRefresh: false,
			Allowed:      false,
			Reason:       "revoked_token_refresh_blocked",
		}
	default:
		return ParasutAccessTokenRefreshNeed{
			NeedsRefresh: false,
			Allowed:      false,
			Reason:       "unknown_token_status",
		}
	}
}

type ParasutTokenRefreshContractRequest struct {
	TenantID                 string
	AppKey                   string
	AccessTokenRef           string
	RefreshTokenRef          string
	RequestedBy              string
	CorrelationID            string
	ProviderLiveModuleOpened bool
	RealTokenRefreshEnabled  bool
	Now                      time.Time
}

type ParasutTokenRefreshContractResult struct {
	TenantID        string
	ProviderKey     string
	AppKey          string
	AccessTokenRef  string
	RefreshTokenRef string
	Status          ParasutTokenExchangeRuntimeStatus
	RefreshReady    bool
	Message         string
	AuditDecision   AuditDecision
	RequestedBy     string
	CorrelationID   string
	CreatedAt       time.Time
}

func PrepareParasutTokenRefreshContract(req ParasutTokenRefreshContractRequest) (ParasutTokenRefreshContractResult, error) {
	if err := validateParasutTokenRefreshContractRequest(req); err != nil {
		return ParasutTokenRefreshContractResult{AuditDecision: AuditDecisionDenied}, err
	}

	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	return ParasutTokenRefreshContractResult{
		TenantID:        normalize(req.TenantID),
		ProviderKey:     ParasutProviderKey,
		AppKey:          normalize(req.AppKey),
		AccessTokenRef:  normalize(req.AccessTokenRef),
		RefreshTokenRef: normalize(req.RefreshTokenRef),
		Status:          ParasutTokenExchangeStatusRefreshDryRunBlocked,
		RefreshReady:    false,
		Message:         "Paraşüt real token refresh kapalı; simulated refresh response kullanılabilir.",
		AuditDecision:   AuditDecisionAllowed,
		RequestedBy:     normalize(req.RequestedBy),
		CorrelationID:   normalize(req.CorrelationID),
		CreatedAt:       now,
	}, nil
}

func validateParasutTokenRefreshContractRequest(req ParasutTokenRefreshContractRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AccessTokenRef, "access_token_ref"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.RefreshTokenRef, "refresh_token_ref"); err != nil {
		return err
	}
	if !isParasutSecretRefForTenant(req.TenantID, req.AccessTokenRef) {
		return fmt.Errorf("%w: access_token_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	if !isParasutSecretRefForTenant(req.TenantID, req.RefreshTokenRef) {
		return fmt.Errorf("%w: refresh_token_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if req.RealTokenRefreshEnabled {
		return fmt.Errorf("%w: real token refresh must remain disabled in dry-run readiness phase", ErrInvalidIntegrationRequest)
	}
	return nil
}

type ParasutSimulatedRefreshResponse struct {
	NewAccessToken     string
	NewRefreshToken    string
	ExpiresInSeconds   int64
	IssuedAt           time.Time
	RotateRefreshToken bool
}

type ParasutTokenRefreshStorageResult struct {
	TenantID           string
	ProviderKey        string
	AppKey             string
	AccessTokenRef     string
	RefreshTokenRef    string
	Lifecycle          ParasutTokenLifecycle
	Status             ParasutTokenExchangeRuntimeStatus
	PlaintextPersisted bool
	AuditDecision      AuditDecision
	CorrelationID      string
	CreatedAt          time.Time
}

func StoreParasutSimulatedRefreshResponse(
	vault *InMemoryParasutCredentialVault,
	contract ParasutTokenRefreshContractResult,
	response ParasutSimulatedRefreshResponse,
) (ParasutTokenRefreshStorageResult, error) {
	if vault == nil {
		return ParasutTokenRefreshStorageResult{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: credential vault required", ErrInvalidIntegrationRequest)
	}
	if err := validateParasutTokenRefreshContractResult(contract); err != nil {
		return ParasutTokenRefreshStorageResult{AuditDecision: AuditDecisionDenied}, err
	}
	if err := validateParasutSimulatedRefreshResponse(response); err != nil {
		return ParasutTokenRefreshStorageResult{AuditDecision: AuditDecisionDenied}, err
	}

	issuedAt := response.IssuedAt
	if issuedAt.IsZero() {
		issuedAt = time.Now().UTC()
	}

	accessRef, err := vault.RotateSecret(ParasutRotateSecretRequest{
		TenantID:      contract.TenantID,
		AppKey:        contract.AppKey,
		SecretKind:    ParasutSecretKindAccessToken,
		OldSecretRef:  contract.AccessTokenRef,
		NewRawSecret:  response.NewAccessToken,
		RotatedBy:     contract.RequestedBy,
		CorrelationID: contract.CorrelationID,
		Now:           issuedAt,
	})
	if err != nil {
		return ParasutTokenRefreshStorageResult{AuditDecision: AuditDecisionDenied}, err
	}

	refreshTokenRef := contract.RefreshTokenRef
	if response.RotateRefreshToken {
		refreshRef, err := vault.RotateSecret(ParasutRotateSecretRequest{
			TenantID:      contract.TenantID,
			AppKey:        contract.AppKey,
			SecretKind:    ParasutSecretKindRefreshToken,
			OldSecretRef:  contract.RefreshTokenRef,
			NewRawSecret:  response.NewRefreshToken,
			RotatedBy:     contract.RequestedBy,
			CorrelationID: contract.CorrelationID,
			Now:           issuedAt,
		})
		if err != nil {
			return ParasutTokenRefreshStorageResult{AuditDecision: AuditDecisionDenied}, err
		}
		refreshTokenRef = refreshRef.SecretRef
	}

	lifecycle, err := BuildParasutTokenLifecycle(ParasutTokenLifecycleRequest{
		TenantID:        contract.TenantID,
		AccessTokenRef:  accessRef.SecretRef,
		RefreshTokenRef: refreshTokenRef,
		IssuedAt:        issuedAt,
		ExpiresAt:       issuedAt.Add(time.Duration(response.ExpiresInSeconds) * time.Second),
		RefreshWindow:   10 * time.Minute,
		CorrelationID:   contract.CorrelationID,
		Now:             issuedAt,
	})
	if err != nil {
		return ParasutTokenRefreshStorageResult{AuditDecision: AuditDecisionDenied}, err
	}

	return ParasutTokenRefreshStorageResult{
		TenantID:           contract.TenantID,
		ProviderKey:        ParasutProviderKey,
		AppKey:             contract.AppKey,
		AccessTokenRef:     accessRef.SecretRef,
		RefreshTokenRef:    refreshTokenRef,
		Lifecycle:          lifecycle,
		Status:             ParasutTokenExchangeStatusRefreshRefsRotated,
		PlaintextPersisted: false,
		AuditDecision:      AuditDecisionAllowed,
		CorrelationID:      contract.CorrelationID,
		CreatedAt:          issuedAt,
	}, nil
}

func validateParasutTokenRefreshContractResult(contract ParasutTokenRefreshContractResult) error {
	if err := requireNonEmpty(contract.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.AccessTokenRef, "access_token_ref"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.RefreshTokenRef, "refresh_token_ref"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if !isParasutSecretRefForTenant(contract.TenantID, contract.AccessTokenRef) {
		return fmt.Errorf("%w: access_token_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	if !isParasutSecretRefForTenant(contract.TenantID, contract.RefreshTokenRef) {
		return fmt.Errorf("%w: refresh_token_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	return nil
}

func validateParasutSimulatedRefreshResponse(response ParasutSimulatedRefreshResponse) error {
	if err := requireNonEmpty(response.NewAccessToken, "new_access_token"); err != nil {
		return err
	}
	if len(response.NewAccessToken) < 8 {
		return fmt.Errorf("%w: new_access_token too short", ErrInvalidIntegrationRequest)
	}
	if response.RotateRefreshToken {
		if err := requireNonEmpty(response.NewRefreshToken, "new_refresh_token"); err != nil {
			return err
		}
		if len(response.NewRefreshToken) < 8 {
			return fmt.Errorf("%w: new_refresh_token too short", ErrInvalidIntegrationRequest)
		}
	}
	if response.ExpiresInSeconds <= 0 {
		return fmt.Errorf("%w: expires_in_seconds must be positive", ErrInvalidIntegrationRequest)
	}
	return nil
}

func MapParasutTokenEndpointError(httpStatus int, providerMessage string) ParasutProviderErrorMapping {
	return MapParasutProviderError(httpStatus, providerMessage)
}

type ParasutTokenExchangeReadinessGateInput struct {
	TokenExchangeContractReady     bool
	SimulatedTokenResponseReady    bool
	TokenRefStorageReady           bool
	TokenLifecycleBridgeReady      bool
	RefreshReadinessGuardReady     bool
	SimulatedRefreshReady          bool
	TokenEndpointErrorMappingReady bool
	TestsReady                     bool
	RealImplementationAuditReady   bool
	RealAPIEnabled                 bool
	RealTokenExchangeEnabled       bool
	RealTokenRefreshEnabled        bool
}

type ParasutTokenExchangeReadinessGateResult struct {
	Ready    bool
	Decision string
	Blockers []string
}

func EvaluateParasutTokenExchangeReadinessGate(input ParasutTokenExchangeReadinessGateInput) ParasutTokenExchangeReadinessGateResult {
	blockers := []string{}

	if !input.TokenExchangeContractReady {
		blockers = append(blockers, "token_exchange_contract_not_ready")
	}
	if !input.SimulatedTokenResponseReady {
		blockers = append(blockers, "simulated_token_response_not_ready")
	}
	if !input.TokenRefStorageReady {
		blockers = append(blockers, "token_ref_storage_not_ready")
	}
	if !input.TokenLifecycleBridgeReady {
		blockers = append(blockers, "token_lifecycle_bridge_not_ready")
	}
	if !input.RefreshReadinessGuardReady {
		blockers = append(blockers, "refresh_readiness_guard_not_ready")
	}
	if !input.SimulatedRefreshReady {
		blockers = append(blockers, "simulated_refresh_not_ready")
	}
	if !input.TokenEndpointErrorMappingReady {
		blockers = append(blockers, "token_endpoint_error_mapping_not_ready")
	}
	if !input.TestsReady {
		blockers = append(blockers, "tests_not_ready")
	}
	if !input.RealImplementationAuditReady {
		blockers = append(blockers, "real_implementation_audit_not_ready")
	}
	if input.RealAPIEnabled {
		blockers = append(blockers, "real_api_enabled_must_remain_false_in_token_exchange_phase")
	}
	if input.RealTokenExchangeEnabled {
		blockers = append(blockers, "real_token_exchange_must_remain_false_in_token_exchange_phase")
	}
	if input.RealTokenRefreshEnabled {
		blockers = append(blockers, "real_token_refresh_must_remain_false_in_token_exchange_phase")
	}

	if len(blockers) > 0 {
		return ParasutTokenExchangeReadinessGateResult{
			Ready:    false,
			Decision: "BLOCKED",
			Blockers: blockers,
		}
	}

	return ParasutTokenExchangeReadinessGateResult{
		Ready:    true,
		Decision: "PARASUT_TOKEN_EXCHANGE_REFRESH_DRY_RUN_READY_WITH_REAL_API_CLOSED",
		Blockers: []string{},
	}
}
