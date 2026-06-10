package publicapiruntime

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	APIKeyEnvironmentSandbox    = "SANDBOX"
	APIKeyEnvironmentProduction = "PRODUCTION"

	APIKeyStatusActive  = "ACTIVE"
	APIKeyStatusRevoked = "REVOKED"
	APIKeyStatusRotated = "ROTATED"

	APIKeyDecisionAllow = "ALLOW"
	APIKeyDecisionDeny  = "DENY"

	APIKeyReasonAllowed             = "API_KEY_ALLOWED"
	APIKeyReasonMissingTenant       = "API_KEY_MISSING_TENANT"
	APIKeyReasonMissingKey          = "API_KEY_MISSING_KEY"
	APIKeyReasonMissingName         = "API_KEY_MISSING_NAME"
	APIKeyReasonInvalidEnvironment  = "API_KEY_INVALID_ENVIRONMENT"
	APIKeyReasonMissingScope        = "API_KEY_MISSING_SCOPE"
	APIKeyReasonInvalidScope        = "API_KEY_INVALID_SCOPE"
	APIKeyReasonCrossTenant         = "API_KEY_CROSS_TENANT_DENIED"
	APIKeyReasonAlreadyInactive     = "API_KEY_ALREADY_INACTIVE"
	APIKeyReasonRawSecretNotAllowed = "API_KEY_RAW_SECRET_NOT_ALLOWED_IN_RECORD"
)

var (
	ErrAPIKeyMissingTenant       = errors.New("missing api key tenant id")
	ErrAPIKeyMissingKey          = errors.New("missing api key id")
	ErrAPIKeyMissingName         = errors.New("missing api key name")
	ErrAPIKeyInvalidEnvironment  = errors.New("invalid api key environment")
	ErrAPIKeyMissingScope        = errors.New("missing api key scope")
	ErrAPIKeyInvalidScope        = errors.New("invalid api key scope")
	ErrAPIKeyCrossTenant         = errors.New("cross-tenant api key access denied")
	ErrAPIKeyAlreadyInactive     = errors.New("api key already inactive")
	ErrAPIKeyRawSecretNotAllowed = errors.New("raw api key secret must not be stored")
)

type APIKeyIssuanceRuntimeConfig struct {
	RequireTenant       bool     `json:"require_tenant"`
	KeyPrefix           string   `json:"key_prefix"`
	AllowedScopes       []string `json:"allowed_scopes"`
	AllowedEnvironments []string `json:"allowed_environments"`
}

func DefaultAPIKeyIssuanceRuntimeConfig() APIKeyIssuanceRuntimeConfig {
	return APIKeyIssuanceRuntimeConfig{
		RequireTenant: true,
		KeyPrefix:     "pix2pi",
		AllowedScopes: []string{
			"read",
			"write",
			"webhook:read",
			"webhook:write",
			"report:read",
			"admin:limited",
		},
		AllowedEnvironments: []string{
			APIKeyEnvironmentSandbox,
			APIKeyEnvironmentProduction,
		},
	}
}

type APIKeyIssueRequest struct {
	TenantID      string   `json:"tenant_id"`
	Name          string   `json:"name"`
	Environment   string   `json:"environment"`
	Scopes        []string `json:"scopes"`
	CreatedBy     string   `json:"created_by,omitempty"`
	CorrelationID string   `json:"correlation_id,omitempty"`
}

type APIKeyRecord struct {
	TenantID      string   `json:"tenant_id"`
	KeyID         string   `json:"key_id"`
	Name          string   `json:"name"`
	Prefix        string   `json:"prefix"`
	SecretHash    string   `json:"secret_hash"`
	Environment   string   `json:"environment"`
	Scopes        []string `json:"scopes"`
	Status        string   `json:"status"`
	CreatedBy     string   `json:"created_by,omitempty"`
	RevokedBy     string   `json:"revoked_by,omitempty"`
	RotatedFromID string   `json:"rotated_from_id,omitempty"`
	CorrelationID string   `json:"correlation_id,omitempty"`
	CreatedAt     string   `json:"created_at"`
	UpdatedAt     string   `json:"updated_at"`
	RevokedAt     string   `json:"revoked_at,omitempty"`
	RotatedAt     string   `json:"rotated_at,omitempty"`
}

type APIKeyIssueResult struct {
	Record    APIKeyRecord `json:"record"`
	RawSecret string       `json:"raw_secret"`
}

type APIKeyRuntimeDecision struct {
	Decision    string `json:"decision"`
	Allowed     bool   `json:"allowed"`
	TenantID    string `json:"tenant_id"`
	KeyID       string `json:"key_id,omitempty"`
	Environment string `json:"environment,omitempty"`
	Reason      string `json:"reason"`
	CheckedAt   string `json:"checked_at"`
}

type APIKeyIssuanceRuntime struct {
	config APIKeyIssuanceRuntimeConfig
	mu     sync.RWMutex
	keys   map[string]APIKeyRecord
}

func NewAPIKeyIssuanceRuntime(config APIKeyIssuanceRuntimeConfig) *APIKeyIssuanceRuntime {
	if strings.TrimSpace(config.KeyPrefix) == "" {
		config.KeyPrefix = "pix2pi"
	}
	if len(config.AllowedScopes) == 0 {
		config.AllowedScopes = DefaultAPIKeyIssuanceRuntimeConfig().AllowedScopes
	}
	if len(config.AllowedEnvironments) == 0 {
		config.AllowedEnvironments = DefaultAPIKeyIssuanceRuntimeConfig().AllowedEnvironments
	}

	return &APIKeyIssuanceRuntime{
		config: config,
		keys:   make(map[string]APIKeyRecord),
	}
}

func (r *APIKeyIssuanceRuntime) IssueKey(req APIKeyIssueRequest) (APIKeyIssueResult, APIKeyRuntimeDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	environment := normalizeEnvironment(req.Environment)

	decision := APIKeyRuntimeDecision{
		Decision:    APIKeyDecisionDeny,
		Allowed:     false,
		TenantID:    tenantID,
		Environment: environment,
		CheckedAt:   now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = APIKeyReasonMissingTenant
		return APIKeyIssueResult{}, decision, ErrAPIKeyMissingTenant
	}

	if strings.TrimSpace(req.Name) == "" {
		decision.Reason = APIKeyReasonMissingName
		return APIKeyIssueResult{}, decision, ErrAPIKeyMissingName
	}

	if !r.environmentAllowed(environment) {
		decision.Reason = APIKeyReasonInvalidEnvironment
		return APIKeyIssueResult{}, decision, ErrAPIKeyInvalidEnvironment
	}

	scopes, err := r.normalizeAndValidateScopes(req.Scopes)
	if err != nil {
		if errors.Is(err, ErrAPIKeyMissingScope) {
			decision.Reason = APIKeyReasonMissingScope
		} else {
			decision.Reason = APIKeyReasonInvalidScope
		}
		return APIKeyIssueResult{}, decision, err
	}

	keyID := NewAPIKeyID()
	rawSecret := NewAPIKeyRawSecret(r.config.KeyPrefix, environment)
	secretHash := HashAPIKeySecret(rawSecret)

	record := APIKeyRecord{
		TenantID:      tenantID,
		KeyID:         keyID,
		Name:          strings.TrimSpace(req.Name),
		Prefix:        r.config.KeyPrefix,
		SecretHash:    secretHash,
		Environment:   environment,
		Scopes:        scopes,
		Status:        APIKeyStatusActive,
		CreatedBy:     strings.TrimSpace(req.CreatedBy),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		CreatedAt:     now,
		UpdatedAt:     now,
	}

	if record.SecretHash == "" || strings.Contains(record.SecretHash, rawSecret) {
		decision.Reason = APIKeyReasonRawSecretNotAllowed
		return APIKeyIssueResult{}, decision, ErrAPIKeyRawSecretNotAllowed
	}

	r.mu.Lock()
	r.keys[keyID] = record
	r.mu.Unlock()

	decision.Decision = APIKeyDecisionAllow
	decision.Allowed = true
	decision.KeyID = keyID
	decision.Reason = APIKeyReasonAllowed

	return APIKeyIssueResult{
		Record:    record,
		RawSecret: rawSecret,
	}, decision, nil
}

func (r *APIKeyIssuanceRuntime) GetKey(tenantID string, keyID string) (APIKeyRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	keyID = strings.TrimSpace(keyID)

	if tenantID == "" {
		return APIKeyRecord{}, ErrAPIKeyMissingTenant
	}
	if keyID == "" {
		return APIKeyRecord{}, ErrAPIKeyMissingKey
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	record, ok := r.keys[keyID]
	if !ok {
		return APIKeyRecord{}, ErrAPIKeyMissingKey
	}
	if record.TenantID != tenantID {
		return APIKeyRecord{}, ErrAPIKeyCrossTenant
	}

	return record, nil
}

func (r *APIKeyIssuanceRuntime) RevokeKey(tenantID string, keyID string, actorRef string) (APIKeyRecord, APIKeyRuntimeDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID = strings.TrimSpace(tenantID)
	keyID = strings.TrimSpace(keyID)

	decision := APIKeyRuntimeDecision{
		Decision:  APIKeyDecisionDeny,
		Allowed:   false,
		TenantID:  tenantID,
		KeyID:     keyID,
		CheckedAt: now,
	}

	if tenantID == "" {
		decision.Reason = APIKeyReasonMissingTenant
		return APIKeyRecord{}, decision, ErrAPIKeyMissingTenant
	}
	if keyID == "" {
		decision.Reason = APIKeyReasonMissingKey
		return APIKeyRecord{}, decision, ErrAPIKeyMissingKey
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	record, ok := r.keys[keyID]
	if !ok {
		decision.Reason = APIKeyReasonMissingKey
		return APIKeyRecord{}, decision, ErrAPIKeyMissingKey
	}
	if record.TenantID != tenantID {
		decision.Reason = APIKeyReasonCrossTenant
		return APIKeyRecord{}, decision, ErrAPIKeyCrossTenant
	}
	if record.Status != APIKeyStatusActive {
		decision.Reason = APIKeyReasonAlreadyInactive
		return APIKeyRecord{}, decision, ErrAPIKeyAlreadyInactive
	}

	record.Status = APIKeyStatusRevoked
	record.RevokedBy = strings.TrimSpace(actorRef)
	record.RevokedAt = now
	record.UpdatedAt = now
	r.keys[keyID] = record

	decision.Decision = APIKeyDecisionAllow
	decision.Allowed = true
	decision.Environment = record.Environment
	decision.Reason = APIKeyReasonAllowed

	return record, decision, nil
}

func (r *APIKeyIssuanceRuntime) RotateKey(tenantID string, keyID string, actorRef string) (APIKeyIssueResult, APIKeyRuntimeDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID = strings.TrimSpace(tenantID)
	keyID = strings.TrimSpace(keyID)

	decision := APIKeyRuntimeDecision{
		Decision:  APIKeyDecisionDeny,
		Allowed:   false,
		TenantID:  tenantID,
		KeyID:     keyID,
		CheckedAt: now,
	}

	if tenantID == "" {
		decision.Reason = APIKeyReasonMissingTenant
		return APIKeyIssueResult{}, decision, ErrAPIKeyMissingTenant
	}
	if keyID == "" {
		decision.Reason = APIKeyReasonMissingKey
		return APIKeyIssueResult{}, decision, ErrAPIKeyMissingKey
	}

	r.mu.Lock()
	oldRecord, ok := r.keys[keyID]
	if !ok {
		r.mu.Unlock()
		decision.Reason = APIKeyReasonMissingKey
		return APIKeyIssueResult{}, decision, ErrAPIKeyMissingKey
	}
	if oldRecord.TenantID != tenantID {
		r.mu.Unlock()
		decision.Reason = APIKeyReasonCrossTenant
		return APIKeyIssueResult{}, decision, ErrAPIKeyCrossTenant
	}
	if oldRecord.Status != APIKeyStatusActive {
		r.mu.Unlock()
		decision.Reason = APIKeyReasonAlreadyInactive
		return APIKeyIssueResult{}, decision, ErrAPIKeyAlreadyInactive
	}

	oldRecord.Status = APIKeyStatusRotated
	oldRecord.RotatedAt = now
	oldRecord.UpdatedAt = now
	r.keys[keyID] = oldRecord
	r.mu.Unlock()

	return r.IssueKey(APIKeyIssueRequest{
		TenantID:      oldRecord.TenantID,
		Name:          oldRecord.Name,
		Environment:   oldRecord.Environment,
		Scopes:        oldRecord.Scopes,
		CreatedBy:     strings.TrimSpace(actorRef),
		CorrelationID: oldRecord.CorrelationID,
	})
}

func (r *APIKeyIssuanceRuntime) ListTenantKeys(tenantID string) ([]APIKeyRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrAPIKeyMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	keys := make([]APIKeyRecord, 0)
	for _, record := range r.keys {
		if record.TenantID == tenantID {
			keys = append(keys, record)
		}
	}
	return keys, nil
}

func (r *APIKeyIssuanceRuntime) normalizeAndValidateScopes(scopes []string) ([]string, error) {
	if len(scopes) == 0 {
		return nil, ErrAPIKeyMissingScope
	}

	seen := map[string]struct{}{}
	normalized := make([]string, 0, len(scopes))

	for _, scope := range scopes {
		scope = strings.TrimSpace(scope)
		if scope == "" {
			continue
		}
		if !r.scopeAllowed(scope) {
			return nil, ErrAPIKeyInvalidScope
		}
		if _, ok := seen[scope]; ok {
			continue
		}
		seen[scope] = struct{}{}
		normalized = append(normalized, scope)
	}

	if len(normalized) == 0 {
		return nil, ErrAPIKeyMissingScope
	}

	return normalized, nil
}

func (r *APIKeyIssuanceRuntime) scopeAllowed(scope string) bool {
	for _, allowed := range r.config.AllowedScopes {
		if strings.EqualFold(strings.TrimSpace(allowed), strings.TrimSpace(scope)) {
			return true
		}
	}
	return false
}

func (r *APIKeyIssuanceRuntime) environmentAllowed(environment string) bool {
	for _, allowed := range r.config.AllowedEnvironments {
		if strings.EqualFold(strings.TrimSpace(allowed), strings.TrimSpace(environment)) {
			return true
		}
	}
	return false
}

func normalizeEnvironment(environment string) string {
	environment = strings.TrimSpace(environment)
	if environment == "" {
		return APIKeyEnvironmentSandbox
	}
	return strings.ToUpper(environment)
}

func HashAPIKeySecret(rawSecret string) string {
	sum := sha256.Sum256([]byte(rawSecret))
	return "sha256:" + hex.EncodeToString(sum[:])
}

func NewAPIKeyID() string {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "ak_" + strings.ReplaceAll(time.Now().UTC().Format("20060102150405.000000000"), ".", "")
	}
	return "ak_" + hex.EncodeToString(raw[:])
}

func NewAPIKeyRawSecret(prefix string, environment string) string {
	var raw [24]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return strings.TrimSpace(prefix) + "_" + strings.ToLower(normalizeEnvironment(environment)) + "_" + strings.ReplaceAll(time.Now().UTC().Format("20060102150405.000000000"), ".", "")
	}
	return strings.TrimSpace(prefix) + "_" + strings.ToLower(normalizeEnvironment(environment)) + "_" + hex.EncodeToString(raw[:])
}
