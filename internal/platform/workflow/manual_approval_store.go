package workflow

import (
	"context"
	"errors"
	"strings"
)

type ApplyManualApprovalSQLStore struct {
	db QueryRowProvider
}

func NewApplyManualApprovalSQLStore(db QueryRowProvider) *ApplyManualApprovalSQLStore {
	return &ApplyManualApprovalSQLStore{
		db: db,
	}
}

func (s *ApplyManualApprovalSQLStore) ApplyApprovalDecision(ctx context.Context, cmd ApplyManualApprovalCommand) (ApplyManualApprovalResult, error) {
	if s == nil || s.db == nil {
		return ApplyManualApprovalResult{}, errors.New("manual approval sql store hazir degil")
	}

	const query = `
WITH decided_approval AS (
  UPDATE runtime.workflow_approvals wa
  SET
    approver_ref = $5,
    decision = $6,
    approval_status = CASE
      WHEN $6 = 'approve' THEN 'approved'
      ELSE 'rejected'
    END,
    comment = NULLIF($7, ''),
    completed = true,
    decided_at = now(),
    updated_at = now()
  WHERE wa.run_id = $2
    AND wa.step_key = $3
    AND wa.approval_id = $4
    AND (
      (NULLIF($1, '') IS NULL AND wa.tenant_id IS NULL)
      OR
      (wa.tenant_id::text = NULLIF($1, ''))
    )
  RETURNING
    wa.run_id,
    wa.step_key,
    wa.approval_id,
    wa.approver_ref,
    wa.decision,
    wa.approval_status::text AS approval_status,
    coalesce(wa.comment, '') AS comment,
    true AS completed
),
updated_step AS (
  UPDATE runtime.workflow_steps ws
  SET
    status = CASE
      WHEN $6 = 'approve' THEN 'approved'
      ELSE 'rejected'
    END,
    updated_at = now()
  WHERE ws.run_id = $2
    AND ws.step_key = $3
    AND EXISTS (SELECT 1 FROM decided_approval)
  RETURNING ws.run_id
),
updated_run AS (
  UPDATE runtime.workflow_runs wr
  SET
    current_state = CASE
      WHEN $6 = 'approve' THEN 'approved'
      ELSE 'rejected'
    END,
    updated_at = now()
  WHERE wr.run_id = $2
    AND EXISTS (SELECT 1 FROM decided_approval)
  RETURNING wr.run_id
)
SELECT
  da.run_id,
  da.step_key,
  da.approval_id,
  da.approver_ref,
  da.decision,
  da.approval_status,
  CASE
    WHEN da.decision = 'approve' THEN 'approved'
    ELSE 'rejected'
  END AS workflow_next_state,
  da.comment,
  da.completed
FROM decided_approval da;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.WorkflowRunID),
		strings.TrimSpace(cmd.StepKey),
		strings.TrimSpace(cmd.ApprovalID),
		strings.TrimSpace(cmd.ApproverRef),
		strings.TrimSpace(cmd.Decision),
		strings.TrimSpace(cmd.Comment),
	)

	var result ApplyManualApprovalResult
	if err := row.Scan(
		&result.WorkflowRunID,
		&result.StepKey,
		&result.ApprovalID,
		&result.ApproverRef,
		&result.Decision,
		&result.ApprovalStatus,
		&result.WorkflowNextState,
		&result.Comment,
		&result.Completed,
	); err != nil {
		return ApplyManualApprovalResult{}, err
	}

	return result, nil
}
