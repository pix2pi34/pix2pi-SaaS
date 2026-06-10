package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ScheduleJobBackoffCommand struct {
	TenantID            string
	JobID               string
	AttemptNo           int
	PlannedDelaySeconds int
	RetryAt             time.Time
	LastErrorCode       string
}

type ScheduleJobBackoffResult struct {
	JobID               string
	Status              string
	AttemptNo           int
	PlannedDelaySeconds int
	RetryAt             time.Time
	LeaseReleased       bool
}

type BackoffSQLStore struct {
	db QueryRowProvider
}

func NewBackoffSQLStore(db QueryRowProvider) *BackoffSQLStore {
	return &BackoffSQLStore{
		db: db,
	}
}

func (s *BackoffSQLStore) ScheduleJobRetry(ctx context.Context, cmd ScheduleJobBackoffCommand) (ScheduleJobBackoffResult, error) {
	if s == nil || s.db == nil {
		return ScheduleJobBackoffResult{}, errors.New("backoff sql store hazir degil")
	}

	const query = `
WITH updated_job AS (
  UPDATE runtime.jobs j
  SET
    status = 'scheduled',
    scheduled_at = $4,
    lease_expires_at = NULL,
    worker_id = NULL,
    updated_at = now()
  WHERE j.id::text = $2
    AND coalesce(j.attempt_no, 0) = $3
    AND (
      (NULLIF($1, '') IS NULL AND j.tenant_id IS NULL)
      OR
      (j.tenant_id::text = NULLIF($1, ''))
    )
  RETURNING
    j.id::text AS job_id,
    j.status::text AS status,
    coalesce(j.attempt_no, 0) AS attempt_no,
    j.scheduled_at
)
SELECT
  u.job_id,
  u.status,
  u.attempt_no,
  $5 AS planned_delay_seconds,
  u.scheduled_at,
  true AS lease_released
FROM updated_job u;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.JobID),
		cmd.AttemptNo,
		cmd.RetryAt.UTC(),
		cmd.PlannedDelaySeconds,
	)

	var result ScheduleJobBackoffResult
	if err := row.Scan(
		&result.JobID,
		&result.Status,
		&result.AttemptNo,
		&result.PlannedDelaySeconds,
		&result.RetryAt,
		&result.LeaseReleased,
	); err != nil {
		return ScheduleJobBackoffResult{}, err
	}

	return result, nil
}
