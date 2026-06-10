package workflow

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ClaimWorkflowStepSQLStore struct {
	db QueryRowProvider
}

func NewClaimWorkflowStepSQLStore(db QueryRowProvider) *ClaimWorkflowStepSQLStore {
	return &ClaimWorkflowStepSQLStore{
		db: db,
	}
}

func (s *ClaimWorkflowStepSQLStore) ClaimStep(ctx context.Context, cmd ClaimWorkflowStepCommand) (ClaimWorkflowStepResult, error) {
	if s == nil || s.db == nil {
		return ClaimWorkflowStepResult{}, errors.New("workflow step claim sql store hazir degil")
	}

	const query = `
WITH updated_step AS (
  UPDATE runtime.workflow_steps ws
  SET
    status = 'in_progress',
    worker_id = $4,
    lease_expires_at = now() + make_interval(secs => $5),
    attempt_no = coalesce(ws.attempt_no, 0) + 1,
    updated_at = now()
  WHERE ws.run_id = $2
    AND ws.step_key = $3
    AND ws.status IN ('pending', 'retry_pending')
    AND (
      (NULLIF($1, '') IS NULL AND ws.tenant_id IS NULL)
      OR
      (ws.tenant_id::text = NULLIF($1, ''))
    )
  RETURNING
    ws.run_id,
    ws.step_key,
    ws.step_type::text AS step_type,
    ws.status::text AS status,
    ws.attempt_no,
    ws.lease_expires_at
)
SELECT
  us.run_id,
  us.step_key,
  us.step_type,
  us.status,
  us.attempt_no,
  us.lease_expires_at
FROM updated_step us;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.WorkflowRunID),
		strings.TrimSpace(cmd.StepKey),
		strings.TrimSpace(cmd.WorkerID),
		cmd.LeaseSeconds,
	)

	var result ClaimWorkflowStepResult
	var leaseExpiresAt time.Time

	if err := row.Scan(
		&result.WorkflowRunID,
		&result.StepKey,
		&result.StepType,
		&result.Status,
		&result.AttemptNo,
		&leaseExpiresAt,
	); err != nil {
		return ClaimWorkflowStepResult{}, err
	}

	result.Claimed = true
	result.LeaseExpiresAt = &leaseExpiresAt

	return result, nil
}
