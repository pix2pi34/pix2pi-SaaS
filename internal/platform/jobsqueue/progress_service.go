package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"time"
)

type UpdateJobProgressCommand struct {
	TenantID           string
	JobID              string
	WorkerID           string
	Status             string
	ProgressPercent    int
	Message            string
	AttemptNo          int
	LeaseExtendSeconds int
}

type UpdateJobProgressResult struct {
	JobID           string
	Status          string
	ProgressPercent int
	AttemptNo       int
	Message         string
	LeaseExpiresAt  *time.Time
}

type UpdateJobProgressStore interface {
	UpdateJobProgress(ctx context.Context, cmd UpdateJobProgressCommand) (UpdateJobProgressResult, error)
}

type UpdateJobProgressUsecase struct {
	store UpdateJobProgressStore
	nowFn func() time.Time
}

func NewUpdateJobProgressUsecase(store UpdateJobProgressStore) *UpdateJobProgressUsecase {
	return &UpdateJobProgressUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *UpdateJobProgressUsecase) Update(ctx context.Context, req UpdateJobProgressRequest) (UpdateJobProgressResponse, error) {
	if u == nil || u.store == nil {
		return UpdateJobProgressResponse{}, errors.New("update job progress usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.JobID = strings.TrimSpace(req.JobID)
	req.WorkerID = strings.TrimSpace(req.WorkerID)
	req.Status = strings.TrimSpace(req.Status)
	req.Message = strings.TrimSpace(req.Message)

	if err := req.Validate(); err != nil {
		return UpdateJobProgressResponse{}, err
	}

	result, err := u.store.UpdateJobProgress(ctx, UpdateJobProgressCommand{
		TenantID:           req.TenantID,
		JobID:              req.JobID,
		WorkerID:           req.WorkerID,
		Status:             req.Status,
		ProgressPercent:    req.ProgressPercent,
		Message:            req.Message,
		AttemptNo:          req.AttemptNo,
		LeaseExtendSeconds: req.LeaseExtendSeconds,
	})
	if err != nil {
		return UpdateJobProgressResponse{}, err
	}

	status := firstNonEmpty(strings.TrimSpace(result.Status), req.Status)
	progressPercent := result.ProgressPercent
	if progressPercent == 0 && req.ProgressPercent > 0 {
		progressPercent = req.ProgressPercent
	}

	attemptNo := result.AttemptNo
	if attemptNo == 0 {
		attemptNo = req.AttemptNo
	}

	message := firstNonEmpty(strings.TrimSpace(result.Message), req.Message)
	leaseExpiresAt := cloneTimePtr(result.LeaseExpiresAt)

	resp := UpdateJobProgressResponse{
		JobID:           firstNonEmpty(strings.TrimSpace(result.JobID), req.JobID),
		WorkerID:        req.WorkerID,
		Status:          status,
		ProgressPercent: progressPercent,
		AttemptNo:       attemptNo,
		Message:         message,
		LeaseExpiresAt:  leaseExpiresAt,
		UpdatedAt:       u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return UpdateJobProgressResponse{}, err
	}

	return resp, nil
}
