package integrationruntime

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"net/url"
	"sort"
	"strings"
	"time"
)

type ParasutOAuthFlowStatus string

const (
	ParasutOAuthFlowStatusAuthorizationURLReady      ParasutOAuthFlowStatus = "AUTHORIZATION_URL_READY"
	ParasutOAuthFlowStatusCallbackAccepted           ParasutOAuthFlowStatus = "CALLBACK_ACCEPTED"
	ParasutOAuthFlowStatusCallbackProviderError      ParasutOAuthFlowStatus = "CALLBACK_PROVIDER_ERROR"
	ParasutOAuthFlowStatusTokenExchangeDryRunBlocked ParasutOAuthFlowStatus = "TOKEN_EXCHANGE_DRY_RUN_BLOCKED"
	ParasutOAuthFlowStatusTokenRefHandoffReady       ParasutOAuthFlowStatus = "TOKEN_REF_HANDOFF_READY"
)

type ParasutOAuthConnectSurfaceContract struct {
	PanelPath                string
	ButtonLabel              string
	CallbackPath             string
	AllowedRoles             []CredentialEntryRole
	MFARecommended           bool
	StateRequired            bool
	NonceRequired            bool
	RealTokenExchangeEnabled bool
}

func DefaultParasutOAuthConnectSurfaceContract() ParasutOAuthConnectSurfaceContract {
	return ParasutOAuthConnectSurfaceContract{
		PanelPath:    "Panel > Ayarlar > Entegrasyonlar > Paraşüt > Bağlan / API Bilgileri",
		ButtonLabel:  "Paraşüt’e Bağlan",
		CallbackPath: "/integrations/parasut/oauth/callback",
		AllowedRoles: []CredentialEntryRole{
			CredentialEntryRoleTenantAdmin,
			CredentialEntryRoleIntegrationAdmin,
		},
		MFARecommended:           true,
		StateRequired:            true,
		NonceRequired:            true,
		RealTokenExchangeEnabled: false,
	}
}

func (contract ParasutOAuthConnectSurfaceContract) CanRoleStartOAuth(role CredentialEntryRole) bool {
	for _, allowed := range contract.AllowedRoles {
		if allowed == role {
			return true
		}
	}
	return false
}

func ValidateParasutOAuthConnectSurfaceContract(contract ParasutOAuthConnectSurfaceContract) error {
	if err := requireNonEmpty(contract.PanelPath, "panel_path"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.ButtonLabel, "button_label"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.CallbackPath, "callback_path"); err != nil {
		return err
	}
	if !strings.Contains(contract.PanelPath, "Ayarlar") || !strings.Contains(contract.PanelPath, "Paraşüt") {
		return fmt.Errorf("%w: panel path must point to Paraşüt integration settings", ErrInvalidIntegrationRequest)
	}
	if !strings.HasPrefix(contract.CallbackPath, "/") {
		return fmt.Errorf("%w: callback path must start with slash", ErrInvalidIntegrationRequest)
	}
	if len(contract.AllowedRoles) == 0 {
		return fmt.Errorf("%w: oauth allowed roles required", ErrInvalidIntegrationRequest)
	}
	if !contract.StateRequired {
		return fmt.Errorf("%w: oauth state must be required", ErrInvalidIntegrationRequest)
	}
	if !contract.NonceRequired {
		return fmt.Errorf("%w: oauth nonce must be required", ErrInvalidIntegrationRequest)
	}
	if contract.RealTokenExchangeEnabled {
		return fmt.Errorf("%w: real token exchange must remain disabled in readiness phase", ErrInvalidIntegrationRequest)
	}
	return nil
}

type ParasutOAuthStateRequest struct {
	TenantID      string
	AppKey        string
	RequestedBy   string
	CorrelationID string
	Nonce         string
}

func BuildParasutOAuthState(req ParasutOAuthStateRequest) (string, error) {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return "", err
	}
	if err := requireNonEmpty(req.AppKey, "app_key"); err != nil {
		return "", err
	}
	if err := requireNonEmpty(req.RequestedBy, "requested_by"); err != nil {
		return "", err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return "", err
	}
	if err := requireNonEmpty(req.Nonce, "nonce"); err != nil {
		return "", err
	}

	raw := fmt.Sprintf("%s|%s|%s|%s|%s|%s", ParasutProviderKey, normalize(req.TenantID), normalize(req.AppKey), normalize(req.RequestedBy), normalize(req.CorrelationID), normalize(req.Nonce))
	sum := sha256.Sum256([]byte(raw))
	return "parasut_state_" + hex.EncodeToString(sum[:]), nil
}

type ParasutAuthorizationURLRequest struct {
	TenantID                 string
	AppKey                   string
	Role                     CredentialEntryRole
	ClientID                 string
	RedirectURI              string
	Scopes                   []string
	State                    string
	Nonce                    string
	RequestedBy              string
	CorrelationID            string
	AuthorizationBaseURL     string
	ProviderLiveModuleOpened bool
	RealAPIEnabled           bool
	Now                      time.Time
}

type ParasutAuthorizationURLResult struct {
	TenantID            string
	ProviderKey         string
	AppKey              string
	AuthorizationURL    string
	RedirectURI         string
	Scopes              []string
	State               string
	Nonce               string
	Status              ParasutOAuthFlowStatus
	RealRedirectEnabled bool
	AuditDecision       AuditDecision
	CorrelationID       string
	CreatedAt           time.Time
}

func BuildParasutAuthorizationURL(contract ParasutOAuthConnectSurfaceContract, req ParasutAuthorizationURLRequest) (ParasutAuthorizationURLResult, error) {
	if err := ValidateParasutOAuthConnectSurfaceContract(contract); err != nil {
		return ParasutAuthorizationURLResult{AuditDecision: AuditDecisionDenied}, err
	}
	if err := validateParasutAuthorizationURLRequest(contract, req); err != nil {
		return ParasutAuthorizationURLResult{AuditDecision: AuditDecisionDenied}, err
	}

	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	baseURL := normalize(req.AuthorizationBaseURL)
	if baseURL == "" {
		baseURL = "https://api.parasut.local/oauth/authorize"
	}

	parsed, err := url.Parse(baseURL)
	if err != nil {
		return ParasutAuthorizationURLResult{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: authorization_base_url invalid", ErrInvalidIntegrationRequest)
	}

	scopes := append([]string(nil), req.Scopes...)
	sort.Strings(scopes)

	query := parsed.Query()
	query.Set("client_id", normalize(req.ClientID))
	query.Set("redirect_uri", normalize(req.RedirectURI))
	query.Set("response_type", "code")
	query.Set("scope", strings.Join(scopes, " "))
	query.Set("state", normalize(req.State))
	query.Set("nonce", normalize(req.Nonce))
	parsed.RawQuery = query.Encode()

	return ParasutAuthorizationURLResult{
		TenantID:            normalize(req.TenantID),
		ProviderKey:         ParasutProviderKey,
		AppKey:              normalize(req.AppKey),
		AuthorizationURL:    parsed.String(),
		RedirectURI:         normalize(req.RedirectURI),
		Scopes:              scopes,
		State:               normalize(req.State),
		Nonce:               normalize(req.Nonce),
		Status:              ParasutOAuthFlowStatusAuthorizationURLReady,
		RealRedirectEnabled: false,
		AuditDecision:       AuditDecisionAllowed,
		CorrelationID:       normalize(req.CorrelationID),
		CreatedAt:           now,
	}, nil
}

func validateParasutAuthorizationURLRequest(contract ParasutOAuthConnectSurfaceContract, req ParasutAuthorizationURLRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AppKey, "app_key"); err != nil {
		return err
	}
	if req.Role == "" {
		return fmt.Errorf("%w: oauth role required", ErrInvalidIntegrationRequest)
	}
	if !contract.CanRoleStartOAuth(req.Role) {
		return fmt.Errorf("%w: oauth role not allowed", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.ClientID, "client_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.RedirectURI, "redirect_uri"); err != nil {
		return err
	}
	if _, err := url.ParseRequestURI(req.RedirectURI); err != nil {
		return fmt.Errorf("%w: redirect_uri invalid", ErrInvalidIntegrationRequest)
	}
	if len(req.Scopes) == 0 {
		return fmt.Errorf("%w: at least one oauth scope required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.State, "state"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.Nonce, "nonce"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if req.RealAPIEnabled && !req.ProviderLiveModuleOpened {
		return fmt.Errorf("%w: real oauth redirect cannot be enabled before provider live module", ErrInvalidIntegrationRequest)
	}
	return nil
}

type ParasutOAuthCallbackRequest struct {
	TenantID                 string
	AppKey                   string
	AuthorizationCode        string
	CallbackError            string
	CallbackErrorDescription string
	ExpectedState            string
	ReceivedState            string
	Nonce                    string
	RequestedBy              string
	CorrelationID            string
	ProviderLiveModuleOpened bool
	RealAPIEnabled           bool
	Now                      time.Time
}

type ParasutOAuthCallbackResult struct {
	TenantID           string
	ProviderKey        string
	AppKey             string
	AuthorizationCode  string
	Status             ParasutOAuthFlowStatus
	TokenExchangeReady bool
	Message            string
	AuditDecision      AuditDecision
	CorrelationID      string
	CreatedAt          time.Time
}

func HandleParasutOAuthCallback(req ParasutOAuthCallbackRequest) (ParasutOAuthCallbackResult, error) {
	if err := validateParasutOAuthCallbackRequest(req); err != nil {
		return ParasutOAuthCallbackResult{AuditDecision: AuditDecisionDenied}, err
	}

	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	if normalize(req.CallbackError) != "" {
		return ParasutOAuthCallbackResult{
			TenantID:           normalize(req.TenantID),
			ProviderKey:        ParasutProviderKey,
			AppKey:             normalize(req.AppKey),
			Status:             ParasutOAuthFlowStatusCallbackProviderError,
			TokenExchangeReady: false,
			Message:            normalize(req.CallbackErrorDescription),
			AuditDecision:      AuditDecisionDenied,
			CorrelationID:      normalize(req.CorrelationID),
			CreatedAt:          now,
		}, nil
	}

	status := ParasutOAuthFlowStatusCallbackAccepted
	tokenExchangeReady := true
	message := "Paraşüt OAuth callback accepted."

	if !req.ProviderLiveModuleOpened || !req.RealAPIEnabled {
		status = ParasutOAuthFlowStatusTokenExchangeDryRunBlocked
		tokenExchangeReady = false
		message = "Paraşüt token exchange kapalı; provider live module ve real API approval gerekir."
	}

	return ParasutOAuthCallbackResult{
		TenantID:           normalize(req.TenantID),
		ProviderKey:        ParasutProviderKey,
		AppKey:             normalize(req.AppKey),
		AuthorizationCode:  normalize(req.AuthorizationCode),
		Status:             status,
		TokenExchangeReady: tokenExchangeReady,
		Message:            message,
		AuditDecision:      AuditDecisionAllowed,
		CorrelationID:      normalize(req.CorrelationID),
		CreatedAt:          now,
	}, nil
}

func validateParasutOAuthCallbackRequest(req ParasutOAuthCallbackRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.ExpectedState, "expected_state"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.ReceivedState, "received_state"); err != nil {
		return err
	}
	if normalize(req.ExpectedState) != normalize(req.ReceivedState) {
		return fmt.Errorf("%w: oauth state mismatch", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.Nonce, "nonce"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if normalize(req.CallbackError) == "" {
		if err := requireNonEmpty(req.AuthorizationCode, "authorization_code"); err != nil {
			return err
		}
	}
	if req.RealAPIEnabled && !req.ProviderLiveModuleOpened {
		return fmt.Errorf("%w: real token exchange cannot be enabled before provider live module", ErrInvalidIntegrationRequest)
	}
	return nil
}

type ParasutOAuthTokenRefHandoffRequest struct {
	TenantID        string
	AppKey          string
	AccessTokenRef  string
	RefreshTokenRef string
	CorrelationID   string
	CreatedBy       string
	Now             time.Time
}

type ParasutOAuthTokenRefHandoffResult struct {
	TenantID        string
	ProviderKey     string
	AppKey          string
	AccessTokenRef  string
	RefreshTokenRef string
	Status          ParasutOAuthFlowStatus
	AuditDecision   AuditDecision
	CorrelationID   string
	CreatedAt       time.Time
}

func BuildParasutOAuthTokenRefHandoff(req ParasutOAuthTokenRefHandoffRequest) (ParasutOAuthTokenRefHandoffResult, error) {
	if err := validateParasutOAuthTokenRefHandoffRequest(req); err != nil {
		return ParasutOAuthTokenRefHandoffResult{AuditDecision: AuditDecisionDenied}, err
	}

	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	return ParasutOAuthTokenRefHandoffResult{
		TenantID:        normalize(req.TenantID),
		ProviderKey:     ParasutProviderKey,
		AppKey:          normalize(req.AppKey),
		AccessTokenRef:  normalize(req.AccessTokenRef),
		RefreshTokenRef: normalize(req.RefreshTokenRef),
		Status:          ParasutOAuthFlowStatusTokenRefHandoffReady,
		AuditDecision:   AuditDecisionAllowed,
		CorrelationID:   normalize(req.CorrelationID),
		CreatedAt:       now,
	}, nil
}

func validateParasutOAuthTokenRefHandoffRequest(req ParasutOAuthTokenRefHandoffRequest) error {
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
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CreatedBy, "created_by"); err != nil {
		return err
	}
	if !isParasutSecretRefForTenant(req.TenantID, req.AccessTokenRef) {
		return fmt.Errorf("%w: access_token_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	if !isParasutSecretRefForTenant(req.TenantID, req.RefreshTokenRef) {
		return fmt.Errorf("%w: refresh_token_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	return nil
}

type ParasutOAuthFlowReadinessGateInput struct {
	ConnectButtonReady           bool
	AuthorizationURLReady        bool
	CallbackIntakeReady          bool
	StateNonceGuardReady         bool
	TokenExchangeDryRunGateReady bool
	TokenRefHandoffReady         bool
	TestsReady                   bool
	RealImplementationAuditReady bool
	RealAPIEnabled               bool
	RealTokenExchangeEnabled     bool
}

type ParasutOAuthFlowReadinessGateResult struct {
	Ready    bool
	Decision string
	Blockers []string
}

func EvaluateParasutOAuthFlowReadinessGate(input ParasutOAuthFlowReadinessGateInput) ParasutOAuthFlowReadinessGateResult {
	blockers := []string{}

	if !input.ConnectButtonReady {
		blockers = append(blockers, "connect_button_not_ready")
	}
	if !input.AuthorizationURLReady {
		blockers = append(blockers, "authorization_url_not_ready")
	}
	if !input.CallbackIntakeReady {
		blockers = append(blockers, "callback_intake_not_ready")
	}
	if !input.StateNonceGuardReady {
		blockers = append(blockers, "state_nonce_guard_not_ready")
	}
	if !input.TokenExchangeDryRunGateReady {
		blockers = append(blockers, "token_exchange_dry_run_gate_not_ready")
	}
	if !input.TokenRefHandoffReady {
		blockers = append(blockers, "token_ref_handoff_not_ready")
	}
	if !input.TestsReady {
		blockers = append(blockers, "tests_not_ready")
	}
	if !input.RealImplementationAuditReady {
		blockers = append(blockers, "real_implementation_audit_not_ready")
	}
	if input.RealAPIEnabled {
		blockers = append(blockers, "real_api_enabled_must_remain_false_in_oauth_flow_phase")
	}
	if input.RealTokenExchangeEnabled {
		blockers = append(blockers, "real_token_exchange_must_remain_false_in_oauth_flow_phase")
	}

	if len(blockers) > 0 {
		return ParasutOAuthFlowReadinessGateResult{
			Ready:    false,
			Decision: "BLOCKED",
			Blockers: blockers,
		}
	}

	return ParasutOAuthFlowReadinessGateResult{
		Ready:    true,
		Decision: "PARASUT_OAUTH_FLOW_READY_WITH_REAL_API_CLOSED",
		Blockers: []string{},
	}
}
