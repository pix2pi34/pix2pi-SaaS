package workflow

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type manualApprovalRowMock struct {
	values []any
	err    error
}

func (r *manualApprovalRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *bool:
			*d = r.values[i].(bool)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type manualApprovalQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *manualApprovalQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestApplyManualApprovalSQLStoreApplyApprovalDecision_ApproveSuccess(t *testing.T) {
	db := &manualApprovalQueryRowProviderMock{
		row: &manualApprovalRowMock{
			values: []any{
				"wf-run-001",
				"approval-step-1",
				"approval-001",
				"user-approver-1",
				"approve",
				"approved",
				"approved",
				"uygun bulundu",
				true,
			},
		},
	}

	store := NewApplyManualApprovalSQLStore(db)

	result, err := store.ApplyApprovalDecision(context.Background(), ApplyManualApprovalCommand{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		ApprovalID:    "approval-001",
		ApproverRef:   "user-approver-1",
		Decision:      "approve",
		Comment:       "uygun bulundu",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.WorkflowRunID != "wf-run-001" {
		t.Fatalf("beklenen workflow_run_id wf-run-001, alinan: %s", result.WorkflowRunID)
	}

	if result.ApprovalStatus != "approved" {
		t.Fatalf("beklenen approval_status approved, alinan: %s", result.ApprovalStatus)
	}

	if result.WorkflowNextState != "approved" {
		t.Fatalf("beklenen workflow_next_state approved, alinan: %s", result.WorkflowNextState)
	}

	if !result.Completed {
		t.Fatalf("beklenen completed true")
	}

	if !strings.Contains(db.lastQuery, "runtime.workflow_approvals") {
		t.Fatalf("workflow_approvals query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.workflow_steps") {
		t.Fatalf("workflow_steps query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.workflow_runs") {
		t.Fatalf("workflow_runs query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "approval_status = CASE") {
		t.Fatalf("approval_status update query icinde olmaliydi")
	}

	if len(db.lastArgs) != 7 {
		t.Fatalf("beklenen 7 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestApplyManualApprovalSQLStoreApplyApprovalDecision_RejectSuccess(t *testing.T) {
	db := &manualApprovalQueryRowProviderMock{
		row: &manualApprovalRowMock{
			values: []any{
				"wf-run-002",
				"approval-step-2",
				"approval-002",
				"user-approver-2",
				"reject",
				"rejected",
				"rejected",
				"eksik bilgi",
				true,
			},
		},
	}

	store := NewApplyManualApprovalSQLStore(db)

	result, err := store.ApplyApprovalDecision(context.Background(), ApplyManualApprovalCommand{
		WorkflowRunID: "wf-run-002",
		StepKey:       "approval-step-2",
		ApprovalID:    "approval-002",
		ApproverRef:   "user-approver-2",
		Decision:      "reject",
		Comment:       "eksik bilgi",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.ApprovalStatus != "rejected" {
		t.Fatalf("beklenen approval_status rejected, alinan: %s", result.ApprovalStatus)
	}

	if result.WorkflowNextState != "rejected" {
		t.Fatalf("beklenen workflow_next_state rejected, alinan: %s", result.WorkflowNextState)
	}
}

func TestApplyManualApprovalSQLStoreApplyApprovalDecision_NoDB(t *testing.T) {
	store := NewApplyManualApprovalSQLStore(nil)

	_, err := store.ApplyApprovalDecision(context.Background(), ApplyManualApprovalCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestApplyManualApprovalSQLStoreApplyApprovalDecision_ScanError(t *testing.T) {
	db := &manualApprovalQueryRowProviderMock{
		row: &manualApprovalRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewApplyManualApprovalSQLStore(db)

	_, err := store.ApplyApprovalDecision(context.Background(), ApplyManualApprovalCommand{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		ApprovalID:    "approval-001",
		ApproverRef:   "user-approver-1",
		Decision:      "approve",
		Comment:       "uygun bulundu",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
