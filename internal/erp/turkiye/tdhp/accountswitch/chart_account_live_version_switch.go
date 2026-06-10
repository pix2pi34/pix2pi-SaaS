package accountswitch

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type ChartVersionStatus string

const (
	ChartVersionDraft      ChartVersionStatus = "DRAFT"
	ChartVersionReady      ChartVersionStatus = "READY"
	ChartVersionCanary     ChartVersionStatus = "CANARY"
	ChartVersionActive     ChartVersionStatus = "ACTIVE"
	ChartVersionSuperseded ChartVersionStatus = "SUPERSEDED"
	ChartVersionRolledBack ChartVersionStatus = "ROLLED_BACK"
	ChartVersionRejected   ChartVersionStatus = "REJECTED"
)

type SwitchStrategy string

const (
	StrategyFull      SwitchStrategy = "FULL"
	StrategyCanary    SwitchStrategy = "CANARY"
	StrategyBlueGreen SwitchStrategy = "BLUE_GREEN"
	StrategyRollback  SwitchStrategy = "ROLLBACK"
)

type DecisionStatus string

const (
	DecisionReady         DecisionStatus = "READY"
	DecisionCanaryStarted DecisionStatus = "CANARY_STARTED"
	DecisionActivated     DecisionStatus = "ACTIVATED"
	DecisionRolledBack    DecisionStatus = "ROLLED_BACK"
	DecisionRejected      DecisionStatus = "REJECTED"
)

type AccountPurpose string

const (
	PurposeReceivable     AccountPurpose = "RECEIVABLE"
	PurposeSales          AccountPurpose = "SALES"
	PurposeOutputKDV      AccountPurpose = "OUTPUT_KDV"
	PurposeInventory      AccountPurpose = "INVENTORY"
	PurposeInputKDV       AccountPurpose = "INPUT_KDV"
	PurposePayable        AccountPurpose = "PAYABLE"
	PurposeBank           AccountPurpose = "BANK"
	PurposeSalesReturn    AccountPurpose = "SALES_RETURN"
	PurposeOpeningBalance AccountPurpose = "OPENING_BALANCE"
	PurposeExpense        AccountPurpose = "EXPENSE"
	PurposeCustom         AccountPurpose = "CUSTOM"
)

type RuntimeConfig struct {
	RuntimeEnabled             bool             `json:"runtime_enabled"`
	DefaultCountryCode         string           `json:"default_country_code"`
	DefaultCurrencyCode        string           `json:"default_currency_code"`
	ApprovalRequired           bool             `json:"approval_required"`
	EvidenceRequired           bool             `json:"evidence_required"`
	IdempotencyRequired        bool             `json:"idempotency_required"`
	CanaryAllowed              bool             `json:"canary_allowed"`
	RollbackAllowed            bool             `json:"rollback_allowed"`
	MinCanaryPercent           int              `json:"min_canary_percent"`
	MaxCanaryPercent           int              `json:"max_canary_percent"`
	RequiredEvidenceFileSuffix string           `json:"required_evidence_file_suffix"`
	AllowedStrategies          []SwitchStrategy `json:"allowed_strategies"`
	RequiredPurposes           []AccountPurpose `json:"required_purposes"`
}

type ChartAccountRule struct {
	Purpose        AccountPurpose `json:"purpose"`
	AccountCode    string         `json:"account_code"`
	AccountName    string         `json:"account_name"`
	RequiredPrefix string         `json:"required_prefix"`
	Active         bool           `json:"active"`
}

type ChartVersion struct {
	VersionID       string             `json:"version_id"`
	VersionCode     string             `json:"version_code"`
	PreviousVersion string             `json:"previous_version"`
	Status          ChartVersionStatus `json:"status"`
	CountryCode     string             `json:"country_code"`
	CurrencyCode    string             `json:"currency_code"`
	LegalReference  string             `json:"legal_reference"`

	ChartArtifactPath   string `json:"chart_artifact_path"`
	MappingArtifactPath string `json:"mapping_artifact_path"`
	ConfigArtifactPath  string `json:"config_artifact_path"`
	EvidenceFilePath    string `json:"evidence_file_path"`
	EvidenceHash        string `json:"evidence_hash"`

	Rules []ChartAccountRule `json:"rules"`

	EffectiveFrom time.Time `json:"effective_from"`
	EffectiveTo   time.Time `json:"effective_to"`

	ApprovedBy string    `json:"approved_by"`
	ApprovedAt time.Time `json:"approved_at"`
	CreatedAt  time.Time `json:"created_at"`
}

type SwitchRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	SwitchID string         `json:"switch_id"`
	Strategy SwitchStrategy `json:"strategy"`

	CurrentVersion ChartVersion `json:"current_version"`
	TargetVersion  ChartVersion `json:"target_version"`

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

	ActiveVersion   ChartVersion `json:"active_version"`
	RollbackVersion ChartVersion `json:"rollback_version"`

	ReasonCode string `json:"reason_code"`
	ReasonText string `json:"reason_text"`

	RequestedBy string    `json:"requested_by"`
	RequestedAt time.Time `json:"requested_at"`
}

type SwitchResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	SwitchID string         `json:"switch_id"`
	Strategy SwitchStrategy `json:"strategy"`

	PreviousVersionCode string             `json:"previous_version_code"`
	TargetVersionCode   string             `json:"target_version_code"`
	TargetStatus        ChartVersionStatus `json:"target_status"`

	DecisionStatus DecisionStatus `json:"decision_status"`

	CanaryPercent   int      `json:"canary_percent"`
	TenantAllowlist []string `json:"tenant_allowlist"`

	RuntimeSwitchReady bool `json:"runtime_switch_ready"`
	ConfigSwitchReady  bool `json:"config_switch_ready"`
	MappingReady       bool `json:"mapping_ready"`
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

	ActiveVersionCode      string             `json:"active_version_code"`
	RollbackVersionCode    string             `json:"rollback_version_code"`
	ActiveVersionNewStatus ChartVersionStatus `json:"active_version_new_status"`
	RollbackVersionStatus  ChartVersionStatus `json:"rollback_version_status"`

	DecisionStatus DecisionStatus `json:"decision_status"`

	RuntimeSwitchReady bool `json:"runtime_switch_ready"`
	ConfigSwitchReady  bool `json:"config_switch_ready"`
	MappingReady       bool `json:"mapping_ready"`
	AuditReady         bool `json:"audit_ready"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	DecidedAt           time.Time `json:"decided_at"`
}

type ResolveRequest struct {
	TenantID        string         `json:"tenant_id"`
	VersionCode     string         `json:"version_code"`
	Purpose         AccountPurpose `json:"purpose"`
	DocumentContext string         `json:"document_context"`
	RequestedAt     time.Time      `json:"requested_at"`
}

type ResolveResult struct {
	TenantID        string         `json:"tenant_id"`
	VersionCode     string         `json:"version_code"`
	Purpose         AccountPurpose `json:"purpose"`
	AccountCode     string         `json:"account_code"`
	AccountName     string         `json:"account_name"`
	DocumentContext string         `json:"document_context"`
	Resolved        bool           `json:"resolved"`
	ResolvedAt      time.Time      `json:"resolved_at"`
}

type ChartAccountLiveSwitchRuntime struct {
	config RuntimeConfig
}

func NewChartAccountLiveSwitchRuntime(config RuntimeConfig) (*ChartAccountLiveSwitchRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("chart account live version switch runtime is disabled")
	}
	if strings.TrimSpace(config.DefaultCountryCode) == "" {
		return nil, errors.New("default_country_code is required")
	}
	if strings.TrimSpace(config.DefaultCurrencyCode) == "" {
		return nil, errors.New("default_currency_code is required")
	}
	if config.MinCanaryPercent < 0 {
		return nil, errors.New("min_canary_percent cannot be negative")
	}
	if config.MaxCanaryPercent < config.MinCanaryPercent {
		return nil, errors.New("max_canary_percent must be greater than or equal to min_canary_percent")
	}
	if strings.TrimSpace(config.RequiredEvidenceFileSuffix) == "" {
		return nil, errors.New("required_evidence_file_suffix is required")
	}
	if len(config.AllowedStrategies) == 0 {
		return nil, errors.New("allowed_strategies are required")
	}
	if len(config.RequiredPurposes) == 0 {
		return nil, errors.New("required_purposes are required")
	}

	return &ChartAccountLiveSwitchRuntime{config: config}, nil
}

func (r *ChartAccountLiveSwitchRuntime) PrepareSwitch(req SwitchRequest) (SwitchResult, error) {
	if err := r.validateSwitchRequest(req); err != nil {
		return rejectedSwitch(req, "VALIDATION_FAILED", err.Error()), err
	}

	switch req.Strategy {
	case StrategyCanary:
		if !r.config.CanaryAllowed {
			return rejectedSwitch(req, "CANARY_SWITCH_DISABLED", "canary switch is disabled"), errors.New("canary switch is disabled")
		}
		if req.CanaryPercent < r.config.MinCanaryPercent || req.CanaryPercent > r.config.MaxCanaryPercent {
			return rejectedSwitch(req, "CANARY_PERCENT_OUT_OF_RANGE", "canary_percent is out of allowed range"), errors.New("canary_percent is out of allowed range")
		}
		if len(req.TenantAllowlist) == 0 {
			return rejectedSwitch(req, "CANARY_TENANT_ALLOWLIST_REQUIRED", "tenant allowlist is required for canary switch"), errors.New("tenant allowlist is required for canary switch")
		}

		return r.switchResult(req, DecisionCanaryStarted, ChartVersionCanary, "CHART_ACCOUNT_VERSION_CANARY_STARTED", "target chart version canary switch started"), nil

	case StrategyFull, StrategyBlueGreen:
		return r.switchResult(req, DecisionReady, ChartVersionReady, "CHART_ACCOUNT_VERSION_SWITCH_READY", "target chart version validated and ready for activation"), nil

	default:
		return rejectedSwitch(req, "SWITCH_STRATEGY_UNSUPPORTED", "switch strategy is unsupported for prepare switch"), errors.New("switch strategy is unsupported for prepare switch")
	}
}

func (r *ChartAccountLiveSwitchRuntime) ActivateSwitch(req SwitchRequest) (SwitchResult, error) {
	if err := r.validateSwitchRequest(req); err != nil {
		return rejectedSwitch(req, "VALIDATION_FAILED", err.Error()), err
	}
	if req.Strategy == StrategyRollback {
		return rejectedSwitch(req, "ACTIVATE_ROLLBACK_STRATEGY_INVALID", "activate switch cannot use rollback strategy"), errors.New("activate switch cannot use rollback strategy")
	}
	if req.CurrentVersion.Status != ChartVersionActive {
		return rejectedSwitch(req, "CURRENT_VERSION_NOT_ACTIVE", "current chart version must be ACTIVE before activation"), errors.New("current chart version must be ACTIVE before activation")
	}
	if req.TargetVersion.Status != ChartVersionReady && req.TargetVersion.Status != ChartVersionCanary {
		return rejectedSwitch(req, "TARGET_VERSION_NOT_READY", "target chart version must be READY or CANARY before activation"), errors.New("target chart version must be READY or CANARY before activation")
	}

	return r.switchResult(req, DecisionActivated, ChartVersionActive, "CHART_ACCOUNT_VERSION_ACTIVATED", "target chart version activated and previous version superseded"), nil
}

func (r *ChartAccountLiveSwitchRuntime) RollbackSwitch(req RollbackRequest) (RollbackResult, error) {
	if !r.config.RollbackAllowed {
		return rejectedRollback(req, "ROLLBACK_DISABLED", "chart account version rollback is disabled"), errors.New("chart account version rollback is disabled")
	}
	if err := r.validateRollbackRequest(req); err != nil {
		return rejectedRollback(req, "VALIDATION_FAILED", err.Error()), err
	}
	if req.ActiveVersion.Status != ChartVersionActive {
		return rejectedRollback(req, "ACTIVE_VERSION_NOT_ACTIVE", "active chart version must be ACTIVE before rollback"), errors.New("active chart version must be ACTIVE before rollback")
	}
	if req.RollbackVersion.Status != ChartVersionSuperseded && req.RollbackVersion.Status != ChartVersionReady {
		return rejectedRollback(req, "ROLLBACK_VERSION_NOT_ELIGIBLE", "rollback chart version must be SUPERSEDED or READY"), errors.New("rollback chart version must be SUPERSEDED or READY")
	}

	return RollbackResult{
		TenantID:               req.TenantID,
		CorrelationID:          req.CorrelationID,
		RequestID:              req.RequestID,
		IdempotencyKey:         req.IdempotencyKey,
		RollbackID:             req.RollbackID,
		ActiveVersionCode:      req.ActiveVersion.VersionCode,
		RollbackVersionCode:    req.RollbackVersion.VersionCode,
		ActiveVersionNewStatus: ChartVersionRolledBack,
		RollbackVersionStatus:  ChartVersionActive,
		DecisionStatus:         DecisionRolledBack,
		RuntimeSwitchReady:     true,
		ConfigSwitchReady:      true,
		MappingReady:           true,
		AuditReady:             true,
		AuditAction:            "CHART_ACCOUNT_VERSION_ROLLED_BACK",
		AuditDecisionReason:    "chart account version rollback validated and ready to apply",
		DecidedAt:              time.Now().UTC(),
	}, nil
}

func (r *ChartAccountLiveSwitchRuntime) ResolveAccount(version ChartVersion, req ResolveRequest) (ResolveResult, error) {
	if strings.TrimSpace(req.TenantID) == "" {
		return ResolveResult{}, errors.New("tenant_id is required")
	}
	if strings.TrimSpace(req.VersionCode) == "" {
		return ResolveResult{}, errors.New("version_code is required")
	}
	if req.VersionCode != version.VersionCode {
		return ResolveResult{}, errors.New("version_code mismatch")
	}
	if strings.TrimSpace(string(req.Purpose)) == "" {
		return ResolveResult{}, errors.New("purpose is required")
	}
	if req.RequestedAt.IsZero() {
		return ResolveResult{}, errors.New("requested_at is required")
	}
	if err := r.validateVersion(version, "resolve"); err != nil {
		return ResolveResult{}, err
	}

	for _, rule := range version.Rules {
		if rule.Purpose == req.Purpose && rule.Active {
			return ResolveResult{
				TenantID:        req.TenantID,
				VersionCode:     req.VersionCode,
				Purpose:         req.Purpose,
				AccountCode:     rule.AccountCode,
				AccountName:     rule.AccountName,
				DocumentContext: req.DocumentContext,
				Resolved:        true,
				ResolvedAt:      time.Now().UTC(),
			}, nil
		}
	}

	return ResolveResult{
		TenantID:        req.TenantID,
		VersionCode:     req.VersionCode,
		Purpose:         req.Purpose,
		DocumentContext: req.DocumentContext,
		Resolved:        false,
		ResolvedAt:      time.Now().UTC(),
	}, errors.New("account purpose could not be resolved")
}

func (r *ChartAccountLiveSwitchRuntime) validateSwitchRequest(req SwitchRequest) error {
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
	if strings.TrimSpace(req.SwitchID) == "" {
		return errors.New("switch_id is required")
	}
	if !r.strategyAllowed(req.Strategy) {
		return fmt.Errorf("switch strategy is not allowed: %s", req.Strategy)
	}
	if err := r.validateVersion(req.CurrentVersion, "current"); err != nil {
		return err
	}
	if err := r.validateVersion(req.TargetVersion, "target"); err != nil {
		return err
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

func (r *ChartAccountLiveSwitchRuntime) validateRollbackRequest(req RollbackRequest) error {
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

func (r *ChartAccountLiveSwitchRuntime) validateVersion(version ChartVersion, label string) error {
	if strings.TrimSpace(version.VersionID) == "" {
		return fmt.Errorf("%s version_id is required", label)
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
	if version.CurrencyCode != r.config.DefaultCurrencyCode {
		return fmt.Errorf("%s currency_code mismatch", label)
	}
	if r.config.ApprovalRequired {
		if strings.TrimSpace(version.LegalReference) == "" {
			return fmt.Errorf("%s legal_reference is required", label)
		}
		if strings.TrimSpace(version.ApprovedBy) == "" {
			return fmt.Errorf("%s approved_by is required", label)
		}
		if version.ApprovedAt.IsZero() {
			return fmt.Errorf("%s approved_at is required", label)
		}
	}
	if strings.TrimSpace(version.ChartArtifactPath) == "" {
		return fmt.Errorf("%s chart_artifact_path is required", label)
	}
	if strings.TrimSpace(version.MappingArtifactPath) == "" {
		return fmt.Errorf("%s mapping_artifact_path is required", label)
	}
	if strings.TrimSpace(version.ConfigArtifactPath) == "" {
		return fmt.Errorf("%s config_artifact_path is required", label)
	}
	if r.config.EvidenceRequired {
		if strings.TrimSpace(version.EvidenceFilePath) == "" {
			return fmt.Errorf("%s evidence_file_path is required", label)
		}
		if !strings.HasSuffix(version.EvidenceFilePath, r.config.RequiredEvidenceFileSuffix) {
			return fmt.Errorf("%s evidence_file_path must end with %s", label, r.config.RequiredEvidenceFileSuffix)
		}
		if strings.TrimSpace(version.EvidenceHash) == "" {
			return fmt.Errorf("%s evidence_hash is required", label)
		}
	}
	if version.EffectiveFrom.IsZero() {
		return fmt.Errorf("%s effective_from is required", label)
	}
	if version.CreatedAt.IsZero() {
		return fmt.Errorf("%s created_at is required", label)
	}
	if err := r.validateRules(version.Rules); err != nil {
		return fmt.Errorf("%s %w", label, err)
	}
	return nil
}

func (r *ChartAccountLiveSwitchRuntime) validateRules(rules []ChartAccountRule) error {
	if len(rules) == 0 {
		return errors.New("rules are required")
	}

	seen := make(map[AccountPurpose]bool)
	for _, rule := range rules {
		if strings.TrimSpace(string(rule.Purpose)) == "" {
			return errors.New("rule purpose is required")
		}
		if strings.TrimSpace(rule.AccountCode) == "" {
			return errors.New("rule account_code is required")
		}
		if strings.TrimSpace(rule.AccountName) == "" {
			return errors.New("rule account_name is required")
		}
		if strings.TrimSpace(rule.RequiredPrefix) == "" {
			return errors.New("rule required_prefix is required")
		}
		if !strings.HasPrefix(rule.AccountCode, rule.RequiredPrefix) {
			return fmt.Errorf("account_code %s must start with required_prefix %s", rule.AccountCode, rule.RequiredPrefix)
		}
		if rule.Active {
			seen[rule.Purpose] = true
		}
	}

	for _, required := range r.config.RequiredPurposes {
		if !seen[required] {
			return fmt.Errorf("required account purpose missing: %s", required)
		}
	}

	return nil
}

func (r *ChartAccountLiveSwitchRuntime) switchResult(req SwitchRequest, decision DecisionStatus, targetStatus ChartVersionStatus, action string, reason string) SwitchResult {
	return SwitchResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		SwitchID:            req.SwitchID,
		Strategy:            req.Strategy,
		PreviousVersionCode: req.CurrentVersion.VersionCode,
		TargetVersionCode:   req.TargetVersion.VersionCode,
		TargetStatus:        targetStatus,
		DecisionStatus:      decision,
		CanaryPercent:       req.CanaryPercent,
		TenantAllowlist:     req.TenantAllowlist,
		RuntimeSwitchReady:  true,
		ConfigSwitchReady:   true,
		MappingReady:        true,
		AuditReady:          true,
		RollbackReady:       r.config.RollbackAllowed,
		AuditAction:         action,
		AuditDecisionReason: reason,
		DecidedAt:           time.Now().UTC(),
	}
}

func (r *ChartAccountLiveSwitchRuntime) strategyAllowed(strategy SwitchStrategy) bool {
	for _, allowed := range r.config.AllowedStrategies {
		if allowed == strategy {
			return true
		}
	}
	return false
}

func rejectedSwitch(req SwitchRequest, code string, message string) SwitchResult {
	return SwitchResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		SwitchID:            req.SwitchID,
		Strategy:            req.Strategy,
		PreviousVersionCode: req.CurrentVersion.VersionCode,
		TargetVersionCode:   req.TargetVersion.VersionCode,
		TargetStatus:        ChartVersionRejected,
		DecisionStatus:      DecisionRejected,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "CHART_ACCOUNT_VERSION_SWITCH_REJECTED",
		AuditDecisionReason: "chart account version switch rejected by validation guard",
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
		ActiveVersionCode:      req.ActiveVersion.VersionCode,
		RollbackVersionCode:    req.RollbackVersion.VersionCode,
		ActiveVersionNewStatus: ChartVersionRejected,
		RollbackVersionStatus:  ChartVersionRejected,
		DecisionStatus:         DecisionRejected,
		ErrorCode:              code,
		ErrorMessage:           message,
		AuditAction:            "CHART_ACCOUNT_VERSION_ROLLBACK_REJECTED",
		AuditDecisionReason:    "chart account version rollback rejected by validation guard",
		DecidedAt:              time.Now().UTC(),
	}
}
