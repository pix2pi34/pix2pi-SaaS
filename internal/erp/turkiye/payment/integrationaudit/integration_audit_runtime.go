package integrationaudit

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type RuntimeMode string

const (
	RuntimeModeSimulation RuntimeMode = "SIMULATION"
	RuntimeModeSandbox    RuntimeMode = "SANDBOX"
	RuntimeModeProduction RuntimeMode = "PRODUCTION"
)

type AuditScope string

const (
	ScopePOSProviderRuntime       AuditScope = "POS_PROVIDER_RUNTIME"
	ScopeBankCollectionRuntime    AuditScope = "BANK_COLLECTION_RUNTIME"
	ScopeReconciliationRuntime    AuditScope = "RECONCILIATION_RUNTIME"
	ScopeRefundCancelRuntime      AuditScope = "REFUND_CANCEL_RUNTIME"
	ScopePaymentStatusSync        AuditScope = "PAYMENT_STATUS_SYNC"
	ScopePaymentErrorRetryRuntime AuditScope = "PAYMENT_ERROR_RETRY_RUNTIME"
	ScopePaymentIntegrationE2E    AuditScope = "PAYMENT_INTEGRATION_E2E"
)

type AuditSource string

const (
	SourceRuntimeCheck   AuditSource = "RUNTIME_CHECK"
	SourceGoTest         AuditSource = "GO_TEST"
	SourceRealAudit      AuditSource = "REAL_IMPLEMENTATION_AUDIT"
	SourceEvidenceFile   AuditSource = "EVIDENCE_FILE"
	SourceConfigArtifact AuditSource = "CONFIG_ARTIFACT"
	SourceDocumentation  AuditSource = "DOCUMENTATION"
)

type AuditDecisionStatus string

const (
	DecisionAccepted     AuditDecisionStatus = "ACCEPTED"
	DecisionRejected     AuditDecisionStatus = "REJECTED"
	DecisionReviewNeeded AuditDecisionStatus = "REVIEW_NEEDED"
	DecisionReady        AuditDecisionStatus = "READY"
)

type AuditEventStatus string

const (
	EventStatusPass AuditEventStatus = "PASS"
	EventStatusFail AuditEventStatus = "FAIL"
	EventStatusWarn AuditEventStatus = "WARN"
)

type RuntimeConfig struct {
	RuntimeEnabled               bool         `json:"runtime_enabled"`
	Mode                         RuntimeMode  `json:"mode"`
	RealProviderGateOpen         bool         `json:"real_provider_gate_open"`
	ProductionApproved           bool         `json:"production_approved"`
	IdempotencyRequired          bool         `json:"idempotency_required"`
	EvidenceHashRequired         bool         `json:"evidence_hash_required"`
	ArtifactPathRequired         bool         `json:"artifact_path_required"`
	FailBlocksClosure            bool         `json:"fail_blocks_closure"`
	WarnRequiresReview           bool         `json:"warn_requires_review"`
	RequiredScopes               []AuditScope `json:"required_scopes"`
	AllowedProviderCodes         []string     `json:"allowed_provider_codes"`
	MinimumPassCountForReadiness int          `json:"minimum_pass_count_for_readiness"`
}

type IntegrationAuditEvent struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	AuditEventID string           `json:"audit_event_id"`
	Scope        AuditScope       `json:"scope"`
	Source       AuditSource      `json:"source"`
	Status       AuditEventStatus `json:"status"`

	ProviderCode         string `json:"provider_code"`
	PaymentTransactionID string `json:"payment_transaction_id"`
	TransactionNo        string `json:"transaction_no"`

	CheckName        string `json:"check_name"`
	ArtifactPath     string `json:"artifact_path"`
	EvidenceFilePath string `json:"evidence_file_path"`
	EvidenceHash     string `json:"evidence_hash"`

	PassCount int `json:"pass_count"`
	FailCount int `json:"fail_count"`
	WarnCount int `json:"warn_count"`

	OccurredAt time.Time `json:"occurred_at"`
}

type IntegrationAuditResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	AuditEventID string           `json:"audit_event_id"`
	Scope        AuditScope       `json:"scope"`
	Source       AuditSource      `json:"source"`
	Status       AuditEventStatus `json:"status"`

	DecisionStatus AuditDecisionStatus `json:"decision_status"`

	Accepted       bool `json:"accepted"`
	BlocksClosure  bool `json:"blocks_closure"`
	ReviewRequired bool `json:"review_required"`

	PassCount int `json:"pass_count"`
	FailCount int `json:"fail_count"`
	WarnCount int `json:"warn_count"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	RecordedAt          time.Time `json:"recorded_at"`
}

type EvidenceBundle struct {
	TenantID      string `json:"tenant_id"`
	CorrelationID string `json:"correlation_id"`
	RequestID     string `json:"request_id"`

	BundleID string `json:"bundle_id"`

	Events []IntegrationAuditEvent `json:"events"`

	PreparedAt time.Time `json:"prepared_at"`
}

type EvidenceBundleResult struct {
	TenantID      string `json:"tenant_id"`
	CorrelationID string `json:"correlation_id"`
	RequestID     string `json:"request_id"`

	BundleID string `json:"bundle_id"`

	DecisionStatus  AuditDecisionStatus `json:"decision_status"`
	ReadyForClosure bool                `json:"ready_for_closure"`
	ReviewRequired  bool                `json:"review_required"`

	TotalEventCount int `json:"total_event_count"`
	PassEventCount  int `json:"pass_event_count"`
	FailEventCount  int `json:"fail_event_count"`
	WarnEventCount  int `json:"warn_event_count"`

	TotalPassCount int `json:"total_pass_count"`
	TotalFailCount int `json:"total_fail_count"`
	TotalWarnCount int `json:"total_warn_count"`

	MissingScopes []AuditScope `json:"missing_scopes"`
	CoveredScopes []AuditScope `json:"covered_scopes"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	EvaluatedAt         time.Time `json:"evaluated_at"`
}

type IntegrationAuditRuntime struct {
	config RuntimeConfig
}

func NewIntegrationAuditRuntime(config RuntimeConfig) (*IntegrationAuditRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("integration audit runtime is disabled")
	}
	if config.Mode == "" {
		return nil, errors.New("runtime mode is required")
	}
	if len(config.RequiredScopes) == 0 {
		return nil, errors.New("required_scopes are required")
	}
	if len(config.AllowedProviderCodes) == 0 {
		return nil, errors.New("allowed_provider_codes are required")
	}
	if config.MinimumPassCountForReadiness < 0 {
		return nil, errors.New("minimum_pass_count_for_readiness cannot be negative")
	}
	if config.Mode == RuntimeModeProduction && (!config.RealProviderGateOpen || !config.ProductionApproved) {
		return nil, errors.New("production real provider audit access is closed until approvals and real provider gate are open")
	}

	return &IntegrationAuditRuntime{config: config}, nil
}

func (r *IntegrationAuditRuntime) RegisterAuditEvent(event IntegrationAuditEvent) (IntegrationAuditResult, error) {
	if err := r.validateEvent(event); err != nil {
		return rejectedEvent(event, "VALIDATION_FAILED", err.Error()), err
	}

	result := IntegrationAuditResult{
		TenantID:       event.TenantID,
		CorrelationID:  event.CorrelationID,
		RequestID:      event.RequestID,
		IdempotencyKey: event.IdempotencyKey,
		AuditEventID:   event.AuditEventID,
		Scope:          event.Scope,
		Source:         event.Source,
		Status:         event.Status,
		PassCount:      event.PassCount,
		FailCount:      event.FailCount,
		WarnCount:      event.WarnCount,
		RecordedAt:     time.Now().UTC(),
	}

	switch event.Status {
	case EventStatusPass:
		result.DecisionStatus = DecisionAccepted
		result.Accepted = true
		result.AuditAction = "INTEGRATION_AUDIT_EVENT_ACCEPTED"
		result.AuditDecisionReason = "audit event passed and accepted"
	case EventStatusWarn:
		result.DecisionStatus = DecisionReviewNeeded
		result.Accepted = true
		result.ReviewRequired = r.config.WarnRequiresReview
		result.AuditAction = "INTEGRATION_AUDIT_EVENT_WARN_REVIEW"
		result.AuditDecisionReason = "audit event has warning and requires review according to policy"
	case EventStatusFail:
		result.DecisionStatus = DecisionRejected
		result.Accepted = false
		result.BlocksClosure = r.config.FailBlocksClosure
		result.ReviewRequired = true
		result.AuditAction = "INTEGRATION_AUDIT_EVENT_FAIL_BLOCKED"
		result.AuditDecisionReason = "audit event failed and blocks closure according to policy"
	default:
		result.DecisionStatus = DecisionRejected
		result.Accepted = false
		result.BlocksClosure = true
		result.ErrorCode = "UNKNOWN_AUDIT_EVENT_STATUS"
		result.ErrorMessage = "unknown audit event status"
		result.AuditAction = "INTEGRATION_AUDIT_EVENT_REJECTED"
		result.AuditDecisionReason = "audit event has unknown status"
		return result, errors.New("unknown audit event status")
	}

	return result, nil
}

func (r *IntegrationAuditRuntime) EvaluateEvidenceBundle(bundle EvidenceBundle) (EvidenceBundleResult, error) {
	if err := r.validateBundle(bundle); err != nil {
		return rejectedBundle(bundle, "VALIDATION_FAILED", err.Error()), err
	}

	covered := make(map[AuditScope]bool)
	result := EvidenceBundleResult{
		TenantID:      bundle.TenantID,
		CorrelationID: bundle.CorrelationID,
		RequestID:     bundle.RequestID,
		BundleID:      bundle.BundleID,
		EvaluatedAt:   time.Now().UTC(),
	}

	for _, event := range bundle.Events {
		eventResult, err := r.RegisterAuditEvent(event)
		if err != nil {
			result.TotalEventCount++
			result.FailEventCount++
			result.TotalFailCount++
			result.DecisionStatus = DecisionRejected
			result.ReadyForClosure = false
			result.ReviewRequired = true
			result.ErrorCode = eventResult.ErrorCode
			result.ErrorMessage = eventResult.ErrorMessage
			result.AuditAction = "INTEGRATION_AUDIT_BUNDLE_REJECTED"
			result.AuditDecisionReason = "bundle contains invalid audit event"
			return result, err
		}

		result.TotalEventCount++
		result.TotalPassCount += event.PassCount
		result.TotalFailCount += event.FailCount
		result.TotalWarnCount += event.WarnCount
		covered[event.Scope] = true

		switch event.Status {
		case EventStatusPass:
			result.PassEventCount++
		case EventStatusWarn:
			result.WarnEventCount++
			if r.config.WarnRequiresReview {
				result.ReviewRequired = true
			}
		case EventStatusFail:
			result.FailEventCount++
			if r.config.FailBlocksClosure {
				result.DecisionStatus = DecisionRejected
				result.ReadyForClosure = false
				result.ReviewRequired = true
				result.AuditAction = "INTEGRATION_AUDIT_BUNDLE_FAIL_BLOCKED"
				result.AuditDecisionReason = "bundle contains failed audit event"
				return result, errors.New("bundle contains failed audit event")
			}
		}
	}

	for _, scope := range r.config.RequiredScopes {
		if covered[scope] {
			result.CoveredScopes = append(result.CoveredScopes, scope)
		} else {
			result.MissingScopes = append(result.MissingScopes, scope)
		}
	}

	if len(result.MissingScopes) > 0 {
		result.DecisionStatus = DecisionReviewNeeded
		result.ReadyForClosure = false
		result.ReviewRequired = true
		result.ErrorCode = "REQUIRED_AUDIT_SCOPE_MISSING"
		result.ErrorMessage = "one or more required audit scopes are missing"
		result.AuditAction = "INTEGRATION_AUDIT_BUNDLE_SCOPE_MISSING"
		result.AuditDecisionReason = "required audit scope coverage is incomplete"
		return result, errors.New("one or more required audit scopes are missing")
	}

	if result.TotalPassCount < r.config.MinimumPassCountForReadiness {
		result.DecisionStatus = DecisionReviewNeeded
		result.ReadyForClosure = false
		result.ReviewRequired = true
		result.ErrorCode = "MINIMUM_PASS_COUNT_NOT_MET"
		result.ErrorMessage = "minimum pass count for readiness is not met"
		result.AuditAction = "INTEGRATION_AUDIT_BUNDLE_PASS_COUNT_LOW"
		result.AuditDecisionReason = "audit bundle pass count is below readiness threshold"
		return result, errors.New("minimum pass count for readiness is not met")
	}

	if result.TotalFailCount > 0 && r.config.FailBlocksClosure {
		result.DecisionStatus = DecisionRejected
		result.ReadyForClosure = false
		result.ReviewRequired = true
		result.ErrorCode = "FAIL_COUNT_BLOCKS_CLOSURE"
		result.ErrorMessage = "fail count blocks closure"
		result.AuditAction = "INTEGRATION_AUDIT_BUNDLE_FAIL_COUNT_BLOCKED"
		result.AuditDecisionReason = "audit bundle fail count is greater than zero"
		return result, errors.New("fail count blocks closure")
	}

	result.DecisionStatus = DecisionReady
	result.ReadyForClosure = true
	result.AuditAction = "INTEGRATION_AUDIT_BUNDLE_READY"
	result.AuditDecisionReason = "all required audit scopes are covered and bundle is ready for closure"
	return result, nil
}

func (r *IntegrationAuditRuntime) validateEvent(event IntegrationAuditEvent) error {
	if strings.TrimSpace(event.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(event.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(event.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if r.config.IdempotencyRequired && strings.TrimSpace(event.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if strings.TrimSpace(event.AuditEventID) == "" {
		return errors.New("audit_event_id is required")
	}
	if !r.scopeAllowed(event.Scope) {
		return fmt.Errorf("audit scope is not allowed: %s", event.Scope)
	}
	if strings.TrimSpace(string(event.Source)) == "" {
		return errors.New("audit source is required")
	}
	if strings.TrimSpace(string(event.Status)) == "" {
		return errors.New("audit event status is required")
	}
	if strings.TrimSpace(event.ProviderCode) != "" && !r.providerAllowed(event.ProviderCode) {
		return fmt.Errorf("provider_code is not allowed: %s", event.ProviderCode)
	}
	if strings.TrimSpace(event.CheckName) == "" {
		return errors.New("check_name is required")
	}
	if r.config.ArtifactPathRequired && strings.TrimSpace(event.ArtifactPath) == "" {
		return errors.New("artifact_path is required")
	}
	if strings.TrimSpace(event.EvidenceFilePath) == "" {
		return errors.New("evidence_file_path is required")
	}
	if r.config.EvidenceHashRequired && strings.TrimSpace(event.EvidenceHash) == "" {
		return errors.New("evidence_hash is required")
	}
	if event.PassCount < 0 {
		return errors.New("pass_count cannot be negative")
	}
	if event.FailCount < 0 {
		return errors.New("fail_count cannot be negative")
	}
	if event.WarnCount < 0 {
		return errors.New("warn_count cannot be negative")
	}
	if event.Status == EventStatusPass && event.FailCount > 0 {
		return errors.New("PASS audit event cannot have fail_count greater than zero")
	}
	if event.Status == EventStatusFail && event.FailCount == 0 {
		return errors.New("FAIL audit event must have fail_count greater than zero")
	}
	if event.OccurredAt.IsZero() {
		return errors.New("occurred_at is required")
	}
	return nil
}

func (r *IntegrationAuditRuntime) validateBundle(bundle EvidenceBundle) error {
	if strings.TrimSpace(bundle.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(bundle.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(bundle.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if strings.TrimSpace(bundle.BundleID) == "" {
		return errors.New("bundle_id is required")
	}
	if len(bundle.Events) == 0 {
		return errors.New("audit bundle events are required")
	}
	if bundle.PreparedAt.IsZero() {
		return errors.New("prepared_at is required")
	}
	return nil
}

func (r *IntegrationAuditRuntime) scopeAllowed(scope AuditScope) bool {
	for _, required := range r.config.RequiredScopes {
		if required == scope {
			return true
		}
	}
	return false
}

func (r *IntegrationAuditRuntime) providerAllowed(providerCode string) bool {
	for _, allowed := range r.config.AllowedProviderCodes {
		if allowed == providerCode {
			return true
		}
	}
	return false
}

func rejectedEvent(event IntegrationAuditEvent, code string, message string) IntegrationAuditResult {
	return IntegrationAuditResult{
		TenantID:            event.TenantID,
		CorrelationID:       event.CorrelationID,
		RequestID:           event.RequestID,
		IdempotencyKey:      event.IdempotencyKey,
		AuditEventID:        event.AuditEventID,
		Scope:               event.Scope,
		Source:              event.Source,
		Status:              event.Status,
		DecisionStatus:      DecisionRejected,
		Accepted:            false,
		BlocksClosure:       true,
		ReviewRequired:      true,
		PassCount:           event.PassCount,
		FailCount:           event.FailCount,
		WarnCount:           event.WarnCount,
		AuditAction:         "INTEGRATION_AUDIT_EVENT_REJECTED",
		AuditDecisionReason: "audit event rejected by validation guard",
		ErrorCode:           code,
		ErrorMessage:        message,
		RecordedAt:          time.Now().UTC(),
	}
}

func rejectedBundle(bundle EvidenceBundle, code string, message string) EvidenceBundleResult {
	return EvidenceBundleResult{
		TenantID:            bundle.TenantID,
		CorrelationID:       bundle.CorrelationID,
		RequestID:           bundle.RequestID,
		BundleID:            bundle.BundleID,
		DecisionStatus:      DecisionRejected,
		ReadyForClosure:     false,
		ReviewRequired:      true,
		AuditAction:         "INTEGRATION_AUDIT_BUNDLE_REJECTED",
		AuditDecisionReason: "audit bundle rejected by validation guard",
		ErrorCode:           code,
		ErrorMessage:        message,
		EvaluatedAt:         time.Now().UTC(),
	}
}
