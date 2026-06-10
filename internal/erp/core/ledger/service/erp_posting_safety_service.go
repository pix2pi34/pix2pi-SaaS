package service

import (
	"context"
	"fmt"
	"strings"

	ledgerdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/domain"
)

type PostingState string

const (
	PostingStatePlanned          PostingState = "planned"
	PostingStateRunning          PostingState = "running"
	PostingStateCompleted        PostingState = "completed"
	PostingStateFailed           PostingState = "failed"
	PostingStateSkippedDuplicate PostingState = "skipped_duplicate"
	PostingStateReplayAccepted   PostingState = "replay_accepted"
)

type PostingSafetyRequest struct {
	TenantID string
	EventID  string
	JournalID string
	Replay   bool
	Postings []ledgerdomain.LedgerPosting
}

type PostingSafetyDecision struct {
	ExecutionKey string
	Allowed      bool
	IsDuplicate  bool
	Replay       bool
	State        PostingState
	Reason       string
}

type PostingExecutionTracker interface {
	Exists(ctx context.Context, executionKey string) (bool, error)
	Mark(ctx context.Context, executionKey string, state PostingState, detail string) error
}

type PostingSafetyService struct {
	tracker PostingExecutionTracker
}

func NewPostingSafetyService(
	tracker PostingExecutionTracker,
) (*PostingSafetyService, error) {
	if tracker == nil {
		return nil, fmt.Errorf("posting execution tracker cannot be nil")
	}

	return &PostingSafetyService{
		tracker: tracker,
	}, nil
}

func (s *PostingSafetyService) Evaluate(
	ctx context.Context,
	req PostingSafetyRequest,
) (PostingSafetyDecision, error) {
	if s == nil {
		return PostingSafetyDecision{}, fmt.Errorf("posting safety service cannot be nil")
	}
	if strings.TrimSpace(req.TenantID) == "" {
		return PostingSafetyDecision{}, fmt.Errorf("tenant id cannot be empty")
	}
	if strings.TrimSpace(req.EventID) == "" {
		return PostingSafetyDecision{}, fmt.Errorf("event id cannot be empty")
	}
	if strings.TrimSpace(req.JournalID) == "" {
		return PostingSafetyDecision{}, fmt.Errorf("journal id cannot be empty")
	}
	if len(req.Postings) == 0 {
		return PostingSafetyDecision{}, fmt.Errorf("postings cannot be empty")
	}

	for _, posting := range req.Postings {
		if strings.TrimSpace(posting.PostingID) == "" {
			return PostingSafetyDecision{}, fmt.Errorf("posting id cannot be empty")
		}
		if posting.JournalID != req.JournalID {
			return PostingSafetyDecision{}, fmt.Errorf(
				"posting journal mismatch: expected=%s got=%s",
				req.JournalID,
				posting.JournalID,
			)
		}
		if posting.EventID != req.EventID {
			return PostingSafetyDecision{}, fmt.Errorf(
				"posting event mismatch: expected=%s got=%s",
				req.EventID,
				posting.EventID,
			)
		}
	}

	executionKey := s.buildExecutionKey(req.TenantID, req.EventID, req.JournalID)

	exists, err := s.tracker.Exists(ctx, executionKey)
	if err != nil {
		return PostingSafetyDecision{}, err
	}

	if exists && !req.Replay {
		return PostingSafetyDecision{
			ExecutionKey: executionKey,
			Allowed:      false,
			IsDuplicate:  true,
			Replay:       false,
			State:        PostingStateSkippedDuplicate,
			Reason:       "duplicate posting blocked",
		}, nil
	}

	if exists && req.Replay {
		return PostingSafetyDecision{
			ExecutionKey: executionKey,
			Allowed:      true,
			IsDuplicate:  true,
			Replay:       true,
			State:        PostingStateReplayAccepted,
			Reason:       "replay explicitly allowed",
		}, nil
	}

	return PostingSafetyDecision{
		ExecutionKey: executionKey,
		Allowed:      true,
		IsDuplicate:  false,
		Replay:       req.Replay,
		State:        PostingStatePlanned,
		Reason:       "posting allowed",
	}, nil
}

func (s *PostingSafetyService) MarkRunning(
	ctx context.Context,
	decision PostingSafetyDecision,
) error {
	return s.mark(ctx, decision, PostingStateRunning, "posting running")
}

func (s *PostingSafetyService) MarkCompleted(
	ctx context.Context,
	decision PostingSafetyDecision,
) error {
	return s.mark(ctx, decision, PostingStateCompleted, "posting completed")
}

func (s *PostingSafetyService) MarkFailed(
	ctx context.Context,
	decision PostingSafetyDecision,
	err error,
) error {
	detail := "posting failed"
	if err != nil {
		detail = err.Error()
	}
	return s.mark(ctx, decision, PostingStateFailed, detail)
}

func (s *PostingSafetyService) mark(
	ctx context.Context,
	decision PostingSafetyDecision,
	state PostingState,
	detail string,
) error {
	if s == nil {
		return fmt.Errorf("posting safety service cannot be nil")
	}
	if strings.TrimSpace(decision.ExecutionKey) == "" {
		return fmt.Errorf("execution key cannot be empty")
	}

	switch state {
	case PostingStateRunning, PostingStateCompleted, PostingStateFailed:
	default:
		return fmt.Errorf("invalid posting state: %s", state)
	}

	return s.tracker.Mark(ctx, decision.ExecutionKey, state, detail)
}

func (s *PostingSafetyService) buildExecutionKey(
	tenantID string,
	eventID string,
	journalID string,
) string {
	return strings.TrimSpace(tenantID) + "::" +
		strings.TrimSpace(eventID) + "::" +
		strings.TrimSpace(journalID)
}
