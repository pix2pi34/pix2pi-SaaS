package plugins

import (
	"regexp"
	"strings"
	"time"
)

var (
	pluginPermissionOperationPattern = regexp.MustCompile(`^[a-z][a-z0-9_]*$`)
	pluginPermissionScopePattern     = regexp.MustCompile(`^[a-z][a-z0-9_]*$`)
)

var allowedPluginPermissionOperations = map[string]struct{}{
	"read":    {},
	"write":   {},
	"execute": {},
	"admin":   {},
}

var allowedPluginPermissionScopes = map[string]struct{}{
	"tenant_data":     {},
	"tenant_runtime":  {},
	"platform_runtime": {},
	"system_config":   {},
}

type EvaluatePluginPermissionRequest struct {
	TenantID          string `json:"tenant_id,omitempty"`
	PluginKey         string `json:"plugin_key"`
	PermissionProfile string `json:"permission_profile"`
	Operation         string `json:"operation"`
	ResourceScope     string `json:"resource_scope"`
	RequestedBy       string `json:"requested_by"`
}

type EvaluatePluginPermissionResponse struct {
	PluginKey         string    `json:"plugin_key"`
	PermissionProfile string    `json:"permission_profile"`
	Operation         string    `json:"operation"`
	ResourceScope     string    `json:"resource_scope"`
	Permitted         bool      `json:"permitted"`
	DenialReason      string    `json:"denial_reason,omitempty"`
	EvaluatedAt       time.Time `json:"evaluated_at"`
}

func (r EvaluatePluginPermissionRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !pluginKeyPattern.MatchString(strings.TrimSpace(r.PluginKey)) {
		errs = append(errs, ValidationError{
			Field:   "plugin_key",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedPluginPermissionProfiles, strings.TrimSpace(r.PermissionProfile)) {
		errs = append(errs, ValidationError{
			Field:   "permission_profile",
			Message: "desteklenmeyen deger",
		})
	}

	if !pluginPermissionOperationPattern.MatchString(strings.TrimSpace(r.Operation)) || !containsValue(allowedPluginPermissionOperations, strings.TrimSpace(r.Operation)) {
		errs = append(errs, ValidationError{
			Field:   "operation",
			Message: "desteklenmeyen veya gecersiz format",
		})
	}

	if !pluginPermissionScopePattern.MatchString(strings.TrimSpace(r.ResourceScope)) || !containsValue(allowedPluginPermissionScopes, strings.TrimSpace(r.ResourceScope)) {
		errs = append(errs, ValidationError{
			Field:   "resource_scope",
			Message: "desteklenmeyen veya gecersiz format",
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

func (r EvaluatePluginPermissionResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !pluginKeyPattern.MatchString(strings.TrimSpace(r.PluginKey)) {
		errs = append(errs, ValidationError{
			Field:   "plugin_key",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedPluginPermissionProfiles, strings.TrimSpace(r.PermissionProfile)) {
		errs = append(errs, ValidationError{
			Field:   "permission_profile",
			Message: "desteklenmeyen deger",
		})
	}

	if !pluginPermissionOperationPattern.MatchString(strings.TrimSpace(r.Operation)) || !containsValue(allowedPluginPermissionOperations, strings.TrimSpace(r.Operation)) {
		errs = append(errs, ValidationError{
			Field:   "operation",
			Message: "desteklenmeyen veya gecersiz format",
		})
	}

	if !pluginPermissionScopePattern.MatchString(strings.TrimSpace(r.ResourceScope)) || !containsValue(allowedPluginPermissionScopes, strings.TrimSpace(r.ResourceScope)) {
		errs = append(errs, ValidationError{
			Field:   "resource_scope",
			Message: "desteklenmeyen veya gecersiz format",
		})
	}

	if !r.Permitted && strings.TrimSpace(r.DenialReason) == "" {
		errs = append(errs, ValidationError{
			Field:   "denial_reason",
			Message: "izin reddinde zorunlu alan",
		})
	}

	if r.EvaluatedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "evaluated_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
