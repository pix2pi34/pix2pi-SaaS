package serviceregistry

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

type SQLStore struct {
	db QueryRowProvider
}

func NewSQLStore(db QueryRowProvider) *SQLStore {
	return &SQLStore{
		db: db,
	}
}

func (s *SQLStore) UpsertServiceInstance(ctx context.Context, cmd UpsertServiceInstanceCommand) (UpsertServiceInstanceResult, error) {
	if s == nil || s.db == nil {
		return UpsertServiceInstanceResult{}, errors.New("service registry sql store hazir degil")
	}

	const query = `
WITH upsert_service AS (
  INSERT INTO runtime.service_registry_services (
    tenant_id,
    business_code,
    service_key,
    display_name,
    service_kind,
    visibility_scope,
    protocol,
    base_path,
    health_path,
    default_port,
    owner_team,
    metadata
  )
  VALUES (
    NULLIF($1, ''),
    'SRV_' || upper(replace($2, '-', '_')),
    $2,
    $3,
    $4,
    $5,
    $6,
    $7,
    $8,
    $9,
    NULLIF($10, ''),
    $11
  )
  ON CONFLICT (
    coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
    service_key
  )
  DO UPDATE SET
    display_name = EXCLUDED.display_name,
    service_kind = EXCLUDED.service_kind,
    visibility_scope = EXCLUDED.visibility_scope,
    protocol = EXCLUDED.protocol,
    base_path = EXCLUDED.base_path,
    health_path = EXCLUDED.health_path,
    default_port = EXCLUDED.default_port,
    owner_team = EXCLUDED.owner_team,
    metadata = EXCLUDED.metadata,
    updated_at = now()
  RETURNING id, service_key
),
upsert_instance AS (
  INSERT INTO runtime.service_registry_instances (
    service_id,
    tenant_id,
    instance_key,
    node_name,
    host,
    port,
    status,
    version,
    heartbeat_interval_seconds,
    metadata,
    last_heartbeat_at,
    last_health_at
  )
  SELECT
    us.id,
    NULLIF($1, ''),
    $12,
    $13,
    $14,
    $15,
    $16,
    NULLIF($17, ''),
    $18,
    $19,
    now(),
    now()
  FROM upsert_service us
  ON CONFLICT (service_id, instance_key)
  DO UPDATE SET
    node_name = EXCLUDED.node_name,
    host = EXCLUDED.host,
    port = EXCLUDED.port,
    status = EXCLUDED.status,
    version = EXCLUDED.version,
    heartbeat_interval_seconds = EXCLUDED.heartbeat_interval_seconds,
    metadata = EXCLUDED.metadata,
    last_heartbeat_at = now(),
    last_health_at = now(),
    updated_at = now()
  RETURNING id, instance_key
)
SELECT
  (SELECT id::text FROM upsert_service),
  (SELECT id::text FROM upsert_instance),
  (SELECT service_key FROM upsert_service),
  (SELECT instance_key FROM upsert_instance);
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.ServiceKey),
		strings.TrimSpace(cmd.DisplayName),
		strings.TrimSpace(cmd.ServiceKind),
		strings.TrimSpace(cmd.VisibilityScope),
		strings.TrimSpace(cmd.Protocol),
		strings.TrimSpace(cmd.BasePath),
		strings.TrimSpace(cmd.HealthPath),
		cmd.DefaultPort,
		strings.TrimSpace(cmd.OwnerTeam),
		cloneMap(cmd.ServiceMetadata),
		strings.TrimSpace(cmd.InstanceKey),
		strings.TrimSpace(cmd.NodeName),
		strings.TrimSpace(cmd.Host),
		cmd.Port,
		strings.TrimSpace(cmd.Status),
		strings.TrimSpace(cmd.Version),
		cmd.HeartbeatIntervalSeconds,
		cloneMap(cmd.InstanceMetadata),
	)

	var result UpsertServiceInstanceResult
	if err := row.Scan(
		&result.ServiceID,
		&result.InstanceID,
		&result.ServiceKey,
		&result.InstanceKey,
	); err != nil {
		return UpsertServiceInstanceResult{}, err
	}

	return result, nil
}

func (s *SQLStore) RecordHeartbeat(ctx context.Context, cmd RecordHeartbeatCommand) (RecordHeartbeatResult, error) {
	if s == nil || s.db == nil {
		return RecordHeartbeatResult{}, errors.New("service registry sql store hazir degil")
	}

	const query = `
WITH target_instance AS (
  SELECT
    i.id,
    i.service_id,
    i.tenant_id,
    i.heartbeat_interval_seconds
  FROM runtime.service_registry_instances i
  JOIN runtime.service_registry_services s
    ON s.id = i.service_id
  WHERE s.service_key = $2
    AND i.instance_key = $3
    AND (
      (NULLIF($1, '') IS NULL AND i.tenant_id IS NULL)
      OR
      (i.tenant_id::text = NULLIF($1, ''))
    )
),
updated_instance AS (
  UPDATE runtime.service_registry_instances i
  SET
    status = $4,
    heartbeat_interval_seconds = $5,
    metadata = $6,
    last_heartbeat_at = now(),
    last_health_at = now(),
    updated_at = now()
  FROM target_instance ti
  WHERE i.id = ti.id
  RETURNING
    i.id,
    ti.service_id,
    ti.tenant_id,
    i.heartbeat_interval_seconds
),
inserted_heartbeat AS (
  INSERT INTO runtime.service_registry_heartbeats (
    service_id,
    instance_id,
    tenant_id,
    status,
    response_time_ms,
    detail
  )
  SELECT
    ui.service_id,
    ui.id,
    ui.tenant_id,
    $4,
    $7,
    $6
  FROM updated_instance ui
  RETURNING id
)
SELECT
  coalesce((SELECT heartbeat_interval_seconds FROM updated_instance), $5),
  CASE
    WHEN $4 IN ('degraded', 'unhealthy', 'draining') THEN true
    WHEN $7 >= 5000 THEN true
    ELSE false
  END;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.ServiceKey),
		strings.TrimSpace(cmd.InstanceKey),
		strings.TrimSpace(cmd.Status),
		cmd.HeartbeatIntervalSeconds,
		cloneMap(cmd.Metadata),
		cmd.ResponseTimeMS,
	)

	var result RecordHeartbeatResult
	if err := row.Scan(
		&result.NextHeartbeatInSeconds,
		&result.HealthPullRequested,
	); err != nil {
		return RecordHeartbeatResult{}, err
	}

	return result, nil
}
