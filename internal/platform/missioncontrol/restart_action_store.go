package missioncontrol

import (
	"context"
	"errors"
	"strings"
)

type RowScanner interface {
	Scan(dest ...any) error
}

type QueryRowProvider interface {
	QueryRowContext(ctx context.Context, query string, args ...any) RowScanner
}

type RestartSQLStore struct {
	db QueryRowProvider
}

func NewRestartSQLStore(db QueryRowProvider) *RestartSQLStore {
	return &RestartSQLStore{
		db: db,
	}
}

func (s *RestartSQLStore) RequestRestartAction(ctx context.Context, cmd RequestRestartActionCommand) (RequestRestartActionResult, error) {
	if s == nil || s.db == nil {
		return RequestRestartActionResult{}, errors.New("restart sql store hazir degil")
	}

	const query = `
WITH target_incident AS (
  SELECT
    i.id,
    i.tenant_id,
    i.service_id,
    i.instance_id
  FROM runtime.mission_control_incidents i
  WHERE i.id::text = $2
    AND i.service_id::text = $3
    AND (
      (NULLIF($1, '') IS NULL AND i.tenant_id IS NULL)
      OR
      (i.tenant_id::text = NULLIF($1, ''))
    )
),
inserted_action AS (
  INSERT INTO runtime.mission_control_actions (
    tenant_id,
    business_code,
    incident_id,
    service_id,
    instance_id,
    action_type,
    action_status,
    requested_by,
    requested_reason,
    requested_at,
    result_message,
    metadata
  )
  SELECT
    ti.tenant_id,
    'ACT_RESTART_' || upper(replace($3, '-', '_')),
    ti.id,
    ti.service_id,
    CASE
      WHEN NULLIF($4, '') IS NULL THEN ti.instance_id
      ELSE NULLIF($4, '')::uuid
    END,
    'restart',
    'requested',
    $5,
    $6,
    now(),
    CASE
      WHEN $7 THEN 'dry-run restart requested'
      ELSE ''
    END,
    jsonb_build_object('dry_run', $7)
  FROM target_incident ti
  RETURNING id::text, action_status::text
)
SELECT id, action_status
FROM inserted_action;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.IncidentID),
		strings.TrimSpace(cmd.ServiceID),
		strings.TrimSpace(cmd.InstanceID),
		strings.TrimSpace(cmd.RequestedBy),
		strings.TrimSpace(cmd.RequestedReason),
		cmd.DryRun,
	)

	var result RequestRestartActionResult
	if err := row.Scan(&result.ActionID, &result.ActionStatus); err != nil {
		return RequestRestartActionResult{}, err
	}

	return result, nil
}
