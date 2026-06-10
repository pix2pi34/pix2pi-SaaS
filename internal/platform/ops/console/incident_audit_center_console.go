package opsconsole

import (
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	IncidentAuditSeverityInfo     = "INFO"
	IncidentAuditSeverityWarning  = "WARNING"
	IncidentAuditSeverityCritical = "CRITICAL"

	IncidentStatusOpen         = "OPEN"
	IncidentStatusAcknowledged = "ACKNOWLEDGED"
	IncidentStatusResolved     = "RESOLVED"

	AuditActionIncidentCreated  = "INCIDENT_CREATED"
	AuditActionIncidentUpdated  = "INCIDENT_UPDATED"
	AuditActionIncidentResolved = "INCIDENT_RESOLVED"
	AuditActionOperatorAction   = "OPERATOR_ACTION"
	AuditActionSystemEvent      = "SYSTEM_EVENT"
	AuditActionSecurityEvent    = "SECURITY_EVENT"

	IncidentAuditDecisionAllow = "ALLOW"
	IncidentAuditDecisionDeny  = "DENY"

	IncidentAuditReasonAllowed           = "INCIDENT_AUDIT_ALLOWED"
	IncidentAuditReasonMissingTenant     = "INCIDENT_AUDIT_MISSING_TENANT"
	IncidentAuditReasonCrossTenant       = "INCIDENT_AUDIT_CROSS_TENANT_DENIED"
	IncidentAuditReasonMissingIncidentID = "INCIDENT_AUDIT_MISSING_INCIDENT_ID"
	IncidentAuditReasonMissingAuditID    = "INCIDENT_AUDIT_MISSING_AUDIT_ID"
	IncidentAuditReasonMissingTitle      = "INCIDENT_AUDIT_MISSING_TITLE"
	IncidentAuditReasonMissingMessage    = "INCIDENT_AUDIT_MISSING_MESSAGE"
	IncidentAuditReasonMissingSeverity   = "INCIDENT_AUDIT_MISSING_SEVERITY"
	IncidentAuditReasonInvalidSeverity   = "INCIDENT_AUDIT_INVALID_SEVERITY"
	IncidentAuditReasonMissingStatus     = "INCIDENT_AUDIT_MISSING_STATUS"
	IncidentAuditReasonInvalidStatus     = "INCIDENT_AUDIT_INVALID_STATUS"
	IncidentAuditReasonIncidentNotFound  = "INCIDENT_AUDIT_INCIDENT_NOT_FOUND"
	IncidentAuditReasonMissingActor      = "INCIDENT_AUDIT_MISSING_ACTOR"
	IncidentAuditReasonMissingActionType = "INCIDENT_AUDIT_MISSING_ACTION_TYPE"
	IncidentAuditReasonInvalidActionType = "INCIDENT_AUDIT_INVALID_ACTION_TYPE"
	IncidentAuditReasonMissingTarget     = "INCIDENT_AUDIT_MISSING_TARGET"
)

var (
	ErrIncidentAuditMissingTenant     = errors.New("missing incident audit tenant id")
	ErrIncidentAuditCrossTenant       = errors.New("cross-tenant incident audit access denied")
	ErrIncidentAuditMissingIncidentID = errors.New("missing incident id")
	ErrIncidentAuditMissingAuditID    = errors.New("missing audit id")
	ErrIncidentAuditMissingTitle      = errors.New("missing incident title")
	ErrIncidentAuditMissingMessage    = errors.New("missing incident audit message")
	ErrIncidentAuditMissingSeverity   = errors.New("missing incident audit severity")
	ErrIncidentAuditInvalidSeverity   = errors.New("invalid incident audit severity")
	ErrIncidentAuditMissingStatus     = errors.New("missing incident status")
	ErrIncidentAuditInvalidStatus     = errors.New("invalid incident status")
	ErrIncidentAuditIncidentNotFound  = errors.New("incident not found")
	ErrIncidentAuditMissingActor      = errors.New("missing audit actor")
	ErrIncidentAuditMissingActionType = errors.New("missing audit action type")
	ErrIncidentAuditInvalidActionType = errors.New("invalid audit action type")
	ErrIncidentAuditMissingTarget     = errors.New("missing audit target")
)

type IncidentAuditCenterConsoleConfig struct {
	RequireTenant       bool     `json:"require_tenant"`
	AllowPlatformViewer bool     `json:"allow_platform_viewer"`
	MaxVisibleIncidents int      `json:"max_visible_incidents"`
	MaxVisibleAuditLogs int      `json:"max_visible_audit_logs"`
	AllowedSeverities   []string `json:"allowed_severities"`
	AllowedStatuses     []string `json:"allowed_statuses"`
	AllowedActionTypes  []string `json:"allowed_action_types"`
}

func DefaultIncidentAuditCenterConsoleConfig() IncidentAuditCenterConsoleConfig {
	return IncidentAuditCenterConsoleConfig{
		RequireTenant:       true,
		AllowPlatformViewer: true,
		MaxVisibleIncidents: 100,
		MaxVisibleAuditLogs: 100,
		AllowedSeverities: []string{
			IncidentAuditSeverityInfo,
			IncidentAuditSeverityWarning,
			IncidentAuditSeverityCritical,
		},
		AllowedStatuses: []string{
			IncidentStatusOpen,
			IncidentStatusAcknowledged,
			IncidentStatusResolved,
		},
		AllowedActionTypes: []string{
			AuditActionIncidentCreated,
			AuditActionIncidentUpdated,
			AuditActionIncidentResolved,
			AuditActionOperatorAction,
			AuditActionSystemEvent,
			AuditActionSecurityEvent,
		},
	}
}

type IncidentCenterRecord struct {
	TenantID      string            `json:"tenant_id"`
	IncidentID    string            `json:"incident_id"`
	Source        string            `json:"source"`
	Severity      string            `json:"severity"`
	Status        string            `json:"status"`
	Title         string            `json:"title"`
	Message       string            `json:"message"`
	Owner         string            `json:"owner,omitempty"`
	CorrelationID string            `json:"correlation_id,omitempty"`
	Metadata      map[string]string `json:"metadata,omitempty"`
	CreatedAt     string            `json:"created_at"`
	UpdatedAt     string            `json:"updated_at"`
	ResolvedAt    string            `json:"resolved_at,omitempty"`
}

type AuditCenterRecord struct {
	TenantID      string            `json:"tenant_id"`
	AuditID       string            `json:"audit_id"`
	ActorID       string            `json:"actor_id"`
	ActionType    string            `json:"action_type"`
	TargetType    string            `json:"target_type"`
	TargetID      string            `json:"target_id"`
	Severity      string            `json:"severity"`
	Message       string            `json:"message"`
	CorrelationID string            `json:"correlation_id,omitempty"`
	Metadata      map[string]string `json:"metadata,omitempty"`
	CreatedAt     string            `json:"created_at"`
}

type IncidentAuditCenterRequest struct {
	TenantID        string `json:"tenant_id"`
	ViewerTenantID  string `json:"viewer_tenant_id,omitempty"`
	SeverityFilter  string `json:"severity_filter,omitempty"`
	StatusFilter    string `json:"status_filter,omitempty"`
	ActionFilter    string `json:"action_filter,omitempty"`
	IncludeResolved bool   `json:"include_resolved"`
	IncludeAudit    bool   `json:"include_audit"`
	CorrelationID   string `json:"correlation_id,omitempty"`
}

type IncidentAuditCenterDecision struct {
	Decision       string `json:"decision"`
	Allowed        bool   `json:"allowed"`
	TenantID       string `json:"tenant_id"`
	ViewerTenantID string `json:"viewer_tenant_id,omitempty"`
	Reason         string `json:"reason"`
	CheckedAt      string `json:"checked_at"`
}

type IncidentAuditCenterSnapshot struct {
	OK                  bool                   `json:"ok"`
	TenantID            string                 `json:"tenant_id"`
	ViewerTenantID      string                 `json:"viewer_tenant_id"`
	SeverityFilter      string                 `json:"severity_filter,omitempty"`
	StatusFilter        string                 `json:"status_filter,omitempty"`
	ActionFilter        string                 `json:"action_filter,omitempty"`
	IncidentCount       int                    `json:"incident_count"`
	AuditCount          int                    `json:"audit_count"`
	OpenCount           int                    `json:"open_count"`
	AcknowledgedCount   int                    `json:"acknowledged_count"`
	ResolvedCount       int                    `json:"resolved_count"`
	InfoCount           int                    `json:"info_count"`
	WarningCount        int                    `json:"warning_count"`
	CriticalCount       int                    `json:"critical_count"`
	SecurityEventCount  int                    `json:"security_event_count"`
	OperatorActionCount int                    `json:"operator_action_count"`
	Incidents           []IncidentCenterRecord `json:"incidents"`
	AuditLogs           []AuditCenterRecord    `json:"audit_logs"`
	CorrelationID       string                 `json:"correlation_id,omitempty"`
	GeneratedAt         string                 `json:"generated_at"`
}

type IncidentAuditCenterConsoleRuntime struct {
	config    IncidentAuditCenterConsoleConfig
	mu        sync.RWMutex
	incidents map[string]IncidentCenterRecord
	auditLogs map[string]AuditCenterRecord
}

func NewIncidentAuditCenterConsoleRuntime(config IncidentAuditCenterConsoleConfig) *IncidentAuditCenterConsoleRuntime {
	defaults := DefaultIncidentAuditCenterConsoleConfig()

	if config.MaxVisibleIncidents <= 0 {
		config.MaxVisibleIncidents = defaults.MaxVisibleIncidents
	}
	if config.MaxVisibleAuditLogs <= 0 {
		config.MaxVisibleAuditLogs = defaults.MaxVisibleAuditLogs
	}
	if len(config.AllowedSeverities) == 0 {
		config.AllowedSeverities = defaults.AllowedSeverities
	}
	if len(config.AllowedStatuses) == 0 {
		config.AllowedStatuses = defaults.AllowedStatuses
	}
	if len(config.AllowedActionTypes) == 0 {
		config.AllowedActionTypes = defaults.AllowedActionTypes
	}

	return &IncidentAuditCenterConsoleRuntime{
		config:    config,
		incidents: make(map[string]IncidentCenterRecord),
		auditLogs: make(map[string]AuditCenterRecord),
	}
}

func (r *IncidentAuditCenterConsoleRuntime) UpsertIncident(entry IncidentCenterRecord) (IncidentCenterRecord, IncidentAuditCenterDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	entry.TenantID = strings.TrimSpace(entry.TenantID)
	entry.IncidentID = strings.TrimSpace(entry.IncidentID)
	entry.Source = strings.TrimSpace(entry.Source)
	entry.Severity = normalizeOpsConsoleValue(entry.Severity)
	entry.Status = normalizeOpsConsoleValue(entry.Status)
	entry.Title = strings.TrimSpace(entry.Title)
	entry.Message = strings.TrimSpace(entry.Message)

	decision := IncidentAuditCenterDecision{
		Decision:  IncidentAuditDecisionDeny,
		Allowed:   false,
		TenantID:  entry.TenantID,
		Reason:    IncidentAuditReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && entry.TenantID == "" {
		decision.Reason = IncidentAuditReasonMissingTenant
		return IncidentCenterRecord{}, decision, ErrIncidentAuditMissingTenant
	}
	if entry.IncidentID == "" {
		decision.Reason = IncidentAuditReasonMissingIncidentID
		return IncidentCenterRecord{}, decision, ErrIncidentAuditMissingIncidentID
	}
	if entry.Title == "" {
		decision.Reason = IncidentAuditReasonMissingTitle
		return IncidentCenterRecord{}, decision, ErrIncidentAuditMissingTitle
	}
	if entry.Message == "" {
		decision.Reason = IncidentAuditReasonMissingMessage
		return IncidentCenterRecord{}, decision, ErrIncidentAuditMissingMessage
	}
	if entry.Severity == "" {
		decision.Reason = IncidentAuditReasonMissingSeverity
		return IncidentCenterRecord{}, decision, ErrIncidentAuditMissingSeverity
	}
	if !r.severityAllowed(entry.Severity) {
		decision.Reason = IncidentAuditReasonInvalidSeverity
		return IncidentCenterRecord{}, decision, ErrIncidentAuditInvalidSeverity
	}
	if entry.Status == "" {
		decision.Reason = IncidentAuditReasonMissingStatus
		return IncidentCenterRecord{}, decision, ErrIncidentAuditMissingStatus
	}
	if !r.statusAllowed(entry.Status) {
		decision.Reason = IncidentAuditReasonInvalidStatus
		return IncidentCenterRecord{}, decision, ErrIncidentAuditInvalidStatus
	}

	if entry.CreatedAt == "" {
		entry.CreatedAt = now
	}
	entry.UpdatedAt = now
	entry.Metadata = cloneOpsConsoleMap(entry.Metadata)

	r.mu.Lock()
	r.incidents[incidentCenterKey(entry.TenantID, entry.IncidentID)] = entry
	r.mu.Unlock()

	decision.Decision = IncidentAuditDecisionAllow
	decision.Allowed = true
	decision.Reason = IncidentAuditReasonAllowed

	return entry, decision, nil
}

func (r *IncidentAuditCenterConsoleRuntime) ResolveIncident(tenantID string, incidentID string, actorID string, message string) (IncidentCenterRecord, IncidentAuditCenterDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID = strings.TrimSpace(tenantID)
	incidentID = strings.TrimSpace(incidentID)
	actorID = strings.TrimSpace(actorID)
	message = strings.TrimSpace(message)

	decision := IncidentAuditCenterDecision{
		Decision:  IncidentAuditDecisionDeny,
		Allowed:   false,
		TenantID:  tenantID,
		Reason:    IncidentAuditReasonAllowed,
		CheckedAt: now,
	}

	if tenantID == "" {
		decision.Reason = IncidentAuditReasonMissingTenant
		return IncidentCenterRecord{}, decision, ErrIncidentAuditMissingTenant
	}
	if incidentID == "" {
		decision.Reason = IncidentAuditReasonMissingIncidentID
		return IncidentCenterRecord{}, decision, ErrIncidentAuditMissingIncidentID
	}
	if actorID == "" {
		decision.Reason = IncidentAuditReasonMissingActor
		return IncidentCenterRecord{}, decision, ErrIncidentAuditMissingActor
	}
	if message == "" {
		decision.Reason = IncidentAuditReasonMissingMessage
		return IncidentCenterRecord{}, decision, ErrIncidentAuditMissingMessage
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	record, ok := r.incidents[incidentCenterKey(tenantID, incidentID)]
	if !ok {
		decision.Reason = IncidentAuditReasonIncidentNotFound
		return IncidentCenterRecord{}, decision, ErrIncidentAuditIncidentNotFound
	}

	record.Status = IncidentStatusResolved
	record.UpdatedAt = now
	record.ResolvedAt = now
	r.incidents[incidentCenterKey(tenantID, incidentID)] = record

	audit := AuditCenterRecord{
		TenantID:   tenantID,
		AuditID:    NewAuditCenterID(),
		ActorID:    actorID,
		ActionType: AuditActionIncidentResolved,
		TargetType: "INCIDENT",
		TargetID:   incidentID,
		Severity:   record.Severity,
		Message:    message,
		CreatedAt:  now,
	}
	r.auditLogs[incidentAuditKey(tenantID, audit.AuditID)] = audit

	decision.Decision = IncidentAuditDecisionAllow
	decision.Allowed = true
	decision.Reason = IncidentAuditReasonAllowed

	return record, decision, nil
}

func (r *IncidentAuditCenterConsoleRuntime) RecordAuditEvent(entry AuditCenterRecord) (AuditCenterRecord, IncidentAuditCenterDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	entry.TenantID = strings.TrimSpace(entry.TenantID)
	entry.AuditID = strings.TrimSpace(entry.AuditID)
	entry.ActorID = strings.TrimSpace(entry.ActorID)
	entry.ActionType = normalizeOpsConsoleValue(entry.ActionType)
	entry.TargetType = strings.TrimSpace(entry.TargetType)
	entry.TargetID = strings.TrimSpace(entry.TargetID)
	entry.Severity = normalizeOpsConsoleValue(entry.Severity)
	entry.Message = strings.TrimSpace(entry.Message)

	decision := IncidentAuditCenterDecision{
		Decision:  IncidentAuditDecisionDeny,
		Allowed:   false,
		TenantID:  entry.TenantID,
		Reason:    IncidentAuditReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && entry.TenantID == "" {
		decision.Reason = IncidentAuditReasonMissingTenant
		return AuditCenterRecord{}, decision, ErrIncidentAuditMissingTenant
	}
	if entry.AuditID == "" {
		entry.AuditID = NewAuditCenterID()
	}
	if entry.ActorID == "" {
		decision.Reason = IncidentAuditReasonMissingActor
		return AuditCenterRecord{}, decision, ErrIncidentAuditMissingActor
	}
	if entry.ActionType == "" {
		decision.Reason = IncidentAuditReasonMissingActionType
		return AuditCenterRecord{}, decision, ErrIncidentAuditMissingActionType
	}
	if !r.actionTypeAllowed(entry.ActionType) {
		decision.Reason = IncidentAuditReasonInvalidActionType
		return AuditCenterRecord{}, decision, ErrIncidentAuditInvalidActionType
	}
	if entry.TargetType == "" || entry.TargetID == "" {
		decision.Reason = IncidentAuditReasonMissingTarget
		return AuditCenterRecord{}, decision, ErrIncidentAuditMissingTarget
	}
	if entry.Severity == "" {
		entry.Severity = IncidentAuditSeverityInfo
	}
	if !r.severityAllowed(entry.Severity) {
		decision.Reason = IncidentAuditReasonInvalidSeverity
		return AuditCenterRecord{}, decision, ErrIncidentAuditInvalidSeverity
	}
	if entry.Message == "" {
		decision.Reason = IncidentAuditReasonMissingMessage
		return AuditCenterRecord{}, decision, ErrIncidentAuditMissingMessage
	}

	if entry.CreatedAt == "" {
		entry.CreatedAt = now
	}
	entry.Metadata = cloneOpsConsoleMap(entry.Metadata)

	r.mu.Lock()
	r.auditLogs[incidentAuditKey(entry.TenantID, entry.AuditID)] = entry
	r.mu.Unlock()

	decision.Decision = IncidentAuditDecisionAllow
	decision.Allowed = true
	decision.Reason = IncidentAuditReasonAllowed

	return entry, decision, nil
}

func (r *IncidentAuditCenterConsoleRuntime) BuildSnapshot(req IncidentAuditCenterRequest) (IncidentAuditCenterSnapshot, IncidentAuditCenterDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	viewerTenantID := strings.TrimSpace(req.ViewerTenantID)
	severityFilter := normalizeOpsConsoleValue(req.SeverityFilter)
	statusFilter := normalizeOpsConsoleValue(req.StatusFilter)
	actionFilter := normalizeOpsConsoleValue(req.ActionFilter)

	if viewerTenantID == "" {
		viewerTenantID = tenantID
	}

	decision := IncidentAuditCenterDecision{
		Decision:       IncidentAuditDecisionDeny,
		Allowed:        false,
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		Reason:         IncidentAuditReasonAllowed,
		CheckedAt:      now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = IncidentAuditReasonMissingTenant
		return IncidentAuditCenterSnapshot{}, decision, ErrIncidentAuditMissingTenant
	}
	if viewerTenantID != tenantID && !(r.config.AllowPlatformViewer && viewerTenantID == "platform") {
		decision.Reason = IncidentAuditReasonCrossTenant
		return IncidentAuditCenterSnapshot{}, decision, ErrIncidentAuditCrossTenant
	}
	if severityFilter != "" && !r.severityAllowed(severityFilter) {
		decision.Reason = IncidentAuditReasonInvalidSeverity
		return IncidentAuditCenterSnapshot{}, decision, ErrIncidentAuditInvalidSeverity
	}
	if statusFilter != "" && !r.statusAllowed(statusFilter) {
		decision.Reason = IncidentAuditReasonInvalidStatus
		return IncidentAuditCenterSnapshot{}, decision, ErrIncidentAuditInvalidStatus
	}
	if actionFilter != "" && !r.actionTypeAllowed(actionFilter) {
		decision.Reason = IncidentAuditReasonInvalidActionType
		return IncidentAuditCenterSnapshot{}, decision, ErrIncidentAuditInvalidActionType
	}

	snapshot := IncidentAuditCenterSnapshot{
		OK:             true,
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		SeverityFilter: severityFilter,
		StatusFilter:   statusFilter,
		ActionFilter:   actionFilter,
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		GeneratedAt:    now,
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, incident := range r.incidents {
		if incident.TenantID != tenantID {
			continue
		}
		if !req.IncludeResolved && incident.Status == IncidentStatusResolved {
			continue
		}
		if severityFilter != "" && incident.Severity != severityFilter {
			continue
		}
		if statusFilter != "" && incident.Status != statusFilter {
			continue
		}
		if snapshot.IncidentCount >= r.config.MaxVisibleIncidents {
			continue
		}

		snapshot.Incidents = append(snapshot.Incidents, incident)
		snapshot.IncidentCount++

		switch incident.Status {
		case IncidentStatusOpen:
			snapshot.OpenCount++
		case IncidentStatusAcknowledged:
			snapshot.AcknowledgedCount++
		case IncidentStatusResolved:
			snapshot.ResolvedCount++
		}

		switch incident.Severity {
		case IncidentAuditSeverityInfo:
			snapshot.InfoCount++
		case IncidentAuditSeverityWarning:
			snapshot.WarningCount++
		case IncidentAuditSeverityCritical:
			snapshot.CriticalCount++
		}
	}

	if req.IncludeAudit {
		for _, audit := range r.auditLogs {
			if audit.TenantID != tenantID {
				continue
			}
			if severityFilter != "" && audit.Severity != severityFilter {
				continue
			}
			if actionFilter != "" && audit.ActionType != actionFilter {
				continue
			}
			if snapshot.AuditCount >= r.config.MaxVisibleAuditLogs {
				continue
			}

			snapshot.AuditLogs = append(snapshot.AuditLogs, audit)
			snapshot.AuditCount++

			switch audit.ActionType {
			case AuditActionSecurityEvent:
				snapshot.SecurityEventCount++
			case AuditActionOperatorAction:
				snapshot.OperatorActionCount++
			}
		}
	}

	decision.Decision = IncidentAuditDecisionAllow
	decision.Allowed = true
	decision.Reason = IncidentAuditReasonAllowed

	return snapshot, decision, nil
}

func (r *IncidentAuditCenterConsoleRuntime) severityAllowed(severity string) bool {
	severity = normalizeOpsConsoleValue(severity)
	for _, allowed := range r.config.AllowedSeverities {
		if normalizeOpsConsoleValue(allowed) == severity {
			return true
		}
	}
	return false
}

func (r *IncidentAuditCenterConsoleRuntime) statusAllowed(status string) bool {
	status = normalizeOpsConsoleValue(status)
	for _, allowed := range r.config.AllowedStatuses {
		if normalizeOpsConsoleValue(allowed) == status {
			return true
		}
	}
	return false
}

func (r *IncidentAuditCenterConsoleRuntime) actionTypeAllowed(actionType string) bool {
	actionType = normalizeOpsConsoleValue(actionType)
	for _, allowed := range r.config.AllowedActionTypes {
		if normalizeOpsConsoleValue(allowed) == actionType {
			return true
		}
	}
	return false
}

func incidentCenterKey(tenantID string, incidentID string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(incidentID)
}

func incidentAuditKey(tenantID string, auditID string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(auditID)
}

func NewIncidentCenterID() string {
	return NewOpsConsoleRuntimeID("incident_")
}

func NewAuditCenterID() string {
	return NewOpsConsoleRuntimeID("audit_")
}
