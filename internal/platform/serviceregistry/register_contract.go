package serviceregistry

import (
	"fmt"
	"regexp"
	"strings"
	"time"
)

var (
	serviceKeyPattern  = regexp.MustCompile(`^[a-z0-9][a-z0-9._-]*$`)
	instanceKeyPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
)

var (
	allowedServiceKinds = map[string]struct{}{
		"api":      {},
		"worker":   {},
		"gateway":  {},
		"cron":     {},
		"realtime": {},
		"plugin":   {},
		"external": {},
	}

	allowedVisibilityScopes = map[string]struct{}{
		"global":   {},
		"tenant":   {},
		"internal": {},
	}

	allowedProtocols = map[string]struct{}{
		"http":     {},
		"https":    {},
		"grpc":     {},
		"ws":       {},
		"sse":      {},
		"nats":     {},
		"tcp":      {},
		"internal": {},
	}

	allowedInstanceStatuses = map[string]struct{}{
		"starting":  {},
		"healthy":   {},
		"degraded":  {},
		"unhealthy": {},
		"draining":  {},
		"stopped":   {},
	}
)

type RegisterServiceRequest struct {
	TenantID                 string         `json:"tenant_id,omitempty"`
	ServiceKey               string         `json:"service_key"`
	DisplayName              string         `json:"display_name"`
	ServiceKind              string         `json:"service_kind"`
	VisibilityScope          string         `json:"visibility_scope"`
	Protocol                 string         `json:"protocol"`
	BasePath                 string         `json:"base_path"`
	HealthPath               string         `json:"health_path"`
	DefaultPort              int            `json:"default_port"`
	OwnerTeam                string         `json:"owner_team,omitempty"`
	Metadata                 map[string]any `json:"metadata,omitempty"`
	InstanceKey              string         `json:"instance_key"`
	NodeName                 string         `json:"node_name"`
	Host                     string         `json:"host"`
	Port                     int            `json:"port"`
	Version                  string         `json:"version,omitempty"`
	Status                   string         `json:"status"`
	HeartbeatIntervalSeconds int            `json:"heartbeat_interval_seconds"`
	InstanceMetadata         map[string]any `json:"instance_metadata,omitempty"`
}

type RegisterServiceResponse struct {
	ServiceID    string    `json:"service_id"`
	InstanceID   string    `json:"instance_id"`
	ServiceKey   string    `json:"service_key"`
	InstanceKey  string    `json:"instance_key"`
	RegisteredAt time.Time `json:"registered_at"`
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
		parts = append(parts, fmt.Sprintf("%s: %s", item.Field, item.Message))
	}

	return strings.Join(parts, ", ")
}

func (r RegisterServiceRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !serviceKeyPattern.MatchString(r.ServiceKey) {
		errs = append(errs, ValidationError{
			Field:   "service_key",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.DisplayName) == "" {
		errs = append(errs, ValidationError{
			Field:   "display_name",
			Message: "zorunlu alan",
		})
	}

	if !containsValue(allowedServiceKinds, r.ServiceKind) {
		errs = append(errs, ValidationError{
			Field:   "service_kind",
			Message: "desteklenmeyen deger",
		})
	}

	if !containsValue(allowedVisibilityScopes, r.VisibilityScope) {
		errs = append(errs, ValidationError{
			Field:   "visibility_scope",
			Message: "desteklenmeyen deger",
		})
	}

	if !containsValue(allowedProtocols, r.Protocol) {
		errs = append(errs, ValidationError{
			Field:   "protocol",
			Message: "desteklenmeyen deger",
		})
	}

	if !strings.HasPrefix(r.BasePath, "/") {
		errs = append(errs, ValidationError{
			Field:   "base_path",
			Message: "slash ile baslamali",
		})
	}

	if !strings.HasPrefix(r.HealthPath, "/") {
		errs = append(errs, ValidationError{
			Field:   "health_path",
			Message: "slash ile baslamali",
		})
	}

	if r.DefaultPort < 1 || r.DefaultPort > 65535 {
		errs = append(errs, ValidationError{
			Field:   "default_port",
			Message: "1-65535 araliginda olmali",
		})
	}

	if !instanceKeyPattern.MatchString(r.InstanceKey) {
		errs = append(errs, ValidationError{
			Field:   "instance_key",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.NodeName) == "" {
		errs = append(errs, ValidationError{
			Field:   "node_name",
			Message: "zorunlu alan",
		})
	}

	if strings.TrimSpace(r.Host) == "" {
		errs = append(errs, ValidationError{
			Field:   "host",
			Message: "zorunlu alan",
		})
	}

	if r.Port < 1 || r.Port > 65535 {
		errs = append(errs, ValidationError{
			Field:   "port",
			Message: "1-65535 araliginda olmali",
		})
	}

	if !containsValue(allowedInstanceStatuses, r.Status) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.HeartbeatIntervalSeconds < 5 || r.HeartbeatIntervalSeconds > 3600 {
		errs = append(errs, ValidationError{
			Field:   "heartbeat_interval_seconds",
			Message: "5-3600 araliginda olmali",
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
