package plugins

import (
	"strings"
	"time"
)

var allowedPluginCompatibilityStatuses = map[string]struct{}{
	"compatible": {},
	"warning":    {},
	"blocked":    {},
}

type CheckPluginVersionCompatibilityRequest struct {
	TenantID       string `json:"tenant_id,omitempty"`
	PluginKey      string `json:"plugin_key"`
	PluginVersion  int    `json:"plugin_version"`
	RuntimeMode    string `json:"runtime_mode"`
	HostAPIVersion int    `json:"host_api_version"`
	RequestedBy    string `json:"requested_by"`
}

type CheckPluginVersionCompatibilityResponse struct {
	PluginKey                string    `json:"plugin_key"`
	PluginVersion            int       `json:"plugin_version"`
	RuntimeMode              string    `json:"runtime_mode"`
	HostAPIVersion           int       `json:"host_api_version"`
	MinSupportedHostVersion  int       `json:"min_supported_host_version"`
	MaxSupportedHostVersion  int       `json:"max_supported_host_version"`
	CompatibilityStatus      string    `json:"compatibility_status"`
	Compatible               bool      `json:"compatible"`
	Reason                   string    `json:"reason,omitempty"`
	CheckedAt                time.Time `json:"checked_at"`
}

func (r CheckPluginVersionCompatibilityRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !pluginKeyPattern.MatchString(strings.TrimSpace(r.PluginKey)) {
		errs = append(errs, ValidationError{
			Field:   "plugin_key",
			Message: "gecersiz format",
		})
	}

	if r.PluginVersion < 1 || r.PluginVersion > 1000 {
		errs = append(errs, ValidationError{
			Field:   "plugin_version",
			Message: "1-1000 araliginda olmali",
		})
	}

	if !containsValue(allowedPluginRuntimeModes, strings.TrimSpace(r.RuntimeMode)) {
		errs = append(errs, ValidationError{
			Field:   "runtime_mode",
			Message: "desteklenmeyen deger",
		})
	}

	if r.HostAPIVersion < 1 || r.HostAPIVersion > 1000 {
		errs = append(errs, ValidationError{
			Field:   "host_api_version",
			Message: "1-1000 araliginda olmali",
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

func (r CheckPluginVersionCompatibilityResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !pluginKeyPattern.MatchString(strings.TrimSpace(r.PluginKey)) {
		errs = append(errs, ValidationError{
			Field:   "plugin_key",
			Message: "gecersiz format",
		})
	}

	if r.PluginVersion < 1 || r.PluginVersion > 1000 {
		errs = append(errs, ValidationError{
			Field:   "plugin_version",
			Message: "1-1000 araliginda olmali",
		})
	}

	if !containsValue(allowedPluginRuntimeModes, strings.TrimSpace(r.RuntimeMode)) {
		errs = append(errs, ValidationError{
			Field:   "runtime_mode",
			Message: "desteklenmeyen deger",
		})
	}

	if r.HostAPIVersion < 1 || r.HostAPIVersion > 1000 {
		errs = append(errs, ValidationError{
			Field:   "host_api_version",
			Message: "1-1000 araliginda olmali",
		})
	}

	if r.MinSupportedHostVersion < 1 || r.MinSupportedHostVersion > 1000 {
		errs = append(errs, ValidationError{
			Field:   "min_supported_host_version",
			Message: "1-1000 araliginda olmali",
		})
	}

	if r.MaxSupportedHostVersion < 1 || r.MaxSupportedHostVersion > 1000 {
		errs = append(errs, ValidationError{
			Field:   "max_supported_host_version",
			Message: "1-1000 araliginda olmali",
		})
	}

	if r.MinSupportedHostVersion > r.MaxSupportedHostVersion {
		errs = append(errs, ValidationError{
			Field:   "supported_host_range",
			Message: "min max'tan buyuk olamaz",
		})
	}

	if !containsValue(allowedPluginCompatibilityStatuses, strings.TrimSpace(r.CompatibilityStatus)) {
		errs = append(errs, ValidationError{
			Field:   "compatibility_status",
			Message: "desteklenmeyen deger",
		})
	}

	if !r.Compatible && strings.TrimSpace(r.Reason) == "" {
		errs = append(errs, ValidationError{
			Field:   "reason",
			Message: "uyumsuz durumda zorunlu alan",
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
