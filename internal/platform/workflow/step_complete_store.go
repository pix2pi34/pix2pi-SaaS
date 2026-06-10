package workflow

import (
	"context"
	"errors"
	"strings"
)

type CompleteWorkflowStepSQLStore struct {
	db QueryRowProvider
}

func NewCompleteWorkflowStepSQLStore(db QueryRowProvider) *CompleteWorkflowStepSQLStore {
	return &CompleteWorkflowStepSQLStore{
		db: db,
	}
}

func (s *CompleteWorkflowStepSQLStore) CompleteStep(ctx context.Context, cmd CompleteWorkflowStepCommand) (CompleteWorkflowStepResult, error) {
	if s == nil || s.db == nil {
		return CompleteWorkflowStepResult{}, errors.New("workflow step complete sql store hazir degil")
	}

	const query = `
WITH updated_step AS (
  UPDATE runtime.workflow_steps ws
  SET
    status = $5,
    output_ref = NULLIF($7, ''),
    error_code = NULLIF($8, ''),
    completion_note = NULLIF($9, ''),
    lease_expires_at = NULL,
    updated_at = now()
  WHERE ws.run_id = $2
    AND ws.step_key = $3
    AND coalesce(ws.worker_id, '') = $4
    AND coalesce(ws.attempt_no, 0) = $6
    AND (
      (NULLIF($1, '') IS NULL AND ws.tenant_id IS NULL)
      OR
      (ws.tenant_id::text = NULLIF($1, ''))
    )
  RETURNING
    ws.run_id,
    ws.step_key,
    ws.status::text AS status,
    ws.attempt_no,
    coalesce(ws.output_ref, '') AS output_ref,
    coalesce(ws.error_code, '') AS error_code,
    coalesce(ws.completion_note, '') AS completion_note
)
SELECT
  us.run_id,
  us.step_key,
  us.status,
  us.attempt_no,
  us.output_ref,
  us.error_code,
  us.completion_note,
  true AS lease_released
FROM updated_step us;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.WorkflowRunID),
		strings.TrimSpace(cmd.StepKey),
		strings.TrimSpace(cmd.WorkerID),
		strings.TrimSpace(cmd.Status),
		cmd.AttemptNo,
		strings.TrimSpace(cmd.OutputRef),
		strings.TrimSpace(cmd.ErrorCode),
		strings.TrimSpace(cmd.CompletionNote),
	)

	var result CompleteWorkflowStepResult
	if err := row.Scan(
		&result.WorkflowRunID,
		&result.StepKey,
		&result.Status,
		&result.AttemptNo,
		&result.OutputRef,
		&result.ErrorCode,
		&result.CompletionNote,
		&result.LeaseReleased,
	); err != nil {
		return CompleteWorkflowStepResult{}, err
	}

	return result, nil
}
