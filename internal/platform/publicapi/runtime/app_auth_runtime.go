package publicapiruntime

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	AppStatusActive    = "ACTIVE"
	AppStatusSuspended = "SUSPENDED"
	AppStatusRevoked   = "REVOKED"

	AppAuthRelationStatusActive  = "ACTIVE"
	AppAuthRelationStatusRevoked = "REVOKED"

	AppAuthDecisionAllow = "ALLOW"
	AppAuthDecisionDeny  = "DENY"

	AppAuthReasonAllowed             = "APP_AUTH_ALLOWED"
	AppAuthReasonMissingTenant       = "APP_AUTH_MISSING_TENANT"
	AppAuthReasonMissingApp          = "APP_AUTH_MISSING_APP"
	AppAuthReasonMissingAPIKey       = "APP_AUTH_MISSING_API_KEY"
	AppAuthReasonMissingName         = "APP_AUTH_MISSING_NAME"
	AppAuthReasonInvalidEnvironment  = "APP_AUTH_INVALID_ENVIRONMENT"
	AppAuthReasonInvalidScope        = "APP_AUTH_INVALID_SCOPE"
	AppAuthReasonMissingScope        = "APP_AUTH_MISSING_SCOPE"
	AppAuthReasonCrossTenant         = "APP_AUTH_CROSS_TENANT_DENIED"
	AppAuthReasonEnvironmentMismatch = "APP_AUTH_ENVIRONMENT_MISMATCH"
	AppAuthReasonInactiveApp         = "APP_AUTH_INACTIVE_APP"
	AppAuthReasonInactiveAPIKey      = "APP_AUTH_INACTIVE_API_KEY"
	AppAuthReasonMissingRelation     = "APP_AUTH_MISSING_RELATION"
	AppAuthReasonInactiveRelation    = "APP_AUTH_INACTIVE_RELATION"
	AppAuthReasonScopeNotAllowed     = "APP_AUTH_SCOPE_NOT_ALLOWED"
)

var (
	ErrAppAuthMissingTenant       = errors.New("missing app auth tenant id")
	ErrAppAuthMissingApp          = errors.New("missing app id")
	ErrAppAuthMissingAPIKey       = errors.New("missing api key id")
	ErrAppAuthMissingName         = errors.New("missing app name")
	ErrAppAuthInvalidEnvironment  = errors.New("invalid app environment")
	ErrAppAuthInvalidScope        = errors.New("invalid app scope")
	ErrAppAuthMissingScope        = errors.New("missing app scope")
	ErrAppAuthCrossTenant         = errors.New("cross-tenant app auth access denied")
	ErrAppAuthEnvironmentMismatch = errors.New("app and api key environment mismatch")
	ErrAppAuthInactiveApp         = errors.New("app is inactive")
	ErrAppAuthInactiveAPIKey      = errors.New("api key is inactive")
	ErrAppAuthMissingRelation     = errors.New("missing app auth relation")
	ErrAppAuthInactiveRelation    = errors.New("app auth relation is inactive")
	ErrAppAuthScopeNotAllowed     = errors.New("requested scope is not allowed")
)

type AppAuthRuntimeConfig struct {
	RequireTenant       bool     `json:"require_tenant"`
	AllowedScopes       []string `json:"allowed_scopes"`
	AllowedEnvironments []string `json:"allowed_environments"`
}

func DefaultAppAuthRuntimeConfig() AppAuthRuntimeConfig {
	defaultAPIKeyConfig := DefaultAPIKeyIssuanceRuntimeConfig()

	return AppAuthRuntimeConfig{
		RequireTenant:       true,
		AllowedScopes:       defaultAPIKeyConfig.AllowedScopes,
		AllowedEnvironments: defaultAPIKeyConfig.AllowedEnvironments,
	}
}

type AppRegistrationRequest struct {
	TenantID      string   `json:"tenant_id"`
	Name          string   `json:"name"`
	Environment   string   `json:"environment"`
	AllowedScopes []string `json:"allowed_scopes"`
	CreatedBy     string   `json:"created_by,omitempty"`
	CorrelationID string   `json:"correlation_id,omitempty"`
}

type AppRegistration struct {
	TenantID      string   `json:"tenant_id"`
	AppID         string   `json:"app_id"`
	Name          string   `json:"name"`
	Environment   string   `json:"environment"`
	AllowedScopes []string `json:"allowed_scopes"`
	Status        string   `json:"status"`
	CreatedBy     string   `json:"created_by,omitempty"`
	CorrelationID string   `json:"correlation_id,omitempty"`
	CreatedAt     string   `json:"created_at"`
	UpdatedAt     string   `json:"updated_at"`
	SuspendedAt   string   `json:"suspended_at,omitempty"`
	RevokedAt     string   `json:"revoked_at,omitempty"`
}

type AppAPIKeyRelationRequest struct {
	TenantID      string       `json:"tenant_id"`
	AppID         string       `json:"app_id"`
	APIKeyRecord  APIKeyRecord `json:"api_key_record"`
	CreatedBy     string       `json:"created_by,omitempty"`
	CorrelationID string       `json:"correlation_id,omitempty"`
}

type AppAPIKeyRelation struct {
	TenantID        string   `json:"tenant_id"`
	RelationID      string   `json:"relation_id"`
	AppID           string   `json:"app_id"`
	KeyID           string   `json:"key_id"`
	Environment     string   `json:"environment"`
	EffectiveScopes []string `json:"effective_scopes"`
	Status          string   `json:"status"`
	CreatedBy       string   `json:"created_by,omitempty"`
	CorrelationID   string   `json:"correlation_id,omitempty"`
	CreatedAt       string   `json:"created_at"`
	UpdatedAt       string   `json:"updated_at"`
	RevokedAt       string   `json:"revoked_at,omitempty"`
}

type AppAuthValidationRequest struct {
	TenantID        string   `json:"tenant_id"`
	AppID           string   `json:"app_id"`
	KeyID           string   `json:"key_id"`
	RequestedScopes []string `json:"requested_scopes"`
	Environment     string   `json:"environment,omitempty"`
	CorrelationID   string   `json:"correlation_id,omitempty"`
}

type AppAuthDecision struct {
	Decision    string   `json:"decision"`
	Allowed     bool     `json:"allowed"`
	TenantID    string   `json:"tenant_id"`
	AppID       string   `json:"app_id,omitempty"`
	KeyID       string   `json:"key_id,omitempty"`
	RelationID  string   `json:"relation_id,omitempty"`
	Environment string   `json:"environment,omitempty"`
	Scopes      []string `json:"scopes,omitempty"`
	Reason      string   `json:"reason"`
	CheckedAt   string   `json:"checked_at"`
}

type AppAuthRuntime struct {
	config    AppAuthRuntimeConfig
	mu        sync.RWMutex
	apps      map[string]AppRegistration
	relations map[string]AppAPIKeyRelation
}

func NewAppAuthRuntime(config AppAuthRuntimeConfig) *AppAuthRuntime {
	if len(config.AllowedScopes) == 0 {
		config.AllowedScopes = DefaultAppAuthRuntimeConfig().AllowedScopes
	}
	if len(config.AllowedEnvironments) == 0 {
		config.AllowedEnvironments = DefaultAppAuthRuntimeConfig().AllowedEnvironments
	}

	return &AppAuthRuntime{
		config:    config,
		apps:      make(map[string]AppRegistration),
		relations: make(map[string]AppAPIKeyRelation),
	}
}

func (r *AppAuthRuntime) RegisterApp(req AppRegistrationRequest) (AppRegistration, AppAuthDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	environment := normalizeEnvironment(req.Environment)

	decision := AppAuthDecision{
		Decision:    AppAuthDecisionDeny,
		Allowed:     false,
		TenantID:    tenantID,
		Environment: environment,
		CheckedAt:   now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = AppAuthReasonMissingTenant
		return AppRegistration{}, decision, ErrAppAuthMissingTenant
	}

	if strings.TrimSpace(req.Name) == "" {
		decision.Reason = AppAuthReasonMissingName
		return AppRegistration{}, decision, ErrAppAuthMissingName
	}

	if !r.environmentAllowed(environment) {
		decision.Reason = AppAuthReasonInvalidEnvironment
		return AppRegistration{}, decision, ErrAppAuthInvalidEnvironment
	}

	scopes, err := r.normalizeAndValidateScopes(req.AllowedScopes)
	if err != nil {
		if errors.Is(err, ErrAppAuthMissingScope) {
			decision.Reason = AppAuthReasonMissingScope
		} else {
			decision.Reason = AppAuthReasonInvalidScope
		}
		return AppRegistration{}, decision, err
	}

	appID := NewAppID()
	app := AppRegistration{
		TenantID:      tenantID,
		AppID:         appID,
		Name:          strings.TrimSpace(req.Name),
		Environment:   environment,
		AllowedScopes: scopes,
		Status:        AppStatusActive,
		CreatedBy:     strings.TrimSpace(req.CreatedBy),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		CreatedAt:     now,
		UpdatedAt:     now,
	}

	r.mu.Lock()
	r.apps[appID] = app
	r.mu.Unlock()

	decision.Decision = AppAuthDecisionAllow
	decision.Allowed = true
	decision.AppID = appID
	decision.Scopes = scopes
	decision.Reason = AppAuthReasonAllowed

	return app, decision, nil
}

func (r *AppAuthRuntime) LinkAPIKey(req AppAPIKeyRelationRequest) (AppAPIKeyRelation, AppAuthDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	appID := strings.TrimSpace(req.AppID)
	keyID := strings.TrimSpace(req.APIKeyRecord.KeyID)

	decision := AppAuthDecision{
		Decision:  AppAuthDecisionDeny,
		Allowed:   false,
		TenantID:  tenantID,
		AppID:     appID,
		KeyID:     keyID,
		CheckedAt: now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = AppAuthReasonMissingTenant
		return AppAPIKeyRelation{}, decision, ErrAppAuthMissingTenant
	}

	if appID == "" {
		decision.Reason = AppAuthReasonMissingApp
		return AppAPIKeyRelation{}, decision, ErrAppAuthMissingApp
	}

	if keyID == "" {
		decision.Reason = AppAuthReasonMissingAPIKey
		return AppAPIKeyRelation{}, decision, ErrAppAuthMissingAPIKey
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	app, ok := r.apps[appID]
	if !ok {
		decision.Reason = AppAuthReasonMissingApp
		return AppAPIKeyRelation{}, decision, ErrAppAuthMissingApp
	}

	if app.TenantID != tenantID || req.APIKeyRecord.TenantID != tenantID {
		decision.Reason = AppAuthReasonCrossTenant
		return AppAPIKeyRelation{}, decision, ErrAppAuthCrossTenant
	}

	if app.Status != AppStatusActive {
		decision.Reason = AppAuthReasonInactiveApp
		return AppAPIKeyRelation{}, decision, ErrAppAuthInactiveApp
	}

	if req.APIKeyRecord.Status != APIKeyStatusActive {
		decision.Reason = AppAuthReasonInactiveAPIKey
		return AppAPIKeyRelation{}, decision, ErrAppAuthInactiveAPIKey
	}

	if app.Environment != req.APIKeyRecord.Environment {
		decision.Reason = AppAuthReasonEnvironmentMismatch
		return AppAPIKeyRelation{}, decision, ErrAppAuthEnvironmentMismatch
	}

	effectiveScopes, err := deriveEffectiveAppScopes(app.AllowedScopes, req.APIKeyRecord.Scopes)
	if err != nil {
		decision.Reason = AppAuthReasonScopeNotAllowed
		return AppAPIKeyRelation{}, decision, err
	}

	relation := AppAPIKeyRelation{
		TenantID:        tenantID,
		RelationID:      NewAppAPIKeyRelationID(),
		AppID:           appID,
		KeyID:           keyID,
		Environment:     app.Environment,
		EffectiveScopes: effectiveScopes,
		Status:          AppAuthRelationStatusActive,
		CreatedBy:       strings.TrimSpace(req.CreatedBy),
		CorrelationID:   strings.TrimSpace(req.CorrelationID),
		CreatedAt:       now,
		UpdatedAt:       now,
	}

	r.relations[relation.RelationID] = relation

	decision.Decision = AppAuthDecisionAllow
	decision.Allowed = true
	decision.RelationID = relation.RelationID
	decision.Environment = relation.Environment
	decision.Scopes = effectiveScopes
	decision.Reason = AppAuthReasonAllowed

	return relation, decision, nil
}

func (r *AppAuthRuntime) ValidateAppAuth(req AppAuthValidationRequest) (AppAuthDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	appID := strings.TrimSpace(req.AppID)
	keyID := strings.TrimSpace(req.KeyID)
	environment := normalizeEnvironment(req.Environment)

	decision := AppAuthDecision{
		Decision:    AppAuthDecisionDeny,
		Allowed:     false,
		TenantID:    tenantID,
		AppID:       appID,
		KeyID:       keyID,
		Environment: environment,
		CheckedAt:   now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = AppAuthReasonMissingTenant
		return decision, ErrAppAuthMissingTenant
	}

	if appID == "" {
		decision.Reason = AppAuthReasonMissingApp
		return decision, ErrAppAuthMissingApp
	}

	if keyID == "" {
		decision.Reason = AppAuthReasonMissingAPIKey
		return decision, ErrAppAuthMissingAPIKey
	}

	if len(req.RequestedScopes) == 0 {
		decision.Reason = AppAuthReasonMissingScope
		return decision, ErrAppAuthMissingScope
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	app, ok := r.apps[appID]
	if !ok {
		decision.Reason = AppAuthReasonMissingApp
		return decision, ErrAppAuthMissingApp
	}

	if app.TenantID != tenantID {
		decision.Reason = AppAuthReasonCrossTenant
		return decision, ErrAppAuthCrossTenant
	}

	if app.Status != AppStatusActive {
		decision.Reason = AppAuthReasonInactiveApp
		return decision, ErrAppAuthInactiveApp
	}

	if req.Environment != "" && app.Environment != environment {
		decision.Reason = AppAuthReasonEnvironmentMismatch
		return decision, ErrAppAuthEnvironmentMismatch
	}

	relation, ok := r.findActiveRelationLocked(tenantID, appID, keyID)
	if !ok {
		decision.Reason = AppAuthReasonMissingRelation
		return decision, ErrAppAuthMissingRelation
	}

	if relation.Status != AppAuthRelationStatusActive {
		decision.Reason = AppAuthReasonInactiveRelation
		return decision, ErrAppAuthInactiveRelation
	}

	requestedScopes, err := normalizeScopeList(req.RequestedScopes)
	if err != nil {
		decision.Reason = AppAuthReasonMissingScope
		return decision, err
	}

	if !allScopesIncluded(requestedScopes, relation.EffectiveScopes) {
		decision.Reason = AppAuthReasonScopeNotAllowed
		return decision, ErrAppAuthScopeNotAllowed
	}

	decision.Decision = AppAuthDecisionAllow
	decision.Allowed = true
	decision.RelationID = relation.RelationID
	decision.Environment = relation.Environment
	decision.Scopes = requestedScopes
	decision.Reason = AppAuthReasonAllowed

	return decision, nil
}

func (r *AppAuthRuntime) SuspendApp(tenantID string, appID string) (AppRegistration, AppAuthDecision, error) {
	return r.changeAppStatus(tenantID, appID, AppStatusSuspended)
}

func (r *AppAuthRuntime) RevokeApp(tenantID string, appID string) (AppRegistration, AppAuthDecision, error) {
	return r.changeAppStatus(tenantID, appID, AppStatusRevoked)
}

func (r *AppAuthRuntime) GetApp(tenantID string, appID string) (AppRegistration, error) {
	tenantID = strings.TrimSpace(tenantID)
	appID = strings.TrimSpace(appID)

	if tenantID == "" {
		return AppRegistration{}, ErrAppAuthMissingTenant
	}
	if appID == "" {
		return AppRegistration{}, ErrAppAuthMissingApp
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	app, ok := r.apps[appID]
	if !ok {
		return AppRegistration{}, ErrAppAuthMissingApp
	}
	if app.TenantID != tenantID {
		return AppRegistration{}, ErrAppAuthCrossTenant
	}

	return app, nil
}

func (r *AppAuthRuntime) ListTenantApps(tenantID string) ([]AppRegistration, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrAppAuthMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]AppRegistration, 0)
	for _, app := range r.apps {
		if app.TenantID == tenantID {
			out = append(out, app)
		}
	}

	return out, nil
}

func (r *AppAuthRuntime) changeAppStatus(tenantID string, appID string, status string) (AppRegistration, AppAuthDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID = strings.TrimSpace(tenantID)
	appID = strings.TrimSpace(appID)

	decision := AppAuthDecision{
		Decision:  AppAuthDecisionDeny,
		Allowed:   false,
		TenantID:  tenantID,
		AppID:     appID,
		CheckedAt: now,
	}

	if tenantID == "" {
		decision.Reason = AppAuthReasonMissingTenant
		return AppRegistration{}, decision, ErrAppAuthMissingTenant
	}

	if appID == "" {
		decision.Reason = AppAuthReasonMissingApp
		return AppRegistration{}, decision, ErrAppAuthMissingApp
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	app, ok := r.apps[appID]
	if !ok {
		decision.Reason = AppAuthReasonMissingApp
		return AppRegistration{}, decision, ErrAppAuthMissingApp
	}

	if app.TenantID != tenantID {
		decision.Reason = AppAuthReasonCrossTenant
		return AppRegistration{}, decision, ErrAppAuthCrossTenant
	}

	app.Status = status
	app.UpdatedAt = now

	switch status {
	case AppStatusSuspended:
		app.SuspendedAt = now
	case AppStatusRevoked:
		app.RevokedAt = now
	}

	r.apps[appID] = app

	decision.Decision = AppAuthDecisionAllow
	decision.Allowed = true
	decision.Environment = app.Environment
	decision.Scopes = app.AllowedScopes
	decision.Reason = AppAuthReasonAllowed

	return app, decision, nil
}

func (r *AppAuthRuntime) findActiveRelationLocked(tenantID string, appID string, keyID string) (AppAPIKeyRelation, bool) {
	for _, relation := range r.relations {
		if relation.TenantID == tenantID &&
			relation.AppID == appID &&
			relation.KeyID == keyID &&
			relation.Status == AppAuthRelationStatusActive {
			return relation, true
		}
	}
	return AppAPIKeyRelation{}, false
}

func (r *AppAuthRuntime) normalizeAndValidateScopes(scopes []string) ([]string, error) {
	normalized, err := normalizeScopeList(scopes)
	if err != nil {
		return nil, err
	}

	for _, scope := range normalized {
		if !scopeInList(scope, r.config.AllowedScopes) {
			return nil, ErrAppAuthInvalidScope
		}
	}

	return normalized, nil
}

func (r *AppAuthRuntime) environmentAllowed(environment string) bool {
	for _, allowed := range r.config.AllowedEnvironments {
		if strings.EqualFold(strings.TrimSpace(allowed), strings.TrimSpace(environment)) {
			return true
		}
	}
	return false
}

func deriveEffectiveAppScopes(appScopes []string, keyScopes []string) ([]string, error) {
	normalizedKeyScopes, err := normalizeScopeList(keyScopes)
	if err != nil {
		return nil, err
	}

	normalizedAppScopes, err := normalizeScopeList(appScopes)
	if err != nil {
		return nil, err
	}

	if !allScopesIncluded(normalizedKeyScopes, normalizedAppScopes) {
		return nil, ErrAppAuthScopeNotAllowed
	}

	return normalizedKeyScopes, nil
}

func normalizeScopeList(scopes []string) ([]string, error) {
	if len(scopes) == 0 {
		return nil, ErrAppAuthMissingScope
	}

	seen := map[string]struct{}{}
	out := make([]string, 0, len(scopes))

	for _, scope := range scopes {
		scope = strings.TrimSpace(scope)
		if scope == "" {
			continue
		}
		if _, ok := seen[scope]; ok {
			continue
		}
		seen[scope] = struct{}{}
		out = append(out, scope)
	}

	if len(out) == 0 {
		return nil, ErrAppAuthMissingScope
	}

	return out, nil
}

func allScopesIncluded(required []string, allowed []string) bool {
	for _, scope := range required {
		if !scopeInList(scope, allowed) {
			return false
		}
	}
	return true
}

func scopeInList(scope string, values []string) bool {
	for _, value := range values {
		if strings.EqualFold(strings.TrimSpace(value), strings.TrimSpace(scope)) {
			return true
		}
	}
	return false
}

func NewAppID() string {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "app_" + strings.ReplaceAll(time.Now().UTC().Format("20060102150405.000000000"), ".", "")
	}
	return "app_" + hex.EncodeToString(raw[:])
}

func NewAppAPIKeyRelationID() string {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "appkey_" + strings.ReplaceAll(time.Now().UTC().Format("20060102150405.000000000"), ".", "")
	}
	return "appkey_" + hex.EncodeToString(raw[:])
}
