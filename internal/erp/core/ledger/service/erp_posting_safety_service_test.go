package service

import (
	"context"
	"testing"

	ledgerdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/domain"
)

type fakePostingExecutionTracker struct {
	existingKeys map[string]bool
	markCalls    int
	lastKey      string
	lastState    PostingState
	lastDetail   string
	existsErr    error
	markErr      error
}

func newFakePostingExecutionTracker() *fakePostingExecutionTracker {
	return &fakePostingExecutionTracker{
		existingKeys: make(map[string]bool),
	}
}

func (f *fakePostingExecutionTracker) Exists(_ context.Context, executionKey string) (bool, error) {
	if f.existsErr != nil {
		return false, f.existsErr
	}
	return f.existingKeys[executionKey], nil
}

func (f *fakePostingExecutionTracker) Mark(_ context.Context, executionKey string, state PostingState, detail string) error {
	if f.markErr != nil {
		return f.markErr
	}
	f.markCalls++
	f.lastKey = executionKey
	f.lastState = state
	f.lastDetail = detail
	f.existingKeys[executionKey] = true
	return nil
}

func sampleSafetyPostings() []ledgerdomain.LedgerPosting {
	return []ledgerdomain.LedgerPosting{
		{
			PostingID:    "JRNL-sale_1001-1",
			JournalID:    "JRNL-sale_1001",
			EventID:      "sale_1001",
			DocumentNo:   "DOC-1001",
			ReferenceID:  "REF-1001",
			SourceModule: "POS",
			AccountCode:  "100.01",
			Debit:        120,
			Credit:       0,
		},
		{
			PostingID:    "JRNL-sale_1001-2",
			JournalID:    "JRNL-sale_1001",
			EventID:      "sale_1001",
			DocumentNo:   "DOC-1001",
			ReferenceID:  "REF-1001",
			SourceModule: "POS",
			AccountCode:  "600.01.001",
			Debit:        0,
			Credit:       100,
		},
		{
			PostingID:    "JRNL-sale_1001-3",
			JournalID:    "JRNL-sale_1001",
			EventID:      "sale_1001",
			DocumentNo:   "DOC-1001",
			ReferenceID:  "REF-1001",
			SourceModule: "POS",
			AccountCode:  "391.01.20",
			Debit:        0,
			Credit:       20,
		},
	}
}

func TestPostingSafetyService_Evaluate_FirstRunAllowed(t *testing.T) {
	tracker := newFakePostingExecutionTracker()

	svc, err := NewPostingSafetyService(tracker)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	decision, err := svc.Evaluate(context.Background(), PostingSafetyRequest{
		TenantID: "tenant_42",
		EventID:  "sale_1001",
		JournalID: "JRNL-sale_1001",
		Replay:   false,
		Postings: sampleSafetyPostings(),
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !decision.Allowed {
		t.Fatal("expected allowed")
	}
	if decision.IsDuplicate {
		t.Fatal("expected not duplicate")
	}
	if decision.State != PostingStatePlanned {
		t.Fatalf("expected planned, got %s", decision.State)
	}
}

func TestPostingSafetyService_Evaluate_DuplicateBlocked(t *testing.T) {
	tracker := newFakePostingExecutionTracker()
	tracker.existingKeys["tenant_42::sale_1001::JRNL-sale_1001"] = true

	svc, err := NewPostingSafetyService(tracker)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	decision, err := svc.Evaluate(context.Background(), PostingSafetyRequest{
		TenantID: "tenant_42",
		EventID:  "sale_1001",
		JournalID: "JRNL-sale_1001",
		Replay:   false,
		Postings: sampleSafetyPostings(),
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if decision.Allowed {
		t.Fatal("expected blocked duplicate")
	}
	if !decision.IsDuplicate {
		t.Fatal("expected duplicate")
	}
	if decision.State != PostingStateSkippedDuplicate {
		t.Fatalf("expected skipped_duplicate, got %s", decision.State)
	}
}

func TestPostingSafetyService_Evaluate_ReplayAllowed(t *testing.T) {
	tracker := newFakePostingExecutionTracker()
	tracker.existingKeys["tenant_42::sale_1001::JRNL-sale_1001"] = true

	svc, err := NewPostingSafetyService(tracker)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	decision, err := svc.Evaluate(context.Background(), PostingSafetyRequest{
		TenantID: "tenant_42",
		EventID:  "sale_1001",
		JournalID: "JRNL-sale_1001",
		Replay:   true,
		Postings: sampleSafetyPostings(),
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !decision.Allowed {
		t.Fatal("expected replay allowed")
	}
	if !decision.IsDuplicate {
		t.Fatal("expected duplicate true on replay")
	}
	if decision.State != PostingStateReplayAccepted {
		t.Fatalf("expected replay_accepted, got %s", decision.State)
	}
}

func TestPostingSafetyService_MarkLifecycle(t *testing.T) {
	tracker := newFakePostingExecutionTracker()

	svc, err := NewPostingSafetyService(tracker)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	decision := PostingSafetyDecision{
		ExecutionKey: "tenant_42::sale_1001::JRNL-sale_1001",
		Allowed:      true,
		State:        PostingStatePlanned,
	}

	if err := svc.MarkRunning(context.Background(), decision); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if tracker.lastState != PostingStateRunning {
		t.Fatalf("expected running, got %s", tracker.lastState)
	}

	if err := svc.MarkCompleted(context.Background(), decision); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if tracker.lastState != PostingStateCompleted {
		t.Fatalf("expected completed, got %s", tracker.lastState)
	}

	if err := svc.MarkFailed(context.Background(), decision, nil); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if tracker.lastState != PostingStateFailed {
		t.Fatalf("expected failed, got %s", tracker.lastState)
	}

	if tracker.markCalls != 3 {
		t.Fatalf("expected 3 mark calls, got %d", tracker.markCalls)
	}
}

func TestPostingSafetyService_Evaluate_PostingMismatch(t *testing.T) {
	tracker := newFakePostingExecutionTracker()

	svc, err := NewPostingSafetyService(tracker)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	postings := sampleSafetyPostings()
	postings[0].EventID = "sale_9999"

	_, err = svc.Evaluate(context.Background(), PostingSafetyRequest{
		TenantID: "tenant_42",
		EventID:  "sale_1001",
		JournalID: "JRNL-sale_1001",
		Replay:   false,
		Postings: postings,
	})
	if err == nil {
		t.Fatal("expected posting mismatch error")
	}
}
