package serviceregistry

import (
	"context"
	"errors"
	"strings"
	"time"
)

type HeartbeatStore interface {
	RecordHeartbeat(ctx context.Context, cmd RecordHeartbeatCommand) (RecordHeartbeatResult, error)
}

type RecordHeartbeatCommand struct {
	TenantID                 string
	ServiceKey               string
	InstanceKey              string
	Status                   string
	Mode                     string
	ResponseTimeMS           int
	HeartbeatIntervalSeconds int
	Metadata                 map[string]any
}

type RecordHeartbeatResult struct {
	NextHeartbeatInSeconds int
	HealthPullRequested    bool
}

type HeartbeatUsecase struct {
	store HeartbeatStore
	nowFn func() time.Time
}

func NewHeartbeatUsecase(store HeartbeatStore) *HeartbeatUsecase {
	return &HeartbeatUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *HeartbeatUsecase) Accept(ctx context.Context, req HeartbeatRequest) (HeartbeatResponse, error) {
	if u == nil || u.store == nil {
		return HeartbeatResponse{}, errors.New("heartbeat usecase hazir degil")
	}

	if err := req.Validate(); err != nil {
		return HeartbeatResponse{}, err
	}

	cmd := RecordHeartbeatCommand{
		TenantID:                 strings.TrimSpace(req.TenantID),
		ServiceKey:               strings.TrimSpace(req.ServiceKey),
		InstanceKey:              strings.TrimSpace(req.InstanceKey),
		Status:                   strings.TrimSpace(req.Status),
		Mode:                     strings.TrimSpace(req.Mode),
		ResponseTimeMS:           req.ResponseTimeMS,
		HeartbeatIntervalSeconds: req.HeartbeatIntervalSeconds,
		Metadata:                 cloneMap(req.Metadata),
	}

	result, err := u.store.RecordHeartbeat(ctx, cmd)
	if err != nil {
		return HeartbeatResponse{}, err
	}

	nextHeartbeat := result.NextHeartbeatInSeconds
	if nextHeartbeat == 0 {
		nextHeartbeat = req.HeartbeatIntervalSeconds
	}

	healthPullRequested := result.HealthPullRequested
	if !healthPullRequested {
		switch req.Status {
		case "degraded", "unhealthy", "draining":
			healthPullRequested = true
		}
	}

	resp := HeartbeatResponse{
		ServiceKey:             cmd.ServiceKey,
		InstanceKey:            cmd.InstanceKey,
		Status:                 cmd.Status,
		HeartbeatAcceptedAt:    u.nowFn().UTC(),
		NextHeartbeatInSeconds: nextHeartbeat,
		HealthPullRequested:    healthPullRequested,
	}

	if err := resp.Validate(); err != nil {
		return HeartbeatResponse{}, err
	}

	return resp, nil
}
