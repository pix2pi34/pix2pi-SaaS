package jobsqueue

import (
	"context"
	"errors"
	"strings"
)

type EnqueueSQLStore struct {
	db QueryRowProvider
}

func NewEnqueueSQLStore(db QueryRowProvider) *EnqueueSQLStore {
	return &EnqueueSQLStore{
		db: db,
	}
}

func (s *EnqueueSQLStore) EnqueueJob(ctx context.Context, cmd EnqueueJobCommand) (EnqueueJobResult, error) {
	if s == nil || s.db == nil {
		return EnqueueJobResult{}, errors.New("enqueue sql store hazir degil")
	}

	const query = `
WITH upsert_queue AS (
  INSERT INTO runtime.job_queues (
    tenant_id,
    business_code,
    queue_key,
    display_name,
    visibility_scope,
    is_enabled,
    metadata
  )
  VALUES (
    NULLIF($1, '')::uuid,
    'JQ_' || upper(replace($2, '-', '_')),
    $2,
    $2,
    CASE
      WHEN NULLIF($1, '') IS NULL THEN 'global'
      ELSE 'tenant'
    END,
    true,
    '{}'::jsonb
  )
  ON CONFLICT (
    coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
    queue_key
  )
  DO UPDATE SET
    updated_at = now()
  RETURNING id
),
dedup_match AS (
  SELECT
    j.id::text AS job_id,
    j.status::text AS status
  FROM runtime.jobs j
  JOIN upsert_queue q
    ON q.id = j.queue_id
  WHERE NULLIF($5, '') IS NOT NULL
    AND j.dedup_key = NULLIF($5, '')
  ORDER BY j.created_at DESC
  LIMIT 1
),
inserted_job AS (
  INSERT INTO runtime.jobs (
    tenant_id,
    queue_id,
    business_code,
    job_key,
    job_type,
    priority,
    status,
    dedup_key,
    payload,
    scheduled_at,
    requested_by,
    max_attempts
  )
  SELECT
    NULLIF($1, '')::uuid,
    q.id,
    'JOB_' || upper(replace($3, '-', '_')),
    $3,
    $4,
    $6,
    CASE
      WHEN $8 IS NULL THEN 'queued'
      ELSE 'scheduled'
    END,
    NULLIF($5, ''),
    $7,
    $8,
    $9,
    $10
  FROM upsert_queue q
  WHERE NOT EXISTS (SELECT 1 FROM dedup_match)
  RETURNING
    id::text AS job_id,
    status::text AS status
)
SELECT
  COALESCE(
    (SELECT job_id FROM dedup_match),
    (SELECT job_id FROM inserted_job)
  ) AS job_id,
  COALESCE(
    (SELECT status FROM dedup_match),
    (SELECT status FROM inserted_job)
  ) AS status,
  EXISTS(SELECT 1 FROM dedup_match) AS dedup_matched;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.QueueKey),
		strings.TrimSpace(cmd.JobKey),
		strings.TrimSpace(cmd.JobType),
		strings.TrimSpace(cmd.DedupKey),
		strings.TrimSpace(cmd.Priority),
		cloneMap(cmd.Payload),
		cmd.ScheduledAt,
		strings.TrimSpace(cmd.RequestedBy),
		cmd.MaxAttempts,
	)

	var result EnqueueJobResult
	if err := row.Scan(&result.JobID, &result.Status, &result.DedupMatched); err != nil {
		return EnqueueJobResult{}, err
	}

	return result, nil
}
