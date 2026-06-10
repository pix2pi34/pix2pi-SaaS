package plugins

import (
	"regexp"
	"strings"
	"time"
)

var (
	pluginSandboxIsolationModePattern = regexp.MustCompile(`^[a-z][a-z0-9_]*$`)
	pluginSandboxNetworkPolicyPattern = regexp.MustCompile(`^[a-z][a-z0-9_]*$`)
)

var allowedPluginSandboxIsolationModes = map[string]struct{}{
	"tenant_process":   {},
	"tenant_namespace": {},
	"tenant_vm":        {},
}

var allowedPluginSandboxNetworkPolicies = map[string]struct{}{
	"disabled":          {},
	"tenant_internal":   {},
	"tenant_egress_only": {},
}

type EnsurePluginSandboxRequest struct {
	TenantID          string `json:"tenant_id,omitempty"`
	PluginKey         string `json:"plugin_key"`
	RuntimeMode       string `json:"runtime_mode"`
	PermissionProfile string `json:"permission_profile"`
	RequestedBy       string `json:"requested_by"`
}

type EnsurePluginSandboxResponse struct {
	PluginKey         string    `json:"plugin_key"`
	RuntimeMode       string    `json:"runtime_mode"`
	PermissionProfile string    `json:"permission_profile"`
	SandboxID         string    `json:"sandbox_id,omitempty"`
	IsolationMode     string    `json:"isolation_mode,omitempty"`
	NetworkPolicy     string    `json:"network_policy,omitempty"`
	TenantScoped      bool      `json:"tenant_scoped"`
	Ready             bool      `json:"ready"`
	DenialReason      string    `json:"denial_reason,omitempty"`
	CheckedAt         time.Time `json:"checked_at"`
}

func (r EnsurePluginSandboxRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !pluginKeyPattern.MatchString(strings.TrimSpace(r.PluginKey)) {
		errs = append(errs, ValidationError{
			Field:   "plugin_key",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedPluginRuntimeModes, strings.TrimSpace(r.RuntimeMode)) {
		errs = append(errs, ValidationError{
			Field:   "runtime_mode",
			Message: "desteklenmeyen deger",
		})
	}

	if !containsValue(allowedPluginPermissionProfiles, strings.TrimSpace(r.PermissionProfile)) {
		errs = append(errs, ValidationError{
			Field:   "permission_profile",
			Message: "desteklenmeyen deger",
		})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{
			Field:   "requested_by",
			Message: "gecersiz format",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r EnsurePluginSandboxResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !pluginKeyPattern.MatchString(strings.TrimSpace(r.PluginKey)) {
		errs = append(errs, ValidationError{
			Field:   "plugin_key",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedPluginRuntimeModes, strings.TrimSpace(r.RuntimeMode)) {
		errs = append(errs, ValidationError{
			Field:   "runtime_mode",
			Message: "desteklenmeyen deger",
		})
	}

	if !containsValue(allowedPluginPermissionProfiles, strings.TrimSpace(r.PermissionProfile)) {
		errs = append(errs, ValidationError{
			Field:   "permission_profile",
			Message: "desteklenmeyen deger",
		})
	}

	if r.Ready {
		if !pluginKeyPattern.MatchString(strings.TrimSpace(r.SandboxID)) {
			errs = append(errs, ValidationError{
				Field:   "sandbox_id",
				Message: "gecersiz format",
			})
		}

		if !pluginSandboxIsolationModePattern.MatchString(strings.TrimSpace(r.IsolationMode)) || !containsValue(allowedPluginSandboxIsolationModes, strings.TrimSpace(r.IsolationMode)) {
			errs = append(errs, ValidationError{
				Field:   "isolation_mode",
				Message: "desteklenmeyen veya gecersiz format",
			})
		}

		if !pluginSandboxNetworkPolicyPattern.MatchString(strings.TrimSpace(r.NetworkPolicy)) || !containsValue(allowedPluginSandboxNetworkPolicies, strings.TrimSpace(r.NetworkPolicy)) {
			errs = append(errs, ValidationError{
				Field:   "network_policy",
				Message: "desteklenmeyen veya gecersiz format",
			})
		}

		if !r.TenantScoped {
			errs = append(errs, ValidationError{
				Field:   "tenant_scoped",
				Message: "true olmali",
			})
		}
	}

	if !r.Ready && strings.TrimSpace(r.DenialReason) == "" {
		errs = append(errs, ValidationError{
			Field:   "denial_reason",
			Message: "hazir degilse zorunlu alan",
		})
	}

	if r.CheckedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "checked_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
