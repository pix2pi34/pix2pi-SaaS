package integrationruntime

import (
	"fmt"
	"net/url"
	"strings"
	"time"
)

type ParasutOAuthCredentialContract struct {
	TenantID           string
	AppKey             string
	Environment        ParasutEnvironment
	ClientID           string
	ClientSecretRef    string
	RedirectURI        string
	Scopes             []string
	WebhookSecretRef   string
	RequestedBy        string
	CorrelationID      string
	ProductionApproved bool
	RealAPIEnabled     bool
}

type ParasutOAuthCredentialContractResult struct {
	TenantID         string
	ProviderKey      string
	AppKey           string
	Environment      ParasutEnvironment
	ClientID         string
	ClientSecretRef  string
	RedirectURI      string
	Scopes           []string
	WebhookSecretRef string
	RequestedBy      string
	CorrelationID    string
	RealAPIEnabled   bool
	AuditDecision    AuditDecision
}

func BuildParasutOAuthCredentialContract(contract ParasutOAuthCredentialContract) (ParasutOAuthCredentialContractResult, error) {
	if err := ValidateParasutOAuthCredentialContract(contract); err != nil {
		return ParasutOAuthCredentialContractResult{AuditDecision: AuditDecisionDenied}, err
	}

	return ParasutOAuthCredentialContractResult{
		TenantID:         normalize(contract.TenantID),
		ProviderKey:      ParasutProviderKey,
		AppKey:           normalize(contract.AppKey),
		Environment:      contract.Environment,
		ClientID:         normalize(contract.ClientID),
		ClientSecretRef:  normalize(contract.ClientSecretRef),
		RedirectURI:      normalize(contract.RedirectURI),
		Scopes:           copySortedStrings(contract.Scopes),
		WebhookSecretRef: normalize(contract.WebhookSecretRef),
		RequestedBy:      normalize(contract.RequestedBy),
		CorrelationID:    normalize(contract.CorrelationID),
		RealAPIEnabled:   false,
		AuditDecision:    AuditDecisionAllowed,
	}, nil
}

func ValidateParasutOAuthCredentialContract(contract ParasutOAuthCredentialContract) error {
	if err := requireNonEmpty(contract.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.AppKey, "app_key"); err != nil {
		return err
	}
	if contract.Environment == "" {
		return fmt.Errorf("%w: parasut oauth environment required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(contract.ClientID, "client_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.ClientSecretRef, "client_secret_ref"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.RedirectURI, "redirect_uri"); err != nil {
		return err
	}
	if _, err := url.ParseRequestURI(contract.RedirectURI); err != nil {
		return fmt.Errorf("%w: redirect_uri invalid", ErrInvalidIntegrationRequest)
	}
	if len(contract.Scopes) == 0 {
		return fmt.Errorf("%w: at least one oauth scope required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(contract.WebhookSecretRef, "webhook_secret_ref"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if contract.RealAPIEnabled {
		return fmt.Errorf("%w: parasut real api enabled is closed in contract readiness phase", ErrInvalidIntegrationRequest)
	}
	if contract.Environment == ParasutEnvironmentProduction && !contract.ProductionApproved {
		return fmt.Errorf("%w: parasut production approval required for production contract", ErrInvalidIntegrationRequest)
	}
	return nil
}

type ParasutTokenStatus string

const (
	ParasutTokenStatusActive          ParasutTokenStatus = "ACTIVE"
	ParasutTokenStatusRefreshRequired ParasutTokenStatus = "REFRESH_REQUIRED"
	ParasutTokenStatusExpired         ParasutTokenStatus = "EXPIRED"
	ParasutTokenStatusRevoked         ParasutTokenStatus = "REVOKED"
)

type ParasutTokenLifecycleRequest struct {
	TenantID        string
	AccessTokenRef  string
	RefreshTokenRef string
	IssuedAt        time.Time
	ExpiresAt       time.Time
	RefreshWindow   time.Duration
	CorrelationID   string
	Revoked         bool
	Now             time.Time
}

type ParasutTokenLifecycle struct {
	TenantID        string
	ProviderKey     string
	AccessTokenRef  string
	RefreshTokenRef string
	IssuedAt        time.Time
	ExpiresAt       time.Time
	RefreshWindow   time.Duration
	Status          ParasutTokenStatus
	CorrelationID   string
}

func BuildParasutTokenLifecycle(req ParasutTokenLifecycleRequest) (ParasutTokenLifecycle, error) {
	if err := validateParasutTokenLifecycleRequest(req); err != nil {
		return ParasutTokenLifecycle{}, err
	}

	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	refreshWindow := req.RefreshWindow
	if refreshWindow <= 0 {
		refreshWindow = 10 * time.Minute
	}

	status := ParasutTokenStatusActive
	if req.Revoked {
		status = ParasutTokenStatusRevoked
	} else if !req.ExpiresAt.After(now) {
		status = ParasutTokenStatusExpired
	} else if req.ExpiresAt.Sub(now) <= refreshWindow {
		status = ParasutTokenStatusRefreshRequired
	}

	return ParasutTokenLifecycle{
		TenantID:        normalize(req.TenantID),
		ProviderKey:     ParasutProviderKey,
		AccessTokenRef:  normalize(req.AccessTokenRef),
		RefreshTokenRef: normalize(req.RefreshTokenRef),
		IssuedAt:        req.IssuedAt,
		ExpiresAt:       req.ExpiresAt,
		RefreshWindow:   refreshWindow,
		Status:          status,
		CorrelationID:   normalize(req.CorrelationID),
	}, nil
}

func validateParasutTokenLifecycleRequest(req ParasutTokenLifecycleRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
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
	if req.IssuedAt.IsZero() {
		return fmt.Errorf("%w: issued_at required", ErrInvalidIntegrationRequest)
	}
	if req.ExpiresAt.IsZero() {
		return fmt.Errorf("%w: expires_at required", ErrInvalidIntegrationRequest)
	}
	if !req.ExpiresAt.After(req.IssuedAt) {
		return fmt.Errorf("%w: expires_at must be after issued_at", ErrInvalidIntegrationRequest)
	}
	return nil
}

type ParasutAPIEndpointContract struct {
	Operation          ConnectorOperation
	Method             string
	Path               string
	RequiresOAuth      bool
	Timeout            time.Duration
	RateLimitPerMinute int
	RealCallEnabled    bool
}

func DefaultParasutAPIEndpointContracts() map[ConnectorOperation]ParasutAPIEndpointContract {
	return map[ConnectorOperation]ParasutAPIEndpointContract{
		ConnectorOperationPullInvoice: {
			Operation:          ConnectorOperationPullInvoice,
			Method:             "GET",
			Path:               "/v4/sales_invoices/{id}",
			RequiresOAuth:      true,
			Timeout:            15 * time.Second,
			RateLimitPerMinute: 60,
			RealCallEnabled:    false,
		},
		ConnectorOperationPushInvoice: {
			Operation:          ConnectorOperationPushInvoice,
			Method:             "POST",
			Path:               "/v4/sales_invoices",
			RequiresOAuth:      true,
			Timeout:            20 * time.Second,
			RateLimitPerMinute: 30,
			RealCallEnabled:    false,
		},
		ConnectorOperationSyncCustomer: {
			Operation:          ConnectorOperationSyncCustomer,
			Method:             "POST",
			Path:               "/v4/contacts",
			RequiresOAuth:      true,
			Timeout:            20 * time.Second,
			RateLimitPerMinute: 30,
			RealCallEnabled:    false,
		},
		ConnectorOperationSyncProduct: {
			Operation:          ConnectorOperationSyncProduct,
			Method:             "POST",
			Path:               "/v4/products",
			RequiresOAuth:      true,
			Timeout:            20 * time.Second,
			RateLimitPerMinute: 30,
			RealCallEnabled:    false,
		},
		ConnectorOperationVerifyWebhook: {
			Operation:          ConnectorOperationVerifyWebhook,
			Method:             "POST",
			Path:               "/webhooks/parasut",
			RequiresOAuth:      false,
			Timeout:            5 * time.Second,
			RateLimitPerMinute: 120,
			RealCallEnabled:    false,
		},
	}
}

func ValidateParasutAPIEndpointContract(contract ParasutAPIEndpointContract) error {
	if contract.Operation == "" {
		return fmt.Errorf("%w: endpoint operation required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(contract.Method, "method"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.Path, "path"); err != nil {
		return err
	}
	if !strings.HasPrefix(contract.Path, "/") {
		return fmt.Errorf("%w: endpoint path must start with slash", ErrInvalidIntegrationRequest)
	}
	if contract.Timeout <= 0 {
		return fmt.Errorf("%w: endpoint timeout must be positive", ErrInvalidIntegrationRequest)
	}
	if contract.RateLimitPerMinute <= 0 {
		return fmt.Errorf("%w: endpoint rate limit must be positive", ErrInvalidIntegrationRequest)
	}
	if contract.RealCallEnabled {
		return fmt.Errorf("%w: parasut real api calls are closed in contract readiness phase", ErrInvalidIntegrationRequest)
	}
	return nil
}

func ValidateParasutAPIEndpointContracts(contracts map[ConnectorOperation]ParasutAPIEndpointContract) error {
	required := []ConnectorOperation{
		ConnectorOperationPullInvoice,
		ConnectorOperationPushInvoice,
		ConnectorOperationSyncCustomer,
		ConnectorOperationSyncProduct,
		ConnectorOperationVerifyWebhook,
	}

	for _, op := range required {
		contract, ok := contracts[op]
		if !ok {
			return fmt.Errorf("%w: missing parasut endpoint contract for %s", ErrInvalidIntegrationRequest, op)
		}
		if err := ValidateParasutAPIEndpointContract(contract); err != nil {
			return err
		}
	}

	return nil
}

type ParasutMappedErrorCode string

const (
	ParasutMappedErrorUnauthorized ParasutMappedErrorCode = "UNAUTHORIZED"
	ParasutMappedErrorTimeout      ParasutMappedErrorCode = "TIMEOUT"
	ParasutMappedErrorRateLimited  ParasutMappedErrorCode = "RATE_LIMITED"
	ParasutMappedErrorValidation   ParasutMappedErrorCode = "VALIDATION_ERROR"
	ParasutMappedErrorServer       ParasutMappedErrorCode = "SERVER_ERROR"
	ParasutMappedErrorUnknown      ParasutMappedErrorCode = "UNKNOWN_PROVIDER_ERROR"
)

type ParasutProviderErrorMapping struct {
	HTTPStatus int
	Code       ParasutMappedErrorCode
	Retryable  bool
	MoveToDLQ  bool
	Message    string
}

func MapParasutProviderError(httpStatus int, providerMessage string) ParasutProviderErrorMapping {
	switch httpStatus {
	case 401, 403:
		return ParasutProviderErrorMapping{
			HTTPStatus: httpStatus,
			Code:       ParasutMappedErrorUnauthorized,
			Retryable:  false,
			MoveToDLQ:  false,
			Message:    providerMessage,
		}
	case 408:
		return ParasutProviderErrorMapping{
			HTTPStatus: httpStatus,
			Code:       ParasutMappedErrorTimeout,
			Retryable:  true,
			MoveToDLQ:  false,
			Message:    providerMessage,
		}
	case 422:
		return ParasutProviderErrorMapping{
			HTTPStatus: httpStatus,
			Code:       ParasutMappedErrorValidation,
			Retryable:  false,
			MoveToDLQ:  false,
			Message:    providerMessage,
		}
	case 429:
		return ParasutProviderErrorMapping{
			HTTPStatus: httpStatus,
			Code:       ParasutMappedErrorRateLimited,
			Retryable:  true,
			MoveToDLQ:  false,
			Message:    providerMessage,
		}
	case 500, 502, 503, 504:
		return ParasutProviderErrorMapping{
			HTTPStatus: httpStatus,
			Code:       ParasutMappedErrorServer,
			Retryable:  true,
			MoveToDLQ:  false,
			Message:    providerMessage,
		}
	default:
		return ParasutProviderErrorMapping{
			HTTPStatus: httpStatus,
			Code:       ParasutMappedErrorUnknown,
			Retryable:  false,
			MoveToDLQ:  true,
			Message:    providerMessage,
		}
	}
}

type ParasutLiveSafetyGateInput struct {
	LegalApprovalReady       bool
	FinanceApprovalReady     bool
	KVKKApprovalReady        bool
	SecretManagementReady    bool
	RollbackPlanReady        bool
	ProviderContractReady    bool
	OAuthContractReady       bool
	EndpointContractsReady   bool
	ErrorMappingReady        bool
	RealAPIEnabled           bool
	ProductionApproved       bool
	ProviderLiveModuleOpened bool
}

type ParasutLiveSafetyGateResult struct {
	Ready    bool
	Decision string
	Blockers []string
}

func EvaluateParasutLiveSafetyGate(input ParasutLiveSafetyGateInput) ParasutLiveSafetyGateResult {
	blockers := []string{}

	if !input.LegalApprovalReady {
		blockers = append(blockers, "legal_approval_not_ready")
	}
	if !input.FinanceApprovalReady {
		blockers = append(blockers, "finance_approval_not_ready")
	}
	if !input.KVKKApprovalReady {
		blockers = append(blockers, "kvkk_approval_not_ready")
	}
	if !input.SecretManagementReady {
		blockers = append(blockers, "secret_management_not_ready")
	}
	if !input.RollbackPlanReady {
		blockers = append(blockers, "rollback_plan_not_ready")
	}
	if !input.ProviderContractReady {
		blockers = append(blockers, "provider_contract_not_ready")
	}
	if !input.OAuthContractReady {
		blockers = append(blockers, "oauth_contract_not_ready")
	}
	if !input.EndpointContractsReady {
		blockers = append(blockers, "endpoint_contracts_not_ready")
	}
	if !input.ErrorMappingReady {
		blockers = append(blockers, "error_mapping_not_ready")
	}
	if input.RealAPIEnabled {
		blockers = append(blockers, "real_api_enabled_must_remain_false_in_this_phase")
	}
	if input.ProductionApproved && !input.ProviderLiveModuleOpened {
		blockers = append(blockers, "provider_live_module_required_before_production")
	}

	if len(blockers) > 0 {
		return ParasutLiveSafetyGateResult{
			Ready:    false,
			Decision: "BLOCKED",
			Blockers: blockers,
		}
	}

	return ParasutLiveSafetyGateResult{
		Ready:    true,
		Decision: "PARASUT_LIVE_CONTRACT_READY_BUT_REAL_API_CLOSED",
		Blockers: []string{},
	}
}
