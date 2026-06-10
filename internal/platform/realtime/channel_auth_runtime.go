package realtime

import (
	"errors"
	"strings"
	"time"
)

var (
	ErrChannelAuthDenied = errors.New("channel authorization denied")
)

const (
	ChannelAuthDecisionAllow = "ALLOW"
	ChannelAuthDecisionDeny  = "DENY"

	ChannelAuthReasonAllowed             = "CHANNEL_AUTH_ALLOWED"
	ChannelAuthReasonMissingTenant       = "CHANNEL_AUTH_MISSING_TENANT"
	ChannelAuthReasonMissingChannel      = "CHANNEL_AUTH_MISSING_CHANNEL"
	ChannelAuthReasonInvalidChannelName  = "CHANNEL_AUTH_INVALID_CHANNEL_NAME"
	ChannelAuthReasonCrossTenantChannel  = "CHANNEL_AUTH_CROSS_TENANT_CHANNEL"
	ChannelAuthReasonForbiddenSystemZone = "CHANNEL_AUTH_FORBIDDEN_SYSTEM_ZONE"
	ChannelAuthReasonUserDenied          = "CHANNEL_AUTH_USER_DENIED"
)

type ChannelAuthRuntimeConfig struct {
	RequireTenant      bool     `json:"require_tenant"`
	MaxChannelLength   int      `json:"max_channel_length"`
	ForbiddenPrefixes  []string `json:"forbidden_prefixes"`
	AllowedSystemUsers []string `json:"allowed_system_users"`
}

func DefaultChannelAuthRuntimeConfig() ChannelAuthRuntimeConfig {
	return ChannelAuthRuntimeConfig{
		RequireTenant:    true,
		MaxChannelLength: 160,
		ForbiddenPrefixes: []string{
			"global:",
			"system:",
			"admin:",
			"super-admin:",
			"break-glass:",
		},
		AllowedSystemUsers: []string{
			"system",
			"ops",
		},
	}
}

type ChannelAuthRequest struct {
	TenantID      string `json:"tenant_id"`
	Channel       string `json:"channel"`
	UserID        string `json:"user_id,omitempty"`
	Transport     string `json:"transport"`
	CorrelationID string `json:"correlation_id,omitempty"`
	RemoteAddr    string `json:"remote_addr,omitempty"`
}

type ChannelAuthDecision struct {
	Decision      string `json:"decision"`
	Allowed       bool   `json:"allowed"`
	TenantID      string `json:"tenant_id"`
	Channel       string `json:"channel"`
	Transport     string `json:"transport"`
	Reason        string `json:"reason"`
	NormalizedKey string `json:"normalized_key"`
	CheckedAt     string `json:"checked_at"`
}

type ChannelAuthorizer interface {
	AuthorizeChannel(req ChannelAuthRequest) ChannelAuthDecision
}

type ChannelAuthRuntime struct {
	config ChannelAuthRuntimeConfig
}

func NewChannelAuthRuntime(config ChannelAuthRuntimeConfig) *ChannelAuthRuntime {
	if config.MaxChannelLength <= 0 {
		config.MaxChannelLength = 160
	}
	if config.ForbiddenPrefixes == nil {
		config.ForbiddenPrefixes = DefaultChannelAuthRuntimeConfig().ForbiddenPrefixes
	}
	return &ChannelAuthRuntime{config: config}
}

func (r *ChannelAuthRuntime) AuthorizeChannel(req ChannelAuthRequest) ChannelAuthDecision {
	tenantID := strings.TrimSpace(req.TenantID)
	channel := strings.TrimSpace(req.Channel)
	userID := strings.TrimSpace(req.UserID)

	decision := ChannelAuthDecision{
		Decision:  ChannelAuthDecisionDeny,
		Allowed:   false,
		TenantID:  tenantID,
		Channel:   channel,
		Transport: strings.TrimSpace(req.Transport),
		CheckedAt: time.Now().UTC().Format(time.RFC3339Nano),
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = ChannelAuthReasonMissingTenant
		return decision
	}

	if channel == "" {
		decision.Reason = ChannelAuthReasonMissingChannel
		return decision
	}

	if !isValidChannelName(channel, r.config.MaxChannelLength) {
		decision.Reason = ChannelAuthReasonInvalidChannelName
		return decision
	}

	lowerChannel := strings.ToLower(channel)
	for _, prefix := range r.config.ForbiddenPrefixes {
		if strings.HasPrefix(lowerChannel, strings.ToLower(prefix)) && !r.isSystemUserAllowed(userID) {
			decision.Reason = ChannelAuthReasonForbiddenSystemZone
			return decision
		}
	}

	if !channelBelongsToTenant(tenantID, channel) {
		decision.Reason = ChannelAuthReasonCrossTenantChannel
		return decision
	}

	decision.Decision = ChannelAuthDecisionAllow
	decision.Allowed = true
	decision.Reason = ChannelAuthReasonAllowed
	decision.NormalizedKey = NormalizeTenantChannelKey(tenantID, channel)
	return decision
}

func NormalizeTenantChannelKey(tenantID string, channel string) string {
	tenantID = strings.TrimSpace(tenantID)
	channel = strings.Trim(strings.TrimSpace(channel), "/")

	if tenantID == "" {
		return channel
	}

	if strings.HasPrefix(channel, "tenant:"+tenantID+":") ||
		strings.HasPrefix(channel, "tenant/"+tenantID+"/") ||
		strings.HasPrefix(channel, "tenant."+tenantID+".") {
		return channel
	}

	return "tenant:" + tenantID + ":" + channel
}

func channelBelongsToTenant(tenantID string, channel string) bool {
	tenantID = strings.TrimSpace(tenantID)
	channel = strings.TrimSpace(channel)

	if tenantID == "" {
		return true
	}

	tenantPrefixes := []string{
		"tenant:",
		"tenant/",
		"tenant.",
	}

	hasTenantPrefix := false
	for _, prefix := range tenantPrefixes {
		if strings.HasPrefix(channel, prefix) {
			hasTenantPrefix = true
			break
		}
	}

	if !hasTenantPrefix {
		return true
	}

	return strings.HasPrefix(channel, "tenant:"+tenantID+":") ||
		strings.HasPrefix(channel, "tenant/"+tenantID+"/") ||
		strings.HasPrefix(channel, "tenant."+tenantID+".")
}

func isValidChannelName(channel string, maxLength int) bool {
	if len(channel) == 0 || len(channel) > maxLength {
		return false
	}

	if strings.Contains(channel, " ") ||
		strings.Contains(channel, "\t") ||
		strings.Contains(channel, "\n") ||
		strings.Contains(channel, "..") ||
		strings.HasPrefix(channel, "/") ||
		strings.HasSuffix(channel, "/") {
		return false
	}

	for _, r := range channel {
		if r >= 'a' && r <= 'z' {
			continue
		}
		if r >= 'A' && r <= 'Z' {
			continue
		}
		if r >= '0' && r <= '9' {
			continue
		}
		switch r {
		case '-', '_', ':', '/', '.':
			continue
		default:
			return false
		}
	}

	return true
}

func (r *ChannelAuthRuntime) isSystemUserAllowed(userID string) bool {
	for _, allowed := range r.config.AllowedSystemUsers {
		if strings.EqualFold(strings.TrimSpace(allowed), userID) {
			return true
		}
	}
	return false
}
