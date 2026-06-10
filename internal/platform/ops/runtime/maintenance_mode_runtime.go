package opsruntime

import (
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	MaintenanceModeActionEnable  = "ENABLE_MAINTENANCE"
	MaintenanceModeActionDisable = "DISABLE_MAINTENANCE"

	MaintenanceModeStateEnabled  = "MAINTENANCE_ENABLED"
	MaintenanceModeStateDisabled = "MAINTENANCE_DISABLED"
	MaintenanceModeStateDenied   = "MAINTENANCE_DENIED"

	MaintenanceModeAuditEventEnabled  = "MAINTENANCE_MODE_ENABLED"
	MaintenanceModeAuditEventDisabled = "MAINTENANCE_MODE_DISABLED"
	MaintenanceModeAuditEventDenied   = "MAINTENANCE_MODE_DENIED"

	MaintenanceModeDecisionAllow = "ALLOW"
	MaintenanceModeDecisionDeny  = "DENY"

	MaintenanceModeReasonAllowed              = "MAINTENANCE_MODE_ALLOWED"
	MaintenanceModeReasonMissingTenant        = "MAINTENANCE_MODE_MISSING_TENANT"
	MaintenanceModeReasonMissingRegistry      = "MAINTENANCE_MODE_MISSING_REGISTRY"
	MaintenanceModeReasonMissingInstance      = "MAINTENANCE_MODE_MISSING_INSTANCE"
	MaintenanceModeReasonMissingOperator      = "MAINTENANCE_MODE_MISSING_OPERATOR"
	MaintenanceModeReasonMissingOperatorRole  = "MAINTENANCE_MODE_MISSING_OPERATOR_ROLE"
	MaintenanceModeReasonUnauthorizedOperator = "MAINTENANCE_MODE_UNAUTHORIZED_OPERATOR"
	MaintenanceModeReasonInvalidAction        = "MAINTENANCE_MODE_INVALID_ACTION"
	MaintenanceModeReasonCrossTenant          = "MAINTENANCE_MODE_CROSS_TENANT_DENIED"
	MaintenanceModeReasonInstanceNotFound     = "MAINTENANCE_MODE_INSTANCE_NOT_FOUND"
	MaintenanceModeReasonMetadataBridgeFailed = "MAINTENANCE_MODE_METADATA_BRIDGE_FAILED"
)

var (
	ErrMaintenanceModeMissingTenant        = errors.New("missing maintenance mode tenant id")
	ErrMaintenanceModeMissingRegistry      = errors.New("missing maintenance mode registry")
	ErrMaintenanceModeMissingInstance      = errors.New("missing maintenance mode instance id")
	ErrMaintenanceModeMissingOperator      = errors.New("missing maintenance mode operator id")
	ErrMaintenanceModeMissingOperatorRole  = errors.New("missing maintenance mode operator role")
	ErrMaintenanceModeUnauthorizedOperator = errors.New("unauthorized maintenance mode operator")
	ErrMaintenanceModeInvalidAction        = errors.New("invalid maintenance mode action")
	ErrMaintenanceModeCrossTenant          = errors.New("cross-tenant maintenance mode action denied")
	ErrMaintenanceModeInstanceNotFound     = errors.New("maintenance mode instance not found")
	ErrMaintenanceModeMetadataBridgeFailed = errors.New("maintenance mode metadata bridge failed")
)

type MaintenanceModeRuntimeConfig struct {
	RequireTenant         bool     `json:"require_tenant"`
	AllowedOperatorRoles  []string `json:"allowed_operator_roles"`
	AllowedActions        []string `json:"allowed_actions"`
	MetadataBridgeEnabled bool     `json:"metadata_bridge_enabled"`
	MetadataVisibility    string   `json:"metadata_visibility"`
}

func DefaultMaintenanceModeRuntimeConfig() MaintenanceModeRuntimeConfig {
	return MaintenanceModeRuntimeConfig{
		RequireTenant: true,
		AllowedOperatorRoles: []string{
			OperatorRolePlatformAdmin,
			OperatorRoleOpsAdmin,
			OperatorRoleSRE,
		},
		AllowedActions: []string{
			MaintenanceModeActionEnable,
			MaintenanceModeActionDisable,
		},
		MetadataBridgeEnabled: true,
		MetadataVisibility:    InstanceMetadataVisibilityInternal,
	}
}

type MaintenanceModeRequest struct {
	TenantID      string `json:"tenant_id"`
	InstanceID    string `json:"instance_id"`
	Action        string `json:"action"`
	OperatorID    string `json:"operator_id"`
	OperatorRole  string `json:"operator_role"`
	Reason        string `json:"reason,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
}

type MaintenanceModeRecord struct {
	TenantID       string `json:"tenant_id"`
	MaintenanceID  string `json:"maintenance_id"`
	ServiceID      string `json:"service_id"`
	InstanceID     string `json:"instance_id"`
	ServiceName    string `json:"service_name"`
	Action         string `json:"action"`
	ModeState      string `json:"mode_state"`
	PreviousStatus string `json:"previous_status"`
	OperatorID     string `json:"operator_id"`
	OperatorRole   string `json:"operator_role"`
	Reason         string `json:"reason,omitempty"`
	CorrelationID  string `json:"correlation_id,omitempty"`
	RequestedAt    string `json:"requested_at"`
	UpdatedAt      string `json:"updated_at"`
}

type MaintenanceModeAuditEvent struct {
	TenantID      string `json:"tenant_id"`
	EventID       string `json:"event_id"`
	MaintenanceID string `json:"maintenance_id,omitempty"`
	InstanceID    string `json:"instance_id,omitempty"`
	ServiceName   string `json:"service_name,omitempty"`
	Action        string `json:"action,omitempty"`
	EventType     string `json:"event_type"`
	Decision      string `json:"decision"`
	Reason        string `json:"reason"`
	OperatorID    string `json:"operator_id,omitempty"`
	OperatorRole  string `json:"operator_role,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
	CreatedAt     string `json:"created_at"`
}

type MaintenanceModeDecision struct {
	Decision       string `json:"decision"`
	Allowed        bool   `json:"allowed"`
	TenantID       string `json:"tenant_id"`
	MaintenanceID  string `json:"maintenance_id,omitempty"`
	ServiceID      string `json:"service_id,omitempty"`
	InstanceID     string `json:"instance_id,omitempty"`
	ServiceName    string `json:"service_name,omitempty"`
	Action         string `json:"action,omitempty"`
	ModeState      string `json:"mode_state,omitempty"`
	PreviousStatus string `json:"previous_status,omitempty"`
	OperatorID     string `json:"operator_id,omitempty"`
	OperatorRole   string `json:"operator_role,omitempty"`
	CorrelationID  string `json:"correlation_id,omitempty"`
	Reason         string `json:"reason"`
	CheckedAt      string `json:"checked_at"`
}

type MaintenanceModeRuntime struct {
	config   MaintenanceModeRuntimeConfig
	registry *InstanceMetadataRuntime
	mu       sync.RWMutex
	records  map[string]MaintenanceModeRecord
	audit    []MaintenanceModeAuditEvent
}

func NewMaintenanceModeRuntime(config MaintenanceModeRuntimeConfig, registry *InstanceMetadataRuntime) *MaintenanceModeRuntime {
	defaults := DefaultMaintenanceModeRuntimeConfig()

	if len(config.AllowedOperatorRoles) == 0 {
		config.AllowedOperatorRoles = defaults.AllowedOperatorRoles
	}
	if len(config.AllowedActions) == 0 {
		config.AllowedActions = defaults.AllowedActions
	}
	if strings.TrimSpace(config.MetadataVisibility) == "" {
		config.MetadataVisibility = defaults.MetadataVisibility
	}

	return &MaintenanceModeRuntime{
		config:   config,
		registry: registry,
		records:  make(map[string]MaintenanceModeRecord),
		audit:    make([]MaintenanceModeAuditEvent, 0),
	}
}

func (r *MaintenanceModeRuntime) ApplyMaintenanceMode(req MaintenanceModeRequest) (MaintenanceModeRecord, MaintenanceModeDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	instanceID := strings.TrimSpace(req.InstanceID)
	operatorID := strings.TrimSpace(req.OperatorID)
	operatorRole := normalizeOpsOperatorRole(req.OperatorRole)
	action := normalizeMaintenanceModeAction(req.Action)

	decision := MaintenanceModeDecision{
		Decision:      MaintenanceModeDecisionDeny,
		Allowed:       false,
		TenantID:      tenantID,
		InstanceID:    instanceID,
		Action:        action,
		OperatorID:    operatorID,
		OperatorRole:  operatorRole,
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		Reason:        MaintenanceModeReasonAllowed,
		CheckedAt:     now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = MaintenanceModeReasonMissingTenant
		r.appendAudit(tenantID, "", instanceID, "", action, MaintenanceModeAuditEventDenied, decision, req)
		return MaintenanceModeRecord{}, decision, ErrMaintenanceModeMissingTenant
	}

	if r.registry == nil {
		decision.Reason = MaintenanceModeReasonMissingRegistry
		r.appendAudit(tenantID, "", instanceID, "", action, MaintenanceModeAuditEventDenied, decision, req)
		return MaintenanceModeRecord{}, decision, ErrMaintenanceModeMissingRegistry
	}

	if instanceID == "" {
		decision.Reason = MaintenanceModeReasonMissingInstance
		r.appendAudit(tenantID, "", instanceID, "", action, MaintenanceModeAuditEventDenied, decision, req)
		return MaintenanceModeRecord{}, decision, ErrMaintenanceModeMissingInstance
	}

	if action == "" || !r.actionAllowed(action) {
		decision.Reason = MaintenanceModeReasonInvalidAction
		r.appendAudit(tenantID, "", instanceID, "", action, MaintenanceModeAuditEventDenied, decision, req)
		return MaintenanceModeRecord{}, decision, ErrMaintenanceModeInvalidAction
	}

	if operatorID == "" {
		decision.Reason = MaintenanceModeReasonMissingOperator
		r.appendAudit(tenantID, "", instanceID, "", action, MaintenanceModeAuditEventDenied, decision, req)
		return MaintenanceModeRecord{}, decision, ErrMaintenanceModeMissingOperator
	}

	if operatorRole == "" {
		decision.Reason = MaintenanceModeReasonMissingOperatorRole
		r.appendAudit(tenantID, "", instanceID, "", action, MaintenanceModeAuditEventDenied, decision, req)
		return MaintenanceModeRecord{}, decision, ErrMaintenanceModeMissingOperatorRole
	}

	if !r.operatorRoleAllowed(operatorRole) {
		decision.Reason = MaintenanceModeReasonUnauthorizedOperator
		r.appendAudit(tenantID, "", instanceID, "", action, MaintenanceModeAuditEventDenied, decision, req)
		return MaintenanceModeRecord{}, decision, ErrMaintenanceModeUnauthorizedOperator
	}

	instance, err := r.getTenantInstance(tenantID, instanceID)
	if err != nil {
		if errors.Is(err, ErrMaintenanceModeCrossTenant) {
			decision.Reason = MaintenanceModeReasonCrossTenant
			r.appendAudit(tenantID, "", instanceID, "", action, MaintenanceModeAuditEventDenied, decision, req)
			return MaintenanceModeRecord{}, decision, ErrMaintenanceModeCrossTenant
		}
		decision.Reason = MaintenanceModeReasonInstanceNotFound
		r.appendAudit(tenantID, "", instanceID, "", action, MaintenanceModeAuditEventDenied, decision, req)
		return MaintenanceModeRecord{}, decision, ErrMaintenanceModeInstanceNotFound
	}

	modeState := MaintenanceModeStateForAction(action)

	record := MaintenanceModeRecord{
		TenantID:       tenantID,
		MaintenanceID:  NewMaintenanceModeID(),
		ServiceID:      instance.ServiceID,
		InstanceID:     instance.InstanceID,
		ServiceName:    instance.ServiceName,
		Action:         action,
		ModeState:      modeState,
		PreviousStatus: instance.Status,
		OperatorID:     operatorID,
		OperatorRole:   operatorRole,
		Reason:         strings.TrimSpace(req.Reason),
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		RequestedAt:    now,
		UpdatedAt:      now,
	}

	if r.config.MetadataBridgeEnabled {
		if err := r.writeMaintenanceMetadata(record); err != nil {
			decision.Reason = MaintenanceModeReasonMetadataBridgeFailed
			r.appendAudit(tenantID, record.MaintenanceID, instanceID, instance.ServiceName, action, MaintenanceModeAuditEventDenied, decision, req)
			return MaintenanceModeRecord{}, decision, ErrMaintenanceModeMetadataBridgeFailed
		}
	}

	r.mu.Lock()
	r.records[record.MaintenanceID] = record
	r.mu.Unlock()

	decision.Decision = MaintenanceModeDecisionAllow
	decision.Allowed = true
	decision.MaintenanceID = record.MaintenanceID
	decision.ServiceID = record.ServiceID
	decision.ServiceName = record.ServiceName
	decision.ModeState = record.ModeState
	decision.PreviousStatus = record.PreviousStatus
	decision.Reason = MaintenanceModeReasonAllowed

	eventType := MaintenanceModeAuditEventEnabled
	if action == MaintenanceModeActionDisable {
		eventType = MaintenanceModeAuditEventDisabled
	}
	r.appendAudit(tenantID, record.MaintenanceID, instanceID, instance.ServiceName, action, eventType, decision, req)

	return record, decision, nil
}

func (r *MaintenanceModeRuntime) GetMaintenanceRecord(tenantID string, maintenanceID string) (MaintenanceModeRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	maintenanceID = strings.TrimSpace(maintenanceID)

	if tenantID == "" {
		return MaintenanceModeRecord{}, ErrMaintenanceModeMissingTenant
	}
	if maintenanceID == "" {
		return MaintenanceModeRecord{}, ErrMaintenanceModeMissingInstance
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	record, ok := r.records[maintenanceID]
	if !ok {
		return MaintenanceModeRecord{}, ErrMaintenanceModeInstanceNotFound
	}

	if record.TenantID != tenantID {
		return MaintenanceModeRecord{}, ErrMaintenanceModeCrossTenant
	}

	return record, nil
}

func (r *MaintenanceModeRuntime) ListTenantMaintenanceRecords(tenantID string) ([]MaintenanceModeRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrMaintenanceModeMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]MaintenanceModeRecord, 0)
	for _, record := range r.records {
		if record.TenantID == tenantID {
			out = append(out, record)
		}
	}

	return out, nil
}

func (r *MaintenanceModeRuntime) ListTenantMaintenanceAuditEvents(tenantID string) ([]MaintenanceModeAuditEvent, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrMaintenanceModeMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]MaintenanceModeAuditEvent, 0)
	for _, event := range r.audit {
		if event.TenantID == tenantID {
			out = append(out, event)
		}
	}

	return out, nil
}

func (r *MaintenanceModeRuntime) getTenantInstance(tenantID string, instanceID string) (ServiceInstanceRecord, error) {
	r.registry.mu.RLock()
	defer r.registry.mu.RUnlock()

	instance, ok := r.registry.instances[serviceInstanceKey(tenantID, instanceID)]
	if ok {
		return instance, nil
	}

	if r.registry.instanceExistsInAnotherTenantLocked(tenantID, instanceID) {
		return ServiceInstanceRecord{}, ErrMaintenanceModeCrossTenant
	}

	return ServiceInstanceRecord{}, ErrMaintenanceModeInstanceNotFound
}

func (r *MaintenanceModeRuntime) writeMaintenanceMetadata(record MaintenanceModeRecord) error {
	metadata := map[string]string{
		"maintenance_mode_id":          record.MaintenanceID,
		"maintenance_mode_action":      record.Action,
		"maintenance_mode_state":       record.ModeState,
		"maintenance_mode_operator_id": record.OperatorID,
		"maintenance_mode_updated_at":  record.UpdatedAt,
	}

	for key, value := range metadata {
		_, decision, err := r.registry.UpsertMetadata(InstanceMetadataUpsertRequest{
			TenantID:      record.TenantID,
			InstanceID:    record.InstanceID,
			Key:           key,
			Value:         value,
			Visibility:    r.config.MetadataVisibility,
			Source:        "maintenance_mode_runtime",
			CorrelationID: record.CorrelationID,
		})
		if err != nil || !decision.Allowed {
			return ErrMaintenanceModeMetadataBridgeFailed
		}
	}

	return nil
}

func (r *MaintenanceModeRuntime) appendAudit(tenantID string, maintenanceID string, instanceID string, serviceName string, action string, eventType string, decision MaintenanceModeDecision, req MaintenanceModeRequest) {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.audit = append(r.audit, MaintenanceModeAuditEvent{
		TenantID:      strings.TrimSpace(tenantID),
		EventID:       NewMaintenanceModeAuditEventID(),
		MaintenanceID: strings.TrimSpace(maintenanceID),
		InstanceID:    strings.TrimSpace(instanceID),
		ServiceName:   strings.TrimSpace(serviceName),
		Action:        normalizeMaintenanceModeAction(action),
		EventType:     eventType,
		Decision:      decision.Decision,
		Reason:        decision.Reason,
		OperatorID:    strings.TrimSpace(req.OperatorID),
		OperatorRole:  normalizeOpsOperatorRole(req.OperatorRole),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		CreatedAt:     time.Now().UTC().Format(time.RFC3339Nano),
	})
}

func (r *MaintenanceModeRuntime) operatorRoleAllowed(role string) bool {
	role = normalizeOpsOperatorRole(role)
	for _, allowed := range r.config.AllowedOperatorRoles {
		if strings.EqualFold(strings.TrimSpace(allowed), role) {
			return true
		}
	}
	return false
}

func (r *MaintenanceModeRuntime) actionAllowed(action string) bool {
	action = normalizeMaintenanceModeAction(action)
	for _, allowed := range r.config.AllowedActions {
		if strings.EqualFold(strings.TrimSpace(allowed), action) {
			return true
		}
	}
	return false
}

func normalizeMaintenanceModeAction(action string) string {
	return strings.ToUpper(strings.TrimSpace(action))
}

func MaintenanceModeStateForAction(action string) string {
	switch normalizeMaintenanceModeAction(action) {
	case MaintenanceModeActionEnable:
		return MaintenanceModeStateEnabled
	case MaintenanceModeActionDisable:
		return MaintenanceModeStateDisabled
	default:
		return MaintenanceModeStateDenied
	}
}

func NewMaintenanceModeID() string {
	return randomOpsRuntimeID("maintenance_mode_")
}

func NewMaintenanceModeAuditEventID() string {
	return randomOpsRuntimeID("maintenance_audit_")
}
