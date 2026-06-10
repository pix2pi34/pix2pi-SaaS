package opsconsole

import (
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	MissionControlActionRestart     = "RESTART"
	MissionControlActionIsolate     = "ISOLATE"
	MissionControlActionQuarantine  = "QUARANTINE"
	MissionControlActionMaintenance = "MAINTENANCE"
	MissionControlActionNote        = "INCIDENT_NOTE"

	MissionControlActionStatusRequested = "REQUESTED"
	MissionControlActionStatusApproved  = "APPROVED"
	MissionControlActionStatusRejected  = "REJECTED"
	MissionControlActionStatusExecuted  = "EXECUTED"

	MissionControlOperatorRoleViewer   = "VIEWER"
	MissionControlOperatorRoleOperator = "OPERATOR"
	MissionControlOperatorRoleAdmin    = "ADMIN"

	MissionControlScreenDecisionAllow = "ALLOW"
	MissionControlScreenDecisionDeny  = "DENY"

	MissionControlScreenReasonAllowed             = "MISSION_CONTROL_SCREEN_ALLOWED"
	MissionControlScreenReasonMissingTenant       = "MISSION_CONTROL_SCREEN_MISSING_TENANT"
	MissionControlScreenReasonCrossTenant         = "MISSION_CONTROL_SCREEN_CROSS_TENANT_DENIED"
	MissionControlScreenReasonMissingActionID     = "MISSION_CONTROL_SCREEN_MISSING_ACTION_ID"
	MissionControlScreenReasonMissingInstanceID   = "MISSION_CONTROL_SCREEN_MISSING_INSTANCE_ID"
	MissionControlScreenReasonMissingOperatorID   = "MISSION_CONTROL_SCREEN_MISSING_OPERATOR_ID"
	MissionControlScreenReasonMissingActionType   = "MISSION_CONTROL_SCREEN_MISSING_ACTION_TYPE"
	MissionControlScreenReasonInvalidActionType   = "MISSION_CONTROL_SCREEN_INVALID_ACTION_TYPE"
	MissionControlScreenReasonInvalidActionStatus = "MISSION_CONTROL_SCREEN_INVALID_ACTION_STATUS"
	MissionControlScreenReasonUnauthorizedRole    = "MISSION_CONTROL_SCREEN_UNAUTHORIZED_ROLE"
	MissionControlScreenReasonMissingMessage      = "MISSION_CONTROL_SCREEN_MISSING_MESSAGE"
)

var (
	ErrMissionControlScreenMissingTenant       = errors.New("missing mission control tenant id")
	ErrMissionControlScreenCrossTenant         = errors.New("cross-tenant mission control access denied")
	ErrMissionControlScreenMissingActionID     = errors.New("missing mission control action id")
	ErrMissionControlScreenMissingInstanceID   = errors.New("missing mission control instance id")
	ErrMissionControlScreenMissingOperatorID   = errors.New("missing mission control operator id")
	ErrMissionControlScreenMissingActionType   = errors.New("missing mission control action type")
	ErrMissionControlScreenInvalidActionType   = errors.New("invalid mission control action type")
	ErrMissionControlScreenInvalidActionStatus = errors.New("invalid mission control action status")
	ErrMissionControlScreenUnauthorizedRole    = errors.New("unauthorized mission control operator role")
	ErrMissionControlScreenMissingMessage      = errors.New("missing mission control action message")
)

type MissionControlScreenConsoleConfig struct {
	RequireTenant       bool     `json:"require_tenant"`
	AllowPlatformViewer bool     `json:"allow_platform_viewer"`
	MaxVisibleActions   int      `json:"max_visible_actions"`
	AllowedActionTypes  []string `json:"allowed_action_types"`
	AllowedStatuses     []string `json:"allowed_statuses"`
	AllowedRoles        []string `json:"allowed_roles"`
	MutatingRoles       []string `json:"mutating_roles"`
}

func DefaultMissionControlScreenConsoleConfig() MissionControlScreenConsoleConfig {
	return MissionControlScreenConsoleConfig{
		RequireTenant:       true,
		AllowPlatformViewer: true,
		MaxVisibleActions:   100,
		AllowedActionTypes: []string{
			MissionControlActionRestart,
			MissionControlActionIsolate,
			MissionControlActionQuarantine,
			MissionControlActionMaintenance,
			MissionControlActionNote,
		},
		AllowedStatuses: []string{
			MissionControlActionStatusRequested,
			MissionControlActionStatusApproved,
			MissionControlActionStatusRejected,
			MissionControlActionStatusExecuted,
		},
		AllowedRoles: []string{
			MissionControlOperatorRoleViewer,
			MissionControlOperatorRoleOperator,
			MissionControlOperatorRoleAdmin,
		},
		MutatingRoles: []string{
			MissionControlOperatorRoleOperator,
			MissionControlOperatorRoleAdmin,
		},
	}
}

type MissionControlActionEntry struct {
	TenantID      string            `json:"tenant_id"`
	ActionID      string            `json:"action_id"`
	ActionType    string            `json:"action_type"`
	Status        string            `json:"status"`
	InstanceID    string            `json:"instance_id"`
	ServiceID     string            `json:"service_id,omitempty"`
	OperatorID    string            `json:"operator_id"`
	OperatorRole  string            `json:"operator_role"`
	Message       string            `json:"message"`
	Reason        string            `json:"reason,omitempty"`
	CorrelationID string            `json:"correlation_id,omitempty"`
	Metadata      map[string]string `json:"metadata,omitempty"`
	CreatedAt     string            `json:"created_at"`
	UpdatedAt     string            `json:"updated_at"`
}

type MissionControlScreenRequest struct {
	TenantID        string `json:"tenant_id"`
	ViewerTenantID  string `json:"viewer_tenant_id,omitempty"`
	ActionFilter    string `json:"action_filter,omitempty"`
	StatusFilter    string `json:"status_filter,omitempty"`
	IncludeExecuted bool   `json:"include_executed"`
	CorrelationID   string `json:"correlation_id,omitempty"`
}

type MissionControlScreenDecision struct {
	Decision       string `json:"decision"`
	Allowed        bool   `json:"allowed"`
	TenantID       string `json:"tenant_id"`
	ViewerTenantID string `json:"viewer_tenant_id,omitempty"`
	ActionFilter   string `json:"action_filter,omitempty"`
	StatusFilter   string `json:"status_filter,omitempty"`
	Reason         string `json:"reason"`
	CheckedAt      string `json:"checked_at"`
}

type MissionControlScreenSnapshot struct {
	OK               bool                        `json:"ok"`
	TenantID         string                      `json:"tenant_id"`
	ViewerTenantID   string                      `json:"viewer_tenant_id"`
	ActionFilter     string                      `json:"action_filter,omitempty"`
	StatusFilter     string                      `json:"status_filter,omitempty"`
	ActionCount      int                         `json:"action_count"`
	RestartCount     int                         `json:"restart_count"`
	IsolateCount     int                         `json:"isolate_count"`
	QuarantineCount  int                         `json:"quarantine_count"`
	MaintenanceCount int                         `json:"maintenance_count"`
	NoteCount        int                         `json:"note_count"`
	RequestedCount   int                         `json:"requested_count"`
	ApprovedCount    int                         `json:"approved_count"`
	RejectedCount    int                         `json:"rejected_count"`
	ExecutedCount    int                         `json:"executed_count"`
	Actions          []MissionControlActionEntry `json:"actions"`
	CorrelationID    string                      `json:"correlation_id,omitempty"`
	GeneratedAt      string                      `json:"generated_at"`
}

type MissionControlScreenConsoleRuntime struct {
	config  MissionControlScreenConsoleConfig
	mu      sync.RWMutex
	actions map[string]MissionControlActionEntry
}

func NewMissionControlScreenConsoleRuntime(config MissionControlScreenConsoleConfig) *MissionControlScreenConsoleRuntime {
	defaults := DefaultMissionControlScreenConsoleConfig()

	if config.MaxVisibleActions <= 0 {
		config.MaxVisibleActions = defaults.MaxVisibleActions
	}
	if len(config.AllowedActionTypes) == 0 {
		config.AllowedActionTypes = defaults.AllowedActionTypes
	}
	if len(config.AllowedStatuses) == 0 {
		config.AllowedStatuses = defaults.AllowedStatuses
	}
	if len(config.AllowedRoles) == 0 {
		config.AllowedRoles = defaults.AllowedRoles
	}
	if len(config.MutatingRoles) == 0 {
		config.MutatingRoles = defaults.MutatingRoles
	}

	return &MissionControlScreenConsoleRuntime{
		config:  config,
		actions: make(map[string]MissionControlActionEntry),
	}
}

func (r *MissionControlScreenConsoleRuntime) RecordAction(entry MissionControlActionEntry) (MissionControlActionEntry, MissionControlScreenDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	entry.TenantID = strings.TrimSpace(entry.TenantID)
	entry.ActionID = strings.TrimSpace(entry.ActionID)
	entry.ActionType = normalizeOpsConsoleValue(entry.ActionType)
	entry.Status = normalizeOpsConsoleValue(entry.Status)
	entry.InstanceID = strings.TrimSpace(entry.InstanceID)
	entry.ServiceID = strings.TrimSpace(entry.ServiceID)
	entry.OperatorID = strings.TrimSpace(entry.OperatorID)
	entry.OperatorRole = normalizeOpsConsoleValue(entry.OperatorRole)
	entry.Message = strings.TrimSpace(entry.Message)

	decision := MissionControlScreenDecision{
		Decision:  MissionControlScreenDecisionDeny,
		Allowed:   false,
		TenantID:  entry.TenantID,
		Reason:    MissionControlScreenReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && entry.TenantID == "" {
		decision.Reason = MissionControlScreenReasonMissingTenant
		return MissionControlActionEntry{}, decision, ErrMissionControlScreenMissingTenant
	}
	if entry.ActionID == "" {
		decision.Reason = MissionControlScreenReasonMissingActionID
		return MissionControlActionEntry{}, decision, ErrMissionControlScreenMissingActionID
	}
	if entry.InstanceID == "" {
		decision.Reason = MissionControlScreenReasonMissingInstanceID
		return MissionControlActionEntry{}, decision, ErrMissionControlScreenMissingInstanceID
	}
	if entry.OperatorID == "" {
		decision.Reason = MissionControlScreenReasonMissingOperatorID
		return MissionControlActionEntry{}, decision, ErrMissionControlScreenMissingOperatorID
	}
	if entry.ActionType == "" {
		decision.Reason = MissionControlScreenReasonMissingActionType
		return MissionControlActionEntry{}, decision, ErrMissionControlScreenMissingActionType
	}
	if !r.actionTypeAllowed(entry.ActionType) {
		decision.Reason = MissionControlScreenReasonInvalidActionType
		return MissionControlActionEntry{}, decision, ErrMissionControlScreenInvalidActionType
	}
	if entry.Status == "" {
		entry.Status = MissionControlActionStatusRequested
	}
	if !r.statusAllowed(entry.Status) {
		decision.Reason = MissionControlScreenReasonInvalidActionStatus
		return MissionControlActionEntry{}, decision, ErrMissionControlScreenInvalidActionStatus
	}
	if !r.roleAllowed(entry.OperatorRole) || !r.roleCanMutate(entry.OperatorRole) {
		decision.Reason = MissionControlScreenReasonUnauthorizedRole
		return MissionControlActionEntry{}, decision, ErrMissionControlScreenUnauthorizedRole
	}
	if entry.Message == "" {
		decision.Reason = MissionControlScreenReasonMissingMessage
		return MissionControlActionEntry{}, decision, ErrMissionControlScreenMissingMessage
	}

	if entry.CreatedAt == "" {
		entry.CreatedAt = now
	}
	entry.UpdatedAt = now
	entry.Metadata = cloneOpsConsoleMap(entry.Metadata)

	r.mu.Lock()
	r.actions[missionControlActionKey(entry.TenantID, entry.ActionID)] = entry
	r.mu.Unlock()

	decision.Decision = MissionControlScreenDecisionAllow
	decision.Allowed = true
	decision.Reason = MissionControlScreenReasonAllowed

	return entry, decision, nil
}

func (r *MissionControlScreenConsoleRuntime) BuildSnapshot(req MissionControlScreenRequest) (MissionControlScreenSnapshot, MissionControlScreenDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	viewerTenantID := strings.TrimSpace(req.ViewerTenantID)
	actionFilter := normalizeOpsConsoleValue(req.ActionFilter)
	statusFilter := normalizeOpsConsoleValue(req.StatusFilter)

	if viewerTenantID == "" {
		viewerTenantID = tenantID
	}

	decision := MissionControlScreenDecision{
		Decision:       MissionControlScreenDecisionDeny,
		Allowed:        false,
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		ActionFilter:   actionFilter,
		StatusFilter:   statusFilter,
		Reason:         MissionControlScreenReasonAllowed,
		CheckedAt:      now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = MissionControlScreenReasonMissingTenant
		return MissionControlScreenSnapshot{}, decision, ErrMissionControlScreenMissingTenant
	}
	if viewerTenantID != tenantID && !(r.config.AllowPlatformViewer && viewerTenantID == "platform") {
		decision.Reason = MissionControlScreenReasonCrossTenant
		return MissionControlScreenSnapshot{}, decision, ErrMissionControlScreenCrossTenant
	}
	if actionFilter != "" && !r.actionTypeAllowed(actionFilter) {
		decision.Reason = MissionControlScreenReasonInvalidActionType
		return MissionControlScreenSnapshot{}, decision, ErrMissionControlScreenInvalidActionType
	}
	if statusFilter != "" && !r.statusAllowed(statusFilter) {
		decision.Reason = MissionControlScreenReasonInvalidActionStatus
		return MissionControlScreenSnapshot{}, decision, ErrMissionControlScreenInvalidActionStatus
	}

	snapshot := MissionControlScreenSnapshot{
		OK:             true,
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		ActionFilter:   actionFilter,
		StatusFilter:   statusFilter,
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		GeneratedAt:    now,
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, action := range r.actions {
		if action.TenantID != tenantID {
			continue
		}
		if !req.IncludeExecuted && action.Status == MissionControlActionStatusExecuted {
			continue
		}
		if actionFilter != "" && action.ActionType != actionFilter {
			continue
		}
		if statusFilter != "" && action.Status != statusFilter {
			continue
		}
		if snapshot.ActionCount >= r.config.MaxVisibleActions {
			continue
		}

		snapshot.Actions = append(snapshot.Actions, action)
		snapshot.ActionCount++

		switch action.ActionType {
		case MissionControlActionRestart:
			snapshot.RestartCount++
		case MissionControlActionIsolate:
			snapshot.IsolateCount++
		case MissionControlActionQuarantine:
			snapshot.QuarantineCount++
		case MissionControlActionMaintenance:
			snapshot.MaintenanceCount++
		case MissionControlActionNote:
			snapshot.NoteCount++
		}

		switch action.Status {
		case MissionControlActionStatusRequested:
			snapshot.RequestedCount++
		case MissionControlActionStatusApproved:
			snapshot.ApprovedCount++
		case MissionControlActionStatusRejected:
			snapshot.RejectedCount++
		case MissionControlActionStatusExecuted:
			snapshot.ExecutedCount++
		}
	}

	decision.Decision = MissionControlScreenDecisionAllow
	decision.Allowed = true
	decision.Reason = MissionControlScreenReasonAllowed

	return snapshot, decision, nil
}

func (r *MissionControlScreenConsoleRuntime) actionTypeAllowed(actionType string) bool {
	actionType = normalizeOpsConsoleValue(actionType)
	for _, allowed := range r.config.AllowedActionTypes {
		if normalizeOpsConsoleValue(allowed) == actionType {
			return true
		}
	}
	return false
}

func (r *MissionControlScreenConsoleRuntime) statusAllowed(status string) bool {
	status = normalizeOpsConsoleValue(status)
	for _, allowed := range r.config.AllowedStatuses {
		if normalizeOpsConsoleValue(allowed) == status {
			return true
		}
	}
	return false
}

func (r *MissionControlScreenConsoleRuntime) roleAllowed(role string) bool {
	role = normalizeOpsConsoleValue(role)
	for _, allowed := range r.config.AllowedRoles {
		if normalizeOpsConsoleValue(allowed) == role {
			return true
		}
	}
	return false
}

func (r *MissionControlScreenConsoleRuntime) roleCanMutate(role string) bool {
	role = normalizeOpsConsoleValue(role)
	for _, allowed := range r.config.MutatingRoles {
		if normalizeOpsConsoleValue(allowed) == role {
			return true
		}
	}
	return false
}

func missionControlActionKey(tenantID string, actionID string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(actionID)
}
