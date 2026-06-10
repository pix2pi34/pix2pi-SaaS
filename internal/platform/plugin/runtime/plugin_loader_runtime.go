package pluginruntime

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	PluginEnvironmentSandbox    = "SANDBOX"
	PluginEnvironmentProduction = "PRODUCTION"

	PluginManifestStatusLoaded = "LOADED"

	PluginLoaderDecisionAllow = "ALLOW"
	PluginLoaderDecisionDeny  = "DENY"

	PluginLoaderReasonAllowed               = "PLUGIN_LOADER_ALLOWED"
	PluginLoaderReasonMissingTenant         = "PLUGIN_LOADER_MISSING_TENANT"
	PluginLoaderReasonMissingManifest       = "PLUGIN_LOADER_MISSING_MANIFEST"
	PluginLoaderReasonInvalidManifest       = "PLUGIN_LOADER_INVALID_MANIFEST"
	PluginLoaderReasonMissingPluginID       = "PLUGIN_LOADER_MISSING_PLUGIN_ID"
	PluginLoaderReasonMissingName           = "PLUGIN_LOADER_MISSING_NAME"
	PluginLoaderReasonMissingVersion        = "PLUGIN_LOADER_MISSING_VERSION"
	PluginLoaderReasonMissingRuntimeVersion = "PLUGIN_LOADER_MISSING_RUNTIME_VERSION"
	PluginLoaderReasonMissingEntryPoint     = "PLUGIN_LOADER_MISSING_ENTRYPOINT"
	PluginLoaderReasonMissingPermission     = "PLUGIN_LOADER_MISSING_PERMISSION"
	PluginLoaderReasonInvalidPermission     = "PLUGIN_LOADER_INVALID_PERMISSION"
	PluginLoaderReasonInvalidEnvironment    = "PLUGIN_LOADER_INVALID_ENVIRONMENT"
	PluginLoaderReasonCrossTenant           = "PLUGIN_LOADER_CROSS_TENANT_DENIED"
)

var (
	ErrPluginLoaderMissingTenant         = errors.New("missing plugin loader tenant id")
	ErrPluginLoaderMissingManifest       = errors.New("missing plugin manifest")
	ErrPluginLoaderInvalidManifest       = errors.New("invalid plugin manifest")
	ErrPluginLoaderMissingPluginID       = errors.New("missing plugin id")
	ErrPluginLoaderMissingName           = errors.New("missing plugin name")
	ErrPluginLoaderMissingVersion        = errors.New("missing plugin version")
	ErrPluginLoaderMissingRuntimeVersion = errors.New("missing plugin runtime version")
	ErrPluginLoaderMissingEntryPoint     = errors.New("missing plugin entrypoint")
	ErrPluginLoaderMissingPermission     = errors.New("missing plugin permission")
	ErrPluginLoaderInvalidPermission     = errors.New("invalid plugin permission")
	ErrPluginLoaderInvalidEnvironment    = errors.New("invalid plugin environment")
	ErrPluginLoaderCrossTenant           = errors.New("cross-tenant plugin load denied")
)

type PluginLoaderRuntimeConfig struct {
	RequireTenant         bool     `json:"require_tenant"`
	RequiredRuntimePrefix string   `json:"required_runtime_prefix"`
	AllowedPermissions    []string `json:"allowed_permissions"`
	AllowedEnvironments   []string `json:"allowed_environments"`
}

func DefaultPluginLoaderRuntimeConfig() PluginLoaderRuntimeConfig {
	return PluginLoaderRuntimeConfig{
		RequireTenant:         true,
		RequiredRuntimePrefix: "pix2pi-plugin-runtime/",
		AllowedPermissions: []string{
			"erp:read",
			"erp:write",
			"webhook:emit",
			"public_api:read",
			"public_api:write",
			"workflow:trigger",
			"notification:send",
			"report:read",
		},
		AllowedEnvironments: []string{
			PluginEnvironmentSandbox,
			PluginEnvironmentProduction,
		},
	}
}

type PluginCapability struct {
	Code        string `json:"code"`
	Description string `json:"description,omitempty"`
}

type PluginManifest struct {
	TenantID       string             `json:"tenant_id"`
	PluginID       string             `json:"plugin_id"`
	Name           string             `json:"name"`
	Version        string             `json:"version"`
	RuntimeVersion string             `json:"runtime_version"`
	EntryPoint     string             `json:"entrypoint"`
	Environment    string             `json:"environment"`
	Permissions    []string           `json:"permissions"`
	Capabilities   []PluginCapability `json:"capabilities,omitempty"`
	Metadata       map[string]string  `json:"metadata,omitempty"`
	Status         string             `json:"status,omitempty"`
	LoadedAt       string             `json:"loaded_at,omitempty"`
	CorrelationID  string             `json:"correlation_id,omitempty"`
}

type PluginLoadRequest struct {
	TenantID      string `json:"tenant_id"`
	RawManifest   []byte `json:"raw_manifest"`
	CorrelationID string `json:"correlation_id,omitempty"`
}

type PluginLoadDecision struct {
	Decision    string   `json:"decision"`
	Allowed     bool     `json:"allowed"`
	TenantID    string   `json:"tenant_id"`
	PluginID    string   `json:"plugin_id,omitempty"`
	Version     string   `json:"version,omitempty"`
	Environment string   `json:"environment,omitempty"`
	Permissions []string `json:"permissions,omitempty"`
	Reason      string   `json:"reason"`
	CheckedAt   string   `json:"checked_at"`
}

type PluginLoaderRuntime struct {
	config PluginLoaderRuntimeConfig
	mu     sync.RWMutex
	loaded map[string]PluginManifest
}

func NewPluginLoaderRuntime(config PluginLoaderRuntimeConfig) *PluginLoaderRuntime {
	if strings.TrimSpace(config.RequiredRuntimePrefix) == "" {
		config.RequiredRuntimePrefix = DefaultPluginLoaderRuntimeConfig().RequiredRuntimePrefix
	}
	if len(config.AllowedPermissions) == 0 {
		config.AllowedPermissions = DefaultPluginLoaderRuntimeConfig().AllowedPermissions
	}
	if len(config.AllowedEnvironments) == 0 {
		config.AllowedEnvironments = DefaultPluginLoaderRuntimeConfig().AllowedEnvironments
	}

	return &PluginLoaderRuntime{
		config: config,
		loaded: make(map[string]PluginManifest),
	}
}

func (r *PluginLoaderRuntime) LoadManifestJSON(req PluginLoadRequest) (PluginManifest, PluginLoadDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)

	decision := PluginLoadDecision{
		Decision:  PluginLoaderDecisionDeny,
		Allowed:   false,
		TenantID:  tenantID,
		Reason:    PluginLoaderReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = PluginLoaderReasonMissingTenant
		return PluginManifest{}, decision, ErrPluginLoaderMissingTenant
	}

	if len(req.RawManifest) == 0 {
		decision.Reason = PluginLoaderReasonMissingManifest
		return PluginManifest{}, decision, ErrPluginLoaderMissingManifest
	}

	var manifest PluginManifest
	if err := json.Unmarshal(req.RawManifest, &manifest); err != nil {
		decision.Reason = PluginLoaderReasonInvalidManifest
		return PluginManifest{}, decision, ErrPluginLoaderInvalidManifest
	}

	manifest.TenantID = strings.TrimSpace(manifest.TenantID)
	manifest.PluginID = strings.TrimSpace(manifest.PluginID)
	manifest.Name = strings.TrimSpace(manifest.Name)
	manifest.Version = strings.TrimSpace(manifest.Version)
	manifest.RuntimeVersion = strings.TrimSpace(manifest.RuntimeVersion)
	manifest.EntryPoint = strings.TrimSpace(manifest.EntryPoint)
	manifest.Environment = normalizePluginEnvironment(manifest.Environment)
	manifest.CorrelationID = strings.TrimSpace(req.CorrelationID)

	decision.PluginID = manifest.PluginID
	decision.Version = manifest.Version
	decision.Environment = manifest.Environment

	if manifest.TenantID == "" {
		decision.Reason = PluginLoaderReasonMissingTenant
		return PluginManifest{}, decision, ErrPluginLoaderMissingTenant
	}

	if manifest.TenantID != tenantID {
		decision.Reason = PluginLoaderReasonCrossTenant
		return PluginManifest{}, decision, ErrPluginLoaderCrossTenant
	}

	if err := r.validateManifest(manifest); err != nil {
		decision.Reason = reasonForPluginLoaderError(err)
		return PluginManifest{}, decision, err
	}

	permissions, err := r.normalizeAndValidatePermissions(manifest.Permissions)
	if err != nil {
		decision.Reason = reasonForPluginLoaderError(err)
		return PluginManifest{}, decision, err
	}

	manifest.Permissions = permissions
	manifest.Status = PluginManifestStatusLoaded
	manifest.LoadedAt = now

	key := PluginManifestKey(manifest.TenantID, manifest.PluginID, manifest.Version)

	r.mu.Lock()
	r.loaded[key] = manifest
	r.mu.Unlock()

	decision.Decision = PluginLoaderDecisionAllow
	decision.Allowed = true
	decision.Permissions = permissions
	decision.Reason = PluginLoaderReasonAllowed

	return manifest, decision, nil
}

func (r *PluginLoaderRuntime) GetLoadedPlugin(tenantID string, pluginID string, version string) (PluginManifest, error) {
	tenantID = strings.TrimSpace(tenantID)
	pluginID = strings.TrimSpace(pluginID)
	version = strings.TrimSpace(version)

	if tenantID == "" {
		return PluginManifest{}, ErrPluginLoaderMissingTenant
	}
	if pluginID == "" {
		return PluginManifest{}, ErrPluginLoaderMissingPluginID
	}
	if version == "" {
		return PluginManifest{}, ErrPluginLoaderMissingVersion
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	manifest, ok := r.loaded[PluginManifestKey(tenantID, pluginID, version)]
	if !ok {
		return PluginManifest{}, ErrPluginLoaderMissingManifest
	}

	if manifest.TenantID != tenantID {
		return PluginManifest{}, ErrPluginLoaderCrossTenant
	}

	return manifest, nil
}

func (r *PluginLoaderRuntime) ListTenantPlugins(tenantID string) ([]PluginManifest, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrPluginLoaderMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]PluginManifest, 0)
	for _, manifest := range r.loaded {
		if manifest.TenantID == tenantID {
			out = append(out, manifest)
		}
	}

	return out, nil
}

func (r *PluginLoaderRuntime) validateManifest(manifest PluginManifest) error {
	if manifest.PluginID == "" {
		return ErrPluginLoaderMissingPluginID
	}
	if manifest.Name == "" {
		return ErrPluginLoaderMissingName
	}
	if manifest.Version == "" {
		return ErrPluginLoaderMissingVersion
	}
	if manifest.RuntimeVersion == "" {
		return ErrPluginLoaderMissingRuntimeVersion
	}
	if r.config.RequiredRuntimePrefix != "" && !strings.HasPrefix(manifest.RuntimeVersion, r.config.RequiredRuntimePrefix) {
		return ErrPluginLoaderMissingRuntimeVersion
	}
	if manifest.EntryPoint == "" {
		return ErrPluginLoaderMissingEntryPoint
	}
	if !r.environmentAllowed(manifest.Environment) {
		return ErrPluginLoaderInvalidEnvironment
	}
	return nil
}

func (r *PluginLoaderRuntime) normalizeAndValidatePermissions(permissions []string) ([]string, error) {
	if len(permissions) == 0 {
		return nil, ErrPluginLoaderMissingPermission
	}

	seen := map[string]struct{}{}
	out := make([]string, 0, len(permissions))

	for _, permission := range permissions {
		permission = strings.TrimSpace(permission)
		if permission == "" {
			continue
		}
		if !r.permissionAllowed(permission) {
			return nil, ErrPluginLoaderInvalidPermission
		}
		if _, ok := seen[permission]; ok {
			continue
		}
		seen[permission] = struct{}{}
		out = append(out, permission)
	}

	if len(out) == 0 {
		return nil, ErrPluginLoaderMissingPermission
	}

	return out, nil
}

func (r *PluginLoaderRuntime) permissionAllowed(permission string) bool {
	for _, allowed := range r.config.AllowedPermissions {
		if strings.EqualFold(strings.TrimSpace(allowed), strings.TrimSpace(permission)) {
			return true
		}
	}
	return false
}

func (r *PluginLoaderRuntime) environmentAllowed(environment string) bool {
	for _, allowed := range r.config.AllowedEnvironments {
		if strings.EqualFold(strings.TrimSpace(allowed), strings.TrimSpace(environment)) {
			return true
		}
	}
	return false
}

func PluginManifestKey(tenantID string, pluginID string, version string) string {
	return strings.TrimSpace(tenantID) + ":" + strings.TrimSpace(pluginID) + ":" + strings.TrimSpace(version)
}

func normalizePluginEnvironment(environment string) string {
	environment = strings.TrimSpace(environment)
	if environment == "" {
		return PluginEnvironmentSandbox
	}
	return strings.ToUpper(environment)
}

func reasonForPluginLoaderError(err error) string {
	switch err {
	case ErrPluginLoaderMissingTenant:
		return PluginLoaderReasonMissingTenant
	case ErrPluginLoaderMissingManifest:
		return PluginLoaderReasonMissingManifest
	case ErrPluginLoaderInvalidManifest:
		return PluginLoaderReasonInvalidManifest
	case ErrPluginLoaderMissingPluginID:
		return PluginLoaderReasonMissingPluginID
	case ErrPluginLoaderMissingName:
		return PluginLoaderReasonMissingName
	case ErrPluginLoaderMissingVersion:
		return PluginLoaderReasonMissingVersion
	case ErrPluginLoaderMissingRuntimeVersion:
		return PluginLoaderReasonMissingRuntimeVersion
	case ErrPluginLoaderMissingEntryPoint:
		return PluginLoaderReasonMissingEntryPoint
	case ErrPluginLoaderMissingPermission:
		return PluginLoaderReasonMissingPermission
	case ErrPluginLoaderInvalidPermission:
		return PluginLoaderReasonInvalidPermission
	case ErrPluginLoaderInvalidEnvironment:
		return PluginLoaderReasonInvalidEnvironment
	case ErrPluginLoaderCrossTenant:
		return PluginLoaderReasonCrossTenant
	default:
		return PluginLoaderReasonInvalidManifest
	}
}

func NewPluginRuntimeLoadID() string {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "plugin_load_" + strings.ReplaceAll(time.Now().UTC().Format("20060102150405.000000000"), ".", "")
	}
	return "plugin_load_" + hex.EncodeToString(raw[:])
}
