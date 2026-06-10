package jobsqueue

import (
	"context"
	"errors"
	"strings"
)

type RecoverSQLStore struct {
	db QueryRowProvider
}

func NewRecoverSQLStore(db QueryRowProvider) *RecoverSQLStore {
	return &RecoverSQLStore{
		db: db,
	}
}

func (s *RecoverSQLStore) RecoverJob(ctx context.Context, cmd RecoverJobCommand) (RecoverJobResult, error) {
	if s == nil || s.db == nil {
		return RecoverJobResult{}, errors.New("recover sql store hazir degil")
	}

	const query = `
WITH target_queue AS (
  SELECT
    q.id,
    q.queue_key
  FROM runtime.job_queues q
  WHERE NULLIF($5, '') IS NOT NULL
    AND q.queue_key = NULLIF($5, '')
    AND (
      (NULLIF($1, '') IS NULL AND q.tenant_id IS NULL)
      OR
      (q.tenant_id::text = NULLIF($1, ''))
    )
  LIMIT 1
),
updated_job AS (
  UPDATE runtime.jobs j
  SET
    status = CASE
      WHEN $3 = 'dead_letter' THEN 'dead_letter'
      ELSE 'queued'
    END,
    queue_id = CASE
      WHEN $3 = 'requeue' AND EXISTS (SELECT 1 FROM target_queue)
        THEN (SELECT id FROM target_queue)
      ELSE j.queue_id
    END,
    lease_expires_at = NULL,
    worker_id = NULL,
    attempt_no = CASE
      WHEN $7 THEN 0
      ELSE coalesce(j.attempt_no, 0)
    END,
    updated_at = now()
  WHERE j.id::text = $2
    AND (
      (NULLIF($1, '') IS NULL AND j.tenant_id IS NULL)
      OR
      (j.tenant_id::text = NULLIF($1, ''))
    )
  RETURNING
    j.id::text AS job_id,
    j.status::text AS status,
    CASE
      WHEN $3 = 'requeue' AND EXISTS (SELECT 1 FROM target_queue)
        THEN (SELECT queue_key FROM target_queue)
      ELSE coalesce((SELECT q.queue_key FROM runtime.job_queues q WHERE q.id = j.queue_id), '')
    END AS queue_key,
    j.attempt_no
)
SELECT
  u.job_id,
  u.status,
  u.queue_key,
  u.attempt_no,
  true AS lease_released
FROM updated_job u;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.JobID),
		strings.TrimSpace(cmd.ActionType),
		strings.TrimSpace(cmd.RequestedBy),
		strings.TrimSpace(cmd.TargetQueueKey),
		strings.TrimSpace(cmd.Reason),
		cmd.ResetAttempts,
	)

	var result RecoverJobResult
	if err := row.Scan(
		&result.JobID,
		&result.Status,
		&result.QueueKey,
		&result.AttemptNo,
		&result.LeaseReleased,
	); err != nil {
		return RecoverJobResult{}, err
	}

	return result, nil
}
