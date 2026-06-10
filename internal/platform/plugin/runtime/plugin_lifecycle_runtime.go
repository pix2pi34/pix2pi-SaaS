package pluginruntime

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	PluginInstallStatusInstalled   = "INSTALLED"
	PluginInstallStatusEnabled     = "ENABLED"
	PluginInstallStatusDisabled    = "DISABLED"
	PluginInstallStatusSuspended   = "SUSPENDED"
	PluginInstallStatusUninstalled = "UNINSTALLED"

	PluginLifecycleActionInstall   = "INSTALL"
	PluginLifecycleActionEnable    = "ENABLE"
	PluginLifecycleActionDisable   = "DISABLE"
	PluginLifecycleActionSuspend   = "SUSPEND"
	PluginLifecycleActionUninstall = "UNINSTALL"

	PluginLifecycleDecisionAllow = "ALLOW"
	PluginLifecycleDecisionDeny  = "DENY"

	PluginLifecycleReasonAllowed           = "PLUGIN_LIFECYCLE_ALLOWED"
	PluginLifecycleReasonMissingTenant     = "PLUGIN_LIFECYCLE_MISSING_TENANT"
	PluginLifecycleReasonMissingPlugin     = "PLUGIN_LIFECYCLE_MISSING_PLUGIN"
	PluginLifecycleReasonMissingInstall    = "PLUGIN_LIFECYCLE_MISSING_INSTALL"
	PluginLifecycleReasonMissingManifest   = "PLUGIN_LIFECYCLE_MISSING_MANIFEST"
	PluginLifecycleReasonCrossTenant       = "PLUGIN_LIFECYCLE_CROSS_TENANT_DENIED"
	PluginLifecycleReasonManifestNotLoaded = "PLUGIN_LIFECYCLE_MANIFEST_NOT_LOADED"
	PluginLifecycleReasonAlreadyInstalled  = "PLUGIN_LIFECYCLE_ALREADY_INSTALLED"
	PluginLifecycleReasonInvalidTransition = "PLUGIN_LIFECYCLE_INVALID_TRANSITION"
	PluginLifecycleReasonTerminalInstall   = "PLUGIN_LIFECYCLE_TERMINAL_INSTALL"
)

var (
	ErrPluginLifecycleMissingTenant     = errors.New("missing plugin lifecycle tenant id")
	ErrPluginLifecycleMissingPlugin     = errors.New("missing plugin id")
	ErrPluginLifecycleMissingInstall    = errors.New("missing plugin install")
	ErrPluginLifecycleMissingManifest   = errors.New("missing plugin manifest")
	ErrPluginLifecycleCrossTenant       = errors.New("cross-tenant plugin lifecycle access denied")
	ErrPluginLifecycleManifestNotLoaded = errors.New("plugin manifest is not loaded")
	ErrPluginLifecycleAlreadyInstalled  = errors.New("plugin already installed for tenant")
	ErrPluginLifecycleInvalidTransition = errors.New("invalid plugin lifecycle transition")
	ErrPluginLifecycleTerminalInstall   = errors.New("plugin install is terminal")
)

type PluginLifecycleRuntimeConfig struct {
	RequireTenant bool `json:"require_tenant"`
}

func DefaultPluginLifecycleRuntimeConfig() PluginLifecycleRuntimeConfig {
	return PluginLifecycleRuntimeConfig{
		RequireTenant: true,
	}
}

type TenantPluginInstall struct {
	TenantID      string         `json:"tenant_id"`
	InstallID     string         `json:"install_id"`
	PluginID      string         `json:"plugin_id"`
	Version       string         `json:"version"`
	Name          string         `json:"name"`
	Environment   string         `json:"environment"`
	Permissions   []string       `json:"permissions"`
	Status        string         `json:"status"`
	Manifest      PluginManifest `json:"manifest"`
	InstalledBy   string         `json:"installed_by,omitempty"`
	UpdatedBy     string         `json:"updated_by,omitempty"`
	CorrelationID string         `json:"correlation_id,omitempty"`
	InstalledAt   string         `json:"installed_at"`
	UpdatedAt     string         `json:"updated_at"`
	EnabledAt     string         `json:"enabled_at,omitempty"`
	DisabledAt    string         `json:"disabled_at,omitempty"`
	SuspendedAt   string         `json:"suspended_at,omitempty"`
	UninstalledAt string         `json:"uninstalled_at,omitempty"`
}

type PluginLifecycleRequest struct {
	TenantID      string         `json:"tenant_id"`
	Manifest      PluginManifest `json:"manifest,omitempty"`
	InstallID     string         `json:"install_id,omitempty"`
	PluginID      string         `json:"plugin_id,omitempty"`
	Version       string         `json:"version,omitempty"`
	ActorRef      string         `json:"actor_ref,omitempty"`
	CorrelationID string         `json:"correlation_id,omitempty"`
}

type PluginLifecycleDecision struct {
	Decision   string `json:"decision"`
	Allowed    bool   `json:"allowed"`
	TenantID   string `json:"tenant_id"`
	InstallID  string `json:"install_id,omitempty"`
	PluginID   string `json:"plugin_id,omitempty"`
	Version    string `json:"version,omitempty"`
	FromStatus string `json:"from_status,omitempty"`
	ToStatus   string `json:"to_status,omitempty"`
	Action     string `json:"action,omitempty"`
	Reason     string `json:"reason"`
	CheckedAt  string `json:"checked_at"`
}

type PluginLifecycleRuntime struct {
	config   PluginLifecycleRuntimeConfig
	mu       sync.RWMutex
	installs map[string]TenantPluginInstall
}

func NewPluginLifecycleRuntime(config PluginLifecycleRuntimeConfig) *PluginLifecycleRuntime {
	return &PluginLifecycleRuntime{
		config:   config,
		installs: make(map[string]TenantPluginInstall),
	}
}

func (r *PluginLifecycleRuntime) InstallPlugin(req PluginLifecycleRequest) (TenantPluginInstall, PluginLifecycleDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)
	tenantID := strings.TrimSpace(req.TenantID)

	decision := PluginLifecycleDecision{
		Decision:  PluginLifecycleDecisionDeny,
		Allowed:   false,
		TenantID:  tenantID,
		Action:    PluginLifecycleActionInstall,
		ToStatus:  PluginInstallStatusInstalled,
		Reason:    PluginLifecycleReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = PluginLifecycleReasonMissingTenant
		return TenantPluginInstall{}, decision, ErrPluginLifecycleMissingTenant
	}

	manifest := req.Manifest
	manifest.TenantID = strings.TrimSpace(manifest.TenantID)
	manifest.PluginID = strings.TrimSpace(manifest.PluginID)
	manifest.Version = strings.TrimSpace(manifest.Version)
	manifest.Name = strings.TrimSpace(manifest.Name)
	manifest.Environment = normalizePluginEnvironment(manifest.Environment)

	decision.PluginID = manifest.PluginID
	decision.Version = manifest.Version

	if manifest.PluginID == "" {
		decision.Reason = PluginLifecycleReasonMissingPlugin
		return TenantPluginInstall{}, decision, ErrPluginLifecycleMissingPlugin
	}
	if manifest.TenantID == "" {
		decision.Reason = PluginLifecycleReasonMissingTenant
		return TenantPluginInstall{}, decision, ErrPluginLifecycleMissingTenant
	}
	if manifest.TenantID != tenantID {
		decision.Reason = PluginLifecycleReasonCrossTenant
		return TenantPluginInstall{}, decision, ErrPluginLifecycleCrossTenant
	}
	if manifest.Status != PluginManifestStatusLoaded {
		decision.Reason = PluginLifecycleReasonManifestNotLoaded
		return TenantPluginInstall{}, decision, ErrPluginLifecycleManifestNotLoaded
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.findInstallLocked(tenantID, manifest.PluginID, manifest.Version); exists {
		decision.Reason = PluginLifecycleReasonAlreadyInstalled
		return TenantPluginInstall{}, decision, ErrPluginLifecycleAlreadyInstalled
	}

	install := TenantPluginInstall{
		TenantID:      tenantID,
		InstallID:     NewTenantPluginInstallID(),
		PluginID:      manifest.PluginID,
		Version:       manifest.Version,
		Name:          manifest.Name,
		Environment:   manifest.Environment,
		Permissions:   append([]string{}, manifest.Permissions...),
		Status:        PluginInstallStatusInstalled,
		Manifest:      manifest,
		InstalledBy:   strings.TrimSpace(req.ActorRef),
		UpdatedBy:     strings.TrimSpace(req.ActorRef),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		InstalledAt:   now,
		UpdatedAt:     now,
	}

	r.installs[install.InstallID] = install

	decision.Decision = PluginLifecycleDecisionAllow
	decision.Allowed = true
	decision.InstallID = install.InstallID
	decision.Reason = PluginLifecycleReasonAllowed

	return install, decision, nil
}

func (r *PluginLifecycleRuntime) EnablePlugin(req PluginLifecycleRequest) (TenantPluginInstall, PluginLifecycleDecision, error) {
	return r.transition(req, PluginLifecycleActionEnable, PluginInstallStatusEnabled)
}

func (r *PluginLifecycleRuntime) DisablePlugin(req PluginLifecycleRequest) (TenantPluginInstall, PluginLifecycleDecision, error) {
	return r.transition(req, PluginLifecycleActionDisable, PluginInstallStatusDisabled)
}

func (r *PluginLifecycleRuntime) SuspendPlugin(req PluginLifecycleRequest) (TenantPluginInstall, PluginLifecycleDecision, error) {
	return r.transition(req, PluginLifecycleActionSuspend, PluginInstallStatusSuspended)
}

func (r *PluginLifecycleRuntime) UninstallPlugin(req PluginLifecycleRequest) (TenantPluginInstall, PluginLifecycleDecision, error) {
	return r.transition(req, PluginLifecycleActionUninstall, PluginInstallStatusUninstalled)
}

func (r *PluginLifecycleRuntime) GetInstall(tenantID string, installID string) (TenantPluginInstall, error) {
	tenantID = strings.TrimSpace(tenantID)
	installID = strings.TrimSpace(installID)

	if tenantID == "" {
		return TenantPluginInstall{}, ErrPluginLifecycleMissingTenant
	}
	if installID == "" {
		return TenantPluginInstall{}, ErrPluginLifecycleMissingInstall
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	install, ok := r.installs[installID]
	if !ok {
		return TenantPluginInstall{}, ErrPluginLifecycleMissingInstall
	}
	if install.TenantID != tenantID {
		return TenantPluginInstall{}, ErrPluginLifecycleCrossTenant
	}

	return install, nil
}

func (r *PluginLifecycleRuntime) ListTenantInstalls(tenantID string) ([]TenantPluginInstall, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrPluginLifecycleMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]TenantPluginInstall, 0)
	for _, install := range r.installs {
		if install.TenantID == tenantID {
			out = append(out, install)
		}
	}
	return out, nil
}

func (r *PluginLifecycleRuntime) transition(req PluginLifecycleRequest, action string, targetStatus string) (TenantPluginInstall, PluginLifecycleDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	installID := strings.TrimSpace(req.InstallID)

	decision := PluginLifecycleDecision{
		Decision:  PluginLifecycleDecisionDeny,
		Allowed:   false,
		TenantID:  tenantID,
		InstallID: installID,
		Action:    action,
		ToStatus:  targetStatus,
		Reason:    PluginLifecycleReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = PluginLifecycleReasonMissingTenant
		return TenantPluginInstall{}, decision, ErrPluginLifecycleMissingTenant
	}
	if installID == "" {
		decision.Reason = PluginLifecycleReasonMissingInstall
		return TenantPluginInstall{}, decision, ErrPluginLifecycleMissingInstall
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	install, ok := r.installs[installID]
	if !ok {
		decision.Reason = PluginLifecycleReasonMissingInstall
		return TenantPluginInstall{}, decision, ErrPluginLifecycleMissingInstall
	}
	if install.TenantID != tenantID {
		decision.Reason = PluginLifecycleReasonCrossTenant
		return TenantPluginInstall{}, decision, ErrPluginLifecycleCrossTenant
	}

	decision.PluginID = install.PluginID
	decision.Version = install.Version
	decision.FromStatus = install.Status

	if isTerminalPluginInstallStatus(install.Status) {
		decision.Reason = PluginLifecycleReasonTerminalInstall
		return TenantPluginInstall{}, decision, ErrPluginLifecycleTerminalInstall
	}

	if !validPluginLifecycleTransition(install.Status, targetStatus) {
		decision.Reason = PluginLifecycleReasonInvalidTransition
		return TenantPluginInstall{}, decision, ErrPluginLifecycleInvalidTransition
	}

	install.Status = targetStatus
	install.UpdatedAt = now
	install.UpdatedBy = strings.TrimSpace(req.ActorRef)
	if strings.TrimSpace(req.CorrelationID) != "" {
		install.CorrelationID = strings.TrimSpace(req.CorrelationID)
	}

	switch targetStatus {
	case PluginInstallStatusEnabled:
		install.EnabledAt = now
	case PluginInstallStatusDisabled:
		install.DisabledAt = now
	case PluginInstallStatusSuspended:
		install.SuspendedAt = now
	case PluginInstallStatusUninstalled:
		install.UninstalledAt = now
	}

	r.installs[installID] = install

	decision.Decision = PluginLifecycleDecisionAllow
	decision.Allowed = true
	decision.Reason = PluginLifecycleReasonAllowed

	return install, decision, nil
}

func (r *PluginLifecycleRuntime) findInstallLocked(tenantID string, pluginID string, version string) (TenantPluginInstall, bool) {
	for _, install := range r.installs {
		if install.TenantID == tenantID &&
			install.PluginID == pluginID &&
			install.Version == version &&
			install.Status != PluginInstallStatusUninstalled {
			return install, true
		}
	}
	return TenantPluginInstall{}, false
}

func validPluginLifecycleTransition(from string, to string) bool {
	switch from {
	case PluginInstallStatusInstalled:
		return to == PluginInstallStatusEnabled || to == PluginInstallStatusUninstalled
	case PluginInstallStatusEnabled:
		return to == PluginInstallStatusDisabled || to == PluginInstallStatusSuspended || to == PluginInstallStatusUninstalled
	case PluginInstallStatusDisabled:
		return to == PluginInstallStatusEnabled || to == PluginInstallStatusUninstalled
	case PluginInstallStatusSuspended:
		return to == PluginInstallStatusEnabled || to == PluginInstallStatusUninstalled
	default:
		return false
	}
}

func isTerminalPluginInstallStatus(status string) bool {
	return status == PluginInstallStatusUninstalled
}

func NewTenantPluginInstallID() string {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "plugin_install_" + strings.ReplaceAll(time.Now().UTC().Format("20060102150405.000000000"), ".", "")
	}
	return "plugin_install_" + hex.EncodeToString(raw[:])
}
