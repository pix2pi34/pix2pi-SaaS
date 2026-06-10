package pluginruntime

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"strconv"
	"strings"
	"sync"
	"time"
)

const (
	PluginCompatibilityStateCompatible   = "COMPATIBLE"
	PluginCompatibilityStateIncompatible = "INCOMPATIBLE"

	PluginCompatibilityDecisionAllow = "ALLOW"
	PluginCompatibilityDecisionDeny  = "DENY"

	PluginCompatibilityReasonAllowed             = "PLUGIN_COMPATIBILITY_ALLOWED"
	PluginCompatibilityReasonMissingTenant       = "PLUGIN_COMPATIBILITY_MISSING_TENANT"
	PluginCompatibilityReasonMissingManifest     = "PLUGIN_COMPATIBILITY_MISSING_MANIFEST"
	PluginCompatibilityReasonMissingPlugin       = "PLUGIN_COMPATIBILITY_MISSING_PLUGIN"
	PluginCompatibilityReasonMissingVersion      = "PLUGIN_COMPATIBILITY_MISSING_VERSION"
	PluginCompatibilityReasonMissingRuntime      = "PLUGIN_COMPATIBILITY_MISSING_RUNTIME_VERSION"
	PluginCompatibilityReasonMissingHostRuntime  = "PLUGIN_COMPATIBILITY_MISSING_HOST_RUNTIME"
	PluginCompatibilityReasonCrossTenant         = "PLUGIN_COMPATIBILITY_CROSS_TENANT_DENIED"
	PluginCompatibilityReasonInvalidRuntime      = "PLUGIN_COMPATIBILITY_INVALID_RUNTIME_VERSION"
	PluginCompatibilityReasonBelowMinimum        = "PLUGIN_COMPATIBILITY_BELOW_MINIMUM_RUNTIME"
	PluginCompatibilityReasonAboveMaximum        = "PLUGIN_COMPATIBILITY_ABOVE_MAXIMUM_RUNTIME"
	PluginCompatibilityReasonEnvironmentMismatch = "PLUGIN_COMPATIBILITY_ENVIRONMENT_MISMATCH"
)

var (
	ErrPluginCompatibilityMissingTenant       = errors.New("missing plugin compatibility tenant id")
	ErrPluginCompatibilityMissingManifest     = errors.New("missing plugin compatibility manifest")
	ErrPluginCompatibilityMissingPlugin       = errors.New("missing plugin id")
	ErrPluginCompatibilityMissingVersion      = errors.New("missing plugin version")
	ErrPluginCompatibilityMissingRuntime      = errors.New("missing plugin runtime version")
	ErrPluginCompatibilityMissingHostRuntime  = errors.New("missing host runtime version")
	ErrPluginCompatibilityCrossTenant         = errors.New("cross-tenant plugin compatibility access denied")
	ErrPluginCompatibilityInvalidRuntime      = errors.New("invalid plugin runtime version")
	ErrPluginCompatibilityBelowMinimum        = errors.New("plugin runtime version below minimum supported")
	ErrPluginCompatibilityAboveMaximum        = errors.New("plugin runtime version above maximum supported")
	ErrPluginCompatibilityEnvironmentMismatch = errors.New("plugin runtime environment mismatch")
)

type PluginVersionCompatibilityRuntimeConfig struct {
	RequireTenant                  bool   `json:"require_tenant"`
	RequiredRuntimePrefix          string `json:"required_runtime_prefix"`
	HostRuntimeVersion             string `json:"host_runtime_version"`
	MinimumSupportedRuntimeVersion string `json:"minimum_supported_runtime_version"`
	MaximumSupportedRuntimeVersion string `json:"maximum_supported_runtime_version"`
	Environment                    string `json:"environment"`
}

func DefaultPluginVersionCompatibilityRuntimeConfig() PluginVersionCompatibilityRuntimeConfig {
	return PluginVersionCompatibilityRuntimeConfig{
		RequireTenant:                  true,
		RequiredRuntimePrefix:          "pix2pi-plugin-runtime/",
		HostRuntimeVersion:             "pix2pi-plugin-runtime/v1.0.0",
		MinimumSupportedRuntimeVersion: "pix2pi-plugin-runtime/v1.0.0",
		MaximumSupportedRuntimeVersion: "pix2pi-plugin-runtime/v1.9.9",
		Environment:                    PluginEnvironmentSandbox,
	}
}

type PluginHostRuntimeVersion struct {
	RuntimeVersion  string `json:"runtime_version"`
	MinSupported    string `json:"min_supported"`
	MaxSupported    string `json:"max_supported"`
	Environment     string `json:"environment"`
	HostBuild       string `json:"host_build,omitempty"`
	CompatibilityID string `json:"compatibility_id,omitempty"`
}

type PluginCompatibilityCheckRequest struct {
	TenantID           string                   `json:"tenant_id"`
	Manifest           PluginManifest           `json:"manifest"`
	HostRuntimeVersion PluginHostRuntimeVersion `json:"host_runtime_version,omitempty"`
	ActorRef           string                   `json:"actor_ref,omitempty"`
	CorrelationID      string                   `json:"correlation_id,omitempty"`
}

type PluginCompatibilityState struct {
	TenantID      string `json:"tenant_id"`
	StateID       string `json:"state_id"`
	PluginID      string `json:"plugin_id"`
	Version       string `json:"version"`
	PluginRuntime string `json:"plugin_runtime"`
	HostRuntime   string `json:"host_runtime"`
	MinSupported  string `json:"min_supported"`
	MaxSupported  string `json:"max_supported"`
	Environment   string `json:"environment"`
	Compatibility string `json:"compatibility"`
	ActorRef      string `json:"actor_ref,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
	CheckedAt     string `json:"checked_at"`
}

type PluginCompatibilityDecision struct {
	Decision      string `json:"decision"`
	Allowed       bool   `json:"allowed"`
	TenantID      string `json:"tenant_id"`
	StateID       string `json:"state_id,omitempty"`
	PluginID      string `json:"plugin_id,omitempty"`
	Version       string `json:"version,omitempty"`
	PluginRuntime string `json:"plugin_runtime,omitempty"`
	HostRuntime   string `json:"host_runtime,omitempty"`
	MinSupported  string `json:"min_supported,omitempty"`
	MaxSupported  string `json:"max_supported,omitempty"`
	Environment   string `json:"environment,omitempty"`
	Compatibility string `json:"compatibility,omitempty"`
	ActorRef      string `json:"actor_ref,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
	Reason        string `json:"reason"`
	CheckedAt     string `json:"checked_at"`
}

type PluginVersionCompatibilityRuntime struct {
	config PluginVersionCompatibilityRuntimeConfig
	mu     sync.RWMutex
	states map[string]PluginCompatibilityState
}

func NewPluginVersionCompatibilityRuntime(config PluginVersionCompatibilityRuntimeConfig) *PluginVersionCompatibilityRuntime {
	defaults := DefaultPluginVersionCompatibilityRuntimeConfig()

	if strings.TrimSpace(config.RequiredRuntimePrefix) == "" {
		config.RequiredRuntimePrefix = defaults.RequiredRuntimePrefix
	}
	if strings.TrimSpace(config.HostRuntimeVersion) == "" {
		config.HostRuntimeVersion = defaults.HostRuntimeVersion
	}
	if strings.TrimSpace(config.MinimumSupportedRuntimeVersion) == "" {
		config.MinimumSupportedRuntimeVersion = defaults.MinimumSupportedRuntimeVersion
	}
	if strings.TrimSpace(config.MaximumSupportedRuntimeVersion) == "" {
		config.MaximumSupportedRuntimeVersion = defaults.MaximumSupportedRuntimeVersion
	}
	if strings.TrimSpace(config.Environment) == "" {
		config.Environment = defaults.Environment
	}

	return &PluginVersionCompatibilityRuntime{
		config: config,
		states: make(map[string]PluginCompatibilityState),
	}
}

func (r *PluginVersionCompatibilityRuntime) CheckCompatibility(req PluginCompatibilityCheckRequest) (PluginCompatibilityState, PluginCompatibilityDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	manifest := req.Manifest
	manifest.TenantID = strings.TrimSpace(manifest.TenantID)
	manifest.PluginID = strings.TrimSpace(manifest.PluginID)
	manifest.Version = strings.TrimSpace(manifest.Version)
	manifest.RuntimeVersion = strings.TrimSpace(manifest.RuntimeVersion)
	manifest.Environment = normalizePluginEnvironment(manifest.Environment)

	host := r.normalizeHostRuntime(req.HostRuntimeVersion)

	decision := PluginCompatibilityDecision{
		Decision:      PluginCompatibilityDecisionDeny,
		Allowed:       false,
		TenantID:      tenantID,
		PluginID:      manifest.PluginID,
		Version:       manifest.Version,
		PluginRuntime: manifest.RuntimeVersion,
		HostRuntime:   host.RuntimeVersion,
		MinSupported:  host.MinSupported,
		MaxSupported:  host.MaxSupported,
		Environment:   host.Environment,
		Compatibility: PluginCompatibilityStateIncompatible,
		ActorRef:      strings.TrimSpace(req.ActorRef),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		Reason:        PluginCompatibilityReasonAllowed,
		CheckedAt:     now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = PluginCompatibilityReasonMissingTenant
		return PluginCompatibilityState{}, decision, ErrPluginCompatibilityMissingTenant
	}

	if manifest.PluginID == "" {
		decision.Reason = PluginCompatibilityReasonMissingPlugin
		return PluginCompatibilityState{}, decision, ErrPluginCompatibilityMissingPlugin
	}

	if manifest.Version == "" {
		decision.Reason = PluginCompatibilityReasonMissingVersion
		return PluginCompatibilityState{}, decision, ErrPluginCompatibilityMissingVersion
	}

	if manifest.RuntimeVersion == "" {
		decision.Reason = PluginCompatibilityReasonMissingRuntime
		return PluginCompatibilityState{}, decision, ErrPluginCompatibilityMissingRuntime
	}

	if manifest.TenantID == "" {
		decision.Reason = PluginCompatibilityReasonMissingTenant
		return PluginCompatibilityState{}, decision, ErrPluginCompatibilityMissingTenant
	}

	if manifest.TenantID != tenantID {
		decision.Reason = PluginCompatibilityReasonCrossTenant
		return PluginCompatibilityState{}, decision, ErrPluginCompatibilityCrossTenant
	}

	if host.RuntimeVersion == "" || host.MinSupported == "" || host.MaxSupported == "" {
		decision.Reason = PluginCompatibilityReasonMissingHostRuntime
		return PluginCompatibilityState{}, decision, ErrPluginCompatibilityMissingHostRuntime
	}

	if normalizePluginEnvironment(host.Environment) != manifest.Environment {
		decision.Reason = PluginCompatibilityReasonEnvironmentMismatch
		return PluginCompatibilityState{}, decision, ErrPluginCompatibilityEnvironmentMismatch
	}

	pluginVersion, err := ParsePluginRuntimeVersion(manifest.RuntimeVersion, r.config.RequiredRuntimePrefix)
	if err != nil {
		decision.Reason = PluginCompatibilityReasonInvalidRuntime
		return PluginCompatibilityState{}, decision, ErrPluginCompatibilityInvalidRuntime
	}

	minVersion, err := ParsePluginRuntimeVersion(host.MinSupported, r.config.RequiredRuntimePrefix)
	if err != nil {
		decision.Reason = PluginCompatibilityReasonInvalidRuntime
		return PluginCompatibilityState{}, decision, ErrPluginCompatibilityInvalidRuntime
	}

	maxVersion, err := ParsePluginRuntimeVersion(host.MaxSupported, r.config.RequiredRuntimePrefix)
	if err != nil {
		decision.Reason = PluginCompatibilityReasonInvalidRuntime
		return PluginCompatibilityState{}, decision, ErrPluginCompatibilityInvalidRuntime
	}

	if ComparePluginRuntimeVersion(pluginVersion, minVersion) < 0 {
		decision.Reason = PluginCompatibilityReasonBelowMinimum
		return PluginCompatibilityState{}, decision, ErrPluginCompatibilityBelowMinimum
	}

	if ComparePluginRuntimeVersion(pluginVersion, maxVersion) > 0 {
		decision.Reason = PluginCompatibilityReasonAboveMaximum
		return PluginCompatibilityState{}, decision, ErrPluginCompatibilityAboveMaximum
	}

	state := PluginCompatibilityState{
		TenantID:      tenantID,
		StateID:       NewPluginCompatibilityStateID(),
		PluginID:      manifest.PluginID,
		Version:       manifest.Version,
		PluginRuntime: manifest.RuntimeVersion,
		HostRuntime:   host.RuntimeVersion,
		MinSupported:  host.MinSupported,
		MaxSupported:  host.MaxSupported,
		Environment:   host.Environment,
		Compatibility: PluginCompatibilityStateCompatible,
		ActorRef:      strings.TrimSpace(req.ActorRef),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		CheckedAt:     now,
	}

	r.mu.Lock()
	r.states[PluginCompatibilityKey(tenantID, manifest.PluginID, manifest.Version)] = state
	r.mu.Unlock()

	decision.Decision = PluginCompatibilityDecisionAllow
	decision.Allowed = true
	decision.StateID = state.StateID
	decision.Compatibility = PluginCompatibilityStateCompatible
	decision.Reason = PluginCompatibilityReasonAllowed

	return state, decision, nil
}

func (r *PluginVersionCompatibilityRuntime) GetCompatibilityState(tenantID string, pluginID string, version string) (PluginCompatibilityState, error) {
	tenantID = strings.TrimSpace(tenantID)
	pluginID = strings.TrimSpace(pluginID)
	version = strings.TrimSpace(version)

	if tenantID == "" {
		return PluginCompatibilityState{}, ErrPluginCompatibilityMissingTenant
	}
	if pluginID == "" {
		return PluginCompatibilityState{}, ErrPluginCompatibilityMissingPlugin
	}
	if version == "" {
		return PluginCompatibilityState{}, ErrPluginCompatibilityMissingVersion
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	state, ok := r.states[PluginCompatibilityKey(tenantID, pluginID, version)]
	if !ok {
		return PluginCompatibilityState{}, ErrPluginCompatibilityMissingManifest
	}

	if state.TenantID != tenantID {
		return PluginCompatibilityState{}, ErrPluginCompatibilityCrossTenant
	}

	return state, nil
}

func (r *PluginVersionCompatibilityRuntime) ListTenantCompatibilityStates(tenantID string) ([]PluginCompatibilityState, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrPluginCompatibilityMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]PluginCompatibilityState, 0)
	for _, state := range r.states {
		if state.TenantID == tenantID {
			out = append(out, state)
		}
	}

	return out, nil
}

func (r *PluginVersionCompatibilityRuntime) normalizeHostRuntime(host PluginHostRuntimeVersion) PluginHostRuntimeVersion {
	host.RuntimeVersion = strings.TrimSpace(host.RuntimeVersion)
	host.MinSupported = strings.TrimSpace(host.MinSupported)
	host.MaxSupported = strings.TrimSpace(host.MaxSupported)
	host.Environment = normalizePluginEnvironment(host.Environment)

	if host.RuntimeVersion == "" {
		host.RuntimeVersion = r.config.HostRuntimeVersion
	}
	if host.MinSupported == "" {
		host.MinSupported = r.config.MinimumSupportedRuntimeVersion
	}
	if host.MaxSupported == "" {
		host.MaxSupported = r.config.MaximumSupportedRuntimeVersion
	}
	if strings.TrimSpace(host.Environment) == "" {
		host.Environment = r.config.Environment
	}
	return host
}

func ParsePluginRuntimeVersion(value string, requiredPrefix string) ([3]int, error) {
	var parsed [3]int

	value = strings.TrimSpace(value)
	requiredPrefix = strings.TrimSpace(requiredPrefix)

	if value == "" {
		return parsed, ErrPluginCompatibilityMissingRuntime
	}

	if requiredPrefix != "" {
		if !strings.HasPrefix(value, requiredPrefix) {
			return parsed, ErrPluginCompatibilityInvalidRuntime
		}
		value = strings.TrimPrefix(value, requiredPrefix)
	}

	value = strings.TrimSpace(value)
	value = strings.TrimPrefix(strings.ToLower(value), "v")
	if value == "" {
		return parsed, ErrPluginCompatibilityInvalidRuntime
	}

	parts := strings.Split(value, ".")
	if len(parts) > 3 {
		return parsed, ErrPluginCompatibilityInvalidRuntime
	}

	for index := 0; index < 3; index++ {
		if index >= len(parts) {
			parsed[index] = 0
			continue
		}

		part := strings.TrimSpace(parts[index])
		if part == "" {
			return parsed, ErrPluginCompatibilityInvalidRuntime
		}

		number, err := strconv.Atoi(part)
		if err != nil || number < 0 {
			return parsed, ErrPluginCompatibilityInvalidRuntime
		}
		parsed[index] = number
	}

	return parsed, nil
}

func ComparePluginRuntimeVersion(left [3]int, right [3]int) int {
	for index := 0; index < 3; index++ {
		if left[index] < right[index] {
			return -1
		}
		if left[index] > right[index] {
			return 1
		}
	}
	return 0
}

func PluginCompatibilityKey(tenantID string, pluginID string, version string) string {
	return strings.TrimSpace(tenantID) + ":" + strings.TrimSpace(pluginID) + ":" + strings.TrimSpace(version)
}

func NewPluginCompatibilityStateID() string {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "plugin_compat_" + strings.ReplaceAll(time.Now().UTC().Format("20060102150405.000000000"), ".", "")
	}
	return "plugin_compat_" + hex.EncodeToString(raw[:])
}
