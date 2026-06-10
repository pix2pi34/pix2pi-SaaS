package realtime

import (
	"context"
	"errors"
	"strings"
)

type OpenWebSocketConnectionSQLStore struct {
	db QueryRowProvider
}

func NewOpenWebSocketConnectionSQLStore(db QueryRowProvider) *OpenWebSocketConnectionSQLStore {
	return &OpenWebSocketConnectionSQLStore{
		db: db,
	}
}

func (s *OpenWebSocketConnectionSQLStore) OpenConnection(ctx context.Context, cmd OpenWebSocketConnectionCommand) (OpenWebSocketConnectionResult, error) {
	if s == nil || s.db == nil {
		return OpenWebSocketConnectionResult{}, errors.New("websocket connection sql store hazir degil")
	}

	const query = `
WITH inserted_connection AS (
  INSERT INTO runtime.realtime_connections (
    tenant_id,
    connection_id,
    channel_name,
    client_id,
    user_ref,
    protocol,
    remote_addr,
    origin,
    requested_by,
    server_node,
    status,
    accepted,
    rejection_reason,
    connected_at,
    last_seen_at,
    created_at,
    updated_at
  )
  VALUES (
    NULLIF($1, ''),
    $2,
    $3,
    $4,
    $5,
    $6,
    $7,
    NULLIF($8, ''),
    $9,
    $10,
    'connected',
    true,
    '',
    now(),
    now(),
    now(),
    now()
  )
  ON CONFLICT (connection_id)
  DO UPDATE SET
    tenant_id = EXCLUDED.tenant_id,
    channel_name = EXCLUDED.channel_name,
    client_id = EXCLUDED.client_id,
    user_ref = EXCLUDED.user_ref,
    protocol = EXCLUDED.protocol,
    remote_addr = EXCLUDED.remote_addr,
    origin = EXCLUDED.origin,
    requested_by = EXCLUDED.requested_by,
    server_node = EXCLUDED.server_node,
    status = 'connected',
    accepted = true,
    rejection_reason = '',
    connected_at = now(),
    last_seen_at = now(),
    updated_at = now()
  RETURNING
    connection_id,
    channel_name,
    client_id,
    user_ref,
    protocol,
    server_node,
    status::text AS status,
    accepted,
    coalesce(rejection_reason, '') AS rejection_reason
)
SELECT
  ic.connection_id,
  ic.channel_name,
  ic.client_id,
  ic.user_ref,
  ic.protocol,
  ic.server_node,
  ic.status,
  ic.accepted,
  ic.rejection_reason
FROM inserted_connection ic;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.ConnectionID),
		strings.TrimSpace(cmd.ChannelName),
		strings.TrimSpace(cmd.ClientID),
		strings.TrimSpace(cmd.UserRef),
		strings.TrimSpace(cmd.Protocol),
		strings.TrimSpace(cmd.RemoteAddr),
		strings.TrimSpace(cmd.Origin),
		strings.TrimSpace(cmd.RequestedBy),
		"local-node",
	)

	var result OpenWebSocketConnectionResult
	if err := row.Scan(
		&result.ConnectionID,
		&result.ChannelName,
		&result.ClientID,
		&result.UserRef,
		&result.Protocol,
		&result.ServerNode,
		&result.Status,
		&result.Accepted,
		&result.RejectionReason,
	); err != nil {
		return OpenWebSocketConnectionResult{}, err
	}

	return result, nil
}
