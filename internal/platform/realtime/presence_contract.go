package realtime

import (
	"strings"
	"time"
)

var allowedRealtimeLifecycleActions = map[string]struct{}{
	"heartbeat":  {},
	"disconnect": {},
	"expire":     {},
}

var allowedRealtimePresenceStatuses = map[string]struct{}{
	"online":  {},
	"offline": {},
	"expired": {},
}

type ApplyRealtimePresenceRequest struct {
	TenantID     string `json:"tenant_id"`
	ConnectionID string `json:"connection_id"`
	ChannelName  string `json:"channel_name"`
	ClientID     string `json:"client_id"`
	UserRef      string `json:"user_ref"`
	ActionType   string `json:"action_type"`
	ServerNode   string `json:"server_node"`
	RequestedBy  string `json:"requested_by"`
}

type ApplyRealtimePresenceResponse struct {
	TenantID         string     `json:"tenant_id"`
	ConnectionID     string     `json:"connection_id"`
	ChannelName      string     `json:"channel_name"`
	ClientID         string     `json:"client_id"`
	UserRef          string     `json:"user_ref"`
	ActionType       string     `json:"action_type"`
	PresenceStatus   string     `json:"presence_status"`
	ConnectionClosed bool       `json:"connection_closed"`
	ServerNode       string     `json:"server_node"`
	LastSeenAt       time.Time  `json:"last_seen_at"`
	ClosedAt         *time.Time `json:"closed_at,omitempty"`
	Applied          bool       `json:"applied"`
	AppliedAt        time.Time  `json:"applied_at"`
}

func (r ApplyRealtimePresenceRequest) Validate() error {
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

	if !containsValue(allowedRealtimeLifecycleActions, strings.TrimSpace(r.ActionType)) {
		errs = append(errs, ValidationError{Field: "action_type", Message: "desteklenmeyen deger"})
	}

	if !realtimeKeyPattern.MatchString(strings.TrimSpace(r.ServerNode)) {
		errs = append(errs, ValidationError{Field: "server_node", Message: "gecersiz format"})
	}

	if !realtimeActorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{Field: "requested_by", Message: "gecersiz format"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r ApplyRealtimePresenceResponse) Validate() error {
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

	if !containsValue(allowedRealtimeLifecycleActions, strings.TrimSpace(r.ActionType)) {
		errs = append(errs, ValidationError{Field: "action_type", Message: "desteklenmeyen deger"})
	}

	if !containsValue(allowedRealtimePresenceStatuses, strings.TrimSpace(r.PresenceStatus)) {
		errs = append(errs, ValidationError{Field: "presence_status", Message: "desteklenmeyen deger"})
	}

	if !realtimeKeyPattern.MatchString(strings.TrimSpace(r.ServerNode)) {
		errs = append(errs, ValidationError{Field: "server_node", Message: "gecersiz format"})
	}

	if r.LastSeenAt.IsZero() {
		errs = append(errs, ValidationError{Field: "last_seen_at", Message: "zorunlu alan"})
	}

	if r.ConnectionClosed && r.ClosedAt == nil {
		errs = append(errs, ValidationError{Field: "closed_at", Message: "connection_closed true ise zorunlu alan"})
	}

	if !r.ConnectionClosed && r.ClosedAt != nil {
		errs = append(errs, ValidationError{Field: "closed_at", Message: "connection acikken bos olmali"})
	}

	if strings.TrimSpace(r.ActionType) == "heartbeat" && strings.TrimSpace(r.PresenceStatus) != "online" {
		errs = append(errs, ValidationError{Field: "presence_status", Message: "heartbeat icin online olmali"})
	}

	if strings.TrimSpace(r.ActionType) == "disconnect" && strings.TrimSpace(r.PresenceStatus) != "offline" {
		errs = append(errs, ValidationError{Field: "presence_status", Message: "disconnect icin offline olmali"})
	}

	if strings.TrimSpace(r.ActionType) == "expire" && strings.TrimSpace(r.PresenceStatus) != "expired" {
		errs = append(errs, ValidationError{Field: "presence_status", Message: "expire icin expired olmali"})
	}

	if !r.Applied {
		errs = append(errs, ValidationError{Field: "applied", Message: "true olmali"})
	}

	if r.AppliedAt.IsZero() {
		errs = append(errs, ValidationError{Field: "applied_at", Message: "zorunlu alan"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
