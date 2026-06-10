package missioncontrol

import (
	"context"
	"errors"
	"strings"
	"time"
)

type TimelineSQLStore struct {
	db QueryRowsProvider
}

func NewTimelineSQLStore(db QueryRowsProvider) *TimelineSQLStore {
	return &TimelineSQLStore{
		db: db,
	}
}

func (s *TimelineSQLStore) ListIncidentTimeline(ctx context.Context, cmd ListIncidentTimelineCommand) ([]IncidentTimelineItem, error) {
	if s == nil || s.db == nil {
		return nil, errors.New("incident timeline sql store hazir degil")
	}

	const query = `
WITH action_events AS (
  SELECT
    a.id::text AS event_id,
    a.incident_id::text AS incident_id,
    a.service_id::text AS service_id,
    'action'::text AS event_type,
    a.action_type::text AS action_type,
    a.action_status::text AS action_status,
    ''::text AS incident_status,
    coalesce(a.requested_by, '') AS actor_ref,
    coalesce(a.requested_reason, '') AS message,
    a.requested_at AS occurred_at
  FROM runtime.mission_control_actions a
  WHERE a.incident_id::text = $2
    AND a.service_id::text = $3
    AND (
      (NULLIF($1, '') IS NULL AND a.tenant_id IS NULL)
      OR
      (a.tenant_id::text = NULLIF($1, ''))
    )
    AND $4 = true
),
state_events AS (
  SELECT
    i.id::text || '-state' AS event_id,
    i.id::text AS incident_id,
    i.service_id::text AS service_id,
    'state_change'::text AS event_type,
    ''::text AS action_type,
    ''::text AS action_status,
    i.status::text AS incident_status,
    ''::text AS actor_ref,
    coalesce(i.summary, '') AS message,
    i.updated_at AS occurred_at
  FROM runtime.mission_control_incidents i
  WHERE i.id::text = $2
    AND i.service_id::text = $3
    AND (
      (NULLIF($1, '') IS NULL AND i.tenant_id IS NULL)
      OR
      (i.tenant_id::text = NULLIF($1, ''))
    )
    AND $5 = true
),
note_events AS (
  SELECT
    i.id::text || '-note' AS event_id,
    i.id::text AS incident_id,
    i.service_id::text AS service_id,
    'note'::text AS event_type,
    ''::text AS action_type,
    ''::text AS action_status,
    i.status::text AS incident_status,
    ''::text AS actor_ref,
    coalesce(i.summary, '') AS message,
    i.updated_at AS occurred_at
  FROM runtime.mission_control_incidents i
  WHERE i.id::text = $2
    AND i.service_id::text = $3
    AND (
      (NULLIF($1, '') IS NULL AND i.tenant_id IS NULL)
      OR
      (i.tenant_id::text = NULLIF($1, ''))
    )
    AND $6 = true
),
combined AS (
  SELECT * FROM action_events
  UNION ALL
  SELECT * FROM state_events
  UNION ALL
  SELECT * FROM note_events
)
SELECT
  event_id,
  incident_id,
  service_id,
  event_type,
  action_type,
  action_status,
  incident_status,
  actor_ref,
  message,
  occurred_at
FROM combined
ORDER BY occurred_at DESC
LIMIT $7;
`

	rows, err := s.db.QueryContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.IncidentID),
		strings.TrimSpace(cmd.ServiceID),
		cmd.IncludeActions,
		cmd.IncludeStateChanges,
		cmd.IncludeNotes,
		cmd.Limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]IncidentTimelineItem, 0)
	for rows.Next() {
		var item IncidentTimelineItem
		var occurredAt time.Time

		if err := rows.Scan(
			&item.EventID,
			&item.IncidentID,
			&item.ServiceID,
			&item.EventType,
			&item.ActionType,
			&item.ActionStatus,
			&item.IncidentStatus,
			&item.ActorRef,
			&item.Message,
			&occurredAt,
		); err != nil {
			return nil, err
		}

		item.OccurredAt = occurredAt
		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}
