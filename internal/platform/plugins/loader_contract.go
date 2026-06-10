package plugins

import (
	"strings"
	"time"
)

var allowedPluginRuntimeModes = map[string]struct{}{
	"native":      {},
	"wasm":        {},
	"http_bridge": {},
}

var allowedPluginPermissionProfiles = map[string]struct{}{
	"read_only":  {},
	"tenant_ops": {},
	"system_ops": {},
}

type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

type ValidationErrors []ValidationError

func (v ValidationErrors) Error() string {
	if len(v) == 0 {
		return "validation failed"
	}

	parts := make([]string, 0, len(v))
	for _, item := range v {
		parts = append(parts, item.Field+": "+item.Message)
	}

	return strings.Join(parts, ", ")
}

func containsValue(values map[string]struct{}, value string) bool {
	_, ok := values[value]
	return ok
}

type LoadPluginRequest struct {
	TenantID    string `json:"tenant_id,omitempty"`
	PluginKey   string `json:"plugin_key"`
	RequestedBy string `json:"requested_by"`
}

type LoadPluginResponse struct {
	PluginKey          string    `json:"plugin_key"`
	Version            int       `json:"version"`
	RuntimeMode        string    `json:"runtime_mode,omitempty"`
	EntrypointRef      string    `json:"entrypoint_ref,omitempty"`
	PermissionProfile  string    `json:"permission_profile,omitempty"`
	SandboxRequired    bool      `json:"sandbox_required"`
	Loaded             bool      `json:"loaded"`
	LoadedAt           time.Time `json:"loaded_at"`
}

func (r LoadPluginRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !pluginKeyPattern.MatchString(strings.TrimSpace(r.PluginKey)) {
		errs = append(errs, ValidationError{
			Field:   "plugin_key",
			Message: "gecersiz format",
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

func (r LoadPluginResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !pluginKeyPattern.MatchString(strings.TrimSpace(r.PluginKey)) {
		errs = append(errs, ValidationError{
			Field:   "plugin_key",
			Message: "gecersiz format",
		})
	}

	if r.Loaded {
		if r.Version < 1 || r.Version > 1000 {
			errs = append(errs, ValidationError{
				Field:   "version",
				Message: "1-1000 araliginda olmali",
			})
		}

		if !containsValue(allowedPluginRuntimeModes, strings.TrimSpace(r.RuntimeMode)) {
			errs = append(errs, ValidationError{
				Field:   "runtime_mode",
				Message: "desteklenmeyen deger",
			})
		}

		if !pluginKeyPattern.MatchString(strings.TrimSpace(r.EntrypointRef)) {
			errs = append(errs, ValidationError{
				Field:   "entrypoint_ref",
				Message: "gecersiz format",
			})
		}

		if !containsValue(allowedPluginPermissionProfiles, strings.TrimSpace(r.PermissionProfile)) {
			errs = append(errs, ValidationError{
				Field:   "permission_profile",
				Message: "desteklenmeyen deger",
			})
		}
	}

	if r.LoadedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "loaded_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
