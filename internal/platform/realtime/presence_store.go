package realtime

import (
	"context"
	"database/sql"
	"errors"
	"strings"
)

type ApplyRealtimePresenceSQLStore struct {
	db QueryRowProvider
}

func NewApplyRealtimePresenceSQLStore(db QueryRowProvider) *ApplyRealtimePresenceSQLStore {
	return &ApplyRealtimePresenceSQLStore{
		db: db,
	}
}

func (s *ApplyRealtimePresenceSQLStore) ApplyPresence(ctx context.Context, cmd ApplyRealtimePresenceCommand) (ApplyRealtimePresenceResult, error) {
	if s == nil || s.db == nil {
		return ApplyRealtimePresenceResult{}, errors.New("realtime presence sql store hazir degil")
	}

	const query = `
WITH updated_presence AS (
  UPDATE runtime.realtime_connections rc
  SET
    presence_status = CASE
      WHEN $6 = 'heartbeat' THEN 'online'
      WHEN $6 = 'disconnect' THEN 'offline'
      WHEN $6 = 'expire' THEN 'expired'
      ELSE rc.presence_status
    END,
    connection_closed = CASE
      WHEN $6 IN ('disconnect', 'expire') THEN true
      ELSE false
    END,
    last_seen_at = now(),
    closed_at = CASE
      WHEN $6 IN ('disconnect', 'expire') THEN now()
      ELSE NULL
    END,
    updated_at = now()
  WHERE rc.connection_id = $2
    AND rc.channel_name = $3
    AND rc.client_id = $4
    AND rc.user_ref = $5
    AND (
      rc.tenant_id::text = $1
    )
  RETURNING
    rc.tenant_id::text AS tenant_id,
    rc.connection_id,
    rc.channel_name,
    rc.client_id,
    rc.user_ref,
    $6 AS action_type,
    rc.presence_status::text AS presence_status,
    rc.connection_closed,
    rc.server_node,
    rc.last_seen_at,
    rc.closed_at,
    true AS applied
)
SELECT
  up.tenant_id,
  up.connection_id,
  up.channel_name,
  up.client_id,
  up.user_ref,
  up.action_type,
  up.presence_status,
  up.connection_closed,
  up.server_node,
  up.last_seen_at,
  up.closed_at,
  up.applied
FROM updated_presence up;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.ConnectionID),
		strings.TrimSpace(cmd.ChannelName),
		strings.TrimSpace(cmd.ClientID),
		strings.TrimSpace(cmd.UserRef),
		strings.TrimSpace(cmd.ActionType),
		strings.TrimSpace(cmd.ServerNode),
		strings.TrimSpace(cmd.RequestedBy),
	)

	var result ApplyRealtimePresenceResult
	var closedAt sql.NullTime

	if err := row.Scan(
		&result.TenantID,
		&result.ConnectionID,
		&result.ChannelName,
		&result.ClientID,
		&result.UserRef,
		&result.ActionType,
		&result.PresenceStatus,
		&result.ConnectionClosed,
		&result.ServerNode,
		&result.LastSeenAt,
		&closedAt,
		&result.Applied,
	); err != nil {
		return ApplyRealtimePresenceResult{}, err
	}

	result.LastSeenAt = result.LastSeenAt.UTC()

	if closedAt.Valid {
		t := closedAt.Time.UTC()
		result.ClosedAt = &t
	}

	return result, nil
}
