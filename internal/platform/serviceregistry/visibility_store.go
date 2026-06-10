package serviceregistry

import (
	"context"
	"errors"
	"strings"
	"time"
)

type RowsScanner interface {
	Next() bool
	Scan(dest ...any) error
	Err() error
	Close() error
}

type QueryRowsProvider interface {
	QueryContext(ctx context.Context, query string, args ...any) (RowsScanner, error)
}

func (s *SQLStore) ListVisibleServiceInstances(ctx context.Context, cmd ListVisibleServicesCommand) ([]VisibleServiceInstance, error) {
	if s == nil || s.db == nil {
		return nil, errors.New("service registry sql store hazir degil")
	}

	rowsProvider, ok := s.db.(QueryRowsProvider)
	if !ok {
		return nil, errors.New("service registry sql rows provider hazir degil")
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
  i.status::text,
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
ORDER BY s.service_key ASC, i.instance_key ASC
LIMIT $5;
`

	rows, err := rowsProvider.QueryContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		cmd.IncludeGlobal,
		strings.TrimSpace(cmd.ServiceKeyPrefix),
		strings.TrimSpace(cmd.InstanceStatus),
		cmd.Limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]VisibleServiceInstance, 0)
	for rows.Next() {
		var item VisibleServiceInstance
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
			&item.InstanceStatus,
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
