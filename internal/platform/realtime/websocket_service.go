package realtime

import (
	"context"
	"errors"
	"strings"
	"time"
)

type OpenWebSocketConnectionCommand struct {
	TenantID     string
	ConnectionID string
	ChannelName  string
	ClientID     string
	UserRef      string
	Protocol     string
	RemoteAddr   string
	Origin       string
	RequestedBy  string
}

type OpenWebSocketConnectionResult struct {
	ConnectionID    string
	ChannelName     string
	ClientID        string
	UserRef         string
	Protocol        string
	ServerNode      string
	Status          string
	Accepted        bool
	RejectionReason string
}

type WebSocketConnectionStore interface {
	OpenConnection(ctx context.Context, cmd OpenWebSocketConnectionCommand) (OpenWebSocketConnectionResult, error)
}

type OpenWebSocketConnectionUsecase struct {
	store WebSocketConnectionStore
	nowFn func() time.Time
}

func NewOpenWebSocketConnectionUsecase(store WebSocketConnectionStore) *OpenWebSocketConnectionUsecase {
	return &OpenWebSocketConnectionUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *OpenWebSocketConnectionUsecase) Open(ctx context.Context, req OpenWebSocketConnectionRequest) (OpenWebSocketConnectionResponse, error) {
	if u == nil || u.store == nil {
		return OpenWebSocketConnectionResponse{}, errors.New("websocket connection usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.ConnectionID = strings.TrimSpace(req.ConnectionID)
	req.ChannelName = strings.TrimSpace(req.ChannelName)
	req.ClientID = strings.TrimSpace(req.ClientID)
	req.UserRef = strings.TrimSpace(req.UserRef)
	req.Protocol = strings.TrimSpace(req.Protocol)
	req.RemoteAddr = strings.TrimSpace(req.RemoteAddr)
	req.Origin = strings.TrimSpace(req.Origin)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return OpenWebSocketConnectionResponse{}, err
	}

	result, err := u.store.OpenConnection(ctx, OpenWebSocketConnectionCommand{
		TenantID:     req.TenantID,
		ConnectionID: req.ConnectionID,
		ChannelName:  req.ChannelName,
		ClientID:     req.ClientID,
		UserRef:      req.UserRef,
		Protocol:     req.Protocol,
		RemoteAddr:   req.RemoteAddr,
		Origin:       req.Origin,
		RequestedBy:  req.RequestedBy,
	})
	if err != nil {
		return OpenWebSocketConnectionResponse{}, err
	}

	status := firstNonEmpty(strings.TrimSpace(result.Status), "connected")
	accepted := result.Accepted
	rejectionReason := strings.TrimSpace(result.RejectionReason)

	if status == "connected" {
		accepted = true
		rejectionReason = ""
	}

	if status == "rejected" {
		accepted = false
		if rejectionReason == "" {
			rejectionReason = "connection rejected"
		}
	}

	resp := OpenWebSocketConnectionResponse{
		ConnectionID:    firstNonEmpty(strings.TrimSpace(result.ConnectionID), req.ConnectionID),
		ChannelName:     firstNonEmpty(strings.TrimSpace(result.ChannelName), req.ChannelName),
		ClientID:        firstNonEmpty(strings.TrimSpace(result.ClientID), req.ClientID),
		UserRef:         firstNonEmpty(strings.TrimSpace(result.UserRef), req.UserRef),
		Protocol:        firstNonEmpty(strings.TrimSpace(result.Protocol), req.Protocol),
		ServerNode:      firstNonEmpty(strings.TrimSpace(result.ServerNode), "local-node"),
		Status:          status,
		Accepted:        accepted,
		RejectionReason: rejectionReason,
		ConnectedAt:     u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return OpenWebSocketConnectionResponse{}, err
	}

	return resp, nil
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if strings.TrimSpace(v) != "" {
			return v
		}
	}
	return ""
}
