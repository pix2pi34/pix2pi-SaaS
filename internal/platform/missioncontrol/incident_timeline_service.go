package missioncontrol

import (
	"context"
	"errors"
	"sort"
	"strings"
	"time"
)

type ListIncidentTimelineCommand struct {
	TenantID            string
	IncidentID          string
	ServiceID           string
	IncludeActions      bool
	IncludeStateChanges bool
	IncludeNotes        bool
	Limit               int
}

type IncidentTimelineStore interface {
	ListIncidentTimeline(ctx context.Context, cmd ListIncidentTimelineCommand) ([]IncidentTimelineItem, error)
}

type IncidentTimelineUsecase struct {
	store IncidentTimelineStore
	nowFn func() time.Time
}

func NewIncidentTimelineUsecase(store IncidentTimelineStore) *IncidentTimelineUsecase {
	return &IncidentTimelineUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *IncidentTimelineUsecase) List(ctx context.Context, req IncidentTimelineRequest) (IncidentTimelineResponse, error) {
	if u == nil || u.store == nil {
		return IncidentTimelineResponse{}, errors.New("incident timeline usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.IncidentID = strings.TrimSpace(req.IncidentID)
	req.ServiceID = strings.TrimSpace(req.ServiceID)

	if err := req.Validate(); err != nil {
		return IncidentTimelineResponse{}, err
	}

	items, err := u.store.ListIncidentTimeline(ctx, ListIncidentTimelineCommand{
		TenantID:            req.TenantID,
		IncidentID:          req.IncidentID,
		ServiceID:           req.ServiceID,
		IncludeActions:      req.IncludeActions,
		IncludeStateChanges: req.IncludeStateChanges,
		IncludeNotes:        req.IncludeNotes,
		Limit:               req.Limit,
	})
	if err != nil {
		return IncidentTimelineResponse{}, err
	}

	sort.Slice(items, func(i, j int) bool {
		return items[i].OccurredAt.After(items[j].OccurredAt)
	})

	resp := IncidentTimelineResponse{
		GeneratedAt: u.nowFn().UTC(),
		Count:       len(items),
		Items:       items,
	}

	if err := resp.Validate(); err != nil {
		return IncidentTimelineResponse{}, err
	}

	return resp, nil
}
