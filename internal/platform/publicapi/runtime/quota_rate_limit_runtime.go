package publicapiruntime

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"
)

const (
	QuotaPolicyStatusActive    = "ACTIVE"
	QuotaPolicyStatusSuspended = "SUSPENDED"
	QuotaPolicyStatusRevoked   = "REVOKED"

	QuotaDecisionAllow = "ALLOW"
	QuotaDecisionDeny  = "DENY"

	QuotaReasonAllowed            = "QUOTA_ALLOWED"
	QuotaReasonMissingTenant      = "QUOTA_MISSING_TENANT"
	QuotaReasonMissingPolicy      = "QUOTA_MISSING_POLICY"
	QuotaReasonMissingApp         = "QUOTA_MISSING_APP"
	QuotaReasonMissingAPIKey      = "QUOTA_MISSING_API_KEY"
	QuotaReasonMissingScope       = "QUOTA_MISSING_SCOPE"
	QuotaReasonInvalidEnvironment = "QUOTA_INVALID_ENVIRONMENT"
	QuotaReasonInvalidLimit       = "QUOTA_INVALID_LIMIT"
	QuotaReasonInvalidWindow      = "QUOTA_INVALID_WINDOW"
	QuotaReasonCrossTenant        = "QUOTA_CROSS_TENANT_DENIED"
	QuotaReasonInactivePolicy     = "QUOTA_POLICY_INACTIVE"
	QuotaReasonPolicyMismatch     = "QUOTA_POLICY_MISMATCH"
	QuotaReasonLimitExceeded      = "QUOTA_LIMIT_EXCEEDED"
)

var (
	ErrQuotaMissingTenant      = errors.New("missing quota tenant id")
	ErrQuotaMissingPolicy      = errors.New("missing quota policy")
	ErrQuotaMissingApp         = errors.New("missing quota app id")
	ErrQuotaMissingAPIKey      = errors.New("missing quota api key id")
	ErrQuotaMissingScope       = errors.New("missing quota scope")
	ErrQuotaInvalidEnvironment = errors.New("invalid quota environment")
	ErrQuotaInvalidLimit       = errors.New("invalid quota limit")
	ErrQuotaInvalidWindow      = errors.New("invalid quota window")
	ErrQuotaCrossTenant        = errors.New("cross-tenant quota access denied")
	ErrQuotaInactivePolicy     = errors.New("quota policy is inactive")
	ErrQuotaPolicyMismatch     = errors.New("quota policy mismatch")
	ErrQuotaLimitExceeded      = errors.New("quota limit exceeded")
)

type QuotaRateLimitRuntimeConfig struct {
	RequireTenant        bool     `json:"require_tenant"`
	DefaultWindowSeconds int      `json:"default_window_seconds"`
	AllowedEnvironments  []string `json:"allowed_environments"`
	AllowedScopes        []string `json:"allowed_scopes"`
}

func DefaultQuotaRateLimitRuntimeConfig() QuotaRateLimitRuntimeConfig {
	defaults := DefaultAppAuthRuntimeConfig()

	return QuotaRateLimitRuntimeConfig{
		RequireTenant:        true,
		DefaultWindowSeconds: 60,
		AllowedEnvironments:  defaults.AllowedEnvironments,
		AllowedScopes:        defaults.AllowedScopes,
	}
}

type QuotaPolicyCreateRequest struct {
	TenantID      string `json:"tenant_id"`
	AppID         string `json:"app_id"`
	KeyID         string `json:"key_id"`
	Environment   string `json:"environment"`
	Scope         string `json:"scope"`
	WindowSeconds int    `json:"window_seconds"`
	MaxRequests   int    `json:"max_requests"`
	CreatedBy     string `json:"created_by,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
}

type QuotaPolicy struct {
	TenantID      string `json:"tenant_id"`
	PolicyID      string `json:"policy_id"`
	AppID         string `json:"app_id"`
	KeyID         string `json:"key_id"`
	Environment   string `json:"environment"`
	Scope         string `json:"scope"`
	WindowSeconds int    `json:"window_seconds"`
	MaxRequests   int    `json:"max_requests"`
	Status        string `json:"status"`
	CreatedBy     string `json:"created_by,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
	CreatedAt     string `json:"created_at"`
	UpdatedAt     string `json:"updated_at"`
	SuspendedAt   string `json:"suspended_at,omitempty"`
	RevokedAt     string `json:"revoked_at,omitempty"`
}

type QuotaUsageRequest struct {
	TenantID      string `json:"tenant_id"`
	AppID         string `json:"app_id"`
	KeyID         string `json:"key_id"`
	Environment   string `json:"environment"`
	Scope         string `json:"scope"`
	PolicyID      string `json:"policy_id,omitempty"`
	Units         int    `json:"units,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
}

type QuotaUsageMeter struct {
	TenantID    string `json:"tenant_id"`
	MeterID     string `json:"meter_id"`
	PolicyID    string `json:"policy_id"`
	AppID       string `json:"app_id"`
	KeyID       string `json:"key_id"`
	Environment string `json:"environment"`
	Scope       string `json:"scope"`
	WindowStart string `json:"window_start"`
	WindowEnd   string `json:"window_end"`
	Used        int    `json:"used"`
	Limit       int    `json:"limit"`
	Remaining   int    `json:"remaining"`
	UpdatedAt   string `json:"updated_at"`
}

type QuotaRateLimitDecision struct {
	Decision      string `json:"decision"`
	Allowed       bool   `json:"allowed"`
	TenantID      string `json:"tenant_id"`
	PolicyID      string `json:"policy_id,omitempty"`
	AppID         string `json:"app_id,omitempty"`
	KeyID         string `json:"key_id,omitempty"`
	Environment   string `json:"environment,omitempty"`
	Scope         string `json:"scope,omitempty"`
	Used          int    `json:"used"`
	Limit         int    `json:"limit"`
	Remaining     int    `json:"remaining"`
	RetryAfterSec int    `json:"retry_after_sec,omitempty"`
	Reason        string `json:"reason"`
	CheckedAt     string `json:"checked_at"`
}

type QuotaRateLimitRuntime struct {
	config   QuotaRateLimitRuntimeConfig
	mu       sync.RWMutex
	policies map[string]QuotaPolicy
	meters   map[string]QuotaUsageMeter
}

func NewQuotaRateLimitRuntime(config QuotaRateLimitRuntimeConfig) *QuotaRateLimitRuntime {
	if config.DefaultWindowSeconds <= 0 {
		config.DefaultWindowSeconds = 60
	}
	if len(config.AllowedEnvironments) == 0 {
		config.AllowedEnvironments = DefaultQuotaRateLimitRuntimeConfig().AllowedEnvironments
	}
	if len(config.AllowedScopes) == 0 {
		config.AllowedScopes = DefaultQuotaRateLimitRuntimeConfig().AllowedScopes
	}

	return &QuotaRateLimitRuntime{
		config:   config,
		policies: make(map[string]QuotaPolicy),
		meters:   make(map[string]QuotaUsageMeter),
	}
}

func (r *QuotaRateLimitRuntime) CreatePolicy(req QuotaPolicyCreateRequest) (QuotaPolicy, QuotaRateLimitDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	appID := strings.TrimSpace(req.AppID)
	keyID := strings.TrimSpace(req.KeyID)
	environment := normalizeEnvironment(req.Environment)
	scope := strings.TrimSpace(req.Scope)

	decision := QuotaRateLimitDecision{
		Decision:    QuotaDecisionDeny,
		Allowed:     false,
		TenantID:    tenantID,
		AppID:       appID,
		KeyID:       keyID,
		Environment: environment,
		Scope:       scope,
		CheckedAt:   now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = QuotaReasonMissingTenant
		return QuotaPolicy{}, decision, ErrQuotaMissingTenant
	}
	if appID == "" {
		decision.Reason = QuotaReasonMissingApp
		return QuotaPolicy{}, decision, ErrQuotaMissingApp
	}
	if keyID == "" {
		decision.Reason = QuotaReasonMissingAPIKey
		return QuotaPolicy{}, decision, ErrQuotaMissingAPIKey
	}
	if scope == "" {
		decision.Reason = QuotaReasonMissingScope
		return QuotaPolicy{}, decision, ErrQuotaMissingScope
	}
	if !r.environmentAllowed(environment) {
		decision.Reason = QuotaReasonInvalidEnvironment
		return QuotaPolicy{}, decision, ErrQuotaInvalidEnvironment
	}
	if !r.scopeAllowed(scope) {
		decision.Reason = QuotaReasonMissingScope
		return QuotaPolicy{}, decision, ErrQuotaMissingScope
	}

	windowSeconds := req.WindowSeconds
	if windowSeconds <= 0 {
		windowSeconds = r.config.DefaultWindowSeconds
	}
	if windowSeconds <= 0 {
		decision.Reason = QuotaReasonInvalidWindow
		return QuotaPolicy{}, decision, ErrQuotaInvalidWindow
	}
	if req.MaxRequests <= 0 {
		decision.Reason = QuotaReasonInvalidLimit
		return QuotaPolicy{}, decision, ErrQuotaInvalidLimit
	}

	policy := QuotaPolicy{
		TenantID:      tenantID,
		PolicyID:      NewQuotaPolicyID(),
		AppID:         appID,
		KeyID:         keyID,
		Environment:   environment,
		Scope:         scope,
		WindowSeconds: windowSeconds,
		MaxRequests:   req.MaxRequests,
		Status:        QuotaPolicyStatusActive,
		CreatedBy:     strings.TrimSpace(req.CreatedBy),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		CreatedAt:     now,
		UpdatedAt:     now,
	}

	r.mu.Lock()
	r.policies[policy.PolicyID] = policy
	r.mu.Unlock()

	decision.Decision = QuotaDecisionAllow
	decision.Allowed = true
	decision.PolicyID = policy.PolicyID
	decision.Limit = policy.MaxRequests
	decision.Remaining = policy.MaxRequests
	decision.Reason = QuotaReasonAllowed

	return policy, decision, nil
}

func (r *QuotaRateLimitRuntime) AllowRequest(req QuotaUsageRequest) (QuotaUsageMeter, QuotaRateLimitDecision, error) {
	nowTime := time.Now().UTC()
	now := nowTime.Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	appID := strings.TrimSpace(req.AppID)
	keyID := strings.TrimSpace(req.KeyID)
	environment := normalizeEnvironment(req.Environment)
	scope := strings.TrimSpace(req.Scope)

	decision := QuotaRateLimitDecision{
		Decision:    QuotaDecisionDeny,
		Allowed:     false,
		TenantID:    tenantID,
		AppID:       appID,
		KeyID:       keyID,
		Environment: environment,
		Scope:       scope,
		CheckedAt:   now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = QuotaReasonMissingTenant
		return QuotaUsageMeter{}, decision, ErrQuotaMissingTenant
	}
	if appID == "" {
		decision.Reason = QuotaReasonMissingApp
		return QuotaUsageMeter{}, decision, ErrQuotaMissingApp
	}
	if keyID == "" {
		decision.Reason = QuotaReasonMissingAPIKey
		return QuotaUsageMeter{}, decision, ErrQuotaMissingAPIKey
	}
	if scope == "" {
		decision.Reason = QuotaReasonMissingScope
		return QuotaUsageMeter{}, decision, ErrQuotaMissingScope
	}

	units := req.Units
	if units <= 0 {
		units = 1
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	policy, err := r.resolvePolicyLocked(req)
	if err != nil {
		decision.Reason = reasonForQuotaError(err)
		return QuotaUsageMeter{}, decision, err
	}

	decision.PolicyID = policy.PolicyID
	decision.Limit = policy.MaxRequests

	if policy.TenantID != tenantID {
		decision.Reason = QuotaReasonCrossTenant
		return QuotaUsageMeter{}, decision, ErrQuotaCrossTenant
	}
	if policy.Status != QuotaPolicyStatusActive {
		decision.Reason = QuotaReasonInactivePolicy
		return QuotaUsageMeter{}, decision, ErrQuotaInactivePolicy
	}
	if !policyMatchesRequest(policy, tenantID, appID, keyID, environment, scope) {
		decision.Reason = QuotaReasonPolicyMismatch
		return QuotaUsageMeter{}, decision, ErrQuotaPolicyMismatch
	}

	windowStart, windowEnd := quotaWindow(nowTime, policy.WindowSeconds)
	meterKey := quotaMeterKey(policy, windowStart)

	meter, ok := r.meters[meterKey]
	if !ok {
		meter = QuotaUsageMeter{
			TenantID:    tenantID,
			MeterID:     NewQuotaMeterID(),
			PolicyID:    policy.PolicyID,
			AppID:       appID,
			KeyID:       keyID,
			Environment: environment,
			Scope:       scope,
			WindowStart: windowStart.Format(time.RFC3339Nano),
			WindowEnd:   windowEnd.Format(time.RFC3339Nano),
			Limit:       policy.MaxRequests,
			Remaining:   policy.MaxRequests,
			UpdatedAt:   now,
		}
	}

	if meter.Used+units > policy.MaxRequests {
		decision.Decision = QuotaDecisionDeny
		decision.Allowed = false
		decision.Used = meter.Used
		decision.Remaining = maxInt(policy.MaxRequests-meter.Used, 0)
		decision.RetryAfterSec = maxInt(int(time.Until(windowEnd).Seconds()), 1)
		decision.Reason = QuotaReasonLimitExceeded
		meter.Remaining = decision.Remaining
		meter.UpdatedAt = now
		r.meters[meterKey] = meter
		return meter, decision, ErrQuotaLimitExceeded
	}

	meter.Used += units
	meter.Limit = policy.MaxRequests
	meter.Remaining = maxInt(policy.MaxRequests-meter.Used, 0)
	meter.UpdatedAt = now
	r.meters[meterKey] = meter

	decision.Decision = QuotaDecisionAllow
	decision.Allowed = true
	decision.Used = meter.Used
	decision.Remaining = meter.Remaining
	decision.Reason = QuotaReasonAllowed

	return meter, decision, nil
}

func (r *QuotaRateLimitRuntime) GetPolicy(tenantID string, policyID string) (QuotaPolicy, error) {
	tenantID = strings.TrimSpace(tenantID)
	policyID = strings.TrimSpace(policyID)

	if tenantID == "" {
		return QuotaPolicy{}, ErrQuotaMissingTenant
	}
	if policyID == "" {
		return QuotaPolicy{}, ErrQuotaMissingPolicy
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	policy, ok := r.policies[policyID]
	if !ok {
		return QuotaPolicy{}, ErrQuotaMissingPolicy
	}
	if policy.TenantID != tenantID {
		return QuotaPolicy{}, ErrQuotaCrossTenant
	}

	return policy, nil
}

func (r *QuotaRateLimitRuntime) SuspendPolicy(tenantID string, policyID string) (QuotaPolicy, QuotaRateLimitDecision, error) {
	return r.changePolicyStatus(tenantID, policyID, QuotaPolicyStatusSuspended)
}

func (r *QuotaRateLimitRuntime) RevokePolicy(tenantID string, policyID string) (QuotaPolicy, QuotaRateLimitDecision, error) {
	return r.changePolicyStatus(tenantID, policyID, QuotaPolicyStatusRevoked)
}

func (r *QuotaRateLimitRuntime) TenantUsageSnapshot(tenantID string) ([]QuotaUsageMeter, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrQuotaMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]QuotaUsageMeter, 0)
	for _, meter := range r.meters {
		if meter.TenantID == tenantID {
			out = append(out, meter)
		}
	}

	return out, nil
}

func (r *QuotaRateLimitRuntime) changePolicyStatus(tenantID string, policyID string, status string) (QuotaPolicy, QuotaRateLimitDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID = strings.TrimSpace(tenantID)
	policyID = strings.TrimSpace(policyID)

	decision := QuotaRateLimitDecision{
		Decision:  QuotaDecisionDeny,
		Allowed:   false,
		TenantID:  tenantID,
		PolicyID:  policyID,
		CheckedAt: now,
	}

	if tenantID == "" {
		decision.Reason = QuotaReasonMissingTenant
		return QuotaPolicy{}, decision, ErrQuotaMissingTenant
	}
	if policyID == "" {
		decision.Reason = QuotaReasonMissingPolicy
		return QuotaPolicy{}, decision, ErrQuotaMissingPolicy
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	policy, ok := r.policies[policyID]
	if !ok {
		decision.Reason = QuotaReasonMissingPolicy
		return QuotaPolicy{}, decision, ErrQuotaMissingPolicy
	}
	if policy.TenantID != tenantID {
		decision.Reason = QuotaReasonCrossTenant
		return QuotaPolicy{}, decision, ErrQuotaCrossTenant
	}

	policy.Status = status
	policy.UpdatedAt = now
	switch status {
	case QuotaPolicyStatusSuspended:
		policy.SuspendedAt = now
	case QuotaPolicyStatusRevoked:
		policy.RevokedAt = now
	}

	r.policies[policyID] = policy

	decision.Decision = QuotaDecisionAllow
	decision.Allowed = true
	decision.AppID = policy.AppID
	decision.KeyID = policy.KeyID
	decision.Environment = policy.Environment
	decision.Scope = policy.Scope
	decision.Limit = policy.MaxRequests
	decision.Reason = QuotaReasonAllowed

	return policy, decision, nil
}

func (r *QuotaRateLimitRuntime) resolvePolicyLocked(req QuotaUsageRequest) (QuotaPolicy, error) {
	policyID := strings.TrimSpace(req.PolicyID)
	if policyID != "" {
		policy, ok := r.policies[policyID]
		if !ok {
			return QuotaPolicy{}, ErrQuotaMissingPolicy
		}
		return policy, nil
	}

	tenantID := strings.TrimSpace(req.TenantID)
	appID := strings.TrimSpace(req.AppID)
	keyID := strings.TrimSpace(req.KeyID)
	environment := normalizeEnvironment(req.Environment)
	scope := strings.TrimSpace(req.Scope)

	for _, policy := range r.policies {
		if policyMatchesRequest(policy, tenantID, appID, keyID, environment, scope) {
			return policy, nil
		}
	}

	return QuotaPolicy{}, ErrQuotaMissingPolicy
}

func (r *QuotaRateLimitRuntime) environmentAllowed(environment string) bool {
	for _, allowed := range r.config.AllowedEnvironments {
		if strings.EqualFold(strings.TrimSpace(allowed), strings.TrimSpace(environment)) {
			return true
		}
	}
	return false
}

func (r *QuotaRateLimitRuntime) scopeAllowed(scope string) bool {
	for _, allowed := range r.config.AllowedScopes {
		if strings.EqualFold(strings.TrimSpace(allowed), strings.TrimSpace(scope)) {
			return true
		}
	}
	return false
}

func policyMatchesRequest(policy QuotaPolicy, tenantID string, appID string, keyID string, environment string, scope string) bool {
	return policy.TenantID == strings.TrimSpace(tenantID) &&
		policy.AppID == strings.TrimSpace(appID) &&
		policy.KeyID == strings.TrimSpace(keyID) &&
		policy.Environment == normalizeEnvironment(environment) &&
		policy.Scope == strings.TrimSpace(scope)
}

func quotaWindow(now time.Time, windowSeconds int) (time.Time, time.Time) {
	if windowSeconds <= 0 {
		windowSeconds = 60
	}

	unix := now.Unix()
	windowStartUnix := unix - (unix % int64(windowSeconds))
	start := time.Unix(windowStartUnix, 0).UTC()
	end := start.Add(time.Duration(windowSeconds) * time.Second)

	return start, end
}

func quotaMeterKey(policy QuotaPolicy, windowStart time.Time) string {
	return fmt.Sprintf("%s:%s:%s:%s:%s:%s",
		policy.TenantID,
		policy.AppID,
		policy.KeyID,
		policy.Environment,
		policy.Scope,
		windowStart.Format(time.RFC3339),
	)
}

func reasonForQuotaError(err error) string {
	switch err {
	case ErrQuotaMissingTenant:
		return QuotaReasonMissingTenant
	case ErrQuotaMissingPolicy:
		return QuotaReasonMissingPolicy
	case ErrQuotaMissingApp:
		return QuotaReasonMissingApp
	case ErrQuotaMissingAPIKey:
		return QuotaReasonMissingAPIKey
	case ErrQuotaMissingScope:
		return QuotaReasonMissingScope
	case ErrQuotaInvalidEnvironment:
		return QuotaReasonInvalidEnvironment
	case ErrQuotaInvalidLimit:
		return QuotaReasonInvalidLimit
	case ErrQuotaInvalidWindow:
		return QuotaReasonInvalidWindow
	case ErrQuotaCrossTenant:
		return QuotaReasonCrossTenant
	case ErrQuotaInactivePolicy:
		return QuotaReasonInactivePolicy
	case ErrQuotaPolicyMismatch:
		return QuotaReasonPolicyMismatch
	case ErrQuotaLimitExceeded:
		return QuotaReasonLimitExceeded
	default:
		return QuotaReasonMissingPolicy
	}
}

func NewQuotaPolicyID() string {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "quota_" + strings.ReplaceAll(time.Now().UTC().Format("20060102150405.000000000"), ".", "")
	}
	return "quota_" + hex.EncodeToString(raw[:])
}

func NewQuotaMeterID() string {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "meter_" + strings.ReplaceAll(time.Now().UTC().Format("20060102150405.000000000"), ".", "")
	}
	return "meter_" + hex.EncodeToString(raw[:])
}

func maxInt(a int, b int) int {
	if a > b {
		return a
	}
	return b
}
