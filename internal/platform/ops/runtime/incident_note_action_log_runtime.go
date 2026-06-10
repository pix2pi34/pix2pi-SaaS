package opsruntime

import (
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	IncidentActionTypeNote           = "INCIDENT_NOTE"
	IncidentActionTypeOperatorAction = "OPERATOR_ACTION"

	IncidentActionSeverityInfo     = "INFO"
	IncidentActionSeverityWarning  = "WARNING"
	IncidentActionSeverityCritical = "CRITICAL"

	IncidentActionLogDecisionAllow = "ALLOW"
	IncidentActionLogDecisionDeny  = "DENY"

	IncidentActionLogReasonAllowed              = "INCIDENT_ACTION_LOG_ALLOWED"
	IncidentActionLogReasonMissingTenant        = "INCIDENT_ACTION_LOG_MISSING_TENANT"
	IncidentActionLogReasonMissingRegistry      = "INCIDENT_ACTION_LOG_MISSING_REGISTRY"
	IncidentActionLogReasonMissingInstance      = "INCIDENT_ACTION_LOG_MISSING_INSTANCE"
	IncidentActionLogReasonMissingOperator      = "INCIDENT_ACTION_LOG_MISSING_OPERATOR"
	IncidentActionLogReasonMissingOperatorRole  = "INCIDENT_ACTION_LOG_MISSING_OPERATOR_ROLE"
	IncidentActionLogReasonUnauthorizedOperator = "INCIDENT_ACTION_LOG_UNAUTHORIZED_OPERATOR"
	IncidentActionLogReasonMissingMessage       = "INCIDENT_ACTION_LOG_MISSING_MESSAGE"
	IncidentActionLogReasonInvalidActionType    = "INCIDENT_ACTION_LOG_INVALID_ACTION_TYPE"
	IncidentActionLogReasonInvalidSeverity      = "INCIDENT_ACTION_LOG_INVALID_SEVERITY"
	IncidentActionLogReasonCrossTenant          = "INCIDENT_ACTION_LOG_CROSS_TENANT_DENIED"
	IncidentActionLogReasonInstanceNotFound     = "INCIDENT_ACTION_LOG_INSTANCE_NOT_FOUND"
	IncidentActionLogReasonMetadataBridgeFailed = "INCIDENT_ACTION_LOG_METADATA_BRIDGE_FAILED"
)

var (
	ErrIncidentActionLogMissingTenant        = errors.New("missing incident action log tenant id")
	ErrIncidentActionLogMissingRegistry      = errors.New("missing incident action log registry")
	ErrIncidentActionLogMissingInstance      = errors.New("missing incident action log instance id")
	ErrIncidentActionLogMissingOperator      = errors.New("missing incident action log operator id")
	ErrIncidentActionLogMissingOperatorRole  = errors.New("missing incident action log operator role")
	ErrIncidentActionLogUnauthorizedOperator = errors.New("unauthorized incident action log operator")
	ErrIncidentActionLogMissingMessage       = errors.New("missing incident action log message")
	ErrIncidentActionLogInvalidActionType    = errors.New("invalid incident action log action type")
	ErrIncidentActionLogInvalidSeverity      = errors.New("invalid incident action log severity")
	ErrIncidentActionLogCrossTenant          = errors.New("cross-tenant incident action log denied")
	ErrIncidentActionLogInstanceNotFound     = errors.New("incident action log instance not found")
	ErrIncidentActionLogMetadataBridgeFailed = errors.New("incident action log metadata bridge failed")
)

type IncidentNoteActionLogRuntimeConfig struct {
	RequireTenant         bool     `json:"require_tenant"`
	AllowedOperatorRoles  []string `json:"allowed_operator_roles"`
	AllowedActionTypes    []string `json:"allowed_action_types"`
	AllowedSeverities     []string `json:"allowed_severities"`
	MetadataBridgeEnabled bool     `json:"metadata_bridge_enabled"`
	MetadataVisibility    string   `json:"metadata_visibility"`
}

func DefaultIncidentNoteActionLogRuntimeConfig() IncidentNoteActionLogRuntimeConfig {
	return IncidentNoteActionLogRuntimeConfig{
		RequireTenant: true,
		AllowedOperatorRoles: []string{
			OperatorRolePlatformAdmin,
			OperatorRoleOpsAdmin,
			OperatorRoleSRE,
		},
		AllowedActionTypes: []string{
			IncidentActionTypeNote,
			IncidentActionTypeOperatorAction,
		},
		AllowedSeverities: []string{
			IncidentActionSeverityInfo,
			IncidentActionSeverityWarning,
			IncidentActionSeverityCritical,
		},
		MetadataBridgeEnabled: true,
		MetadataVisibility:    InstanceMetadataVisibilityInternal,
	}
}

type IncidentNoteRequest struct {
	TenantID      string `json:"tenant_id"`
	InstanceID    string `json:"instance_id"`
	OperatorID    string `json:"operator_id"`
	OperatorRole  string `json:"operator_role"`
	Severity      string `json:"severity,omitempty"`
	Message       string `json:"message"`
	CorrelationID string `json:"correlation_id,omitempty"`
}

type IncidentActionLogRequest struct {
	TenantID        string `json:"tenant_id"`
	InstanceID      string `json:"instance_id"`
	ActionType      string `json:"action_type"`
	OperatorID      string `json:"operator_id"`
	OperatorRole    string `json:"operator_role"`
	Severity        string `json:"severity,omitempty"`
	Message         string `json:"message"`
	RelatedActionID string `json:"related_action_id,omitempty"`
	CorrelationID   string `json:"correlation_id,omitempty"`
}

type IncidentActionLogRecord struct {
	TenantID        string `json:"tenant_id"`
	LogID           string `json:"log_id"`
	ServiceID       string `json:"service_id"`
	InstanceID      string `json:"instance_id"`
	ServiceName     string `json:"service_name"`
	ActionType      string `json:"action_type"`
	Severity        string `json:"severity"`
	Message         string `json:"message"`
	RelatedActionID string `json:"related_action_id,omitempty"`
	OperatorID      string `json:"operator_id"`
	OperatorRole    string `json:"operator_role"`
	CorrelationID   string `json:"correlation_id,omitempty"`
	CreatedAt       string `json:"created_at"`
}

type IncidentActionLogDecision struct {
	Decision        string `json:"decision"`
	Allowed         bool   `json:"allowed"`
	TenantID        string `json:"tenant_id"`
	LogID           string `json:"log_id,omitempty"`
	ServiceID       string `json:"service_id,omitempty"`
	InstanceID      string `json:"instance_id,omitempty"`
	ServiceName     string `json:"service_name,omitempty"`
	ActionType      string `json:"action_type,omitempty"`
	Severity        string `json:"severity,omitempty"`
	OperatorID      string `json:"operator_id,omitempty"`
	OperatorRole    string `json:"operator_role,omitempty"`
	RelatedActionID string `json:"related_action_id,omitempty"`
	CorrelationID   string `json:"correlation_id,omitempty"`
	Reason          string `json:"reason"`
	CheckedAt       string `json:"checked_at"`
}

type IncidentNoteActionLogRuntime struct {
	config   IncidentNoteActionLogRuntimeConfig
	registry *InstanceMetadataRuntime
	mu       sync.RWMutex
	logs     map[string]IncidentActionLogRecord
}

func NewIncidentNoteActionLogRuntime(config IncidentNoteActionLogRuntimeConfig, registry *InstanceMetadataRuntime) *IncidentNoteActionLogRuntime {
	defaults := DefaultIncidentNoteActionLogRuntimeConfig()

	if len(config.AllowedOperatorRoles) == 0 {
		config.AllowedOperatorRoles = defaults.AllowedOperatorRoles
	}
	if len(config.AllowedActionTypes) == 0 {
		config.AllowedActionTypes = defaults.AllowedActionTypes
	}
	if len(config.AllowedSeverities) == 0 {
		config.AllowedSeverities = defaults.AllowedSeverities
	}
	if strings.TrimSpace(config.MetadataVisibility) == "" {
		config.MetadataVisibility = defaults.MetadataVisibility
	}

	return &IncidentNoteActionLogRuntime{
		config:   config,
		registry: registry,
		logs:     make(map[string]IncidentActionLogRecord),
	}
}

func (r *IncidentNoteActionLogRuntime) CreateIncidentNote(req IncidentNoteRequest) (IncidentActionLogRecord, IncidentActionLogDecision, error) {
	return r.RecordIncidentAction(IncidentActionLogRequest{
		TenantID:      req.TenantID,
		InstanceID:    req.InstanceID,
		ActionType:    IncidentActionTypeNote,
		OperatorID:    req.OperatorID,
		OperatorRole:  req.OperatorRole,
		Severity:      req.Severity,
		Message:       req.Message,
		CorrelationID: req.CorrelationID,
	})
}

func (r *IncidentNoteActionLogRuntime) RecordIncidentAction(req IncidentActionLogRequest) (IncidentActionLogRecord, IncidentActionLogDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	instanceID := strings.TrimSpace(req.InstanceID)
	actionType := normalizeIncidentActionType(req.ActionType)
	operatorID := strings.TrimSpace(req.OperatorID)
	operatorRole := normalizeOpsOperatorRole(req.OperatorRole)
	severity := normalizeIncidentSeverity(req.Severity)

	decision := IncidentActionLogDecision{
		Decision:        IncidentActionLogDecisionDeny,
		Allowed:         false,
		TenantID:        tenantID,
		InstanceID:      instanceID,
		ActionType:      actionType,
		Severity:        severity,
		OperatorID:      operatorID,
		OperatorRole:    operatorRole,
		RelatedActionID: strings.TrimSpace(req.RelatedActionID),
		CorrelationID:   strings.TrimSpace(req.CorrelationID),
		Reason:          IncidentActionLogReasonAllowed,
		CheckedAt:       now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = IncidentActionLogReasonMissingTenant
		return IncidentActionLogRecord{}, decision, ErrIncidentActionLogMissingTenant
	}

	if r.registry == nil {
		decision.Reason = IncidentActionLogReasonMissingRegistry
		return IncidentActionLogRecord{}, decision, ErrIncidentActionLogMissingRegistry
	}

	if instanceID == "" {
		decision.Reason = IncidentActionLogReasonMissingInstance
		return IncidentActionLogRecord{}, decision, ErrIncidentActionLogMissingInstance
	}

	if actionType == "" || !r.actionTypeAllowed(actionType) {
		decision.Reason = IncidentActionLogReasonInvalidActionType
		return IncidentActionLogRecord{}, decision, ErrIncidentActionLogInvalidActionType
	}

	if operatorID == "" {
		decision.Reason = IncidentActionLogReasonMissingOperator
		return IncidentActionLogRecord{}, decision, ErrIncidentActionLogMissingOperator
	}

	if operatorRole == "" {
		decision.Reason = IncidentActionLogReasonMissingOperatorRole
		return IncidentActionLogRecord{}, decision, ErrIncidentActionLogMissingOperatorRole
	}

	if !r.operatorRoleAllowed(operatorRole) {
		decision.Reason = IncidentActionLogReasonUnauthorizedOperator
		return IncidentActionLogRecord{}, decision, ErrIncidentActionLogUnauthorizedOperator
	}

	if severity == "" || !r.severityAllowed(severity) {
		decision.Reason = IncidentActionLogReasonInvalidSeverity
		return IncidentActionLogRecord{}, decision, ErrIncidentActionLogInvalidSeverity
	}

	if strings.TrimSpace(req.Message) == "" {
		decision.Reason = IncidentActionLogReasonMissingMessage
		return IncidentActionLogRecord{}, decision, ErrIncidentActionLogMissingMessage
	}

	instance, err := r.getTenantInstance(tenantID, instanceID)
	if err != nil {
		if errors.Is(err, ErrIncidentActionLogCrossTenant) {
			decision.Reason = IncidentActionLogReasonCrossTenant
			return IncidentActionLogRecord{}, decision, ErrIncidentActionLogCrossTenant
		}
		decision.Reason = IncidentActionLogReasonInstanceNotFound
		return IncidentActionLogRecord{}, decision, ErrIncidentActionLogInstanceNotFound
	}

	record := IncidentActionLogRecord{
		TenantID:        tenantID,
		LogID:           NewIncidentActionLogID(),
		ServiceID:       instance.ServiceID,
		InstanceID:      instance.InstanceID,
		ServiceName:     instance.ServiceName,
		ActionType:      actionType,
		Severity:        severity,
		Message:         strings.TrimSpace(req.Message),
		RelatedActionID: strings.TrimSpace(req.RelatedActionID),
		OperatorID:      operatorID,
		OperatorRole:    operatorRole,
		CorrelationID:   strings.TrimSpace(req.CorrelationID),
		CreatedAt:       now,
	}

	if r.config.MetadataBridgeEnabled {
		if err := r.writeIncidentMetadata(record); err != nil {
			decision.Reason = IncidentActionLogReasonMetadataBridgeFailed
			return IncidentActionLogRecord{}, decision, ErrIncidentActionLogMetadataBridgeFailed
		}
	}

	r.mu.Lock()
	r.logs[record.LogID] = record
	r.mu.Unlock()

	decision.Decision = IncidentActionLogDecisionAllow
	decision.Allowed = true
	decision.LogID = record.LogID
	decision.ServiceID = record.ServiceID
	decision.ServiceName = record.ServiceName
	decision.Reason = IncidentActionLogReasonAllowed

	return record, decision, nil
}

func (r *IncidentNoteActionLogRuntime) GetIncidentActionLog(tenantID string, logID string) (IncidentActionLogRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	logID = strings.TrimSpace(logID)

	if tenantID == "" {
		return IncidentActionLogRecord{}, ErrIncidentActionLogMissingTenant
	}
	if logID == "" {
		return IncidentActionLogRecord{}, ErrIncidentActionLogMissingInstance
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	record, ok := r.logs[logID]
	if !ok {
		return IncidentActionLogRecord{}, ErrIncidentActionLogInstanceNotFound
	}

	if record.TenantID != tenantID {
		return IncidentActionLogRecord{}, ErrIncidentActionLogCrossTenant
	}

	return record, nil
}

func (r *IncidentNoteActionLogRuntime) ListTenantIncidentActionLogs(tenantID string) ([]IncidentActionLogRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrIncidentActionLogMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]IncidentActionLogRecord, 0)
	for _, record := range r.logs {
		if record.TenantID == tenantID {
			out = append(out, record)
		}
	}

	return out, nil
}

func (r *IncidentNoteActionLogRuntime) ListInstanceIncidentActionLogs(tenantID string, instanceID string) ([]IncidentActionLogRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	instanceID = strings.TrimSpace(instanceID)

	if tenantID == "" {
		return nil, ErrIncidentActionLogMissingTenant
	}
	if instanceID == "" {
		return nil, ErrIncidentActionLogMissingInstance
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]IncidentActionLogRecord, 0)
	for _, record := range r.logs {
		if record.TenantID == tenantID && record.InstanceID == instanceID {
			out = append(out, record)
		}
	}

	return out, nil
}

func (r *IncidentNoteActionLogRuntime) getTenantInstance(tenantID string, instanceID string) (ServiceInstanceRecord, error) {
	r.registry.mu.RLock()
	defer r.registry.mu.RUnlock()

	instance, ok := r.registry.instances[serviceInstanceKey(tenantID, instanceID)]
	if ok {
		return instance, nil
	}

	if r.registry.instanceExistsInAnotherTenantLocked(tenantID, instanceID) {
		return ServiceInstanceRecord{}, ErrIncidentActionLogCrossTenant
	}

	return ServiceInstanceRecord{}, ErrIncidentActionLogInstanceNotFound
}

func (r *IncidentNoteActionLogRuntime) writeIncidentMetadata(record IncidentActionLogRecord) error {
	metadata := map[string]string{
		"incident_action_log_id":      record.LogID,
		"incident_action_type":        record.ActionType,
		"incident_action_severity":    record.Severity,
		"incident_action_operator_id": record.OperatorID,
		"incident_action_logged_at":   record.CreatedAt,
	}

	for key, value := range metadata {
		_, decision, err := r.registry.UpsertMetadata(InstanceMetadataUpsertRequest{
			TenantID:      record.TenantID,
			InstanceID:    record.InstanceID,
			Key:           key,
			Value:         value,
			Visibility:    r.config.MetadataVisibility,
			Source:        "incident_note_action_log_runtime",
			CorrelationID: record.CorrelationID,
		})
		if err != nil || !decision.Allowed {
			return ErrIncidentActionLogMetadataBridgeFailed
		}
	}

	return nil
}

func (r *IncidentNoteActionLogRuntime) operatorRoleAllowed(role string) bool {
	role = normalizeOpsOperatorRole(role)
	for _, allowed := range r.config.AllowedOperatorRoles {
		if strings.EqualFold(strings.TrimSpace(allowed), role) {
			return true
		}
	}
	return false
}

func (r *IncidentNoteActionLogRuntime) actionTypeAllowed(actionType string) bool {
	actionType = normalizeIncidentActionType(actionType)
	for _, allowed := range r.config.AllowedActionTypes {
		if strings.EqualFold(strings.TrimSpace(allowed), actionType) {
			return true
		}
	}
	return false
}

func (r *IncidentNoteActionLogRuntime) severityAllowed(severity string) bool {
	severity = normalizeIncidentSeverity(severity)
	for _, allowed := range r.config.AllowedSeverities {
		if strings.EqualFold(strings.TrimSpace(allowed), severity) {
			return true
		}
	}
	return false
}

func normalizeIncidentActionType(actionType string) string {
	return strings.ToUpper(strings.TrimSpace(actionType))
}

func normalizeIncidentSeverity(severity string) string {
	severity = strings.ToUpper(strings.TrimSpace(severity))
	if severity == "" {
		return IncidentActionSeverityInfo
	}
	return severity
}

func NewIncidentActionLogID() string {
	return randomOpsRuntimeID("incident_action_log_")
}
