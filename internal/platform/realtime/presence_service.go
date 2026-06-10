package realtime

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ApplyRealtimePresenceCommand struct {
	TenantID     string
	ConnectionID string
	ChannelName  string
	ClientID     string
	UserRef      string
	ActionType   string
	ServerNode   string
	RequestedBy  string
}

type ApplyRealtimePresenceResult struct {
	TenantID         string
	ConnectionID     string
	ChannelName      string
	ClientID         string
	UserRef          string
	ActionType       string
	PresenceStatus   string
	ConnectionClosed bool
	ServerNode       string
	LastSeenAt       time.Time
	ClosedAt         *time.Time
	Applied          bool
}

type RealtimePresenceStore interface {
	ApplyPresence(ctx context.Context, cmd ApplyRealtimePresenceCommand) (ApplyRealtimePresenceResult, error)
}

type ApplyRealtimePresenceUsecase struct {
	store RealtimePresenceStore
	nowFn func() time.Time
}

func NewApplyRealtimePresenceUsecase(store RealtimePresenceStore) *ApplyRealtimePresenceUsecase {
	return &ApplyRealtimePresenceUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *ApplyRealtimePresenceUsecase) Apply(ctx context.Context, req ApplyRealtimePresenceRequest) (ApplyRealtimePresenceResponse, error) {
	if u == nil || u.store == nil {
		return ApplyRealtimePresenceResponse{}, errors.New("realtime presence usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.ConnectionID = strings.TrimSpace(req.ConnectionID)
	req.ChannelName = strings.TrimSpace(req.ChannelName)
	req.ClientID = strings.TrimSpace(req.ClientID)
	req.UserRef = strings.TrimSpace(req.UserRef)
	req.ActionType = strings.TrimSpace(req.ActionType)
	req.ServerNode = strings.TrimSpace(req.ServerNode)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return ApplyRealtimePresenceResponse{}, err
	}

	result, err := u.store.ApplyPresence(ctx, ApplyRealtimePresenceCommand{
		TenantID:     req.TenantID,
		ConnectionID: req.ConnectionID,
		ChannelName:  req.ChannelName,
		ClientID:     req.ClientID,
		UserRef:      req.UserRef,
		ActionType:   req.ActionType,
		ServerNode:   req.ServerNode,
		RequestedBy:  req.RequestedBy,
	})
	if err != nil {
		return ApplyRealtimePresenceResponse{}, err
	}

	now := u.nowFn().UTC()

	presenceStatus, connectionClosed := resolveFallbackRealtimePresence(req.ActionType)

	if strings.TrimSpace(result.PresenceStatus) != "" {
		presenceStatus = strings.TrimSpace(result.PresenceStatus)
	}

	if result.ConnectionClosed {
		connectionClosed = true
	}

	lastSeenAt := result.LastSeenAt
	if lastSeenAt.IsZero() {
		lastSeenAt = now
	} else {
		lastSeenAt = lastSeenAt.UTC()
	}

	closedAt := cloneRealtimeTimePtr(result.ClosedAt)
	if connectionClosed && closedAt == nil {
		closedAt = &now
	}

	applied := result.Applied
	if !applied {
		applied = true
	}

	resp := ApplyRealtimePresenceResponse{
		TenantID:         firstNonEmpty(strings.TrimSpace(result.TenantID), req.TenantID),
		ConnectionID:     firstNonEmpty(strings.TrimSpace(result.ConnectionID), req.ConnectionID),
		ChannelName:      firstNonEmpty(strings.TrimSpace(result.ChannelName), req.ChannelName),
		ClientID:         firstNonEmpty(strings.TrimSpace(result.ClientID), req.ClientID),
		UserRef:          firstNonEmpty(strings.TrimSpace(result.UserRef), req.UserRef),
		ActionType:       firstNonEmpty(strings.TrimSpace(result.ActionType), req.ActionType),
		PresenceStatus:   presenceStatus,
		ConnectionClosed: connectionClosed,
		ServerNode:       firstNonEmpty(strings.TrimSpace(result.ServerNode), req.ServerNode),
		LastSeenAt:       lastSeenAt,
		ClosedAt:         closedAt,
		Applied:          applied,
		AppliedAt:        now,
	}

	if err := resp.Validate(); err != nil {
		return ApplyRealtimePresenceResponse{}, err
	}

	return resp, nil
}

func resolveFallbackRealtimePresence(actionType string) (string, bool) {
	switch strings.TrimSpace(actionType) {
	case "heartbeat":
		return "online", false
	case "disconnect":
		return "offline", true
	case "expire":
		return "expired", true
	default:
		return "", false
	}
}

func cloneRealtimeTimePtr(in *time.Time) *time.Time {
	if in == nil {
		return nil
	}

	t := in.UTC()
	return &t
}
