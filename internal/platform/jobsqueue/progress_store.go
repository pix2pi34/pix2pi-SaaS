package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"time"
)

type UpdateProgressSQLStore struct {
	db QueryRowProvider
}

func NewUpdateProgressSQLStore(db QueryRowProvider) *UpdateProgressSQLStore {
	return &UpdateProgressSQLStore{
		db: db,
	}
}

func (s *UpdateProgressSQLStore) UpdateJobProgress(ctx context.Context, cmd UpdateJobProgressCommand) (UpdateJobProgressResult, error) {
	if s == nil || s.db == nil {
		return UpdateJobProgressResult{}, errors.New("update progress sql store hazir degil")
	}

	const query = `
WITH updated_job AS (
  UPDATE runtime.jobs j
  SET
    status = $4,
    lease_expires_at = CASE
      WHEN $4 = 'processing' AND $8 > 0 THEN now() + make_interval(secs => $8)
      WHEN $4 IN ('succeeded', 'failed', 'cancelled') THEN NULL
      ELSE j.lease_expires_at
    END,
    updated_at = now()
  WHERE j.id::text = $2
    AND coalesce(j.worker_id, '') = $3
    AND coalesce(j.attempt_no, 0) = $7
    AND (
      (NULLIF($1, '') IS NULL AND j.tenant_id IS NULL)
      OR
      (j.tenant_id::text = NULLIF($1, ''))
    )
  RETURNING
    j.id::text AS job_id,
    j.status::text AS status,
    j.lease_expires_at
)
SELECT
  u.job_id,
  u.status,
  $5 AS progress_percent,
  $7 AS attempt_no,
  $6 AS message,
  u.lease_expires_at
FROM updated_job u;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.JobID),
		strings.TrimSpace(cmd.WorkerID),
		strings.TrimSpace(cmd.Status),
		cmd.ProgressPercent,
		strings.TrimSpace(cmd.Message),
		cmd.AttemptNo,
		cmd.LeaseExtendSeconds,
	)

	var result UpdateJobProgressResult
	var leaseExpiresAt time.Time

	if err := row.Scan(
		&result.JobID,
		&result.Status,
		&result.ProgressPercent,
		&result.AttemptNo,
		&result.Message,
		&leaseExpiresAt,
	); err != nil {
		return UpdateJobProgressResult{}, err
	}

	if !leaseExpiresAt.IsZero() {
		result.LeaseExpiresAt = &leaseExpiresAt
	}

	return result, nil
}
