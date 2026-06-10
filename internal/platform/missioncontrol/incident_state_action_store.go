package missioncontrol

import (
	"context"
	"errors"
	"strings"
)

type IncidentStateSQLStore struct {
	db QueryRowProvider
}

func NewIncidentStateSQLStore(db QueryRowProvider) *IncidentStateSQLStore {
	return &IncidentStateSQLStore{
		db: db,
	}
}

func (s *IncidentStateSQLStore) RequestIncidentStateAction(ctx context.Context, cmd RequestIncidentStateActionCommand) (RequestIncidentStateActionResult, error) {
	if s == nil || s.db == nil {
		return RequestIncidentStateActionResult{}, errors.New("incident state sql store hazir degil")
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
updated_incident AS (
  UPDATE runtime.mission_control_incidents i
  SET
    status = CASE
      WHEN $4 = 'acknowledge' THEN 'acknowledged'
      WHEN $4 = 'resolve' THEN 'resolved'
      ELSE i.status
    END,
    summary = CASE
      WHEN NULLIF($6, '') IS NULL THEN i.summary
      ELSE i.summary
    END,
    updated_at = now()
  FROM target_incident ti
  WHERE i.id = ti.id
    AND NOT $7
  RETURNING
    i.id,
    i.tenant_id,
    i.service_id,
    i.instance_id,
    i.status::text AS incident_status
),
selected_incident AS (
  SELECT
    ti.id,
    ti.tenant_id,
    ti.service_id,
    ti.instance_id,
    CASE
      WHEN $4 = 'acknowledge' THEN 'acknowledged'
      WHEN $4 = 'resolve' THEN 'resolved'
      ELSE 'open'
    END AS incident_status
  FROM target_incident ti
  WHERE $7
  UNION ALL
  SELECT
    ui.id,
    ui.tenant_id,
    ui.service_id,
    ui.instance_id,
    ui.incident_status
  FROM updated_incident ui
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
    si.tenant_id,
    'ACT_' || upper(replace($4, '-', '_')) || '_' || upper(replace($3, '-', '_')),
    si.id,
    si.service_id,
    si.instance_id,
    $4,
    'requested',
    $5,
    $6,
    now(),
    CASE
      WHEN $7 THEN 'dry-run incident state action requested'
      ELSE ''
    END,
    jsonb_build_object(
      'dry_run', $7,
      'action_type', $4
    )
  FROM selected_incident si
  RETURNING id::text, action_status::text
)
SELECT
  ia.id,
  ia.action_status,
  si.incident_status
FROM inserted_action ia
CROSS JOIN selected_incident si
LIMIT 1;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.IncidentID),
		strings.TrimSpace(cmd.ServiceID),
		strings.TrimSpace(cmd.ActionType),
		strings.TrimSpace(cmd.RequestedBy),
		strings.TrimSpace(cmd.ResponseNote),
		cmd.DryRun,
	)

	var result RequestIncidentStateActionResult
	if err := row.Scan(&result.ActionID, &result.ActionStatus, &result.IncidentStatus); err != nil {
		return RequestIncidentStateActionResult{}, err
	}

	return result, nil
}
