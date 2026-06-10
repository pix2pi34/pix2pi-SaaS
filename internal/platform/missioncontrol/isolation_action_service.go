package missioncontrol

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

type RequestIsolationActionCommand struct {
	TenantID        string
	IncidentID      string
	ServiceID       string
	InstanceID      string
	ActionType      string
	RequestedBy     string
	RequestedReason string
	DryRun          bool
}

type RequestIsolationActionResult struct {
	ActionID     string
	ActionStatus string
}

type IsolationActionStore interface {
	RequestIsolationAction(ctx context.Context, cmd RequestIsolationActionCommand) (RequestIsolationActionResult, error)
}

type IsolationActionUsecase struct {
	store IsolationActionStore
	nowFn func() time.Time
}

func NewIsolationActionUsecase(store IsolationActionStore) *IsolationActionUsecase {
	return &IsolationActionUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *IsolationActionUsecase) Request(ctx context.Context, req IsolationActionRequest) (IsolationActionResponse, error) {
	if u == nil || u.store == nil {
		return IsolationActionResponse{}, errors.New("isolation action usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.IncidentID = strings.TrimSpace(req.IncidentID)
	req.ServiceID = strings.TrimSpace(req.ServiceID)
	req.InstanceID = strings.TrimSpace(req.InstanceID)
	req.ActionType = strings.TrimSpace(req.ActionType)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)
	req.RequestedReason = strings.TrimSpace(req.RequestedReason)

	if err := req.Validate(); err != nil {
		return IsolationActionResponse{}, err
	}

	result, err := u.store.RequestIsolationAction(ctx, RequestIsolationActionCommand{
		TenantID:        req.TenantID,
		IncidentID:      req.IncidentID,
		ServiceID:       req.ServiceID,
		InstanceID:      req.InstanceID,
		ActionType:      req.ActionType,
		RequestedBy:     req.RequestedBy,
		RequestedReason: req.RequestedReason,
		DryRun:          req.DryRun,
	})
	if err != nil {
		return IsolationActionResponse{}, err
	}

	actionID := strings.TrimSpace(result.ActionID)
	if actionID == "" {
		actionID = uuid.NewString()
	}

	actionStatus := strings.TrimSpace(result.ActionStatus)
	if actionStatus == "" {
		actionStatus = "requested"
	}

	resp := IsolationActionResponse{
		ActionID:     actionID,
		IncidentID:   req.IncidentID,
		ServiceID:    req.ServiceID,
		InstanceID:   req.InstanceID,
		ActionType:   req.ActionType,
		ActionStatus: actionStatus,
		DryRun:       req.DryRun,
		RequestedAt:  u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return IsolationActionResponse{}, err
	}

	return resp, nil
}
