package realtime

import (
	"regexp"
	"strings"
	"time"
)

var (
	realtimeKeyPattern      = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
	realtimeChannelPattern  = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
	realtimeActorRefPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
)

var allowedRealtimeProtocols = map[string]struct{}{
	"websocket": {},
}

var allowedWebSocketConnectionStatuses = map[string]struct{}{
	"connected": {},
	"rejected":  {},
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

type OpenWebSocketConnectionRequest struct {
	TenantID     string `json:"tenant_id,omitempty"`
	ConnectionID string `json:"connection_id"`
	ChannelName  string `json:"channel_name"`
	ClientID     string `json:"client_id"`
	UserRef      string `json:"user_ref"`
	Protocol     string `json:"protocol"`
	RemoteAddr   string `json:"remote_addr"`
	Origin       string `json:"origin,omitempty"`
	RequestedBy  string `json:"requested_by"`
}

type OpenWebSocketConnectionResponse struct {
	ConnectionID    string    `json:"connection_id"`
	ChannelName     string    `json:"channel_name"`
	ClientID        string    `json:"client_id"`
	UserRef         string    `json:"user_ref"`
	Protocol        string    `json:"protocol"`
	ServerNode      string    `json:"server_node"`
	Status          string    `json:"status"`
	Accepted        bool      `json:"accepted"`
	RejectionReason string    `json:"rejection_reason,omitempty"`
	ConnectedAt     time.Time `json:"connected_at"`
}

func (r OpenWebSocketConnectionRequest) Validate() error {
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

	if !containsValue(allowedRealtimeProtocols, strings.TrimSpace(r.Protocol)) {
		errs = append(errs, ValidationError{Field: "protocol", Message: "desteklenmeyen deger"})
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

func (r OpenWebSocketConnectionResponse) Validate() error {
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

	if !containsValue(allowedRealtimeProtocols, strings.TrimSpace(r.Protocol)) {
		errs = append(errs, ValidationError{Field: "protocol", Message: "desteklenmeyen deger"})
	}

	if strings.TrimSpace(r.ServerNode) == "" {
		errs = append(errs, ValidationError{Field: "server_node", Message: "zorunlu alan"})
	}

	if !containsValue(allowedWebSocketConnectionStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{Field: "status", Message: "desteklenmeyen deger"})
	}

	if r.Accepted && strings.TrimSpace(r.Status) != "connected" {
		errs = append(errs, ValidationError{Field: "status", Message: "accepted true ise connected olmali"})
	}

	if !r.Accepted && strings.TrimSpace(r.RejectionReason) == "" {
		errs = append(errs, ValidationError{Field: "rejection_reason", Message: "rejected durumda zorunlu alan"})
	}

	if r.ConnectedAt.IsZero() {
		errs = append(errs, ValidationError{Field: "connected_at", Message: "zorunlu alan"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
