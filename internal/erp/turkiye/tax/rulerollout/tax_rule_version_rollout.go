package rulerollout

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type TaxFamily string

const (
	TaxFamilyKDV          TaxFamily = "KDV"
	TaxFamilyStopaj       TaxFamily = "STOPAJ"
	TaxFamilyTaxExemption TaxFamily = "TAX_EXEMPTION"
	TaxFamilyOTV          TaxFamily = "OTV"
	TaxFamilyDamga        TaxFamily = "DAMGA"
	TaxFamilyCustom       TaxFamily = "CUSTOM"
)

type RolloutStrategy string

const (
	StrategyFull      RolloutStrategy = "FULL"
	StrategyCanary    RolloutStrategy = "CANARY"
	StrategyBlueGreen RolloutStrategy = "BLUE_GREEN"
	StrategyRollback  RolloutStrategy = "ROLLBACK"
)

type VersionStatus string

const (
	VersionStatusDraft      VersionStatus = "DRAFT"
	VersionStatusReady      VersionStatus = "READY"
	VersionStatusCanary     VersionStatus = "CANARY"
	VersionStatusActive     VersionStatus = "ACTIVE"
	VersionStatusSuperseded VersionStatus = "SUPERSEDED"
	VersionStatusRolledBack VersionStatus = "ROLLED_BACK"
	VersionStatusRejected   VersionStatus = "REJECTED"
)

type DecisionStatus string

const (
	DecisionReady         DecisionStatus = "READY"
	DecisionCanaryStarted DecisionStatus = "CANARY_STARTED"
	DecisionActivated     DecisionStatus = "ACTIVATED"
	DecisionRolledBack    DecisionStatus = "ROLLED_BACK"
	DecisionRejected      DecisionStatus = "REJECTED"
)

type RuntimeConfig struct {
	RuntimeEnabled             bool              `json:"runtime_enabled"`
	DefaultCountryCode         string            `json:"default_country_code"`
	ApprovalRequired           bool              `json:"approval_required"`
	LegalReferenceRequired     bool              `json:"legal_reference_required"`
	AuditRequired              bool              `json:"audit_required"`
	IdempotencyRequired        bool              `json:"idempotency_required"`
	CanaryAllowed              bool              `json:"canary_allowed"`
	RollbackAllowed            bool              `json:"rollback_allowed"`
	MinCanaryPercent           int               `json:"min_canary_percent"`
	MaxCanaryPercent           int               `json:"max_canary_percent"`
	AllowedTaxFamilies         []TaxFamily       `json:"allowed_tax_families"`
	AllowedRolloutStrategies   []RolloutStrategy `json:"allowed_rollout_strategies"`
	RequiredEvidenceFileSuffix string            `json:"required_evidence_file_suffix"`
}

type TaxRuleVersion struct {
	VersionID           string        `json:"version_id"`
	TaxFamily           TaxFamily     `json:"tax_family"`
	VersionCode         string        `json:"version_code"`
	PreviousVersionCode string        `json:"previous_version_code"`
	Status              VersionStatus `json:"status"`
	CountryCode         string        `json:"country_code"`
	LegalReference      string        `json:"legal_reference"`
	RuleArtifactPath    string        `json:"rule_artifact_path"`
	ConfigArtifactPath  string        `json:"config_artifact_path"`
	EvidenceFilePath    string        `json:"evidence_file_path"`
	EvidenceHash        string        `json:"evidence_hash"`
	EffectiveFrom       time.Time     `json:"effective_from"`
	EffectiveTo         time.Time     `json:"effective_to"`
	ApprovedBy          string        `json:"approved_by"`
	ApprovedAt          time.Time     `json:"approved_at"`
	CreatedAt           time.Time     `json:"created_at"`
}

type RolloutRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	RolloutID string          `json:"rollout_id"`
	Strategy  RolloutStrategy `json:"strategy"`

	CurrentVersion TaxRuleVersion `json:"current_version"`
	TargetVersion  TaxRuleVersion `json:"target_version"`

	CanaryPercent   int      `json:"canary_percent"`
	TenantAllowlist []string `json:"tenant_allowlist"`

	RequestedBy string    `json:"requested_by"`
	RequestedAt time.Time `json:"requested_at"`
}

type RollbackRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	RollbackID string `json:"rollback_id"`

	ActiveVersion   TaxRuleVersion `json:"active_version"`
	RollbackVersion TaxRuleVersion `json:"rollback_version"`

	ReasonCode string `json:"reason_code"`
	ReasonText string `json:"reason_text"`

	RequestedBy string    `json:"requested_by"`
	RequestedAt time.Time `json:"requested_at"`
}

type RolloutResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	RolloutID string          `json:"rollout_id"`
	Strategy  RolloutStrategy `json:"strategy"`

	TaxFamily           TaxFamily     `json:"tax_family"`
	PreviousVersionCode string        `json:"previous_version_code"`
	TargetVersionCode   string        `json:"target_version_code"`
	TargetStatus        VersionStatus `json:"target_status"`

	DecisionStatus DecisionStatus `json:"decision_status"`

	CanaryPercent   int      `json:"canary_percent"`
	TenantAllowlist []string `json:"tenant_allowlist"`

	RuntimeSwitchReady bool `json:"runtime_switch_ready"`
	ConfigSwitchReady  bool `json:"config_switch_ready"`
	AuditReady         bool `json:"audit_ready"`
	RollbackReady      bool `json:"rollback_ready"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	DecidedAt           time.Time `json:"decided_at"`
}

type RollbackResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	RollbackID string `json:"rollback_id"`

	TaxFamily              TaxFamily     `json:"tax_family"`
	ActiveVersionCode      string        `json:"active_version_code"`
	RollbackVersionCode    string        `json:"rollback_version_code"`
	ActiveVersionNewStatus VersionStatus `json:"active_version_new_status"`
	RollbackVersionStatus  VersionStatus `json:"rollback_version_status"`

	DecisionStatus DecisionStatus `json:"decision_status"`

	RuntimeSwitchReady bool `json:"runtime_switch_ready"`
	ConfigSwitchReady  bool `json:"config_switch_ready"`
	AuditReady         bool `json:"audit_ready"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	DecidedAt           time.Time `json:"decided_at"`
}

type TaxRuleVersionRolloutRuntime struct {
	config RuntimeConfig
}

func NewTaxRuleVersionRolloutRuntime(config RuntimeConfig) (*TaxRuleVersionRolloutRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("tax rule version rollout runtime is disabled")
	}
	if strings.TrimSpace(config.DefaultCountryCode) == "" {
		return nil, errors.New("default_country_code is required")
	}
	if config.MinCanaryPercent < 0 {
		return nil, errors.New("min_canary_percent cannot be negative")
	}
	if config.MaxCanaryPercent < config.MinCanaryPercent {
		return nil, errors.New("max_canary_percent must be greater than or equal to min_canary_percent")
	}
	if len(config.AllowedTaxFamilies) == 0 {
		return nil, errors.New("allowed_tax_families are required")
	}
	if len(config.AllowedRolloutStrategies) == 0 {
		return nil, errors.New("allowed_rollout_strategies are required")
	}
	if strings.TrimSpace(config.RequiredEvidenceFileSuffix) == "" {
		return nil, errors.New("required_evidence_file_suffix is required")
	}

	return &TaxRuleVersionRolloutRuntime{config: config}, nil
}

func (r *TaxRuleVersionRolloutRuntime) PrepareRollout(req RolloutRequest) (RolloutResult, error) {
	if err := r.validateRolloutRequest(req); err != nil {
		return rejectedRollout(req, "VALIDATION_FAILED", err.Error()), err
	}

	switch req.Strategy {
	case StrategyCanary:
		if !r.config.CanaryAllowed {
			return rejectedRollout(req, "CANARY_ROLLOUT_DISABLED", "canary rollout is disabled"), errors.New("canary rollout is disabled")
		}
		if req.CanaryPercent < r.config.MinCanaryPercent || req.CanaryPercent > r.config.MaxCanaryPercent {
			return rejectedRollout(req, "CANARY_PERCENT_OUT_OF_RANGE", "canary_percent is out of allowed range"), errors.New("canary_percent is out of allowed range")
		}
		if len(req.TenantAllowlist) == 0 {
			return rejectedRollout(req, "CANARY_TENANT_ALLOWLIST_REQUIRED", "tenant allowlist is required for canary rollout"), errors.New("tenant allowlist is required for canary rollout")
		}

		return r.rolloutResult(req, DecisionCanaryStarted, VersionStatusCanary, "TAX_RULE_VERSION_CANARY_STARTED", "target tax rule version canary rollout started"), nil

	case StrategyFull, StrategyBlueGreen:
		return r.rolloutResult(req, DecisionReady, VersionStatusReady, "TAX_RULE_VERSION_ROLLOUT_READY", "target tax rule version validated and ready for activation"), nil

	default:
		return rejectedRollout(req, "ROLLOUT_STRATEGY_UNSUPPORTED", "rollout strategy is unsupported for prepare rollout"), errors.New("rollout strategy is unsupported for prepare rollout")
	}
}

func (r *TaxRuleVersionRolloutRuntime) ActivateVersion(req RolloutRequest) (RolloutResult, error) {
	if err := r.validateRolloutRequest(req); err != nil {
		return rejectedRollout(req, "VALIDATION_FAILED", err.Error()), err
	}
	if req.Strategy == StrategyRollback {
		return rejectedRollout(req, "ACTIVATE_ROLLBACK_STRATEGY_INVALID", "activate version cannot use rollback strategy"), errors.New("activate version cannot use rollback strategy")
	}
	if req.CurrentVersion.Status != VersionStatusActive {
		return rejectedRollout(req, "CURRENT_VERSION_NOT_ACTIVE", "current version must be ACTIVE before activation"), errors.New("current version must be ACTIVE before activation")
	}
	if req.TargetVersion.Status != VersionStatusReady && req.TargetVersion.Status != VersionStatusCanary {
		return rejectedRollout(req, "TARGET_VERSION_NOT_READY", "target version must be READY or CANARY before activation"), errors.New("target version must be READY or CANARY before activation")
	}

	return r.rolloutResult(req, DecisionActivated, VersionStatusActive, "TAX_RULE_VERSION_ACTIVATED", "target tax rule version activated and previous version superseded"), nil
}

func (r *TaxRuleVersionRolloutRuntime) RollbackVersion(req RollbackRequest) (RollbackResult, error) {
	if !r.config.RollbackAllowed {
		return rejectedRollback(req, "ROLLBACK_DISABLED", "tax rule version rollback is disabled"), errors.New("tax rule version rollback is disabled")
	}
	if err := r.validateRollbackRequest(req); err != nil {
		return rejectedRollback(req, "VALIDATION_FAILED", err.Error()), err
	}
	if req.ActiveVersion.Status != VersionStatusActive {
		return rejectedRollback(req, "ACTIVE_VERSION_NOT_ACTIVE", "active version must be ACTIVE before rollback"), errors.New("active version must be ACTIVE before rollback")
	}
	if req.RollbackVersion.Status != VersionStatusSuperseded && req.RollbackVersion.Status != VersionStatusReady {
		return rejectedRollback(req, "ROLLBACK_VERSION_NOT_ELIGIBLE", "rollback version must be SUPERSEDED or READY"), errors.New("rollback version must be SUPERSEDED or READY")
	}
	if req.ActiveVersion.TaxFamily != req.RollbackVersion.TaxFamily {
		return rejectedRollback(req, "ROLLBACK_TAX_FAMILY_MISMATCH", "active and rollback versions must belong to the same tax family"), errors.New("active and rollback versions must belong to the same tax family")
	}

	return RollbackResult{
		TenantID:               req.TenantID,
		CorrelationID:          req.CorrelationID,
		RequestID:              req.RequestID,
		IdempotencyKey:         req.IdempotencyKey,
		RollbackID:             req.RollbackID,
		TaxFamily:              req.ActiveVersion.TaxFamily,
		ActiveVersionCode:      req.ActiveVersion.VersionCode,
		RollbackVersionCode:    req.RollbackVersion.VersionCode,
		ActiveVersionNewStatus: VersionStatusRolledBack,
		RollbackVersionStatus:  VersionStatusActive,
		DecisionStatus:         DecisionRolledBack,
		RuntimeSwitchReady:     true,
		ConfigSwitchReady:      true,
		AuditReady:             true,
		AuditAction:            "TAX_RULE_VERSION_ROLLED_BACK",
		AuditDecisionReason:    "tax rule version rollback validated and ready to apply",
		DecidedAt:              time.Now().UTC(),
	}, nil
}

func (r *TaxRuleVersionRolloutRuntime) validateRolloutRequest(req RolloutRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(req.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if r.config.IdempotencyRequired && strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if strings.TrimSpace(req.RolloutID) == "" {
		return errors.New("rollout_id is required")
	}
	if !r.rolloutStrategyAllowed(req.Strategy) {
		return fmt.Errorf("rollout strategy is not allowed: %s", req.Strategy)
	}
	if err := r.validateVersion(req.CurrentVersion, "current"); err != nil {
		return err
	}
	if err := r.validateVersion(req.TargetVersion, "target"); err != nil {
		return err
	}
	if req.CurrentVersion.TaxFamily != req.TargetVersion.TaxFamily {
		return errors.New("current and target versions must belong to the same tax family")
	}
	if req.CurrentVersion.VersionCode == req.TargetVersion.VersionCode {
		return errors.New("current and target version codes must be different")
	}
	if strings.TrimSpace(req.RequestedBy) == "" {
		return errors.New("requested_by is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *TaxRuleVersionRolloutRuntime) validateRollbackRequest(req RollbackRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(req.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if r.config.IdempotencyRequired && strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if strings.TrimSpace(req.RollbackID) == "" {
		return errors.New("rollback_id is required")
	}
	if err := r.validateVersion(req.ActiveVersion, "active"); err != nil {
		return err
	}
	if err := r.validateVersion(req.RollbackVersion, "rollback"); err != nil {
		return err
	}
	if strings.TrimSpace(req.ReasonCode) == "" {
		return errors.New("reason_code is required")
	}
	if strings.TrimSpace(req.ReasonText) == "" {
		return errors.New("reason_text is required")
	}
	if strings.TrimSpace(req.RequestedBy) == "" {
		return errors.New("requested_by is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *TaxRuleVersionRolloutRuntime) validateVersion(version TaxRuleVersion, label string) error {
	if strings.TrimSpace(version.VersionID) == "" {
		return fmt.Errorf("%s version_id is required", label)
	}
	if !r.taxFamilyAllowed(version.TaxFamily) {
		return fmt.Errorf("%s tax_family is not allowed: %s", label, version.TaxFamily)
	}
	if strings.TrimSpace(version.VersionCode) == "" {
		return fmt.Errorf("%s version_code is required", label)
	}
	if strings.TrimSpace(string(version.Status)) == "" {
		return fmt.Errorf("%s status is required", label)
	}
	if version.CountryCode != r.config.DefaultCountryCode {
		return fmt.Errorf("%s country_code mismatch", label)
	}
	if r.config.LegalReferenceRequired && strings.TrimSpace(version.LegalReference) == "" {
		return fmt.Errorf("%s legal_reference is required", label)
	}
	if strings.TrimSpace(version.RuleArtifactPath) == "" {
		return fmt.Errorf("%s rule_artifact_path is required", label)
	}
	if strings.TrimSpace(version.ConfigArtifactPath) == "" {
		return fmt.Errorf("%s config_artifact_path is required", label)
	}
	if strings.TrimSpace(version.EvidenceFilePath) == "" {
		return fmt.Errorf("%s evidence_file_path is required", label)
	}
	if !strings.HasSuffix(version.EvidenceFilePath, r.config.RequiredEvidenceFileSuffix) {
		return fmt.Errorf("%s evidence_file_path must end with %s", label, r.config.RequiredEvidenceFileSuffix)
	}
	if strings.TrimSpace(version.EvidenceHash) == "" {
		return fmt.Errorf("%s evidence_hash is required", label)
	}
	if version.EffectiveFrom.IsZero() {
		return fmt.Errorf("%s effective_from is required", label)
	}
	if r.config.ApprovalRequired {
		if strings.TrimSpace(version.ApprovedBy) == "" {
			return fmt.Errorf("%s approved_by is required", label)
		}
		if version.ApprovedAt.IsZero() {
			return fmt.Errorf("%s approved_at is required", label)
		}
	}
	if version.CreatedAt.IsZero() {
		return fmt.Errorf("%s created_at is required", label)
	}
	return nil
}

func (r *TaxRuleVersionRolloutRuntime) rolloutResult(req RolloutRequest, decision DecisionStatus, targetStatus VersionStatus, action string, reason string) RolloutResult {
	return RolloutResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		RolloutID:           req.RolloutID,
		Strategy:            req.Strategy,
		TaxFamily:           req.TargetVersion.TaxFamily,
		PreviousVersionCode: req.CurrentVersion.VersionCode,
		TargetVersionCode:   req.TargetVersion.VersionCode,
		TargetStatus:        targetStatus,
		DecisionStatus:      decision,
		CanaryPercent:       req.CanaryPercent,
		TenantAllowlist:     req.TenantAllowlist,
		RuntimeSwitchReady:  true,
		ConfigSwitchReady:   true,
		AuditReady:          true,
		RollbackReady:       r.config.RollbackAllowed,
		AuditAction:         action,
		AuditDecisionReason: reason,
		DecidedAt:           time.Now().UTC(),
	}
}

func (r *TaxRuleVersionRolloutRuntime) taxFamilyAllowed(family TaxFamily) bool {
	for _, allowed := range r.config.AllowedTaxFamilies {
		if allowed == family {
			return true
		}
	}
	return false
}

func (r *TaxRuleVersionRolloutRuntime) rolloutStrategyAllowed(strategy RolloutStrategy) bool {
	for _, allowed := range r.config.AllowedRolloutStrategies {
		if allowed == strategy {
			return true
		}
	}
	return false
}

func rejectedRollout(req RolloutRequest, code string, message string) RolloutResult {
	return RolloutResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		RolloutID:           req.RolloutID,
		Strategy:            req.Strategy,
		TaxFamily:           req.TargetVersion.TaxFamily,
		PreviousVersionCode: req.CurrentVersion.VersionCode,
		TargetVersionCode:   req.TargetVersion.VersionCode,
		TargetStatus:        VersionStatusRejected,
		DecisionStatus:      DecisionRejected,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "TAX_RULE_VERSION_ROLLOUT_REJECTED",
		AuditDecisionReason: "tax rule version rollout rejected by runtime validation guard",
		DecidedAt:           time.Now().UTC(),
	}
}

func rejectedRollback(req RollbackRequest, code string, message string) RollbackResult {
	return RollbackResult{
		TenantID:               req.TenantID,
		CorrelationID:          req.CorrelationID,
		RequestID:              req.RequestID,
		IdempotencyKey:         req.IdempotencyKey,
		RollbackID:             req.RollbackID,
		TaxFamily:              req.ActiveVersion.TaxFamily,
		ActiveVersionCode:      req.ActiveVersion.VersionCode,
		RollbackVersionCode:    req.RollbackVersion.VersionCode,
		ActiveVersionNewStatus: VersionStatusRejected,
		RollbackVersionStatus:  VersionStatusRejected,
		DecisionStatus:         DecisionRejected,
		ErrorCode:              code,
		ErrorMessage:           message,
		AuditAction:            "TAX_RULE_VERSION_ROLLBACK_REJECTED",
		AuditDecisionReason:    "tax rule version rollback rejected by runtime validation guard",
		DecidedAt:              time.Now().UTC(),
	}
}
