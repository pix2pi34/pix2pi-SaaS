package realtime

import (
	"context"
	"errors"
	"strings"
	"time"
)

type OpenSSEConnectionCommand struct {
	TenantID     string
	ConnectionID string
	ChannelName  string
	ClientID     string
	UserRef      string
	Protocol     string
	LastEventID  string
	RemoteAddr   string
	Origin       string
	RequestedBy  string
}

type OpenSSEConnectionResult struct {
	ConnectionID    string
	ChannelName     string
	ClientID        string
	UserRef         string
	Protocol        string
	LastEventID     string
	ServerNode      string
	Status          string
	Accepted        bool
	RejectionReason string
}

type SSEConnectionStore interface {
	OpenStream(ctx context.Context, cmd OpenSSEConnectionCommand) (OpenSSEConnectionResult, error)
}

type OpenSSEConnectionUsecase struct {
	store SSEConnectionStore
	nowFn func() time.Time
}

func NewOpenSSEConnectionUsecase(store SSEConnectionStore) *OpenSSEConnectionUsecase {
	return &OpenSSEConnectionUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *OpenSSEConnectionUsecase) Open(ctx context.Context, req OpenSSEConnectionRequest) (OpenSSEConnectionResponse, error) {
	if u == nil || u.store == nil {
		return OpenSSEConnectionResponse{}, errors.New("sse connection usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.ConnectionID = strings.TrimSpace(req.ConnectionID)
	req.ChannelName = strings.TrimSpace(req.ChannelName)
	req.ClientID = strings.TrimSpace(req.ClientID)
	req.UserRef = strings.TrimSpace(req.UserRef)
	req.Protocol = strings.TrimSpace(req.Protocol)
	req.LastEventID = strings.TrimSpace(req.LastEventID)
	req.RemoteAddr = strings.TrimSpace(req.RemoteAddr)
	req.Origin = strings.TrimSpace(req.Origin)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return OpenSSEConnectionResponse{}, err
	}

	result, err := u.store.OpenStream(ctx, OpenSSEConnectionCommand{
		TenantID:     req.TenantID,
		ConnectionID: req.ConnectionID,
		ChannelName:  req.ChannelName,
		ClientID:     req.ClientID,
		UserRef:      req.UserRef,
		Protocol:     req.Protocol,
		LastEventID:  req.LastEventID,
		RemoteAddr:   req.RemoteAddr,
		Origin:       req.Origin,
		RequestedBy:  req.RequestedBy,
	})
	if err != nil {
		return OpenSSEConnectionResponse{}, err
	}

	status := firstNonEmpty(strings.TrimSpace(result.Status), "streaming")
	accepted := result.Accepted
	rejectionReason := strings.TrimSpace(result.RejectionReason)

	if status == "streaming" {
		accepted = true
		rejectionReason = ""
	}

	if status == "rejected" {
		accepted = false
		if rejectionReason == "" {
			rejectionReason = "sse stream rejected"
		}
	}

	resp := OpenSSEConnectionResponse{
		ConnectionID:    firstNonEmpty(strings.TrimSpace(result.ConnectionID), req.ConnectionID),
		ChannelName:     firstNonEmpty(strings.TrimSpace(result.ChannelName), req.ChannelName),
		ClientID:        firstNonEmpty(strings.TrimSpace(result.ClientID), req.ClientID),
		UserRef:         firstNonEmpty(strings.TrimSpace(result.UserRef), req.UserRef),
		Protocol:        firstNonEmpty(strings.TrimSpace(result.Protocol), req.Protocol),
		LastEventID:     firstNonEmpty(strings.TrimSpace(result.LastEventID), req.LastEventID),
		ServerNode:      firstNonEmpty(strings.TrimSpace(result.ServerNode), "local-node"),
		Status:          status,
		Accepted:        accepted,
		RejectionReason: rejectionReason,
		StreamOpenedAt:  u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return OpenSSEConnectionResponse{}, err
	}

	return resp, nil
}
