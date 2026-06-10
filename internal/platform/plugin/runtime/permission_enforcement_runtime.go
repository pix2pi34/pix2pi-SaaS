package pluginruntime

import (
	"errors"
	"strings"
	"time"
)

const (
	PluginRuntimeActionERPRead          = "ERP_READ"
	PluginRuntimeActionERPWrite         = "ERP_WRITE"
	PluginRuntimeActionWebhookEmit      = "WEBHOOK_EMIT"
	PluginRuntimeActionPublicAPIRead    = "PUBLIC_API_READ"
	PluginRuntimeActionPublicAPIWrite   = "PUBLIC_API_WRITE"
	PluginRuntimeActionWorkflowTrigger  = "WORKFLOW_TRIGGER"
	PluginRuntimeActionNotificationSend = "NOTIFICATION_SEND"
	PluginRuntimeActionReportRead       = "REPORT_READ"

	PluginPermissionDecisionAllow = "ALLOW"
	PluginPermissionDecisionDeny  = "DENY"

	PluginPermissionReasonAllowed           = "PLUGIN_PERMISSION_ALLOWED"
	PluginPermissionReasonMissingTenant     = "PLUGIN_PERMISSION_MISSING_TENANT"
	PluginPermissionReasonMissingInstall    = "PLUGIN_PERMISSION_MISSING_INSTALL"
	PluginPermissionReasonMissingAction     = "PLUGIN_PERMISSION_MISSING_ACTION"
	PluginPermissionReasonCrossTenant       = "PLUGIN_PERMISSION_CROSS_TENANT_DENIED"
	PluginPermissionReasonInstallNotEnabled = "PLUGIN_PERMISSION_INSTALL_NOT_ENABLED"
	PluginPermissionReasonActionUnknown     = "PLUGIN_PERMISSION_ACTION_UNKNOWN"
	PluginPermissionReasonPermissionDenied  = "PLUGIN_PERMISSION_DENIED"
)

var (
	ErrPluginPermissionMissingTenant     = errors.New("missing plugin permission tenant id")
	ErrPluginPermissionMissingInstall    = errors.New("missing plugin permission install")
	ErrPluginPermissionMissingAction     = errors.New("missing plugin permission action")
	ErrPluginPermissionCrossTenant       = errors.New("cross-tenant plugin permission access denied")
	ErrPluginPermissionInstallNotEnabled = errors.New("plugin install is not enabled")
	ErrPluginPermissionActionUnknown     = errors.New("unknown plugin runtime action")
	ErrPluginPermissionDenied            = errors.New("plugin permission denied")
)

type PluginPermissionEnforcementRuntimeConfig struct {
	RequireTenant       bool              `json:"require_tenant"`
	RequireEnabledState bool              `json:"require_enabled_state"`
	ActionPermissionMap map[string]string `json:"action_permission_map"`
}

func DefaultPluginPermissionEnforcementRuntimeConfig() PluginPermissionEnforcementRuntimeConfig {
	return PluginPermissionEnforcementRuntimeConfig{
		RequireTenant:       true,
		RequireEnabledState: true,
		ActionPermissionMap: map[string]string{
			PluginRuntimeActionERPRead:          "erp:read",
			PluginRuntimeActionERPWrite:         "erp:write",
			PluginRuntimeActionWebhookEmit:      "webhook:emit",
			PluginRuntimeActionPublicAPIRead:    "public_api:read",
			PluginRuntimeActionPublicAPIWrite:   "public_api:write",
			PluginRuntimeActionWorkflowTrigger:  "workflow:trigger",
			PluginRuntimeActionNotificationSend: "notification:send",
			PluginRuntimeActionReportRead:       "report:read",
		},
	}
}

type PluginPermissionCheckRequest struct {
	TenantID      string              `json:"tenant_id"`
	Install       TenantPluginInstall `json:"install"`
	Action        string              `json:"action"`
	Resource      string              `json:"resource,omitempty"`
	ActorRef      string              `json:"actor_ref,omitempty"`
	CorrelationID string              `json:"correlation_id,omitempty"`
}

type PluginPermissionDecision struct {
	Decision           string   `json:"decision"`
	Allowed            bool     `json:"allowed"`
	TenantID           string   `json:"tenant_id"`
	InstallID          string   `json:"install_id,omitempty"`
	PluginID           string   `json:"plugin_id,omitempty"`
	Version            string   `json:"version,omitempty"`
	Action             string   `json:"action,omitempty"`
	RequiredPermission string   `json:"required_permission,omitempty"`
	GrantedPermissions []string `json:"granted_permissions,omitempty"`
	Resource           string   `json:"resource,omitempty"`
	ActorRef           string   `json:"actor_ref,omitempty"`
	CorrelationID      string   `json:"correlation_id,omitempty"`
	Reason             string   `json:"reason"`
	CheckedAt          string   `json:"checked_at"`
}

type PluginPermissionEnforcementRuntime struct {
	config PluginPermissionEnforcementRuntimeConfig
}

func NewPluginPermissionEnforcementRuntime(config PluginPermissionEnforcementRuntimeConfig) *PluginPermissionEnforcementRuntime {
	if len(config.ActionPermissionMap) == 0 {
		config.ActionPermissionMap = DefaultPluginPermissionEnforcementRuntimeConfig().ActionPermissionMap
	}
	return &PluginPermissionEnforcementRuntime{config: config}
}

func (r *PluginPermissionEnforcementRuntime) CheckPermission(req PluginPermissionCheckRequest) (PluginPermissionDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	action := normalizePluginRuntimeAction(req.Action)
	install := req.Install

	decision := PluginPermissionDecision{
		Decision:           PluginPermissionDecisionDeny,
		Allowed:            false,
		TenantID:           tenantID,
		InstallID:          strings.TrimSpace(install.InstallID),
		PluginID:           strings.TrimSpace(install.PluginID),
		Version:            strings.TrimSpace(install.Version),
		Action:             action,
		GrantedPermissions: append([]string{}, install.Permissions...),
		Resource:           strings.TrimSpace(req.Resource),
		ActorRef:           strings.TrimSpace(req.ActorRef),
		CorrelationID:      strings.TrimSpace(req.CorrelationID),
		Reason:             PluginPermissionReasonAllowed,
		CheckedAt:          now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = PluginPermissionReasonMissingTenant
		return decision, ErrPluginPermissionMissingTenant
	}

	if strings.TrimSpace(install.InstallID) == "" {
		decision.Reason = PluginPermissionReasonMissingInstall
		return decision, ErrPluginPermissionMissingInstall
	}

	if action == "" {
		decision.Reason = PluginPermissionReasonMissingAction
		return decision, ErrPluginPermissionMissingAction
	}

	if strings.TrimSpace(install.TenantID) != tenantID {
		decision.Reason = PluginPermissionReasonCrossTenant
		return decision, ErrPluginPermissionCrossTenant
	}

	if r.config.RequireEnabledState && install.Status != PluginInstallStatusEnabled {
		decision.Reason = PluginPermissionReasonInstallNotEnabled
		return decision, ErrPluginPermissionInstallNotEnabled
	}

	requiredPermission, ok := r.config.ActionPermissionMap[action]
	if !ok || strings.TrimSpace(requiredPermission) == "" {
		decision.Reason = PluginPermissionReasonActionUnknown
		return decision, ErrPluginPermissionActionUnknown
	}
	decision.RequiredPermission = requiredPermission

	if !PluginPermissionListContains(install.Permissions, requiredPermission) {
		decision.Reason = PluginPermissionReasonPermissionDenied
		return decision, ErrPluginPermissionDenied
	}

	decision.Decision = PluginPermissionDecisionAllow
	decision.Allowed = true
	decision.Reason = PluginPermissionReasonAllowed

	return decision, nil
}

func (r *PluginPermissionEnforcementRuntime) CanPerform(req PluginPermissionCheckRequest) bool {
	decision, err := r.CheckPermission(req)
	return err == nil && decision.Allowed
}

func normalizePluginRuntimeAction(action string) string {
	return strings.ToUpper(strings.TrimSpace(action))
}

func PluginPermissionListContains(permissions []string, required string) bool {
	required = strings.TrimSpace(required)
	for _, permission := range permissions {
		if strings.EqualFold(strings.TrimSpace(permission), required) {
			return true
		}
	}
	return false
}
