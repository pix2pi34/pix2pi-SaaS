package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"time"
)

type RecoverJobCommand struct {
	TenantID       string
	JobID          string
	ActionType     string
	RequestedBy    string
	TargetQueueKey string
	Reason         string
	ResetAttempts  bool
}

type RecoverJobResult struct {
	JobID         string
	Status        string
	QueueKey      string
	AttemptNo     int
	LeaseReleased bool
}

type RecoverJobStore interface {
	RecoverJob(ctx context.Context, cmd RecoverJobCommand) (RecoverJobResult, error)
}

type RecoverJobUsecase struct {
	store RecoverJobStore
	nowFn func() time.Time
}

func NewRecoverJobUsecase(store RecoverJobStore) *RecoverJobUsecase {
	return &RecoverJobUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *RecoverJobUsecase) Recover(ctx context.Context, req RecoverJobRequest) (RecoverJobResponse, error) {
	if u == nil || u.store == nil {
		return RecoverJobResponse{}, errors.New("recover job usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.JobID = strings.TrimSpace(req.JobID)
	req.ActionType = strings.TrimSpace(req.ActionType)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)
	req.TargetQueueKey = strings.TrimSpace(req.TargetQueueKey)
	req.Reason = strings.TrimSpace(req.Reason)

	if err := req.Validate(); err != nil {
		return RecoverJobResponse{}, err
	}

	result, err := u.store.RecoverJob(ctx, RecoverJobCommand{
		TenantID:       req.TenantID,
		JobID:          req.JobID,
		ActionType:     req.ActionType,
		RequestedBy:    req.RequestedBy,
		TargetQueueKey: req.TargetQueueKey,
		Reason:         req.Reason,
		ResetAttempts:  req.ResetAttempts,
	})
	if err != nil {
		return RecoverJobResponse{}, err
	}

	status := strings.TrimSpace(result.Status)
	if status == "" {
		switch req.ActionType {
		case "dead_letter":
			status = "dead_letter"
		default:
			status = "queued"
		}
	}

	queueKey := firstNonEmpty(strings.TrimSpace(result.QueueKey), req.TargetQueueKey)

	attemptNo := result.AttemptNo
	if req.ResetAttempts && attemptNo == 0 {
		attemptNo = 0
	}

	leaseReleased := result.LeaseReleased
	if !leaseReleased {
		leaseReleased = true
	}

	resp := RecoverJobResponse{
		JobID:         firstNonEmpty(strings.TrimSpace(result.JobID), req.JobID),
		ActionType:    req.ActionType,
		Status:        status,
		QueueKey:      queueKey,
		AttemptNo:     attemptNo,
		LeaseReleased: leaseReleased,
		RequestedBy:   req.RequestedBy,
		Reason:        req.Reason,
		RequestedAt:   u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return RecoverJobResponse{}, err
	}

	return resp, nil
}
