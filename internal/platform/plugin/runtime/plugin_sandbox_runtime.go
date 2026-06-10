package pluginruntime

import (
	"errors"
	"strings"
	"time"
)

const (
	PluginSandboxDecisionAllow = "ALLOW"
	PluginSandboxDecisionDeny  = "DENY"

	PluginSandboxNamespacePrefix = "plugin_sandbox"

	PluginSandboxReasonAllowed              = "PLUGIN_SANDBOX_ALLOWED"
	PluginSandboxReasonMissingTenant        = "PLUGIN_SANDBOX_MISSING_TENANT"
	PluginSandboxReasonMissingInstall       = "PLUGIN_SANDBOX_MISSING_INSTALL"
	PluginSandboxReasonMissingAction        = "PLUGIN_SANDBOX_MISSING_ACTION"
	PluginSandboxReasonCrossTenant          = "PLUGIN_SANDBOX_CROSS_TENANT_DENIED"
	PluginSandboxReasonInstallNotEnabled    = "PLUGIN_SANDBOX_INSTALL_NOT_ENABLED"
	PluginSandboxReasonEnvironmentMismatch  = "PLUGIN_SANDBOX_ENVIRONMENT_MISMATCH"
	PluginSandboxReasonProductionDenied     = "PLUGIN_SANDBOX_PRODUCTION_DENIED"
	PluginSandboxReasonPermissionDenied     = "PLUGIN_SANDBOX_PERMISSION_DENIED"
	PluginSandboxReasonPermissionRuntimeNil = "PLUGIN_SANDBOX_PERMISSION_RUNTIME_MISSING"
)

var (
	ErrPluginSandboxMissingTenant        = errors.New("missing plugin sandbox tenant id")
	ErrPluginSandboxMissingInstall       = errors.New("missing plugin sandbox install")
	ErrPluginSandboxMissingAction        = errors.New("missing plugin sandbox action")
	ErrPluginSandboxCrossTenant          = errors.New("cross-tenant plugin sandbox access denied")
	ErrPluginSandboxInstallNotEnabled    = errors.New("plugin sandbox install is not enabled")
	ErrPluginSandboxEnvironmentMismatch  = errors.New("plugin sandbox environment mismatch")
	ErrPluginSandboxProductionDenied     = errors.New("plugin sandbox production environment denied")
	ErrPluginSandboxPermissionDenied     = errors.New("plugin sandbox permission denied")
	ErrPluginSandboxPermissionRuntimeNil = errors.New("plugin sandbox permission runtime missing")
)

type PluginSandboxRuntimeConfig struct {
	RequireTenant             bool `json:"require_tenant"`
	RequireEnabledInstall     bool `json:"require_enabled_install"`
	RequireSandboxEnvironment bool `json:"require_sandbox_environment"`
	DenyProductionByDefault   bool `json:"deny_production_by_default"`
	EnablePermissionBridge    bool `json:"enable_permission_bridge"`
}

func DefaultPluginSandboxRuntimeConfig() PluginSandboxRuntimeConfig {
	return PluginSandboxRuntimeConfig{
		RequireTenant:             true,
		RequireEnabledInstall:     true,
		RequireSandboxEnvironment: true,
		DenyProductionByDefault:   true,
		EnablePermissionBridge:    true,
	}
}

type PluginSandboxExecutionRequest struct {
	TenantID      string              `json:"tenant_id"`
	Install       TenantPluginInstall `json:"install"`
	Action        string              `json:"action"`
	Resource      string              `json:"resource,omitempty"`
	Environment   string              `json:"environment,omitempty"`
	PayloadKind   string              `json:"payload_kind,omitempty"`
	ActorRef      string              `json:"actor_ref,omitempty"`
	CorrelationID string              `json:"correlation_id,omitempty"`
}

type PluginSandboxExecutionContext struct {
	TenantID           string   `json:"tenant_id"`
	InstallID          string   `json:"install_id"`
	PluginID           string   `json:"plugin_id"`
	Version            string   `json:"version"`
	Environment        string   `json:"environment"`
	Action             string   `json:"action"`
	RequiredPermission string   `json:"required_permission,omitempty"`
	GrantedPermissions []string `json:"granted_permissions,omitempty"`
	SandboxNamespace   string   `json:"sandbox_namespace"`
	Resource           string   `json:"resource,omitempty"`
	PayloadKind        string   `json:"payload_kind,omitempty"`
	ActorRef           string   `json:"actor_ref,omitempty"`
	CorrelationID      string   `json:"correlation_id,omitempty"`
	CreatedAt          string   `json:"created_at"`
}

type PluginSandboxDecision struct {
	Decision           string   `json:"decision"`
	Allowed            bool     `json:"allowed"`
	TenantID           string   `json:"tenant_id"`
	InstallID          string   `json:"install_id,omitempty"`
	PluginID           string   `json:"plugin_id,omitempty"`
	Version            string   `json:"version,omitempty"`
	Environment        string   `json:"environment,omitempty"`
	Action             string   `json:"action,omitempty"`
	RequiredPermission string   `json:"required_permission,omitempty"`
	GrantedPermissions []string `json:"granted_permissions,omitempty"`
	SandboxNamespace   string   `json:"sandbox_namespace,omitempty"`
	Resource           string   `json:"resource,omitempty"`
	ActorRef           string   `json:"actor_ref,omitempty"`
	CorrelationID      string   `json:"correlation_id,omitempty"`
	Reason             string   `json:"reason"`
	CheckedAt          string   `json:"checked_at"`
}

type PluginSandboxRuntime struct {
	config            PluginSandboxRuntimeConfig
	permissionRuntime *PluginPermissionEnforcementRuntime
}

func NewPluginSandboxRuntime(config PluginSandboxRuntimeConfig, permissionRuntime *PluginPermissionEnforcementRuntime) *PluginSandboxRuntime {
	return &PluginSandboxRuntime{
		config:            config,
		permissionRuntime: permissionRuntime,
	}
}

func (r *PluginSandboxRuntime) BuildExecutionContext(req PluginSandboxExecutionRequest) (PluginSandboxExecutionContext, PluginSandboxDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	install := req.Install
	action := normalizePluginRuntimeAction(req.Action)
	environment := normalizePluginEnvironment(req.Environment)
	if strings.TrimSpace(req.Environment) == "" {
		environment = normalizePluginEnvironment(install.Environment)
	}

	decision := PluginSandboxDecision{
		Decision:           PluginSandboxDecisionDeny,
		Allowed:            false,
		TenantID:           tenantID,
		InstallID:          strings.TrimSpace(install.InstallID),
		PluginID:           strings.TrimSpace(install.PluginID),
		Version:            strings.TrimSpace(install.Version),
		Environment:        environment,
		Action:             action,
		GrantedPermissions: append([]string{}, install.Permissions...),
		Resource:           strings.TrimSpace(req.Resource),
		ActorRef:           strings.TrimSpace(req.ActorRef),
		CorrelationID:      strings.TrimSpace(req.CorrelationID),
		Reason:             PluginSandboxReasonAllowed,
		CheckedAt:          now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = PluginSandboxReasonMissingTenant
		return PluginSandboxExecutionContext{}, decision, ErrPluginSandboxMissingTenant
	}

	if strings.TrimSpace(install.InstallID) == "" {
		decision.Reason = PluginSandboxReasonMissingInstall
		return PluginSandboxExecutionContext{}, decision, ErrPluginSandboxMissingInstall
	}

	if action == "" {
		decision.Reason = PluginSandboxReasonMissingAction
		return PluginSandboxExecutionContext{}, decision, ErrPluginSandboxMissingAction
	}

	if strings.TrimSpace(install.TenantID) != tenantID {
		decision.Reason = PluginSandboxReasonCrossTenant
		return PluginSandboxExecutionContext{}, decision, ErrPluginSandboxCrossTenant
	}

	if r.config.RequireEnabledInstall && install.Status != PluginInstallStatusEnabled {
		decision.Reason = PluginSandboxReasonInstallNotEnabled
		return PluginSandboxExecutionContext{}, decision, ErrPluginSandboxInstallNotEnabled
	}

	if normalizePluginEnvironment(install.Environment) != environment {
		decision.Reason = PluginSandboxReasonEnvironmentMismatch
		return PluginSandboxExecutionContext{}, decision, ErrPluginSandboxEnvironmentMismatch
	}

	if r.config.DenyProductionByDefault && environment == PluginEnvironmentProduction {
		decision.Reason = PluginSandboxReasonProductionDenied
		return PluginSandboxExecutionContext{}, decision, ErrPluginSandboxProductionDenied
	}

	if r.config.RequireSandboxEnvironment && environment != PluginEnvironmentSandbox {
		decision.Reason = PluginSandboxReasonProductionDenied
		return PluginSandboxExecutionContext{}, decision, ErrPluginSandboxProductionDenied
	}

	var permissionDecision PluginPermissionDecision
	if r.config.EnablePermissionBridge {
		if r.permissionRuntime == nil {
			decision.Reason = PluginSandboxReasonPermissionRuntimeNil
			return PluginSandboxExecutionContext{}, decision, ErrPluginSandboxPermissionRuntimeNil
		}

		var err error
		permissionDecision, err = r.permissionRuntime.CheckPermission(PluginPermissionCheckRequest{
			TenantID:      tenantID,
			Install:       install,
			Action:        action,
			Resource:      strings.TrimSpace(req.Resource),
			ActorRef:      strings.TrimSpace(req.ActorRef),
			CorrelationID: strings.TrimSpace(req.CorrelationID),
		})
		if err != nil || !permissionDecision.Allowed {
			decision.Reason = PluginSandboxReasonPermissionDenied
			decision.RequiredPermission = permissionDecision.RequiredPermission
			return PluginSandboxExecutionContext{}, decision, ErrPluginSandboxPermissionDenied
		}
		decision.RequiredPermission = permissionDecision.RequiredPermission
	}

	namespace := BuildPluginSandboxNamespace(tenantID, install.PluginID, install.InstallID)

	ctx := PluginSandboxExecutionContext{
		TenantID:           tenantID,
		InstallID:          install.InstallID,
		PluginID:           install.PluginID,
		Version:            install.Version,
		Environment:        environment,
		Action:             action,
		RequiredPermission: decision.RequiredPermission,
		GrantedPermissions: append([]string{}, install.Permissions...),
		SandboxNamespace:   namespace,
		Resource:           strings.TrimSpace(req.Resource),
		PayloadKind:        strings.TrimSpace(req.PayloadKind),
		ActorRef:           strings.TrimSpace(req.ActorRef),
		CorrelationID:      strings.TrimSpace(req.CorrelationID),
		CreatedAt:          now,
	}

	decision.Decision = PluginSandboxDecisionAllow
	decision.Allowed = true
	decision.SandboxNamespace = namespace
	decision.Reason = PluginSandboxReasonAllowed

	return ctx, decision, nil
}

func (r *PluginSandboxRuntime) CanExecute(req PluginSandboxExecutionRequest) bool {
	decision, err := r.CheckSandbox(req)
	return err == nil && decision.Allowed
}

func (r *PluginSandboxRuntime) CheckSandbox(req PluginSandboxExecutionRequest) (PluginSandboxDecision, error) {
	_, decision, err := r.BuildExecutionContext(req)
	return decision, err
}

func BuildPluginSandboxNamespace(tenantID string, pluginID string, installID string) string {
	return PluginSandboxNamespacePrefix + ":" + strings.TrimSpace(tenantID) + ":" + strings.TrimSpace(pluginID) + ":" + strings.TrimSpace(installID)
}

func PluginSandboxContextMatchesTenant(ctx PluginSandboxExecutionContext, tenantID string) bool {
	return strings.TrimSpace(ctx.TenantID) == strings.TrimSpace(tenantID)
}
