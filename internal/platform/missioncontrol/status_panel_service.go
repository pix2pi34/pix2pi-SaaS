package missioncontrol

import (
	"context"
	"errors"
	"sort"
	"strings"
	"time"
)

type StatusPanelStore interface {
	ListRuntimeStatusCards(ctx context.Context, req StatusPanelRequest) ([]ServiceStatusCard, error)
}

type StatusPanelUsecase struct {
	store StatusPanelStore
	nowFn func() time.Time
}

func NewStatusPanelUsecase(store StatusPanelStore) *StatusPanelUsecase {
	return &StatusPanelUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *StatusPanelUsecase) Get(ctx context.Context, req StatusPanelRequest) (StatusPanelResponse, error) {
	if u == nil || u.store == nil {
		return StatusPanelResponse{}, errors.New("mission control status panel usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.ServiceKeyLike = strings.TrimSpace(req.ServiceKeyLike)
	req.StatusFilter = strings.TrimSpace(req.StatusFilter)

	if err := req.Validate(); err != nil {
		return StatusPanelResponse{}, err
	}

	items, err := u.store.ListRuntimeStatusCards(ctx, req)
	if err != nil {
		return StatusPanelResponse{}, err
	}

	sort.Slice(items, func(i, j int) bool {
		if items[i].RuntimeStatus == items[j].RuntimeStatus {
			if items[i].ServiceKey == items[j].ServiceKey {
				return items[i].InstanceKey < items[j].InstanceKey
			}
			return items[i].ServiceKey < items[j].ServiceKey
		}
		return items[i].RuntimeStatus < items[j].RuntimeStatus
	})

	resp := StatusPanelResponse{
		GeneratedAt: u.nowFn().UTC(),
		Summary:     buildStatusPanelSummary(items),
		Items:       items,
	}

	if err := resp.Validate(); err != nil {
		return StatusPanelResponse{}, err
	}

	return resp, nil
}

func buildStatusPanelSummary(items []ServiceStatusCard) StatusPanelSummary {
	summary := StatusPanelSummary{
		Total: len(items),
	}

	for _, item := range items {
		switch item.RuntimeStatus {
		case "healthy":
			summary.Healthy++
		case "degraded":
			summary.Degraded++
		case "unhealthy":
			summary.Unhealthy++
		case "starting":
			summary.Starting++
		case "draining":
			summary.Draining++
		case "stopped":
			summary.Stopped++
		}
	}

	return summary
}
