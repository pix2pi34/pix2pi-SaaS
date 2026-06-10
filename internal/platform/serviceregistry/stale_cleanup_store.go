package serviceregistry

import (
	"context"
	"errors"
)

func (s *SQLStore) CleanupStaleInstances(ctx context.Context, cmd CleanupStaleInstancesCommand) (CleanupStaleInstancesResult, error) {
	if s == nil || s.db == nil {
		return CleanupStaleInstancesResult{}, errors.New("service registry sql store hazir degil")
	}

	const query = `
WITH target_rows AS (
  SELECT i.id
  FROM runtime.service_registry_instances i
  JOIN runtime.service_registry_services s
    ON s.id = i.service_id
  WHERE (
      (NULLIF($1, '') IS NULL AND i.tenant_id IS NULL)
      OR
      (i.tenant_id::text = NULLIF($1, ''))
    )
    AND i.status <> $2
    AND coalesce(i.last_heartbeat_at, i.created_at) < $3
  ORDER BY coalesce(i.last_heartbeat_at, i.created_at) ASC
  LIMIT $4
),
updated_rows AS (
  UPDATE runtime.service_registry_instances i
  SET
    status = $2,
    retired_at = CASE WHEN $5 THEN i.retired_at ELSE now() END,
    updated_at = CASE WHEN $5 THEN i.updated_at ELSE now() END
  WHERE i.id IN (SELECT id FROM target_rows)
    AND NOT $5
  RETURNING i.id
)
SELECT CASE
  WHEN $5 THEN (SELECT count(*)::int FROM target_rows)
  ELSE (SELECT count(*)::int FROM updated_rows)
END;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		cmd.TenantID,
		cmd.TargetStatus,
		cmd.ThresholdTime,
		cmd.Limit,
		cmd.DryRun,
	)

	var result CleanupStaleInstancesResult
	if err := row.Scan(&result.CleanedCount); err != nil {
		return CleanupStaleInstancesResult{}, err
	}

	return result, nil
}
