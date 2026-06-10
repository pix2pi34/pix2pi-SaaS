package realtime

import (
	"context"
	"errors"
	"strings"
	"time"
)

type AuthorizeRealtimeChannelCommand struct {
	TenantID     string
	ConnectionID string
	ChannelName  string
	ClientID     string
	UserRef      string
	Operation    string
	RequestedBy  string
}

type AuthorizeRealtimeChannelResult struct {
	TenantID      string
	ConnectionID  string
	ChannelName   string
	ClientID      string
	UserRef       string
	Operation     string
	ChannelScope  string
	AuthStatus    string
	AccessGranted bool
	DenialReason  string
}

type RealtimeChannelAuthStore interface {
	AuthorizeChannel(ctx context.Context, cmd AuthorizeRealtimeChannelCommand) (AuthorizeRealtimeChannelResult, error)
}

type AuthorizeRealtimeChannelUsecase struct {
	store RealtimeChannelAuthStore
	nowFn func() time.Time
}

func NewAuthorizeRealtimeChannelUsecase(store RealtimeChannelAuthStore) *AuthorizeRealtimeChannelUsecase {
	return &AuthorizeRealtimeChannelUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *AuthorizeRealtimeChannelUsecase) Authorize(ctx context.Context, req AuthorizeRealtimeChannelRequest) (AuthorizeRealtimeChannelResponse, error) {
	if u == nil || u.store == nil {
		return AuthorizeRealtimeChannelResponse{}, errors.New("realtime channel auth usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.ConnectionID = strings.TrimSpace(req.ConnectionID)
	req.ChannelName = strings.TrimSpace(req.ChannelName)
	req.ClientID = strings.TrimSpace(req.ClientID)
	req.UserRef = strings.TrimSpace(req.UserRef)
	req.Operation = strings.TrimSpace(req.Operation)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return AuthorizeRealtimeChannelResponse{}, err
	}

	result, err := u.store.AuthorizeChannel(ctx, AuthorizeRealtimeChannelCommand{
		TenantID:     req.TenantID,
		ConnectionID: req.ConnectionID,
		ChannelName:  req.ChannelName,
		ClientID:     req.ClientID,
		UserRef:      req.UserRef,
		Operation:    req.Operation,
		RequestedBy:  req.RequestedBy,
	})
	if err != nil {
		return AuthorizeRealtimeChannelResponse{}, err
	}

	scope, status, accessGranted, denialReason := resolveFallbackRealtimeChannelAuth(req.TenantID, req.ChannelName, req.Operation)

	if strings.TrimSpace(result.ChannelScope) != "" {
		scope = strings.TrimSpace(result.ChannelScope)
	}

	if strings.TrimSpace(result.AuthStatus) != "" {
		status = strings.TrimSpace(result.AuthStatus)
	}

	if result.AccessGranted {
		accessGranted = true
		status = "granted"
		denialReason = ""
	}

	if strings.TrimSpace(result.DenialReason) != "" {
		accessGranted = false
		status = "denied"
		denialReason = strings.TrimSpace(result.DenialReason)
	}

	resp := AuthorizeRealtimeChannelResponse{
		TenantID:      firstNonEmpty(strings.TrimSpace(result.TenantID), req.TenantID),
		ConnectionID:  firstNonEmpty(strings.TrimSpace(result.ConnectionID), req.ConnectionID),
		ChannelName:   firstNonEmpty(strings.TrimSpace(result.ChannelName), req.ChannelName),
		ClientID:      firstNonEmpty(strings.TrimSpace(result.ClientID), req.ClientID),
		UserRef:       firstNonEmpty(strings.TrimSpace(result.UserRef), req.UserRef),
		Operation:     firstNonEmpty(strings.TrimSpace(result.Operation), req.Operation),
		ChannelScope:  scope,
		AuthStatus:    status,
		AccessGranted: accessGranted,
		DenialReason:  denialReason,
		AuthorizedAt:  u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return AuthorizeRealtimeChannelResponse{}, err
	}

	return resp, nil
}

func resolveFallbackRealtimeChannelAuth(tenantID, channelName, operation string) (string, string, bool, string) {
	tenantID = strings.TrimSpace(tenantID)
	channelName = strings.TrimSpace(channelName)
	operation = strings.TrimSpace(operation)

	if tenantID == "" {
		return "tenant", "denied", false, "tenant_id zorunlu"
	}

	if strings.HasPrefix(channelName, "tenant.") {
		if operation == "subscribe" || operation == "publish" {
			return "tenant", "granted", true, ""
		}
	}

	if strings.HasPrefix(channelName, "platform.") {
		return "platform", "denied", false, "platform kanali tenant runtime icin kapali"
	}

	return "tenant", "denied", false, "kanal tenant guvenlik kuralina uymuyor"
}
