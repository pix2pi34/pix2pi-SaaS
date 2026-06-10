package jobsqueue

import (
	"context"
	"errors"
	"strings"
)

type JobAuditSQLStore struct {
	db QueryRowProvider
}

func NewJobAuditSQLStore(db QueryRowProvider) *JobAuditSQLStore {
	return &JobAuditSQLStore{
		db: db,
	}
}

func (s *JobAuditSQLStore) RecordJobAuditEvent(ctx context.Context, cmd RecordJobAuditEventCommand) (RecordJobAuditEventResult, error) {
	if s == nil || s.db == nil {
		return RecordJobAuditEventResult{}, errors.New("job audit sql store hazir degil")
	}

	const query = `
WITH target_job AS (
  SELECT
    j.id,
    coalesce(j.attempt_no, 0) AS current_attempt_no
  FROM runtime.jobs j
  WHERE j.id::text = $2
    AND (
      (NULLIF($1, '') IS NULL AND j.tenant_id IS NULL)
      OR
      (j.tenant_id::text = NULLIF($1, ''))
    )
),
inserted_audit AS (
  INSERT INTO runtime.job_attempts (
    job_id,
    tenant_id,
    business_code,
    attempt_no,
    status,
    worker_id,
    result_message,
    metadata
  )
  SELECT
    tj.id,
    NULLIF($1, '')::uuid,
    'JAUD_' || upper(replace($3, '-', '_')) || '_' || upper(replace($2, '-', '_')),
    CASE
      WHEN $6 > 0 THEN $6
      ELSE tj.current_attempt_no
    END,
    NULLIF($5, ''),
    $4,
    NULLIF($7, ''),
    $8
  FROM target_job tj
  RETURNING id::text
)
SELECT id
FROM inserted_audit;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.JobID),
		strings.TrimSpace(cmd.EventType),
		strings.TrimSpace(cmd.ActorRef),
		strings.TrimSpace(cmd.Status),
		cmd.AttemptNo,
		strings.TrimSpace(cmd.Message),
		cloneMap(cmd.Metadata),
	)

	var result RecordJobAuditEventResult
	if err := row.Scan(&result.AuditID); err != nil {
		return RecordJobAuditEventResult{}, err
	}

	return result, nil
}
