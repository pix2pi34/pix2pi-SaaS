package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ClaimJobCommand struct {
	TenantID     string
	QueueKey     string
	WorkerID     string
	LeaseSeconds int
}

type ClaimJobResult struct {
	Claimed        bool
	JobID          string
	QueueKey       string
	JobKey         string
	JobType        string
	Priority       string
	Status         string
	AttemptNo      int
	Payload        map[string]any
	LeaseExpiresAt *time.Time
}

type ClaimJobStore interface {
	ClaimNextJob(ctx context.Context, cmd ClaimJobCommand) (ClaimJobResult, error)
}

type ClaimJobUsecase struct {
	store ClaimJobStore
	nowFn func() time.Time
}

func NewClaimJobUsecase(store ClaimJobStore) *ClaimJobUsecase {
	return &ClaimJobUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *ClaimJobUsecase) Claim(ctx context.Context, req ClaimJobRequest) (ClaimJobResponse, error) {
	if u == nil || u.store == nil {
		return ClaimJobResponse{}, errors.New("claim job usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.QueueKey = strings.TrimSpace(req.QueueKey)
	req.WorkerID = strings.TrimSpace(req.WorkerID)

	if err := req.Validate(); err != nil {
		return ClaimJobResponse{}, err
	}

	result, err := u.store.ClaimNextJob(ctx, ClaimJobCommand{
		TenantID:     req.TenantID,
		QueueKey:     req.QueueKey,
		WorkerID:     req.WorkerID,
		LeaseSeconds: req.LeaseSeconds,
	})
	if err != nil {
		return ClaimJobResponse{}, err
	}

	resp := ClaimJobResponse{
		Claimed:   result.Claimed,
		ClaimedAt: u.nowFn().UTC(),
	}

	if result.Claimed {
		resp.JobID = strings.TrimSpace(result.JobID)
		resp.QueueKey = firstNonEmpty(strings.TrimSpace(result.QueueKey), req.QueueKey)
		resp.JobKey = strings.TrimSpace(result.JobKey)
		resp.JobType = strings.TrimSpace(result.JobType)
		resp.Priority = strings.TrimSpace(result.Priority)
		resp.Status = firstNonEmpty(strings.TrimSpace(result.Status), "processing")
		resp.AttemptNo = result.AttemptNo
		resp.Payload = cloneMap(result.Payload)
		resp.WorkerID = req.WorkerID
		resp.LeaseExpiresAt = cloneTimePtr(result.LeaseExpiresAt)
	}

	if err := resp.Validate(); err != nil {
		return ClaimJobResponse{}, err
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
