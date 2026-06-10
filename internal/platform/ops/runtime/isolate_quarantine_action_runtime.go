package opsruntime

import (
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	IsolateQuarantineActionTypeIsolate    = "ISOLATE"
	IsolateQuarantineActionTypeQuarantine = "QUARANTINE"

	IsolateQuarantineStateIsolateRequested    = "ISOLATE_REQUESTED"
	IsolateQuarantineStateQuarantineRequested = "QUARANTINE_REQUESTED"
	IsolateQuarantineStateDenied              = "ISOLATE_QUARANTINE_DENIED"

	IsolateQuarantineAuditEventRequested = "ISOLATE_QUARANTINE_ACTION_REQUESTED"
	IsolateQuarantineAuditEventDenied    = "ISOLATE_QUARANTINE_ACTION_DENIED"

	IsolateQuarantineDecisionAllow = "ALLOW"
	IsolateQuarantineDecisionDeny  = "DENY"

	IsolateQuarantineReasonAllowed              = "ISOLATE_QUARANTINE_ALLOWED"
	IsolateQuarantineReasonMissingTenant        = "ISOLATE_QUARANTINE_MISSING_TENANT"
	IsolateQuarantineReasonMissingRegistry      = "ISOLATE_QUARANTINE_MISSING_REGISTRY"
	IsolateQuarantineReasonMissingInstance      = "ISOLATE_QUARANTINE_MISSING_INSTANCE"
	IsolateQuarantineReasonMissingOperator      = "ISOLATE_QUARANTINE_MISSING_OPERATOR"
	IsolateQuarantineReasonMissingOperatorRole  = "ISOLATE_QUARANTINE_MISSING_OPERATOR_ROLE"
	IsolateQuarantineReasonUnauthorizedOperator = "ISOLATE_QUARANTINE_UNAUTHORIZED_OPERATOR"
	IsolateQuarantineReasonInvalidActionType    = "ISOLATE_QUARANTINE_INVALID_ACTION_TYPE"
	IsolateQuarantineReasonCrossTenant          = "ISOLATE_QUARANTINE_CROSS_TENANT_DENIED"
	IsolateQuarantineReasonInstanceNotFound     = "ISOLATE_QUARANTINE_INSTANCE_NOT_FOUND"
	IsolateQuarantineReasonMetadataBridgeFailed = "ISOLATE_QUARANTINE_METADATA_BRIDGE_FAILED"
)

var (
	ErrIsolateQuarantineMissingTenant        = errors.New("missing isolate quarantine tenant id")
	ErrIsolateQuarantineMissingRegistry      = errors.New("missing isolate quarantine registry")
	ErrIsolateQuarantineMissingInstance      = errors.New("missing isolate quarantine instance id")
	ErrIsolateQuarantineMissingOperator      = errors.New("missing isolate quarantine operator id")
	ErrIsolateQuarantineMissingOperatorRole  = errors.New("missing isolate quarantine operator role")
	ErrIsolateQuarantineUnauthorizedOperator = errors.New("unauthorized isolate quarantine operator")
	ErrIsolateQuarantineInvalidActionType    = errors.New("invalid isolate quarantine action type")
	ErrIsolateQuarantineCrossTenant          = errors.New("cross-tenant isolate quarantine action denied")
	ErrIsolateQuarantineInstanceNotFound     = errors.New("isolate quarantine instance not found")
	ErrIsolateQuarantineMetadataBridgeFailed = errors.New("isolate quarantine metadata bridge failed")
)

type IsolateQuarantineActionRuntimeConfig struct {
	RequireTenant         bool     `json:"require_tenant"`
	AllowedOperatorRoles  []string `json:"allowed_operator_roles"`
	AllowedActionTypes    []string `json:"allowed_action_types"`
	MetadataBridgeEnabled bool     `json:"metadata_bridge_enabled"`
	MetadataVisibility    string   `json:"metadata_visibility"`
}

func DefaultIsolateQuarantineActionRuntimeConfig() IsolateQuarantineActionRuntimeConfig {
	return IsolateQuarantineActionRuntimeConfig{
		RequireTenant: true,
		AllowedOperatorRoles: []string{
			OperatorRolePlatformAdmin,
			OperatorRoleOpsAdmin,
			OperatorRoleSRE,
		},
		AllowedActionTypes: []string{
			IsolateQuarantineActionTypeIsolate,
			IsolateQuarantineActionTypeQuarantine,
		},
		MetadataBridgeEnabled: true,
		MetadataVisibility:    InstanceMetadataVisibilityInternal,
	}
}

type IsolateQuarantineActionRequest struct {
	TenantID      string `json:"tenant_id"`
	InstanceID    string `json:"instance_id"`
	ActionType    string `json:"action_type"`
	OperatorID    string `json:"operator_id"`
	OperatorRole  string `json:"operator_role"`
	Reason        string `json:"reason,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
}

type IsolateQuarantineActionRecord struct {
	TenantID       string `json:"tenant_id"`
	ActionID       string `json:"action_id"`
	ServiceID      string `json:"service_id"`
	InstanceID     string `json:"instance_id"`
	ServiceName    string `json:"service_name"`
	ActionType     string `json:"action_type"`
	ActionState    string `json:"action_state"`
	PreviousStatus string `json:"previous_status"`
	OperatorID     string `json:"operator_id"`
	OperatorRole   string `json:"operator_role"`
	Reason         string `json:"reason,omitempty"`
	CorrelationID  string `json:"correlation_id,omitempty"`
	RequestedAt    string `json:"requested_at"`
	UpdatedAt      string `json:"updated_at"`
}

type IsolateQuarantineAuditEvent struct {
	TenantID      string `json:"tenant_id"`
	EventID       string `json:"event_id"`
	ActionID      string `json:"action_id,omitempty"`
	InstanceID    string `json:"instance_id,omitempty"`
	ServiceName   string `json:"service_name,omitempty"`
	ActionType    string `json:"action_type,omitempty"`
	EventType     string `json:"event_type"`
	Decision      string `json:"decision"`
	Reason        string `json:"reason"`
	OperatorID    string `json:"operator_id,omitempty"`
	OperatorRole  string `json:"operator_role,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
	CreatedAt     string `json:"created_at"`
}

type IsolateQuarantineDecision struct {
	Decision       string `json:"decision"`
	Allowed        bool   `json:"allowed"`
	TenantID       string `json:"tenant_id"`
	ActionID       string `json:"action_id,omitempty"`
	ServiceID      string `json:"service_id,omitempty"`
	InstanceID     string `json:"instance_id,omitempty"`
	ServiceName    string `json:"service_name,omitempty"`
	ActionType     string `json:"action_type,omitempty"`
	ActionState    string `json:"action_state,omitempty"`
	PreviousStatus string `json:"previous_status,omitempty"`
	OperatorID     string `json:"operator_id,omitempty"`
	OperatorRole   string `json:"operator_role,omitempty"`
	CorrelationID  string `json:"correlation_id,omitempty"`
	Reason         string `json:"reason"`
	CheckedAt      string `json:"checked_at"`
}

type IsolateQuarantineActionRuntime struct {
	config   IsolateQuarantineActionRuntimeConfig
	registry *InstanceMetadataRuntime
	mu       sync.RWMutex
	actions  map[string]IsolateQuarantineActionRecord
	audit    []IsolateQuarantineAuditEvent
}

func NewIsolateQuarantineActionRuntime(config IsolateQuarantineActionRuntimeConfig, registry *InstanceMetadataRuntime) *IsolateQuarantineActionRuntime {
	defaults := DefaultIsolateQuarantineActionRuntimeConfig()

	if len(config.AllowedOperatorRoles) == 0 {
		config.AllowedOperatorRoles = defaults.AllowedOperatorRoles
	}
	if len(config.AllowedActionTypes) == 0 {
		config.AllowedActionTypes = defaults.AllowedActionTypes
	}
	if strings.TrimSpace(config.MetadataVisibility) == "" {
		config.MetadataVisibility = defaults.MetadataVisibility
	}

	return &IsolateQuarantineActionRuntime{
		config:   config,
		registry: registry,
		actions:  make(map[string]IsolateQuarantineActionRecord),
		audit:    make([]IsolateQuarantineAuditEvent, 0),
	}
}

func (r *IsolateQuarantineActionRuntime) RequestIsolateOrQuarantine(req IsolateQuarantineActionRequest) (IsolateQuarantineActionRecord, IsolateQuarantineDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	instanceID := strings.TrimSpace(req.InstanceID)
	operatorID := strings.TrimSpace(req.OperatorID)
	operatorRole := normalizeOpsOperatorRole(req.OperatorRole)
	actionType := normalizeIsolateQuarantineActionType(req.ActionType)

	decision := IsolateQuarantineDecision{
		Decision:      IsolateQuarantineDecisionDeny,
		Allowed:       false,
		TenantID:      tenantID,
		InstanceID:    instanceID,
		ActionType:    actionType,
		OperatorID:    operatorID,
		OperatorRole:  operatorRole,
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		Reason:        IsolateQuarantineReasonAllowed,
		CheckedAt:     now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = IsolateQuarantineReasonMissingTenant
		r.appendAudit(tenantID, "", instanceID, "", actionType, IsolateQuarantineAuditEventDenied, decision, req)
		return IsolateQuarantineActionRecord{}, decision, ErrIsolateQuarantineMissingTenant
	}

	if r.registry == nil {
		decision.Reason = IsolateQuarantineReasonMissingRegistry
		r.appendAudit(tenantID, "", instanceID, "", actionType, IsolateQuarantineAuditEventDenied, decision, req)
		return IsolateQuarantineActionRecord{}, decision, ErrIsolateQuarantineMissingRegistry
	}

	if instanceID == "" {
		decision.Reason = IsolateQuarantineReasonMissingInstance
		r.appendAudit(tenantID, "", instanceID, "", actionType, IsolateQuarantineAuditEventDenied, decision, req)
		return IsolateQuarantineActionRecord{}, decision, ErrIsolateQuarantineMissingInstance
	}

	if actionType == "" || !r.actionTypeAllowed(actionType) {
		decision.Reason = IsolateQuarantineReasonInvalidActionType
		r.appendAudit(tenantID, "", instanceID, "", actionType, IsolateQuarantineAuditEventDenied, decision, req)
		return IsolateQuarantineActionRecord{}, decision, ErrIsolateQuarantineInvalidActionType
	}

	if operatorID == "" {
		decision.Reason = IsolateQuarantineReasonMissingOperator
		r.appendAudit(tenantID, "", instanceID, "", actionType, IsolateQuarantineAuditEventDenied, decision, req)
		return IsolateQuarantineActionRecord{}, decision, ErrIsolateQuarantineMissingOperator
	}

	if operatorRole == "" {
		decision.Reason = IsolateQuarantineReasonMissingOperatorRole
		r.appendAudit(tenantID, "", instanceID, "", actionType, IsolateQuarantineAuditEventDenied, decision, req)
		return IsolateQuarantineActionRecord{}, decision, ErrIsolateQuarantineMissingOperatorRole
	}

	if !r.operatorRoleAllowed(operatorRole) {
		decision.Reason = IsolateQuarantineReasonUnauthorizedOperator
		r.appendAudit(tenantID, "", instanceID, "", actionType, IsolateQuarantineAuditEventDenied, decision, req)
		return IsolateQuarantineActionRecord{}, decision, ErrIsolateQuarantineUnauthorizedOperator
	}

	instance, err := r.getTenantInstance(tenantID, instanceID)
	if err != nil {
		if errors.Is(err, ErrIsolateQuarantineCrossTenant) {
			decision.Reason = IsolateQuarantineReasonCrossTenant
			r.appendAudit(tenantID, "", instanceID, "", actionType, IsolateQuarantineAuditEventDenied, decision, req)
			return IsolateQuarantineActionRecord{}, decision, ErrIsolateQuarantineCrossTenant
		}
		decision.Reason = IsolateQuarantineReasonInstanceNotFound
		r.appendAudit(tenantID, "", instanceID, "", actionType, IsolateQuarantineAuditEventDenied, decision, req)
		return IsolateQuarantineActionRecord{}, decision, ErrIsolateQuarantineInstanceNotFound
	}

	actionState := IsolateQuarantineStateForType(actionType)

	action := IsolateQuarantineActionRecord{
		TenantID:       tenantID,
		ActionID:       NewIsolateQuarantineActionID(),
		ServiceID:      instance.ServiceID,
		InstanceID:     instance.InstanceID,
		ServiceName:    instance.ServiceName,
		ActionType:     actionType,
		ActionState:    actionState,
		PreviousStatus: instance.Status,
		OperatorID:     operatorID,
		OperatorRole:   operatorRole,
		Reason:         strings.TrimSpace(req.Reason),
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		RequestedAt:    now,
		UpdatedAt:      now,
	}

	if r.config.MetadataBridgeEnabled {
		if err := r.writeActionMetadata(action); err != nil {
			decision.Reason = IsolateQuarantineReasonMetadataBridgeFailed
			r.appendAudit(tenantID, action.ActionID, instanceID, instance.ServiceName, actionType, IsolateQuarantineAuditEventDenied, decision, req)
			return IsolateQuarantineActionRecord{}, decision, ErrIsolateQuarantineMetadataBridgeFailed
		}
	}

	r.mu.Lock()
	r.actions[action.ActionID] = action
	r.mu.Unlock()

	decision.Decision = IsolateQuarantineDecisionAllow
	decision.Allowed = true
	decision.ActionID = action.ActionID
	decision.ServiceID = action.ServiceID
	decision.ServiceName = action.ServiceName
	decision.ActionState = action.ActionState
	decision.PreviousStatus = action.PreviousStatus
	decision.Reason = IsolateQuarantineReasonAllowed

	r.appendAudit(tenantID, action.ActionID, instanceID, instance.ServiceName, actionType, IsolateQuarantineAuditEventRequested, decision, req)

	return action, decision, nil
}

func (r *IsolateQuarantineActionRuntime) GetAction(tenantID string, actionID string) (IsolateQuarantineActionRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	actionID = strings.TrimSpace(actionID)

	if tenantID == "" {
		return IsolateQuarantineActionRecord{}, ErrIsolateQuarantineMissingTenant
	}
	if actionID == "" {
		return IsolateQuarantineActionRecord{}, ErrIsolateQuarantineMissingInstance
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	action, ok := r.actions[actionID]
	if !ok {
		return IsolateQuarantineActionRecord{}, ErrIsolateQuarantineInstanceNotFound
	}

	if action.TenantID != tenantID {
		return IsolateQuarantineActionRecord{}, ErrIsolateQuarantineCrossTenant
	}

	return action, nil
}

func (r *IsolateQuarantineActionRuntime) ListTenantActions(tenantID string) ([]IsolateQuarantineActionRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrIsolateQuarantineMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]IsolateQuarantineActionRecord, 0)
	for _, action := range r.actions {
		if action.TenantID == tenantID {
			out = append(out, action)
		}
	}

	return out, nil
}

func (r *IsolateQuarantineActionRuntime) ListTenantAuditEvents(tenantID string) ([]IsolateQuarantineAuditEvent, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrIsolateQuarantineMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]IsolateQuarantineAuditEvent, 0)
	for _, event := range r.audit {
		if event.TenantID == tenantID {
			out = append(out, event)
		}
	}

	return out, nil
}

func (r *IsolateQuarantineActionRuntime) getTenantInstance(tenantID string, instanceID string) (ServiceInstanceRecord, error) {
	r.registry.mu.RLock()
	defer r.registry.mu.RUnlock()

	instance, ok := r.registry.instances[serviceInstanceKey(tenantID, instanceID)]
	if ok {
		return instance, nil
	}

	if r.registry.instanceExistsInAnotherTenantLocked(tenantID, instanceID) {
		return ServiceInstanceRecord{}, ErrIsolateQuarantineCrossTenant
	}

	return ServiceInstanceRecord{}, ErrIsolateQuarantineInstanceNotFound
}

func (r *IsolateQuarantineActionRuntime) writeActionMetadata(action IsolateQuarantineActionRecord) error {
	metadata := map[string]string{
		"isolate_quarantine_action_id":    action.ActionID,
		"isolate_quarantine_action_type":  action.ActionType,
		"isolate_quarantine_action_state": action.ActionState,
		"isolate_quarantine_operator_id":  action.OperatorID,
		"isolate_quarantine_requested_at": action.RequestedAt,
	}

	for key, value := range metadata {
		_, decision, err := r.registry.UpsertMetadata(InstanceMetadataUpsertRequest{
			TenantID:      action.TenantID,
			InstanceID:    action.InstanceID,
			Key:           key,
			Value:         value,
			Visibility:    r.config.MetadataVisibility,
			Source:        "isolate_quarantine_action_runtime",
			CorrelationID: action.CorrelationID,
		})
		if err != nil || !decision.Allowed {
			return ErrIsolateQuarantineMetadataBridgeFailed
		}
	}

	return nil
}

func (r *IsolateQuarantineActionRuntime) appendAudit(tenantID string, actionID string, instanceID string, serviceName string, actionType string, eventType string, decision IsolateQuarantineDecision, req IsolateQuarantineActionRequest) {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.audit = append(r.audit, IsolateQuarantineAuditEvent{
		TenantID:      strings.TrimSpace(tenantID),
		EventID:       NewIsolateQuarantineAuditEventID(),
		ActionID:      strings.TrimSpace(actionID),
		InstanceID:    strings.TrimSpace(instanceID),
		ServiceName:   strings.TrimSpace(serviceName),
		ActionType:    normalizeIsolateQuarantineActionType(actionType),
		EventType:     eventType,
		Decision:      decision.Decision,
		Reason:        decision.Reason,
		OperatorID:    strings.TrimSpace(req.OperatorID),
		OperatorRole:  normalizeOpsOperatorRole(req.OperatorRole),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		CreatedAt:     time.Now().UTC().Format(time.RFC3339Nano),
	})
}

func (r *IsolateQuarantineActionRuntime) operatorRoleAllowed(role string) bool {
	role = normalizeOpsOperatorRole(role)
	for _, allowed := range r.config.AllowedOperatorRoles {
		if strings.EqualFold(strings.TrimSpace(allowed), role) {
			return true
		}
	}
	return false
}

func (r *IsolateQuarantineActionRuntime) actionTypeAllowed(actionType string) bool {
	actionType = normalizeIsolateQuarantineActionType(actionType)
	for _, allowed := range r.config.AllowedActionTypes {
		if strings.EqualFold(strings.TrimSpace(allowed), actionType) {
			return true
		}
	}
	return false
}

func normalizeIsolateQuarantineActionType(actionType string) string {
	return strings.ToUpper(strings.TrimSpace(actionType))
}

func IsolateQuarantineStateForType(actionType string) string {
	switch normalizeIsolateQuarantineActionType(actionType) {
	case IsolateQuarantineActionTypeIsolate:
		return IsolateQuarantineStateIsolateRequested
	case IsolateQuarantineActionTypeQuarantine:
		return IsolateQuarantineStateQuarantineRequested
	default:
		return IsolateQuarantineStateDenied
	}
}

func NewIsolateQuarantineActionID() string {
	return randomOpsRuntimeID("isolate_quarantine_action_")
}

func NewIsolateQuarantineAuditEventID() string {
	return randomOpsRuntimeID("isolate_quarantine_audit_")
}
