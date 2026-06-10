package idempotency

import (
	"context"
	"errors"
	"strings"
)

type FinalizeDedupeRecordSQLStore struct {
	db QueryRowProvider
}

func NewFinalizeDedupeRecordSQLStore(db QueryRowProvider) *FinalizeDedupeRecordSQLStore {
	return &FinalizeDedupeRecordSQLStore{
		db: db,
	}
}

func (s *FinalizeDedupeRecordSQLStore) FinalizeRecord(ctx context.Context, cmd FinalizeDedupeRecordCommand) (FinalizeDedupeRecordResult, error) {
	if s == nil || s.db == nil {
		return FinalizeDedupeRecordResult{}, errors.New("finalize dedupe sql store hazir degil")
	}

	const query = `
WITH updated_record AS (
  UPDATE runtime.dedupe_records d
  SET
    payload_hash = $4,
    value_ref = $5,
    status = $6,
    requested_by = $7,
    updated_at = now()
  WHERE d.scope_key = $2
    AND d.record_key = $3
    AND (
      (NULLIF($1, '') IS NULL AND d.tenant_id IS NULL)
      OR
      (d.tenant_id::text = NULLIF($1, ''))
    )
    AND d.expires_at > now()
  RETURNING
    d.id::text AS record_id,
    coalesce(d.value_ref, '') AS value_ref,
    d.status::text AS final_status
)
SELECT
  record_id,
  value_ref,
  final_status
FROM updated_record;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.ScopeKey),
		strings.TrimSpace(cmd.RecordKey),
		strings.TrimSpace(cmd.PayloadHash),
		strings.TrimSpace(cmd.ValueRef),
		strings.TrimSpace(cmd.FinalStatus),
		strings.TrimSpace(cmd.RequestedBy),
	)

	var result FinalizeDedupeRecordResult
	if err := row.Scan(
		&result.RecordID,
		&result.ValueRef,
		&result.FinalStatus,
	); err != nil {
		return FinalizeDedupeRecordResult{}, err
	}

	return result, nil
}
