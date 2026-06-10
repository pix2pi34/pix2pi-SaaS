package missioncontrol

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

type RequestIncidentStateActionCommand struct {
	TenantID     string
	IncidentID   string
	ServiceID    string
	ActionType   string
	RequestedBy  string
	ResponseNote string
	DryRun       bool
}

type RequestIncidentStateActionResult struct {
	ActionID       string
	ActionStatus   string
	IncidentStatus string
}

type IncidentStateActionStore interface {
	RequestIncidentStateAction(ctx context.Context, cmd RequestIncidentStateActionCommand) (RequestIncidentStateActionResult, error)
}

type IncidentStateActionUsecase struct {
	store IncidentStateActionStore
	nowFn func() time.Time
}

func NewIncidentStateActionUsecase(store IncidentStateActionStore) *IncidentStateActionUsecase {
	return &IncidentStateActionUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *IncidentStateActionUsecase) Request(ctx context.Context, req IncidentStateActionRequest) (IncidentStateActionResponse, error) {
	if u == nil || u.store == nil {
		return IncidentStateActionResponse{}, errors.New("incident state action usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.IncidentID = strings.TrimSpace(req.IncidentID)
	req.ServiceID = strings.TrimSpace(req.ServiceID)
	req.ActionType = strings.TrimSpace(req.ActionType)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)
	req.ResponseNote = strings.TrimSpace(req.ResponseNote)

	if err := req.Validate(); err != nil {
		return IncidentStateActionResponse{}, err
	}

	result, err := u.store.RequestIncidentStateAction(ctx, RequestIncidentStateActionCommand{
		TenantID:     req.TenantID,
		IncidentID:   req.IncidentID,
		ServiceID:    req.ServiceID,
		ActionType:   req.ActionType,
		RequestedBy:  req.RequestedBy,
		ResponseNote: req.ResponseNote,
		DryRun:       req.DryRun,
	})
	if err != nil {
		return IncidentStateActionResponse{}, err
	}

	actionID := strings.TrimSpace(result.ActionID)
	if actionID == "" {
		actionID = uuid.NewString()
	}

	actionStatus := strings.TrimSpace(result.ActionStatus)
	if actionStatus == "" {
		actionStatus = "requested"
	}

	incidentStatus := strings.TrimSpace(result.IncidentStatus)
	if incidentStatus == "" {
		switch req.ActionType {
		case "acknowledge":
			incidentStatus = "acknowledged"
		case "resolve":
			incidentStatus = "resolved"
		default:
			incidentStatus = "open"
		}
	}

	resp := IncidentStateActionResponse{
		ActionID:       actionID,
		IncidentID:     req.IncidentID,
		ServiceID:      req.ServiceID,
		ActionType:     req.ActionType,
		ActionStatus:   actionStatus,
		IncidentStatus: incidentStatus,
		ResponseNote:   req.ResponseNote,
		DryRun:         req.DryRun,
		RequestedAt:    u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return IncidentStateActionResponse{}, err
	}

	return resp, nil
}
