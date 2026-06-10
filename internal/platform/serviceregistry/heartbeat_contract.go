package serviceregistry

import (
	"fmt"
	"strings"
	"time"
)

var allowedHeartbeatModes = map[string]struct{}{
	"push": {},
	"pull": {},
}

type HeartbeatRequest struct {
	TenantID                 string         `json:"tenant_id,omitempty"`
	ServiceKey               string         `json:"service_key"`
	InstanceKey              string         `json:"instance_key"`
	Status                   string         `json:"status"`
	Mode                     string         `json:"mode"`
	ResponseTimeMS           int            `json:"response_time_ms"`
	HeartbeatIntervalSeconds int            `json:"heartbeat_interval_seconds"`
	Metadata                 map[string]any `json:"metadata,omitempty"`
}

type HeartbeatResponse struct {
	ServiceKey             string    `json:"service_key"`
	InstanceKey            string    `json:"instance_key"`
	Status                 string    `json:"status"`
	HeartbeatAcceptedAt    time.Time `json:"heartbeat_accepted_at"`
	NextHeartbeatInSeconds int       `json:"next_heartbeat_in_seconds"`
	HealthPullRequested    bool      `json:"health_pull_requested"`
}

func (r HeartbeatRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !serviceKeyPattern.MatchString(r.ServiceKey) {
		errs = append(errs, ValidationError{
			Field:   "service_key",
			Message: "gecersiz format",
		})
	}

	if !instanceKeyPattern.MatchString(r.InstanceKey) {
		errs = append(errs, ValidationError{
			Field:   "instance_key",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedInstanceStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if !containsValue(allowedHeartbeatModes, strings.TrimSpace(r.Mode)) {
		errs = append(errs, ValidationError{
			Field:   "mode",
			Message: "desteklenmeyen deger",
		})
	}

	if r.ResponseTimeMS < 0 || r.ResponseTimeMS > 300000 {
		errs = append(errs, ValidationError{
			Field:   "response_time_ms",
			Message: "0-300000 araliginda olmali",
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

func (r HeartbeatResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !serviceKeyPattern.MatchString(r.ServiceKey) {
		errs = append(errs, ValidationError{
			Field:   "service_key",
			Message: "gecersiz format",
		})
	}

	if !instanceKeyPattern.MatchString(r.InstanceKey) {
		errs = append(errs, ValidationError{
			Field:   "instance_key",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedInstanceStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.HeartbeatAcceptedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "heartbeat_accepted_at",
			Message: "zorunlu alan",
		})
	}

	if r.NextHeartbeatInSeconds < 5 || r.NextHeartbeatInSeconds > 3600 {
		errs = append(errs, ValidationError{
			Field:   "next_heartbeat_in_seconds",
			Message: "5-3600 araliginda olmali",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r HeartbeatRequest) String() string {
	return fmt.Sprintf(
		"service_key=%s instance_key=%s status=%s mode=%s",
		r.ServiceKey,
		r.InstanceKey,
		r.Status,
		r.Mode,
	)
}
