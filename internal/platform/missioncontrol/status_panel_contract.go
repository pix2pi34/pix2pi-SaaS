package missioncontrol

import (
	"regexp"
	"strings"
	"time"
)

var (
	serviceKeyPattern = regexp.MustCompile(`^[a-z0-9][a-z0-9._-]*$`)
)

var allowedRuntimeStatuses = map[string]struct{}{
	"starting":  {},
	"healthy":   {},
	"degraded":  {},
	"unhealthy": {},
	"draining":  {},
	"stopped":   {},
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

type StatusPanelRequest struct {
	TenantID       string `json:"tenant_id,omitempty"`
	IncludeGlobal  bool   `json:"include_global"`
	ServiceKeyLike string `json:"service_key_like,omitempty"`
	StatusFilter   string `json:"status_filter,omitempty"`
	Limit          int    `json:"limit"`
}

type ServiceStatusCard struct {
	ServiceID       string    `json:"service_id"`
	InstanceID      string    `json:"instance_id"`
	TenantID        string    `json:"tenant_id,omitempty"`
	ServiceKey      string    `json:"service_key"`
	DisplayName     string    `json:"display_name"`
	ServiceKind     string    `json:"service_kind"`
	VisibilityScope string    `json:"visibility_scope"`
	InstanceKey     string    `json:"instance_key"`
	RuntimeStatus   string    `json:"runtime_status"`
	Host            string    `json:"host"`
	Port            int       `json:"port"`
	Version         string    `json:"version,omitempty"`
	LastHeartbeatAt time.Time `json:"last_heartbeat_at"`
}

type StatusPanelSummary struct {
	Total      int `json:"total"`
	Healthy    int `json:"healthy"`
	Degraded   int `json:"degraded"`
	Unhealthy  int `json:"unhealthy"`
	Starting   int `json:"starting"`
	Draining   int `json:"draining"`
	Stopped    int `json:"stopped"`
}

type StatusPanelResponse struct {
	GeneratedAt time.Time          `json:"generated_at"`
	Summary     StatusPanelSummary `json:"summary"`
	Items       []ServiceStatusCard `json:"items"`
}

func (r StatusPanelRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if r.Limit < 1 || r.Limit > 500 {
		errs = append(errs, ValidationError{
			Field:   "limit",
			Message: "1-500 araliginda olmali",
		})
	}

	if strings.TrimSpace(r.StatusFilter) != "" && !containsValue(allowedRuntimeStatuses, strings.TrimSpace(r.StatusFilter)) {
		errs = append(errs, ValidationError{
			Field:   "status_filter",
			Message: "desteklenmeyen deger",
		})
	}

	if keyLike := strings.TrimSpace(r.ServiceKeyLike); keyLike != "" && !serviceKeyPattern.MatchString(keyLike) {
		errs = append(errs, ValidationError{
			Field:   "service_key_like",
			Message: "gecersiz format",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r StatusPanelResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if r.GeneratedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "generated_at",
			Message: "zorunlu alan",
		})
	}

	if r.Summary.Total < 0 {
		errs = append(errs, ValidationError{
			Field:   "summary.total",
			Message: "negatif olamaz",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func containsValue(values map[string]struct{}, value string) bool {
	_, ok := values[value]
	return ok
}
