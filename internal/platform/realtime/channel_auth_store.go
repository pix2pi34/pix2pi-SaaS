package realtime

import (
	"context"
	"errors"
	"strings"
)

type AuthorizeRealtimeChannelSQLStore struct {
	db QueryRowProvider
}

func NewAuthorizeRealtimeChannelSQLStore(db QueryRowProvider) *AuthorizeRealtimeChannelSQLStore {
	return &AuthorizeRealtimeChannelSQLStore{
		db: db,
	}
}

func (s *AuthorizeRealtimeChannelSQLStore) AuthorizeChannel(ctx context.Context, cmd AuthorizeRealtimeChannelCommand) (AuthorizeRealtimeChannelResult, error) {
	if s == nil || s.db == nil {
		return AuthorizeRealtimeChannelResult{}, errors.New("realtime channel auth sql store hazir degil")
	}

	const query = `
WITH request_context AS (
  SELECT
    $1::text AS tenant_id,
    $2::text AS connection_id,
    $3::text AS channel_name,
    $4::text AS client_id,
    $5::text AS user_ref,
    $6::text AS operation,
    $7::text AS requested_by
),
matched_rule AS (
  SELECT
    rcp.channel_scope,
    rcp.auth_status,
    rcp.access_granted,
    coalesce(rcp.denial_reason, '') AS denial_reason
  FROM runtime.realtime_channel_permissions rcp
  WHERE rcp.channel_name = $3
    AND rcp.operation = $6
    AND (
      (NULLIF($1, '') IS NULL AND rcp.tenant_id IS NULL)
      OR
      (rcp.tenant_id::text = NULLIF($1, ''))
    )
  ORDER BY rcp.updated_at DESC
  LIMIT 1
)
SELECT
  rc.tenant_id,
  rc.connection_id,
  rc.channel_name,
  rc.client_id,
  rc.user_ref,
  rc.operation,
  COALESCE(
    (SELECT channel_scope FROM matched_rule),
    CASE
      WHEN rc.channel_name LIKE 'platform.%' THEN 'platform'
      ELSE 'tenant'
    END
  ) AS channel_scope,
  COALESCE(
    (SELECT auth_status FROM matched_rule),
    CASE
      WHEN rc.channel_name LIKE 'tenant.%' THEN 'granted'
      ELSE 'denied'
    END
  ) AS auth_status,
  COALESCE(
    (SELECT access_granted FROM matched_rule),
    CASE
      WHEN rc.channel_name LIKE 'tenant.%' THEN true
      ELSE false
    END
  ) AS access_granted,
  COALESCE(
    (SELECT denial_reason FROM matched_rule),
    CASE
      WHEN rc.channel_name LIKE 'tenant.%' THEN ''
      WHEN rc.channel_name LIKE 'platform.%' THEN 'platform kanali tenant runtime icin kapali'
      ELSE 'kanal tenant guvenlik kuralina uymuyor'
    END
  ) AS denial_reason
FROM request_context rc;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.ConnectionID),
		strings.TrimSpace(cmd.ChannelName),
		strings.TrimSpace(cmd.ClientID),
		strings.TrimSpace(cmd.UserRef),
		strings.TrimSpace(cmd.Operation),
		strings.TrimSpace(cmd.RequestedBy),
	)

	var result AuthorizeRealtimeChannelResult
	if err := row.Scan(
		&result.TenantID,
		&result.ConnectionID,
		&result.ChannelName,
		&result.ClientID,
		&result.UserRef,
		&result.Operation,
		&result.ChannelScope,
		&result.AuthStatus,
		&result.AccessGranted,
		&result.DenialReason,
	); err != nil {
		return AuthorizeRealtimeChannelResult{}, err
	}

	return result, nil
}
