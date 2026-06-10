package missioncontrol

import (
	"context"
	"errors"
	"strings"
	"time"
)

type SQLStore struct {
	db QueryRowsProvider
}

func NewSQLStore(db QueryRowsProvider) *SQLStore {
	return &SQLStore{
		db: db,
	}
}

func (s *SQLStore) ListRuntimeStatusCards(ctx context.Context, req StatusPanelRequest) ([]ServiceStatusCard, error) {
	if s == nil || s.db == nil {
		return nil, errors.New("mission control sql store hazir degil")
	}

	const query = `
SELECT
  s.id::text AS service_id,
  i.id::text AS instance_id,
  coalesce(i.tenant_id::text, '') AS tenant_id,
  s.service_key,
  s.display_name,
  s.service_kind::text,
  s.visibility_scope::text,
  i.instance_key,
  i.status::text AS runtime_status,
  i.host,
  i.port,
  coalesce(i.version, '') AS version,
  coalesce(i.last_heartbeat_at, i.created_at) AS last_heartbeat_at
FROM runtime.service_registry_services s
JOIN runtime.service_registry_instances i
  ON i.service_id = s.id
WHERE (
    (
      NULLIF($1, '') IS NOT NULL
      AND i.tenant_id::text = NULLIF($1, '')
    )
    OR
    (
      $2 = true
      AND s.visibility_scope = 'global'
    )
  )
  AND ($3 = '' OR s.service_key LIKE $3 || '%')
  AND ($4 = '' OR i.status::text = $4)
ORDER BY i.status::text ASC, s.service_key ASC, i.instance_key ASC
LIMIT $5;
`

	rows, err := s.db.QueryContext(
		ctx,
		query,
		strings.TrimSpace(req.TenantID),
		req.IncludeGlobal,
		strings.TrimSpace(req.ServiceKeyLike),
		strings.TrimSpace(req.StatusFilter),
		req.Limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]ServiceStatusCard, 0)
	for rows.Next() {
		var item ServiceStatusCard
		var lastHeartbeatAt time.Time

		if err := rows.Scan(
			&item.ServiceID,
			&item.InstanceID,
			&item.TenantID,
			&item.ServiceKey,
			&item.DisplayName,
			&item.ServiceKind,
			&item.VisibilityScope,
			&item.InstanceKey,
			&item.RuntimeStatus,
			&item.Host,
			&item.Port,
			&item.Version,
			&lastHeartbeatAt,
		); err != nil {
			return nil, err
		}

		item.LastHeartbeatAt = lastHeartbeatAt
		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}
