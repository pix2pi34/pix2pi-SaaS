package jobsqueue

import (
	"context"
	"errors"
	"strings"
)

type ResolveDispatchSQLStore struct {
	db QueryRowProvider
}

func NewResolveDispatchSQLStore(db QueryRowProvider) *ResolveDispatchSQLStore {
	return &ResolveDispatchSQLStore{
		db: db,
	}
}

func (s *ResolveDispatchSQLStore) ResolveDispatchPolicy(ctx context.Context, cmd ResolveDispatchCommand) (ResolveDispatchResult, error) {
	if s == nil || s.db == nil {
		return ResolveDispatchResult{}, errors.New("resolve dispatch sql store hazir degil")
	}

	const query = `
WITH target_job AS (
  SELECT
    j.id,
    j.queue_id,
    q.queue_key,
    coalesce(j.priority::text, '') AS priority
  FROM runtime.jobs j
  JOIN runtime.job_queues q
    ON q.id = j.queue_id
  WHERE j.id::text = $2
    AND q.queue_key = $3
    AND (
      (NULLIF($1, '') IS NULL AND j.tenant_id IS NULL)
      OR
      (j.tenant_id::text = NULLIF($1, ''))
    )
  LIMIT 1
)
SELECT
  CASE
    WHEN NULLIF($1, '') IS NOT NULL AND $4 IN ('high', 'critical')
      THEN tj.queue_key
    ELSE tj.queue_key
  END AS effective_queue_key,
  CASE
    WHEN NULLIF($1, '') IS NOT NULL
      THEN 'tenant-' || replace(NULLIF($1, '')::text, '-', '_') || '-pool'
    WHEN $4 IN ('high', 'critical')
      THEN 'priority-burst'
    ELSE 'shared-default'
  END AS preferred_pool,
  CASE
    WHEN NULLIF($1, '') IS NOT NULL
      THEN 'tenant_pinned'
    WHEN $4 IN ('high', 'critical')
      THEN 'priority_lane'
    ELSE 'shared_pool'
  END AS dispatch_mode,
  CASE
    WHEN NULLIF($1, '') IS NOT NULL THEN true
    ELSE false
  END AS tenant_aware
FROM target_job tj;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.JobID),
		strings.TrimSpace(cmd.QueueKey),
		strings.TrimSpace(cmd.Priority),
	)

	var result ResolveDispatchResult
	if err := row.Scan(
		&result.EffectiveQueueKey,
		&result.PreferredPool,
		&result.DispatchMode,
		&result.TenantAware,
	); err != nil {
		return ResolveDispatchResult{}, err
	}

	return result, nil
}
