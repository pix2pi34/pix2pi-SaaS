package opsruntime

import (
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	OperatorRolePlatformAdmin = "PLATFORM_ADMIN"
	OperatorRoleOpsAdmin      = "OPS_ADMIN"
	OperatorRoleSRE           = "SRE"
	OperatorRoleViewer        = "VIEWER"

	RestartActionStateRequested = "RESTART_REQUESTED"
	RestartActionStateDenied    = "RESTART_DENIED"

	RestartActionAuditEventRequested = "RESTART_ACTION_REQUESTED"
	RestartActionAuditEventDenied    = "RESTART_ACTION_DENIED"

	RestartActionDecisionAllow = "ALLOW"
	RestartActionDecisionDeny  = "DENY"

	RestartActionReasonAllowed              = "RESTART_ACTION_ALLOWED"
	RestartActionReasonMissingTenant        = "RESTART_ACTION_MISSING_TENANT"
	RestartActionReasonMissingRegistry      = "RESTART_ACTION_MISSING_REGISTRY"
	RestartActionReasonMissingInstance      = "RESTART_ACTION_MISSING_INSTANCE"
	RestartActionReasonMissingOperator      = "RESTART_ACTION_MISSING_OPERATOR"
	RestartActionReasonMissingOperatorRole  = "RESTART_ACTION_MISSING_OPERATOR_ROLE"
	RestartActionReasonUnauthorizedOperator = "RESTART_ACTION_UNAUTHORIZED_OPERATOR"
	RestartActionReasonCrossTenant          = "RESTART_ACTION_CROSS_TENANT_DENIED"
	RestartActionReasonInstanceNotFound     = "RESTART_ACTION_INSTANCE_NOT_FOUND"
	RestartActionReasonStatusNotRestartable = "RESTART_ACTION_STATUS_NOT_RESTARTABLE"
	RestartActionReasonMetadataBridgeFailed = "RESTART_ACTION_METADATA_BRIDGE_FAILED"
)

var (
	ErrRestartActionMissingTenant        = errors.New("missing restart action tenant id")
	ErrRestartActionMissingRegistry      = errors.New("missing restart action registry")
	ErrRestartActionMissingInstance      = errors.New("missing restart action instance id")
	ErrRestartActionMissingOperator      = errors.New("missing restart action operator id")
	ErrRestartActionMissingOperatorRole  = errors.New("missing restart action operator role")
	ErrRestartActionUnauthorizedOperator = errors.New("unauthorized restart action operator")
	ErrRestartActionCrossTenant          = errors.New("cross-tenant restart action denied")
	ErrRestartActionInstanceNotFound     = errors.New("restart action instance not found")
	ErrRestartActionStatusNotRestartable = errors.New("service instance status is not restartable")
	ErrRestartActionMetadataBridgeFailed = errors.New("restart action metadata bridge failed")
)

type RestartActionRuntimeConfig struct {
	RequireTenant         bool     `json:"require_tenant"`
	AllowedOperatorRoles  []string `json:"allowed_operator_roles"`
	RestartableStatuses   []string `json:"restartable_statuses"`
	MetadataBridgeEnabled bool     `json:"metadata_bridge_enabled"`
	MetadataVisibility    string   `json:"metadata_visibility"`
}

func DefaultRestartActionRuntimeConfig() RestartActionRuntimeConfig {
	return RestartActionRuntimeConfig{
		RequireTenant: true,
		AllowedOperatorRoles: []string{
			OperatorRolePlatformAdmin,
			OperatorRoleOpsAdmin,
			OperatorRoleSRE,
		},
		RestartableStatuses: []string{
			ServiceInstanceStatusHealthy,
			ServiceInstanceStatusUnhealthy,
			ServiceInstanceStatusStale,
		},
		MetadataBridgeEnabled: true,
		MetadataVisibility:    InstanceMetadataVisibilityInternal,
	}
}

type RestartActionRequest struct {
	TenantID      string `json:"tenant_id"`
	InstanceID    string `json:"instance_id"`
	OperatorID    string `json:"operator_id"`
	OperatorRole  string `json:"operator_role"`
	Reason        string `json:"reason,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
}

type RestartActionRecord struct {
	TenantID       string `json:"tenant_id"`
	ActionID       string `json:"action_id"`
	ServiceID      string `json:"service_id"`
	InstanceID     string `json:"instance_id"`
	ServiceName    string `json:"service_name"`
	PreviousStatus string `json:"previous_status"`
	ActionState    string `json:"action_state"`
	OperatorID     string `json:"operator_id"`
	OperatorRole   string `json:"operator_role"`
	Reason         string `json:"reason,omitempty"`
	CorrelationID  string `json:"correlation_id,omitempty"`
	RequestedAt    string `json:"requested_at"`
	UpdatedAt      string `json:"updated_at"`
}

type RestartActionAuditEvent struct {
	TenantID      string `json:"tenant_id"`
	EventID       string `json:"event_id"`
	ActionID      string `json:"action_id,omitempty"`
	InstanceID    string `json:"instance_id,omitempty"`
	ServiceName   string `json:"service_name,omitempty"`
	EventType     string `json:"event_type"`
	Decision      string `json:"decision"`
	Reason        string `json:"reason"`
	OperatorID    string `json:"operator_id,omitempty"`
	OperatorRole  string `json:"operator_role,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
	CreatedAt     string `json:"created_at"`
}

type RestartActionDecision struct {
	Decision       string `json:"decision"`
	Allowed        bool   `json:"allowed"`
	TenantID       string `json:"tenant_id"`
	ActionID       string `json:"action_id,omitempty"`
	ServiceID      string `json:"service_id,omitempty"`
	InstanceID     string `json:"instance_id,omitempty"`
	ServiceName    string `json:"service_name,omitempty"`
	OperatorID     string `json:"operator_id,omitempty"`
	OperatorRole   string `json:"operator_role,omitempty"`
	PreviousStatus string `json:"previous_status,omitempty"`
	ActionState    string `json:"action_state,omitempty"`
	CorrelationID  string `json:"correlation_id,omitempty"`
	Reason         string `json:"reason"`
	CheckedAt      string `json:"checked_at"`
}

type RestartActionRuntime struct {
	config   RestartActionRuntimeConfig
	registry *InstanceMetadataRuntime
	mu       sync.RWMutex
	actions  map[string]RestartActionRecord
	audit    []RestartActionAuditEvent
}

func NewRestartActionRuntime(config RestartActionRuntimeConfig, registry *InstanceMetadataRuntime) *RestartActionRuntime {
	defaults := DefaultRestartActionRuntimeConfig()

	if len(config.AllowedOperatorRoles) == 0 {
		config.AllowedOperatorRoles = defaults.AllowedOperatorRoles
	}
	if len(config.RestartableStatuses) == 0 {
		config.RestartableStatuses = defaults.RestartableStatuses
	}
	if strings.TrimSpace(config.MetadataVisibility) == "" {
		config.MetadataVisibility = defaults.MetadataVisibility
	}

	return &RestartActionRuntime{
		config:   config,
		registry: registry,
		actions:  make(map[string]RestartActionRecord),
		audit:    make([]RestartActionAuditEvent, 0),
	}
}

func (r *RestartActionRuntime) RequestRestart(req RestartActionRequest) (RestartActionRecord, RestartActionDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	instanceID := strings.TrimSpace(req.InstanceID)
	operatorID := strings.TrimSpace(req.OperatorID)
	operatorRole := normalizeOpsOperatorRole(req.OperatorRole)

	decision := RestartActionDecision{
		Decision:      RestartActionDecisionDeny,
		Allowed:       false,
		TenantID:      tenantID,
		InstanceID:    instanceID,
		OperatorID:    operatorID,
		OperatorRole:  operatorRole,
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		Reason:        RestartActionReasonAllowed,
		CheckedAt:     now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = RestartActionReasonMissingTenant
		r.appendAudit(tenantID, "", instanceID, "", RestartActionAuditEventDenied, decision, req)
		return RestartActionRecord{}, decision, ErrRestartActionMissingTenant
	}

	if r.registry == nil {
		decision.Reason = RestartActionReasonMissingRegistry
		r.appendAudit(tenantID, "", instanceID, "", RestartActionAuditEventDenied, decision, req)
		return RestartActionRecord{}, decision, ErrRestartActionMissingRegistry
	}

	if instanceID == "" {
		decision.Reason = RestartActionReasonMissingInstance
		r.appendAudit(tenantID, "", instanceID, "", RestartActionAuditEventDenied, decision, req)
		return RestartActionRecord{}, decision, ErrRestartActionMissingInstance
	}

	if operatorID == "" {
		decision.Reason = RestartActionReasonMissingOperator
		r.appendAudit(tenantID, "", instanceID, "", RestartActionAuditEventDenied, decision, req)
		return RestartActionRecord{}, decision, ErrRestartActionMissingOperator
	}

	if operatorRole == "" {
		decision.Reason = RestartActionReasonMissingOperatorRole
		r.appendAudit(tenantID, "", instanceID, "", RestartActionAuditEventDenied, decision, req)
		return RestartActionRecord{}, decision, ErrRestartActionMissingOperatorRole
	}

	if !r.operatorRoleAllowed(operatorRole) {
		decision.Reason = RestartActionReasonUnauthorizedOperator
		r.appendAudit(tenantID, "", instanceID, "", RestartActionAuditEventDenied, decision, req)
		return RestartActionRecord{}, decision, ErrRestartActionUnauthorizedOperator
	}

	instance, err := r.getTenantInstance(tenantID, instanceID)
	if err != nil {
		if errors.Is(err, ErrRestartActionCrossTenant) {
			decision.Reason = RestartActionReasonCrossTenant
			r.appendAudit(tenantID, "", instanceID, "", RestartActionAuditEventDenied, decision, req)
			return RestartActionRecord{}, decision, ErrRestartActionCrossTenant
		}
		decision.Reason = RestartActionReasonInstanceNotFound
		r.appendAudit(tenantID, "", instanceID, "", RestartActionAuditEventDenied, decision, req)
		return RestartActionRecord{}, decision, ErrRestartActionInstanceNotFound
	}

	decision.ServiceID = instance.ServiceID
	decision.ServiceName = instance.ServiceName
	decision.PreviousStatus = instance.Status

	if !r.restartableStatus(instance.Status) {
		decision.Reason = RestartActionReasonStatusNotRestartable
		r.appendAudit(tenantID, "", instanceID, instance.ServiceName, RestartActionAuditEventDenied, decision, req)
		return RestartActionRecord{}, decision, ErrRestartActionStatusNotRestartable
	}

	action := RestartActionRecord{
		TenantID:       tenantID,
		ActionID:       NewRestartActionID(),
		ServiceID:      instance.ServiceID,
		InstanceID:     instance.InstanceID,
		ServiceName:    instance.ServiceName,
		PreviousStatus: instance.Status,
		ActionState:    RestartActionStateRequested,
		OperatorID:     operatorID,
		OperatorRole:   operatorRole,
		Reason:         strings.TrimSpace(req.Reason),
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		RequestedAt:    now,
		UpdatedAt:      now,
	}

	if r.config.MetadataBridgeEnabled {
		if err := r.writeRestartMetadata(action); err != nil {
			decision.Reason = RestartActionReasonMetadataBridgeFailed
			r.appendAudit(tenantID, action.ActionID, instanceID, instance.ServiceName, RestartActionAuditEventDenied, decision, req)
			return RestartActionRecord{}, decision, ErrRestartActionMetadataBridgeFailed
		}
	}

	r.mu.Lock()
	r.actions[action.ActionID] = action
	r.mu.Unlock()

	decision.Decision = RestartActionDecisionAllow
	decision.Allowed = true
	decision.ActionID = action.ActionID
	decision.ActionState = action.ActionState
	decision.Reason = RestartActionReasonAllowed

	r.appendAudit(tenantID, action.ActionID, instanceID, instance.ServiceName, RestartActionAuditEventRequested, decision, req)

	return action, decision, nil
}

func (r *RestartActionRuntime) GetAction(tenantID string, actionID string) (RestartActionRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	actionID = strings.TrimSpace(actionID)

	if tenantID == "" {
		return RestartActionRecord{}, ErrRestartActionMissingTenant
	}
	if actionID == "" {
		return RestartActionRecord{}, ErrRestartActionMissingInstance
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	action, ok := r.actions[actionID]
	if !ok {
		return RestartActionRecord{}, ErrRestartActionInstanceNotFound
	}

	if action.TenantID != tenantID {
		return RestartActionRecord{}, ErrRestartActionCrossTenant
	}

	return action, nil
}

func (r *RestartActionRuntime) ListTenantActions(tenantID string) ([]RestartActionRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrRestartActionMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]RestartActionRecord, 0)
	for _, action := range r.actions {
		if action.TenantID == tenantID {
			out = append(out, action)
		}
	}

	return out, nil
}

func (r *RestartActionRuntime) ListTenantAuditEvents(tenantID string) ([]RestartActionAuditEvent, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrRestartActionMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]RestartActionAuditEvent, 0)
	for _, event := range r.audit {
		if event.TenantID == tenantID {
			out = append(out, event)
		}
	}

	return out, nil
}

func (r *RestartActionRuntime) getTenantInstance(tenantID string, instanceID string) (ServiceInstanceRecord, error) {
	r.registry.mu.RLock()
	defer r.registry.mu.RUnlock()

	instance, ok := r.registry.instances[serviceInstanceKey(tenantID, instanceID)]
	if ok {
		return instance, nil
	}

	if r.registry.instanceExistsInAnotherTenantLocked(tenantID, instanceID) {
		return ServiceInstanceRecord{}, ErrRestartActionCrossTenant
	}

	return ServiceInstanceRecord{}, ErrRestartActionInstanceNotFound
}

func (r *RestartActionRuntime) writeRestartMetadata(action RestartActionRecord) error {
	metadata := map[string]string{
		"restart_action_id":    action.ActionID,
		"restart_requested_at": action.RequestedAt,
		"restart_operator_id":  action.OperatorID,
		"restart_action_state": action.ActionState,
	}

	for key, value := range metadata {
		_, decision, err := r.registry.UpsertMetadata(InstanceMetadataUpsertRequest{
			TenantID:      action.TenantID,
			InstanceID:    action.InstanceID,
			Key:           key,
			Value:         value,
			Visibility:    r.config.MetadataVisibility,
			Source:        "restart_action_runtime",
			CorrelationID: action.CorrelationID,
		})
		if err != nil || !decision.Allowed {
			return ErrRestartActionMetadataBridgeFailed
		}
	}

	return nil
}

func (r *RestartActionRuntime) appendAudit(tenantID string, actionID string, instanceID string, serviceName string, eventType string, decision RestartActionDecision, req RestartActionRequest) {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.audit = append(r.audit, RestartActionAuditEvent{
		TenantID:      strings.TrimSpace(tenantID),
		EventID:       NewRestartActionAuditEventID(),
		ActionID:      strings.TrimSpace(actionID),
		InstanceID:    strings.TrimSpace(instanceID),
		ServiceName:   strings.TrimSpace(serviceName),
		EventType:     eventType,
		Decision:      decision.Decision,
		Reason:        decision.Reason,
		OperatorID:    strings.TrimSpace(req.OperatorID),
		OperatorRole:  normalizeOpsOperatorRole(req.OperatorRole),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		CreatedAt:     time.Now().UTC().Format(time.RFC3339Nano),
	})
}

func (r *RestartActionRuntime) operatorRoleAllowed(role string) bool {
	role = normalizeOpsOperatorRole(role)
	for _, allowed := range r.config.AllowedOperatorRoles {
		if strings.EqualFold(strings.TrimSpace(allowed), role) {
			return true
		}
	}
	return false
}

func (r *RestartActionRuntime) restartableStatus(status string) bool {
	status = normalizeInstanceStatus(status)
	for _, allowed := range r.config.RestartableStatuses {
		if strings.EqualFold(strings.TrimSpace(allowed), status) {
			return true
		}
	}
	return false
}

func normalizeOpsOperatorRole(role string) string {
	return strings.ToUpper(strings.TrimSpace(role))
}

func NewRestartActionID() string {
	return randomOpsRuntimeID("restart_action_")
}

func NewRestartActionAuditEventID() string {
	return randomOpsRuntimeID("restart_audit_")
}
