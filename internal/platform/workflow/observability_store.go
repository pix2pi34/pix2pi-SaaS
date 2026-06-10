package workflow

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
)

type LoadWorkflowObservabilitySQLStore struct {
	db QueryRowProvider
}

func NewLoadWorkflowObservabilitySQLStore(db QueryRowProvider) *LoadWorkflowObservabilitySQLStore {
	return &LoadWorkflowObservabilitySQLStore{
		db: db,
	}
}

func (s *LoadWorkflowObservabilitySQLStore) LoadObservability(ctx context.Context, cmd LoadWorkflowObservabilityCommand) (LoadWorkflowObservabilityResult, error) {
	if s == nil || s.db == nil {
		return LoadWorkflowObservabilityResult{}, errors.New("workflow observability sql store hazir degil")
	}

	const query = `
WITH step_rows AS (
  SELECT
    ws.step_key,
    ws.step_type::text AS step_type,
    ws.status::text AS status,
    coalesce(ws.attempt_no, 0) AS attempt_no,
    coalesce(ws.worker_id, '') AS worker_id,
    ws.lease_expires_at,
    coalesce(ws.error_code, '') AS last_error_code
  FROM runtime.workflow_steps ws
  WHERE ws.run_id = $2
    AND (
      (NULLIF($1, '') IS NULL AND ws.tenant_id IS NULL)
      OR
      (ws.tenant_id::text = NULLIF($1, ''))
    )
),
approval_summary AS (
  SELECT
    count(*) FILTER (WHERE wa.approval_status = 'pending')::int AS pending_approvals
  FROM runtime.workflow_approvals wa
  WHERE wa.run_id = $2
    AND (
      (NULLIF($1, '') IS NULL AND wa.tenant_id IS NULL)
      OR
      (wa.tenant_id::text = NULLIF($1, ''))
    )
),
step_summary AS (
  SELECT
    count(*)::int AS total_steps,
    count(*) FILTER (WHERE sr.status IN ('pending', 'retry_pending'))::int AS pending_steps,
    count(*) FILTER (WHERE sr.status = 'in_progress')::int AS in_progress_steps,
    count(*) FILTER (WHERE sr.status = 'completed')::int AS completed_steps,
    count(*) FILTER (WHERE sr.status = 'failed')::int AS failed_steps,
    count(*) FILTER (
      WHERE sr.lease_expires_at IS NOT NULL
        AND sr.lease_expires_at > now()
    )::int AS active_lease_count,
    count(*) FILTER (
      WHERE sr.lease_expires_at IS NOT NULL
        AND sr.lease_expires_at <= now()
    )::int AS expired_lease_count
  FROM step_rows sr
)
SELECT
  wr.run_id,
  wr.definition_key,
  wr.current_state::text AS workflow_state,
  ss.total_steps,
  ss.pending_steps,
  ss.in_progress_steps,
  ss.completed_steps,
  ss.failed_steps,
  coalesce((SELECT pending_approvals FROM approval_summary), 0) AS pending_approvals,
  ss.active_lease_count,
  ss.expired_lease_count,
  COALESCE((
    SELECT json_agg(
      json_build_object(
        'step_key', sr.step_key,
        'step_type', sr.step_type,
        'status', sr.status,
        'attempt_no', sr.attempt_no,
        'worker_id', sr.worker_id,
        'lease_expires_at', sr.lease_expires_at,
        'last_error_code', sr.last_error_code
      )
    )::text
    FROM step_rows sr
  ), '[]') AS steps_json
FROM runtime.workflow_runs wr
CROSS JOIN step_summary ss
WHERE wr.run_id = $2
  AND (
    (NULLIF($1, '') IS NULL AND wr.tenant_id IS NULL)
    OR
    (wr.tenant_id::text = NULLIF($1, ''))
  )
LIMIT 1;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.WorkflowRunID),
	)

	var result LoadWorkflowObservabilityResult
	var stepsJSON string

	if err := row.Scan(
		&result.WorkflowRunID,
		&result.DefinitionKey,
		&result.WorkflowState,
		&result.Summary.TotalSteps,
		&result.Summary.PendingSteps,
		&result.Summary.InProgressSteps,
		&result.Summary.CompletedSteps,
		&result.Summary.FailedSteps,
		&result.Summary.PendingApprovals,
		&result.Summary.ActiveLeaseCount,
		&result.Summary.ExpiredLeaseCount,
		&stepsJSON,
	); err != nil {
		return LoadWorkflowObservabilityResult{}, err
	}

	result.Steps = []WorkflowStepObservation{}
	if strings.TrimSpace(stepsJSON) != "" {
		if err := json.Unmarshal([]byte(stepsJSON), &result.Steps); err != nil {
			return LoadWorkflowObservabilityResult{}, err
		}
	}

	return result, nil
}
