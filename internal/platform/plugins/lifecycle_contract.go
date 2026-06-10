package plugins

import (
	"strings"
	"time"
)

var allowedPluginLifecycleActions = map[string]struct{}{
	"activate":   {},
	"deactivate": {},
	"suspend":    {},
	"resume":     {},
}

var allowedPluginLifecycleStatuses = map[string]struct{}{
	"active":    {},
	"inactive":  {},
	"suspended": {},
}

type ApplyPluginLifecycleRequest struct {
	TenantID    string `json:"tenant_id,omitempty"`
	PluginKey   string `json:"plugin_key"`
	ActionType  string `json:"action_type"`
	RequestedBy string `json:"requested_by"`
	Reason      string `json:"reason,omitempty"`
}

type ApplyPluginLifecycleResponse struct {
	PluginKey       string    `json:"plugin_key"`
	ActionType      string    `json:"action_type"`
	LifecycleStatus string    `json:"lifecycle_status"`
	RuntimeEnabled  bool      `json:"runtime_enabled"`
	Applied         bool      `json:"applied"`
	Reason          string    `json:"reason,omitempty"`
	RequestedBy     string    `json:"requested_by"`
	AppliedAt       time.Time `json:"applied_at"`
}

func (r ApplyPluginLifecycleRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !pluginKeyPattern.MatchString(strings.TrimSpace(r.PluginKey)) {
		errs = append(errs, ValidationError{
			Field:   "plugin_key",
			Message: "gecersiz format",
		})
	}

	if !pluginKeyPattern.MatchString(strings.TrimSpace(r.ActionType)) || !containsValue(allowedPluginLifecycleActions, strings.TrimSpace(r.ActionType)) {
		errs = append(errs, ValidationError{
			Field:   "action_type",
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

func (r ApplyPluginLifecycleResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !pluginKeyPattern.MatchString(strings.TrimSpace(r.PluginKey)) {
		errs = append(errs, ValidationError{
			Field:   "plugin_key",
			Message: "gecersiz format",
		})
	}

	if !pluginKeyPattern.MatchString(strings.TrimSpace(r.ActionType)) || !containsValue(allowedPluginLifecycleActions, strings.TrimSpace(r.ActionType)) {
		errs = append(errs, ValidationError{
			Field:   "action_type",
			Message: "desteklenmeyen deger",
		})
	}

	if r.Applied {
		if !containsValue(allowedPluginLifecycleStatuses, strings.TrimSpace(r.LifecycleStatus)) {
			errs = append(errs, ValidationError{
				Field:   "lifecycle_status",
				Message: "desteklenmeyen deger",
			})
		}
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{
			Field:   "requested_by",
			Message: "gecersiz format",
		})
	}

	if r.AppliedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "applied_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
