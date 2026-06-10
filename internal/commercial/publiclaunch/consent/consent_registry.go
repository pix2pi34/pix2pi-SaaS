package consent

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"
)

type ConsentScope string
type ConsentStatus string
type FeatureGate string

const (
	ScopeDataSupportedPlanTerms               ConsentScope = "DATA_SUPPORTED_PLAN_TERMS"
	ScopePersonalDataCommercialRecommendation ConsentScope = "PERSONAL_DATA_COMMERCIAL_RECOMMENDATION"
	ScopeSponsoredOfferPersonalization        ConsentScope = "SPONSORED_OFFER_PERSONALIZATION"
	ScopeAnonymizedAggregatedInsight          ConsentScope = "ANONYMIZED_AGGREGATED_INSIGHT"
	ScopeAIDecisionSupport                    ConsentScope = "AI_DECISION_SUPPORT"
	ScopeCommercialElectronicMessage          ConsentScope = "COMMERCIAL_ELECTRONIC_MESSAGE"
	ScopeNonEssentialCookies                  ConsentScope = "NON_ESSENTIAL_COOKIES"

	StatusUnknown  ConsentStatus = "UNKNOWN"
	StatusAccepted ConsentStatus = "ACCEPTED"
	StatusDeclined ConsentStatus = "DECLINED"
	StatusRevoked  ConsentStatus = "REVOKED"

	GateCoreProduct                   FeatureGate = "core_product"
	GateDataSupportedPlan             FeatureGate = "data_supported_plan"
	GateCommercialRecommendation      FeatureGate = "commercial_recommendation"
	GateSponsoredOfferPersonalization FeatureGate = "sponsored_offer_personalization"
	GateAnonymousAggregatedInsight    FeatureGate = "anonymous_aggregated_insight"
	GateAIDecisionSupport             FeatureGate = "ai_decision_support"
	GateCommercialElectronicMessage   FeatureGate = "commercial_electronic_message"
	GateNonEssentialCookies           FeatureGate = "non_essential_cookies"
)

var (
	ErrTenantRequired          = errors.New("tenant_id is required")
	ErrUserRequired            = errors.New("user_id is required")
	ErrScopeRequired           = errors.New("consent_scope is required")
	ErrDocumentVersionRequired = errors.New("document_version is required")
	ErrIPAddressRequired       = errors.New("ip_address is required")
	ErrChannelRequired         = errors.New("channel is required")
	ErrConsentNotFound         = errors.New("consent record not found")
)

type ConsentDecision struct {
	TenantID        string
	UserID          string
	Scope           ConsentScope
	Status          ConsentStatus
	DocumentVersion string
	AcceptedAt      time.Time
	RevokedAt       *time.Time
	IPAddress       string
	UserAgent       string
	Channel         string
	EvidenceHash    string
	CorrelationID   string
	Reason          string
}

type DecisionInput struct {
	TenantID        string
	UserID          string
	Scope           ConsentScope
	DocumentVersion string
	IPAddress       string
	UserAgent       string
	Channel         string
	CorrelationID   string
	Reason          string
	Now             time.Time
}

type FeatureGateDecision struct {
	Gate     FeatureGate
	Allowed  bool
	Reason   string
	Scope    ConsentScope
	PlanMode string
	TenantID string
	UserID   string
}

type Registry struct {
	mu        sync.RWMutex
	decisions map[string]ConsentDecision
}

func NewRegistry() *Registry {
	return &Registry{decisions: map[string]ConsentDecision{}}
}

func (r *Registry) Accept(input DecisionInput) (ConsentDecision, error) {
	return r.record(input, StatusAccepted)
}

func (r *Registry) Decline(input DecisionInput) (ConsentDecision, error) {
	return r.record(input, StatusDeclined)
}

func (r *Registry) Revoke(input DecisionInput) (ConsentDecision, error) {
	if err := validateInput(input); err != nil {
		return ConsentDecision{}, err
	}

	now := normalizeTime(input.Now)

	r.mu.Lock()
	defer r.mu.Unlock()

	key := consentKey(input.TenantID, input.UserID, input.Scope)
	prev, ok := r.decisions[key]
	if !ok {
		return ConsentDecision{}, ErrConsentNotFound
	}

	prev.Status = StatusRevoked
	prev.RevokedAt = &now
	prev.CorrelationID = strings.TrimSpace(input.CorrelationID)
	prev.Reason = strings.TrimSpace(input.Reason)
	prev.EvidenceHash = evidenceHash(prev)

	r.decisions[key] = prev
	return prev, nil
}

func (r *Registry) Get(tenantID, userID string, scope ConsentScope) (ConsentDecision, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	decision, ok := r.decisions[consentKey(tenantID, userID, scope)]
	return decision, ok
}

func (r *Registry) Status(tenantID, userID string, scope ConsentScope) ConsentStatus {
	decision, ok := r.Get(tenantID, userID, scope)
	if !ok {
		return StatusUnknown
	}
	return decision.Status
}

func (r *Registry) IsAccepted(tenantID, userID string, scope ConsentScope) bool {
	return r.Status(tenantID, userID, scope) == StatusAccepted
}

func (r *Registry) EvaluateGate(tenantID, userID string, gate FeatureGate) FeatureGateDecision {
	if gate == GateCoreProduct {
		return FeatureGateDecision{
			Gate:     gate,
			Allowed:  true,
			Reason:   "core product is allowed separately from data monetization consent",
			TenantID: tenantID,
			UserID:   userID,
		}
	}

	scope, ok := requiredScopeForGate(gate)
	if !ok {
		return FeatureGateDecision{
			Gate:     gate,
			Allowed:  false,
			Reason:   "unknown feature gate",
			TenantID: tenantID,
			UserID:   userID,
		}
	}

	if r.IsAccepted(tenantID, userID, scope) {
		return FeatureGateDecision{
			Gate:     gate,
			Allowed:  true,
			Reason:   "required consent scope accepted",
			Scope:    scope,
			PlanMode: "DATA_SUPPORTED_OR_ALLOWED_BY_SCOPE",
			TenantID: tenantID,
			UserID:   userID,
		}
	}

	return FeatureGateDecision{
		Gate:     gate,
		Allowed:  false,
		Reason:   "required consent scope is not accepted; route to restricted paid or disabled feature",
		Scope:    scope,
		PlanMode: "RESTRICTED_PAID_OR_DISABLED",
		TenantID: tenantID,
		UserID:   userID,
	}
}

func (r *Registry) Snapshot(tenantID, userID string) []ConsentDecision {
	r.mu.RLock()
	defer r.mu.RUnlock()

	prefix := strings.TrimSpace(tenantID) + "|" + strings.TrimSpace(userID) + "|"
	out := make([]ConsentDecision, 0)
	for key, decision := range r.decisions {
		if strings.HasPrefix(key, prefix) {
			out = append(out, decision)
		}
	}

	sort.Slice(out, func(i, j int) bool {
		return out[i].Scope < out[j].Scope
	})

	return out
}

func (r *Registry) record(input DecisionInput, status ConsentStatus) (ConsentDecision, error) {
	if err := validateInput(input); err != nil {
		return ConsentDecision{}, err
	}

	now := normalizeTime(input.Now)

	decision := ConsentDecision{
		TenantID:        strings.TrimSpace(input.TenantID),
		UserID:          strings.TrimSpace(input.UserID),
		Scope:           input.Scope,
		Status:          status,
		DocumentVersion: strings.TrimSpace(input.DocumentVersion),
		AcceptedAt:      now,
		IPAddress:       strings.TrimSpace(input.IPAddress),
		UserAgent:       strings.TrimSpace(input.UserAgent),
		Channel:         strings.TrimSpace(input.Channel),
		CorrelationID:   strings.TrimSpace(input.CorrelationID),
		Reason:          strings.TrimSpace(input.Reason),
	}

	decision.EvidenceHash = evidenceHash(decision)

	r.mu.Lock()
	defer r.mu.Unlock()

	r.decisions[consentKey(decision.TenantID, decision.UserID, decision.Scope)] = decision
	return decision, nil
}

func validateInput(input DecisionInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}
	if strings.TrimSpace(input.UserID) == "" {
		return ErrUserRequired
	}
	if strings.TrimSpace(string(input.Scope)) == "" {
		return ErrScopeRequired
	}
	if strings.TrimSpace(input.DocumentVersion) == "" {
		return ErrDocumentVersionRequired
	}
	if strings.TrimSpace(input.IPAddress) == "" {
		return ErrIPAddressRequired
	}
	if strings.TrimSpace(input.Channel) == "" {
		return ErrChannelRequired
	}
	return nil
}

func normalizeTime(t time.Time) time.Time {
	if t.IsZero() {
		return time.Now().UTC()
	}
	return t.UTC()
}

func consentKey(tenantID, userID string, scope ConsentScope) string {
	return strings.TrimSpace(tenantID) + "|" + strings.TrimSpace(userID) + "|" + strings.TrimSpace(string(scope))
}

func requiredScopeForGate(gate FeatureGate) (ConsentScope, bool) {
	switch gate {
	case GateDataSupportedPlan:
		return ScopeDataSupportedPlanTerms, true
	case GateCommercialRecommendation:
		return ScopePersonalDataCommercialRecommendation, true
	case GateSponsoredOfferPersonalization:
		return ScopeSponsoredOfferPersonalization, true
	case GateAnonymousAggregatedInsight:
		return ScopeAnonymizedAggregatedInsight, true
	case GateAIDecisionSupport:
		return ScopeAIDecisionSupport, true
	case GateCommercialElectronicMessage:
		return ScopeCommercialElectronicMessage, true
	case GateNonEssentialCookies:
		return ScopeNonEssentialCookies, true
	default:
		return "", false
	}
}

func evidenceHash(decision ConsentDecision) string {
	raw := fmt.Sprintf(
		"%s|%s|%s|%s|%s|%s|%s|%s|%s|%s",
		decision.TenantID,
		decision.UserID,
		decision.Scope,
		decision.Status,
		decision.DocumentVersion,
		decision.AcceptedAt.Format(time.RFC3339Nano),
		formatRevokedAt(decision.RevokedAt),
		decision.IPAddress,
		decision.Channel,
		decision.CorrelationID,
	)

	sum := sha256.Sum256([]byte(raw))
	return hex.EncodeToString(sum[:])
}

func formatRevokedAt(t *time.Time) string {
	if t == nil {
		return ""
	}
	return t.UTC().Format(time.RFC3339Nano)
}
