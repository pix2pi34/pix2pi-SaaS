package realtime

import (
	"strings"
	"time"
)

var allowedSSEProtocols = map[string]struct{}{
	"sse": {},
}

var allowedSSEConnectionStatuses = map[string]struct{}{
	"streaming": {},
	"rejected":  {},
}

type OpenSSEConnectionRequest struct {
	TenantID      string `json:"tenant_id,omitempty"`
	ConnectionID  string `json:"connection_id"`
	ChannelName   string `json:"channel_name"`
	ClientID      string `json:"client_id"`
	UserRef       string `json:"user_ref"`
	Protocol      string `json:"protocol"`
	LastEventID   string `json:"last_event_id,omitempty"`
	RemoteAddr    string `json:"remote_addr"`
	Origin        string `json:"origin,omitempty"`
	RequestedBy   string `json:"requested_by"`
}

type OpenSSEConnectionResponse struct {
	ConnectionID    string    `json:"connection_id"`
	ChannelName     string    `json:"channel_name"`
	ClientID        string    `json:"client_id"`
	UserRef         string    `json:"user_ref"`
	Protocol        string    `json:"protocol"`
	LastEventID     string    `json:"last_event_id,omitempty"`
	ServerNode      string    `json:"server_node"`
	Status          string    `json:"status"`
	Accepted        bool      `json:"accepted"`
	RejectionReason string    `json:"rejection_reason,omitempty"`
	StreamOpenedAt  time.Time `json:"stream_opened_at"`
}

func (r OpenSSEConnectionRequest) Validate() error {
	errs := make(ValidationErrors, 0)

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

	if !containsValue(allowedSSEProtocols, strings.TrimSpace(r.Protocol)) {
		errs = append(errs, ValidationError{Field: "protocol", Message: "desteklenmeyen deger"})
	}

	if strings.TrimSpace(r.LastEventID) != "" && !realtimeKeyPattern.MatchString(strings.TrimSpace(r.LastEventID)) {
		errs = append(errs, ValidationError{Field: "last_event_id", Message: "gecersiz format"})
	}

	if !realtimeActorRefPattern.MatchString(strings.TrimSpace(r.RemoteAddr)) {
		errs = append(errs, ValidationError{Field: "remote_addr", Message: "gecersiz format"})
	}

	origin := strings.TrimSpace(r.Origin)
	if origin != "" && !(strings.HasPrefix(origin, "https://") || strings.HasPrefix(origin, "http://")) {
		errs = append(errs, ValidationError{Field: "origin", Message: "http veya https URL olmali"})
	}

	if !realtimeActorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{Field: "requested_by", Message: "gecersiz format"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r OpenSSEConnectionResponse) Validate() error {
	errs := make(ValidationErrors, 0)

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

	if !containsValue(allowedSSEProtocols, strings.TrimSpace(r.Protocol)) {
		errs = append(errs, ValidationError{Field: "protocol", Message: "desteklenmeyen deger"})
	}

	if strings.TrimSpace(r.LastEventID) != "" && !realtimeKeyPattern.MatchString(strings.TrimSpace(r.LastEventID)) {
		errs = append(errs, ValidationError{Field: "last_event_id", Message: "gecersiz format"})
	}

	if strings.TrimSpace(r.ServerNode) == "" {
		errs = append(errs, ValidationError{Field: "server_node", Message: "zorunlu alan"})
	}

	if !containsValue(allowedSSEConnectionStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{Field: "status", Message: "desteklenmeyen deger"})
	}

	if r.Accepted && strings.TrimSpace(r.Status) != "streaming" {
		errs = append(errs, ValidationError{Field: "status", Message: "accepted true ise streaming olmali"})
	}

	if !r.Accepted && strings.TrimSpace(r.RejectionReason) == "" {
		errs = append(errs, ValidationError{Field: "rejection_reason", Message: "rejected durumda zorunlu alan"})
	}

	if r.StreamOpenedAt.IsZero() {
		errs = append(errs, ValidationError{Field: "stream_opened_at", Message: "zorunlu alan"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
