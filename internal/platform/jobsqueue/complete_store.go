package jobsqueue

import (
	"context"
	"errors"
	"strings"
)

type CompleteSQLStore struct {
	db QueryRowProvider
}

func NewCompleteSQLStore(db QueryRowProvider) *CompleteSQLStore {
	return &CompleteSQLStore{
		db: db,
	}
}

func (s *CompleteSQLStore) CompleteJob(ctx context.Context, cmd CompleteJobCommand) (CompleteJobResult, error) {
	if s == nil || s.db == nil {
		return CompleteJobResult{}, errors.New("complete sql store hazir degil")
	}

	const query = `
WITH updated_job AS (
  UPDATE runtime.jobs j
  SET
    status = $4,
    lease_expires_at = NULL,
    updated_at = now()
  WHERE j.id::text = $2
    AND coalesce(j.worker_id, '') = $3
    AND coalesce(j.attempt_no, 0) = $5
    AND (
      (NULLIF($1, '') IS NULL AND j.tenant_id IS NULL)
      OR
      (j.tenant_id::text = NULLIF($1, ''))
    )
  RETURNING
    j.id::text AS job_id,
    j.status::text AS status,
    j.attempt_no
)
SELECT
  u.job_id,
  u.status,
  u.attempt_no,
  $6 AS completion_note,
  $7 AS error_code,
  $8 AS output_payload,
  true AS lease_released
FROM updated_job u;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.JobID),
		strings.TrimSpace(cmd.WorkerID),
		strings.TrimSpace(cmd.Status),
		cmd.AttemptNo,
		strings.TrimSpace(cmd.CompletionNote),
		strings.TrimSpace(cmd.ErrorCode),
		cloneMap(cmd.OutputPayload),
	)

	var result CompleteJobResult
	if err := row.Scan(
		&result.JobID,
		&result.Status,
		&result.AttemptNo,
		&result.CompletionNote,
		&result.ErrorCode,
		&result.OutputPayload,
		&result.LeaseReleased,
	); err != nil {
		return CompleteJobResult{}, err
	}

	return result, nil
}
