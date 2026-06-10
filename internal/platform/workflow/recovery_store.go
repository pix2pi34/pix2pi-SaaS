package workflow

import (
	"context"
	"errors"
	"strings"
)

type ApplyWorkflowRecoverySQLStore struct {
	db QueryRowProvider
}

func NewApplyWorkflowRecoverySQLStore(db QueryRowProvider) *ApplyWorkflowRecoverySQLStore {
	return &ApplyWorkflowRecoverySQLStore{
		db: db,
	}
}

func (s *ApplyWorkflowRecoverySQLStore) ApplyRecovery(ctx context.Context, cmd ApplyWorkflowRecoveryCommand) (ApplyWorkflowRecoveryResult, error) {
	if s == nil || s.db == nil {
		return ApplyWorkflowRecoveryResult{}, errors.New("workflow recovery sql store hazir degil")
	}

	const query = `
WITH updated_step AS (
  UPDATE runtime.workflow_steps ws
  SET
    status = CASE
      WHEN $4 = 'retry' THEN 'pending'
      ELSE 'compensating'
    END,
    compensation_ref = CASE
      WHEN $4 = 'compensate' THEN NULLIF($8, '')
      ELSE ws.compensation_ref
    END,
    lease_expires_at = NULL,
    worker_id = NULL,
    attempt_no = CASE
      WHEN $7 THEN 0
      ELSE coalesce(ws.attempt_no, 0)
    END,
    updated_at = now()
  WHERE ws.run_id = $2
    AND ws.step_key = $3
    AND (
      (NULLIF($1, '') IS NULL AND ws.tenant_id IS NULL)
      OR
      (ws.tenant_id::text = NULLIF($1, ''))
    )
  RETURNING
    ws.run_id,
    ws.step_key,
    ws.status::text AS step_status,
    ws.attempt_no,
    coalesce(ws.compensation_ref, '') AS compensation_ref
),
updated_run AS (
  UPDATE runtime.workflow_runs wr
  SET
    current_state = CASE
      WHEN $4 = 'retry' THEN 'pending'
      ELSE 'failed'
    END,
    updated_at = now()
  WHERE wr.run_id = $2
    AND EXISTS (SELECT 1 FROM updated_step)
  RETURNING
    wr.current_state::text AS workflow_state
)
SELECT
  us.run_id,
  us.step_key,
  $4 AS action_type,
  us.step_status,
  COALESCE(
    (SELECT workflow_state FROM updated_run),
    CASE
      WHEN $4 = 'retry' THEN 'pending'
      ELSE 'failed'
    END
  ) AS workflow_state,
  us.attempt_no,
  us.compensation_ref,
  true AS lease_released
FROM updated_step us;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.WorkflowRunID),
		strings.TrimSpace(cmd.StepKey),
		strings.TrimSpace(cmd.ActionType),
		strings.TrimSpace(cmd.RequestedBy),
		strings.TrimSpace(cmd.Reason),
		cmd.ResetAttempts,
		strings.TrimSpace(cmd.CompensationRef),
	)

	var result ApplyWorkflowRecoveryResult
	if err := row.Scan(
		&result.WorkflowRunID,
		&result.StepKey,
		&result.ActionType,
		&result.StepStatus,
		&result.WorkflowState,
		&result.AttemptNo,
		&result.CompensationRef,
		&result.LeaseReleased,
	); err != nil {
		return ApplyWorkflowRecoveryResult{}, err
	}

	return result, nil
}
