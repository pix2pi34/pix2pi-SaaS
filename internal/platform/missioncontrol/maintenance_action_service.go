package missioncontrol

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

type RequestMaintenanceActionCommand struct {
	TenantID        string
	IncidentID      string
	ServiceID       string
	InstanceID      string
	ActionType      string
	RequestedBy     string
	RequestedReason string
	DryRun          bool
}

type RequestMaintenanceActionResult struct {
	ActionID     string
	ActionStatus string
}

type MaintenanceActionStore interface {
	RequestMaintenanceAction(ctx context.Context, cmd RequestMaintenanceActionCommand) (RequestMaintenanceActionResult, error)
}

type MaintenanceActionUsecase struct {
	store MaintenanceActionStore
	nowFn func() time.Time
}

func NewMaintenanceActionUsecase(store MaintenanceActionStore) *MaintenanceActionUsecase {
	return &MaintenanceActionUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *MaintenanceActionUsecase) Request(ctx context.Context, req MaintenanceActionRequest) (MaintenanceActionResponse, error) {
	if u == nil || u.store == nil {
		return MaintenanceActionResponse{}, errors.New("maintenance action usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.IncidentID = strings.TrimSpace(req.IncidentID)
	req.ServiceID = strings.TrimSpace(req.ServiceID)
	req.InstanceID = strings.TrimSpace(req.InstanceID)
	req.ActionType = strings.TrimSpace(req.ActionType)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)
	req.RequestedReason = strings.TrimSpace(req.RequestedReason)

	if err := req.Validate(); err != nil {
		return MaintenanceActionResponse{}, err
	}

	result, err := u.store.RequestMaintenanceAction(ctx, RequestMaintenanceActionCommand{
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
		return MaintenanceActionResponse{}, err
	}

	actionID := strings.TrimSpace(result.ActionID)
	if actionID == "" {
		actionID = uuid.NewString()
	}

	actionStatus := strings.TrimSpace(result.ActionStatus)
	if actionStatus == "" {
		actionStatus = "requested"
	}

	resp := MaintenanceActionResponse{
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
		return MaintenanceActionResponse{}, err
	}

	return resp, nil
}
