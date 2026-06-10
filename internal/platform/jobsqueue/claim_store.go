package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ClaimSQLStore struct {
	db QueryRowProvider
}

func NewClaimSQLStore(db QueryRowProvider) *ClaimSQLStore {
	return &ClaimSQLStore{
		db: db,
	}
}

func (s *ClaimSQLStore) ClaimNextJob(ctx context.Context, cmd ClaimJobCommand) (ClaimJobResult, error) {
	if s == nil || s.db == nil {
		return ClaimJobResult{}, errors.New("claim sql store hazir degil")
	}

	const query = `
WITH target_queue AS (
  SELECT q.id
  FROM runtime.job_queues q
  WHERE q.queue_key = $2
    AND (
      (NULLIF($1, '') IS NULL AND q.tenant_id IS NULL)
      OR
      (q.tenant_id::text = NULLIF($1, ''))
    )
  LIMIT 1
),
candidate_job AS (
  SELECT
    j.id,
    j.queue_id,
    j.job_key,
    j.job_type,
    j.priority::text AS priority,
    j.payload,
    coalesce(j.attempt_no, 0) AS attempt_no
  FROM runtime.jobs j
  JOIN target_queue q
    ON q.id = j.queue_id
  WHERE j.status IN ('queued', 'scheduled')
    AND (
      j.scheduled_at IS NULL
      OR j.scheduled_at <= now()
    )
  ORDER BY
    CASE j.priority::text
      WHEN 'critical' THEN 1
      WHEN 'high' THEN 2
      WHEN 'normal' THEN 3
      WHEN 'low' THEN 4
      ELSE 5
    END,
    j.created_at ASC
  LIMIT 1
  FOR UPDATE SKIP LOCKED
),
updated_job AS (
  UPDATE runtime.jobs j
  SET
    status = 'processing',
    worker_id = $3,
    lease_expires_at = now() + make_interval(secs => $4),
    attempt_no = coalesce(j.attempt_no, 0) + 1,
    started_at = coalesce(j.started_at, now()),
    updated_at = now()
  FROM candidate_job c
  WHERE j.id = c.id
  RETURNING
    j.id::text AS job_id,
    j.job_key,
    j.job_type,
    j.priority::text AS priority,
    j.status::text AS status,
    j.payload,
    j.attempt_no,
    j.lease_expires_at
)
SELECT
  u.job_id,
  $2 AS queue_key,
  u.job_key,
  u.job_type,
  u.priority,
  u.status,
  u.attempt_no,
  u.payload,
  u.lease_expires_at
FROM updated_job u;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.QueueKey),
		strings.TrimSpace(cmd.WorkerID),
		cmd.LeaseSeconds,
	)

	var result ClaimJobResult
	var payload map[string]any
	var leaseExpiresAt time.Time

	err := row.Scan(
		&result.JobID,
		&result.QueueKey,
		&result.JobKey,
		&result.JobType,
		&result.Priority,
		&result.Status,
		&result.AttemptNo,
		&payload,
		&leaseExpiresAt,
	)
	if err != nil {
		return ClaimJobResult{}, err
	}

	result.Claimed = true
	result.Payload = cloneMap(payload)
	result.LeaseExpiresAt = &leaseExpiresAt

	return result, nil
}
