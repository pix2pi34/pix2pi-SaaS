package workflow

import (
	"context"
	"errors"
	"strings"
)

type ApplyWorkflowTransitionSQLStore struct {
	db QueryRowProvider
}

func NewApplyWorkflowTransitionSQLStore(db QueryRowProvider) *ApplyWorkflowTransitionSQLStore {
	return &ApplyWorkflowTransitionSQLStore{
		db: db,
	}
}

func (s *ApplyWorkflowTransitionSQLStore) ApplyTransition(ctx context.Context, cmd ApplyWorkflowTransitionCommand) (ApplyWorkflowTransitionResult, error) {
	if s == nil || s.db == nil {
		return ApplyWorkflowTransitionResult{}, errors.New("workflow state machine sql store hazir degil")
	}

	const query = `
WITH transition_rules AS (
  SELECT
    CASE
      WHEN $4 = 'draft' AND $5 = 'submit' THEN 'pending'
      WHEN $4 = 'pending' AND $5 = 'start' THEN 'in_progress'
      WHEN $4 = 'in_progress' AND $5 = 'request_approval' THEN 'waiting_approval'
      WHEN $4 = 'waiting_approval' AND $5 = 'approve' THEN 'approved'
      WHEN $4 = 'waiting_approval' AND $5 = 'reject' THEN 'rejected'
      WHEN $4 = 'approved' AND $5 = 'complete' THEN 'completed'
      WHEN $4 = 'in_progress' AND $5 = 'fail' THEN 'failed'
      WHEN $4 IN ('pending', 'in_progress', 'waiting_approval') AND $5 = 'cancel' THEN 'cancelled'
      WHEN $4 = 'failed' AND $5 = 'retry' THEN 'pending'
      ELSE ''
    END AS next_state
),
updated_workflow AS (
  UPDATE runtime.workflow_runs w
  SET
    current_state = tr.next_state,
    requested_by = $6,
    context_vars = $7,
    updated_at = now()
  FROM transition_rules tr
  WHERE w.run_id = $2
    AND w.definition_key = $3
    AND w.current_state = $4
    AND tr.next_state <> ''
    AND (
      (NULLIF($1, '') IS NULL AND w.tenant_id IS NULL)
      OR
      (w.tenant_id::text = NULLIF($1, ''))
    )
  RETURNING
    w.run_id,
    w.definition_key,
    $4 AS previous_state,
    $5 AS action,
    w.current_state AS next_state,
    true AS transition_allowed,
    '' AS reason
)
SELECT
  COALESCE(
    (SELECT run_id FROM updated_workflow),
    $2
  ) AS workflow_run_id,
  COALESCE(
    (SELECT definition_key FROM updated_workflow),
    $3
  ) AS definition_key,
  COALESCE(
    (SELECT previous_state FROM updated_workflow),
    $4
  ) AS previous_state,
  COALESCE(
    (SELECT action FROM updated_workflow),
    $5
  ) AS action,
  COALESCE(
    (SELECT next_state FROM updated_workflow),
    ''
  ) AS next_state,
  COALESCE(
    (SELECT transition_allowed FROM updated_workflow),
    false
  ) AS transition_allowed,
  CASE
    WHEN EXISTS (SELECT 1 FROM updated_workflow) THEN ''
    ELSE 'transition not allowed'
  END AS reason;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.WorkflowRunID),
		strings.TrimSpace(cmd.DefinitionKey),
		strings.TrimSpace(cmd.CurrentState),
		strings.TrimSpace(cmd.Action),
		strings.TrimSpace(cmd.RequestedBy),
		cloneMap(cmd.ContextVars),
	)

	var result ApplyWorkflowTransitionResult
	if err := row.Scan(
		&result.WorkflowRunID,
		&result.DefinitionKey,
		&result.PreviousState,
		&result.Action,
		&result.NextState,
		&result.TransitionAllowed,
		&result.Reason,
	); err != nil {
		return ApplyWorkflowTransitionResult{}, err
	}

	return result, nil
}
