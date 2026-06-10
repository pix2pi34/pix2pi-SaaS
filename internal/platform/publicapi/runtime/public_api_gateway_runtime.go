package publicapiruntime

import (
	"errors"
	"strings"
	"time"
)

const (
	PublicAPIGatewayDecisionAllow = "ALLOW"
	PublicAPIGatewayDecisionDeny  = "DENY"

	PublicAPIGatewayReasonAllowed             = "PUBLIC_API_GATEWAY_ALLOWED"
	PublicAPIGatewayReasonMissingTenant       = "PUBLIC_API_GATEWAY_MISSING_TENANT"
	PublicAPIGatewayReasonMissingApp          = "PUBLIC_API_GATEWAY_MISSING_APP"
	PublicAPIGatewayReasonMissingScope        = "PUBLIC_API_GATEWAY_MISSING_SCOPE"
	PublicAPIGatewayReasonMissingPath         = "PUBLIC_API_GATEWAY_MISSING_PATH"
	PublicAPIGatewayReasonMissingAPIKey       = "PUBLIC_API_GATEWAY_MISSING_API_KEY"
	PublicAPIGatewayReasonAPIKeyNotFound      = "PUBLIC_API_GATEWAY_API_KEY_NOT_FOUND"
	PublicAPIGatewayReasonInactiveAPIKey      = "PUBLIC_API_GATEWAY_INACTIVE_API_KEY"
	PublicAPIGatewayReasonCrossTenant         = "PUBLIC_API_GATEWAY_CROSS_TENANT_DENIED"
	PublicAPIGatewayReasonEnvironmentMismatch = "PUBLIC_API_GATEWAY_ENVIRONMENT_MISMATCH"
	PublicAPIGatewayReasonScopeDenied         = "PUBLIC_API_GATEWAY_SCOPE_DENIED"
	PublicAPIGatewayReasonAppAuthDenied       = "PUBLIC_API_GATEWAY_APP_AUTH_DENIED"
	PublicAPIGatewayReasonSandboxDenied       = "PUBLIC_API_GATEWAY_SANDBOX_DENIED"
	PublicAPIGatewayReasonQuotaDenied         = "PUBLIC_API_GATEWAY_QUOTA_DENIED"
	PublicAPIGatewayReasonDeveloperDocsDenied = "PUBLIC_API_GATEWAY_DEVELOPER_DOCS_DENIED"

	PublicAPIGatewayDocsFormatMarkdown     = "MARKDOWN"
	PublicAPIGatewayDocsFormatOpenAPITrace = "OPENAPI_TRACE"
)

var (
	ErrPublicAPIGatewayMissingTenant       = errors.New("missing public api gateway tenant id")
	ErrPublicAPIGatewayMissingApp          = errors.New("missing public api gateway app id")
	ErrPublicAPIGatewayMissingScope        = errors.New("missing public api gateway scope")
	ErrPublicAPIGatewayMissingPath         = errors.New("missing public api gateway path")
	ErrPublicAPIGatewayMissingAPIKey       = errors.New("missing public api gateway api key")
	ErrPublicAPIGatewayAPIKeyNotFound      = errors.New("public api gateway api key not found")
	ErrPublicAPIGatewayInactiveAPIKey      = errors.New("public api gateway inactive api key")
	ErrPublicAPIGatewayCrossTenant         = errors.New("cross-tenant public api gateway access denied")
	ErrPublicAPIGatewayEnvironmentMismatch = errors.New("public api gateway environment mismatch")
	ErrPublicAPIGatewayScopeDenied         = errors.New("public api gateway scope denied")
	ErrPublicAPIGatewayAppAuthDenied       = errors.New("public api gateway app auth denied")
	ErrPublicAPIGatewaySandboxDenied       = errors.New("public api gateway sandbox denied")
	ErrPublicAPIGatewayQuotaDenied         = errors.New("public api gateway quota denied")
	ErrPublicAPIGatewayDeveloperDocsDenied = errors.New("public api gateway developer docs denied")
)

type PublicAPIGatewayRuntimeConfig struct {
	RequireTenant             bool   `json:"require_tenant"`
	RequireAPIKey             bool   `json:"require_api_key"`
	EnableAppAuthBridge       bool   `json:"enable_app_auth_bridge"`
	EnableQuotaBridge         bool   `json:"enable_quota_bridge"`
	EnableSandboxBridge       bool   `json:"enable_sandbox_bridge"`
	EnableDeveloperDocsBridge bool   `json:"enable_developer_docs_bridge"`
	DeveloperDocsMarkdownPath string `json:"developer_docs_markdown_path"`
	DeveloperDocsOpenAPIPath  string `json:"developer_docs_openapi_path"`
}

func DefaultPublicAPIGatewayRuntimeConfig() PublicAPIGatewayRuntimeConfig {
	return PublicAPIGatewayRuntimeConfig{
		RequireTenant:             true,
		RequireAPIKey:             true,
		EnableAppAuthBridge:       true,
		EnableQuotaBridge:         true,
		EnableSandboxBridge:       true,
		EnableDeveloperDocsBridge: true,
		DeveloperDocsMarkdownPath: "/developer/docs",
		DeveloperDocsOpenAPIPath:  "/developer/openapi-trace",
	}
}

type PublicAPIGatewayRuntime struct {
	config  PublicAPIGatewayRuntimeConfig
	apiKeys *APIKeyIssuanceRuntime
	appAuth *AppAuthRuntime
	quota   *QuotaRateLimitRuntime
	sandbox *SandboxEnvironmentRuntime
	docs    *DeveloperDocsPublishRuntime
}

func NewPublicAPIGatewayRuntime(
	config PublicAPIGatewayRuntimeConfig,
	apiKeys *APIKeyIssuanceRuntime,
	appAuth *AppAuthRuntime,
	quota *QuotaRateLimitRuntime,
	sandbox *SandboxEnvironmentRuntime,
	docs *DeveloperDocsPublishRuntime,
) *PublicAPIGatewayRuntime {
	if strings.TrimSpace(config.DeveloperDocsMarkdownPath) == "" {
		config.DeveloperDocsMarkdownPath = "/developer/docs"
	}
	if strings.TrimSpace(config.DeveloperDocsOpenAPIPath) == "" {
		config.DeveloperDocsOpenAPIPath = "/developer/openapi-trace"
	}

	return &PublicAPIGatewayRuntime{
		config:  config,
		apiKeys: apiKeys,
		appAuth: appAuth,
		quota:   quota,
		sandbox: sandbox,
		docs:    docs,
	}
}

type PublicAPIGatewayRequest struct {
	TenantID      string            `json:"tenant_id"`
	AppID         string            `json:"app_id"`
	Environment   string            `json:"environment"`
	Scope         string            `json:"scope"`
	Method        string            `json:"method"`
	Path          string            `json:"path"`
	Headers       map[string]string `json:"headers,omitempty"`
	CorrelationID string            `json:"correlation_id,omitempty"`
}

type PublicAPIGatewayResponse struct {
	TenantID      string `json:"tenant_id"`
	AppID         string `json:"app_id"`
	KeyID         string `json:"key_id"`
	Environment   string `json:"environment"`
	Scope         string `json:"scope"`
	Method        string `json:"method"`
	Path          string `json:"path"`
	DataNamespace string `json:"data_namespace,omitempty"`
	DocsFormat    string `json:"docs_format,omitempty"`
	DocsContent   string `json:"docs_content,omitempty"`
	Allowed       bool   `json:"allowed"`
	Reason        string `json:"reason"`
	CheckedAt     string `json:"checked_at"`
}

type PublicAPIGatewayDecision struct {
	Decision      string `json:"decision"`
	Allowed       bool   `json:"allowed"`
	TenantID      string `json:"tenant_id"`
	AppID         string `json:"app_id,omitempty"`
	KeyID         string `json:"key_id,omitempty"`
	Environment   string `json:"environment,omitempty"`
	Scope         string `json:"scope,omitempty"`
	Path          string `json:"path,omitempty"`
	DataNamespace string `json:"data_namespace,omitempty"`
	Reason        string `json:"reason"`
	CheckedAt     string `json:"checked_at"`
}

func (r *PublicAPIGatewayRuntime) HandleRequest(req PublicAPIGatewayRequest) (PublicAPIGatewayResponse, PublicAPIGatewayDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.AppID = strings.TrimSpace(req.AppID)
	req.Environment = normalizeEnvironment(req.Environment)
	req.Scope = strings.TrimSpace(req.Scope)
	req.Method = strings.ToUpper(strings.TrimSpace(req.Method))
	req.Path = strings.TrimSpace(req.Path)

	decision := PublicAPIGatewayDecision{
		Decision:    PublicAPIGatewayDecisionDeny,
		Allowed:     false,
		TenantID:    req.TenantID,
		AppID:       req.AppID,
		Environment: req.Environment,
		Scope:       req.Scope,
		Path:        req.Path,
		CheckedAt:   now,
	}

	if r.config.RequireTenant && req.TenantID == "" {
		decision.Reason = PublicAPIGatewayReasonMissingTenant
		return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayMissingTenant
	}
	if req.AppID == "" {
		decision.Reason = PublicAPIGatewayReasonMissingApp
		return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayMissingApp
	}
	if req.Scope == "" {
		decision.Reason = PublicAPIGatewayReasonMissingScope
		return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayMissingScope
	}
	if req.Path == "" {
		decision.Reason = PublicAPIGatewayReasonMissingPath
		return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayMissingPath
	}

	rawSecret, err := ExtractPublicAPIKeySecret(req.Headers)
	if err != nil {
		decision.Reason = PublicAPIGatewayReasonMissingAPIKey
		return PublicAPIGatewayResponse{}, decision, err
	}

	apiKey, err := r.findAPIKeyByRawSecret(req.TenantID, rawSecret)
	if err != nil {
		decision.Reason = reasonForGatewayAPIKeyError(err)
		return PublicAPIGatewayResponse{}, decision, err
	}

	decision.KeyID = apiKey.KeyID

	if apiKey.Status != APIKeyStatusActive {
		decision.Reason = PublicAPIGatewayReasonInactiveAPIKey
		return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayInactiveAPIKey
	}
	if apiKey.TenantID != req.TenantID {
		decision.Reason = PublicAPIGatewayReasonCrossTenant
		return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayCrossTenant
	}
	if apiKey.Environment != req.Environment {
		decision.Reason = PublicAPIGatewayReasonEnvironmentMismatch
		return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayEnvironmentMismatch
	}
	if !scopeInList(req.Scope, apiKey.Scopes) {
		decision.Reason = PublicAPIGatewayReasonScopeDenied
		return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayScopeDenied
	}

	appDecision := AppAuthDecision{
		Decision:    AppAuthDecisionAllow,
		Allowed:     true,
		TenantID:    req.TenantID,
		AppID:       req.AppID,
		KeyID:       apiKey.KeyID,
		Environment: req.Environment,
		Scopes:      []string{req.Scope},
		Reason:      AppAuthReasonAllowed,
		CheckedAt:   now,
	}

	if r.config.EnableAppAuthBridge {
		if r.appAuth == nil {
			decision.Reason = PublicAPIGatewayReasonAppAuthDenied
			return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayAppAuthDenied
		}

		appDecision, err = r.appAuth.ValidateAppAuth(AppAuthValidationRequest{
			TenantID:        req.TenantID,
			AppID:           req.AppID,
			KeyID:           apiKey.KeyID,
			RequestedScopes: []string{req.Scope},
			Environment:     req.Environment,
			CorrelationID:   req.CorrelationID,
		})
		if err != nil || !appDecision.Allowed {
			decision.Reason = PublicAPIGatewayReasonAppAuthDenied
			return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayAppAuthDenied
		}
	}

	var sandboxContext SandboxRequestContext
	if r.config.EnableSandboxBridge {
		if r.sandbox == nil {
			decision.Reason = PublicAPIGatewayReasonSandboxDenied
			return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewaySandboxDenied
		}

		sandboxContext, _, err = r.sandbox.BuildContext(SandboxRequestContextRequest{
			TenantID:      req.TenantID,
			AppID:         req.AppID,
			KeyID:         apiKey.KeyID,
			Environment:   req.Environment,
			Scope:         req.Scope,
			Method:        req.Method,
			Path:          req.Path,
			CorrelationID: req.CorrelationID,
		})
		if err != nil {
			decision.Reason = PublicAPIGatewayReasonSandboxDenied
			return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewaySandboxDenied
		}

		sandboxDecision, err := r.sandbox.ValidateAppAuthBoundary(sandboxContext, appDecision)
		if err != nil || !sandboxDecision.Allowed {
			decision.Reason = PublicAPIGatewayReasonSandboxDenied
			return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewaySandboxDenied
		}
	}

	if r.config.EnableQuotaBridge {
		if r.quota == nil {
			decision.Reason = PublicAPIGatewayReasonQuotaDenied
			return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayQuotaDenied
		}

		if r.config.EnableSandboxBridge {
			_, quotaDecision, err := r.sandbox.AllowSandboxQuota(sandboxContext, r.quota)
			if err != nil || !quotaDecision.Allowed {
				decision.Reason = PublicAPIGatewayReasonQuotaDenied
				return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayQuotaDenied
			}
		} else {
			_, quotaDecision, err := r.quota.AllowRequest(QuotaUsageRequest{
				TenantID:      req.TenantID,
				AppID:         req.AppID,
				KeyID:         apiKey.KeyID,
				Environment:   req.Environment,
				Scope:         req.Scope,
				Units:         1,
				CorrelationID: req.CorrelationID,
			})
			if err != nil || !quotaDecision.Allowed {
				decision.Reason = PublicAPIGatewayReasonQuotaDenied
				return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayQuotaDenied
			}
		}
	}

	decision.Decision = PublicAPIGatewayDecisionAllow
	decision.Allowed = true
	decision.DataNamespace = sandboxContext.DataNamespace
	decision.Reason = PublicAPIGatewayReasonAllowed

	response := PublicAPIGatewayResponse{
		TenantID:      req.TenantID,
		AppID:         req.AppID,
		KeyID:         apiKey.KeyID,
		Environment:   req.Environment,
		Scope:         req.Scope,
		Method:        req.Method,
		Path:          req.Path,
		DataNamespace: sandboxContext.DataNamespace,
		Allowed:       true,
		Reason:        PublicAPIGatewayReasonAllowed,
		CheckedAt:     now,
	}

	return response, decision, nil
}

func (r *PublicAPIGatewayRuntime) HandleDeveloperDocsRequest(path string) (PublicAPIGatewayResponse, PublicAPIGatewayDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)
	path = strings.TrimSpace(path)

	decision := PublicAPIGatewayDecision{
		Decision:  PublicAPIGatewayDecisionDeny,
		Allowed:   false,
		Path:      path,
		CheckedAt: now,
	}

	if !r.config.EnableDeveloperDocsBridge || r.docs == nil {
		decision.Reason = PublicAPIGatewayReasonDeveloperDocsDenied
		return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayDeveloperDocsDenied
	}

	if path == r.config.DeveloperDocsMarkdownPath {
		result, docsDecision, err := r.docs.PublishMarkdown()
		if err != nil || !docsDecision.Allowed {
			decision.Reason = PublicAPIGatewayReasonDeveloperDocsDenied
			return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayDeveloperDocsDenied
		}

		decision.Decision = PublicAPIGatewayDecisionAllow
		decision.Allowed = true
		decision.Reason = PublicAPIGatewayReasonAllowed

		return PublicAPIGatewayResponse{
			Path:        path,
			DocsFormat:  PublicAPIGatewayDocsFormatMarkdown,
			DocsContent: result.Content,
			Allowed:     true,
			Reason:      PublicAPIGatewayReasonAllowed,
			CheckedAt:   now,
		}, decision, nil
	}

	if path == r.config.DeveloperDocsOpenAPIPath {
		result, docsDecision, err := r.docs.PublishOpenAPITrace()
		if err != nil || !docsDecision.Allowed {
			decision.Reason = PublicAPIGatewayReasonDeveloperDocsDenied
			return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayDeveloperDocsDenied
		}

		decision.Decision = PublicAPIGatewayDecisionAllow
		decision.Allowed = true
		decision.Reason = PublicAPIGatewayReasonAllowed

		return PublicAPIGatewayResponse{
			Path:        path,
			DocsFormat:  PublicAPIGatewayDocsFormatOpenAPITrace,
			DocsContent: result.Content,
			Allowed:     true,
			Reason:      PublicAPIGatewayReasonAllowed,
			CheckedAt:   now,
		}, decision, nil
	}

	decision.Reason = PublicAPIGatewayReasonMissingPath
	return PublicAPIGatewayResponse{}, decision, ErrPublicAPIGatewayMissingPath
}

func ExtractPublicAPIKeySecret(headers map[string]string) (string, error) {
	if len(headers) == 0 {
		return "", ErrPublicAPIGatewayMissingAPIKey
	}

	if value, ok := lookupHeader(headers, "Authorization"); ok {
		value = strings.TrimSpace(value)
		if strings.HasPrefix(strings.ToLower(value), "bearer ") {
			secret := strings.TrimSpace(value[len("Bearer "):])
			if secret != "" {
				return secret, nil
			}
		}
	}

	if value, ok := lookupHeader(headers, "X-API-Key"); ok {
		secret := strings.TrimSpace(value)
		if secret != "" {
			return secret, nil
		}
	}

	return "", ErrPublicAPIGatewayMissingAPIKey
}

func (r *PublicAPIGatewayRuntime) findAPIKeyByRawSecret(tenantID string, rawSecret string) (APIKeyRecord, error) {
	if r.apiKeys == nil {
		return APIKeyRecord{}, ErrPublicAPIGatewayAPIKeyNotFound
	}

	tenantID = strings.TrimSpace(tenantID)
	rawSecret = strings.TrimSpace(rawSecret)
	if rawSecret == "" {
		return APIKeyRecord{}, ErrPublicAPIGatewayMissingAPIKey
	}

	hash := HashAPIKeySecret(rawSecret)

	r.apiKeys.mu.RLock()
	defer r.apiKeys.mu.RUnlock()

	for _, record := range r.apiKeys.keys {
		if record.SecretHash == hash {
			if record.TenantID != tenantID {
				return APIKeyRecord{}, ErrPublicAPIGatewayCrossTenant
			}
			if record.Status != APIKeyStatusActive {
				return APIKeyRecord{}, ErrPublicAPIGatewayInactiveAPIKey
			}
			return record, nil
		}
	}

	return APIKeyRecord{}, ErrPublicAPIGatewayAPIKeyNotFound
}

func lookupHeader(headers map[string]string, name string) (string, bool) {
	for key, value := range headers {
		if strings.EqualFold(strings.TrimSpace(key), strings.TrimSpace(name)) {
			return value, true
		}
	}
	return "", false
}

func reasonForGatewayAPIKeyError(err error) string {
	switch err {
	case ErrPublicAPIGatewayMissingAPIKey:
		return PublicAPIGatewayReasonMissingAPIKey
	case ErrPublicAPIGatewayAPIKeyNotFound:
		return PublicAPIGatewayReasonAPIKeyNotFound
	case ErrPublicAPIGatewayInactiveAPIKey:
		return PublicAPIGatewayReasonInactiveAPIKey
	case ErrPublicAPIGatewayCrossTenant:
		return PublicAPIGatewayReasonCrossTenant
	default:
		return PublicAPIGatewayReasonAPIKeyNotFound
	}
}
