package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"time"
)

type CompleteJobCommand struct {
	TenantID       string
	JobID          string
	WorkerID       string
	Status         string
	AttemptNo      int
	CompletionNote string
	ErrorCode      string
	OutputPayload  map[string]any
}

type CompleteJobResult struct {
	JobID          string
	Status         string
	AttemptNo      int
	CompletionNote string
	ErrorCode      string
	OutputPayload  map[string]any
	LeaseReleased  bool
}

type CompleteJobStore interface {
	CompleteJob(ctx context.Context, cmd CompleteJobCommand) (CompleteJobResult, error)
}

type CompleteJobUsecase struct {
	store CompleteJobStore
	nowFn func() time.Time
}

func NewCompleteJobUsecase(store CompleteJobStore) *CompleteJobUsecase {
	return &CompleteJobUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *CompleteJobUsecase) Complete(ctx context.Context, req CompleteJobRequest) (CompleteJobResponse, error) {
	if u == nil || u.store == nil {
		return CompleteJobResponse{}, errors.New("complete job usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.JobID = strings.TrimSpace(req.JobID)
	req.WorkerID = strings.TrimSpace(req.WorkerID)
	req.Status = strings.TrimSpace(req.Status)
	req.CompletionNote = strings.TrimSpace(req.CompletionNote)
	req.ErrorCode = strings.TrimSpace(req.ErrorCode)

	if err := req.Validate(); err != nil {
		return CompleteJobResponse{}, err
	}

	result, err := u.store.CompleteJob(ctx, CompleteJobCommand{
		TenantID:       req.TenantID,
		JobID:          req.JobID,
		WorkerID:       req.WorkerID,
		Status:         req.Status,
		AttemptNo:      req.AttemptNo,
		CompletionNote: req.CompletionNote,
		ErrorCode:      req.ErrorCode,
		OutputPayload:  cloneMap(req.OutputPayload),
	})
	if err != nil {
		return CompleteJobResponse{}, err
	}

	resp := CompleteJobResponse{
		JobID:          firstNonEmpty(strings.TrimSpace(result.JobID), req.JobID),
		WorkerID:       req.WorkerID,
		Status:         firstNonEmpty(strings.TrimSpace(result.Status), req.Status),
		AttemptNo:      firstNonZero(result.AttemptNo, req.AttemptNo),
		CompletionNote: firstNonEmpty(strings.TrimSpace(result.CompletionNote), req.CompletionNote),
		ErrorCode:      firstNonEmpty(strings.TrimSpace(result.ErrorCode), req.ErrorCode),
		OutputPayload:  cloneMap(nonNilMap(result.OutputPayload, req.OutputPayload)),
		LeaseReleased:  result.LeaseReleased || true,
		FinishedAt:     u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return CompleteJobResponse{}, err
	}

	return resp, nil
}

func firstNonZero(values ...int) int {
	for _, v := range values {
		if v != 0 {
			return v
		}
	}
	return 0
}

func nonNilMap(primary map[string]any, fallback map[string]any) map[string]any {
	if len(primary) > 0 {
		return primary
	}
	return fallback
}
