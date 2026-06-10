package realtime

import (
	"strings"
	"time"
)

var allowedRealtimeChannelOperations = map[string]struct{}{
	"subscribe": {},
	"publish":   {},
}

var allowedRealtimeChannelScopes = map[string]struct{}{
	"tenant":   {},
	"platform": {},
}

var allowedRealtimeChannelAuthStatuses = map[string]struct{}{
	"granted": {},
	"denied":  {},
}

type AuthorizeRealtimeChannelRequest struct {
	TenantID     string `json:"tenant_id"`
	ConnectionID string `json:"connection_id"`
	ChannelName  string `json:"channel_name"`
	ClientID     string `json:"client_id"`
	UserRef      string `json:"user_ref"`
	Operation    string `json:"operation"`
	RequestedBy  string `json:"requested_by"`
}

type AuthorizeRealtimeChannelResponse struct {
	TenantID       string    `json:"tenant_id"`
	ConnectionID   string    `json:"connection_id"`
	ChannelName    string    `json:"channel_name"`
	ClientID       string    `json:"client_id"`
	UserRef        string    `json:"user_ref"`
	Operation      string    `json:"operation"`
	ChannelScope   string    `json:"channel_scope"`
	AuthStatus     string    `json:"auth_status"`
	AccessGranted  bool      `json:"access_granted"`
	DenialReason   string    `json:"denial_reason,omitempty"`
	AuthorizedAt   time.Time `json:"authorized_at"`
}

func (r AuthorizeRealtimeChannelRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !realtimeKeyPattern.MatchString(strings.TrimSpace(r.TenantID)) {
		errs = append(errs, ValidationError{Field: "tenant_id", Message: "gecersiz format"})
	}

	if !realtimeKeyPattern.MatchString(strings.TrimSpace(r.ConnectionID)) {
		errs = append(errs, ValidationError{Field: "connection_id", Message: "gecersiz format"})
	}

	if !realtimeChannelPattern.MatchString(strings.TrimSpace(r.ChannelName)) {
		errs = append(errs, ValidationError{Field: "channel_name", Message: "gecersiz format"})
	}

	if !realtimeKeyPattern.MatchString(strings.TrimSpace(r.ClientID)) {
		errs = append(errs, ValidationError{Field: "client_id", Message: "gecersiz format"})
	}

	if !realtimeActorRefPattern.MatchString(strings.TrimSpace(r.UserRef)) {
		errs = append(errs, ValidationError{Field: "user_ref", Message: "gecersiz format"})
	}

	if !containsValue(allowedRealtimeChannelOperations, strings.TrimSpace(r.Operation)) {
		errs = append(errs, ValidationError{Field: "operation", Message: "desteklenmeyen deger"})
	}

	if !realtimeActorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{Field: "requested_by", Message: "gecersiz format"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r AuthorizeRealtimeChannelResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !realtimeKeyPattern.MatchString(strings.TrimSpace(r.TenantID)) {
		errs = append(errs, ValidationError{Field: "tenant_id", Message: "gecersiz format"})
	}

	if !realtimeKeyPattern.MatchString(strings.TrimSpace(r.ConnectionID)) {
		errs = append(errs, ValidationError{Field: "connection_id", Message: "gecersiz format"})
	}

	if !realtimeChannelPattern.MatchString(strings.TrimSpace(r.ChannelName)) {
		errs = append(errs, ValidationError{Field: "channel_name", Message: "gecersiz format"})
	}

	if !realtimeKeyPattern.MatchString(strings.TrimSpace(r.ClientID)) {
		errs = append(errs, ValidationError{Field: "client_id", Message: "gecersiz format"})
	}

	if !realtimeActorRefPattern.MatchString(strings.TrimSpace(r.UserRef)) {
		errs = append(errs, ValidationError{Field: "user_ref", Message: "gecersiz format"})
	}

	if !containsValue(allowedRealtimeChannelOperations, strings.TrimSpace(r.Operation)) {
		errs = append(errs, ValidationError{Field: "operation", Message: "desteklenmeyen deger"})
	}

	if !containsValue(allowedRealtimeChannelScopes, strings.TrimSpace(r.ChannelScope)) {
		errs = append(errs, ValidationError{Field: "channel_scope", Message: "desteklenmeyen deger"})
	}

	if !containsValue(allowedRealtimeChannelAuthStatuses, strings.TrimSpace(r.AuthStatus)) {
		errs = append(errs, ValidationError{Field: "auth_status", Message: "desteklenmeyen deger"})
	}

	if r.AccessGranted && strings.TrimSpace(r.AuthStatus) != "granted" {
		errs = append(errs, ValidationError{Field: "auth_status", Message: "access_granted true ise granted olmali"})
	}

	if !r.AccessGranted && strings.TrimSpace(r.DenialReason) == "" {
		errs = append(errs, ValidationError{Field: "denial_reason", Message: "denied durumda zorunlu alan"})
	}

	if r.AuthorizedAt.IsZero() {
		errs = append(errs, ValidationError{Field: "authorized_at", Message: "zorunlu alan"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
