package publicapi

import (
	"context"
	"errors"
	"strings"
)

type ResolvePublicAPIGatewaySQLStore struct {
	db QueryRowProvider
}

func NewResolvePublicAPIGatewaySQLStore(db QueryRowProvider) *ResolvePublicAPIGatewaySQLStore {
	return &ResolvePublicAPIGatewaySQLStore{
		db: db,
	}
}

func (s *ResolvePublicAPIGatewaySQLStore) ResolveRoute(ctx context.Context, cmd ResolvePublicAPIGatewayCommand) (ResolvePublicAPIGatewayResult, error) {
	if s == nil || s.db == nil {
		return ResolvePublicAPIGatewayResult{}, errors.New("public api gateway sql store hazir degil")
	}

	const query = `
WITH route_match AS (
  SELECT
    par.target_service,
    par.target_path_prefix,
    par.gateway_status,
    par.allowed,
    coalesce(par.rejection_reason, '') AS rejection_reason
  FROM runtime.public_api_routes par
  WHERE par.method = $5
    AND $6 LIKE par.path_prefix || '%'
    AND par.is_active = true
    AND (
      (NULLIF($1, '') IS NULL AND par.tenant_id IS NULL)
      OR
      (par.tenant_id::text = NULLIF($1, ''))
    )
  ORDER BY length(par.path_prefix) DESC, par.updated_at DESC
  LIMIT 1
),
request_log AS (
  INSERT INTO runtime.public_api_gateway_requests (
    tenant_id,
    request_id,
    app_id,
    api_key_id,
    method,
    path,
    origin,
    requested_by,
    target_service,
    target_path,
    gateway_status,
    accepted,
    rejection_reason,
    created_at,
    updated_at
  )
  SELECT
    NULLIF($1, ''),
    $2,
    $3,
    $4,
    $5,
    $6,
    NULLIF($7, ''),
    $8,
    COALESCE((SELECT target_service FROM route_match), ''),
    COALESCE((SELECT target_path_prefix FROM route_match), $6),
    COALESCE((SELECT gateway_status FROM route_match), 'accepted'),
    COALESCE((SELECT allowed FROM route_match), true),
    COALESCE((SELECT rejection_reason FROM route_match), ''),
    now(),
    now()
  RETURNING
    request_id,
    app_id,
    api_key_id,
    method,
    path,
    target_service,
    target_path,
    gateway_status::text AS gateway_status,
    accepted,
    rejection_reason
)
SELECT
  rl.request_id,
  rl.app_id,
  rl.api_key_id,
  rl.method,
  rl.path,
  rl.target_service,
  rl.target_path,
  rl.gateway_status,
  rl.accepted,
  rl.rejection_reason
FROM request_log rl;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.RequestID),
		strings.TrimSpace(cmd.AppID),
		strings.TrimSpace(cmd.APIKeyID),
		strings.ToUpper(strings.TrimSpace(cmd.Method)),
		normalizePublicAPIPath(cmd.Path),
		strings.TrimSpace(cmd.Origin),
		strings.TrimSpace(cmd.RequestedBy),
	)

	var result ResolvePublicAPIGatewayResult
	if err := row.Scan(
		&result.RequestID,
		&result.AppID,
		&result.APIKeyID,
		&result.Method,
		&result.Path,
		&result.TargetService,
		&result.TargetPath,
		&result.GatewayStatus,
		&result.Accepted,
		&result.RejectionReason,
	); err != nil {
		return ResolvePublicAPIGatewayResult{}, err
	}

	return result, nil
}
