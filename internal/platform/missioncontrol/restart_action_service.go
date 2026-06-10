package missioncontrol

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

type RequestRestartActionCommand struct {
	TenantID        string
	IncidentID      string
	ServiceID       string
	InstanceID      string
	RequestedBy     string
	RequestedReason string
	DryRun          bool
}

type RequestRestartActionResult struct {
	ActionID     string
	ActionStatus string
}

type RestartActionStore interface {
	RequestRestartAction(ctx context.Context, cmd RequestRestartActionCommand) (RequestRestartActionResult, error)
}

type RestartActionUsecase struct {
	store RestartActionStore
	nowFn func() time.Time
}

func NewRestartActionUsecase(store RestartActionStore) *RestartActionUsecase {
	return &RestartActionUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *RestartActionUsecase) Request(ctx context.Context, req RestartActionRequest) (RestartActionResponse, error) {
	if u == nil || u.store == nil {
		return RestartActionResponse{}, errors.New("restart action usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.IncidentID = strings.TrimSpace(req.IncidentID)
	req.ServiceID = strings.TrimSpace(req.ServiceID)
	req.InstanceID = strings.TrimSpace(req.InstanceID)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)
	req.RequestedReason = strings.TrimSpace(req.RequestedReason)

	if err := req.Validate(); err != nil {
		return RestartActionResponse{}, err
	}

	result, err := u.store.RequestRestartAction(ctx, RequestRestartActionCommand{
		TenantID:        req.TenantID,
		IncidentID:      req.IncidentID,
		ServiceID:       req.ServiceID,
		InstanceID:      req.InstanceID,
		RequestedBy:     req.RequestedBy,
		RequestedReason: req.RequestedReason,
		DryRun:          req.DryRun,
	})
	if err != nil {
		return RestartActionResponse{}, err
	}

	actionID := strings.TrimSpace(result.ActionID)
	if actionID == "" {
		actionID = uuid.NewString()
	}

	actionStatus := strings.TrimSpace(result.ActionStatus)
	if actionStatus == "" {
		actionStatus = "requested"
	}

	resp := RestartActionResponse{
		ActionID:     actionID,
		IncidentID:   req.IncidentID,
		ServiceID:    req.ServiceID,
		InstanceID:   req.InstanceID,
		ActionType:   "restart",
		ActionStatus: actionStatus,
		DryRun:       req.DryRun,
		RequestedAt:  u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return RestartActionResponse{}, err
	}

	return resp, nil
}
