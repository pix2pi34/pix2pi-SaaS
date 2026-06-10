package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

type RecordJobAuditEventCommand struct {
	TenantID  string
	JobID     string
	EventType string
	ActorRef  string
	Status    string
	AttemptNo int
	Message   string
	Metadata  map[string]any
}

type RecordJobAuditEventResult struct {
	AuditID string
}

type JobAuditStore interface {
	RecordJobAuditEvent(ctx context.Context, cmd RecordJobAuditEventCommand) (RecordJobAuditEventResult, error)
}

type JobAuditUsecase struct {
	store JobAuditStore
	nowFn func() time.Time
}

func NewJobAuditUsecase(store JobAuditStore) *JobAuditUsecase {
	return &JobAuditUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *JobAuditUsecase) Record(ctx context.Context, req RecordJobAuditEventRequest) (RecordJobAuditEventResponse, error) {
	if u == nil || u.store == nil {
		return RecordJobAuditEventResponse{}, errors.New("job audit usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.JobID = strings.TrimSpace(req.JobID)
	req.EventType = strings.TrimSpace(req.EventType)
	req.ActorRef = strings.TrimSpace(req.ActorRef)
	req.Status = strings.TrimSpace(req.Status)
	req.Message = strings.TrimSpace(req.Message)

	if err := req.Validate(); err != nil {
		return RecordJobAuditEventResponse{}, err
	}

	result, err := u.store.RecordJobAuditEvent(ctx, RecordJobAuditEventCommand{
		TenantID:  req.TenantID,
		JobID:     req.JobID,
		EventType: req.EventType,
		ActorRef:  req.ActorRef,
		Status:    req.Status,
		AttemptNo: req.AttemptNo,
		Message:   req.Message,
		Metadata:  cloneMap(req.Metadata),
	})
	if err != nil {
		return RecordJobAuditEventResponse{}, err
	}

	auditID := strings.TrimSpace(result.AuditID)
	if auditID == "" {
		auditID = uuid.NewString()
	}

	resp := RecordJobAuditEventResponse{
		AuditID:    auditID,
		JobID:      req.JobID,
		EventType:  req.EventType,
		ActorRef:   req.ActorRef,
		Status:     req.Status,
		AttemptNo:  req.AttemptNo,
		Message:    req.Message,
		Metadata:   cloneMap(req.Metadata),
		OccurredAt: u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return RecordJobAuditEventResponse{}, err
	}

	return resp, nil
}
