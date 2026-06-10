package realtime

import (
	"context"
	"errors"
	"strings"
)

type OpenSSEConnectionSQLStore struct {
	db QueryRowProvider
}

func NewOpenSSEConnectionSQLStore(db QueryRowProvider) *OpenSSEConnectionSQLStore {
	return &OpenSSEConnectionSQLStore{
		db: db,
	}
}

func (s *OpenSSEConnectionSQLStore) OpenStream(ctx context.Context, cmd OpenSSEConnectionCommand) (OpenSSEConnectionResult, error) {
	if s == nil || s.db == nil {
		return OpenSSEConnectionResult{}, errors.New("sse connection sql store hazir degil")
	}

	const query = `
WITH inserted_stream AS (
  INSERT INTO runtime.realtime_connections (
    tenant_id,
    connection_id,
    channel_name,
    client_id,
    user_ref,
    protocol,
    last_event_id,
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
    NULLIF($7, ''),
    $8,
    NULLIF($9, ''),
    $10,
    $11,
    'streaming',
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
    last_event_id = EXCLUDED.last_event_id,
    remote_addr = EXCLUDED.remote_addr,
    origin = EXCLUDED.origin,
    requested_by = EXCLUDED.requested_by,
    server_node = EXCLUDED.server_node,
    status = 'streaming',
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
    coalesce(last_event_id, '') AS last_event_id,
    server_node,
    status::text AS status,
    accepted,
    coalesce(rejection_reason, '') AS rejection_reason
)
SELECT
  ist.connection_id,
  ist.channel_name,
  ist.client_id,
  ist.user_ref,
  ist.protocol,
  ist.last_event_id,
  ist.server_node,
  ist.status,
  ist.accepted,
  ist.rejection_reason
FROM inserted_stream ist;
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
		strings.TrimSpace(cmd.LastEventID),
		strings.TrimSpace(cmd.RemoteAddr),
		strings.TrimSpace(cmd.Origin),
		strings.TrimSpace(cmd.RequestedBy),
		"local-node",
	)

	var result OpenSSEConnectionResult
	if err := row.Scan(
		&result.ConnectionID,
		&result.ChannelName,
		&result.ClientID,
		&result.UserRef,
		&result.Protocol,
		&result.LastEventID,
		&result.ServerNode,
		&result.Status,
		&result.Accepted,
		&result.RejectionReason,
	); err != nil {
		return OpenSSEConnectionResult{}, err
	}

	return result, nil
}
