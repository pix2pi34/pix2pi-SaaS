package publicapiruntime

import (
	"errors"
	"strings"
	"time"
)

const (
	SandboxDecisionAllow = "ALLOW"
	SandboxDecisionDeny  = "DENY"

	SandboxReasonAllowed                    = "SANDBOX_ALLOWED"
	SandboxReasonMissingTenant              = "SANDBOX_MISSING_TENANT"
	SandboxReasonMissingApp                 = "SANDBOX_MISSING_APP"
	SandboxReasonMissingAPIKey              = "SANDBOX_MISSING_API_KEY"
	SandboxReasonMissingScope               = "SANDBOX_MISSING_SCOPE"
	SandboxReasonMissingPath                = "SANDBOX_MISSING_PATH"
	SandboxReasonInvalidEnvironment         = "SANDBOX_INVALID_ENVIRONMENT"
	SandboxReasonProductionDenied           = "SANDBOX_PRODUCTION_DENIED"
	SandboxReasonAppAuthDenied              = "SANDBOX_APP_AUTH_DENIED"
	SandboxReasonAppAuthEnvironmentMismatch = "SANDBOX_APP_AUTH_ENVIRONMENT_MISMATCH"
	SandboxReasonQuotaDenied                = "SANDBOX_QUOTA_DENIED"
	SandboxReasonCrossTenant                = "SANDBOX_CROSS_TENANT_DENIED"

	SandboxDataNamespacePrefix = "sandbox"
)

var (
	ErrSandboxMissingTenant              = errors.New("missing sandbox tenant id")
	ErrSandboxMissingApp                 = errors.New("missing sandbox app id")
	ErrSandboxMissingAPIKey              = errors.New("missing sandbox api key id")
	ErrSandboxMissingScope               = errors.New("missing sandbox scope")
	ErrSandboxMissingPath                = errors.New("missing sandbox request path")
	ErrSandboxInvalidEnvironment         = errors.New("invalid sandbox environment")
	ErrSandboxProductionDenied           = errors.New("production environment denied by sandbox runtime")
	ErrSandboxAppAuthDenied              = errors.New("sandbox app auth denied")
	ErrSandboxAppAuthEnvironmentMismatch = errors.New("sandbox app auth environment mismatch")
	ErrSandboxQuotaDenied                = errors.New("sandbox quota denied")
	ErrSandboxCrossTenant                = errors.New("cross-tenant sandbox access denied")
)

type SandboxEnvironmentRuntimeConfig struct {
	RequireTenant             bool `json:"require_tenant"`
	DenyProductionByDefault   bool `json:"deny_production_by_default"`
	RequireSandboxEnvironment bool `json:"require_sandbox_environment"`
	EnableQuotaBridge         bool `json:"enable_quota_bridge"`
}

func DefaultSandboxEnvironmentRuntimeConfig() SandboxEnvironmentRuntimeConfig {
	return SandboxEnvironmentRuntimeConfig{
		RequireTenant:             true,
		DenyProductionByDefault:   true,
		RequireSandboxEnvironment: true,
		EnableQuotaBridge:         true,
	}
}

type SandboxRequestContextRequest struct {
	TenantID      string `json:"tenant_id"`
	AppID         string `json:"app_id"`
	KeyID         string `json:"key_id"`
	Environment   string `json:"environment"`
	Scope         string `json:"scope"`
	Method        string `json:"method,omitempty"`
	Path          string `json:"path"`
	CorrelationID string `json:"correlation_id,omitempty"`
}

type SandboxRequestContext struct {
	TenantID      string `json:"tenant_id"`
	AppID         string `json:"app_id"`
	KeyID         string `json:"key_id"`
	Environment   string `json:"environment"`
	Scope         string `json:"scope"`
	Method        string `json:"method,omitempty"`
	Path          string `json:"path"`
	DataNamespace string `json:"data_namespace"`
	IsSandbox     bool   `json:"is_sandbox"`
	CorrelationID string `json:"correlation_id,omitempty"`
	CreatedAt     string `json:"created_at"`
}

type SandboxBoundaryDecision struct {
	Decision      string `json:"decision"`
	Allowed       bool   `json:"allowed"`
	TenantID      string `json:"tenant_id"`
	AppID         string `json:"app_id,omitempty"`
	KeyID         string `json:"key_id,omitempty"`
	Environment   string `json:"environment,omitempty"`
	Scope         string `json:"scope,omitempty"`
	DataNamespace string `json:"data_namespace,omitempty"`
	Reason        string `json:"reason"`
	CheckedAt     string `json:"checked_at"`
}

type SandboxEnvironmentRuntime struct {
	config SandboxEnvironmentRuntimeConfig
}

func NewSandboxEnvironmentRuntime(config SandboxEnvironmentRuntimeConfig) *SandboxEnvironmentRuntime {
	return &SandboxEnvironmentRuntime{config: config}
}

func (r *SandboxEnvironmentRuntime) BuildContext(req SandboxRequestContextRequest) (SandboxRequestContext, SandboxBoundaryDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	appID := strings.TrimSpace(req.AppID)
	keyID := strings.TrimSpace(req.KeyID)
	environment := normalizeEnvironment(req.Environment)
	scope := strings.TrimSpace(req.Scope)
	path := strings.TrimSpace(req.Path)

	decision := SandboxBoundaryDecision{
		Decision:    SandboxDecisionDeny,
		Allowed:     false,
		TenantID:    tenantID,
		AppID:       appID,
		KeyID:       keyID,
		Environment: environment,
		Scope:       scope,
		CheckedAt:   now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = SandboxReasonMissingTenant
		return SandboxRequestContext{}, decision, ErrSandboxMissingTenant
	}
	if appID == "" {
		decision.Reason = SandboxReasonMissingApp
		return SandboxRequestContext{}, decision, ErrSandboxMissingApp
	}
	if keyID == "" {
		decision.Reason = SandboxReasonMissingAPIKey
		return SandboxRequestContext{}, decision, ErrSandboxMissingAPIKey
	}
	if scope == "" {
		decision.Reason = SandboxReasonMissingScope
		return SandboxRequestContext{}, decision, ErrSandboxMissingScope
	}
	if path == "" {
		decision.Reason = SandboxReasonMissingPath
		return SandboxRequestContext{}, decision, ErrSandboxMissingPath
	}
	if environment != APIKeyEnvironmentSandbox && environment != APIKeyEnvironmentProduction {
		decision.Reason = SandboxReasonInvalidEnvironment
		return SandboxRequestContext{}, decision, ErrSandboxInvalidEnvironment
	}
	if r.config.DenyProductionByDefault && environment == APIKeyEnvironmentProduction {
		decision.Reason = SandboxReasonProductionDenied
		return SandboxRequestContext{}, decision, ErrSandboxProductionDenied
	}
	if r.config.RequireSandboxEnvironment && environment != APIKeyEnvironmentSandbox {
		decision.Reason = SandboxReasonInvalidEnvironment
		return SandboxRequestContext{}, decision, ErrSandboxInvalidEnvironment
	}

	namespace := BuildSandboxDataNamespace(tenantID, appID)

	ctx := SandboxRequestContext{
		TenantID:      tenantID,
		AppID:         appID,
		KeyID:         keyID,
		Environment:   environment,
		Scope:         scope,
		Method:        strings.ToUpper(strings.TrimSpace(req.Method)),
		Path:          path,
		DataNamespace: namespace,
		IsSandbox:     environment == APIKeyEnvironmentSandbox,
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		CreatedAt:     now,
	}

	decision.Decision = SandboxDecisionAllow
	decision.Allowed = true
	decision.DataNamespace = namespace
	decision.Reason = SandboxReasonAllowed

	return ctx, decision, nil
}

func (r *SandboxEnvironmentRuntime) ValidateAppAuthBoundary(ctx SandboxRequestContext, appDecision AppAuthDecision) (SandboxBoundaryDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	decision := SandboxBoundaryDecision{
		Decision:      SandboxDecisionDeny,
		Allowed:       false,
		TenantID:      ctx.TenantID,
		AppID:         ctx.AppID,
		KeyID:         ctx.KeyID,
		Environment:   ctx.Environment,
		Scope:         ctx.Scope,
		DataNamespace: ctx.DataNamespace,
		CheckedAt:     now,
	}

	if ctx.TenantID == "" {
		decision.Reason = SandboxReasonMissingTenant
		return decision, ErrSandboxMissingTenant
	}

	if appDecision.TenantID != ctx.TenantID || appDecision.AppID != ctx.AppID || appDecision.KeyID != ctx.KeyID {
		decision.Reason = SandboxReasonCrossTenant
		return decision, ErrSandboxCrossTenant
	}

	if !appDecision.Allowed {
		decision.Reason = SandboxReasonAppAuthDenied
		return decision, ErrSandboxAppAuthDenied
	}

	if appDecision.Environment != APIKeyEnvironmentSandbox || ctx.Environment != APIKeyEnvironmentSandbox {
		decision.Reason = SandboxReasonAppAuthEnvironmentMismatch
		return decision, ErrSandboxAppAuthEnvironmentMismatch
	}

	if !scopeInList(ctx.Scope, appDecision.Scopes) {
		decision.Reason = SandboxReasonAppAuthDenied
		return decision, ErrSandboxAppAuthDenied
	}

	decision.Decision = SandboxDecisionAllow
	decision.Allowed = true
	decision.Reason = SandboxReasonAllowed

	return decision, nil
}

func (r *SandboxEnvironmentRuntime) AllowSandboxQuota(ctx SandboxRequestContext, quotaRuntime *QuotaRateLimitRuntime) (QuotaUsageMeter, SandboxBoundaryDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	decision := SandboxBoundaryDecision{
		Decision:      SandboxDecisionDeny,
		Allowed:       false,
		TenantID:      ctx.TenantID,
		AppID:         ctx.AppID,
		KeyID:         ctx.KeyID,
		Environment:   ctx.Environment,
		Scope:         ctx.Scope,
		DataNamespace: ctx.DataNamespace,
		CheckedAt:     now,
	}

	if !r.config.EnableQuotaBridge {
		decision.Decision = SandboxDecisionAllow
		decision.Allowed = true
		decision.Reason = SandboxReasonAllowed
		return QuotaUsageMeter{}, decision, nil
	}

	if quotaRuntime == nil {
		decision.Reason = SandboxReasonQuotaDenied
		return QuotaUsageMeter{}, decision, ErrSandboxQuotaDenied
	}

	if ctx.TenantID == "" {
		decision.Reason = SandboxReasonMissingTenant
		return QuotaUsageMeter{}, decision, ErrSandboxMissingTenant
	}

	if ctx.Environment != APIKeyEnvironmentSandbox {
		decision.Reason = SandboxReasonProductionDenied
		return QuotaUsageMeter{}, decision, ErrSandboxProductionDenied
	}

	meter, quotaDecision, err := quotaRuntime.AllowRequest(QuotaUsageRequest{
		TenantID:    ctx.TenantID,
		AppID:       ctx.AppID,
		KeyID:       ctx.KeyID,
		Environment: ctx.Environment,
		Scope:       ctx.Scope,
		Units:       1,
	})

	if err != nil || !quotaDecision.Allowed {
		decision.Reason = SandboxReasonQuotaDenied
		return meter, decision, ErrSandboxQuotaDenied
	}

	decision.Decision = SandboxDecisionAllow
	decision.Allowed = true
	decision.Reason = SandboxReasonAllowed

	return meter, decision, nil
}

func BuildSandboxDataNamespace(tenantID string, appID string) string {
	return SandboxDataNamespacePrefix + ":" + strings.TrimSpace(tenantID) + ":" + strings.TrimSpace(appID)
}

func SandboxContextMatchesTenant(ctx SandboxRequestContext, tenantID string) bool {
	return strings.TrimSpace(ctx.TenantID) == strings.TrimSpace(tenantID)
}
