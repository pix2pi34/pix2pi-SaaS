package opsconsole

import (
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	EarlyWarningSeverityInfo     = "INFO"
	EarlyWarningSeverityWarning  = "WARNING"
	EarlyWarningSeverityCritical = "CRITICAL"

	EarlyWarningStatusOpen         = "OPEN"
	EarlyWarningStatusAcknowledged = "ACKNOWLEDGED"
	EarlyWarningStatusResolved     = "RESOLVED"
	EarlyWarningStatusSuppressed   = "SUPPRESSED"

	EarlyWarningSourceRuntimeHealth = "RUNTIME_HEALTH"
	EarlyWarningSourceJobQueue      = "JOB_QUEUE"
	EarlyWarningSourceWebhook       = "WEBHOOK"
	EarlyWarningSourceNotification  = "NOTIFICATION"
	EarlyWarningSourceDatabase      = "DATABASE"
	EarlyWarningSourceSecurity      = "SECURITY"
	EarlyWarningSourceEventBus      = "EVENT_BUS"

	EarlyWarningRuleOperatorGreaterThan = "GREATER_THAN"
	EarlyWarningRuleOperatorLessThan    = "LESS_THAN"
	EarlyWarningRuleOperatorEquals      = "EQUALS"

	EarlyWarningDashboardDecisionAllow = "ALLOW"
	EarlyWarningDashboardDecisionDeny  = "DENY"

	EarlyWarningDashboardReasonAllowed           = "EARLY_WARNING_DASHBOARD_ALLOWED"
	EarlyWarningDashboardReasonMissingTenant     = "EARLY_WARNING_DASHBOARD_MISSING_TENANT"
	EarlyWarningDashboardReasonCrossTenant       = "EARLY_WARNING_DASHBOARD_CROSS_TENANT_DENIED"
	EarlyWarningDashboardReasonMissingRuleID     = "EARLY_WARNING_DASHBOARD_MISSING_RULE_ID"
	EarlyWarningDashboardReasonMissingAlertID    = "EARLY_WARNING_DASHBOARD_MISSING_ALERT_ID"
	EarlyWarningDashboardReasonMissingMetric     = "EARLY_WARNING_DASHBOARD_MISSING_METRIC"
	EarlyWarningDashboardReasonMissingSource     = "EARLY_WARNING_DASHBOARD_MISSING_SOURCE"
	EarlyWarningDashboardReasonInvalidSource     = "EARLY_WARNING_DASHBOARD_INVALID_SOURCE"
	EarlyWarningDashboardReasonInvalidSeverity   = "EARLY_WARNING_DASHBOARD_INVALID_SEVERITY"
	EarlyWarningDashboardReasonInvalidStatus     = "EARLY_WARNING_DASHBOARD_INVALID_STATUS"
	EarlyWarningDashboardReasonInvalidOperator   = "EARLY_WARNING_DASHBOARD_INVALID_OPERATOR"
	EarlyWarningDashboardReasonMissingMessage    = "EARLY_WARNING_DASHBOARD_MISSING_MESSAGE"
	EarlyWarningDashboardReasonMissingOperatorID = "EARLY_WARNING_DASHBOARD_MISSING_OPERATOR_ID"
	EarlyWarningDashboardReasonAlertNotFound     = "EARLY_WARNING_DASHBOARD_ALERT_NOT_FOUND"
)

var (
	ErrEarlyWarningDashboardMissingTenant     = errors.New("missing early warning tenant id")
	ErrEarlyWarningDashboardCrossTenant       = errors.New("cross-tenant early warning access denied")
	ErrEarlyWarningDashboardMissingRuleID     = errors.New("missing early warning rule id")
	ErrEarlyWarningDashboardMissingAlertID    = errors.New("missing early warning alert id")
	ErrEarlyWarningDashboardMissingMetric     = errors.New("missing early warning metric")
	ErrEarlyWarningDashboardMissingSource     = errors.New("missing early warning source")
	ErrEarlyWarningDashboardInvalidSource     = errors.New("invalid early warning source")
	ErrEarlyWarningDashboardInvalidSeverity   = errors.New("invalid early warning severity")
	ErrEarlyWarningDashboardInvalidStatus     = errors.New("invalid early warning status")
	ErrEarlyWarningDashboardInvalidOperator   = errors.New("invalid early warning operator")
	ErrEarlyWarningDashboardMissingMessage    = errors.New("missing early warning message")
	ErrEarlyWarningDashboardMissingOperatorID = errors.New("missing early warning operator id")
	ErrEarlyWarningDashboardAlertNotFound     = errors.New("early warning alert not found")
)

type EarlyWarningAlertDashboardConsoleConfig struct {
	RequireTenant       bool     `json:"require_tenant"`
	AllowPlatformViewer bool     `json:"allow_platform_viewer"`
	MaxVisibleRules     int      `json:"max_visible_rules"`
	MaxVisibleAlerts    int      `json:"max_visible_alerts"`
	AllowedSeverities   []string `json:"allowed_severities"`
	AllowedStatuses     []string `json:"allowed_statuses"`
	AllowedSources      []string `json:"allowed_sources"`
	AllowedOperators    []string `json:"allowed_operators"`
}

func DefaultEarlyWarningAlertDashboardConsoleConfig() EarlyWarningAlertDashboardConsoleConfig {
	return EarlyWarningAlertDashboardConsoleConfig{
		RequireTenant:       true,
		AllowPlatformViewer: true,
		MaxVisibleRules:     100,
		MaxVisibleAlerts:    100,
		AllowedSeverities: []string{
			EarlyWarningSeverityInfo,
			EarlyWarningSeverityWarning,
			EarlyWarningSeverityCritical,
		},
		AllowedStatuses: []string{
			EarlyWarningStatusOpen,
			EarlyWarningStatusAcknowledged,
			EarlyWarningStatusResolved,
			EarlyWarningStatusSuppressed,
		},
		AllowedSources: []string{
			EarlyWarningSourceRuntimeHealth,
			EarlyWarningSourceJobQueue,
			EarlyWarningSourceWebhook,
			EarlyWarningSourceNotification,
			EarlyWarningSourceDatabase,
			EarlyWarningSourceSecurity,
			EarlyWarningSourceEventBus,
		},
		AllowedOperators: []string{
			EarlyWarningRuleOperatorGreaterThan,
			EarlyWarningRuleOperatorLessThan,
			EarlyWarningRuleOperatorEquals,
		},
	}
}

type EarlyWarningRuleEntry struct {
	TenantID      string            `json:"tenant_id"`
	RuleID        string            `json:"rule_id"`
	Name          string            `json:"name"`
	Source        string            `json:"source"`
	Metric        string            `json:"metric"`
	Operator      string            `json:"operator"`
	Threshold     float64           `json:"threshold"`
	Severity      string            `json:"severity"`
	Enabled       bool              `json:"enabled"`
	CorrelationID string            `json:"correlation_id,omitempty"`
	Metadata      map[string]string `json:"metadata,omitempty"`
	CreatedAt     string            `json:"created_at"`
	UpdatedAt     string            `json:"updated_at"`
}

type EarlyWarningAlertEntry struct {
	TenantID       string            `json:"tenant_id"`
	AlertID        string            `json:"alert_id"`
	RuleID         string            `json:"rule_id"`
	Source         string            `json:"source"`
	Metric         string            `json:"metric"`
	ObservedValue  float64           `json:"observed_value"`
	Threshold      float64           `json:"threshold"`
	Severity       string            `json:"severity"`
	Status         string            `json:"status"`
	Message        string            `json:"message"`
	OperatorID     string            `json:"operator_id,omitempty"`
	AcknowledgedAt string            `json:"acknowledged_at,omitempty"`
	ResolvedAt     string            `json:"resolved_at,omitempty"`
	CorrelationID  string            `json:"correlation_id,omitempty"`
	Metadata       map[string]string `json:"metadata,omitempty"`
	CreatedAt      string            `json:"created_at"`
	UpdatedAt      string            `json:"updated_at"`
}

type EarlyWarningDashboardRequest struct {
	TenantID        string `json:"tenant_id"`
	ViewerTenantID  string `json:"viewer_tenant_id,omitempty"`
	SourceFilter    string `json:"source_filter,omitempty"`
	SeverityFilter  string `json:"severity_filter,omitempty"`
	StatusFilter    string `json:"status_filter,omitempty"`
	IncludeResolved bool   `json:"include_resolved"`
	IncludeRules    bool   `json:"include_rules"`
	CorrelationID   string `json:"correlation_id,omitempty"`
}

type EarlyWarningDashboardDecision struct {
	Decision       string `json:"decision"`
	Allowed        bool   `json:"allowed"`
	TenantID       string `json:"tenant_id"`
	ViewerTenantID string `json:"viewer_tenant_id,omitempty"`
	SourceFilter   string `json:"source_filter,omitempty"`
	SeverityFilter string `json:"severity_filter,omitempty"`
	StatusFilter   string `json:"status_filter,omitempty"`
	Reason         string `json:"reason"`
	CheckedAt      string `json:"checked_at"`
}

type EarlyWarningDashboardSnapshot struct {
	OK                 bool                     `json:"ok"`
	TenantID           string                   `json:"tenant_id"`
	ViewerTenantID     string                   `json:"viewer_tenant_id"`
	SourceFilter       string                   `json:"source_filter,omitempty"`
	SeverityFilter     string                   `json:"severity_filter,omitempty"`
	StatusFilter       string                   `json:"status_filter,omitempty"`
	RuleCount          int                      `json:"rule_count"`
	AlertCount         int                      `json:"alert_count"`
	OpenCount          int                      `json:"open_count"`
	AcknowledgedCount  int                      `json:"acknowledged_count"`
	ResolvedCount      int                      `json:"resolved_count"`
	SuppressedCount    int                      `json:"suppressed_count"`
	InfoCount          int                      `json:"info_count"`
	WarningCount       int                      `json:"warning_count"`
	CriticalCount      int                      `json:"critical_count"`
	RuntimeHealthCount int                      `json:"runtime_health_count"`
	JobQueueCount      int                      `json:"job_queue_count"`
	WebhookCount       int                      `json:"webhook_count"`
	DatabaseCount      int                      `json:"database_count"`
	SecurityCount      int                      `json:"security_count"`
	EventBusCount      int                      `json:"event_bus_count"`
	Rules              []EarlyWarningRuleEntry  `json:"rules"`
	Alerts             []EarlyWarningAlertEntry `json:"alerts"`
	CorrelationID      string                   `json:"correlation_id,omitempty"`
	GeneratedAt        string                   `json:"generated_at"`
}

type EarlyWarningAlertDashboardConsoleRuntime struct {
	config EarlyWarningAlertDashboardConsoleConfig
	mu     sync.RWMutex
	rules  map[string]EarlyWarningRuleEntry
	alerts map[string]EarlyWarningAlertEntry
}

func NewEarlyWarningAlertDashboardConsoleRuntime(config EarlyWarningAlertDashboardConsoleConfig) *EarlyWarningAlertDashboardConsoleRuntime {
	defaults := DefaultEarlyWarningAlertDashboardConsoleConfig()

	if config.MaxVisibleRules <= 0 {
		config.MaxVisibleRules = defaults.MaxVisibleRules
	}
	if config.MaxVisibleAlerts <= 0 {
		config.MaxVisibleAlerts = defaults.MaxVisibleAlerts
	}
	if len(config.AllowedSeverities) == 0 {
		config.AllowedSeverities = defaults.AllowedSeverities
	}
	if len(config.AllowedStatuses) == 0 {
		config.AllowedStatuses = defaults.AllowedStatuses
	}
	if len(config.AllowedSources) == 0 {
		config.AllowedSources = defaults.AllowedSources
	}
	if len(config.AllowedOperators) == 0 {
		config.AllowedOperators = defaults.AllowedOperators
	}

	return &EarlyWarningAlertDashboardConsoleRuntime{
		config: config,
		rules:  make(map[string]EarlyWarningRuleEntry),
		alerts: make(map[string]EarlyWarningAlertEntry),
	}
}

func (r *EarlyWarningAlertDashboardConsoleRuntime) UpsertRule(entry EarlyWarningRuleEntry) (EarlyWarningRuleEntry, EarlyWarningDashboardDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	entry.TenantID = strings.TrimSpace(entry.TenantID)
	entry.RuleID = strings.TrimSpace(entry.RuleID)
	entry.Name = strings.TrimSpace(entry.Name)
	entry.Source = normalizeOpsConsoleValue(entry.Source)
	entry.Metric = strings.TrimSpace(entry.Metric)
	entry.Operator = normalizeOpsConsoleValue(entry.Operator)
	entry.Severity = normalizeOpsConsoleValue(entry.Severity)

	decision := EarlyWarningDashboardDecision{
		Decision:  EarlyWarningDashboardDecisionDeny,
		Allowed:   false,
		TenantID:  entry.TenantID,
		Reason:    EarlyWarningDashboardReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && entry.TenantID == "" {
		decision.Reason = EarlyWarningDashboardReasonMissingTenant
		return EarlyWarningRuleEntry{}, decision, ErrEarlyWarningDashboardMissingTenant
	}
	if entry.RuleID == "" {
		decision.Reason = EarlyWarningDashboardReasonMissingRuleID
		return EarlyWarningRuleEntry{}, decision, ErrEarlyWarningDashboardMissingRuleID
	}
	if entry.Source == "" {
		decision.Reason = EarlyWarningDashboardReasonMissingSource
		return EarlyWarningRuleEntry{}, decision, ErrEarlyWarningDashboardMissingSource
	}
	if !r.sourceAllowed(entry.Source) {
		decision.Reason = EarlyWarningDashboardReasonInvalidSource
		return EarlyWarningRuleEntry{}, decision, ErrEarlyWarningDashboardInvalidSource
	}
	if entry.Metric == "" {
		decision.Reason = EarlyWarningDashboardReasonMissingMetric
		return EarlyWarningRuleEntry{}, decision, ErrEarlyWarningDashboardMissingMetric
	}
	if entry.Operator == "" || !r.operatorAllowed(entry.Operator) {
		decision.Reason = EarlyWarningDashboardReasonInvalidOperator
		return EarlyWarningRuleEntry{}, decision, ErrEarlyWarningDashboardInvalidOperator
	}
	if entry.Severity == "" || !r.severityAllowed(entry.Severity) {
		decision.Reason = EarlyWarningDashboardReasonInvalidSeverity
		return EarlyWarningRuleEntry{}, decision, ErrEarlyWarningDashboardInvalidSeverity
	}
	if entry.CreatedAt == "" {
		entry.CreatedAt = now
	}
	entry.UpdatedAt = now
	entry.Metadata = cloneOpsConsoleMap(entry.Metadata)

	r.mu.Lock()
	r.rules[earlyWarningRuleKey(entry.TenantID, entry.RuleID)] = entry
	r.mu.Unlock()

	decision.Decision = EarlyWarningDashboardDecisionAllow
	decision.Allowed = true
	decision.Reason = EarlyWarningDashboardReasonAllowed

	return entry, decision, nil
}

func (r *EarlyWarningAlertDashboardConsoleRuntime) RaiseAlert(entry EarlyWarningAlertEntry) (EarlyWarningAlertEntry, EarlyWarningDashboardDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	entry.TenantID = strings.TrimSpace(entry.TenantID)
	entry.AlertID = strings.TrimSpace(entry.AlertID)
	entry.RuleID = strings.TrimSpace(entry.RuleID)
	entry.Source = normalizeOpsConsoleValue(entry.Source)
	entry.Metric = strings.TrimSpace(entry.Metric)
	entry.Severity = normalizeOpsConsoleValue(entry.Severity)
	entry.Status = normalizeOpsConsoleValue(entry.Status)
	entry.Message = strings.TrimSpace(entry.Message)

	decision := EarlyWarningDashboardDecision{
		Decision:  EarlyWarningDashboardDecisionDeny,
		Allowed:   false,
		TenantID:  entry.TenantID,
		Reason:    EarlyWarningDashboardReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && entry.TenantID == "" {
		decision.Reason = EarlyWarningDashboardReasonMissingTenant
		return EarlyWarningAlertEntry{}, decision, ErrEarlyWarningDashboardMissingTenant
	}
	if entry.AlertID == "" {
		decision.Reason = EarlyWarningDashboardReasonMissingAlertID
		return EarlyWarningAlertEntry{}, decision, ErrEarlyWarningDashboardMissingAlertID
	}
	if entry.Source == "" {
		decision.Reason = EarlyWarningDashboardReasonMissingSource
		return EarlyWarningAlertEntry{}, decision, ErrEarlyWarningDashboardMissingSource
	}
	if !r.sourceAllowed(entry.Source) {
		decision.Reason = EarlyWarningDashboardReasonInvalidSource
		return EarlyWarningAlertEntry{}, decision, ErrEarlyWarningDashboardInvalidSource
	}
	if entry.Metric == "" {
		decision.Reason = EarlyWarningDashboardReasonMissingMetric
		return EarlyWarningAlertEntry{}, decision, ErrEarlyWarningDashboardMissingMetric
	}
	if entry.Severity == "" || !r.severityAllowed(entry.Severity) {
		decision.Reason = EarlyWarningDashboardReasonInvalidSeverity
		return EarlyWarningAlertEntry{}, decision, ErrEarlyWarningDashboardInvalidSeverity
	}
	if entry.Status == "" {
		entry.Status = EarlyWarningStatusOpen
	}
	if !r.statusAllowed(entry.Status) {
		decision.Reason = EarlyWarningDashboardReasonInvalidStatus
		return EarlyWarningAlertEntry{}, decision, ErrEarlyWarningDashboardInvalidStatus
	}
	if entry.Message == "" {
		decision.Reason = EarlyWarningDashboardReasonMissingMessage
		return EarlyWarningAlertEntry{}, decision, ErrEarlyWarningDashboardMissingMessage
	}
	if entry.CreatedAt == "" {
		entry.CreatedAt = now
	}
	entry.UpdatedAt = now
	entry.Metadata = cloneOpsConsoleMap(entry.Metadata)

	r.mu.Lock()
	r.alerts[earlyWarningAlertKey(entry.TenantID, entry.AlertID)] = entry
	r.mu.Unlock()

	decision.Decision = EarlyWarningDashboardDecisionAllow
	decision.Allowed = true
	decision.Reason = EarlyWarningDashboardReasonAllowed

	return entry, decision, nil
}

func (r *EarlyWarningAlertDashboardConsoleRuntime) AcknowledgeAlert(tenantID string, alertID string, operatorID string) (EarlyWarningAlertEntry, EarlyWarningDashboardDecision, error) {
	return r.transitionAlert(tenantID, alertID, operatorID, EarlyWarningStatusAcknowledged)
}

func (r *EarlyWarningAlertDashboardConsoleRuntime) ResolveAlert(tenantID string, alertID string, operatorID string) (EarlyWarningAlertEntry, EarlyWarningDashboardDecision, error) {
	return r.transitionAlert(tenantID, alertID, operatorID, EarlyWarningStatusResolved)
}

func (r *EarlyWarningAlertDashboardConsoleRuntime) transitionAlert(tenantID string, alertID string, operatorID string, status string) (EarlyWarningAlertEntry, EarlyWarningDashboardDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID = strings.TrimSpace(tenantID)
	alertID = strings.TrimSpace(alertID)
	operatorID = strings.TrimSpace(operatorID)
	status = normalizeOpsConsoleValue(status)

	decision := EarlyWarningDashboardDecision{
		Decision:  EarlyWarningDashboardDecisionDeny,
		Allowed:   false,
		TenantID:  tenantID,
		Reason:    EarlyWarningDashboardReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = EarlyWarningDashboardReasonMissingTenant
		return EarlyWarningAlertEntry{}, decision, ErrEarlyWarningDashboardMissingTenant
	}
	if alertID == "" {
		decision.Reason = EarlyWarningDashboardReasonMissingAlertID
		return EarlyWarningAlertEntry{}, decision, ErrEarlyWarningDashboardMissingAlertID
	}
	if operatorID == "" {
		decision.Reason = EarlyWarningDashboardReasonMissingOperatorID
		return EarlyWarningAlertEntry{}, decision, ErrEarlyWarningDashboardMissingOperatorID
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	alert, ok := r.alerts[earlyWarningAlertKey(tenantID, alertID)]
	if !ok {
		decision.Reason = EarlyWarningDashboardReasonAlertNotFound
		return EarlyWarningAlertEntry{}, decision, ErrEarlyWarningDashboardAlertNotFound
	}

	alert.Status = status
	alert.OperatorID = operatorID
	alert.UpdatedAt = now
	if status == EarlyWarningStatusAcknowledged {
		alert.AcknowledgedAt = now
	}
	if status == EarlyWarningStatusResolved {
		alert.ResolvedAt = now
	}
	r.alerts[earlyWarningAlertKey(tenantID, alertID)] = alert

	decision.Decision = EarlyWarningDashboardDecisionAllow
	decision.Allowed = true
	decision.Reason = EarlyWarningDashboardReasonAllowed

	return alert, decision, nil
}

func (r *EarlyWarningAlertDashboardConsoleRuntime) BuildSnapshot(req EarlyWarningDashboardRequest) (EarlyWarningDashboardSnapshot, EarlyWarningDashboardDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	viewerTenantID := strings.TrimSpace(req.ViewerTenantID)
	sourceFilter := normalizeOpsConsoleValue(req.SourceFilter)
	severityFilter := normalizeOpsConsoleValue(req.SeverityFilter)
	statusFilter := normalizeOpsConsoleValue(req.StatusFilter)

	if viewerTenantID == "" {
		viewerTenantID = tenantID
	}

	decision := EarlyWarningDashboardDecision{
		Decision:       EarlyWarningDashboardDecisionDeny,
		Allowed:        false,
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		SourceFilter:   sourceFilter,
		SeverityFilter: severityFilter,
		StatusFilter:   statusFilter,
		Reason:         EarlyWarningDashboardReasonAllowed,
		CheckedAt:      now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = EarlyWarningDashboardReasonMissingTenant
		return EarlyWarningDashboardSnapshot{}, decision, ErrEarlyWarningDashboardMissingTenant
	}
	if viewerTenantID != tenantID && !(r.config.AllowPlatformViewer && viewerTenantID == "platform") {
		decision.Reason = EarlyWarningDashboardReasonCrossTenant
		return EarlyWarningDashboardSnapshot{}, decision, ErrEarlyWarningDashboardCrossTenant
	}
	if sourceFilter != "" && !r.sourceAllowed(sourceFilter) {
		decision.Reason = EarlyWarningDashboardReasonInvalidSource
		return EarlyWarningDashboardSnapshot{}, decision, ErrEarlyWarningDashboardInvalidSource
	}
	if severityFilter != "" && !r.severityAllowed(severityFilter) {
		decision.Reason = EarlyWarningDashboardReasonInvalidSeverity
		return EarlyWarningDashboardSnapshot{}, decision, ErrEarlyWarningDashboardInvalidSeverity
	}
	if statusFilter != "" && !r.statusAllowed(statusFilter) {
		decision.Reason = EarlyWarningDashboardReasonInvalidStatus
		return EarlyWarningDashboardSnapshot{}, decision, ErrEarlyWarningDashboardInvalidStatus
	}

	snapshot := EarlyWarningDashboardSnapshot{
		OK:             true,
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		SourceFilter:   sourceFilter,
		SeverityFilter: severityFilter,
		StatusFilter:   statusFilter,
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		GeneratedAt:    now,
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	if req.IncludeRules {
		for _, rule := range r.rules {
			if rule.TenantID != tenantID {
				continue
			}
			if sourceFilter != "" && rule.Source != sourceFilter {
				continue
			}
			if severityFilter != "" && rule.Severity != severityFilter {
				continue
			}
			if snapshot.RuleCount >= r.config.MaxVisibleRules {
				continue
			}
			snapshot.Rules = append(snapshot.Rules, rule)
			snapshot.RuleCount++
		}
	}

	for _, alert := range r.alerts {
		if alert.TenantID != tenantID {
			continue
		}
		if !req.IncludeResolved && (alert.Status == EarlyWarningStatusResolved || alert.Status == EarlyWarningStatusSuppressed) {
			continue
		}
		if sourceFilter != "" && alert.Source != sourceFilter {
			continue
		}
		if severityFilter != "" && alert.Severity != severityFilter {
			continue
		}
		if statusFilter != "" && alert.Status != statusFilter {
			continue
		}
		if snapshot.AlertCount >= r.config.MaxVisibleAlerts {
			continue
		}

		snapshot.Alerts = append(snapshot.Alerts, alert)
		snapshot.AlertCount++

		switch alert.Status {
		case EarlyWarningStatusOpen:
			snapshot.OpenCount++
		case EarlyWarningStatusAcknowledged:
			snapshot.AcknowledgedCount++
		case EarlyWarningStatusResolved:
			snapshot.ResolvedCount++
		case EarlyWarningStatusSuppressed:
			snapshot.SuppressedCount++
		}

		switch alert.Severity {
		case EarlyWarningSeverityInfo:
			snapshot.InfoCount++
		case EarlyWarningSeverityWarning:
			snapshot.WarningCount++
		case EarlyWarningSeverityCritical:
			snapshot.CriticalCount++
		}

		switch alert.Source {
		case EarlyWarningSourceRuntimeHealth:
			snapshot.RuntimeHealthCount++
		case EarlyWarningSourceJobQueue:
			snapshot.JobQueueCount++
		case EarlyWarningSourceWebhook:
			snapshot.WebhookCount++
		case EarlyWarningSourceDatabase:
			snapshot.DatabaseCount++
		case EarlyWarningSourceSecurity:
			snapshot.SecurityCount++
		case EarlyWarningSourceEventBus:
			snapshot.EventBusCount++
		}
	}

	decision.Decision = EarlyWarningDashboardDecisionAllow
	decision.Allowed = true
	decision.Reason = EarlyWarningDashboardReasonAllowed

	return snapshot, decision, nil
}

func (r *EarlyWarningAlertDashboardConsoleRuntime) severityAllowed(severity string) bool {
	severity = normalizeOpsConsoleValue(severity)
	for _, allowed := range r.config.AllowedSeverities {
		if normalizeOpsConsoleValue(allowed) == severity {
			return true
		}
	}
	return false
}

func (r *EarlyWarningAlertDashboardConsoleRuntime) statusAllowed(status string) bool {
	status = normalizeOpsConsoleValue(status)
	for _, allowed := range r.config.AllowedStatuses {
		if normalizeOpsConsoleValue(allowed) == status {
			return true
		}
	}
	return false
}

func (r *EarlyWarningAlertDashboardConsoleRuntime) sourceAllowed(source string) bool {
	source = normalizeOpsConsoleValue(source)
	for _, allowed := range r.config.AllowedSources {
		if normalizeOpsConsoleValue(allowed) == source {
			return true
		}
	}
	return false
}

func (r *EarlyWarningAlertDashboardConsoleRuntime) operatorAllowed(operator string) bool {
	operator = normalizeOpsConsoleValue(operator)
	for _, allowed := range r.config.AllowedOperators {
		if normalizeOpsConsoleValue(allowed) == operator {
			return true
		}
	}
	return false
}

func earlyWarningRuleKey(tenantID string, ruleID string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(ruleID)
}

func earlyWarningAlertKey(tenantID string, alertID string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(alertID)
}
