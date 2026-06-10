package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

type EnqueueJobCommand struct {
	TenantID    string
	QueueKey    string
	JobKey      string
	JobType     string
	Priority    string
	DedupKey    string
	Payload     map[string]any
	ScheduledAt *time.Time
	RequestedBy string
	MaxAttempts int
}

type EnqueueJobResult struct {
	JobID        string
	Status       string
	DedupMatched bool
	ScheduledAt  *time.Time
}

type EnqueueJobStore interface {
	EnqueueJob(ctx context.Context, cmd EnqueueJobCommand) (EnqueueJobResult, error)
}

type EnqueueJobUsecase struct {
	store EnqueueJobStore
	nowFn func() time.Time
}

func NewEnqueueJobUsecase(store EnqueueJobStore) *EnqueueJobUsecase {
	return &EnqueueJobUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *EnqueueJobUsecase) Enqueue(ctx context.Context, req EnqueueJobRequest) (EnqueueJobResponse, error) {
	if u == nil || u.store == nil {
		return EnqueueJobResponse{}, errors.New("enqueue job usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.QueueKey = strings.TrimSpace(req.QueueKey)
	req.JobKey = strings.TrimSpace(req.JobKey)
	req.JobType = strings.TrimSpace(req.JobType)
	req.Priority = strings.TrimSpace(req.Priority)
	req.DedupKey = strings.TrimSpace(req.DedupKey)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return EnqueueJobResponse{}, err
	}

	result, err := u.store.EnqueueJob(ctx, EnqueueJobCommand{
		TenantID:    req.TenantID,
		QueueKey:    req.QueueKey,
		JobKey:      req.JobKey,
		JobType:     req.JobType,
		Priority:    req.Priority,
		DedupKey:    req.DedupKey,
		Payload:     cloneMap(req.Payload),
		ScheduledAt: cloneTimePtr(req.ScheduledAt),
		RequestedBy: req.RequestedBy,
		MaxAttempts: req.MaxAttempts,
	})
	if err != nil {
		return EnqueueJobResponse{}, err
	}

	jobID := strings.TrimSpace(result.JobID)
	if jobID == "" {
		jobID = uuid.NewString()
	}

	status := strings.TrimSpace(result.Status)
	if status == "" {
		if req.ScheduledAt != nil {
			status = "scheduled"
		} else {
			status = "queued"
		}
	}

	scheduledAt := cloneTimePtr(result.ScheduledAt)
	if scheduledAt == nil {
		scheduledAt = cloneTimePtr(req.ScheduledAt)
	}

	resp := EnqueueJobResponse{
		JobID:        jobID,
		QueueKey:     req.QueueKey,
		JobKey:       req.JobKey,
		JobType:      req.JobType,
		Priority:     req.Priority,
		Status:       status,
		DedupMatched: result.DedupMatched,
		ScheduledAt:  scheduledAt,
		EnqueuedAt:   u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return EnqueueJobResponse{}, err
	}

	return resp, nil
}

func cloneMap(in map[string]any) map[string]any {
	if len(in) == 0 {
		return map[string]any{}
	}

	out := make(map[string]any, len(in))
	for k, v := range in {
		out[k] = v
	}

	return out
}

func cloneTimePtr(in *time.Time) *time.Time {
	if in == nil {
		return nil
	}

	t := in.UTC()
	return &t
}
