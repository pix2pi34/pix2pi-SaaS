package idempotency

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ReserveDedupeRecordSQLStore struct {
	db QueryRowProvider
}

func NewReserveDedupeRecordSQLStore(db QueryRowProvider) *ReserveDedupeRecordSQLStore {
	return &ReserveDedupeRecordSQLStore{
		db: db,
	}
}

func (s *ReserveDedupeRecordSQLStore) ReserveOrCheckRecord(ctx context.Context, cmd ReserveDedupeRecordCommand) (ReserveDedupeRecordResult, error) {
	if s == nil || s.db == nil {
		return ReserveDedupeRecordResult{}, errors.New("reserve dedupe sql store hazir degil")
	}

	const query = `
WITH existing_record AS (
  SELECT
    d.id::text AS record_id,
    d.payload_hash,
    coalesce(d.value_ref, '') AS existing_value_ref,
    d.expires_at
  FROM runtime.dedupe_records d
  WHERE d.scope_key = $2
    AND d.record_key = $3
    AND (
      (NULLIF($1, '') IS NULL AND d.tenant_id IS NULL)
      OR
      (d.tenant_id::text = NULLIF($1, ''))
    )
    AND d.expires_at > now()
  ORDER BY d.created_at DESC
  LIMIT 1
),
inserted_record AS (
  INSERT INTO runtime.dedupe_records (
    tenant_id,
    business_code,
    scope_key,
    record_key,
    payload_hash,
    requested_by,
    expires_at
  )
  SELECT
    NULLIF($1, '')::uuid,
    'DEDUPE_' || upper(replace($2, '-', '_')) || '_' || upper(replace($3, '-', '_')),
    $2,
    $3,
    $4,
    $6,
    now() + make_interval(secs => $5)
  WHERE NOT EXISTS (SELECT 1 FROM existing_record)
  RETURNING
    id::text AS record_id,
    expires_at
)
SELECT
  COALESCE(
    (SELECT record_id FROM existing_record),
    (SELECT record_id FROM inserted_record)
  ) AS record_id,
  CASE
    WHEN EXISTS (SELECT 1 FROM existing_record WHERE payload_hash = $4) THEN 'existing'
    WHEN EXISTS (SELECT 1 FROM existing_record WHERE payload_hash <> $4) THEN 'conflict'
    ELSE 'reserved'
  END AS status,
  COALESCE(
    (SELECT existing_value_ref FROM existing_record),
    ''
  ) AS existing_value_ref,
  COALESCE(
    (SELECT expires_at FROM existing_record),
    (SELECT expires_at FROM inserted_record)
  ) AS expires_at;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.ScopeKey),
		strings.TrimSpace(cmd.RecordKey),
		strings.TrimSpace(cmd.PayloadHash),
		cmd.TTLSeconds,
		strings.TrimSpace(cmd.RequestedBy),
	)

	var result ReserveDedupeRecordResult
	var expiresAt time.Time

	if err := row.Scan(
		&result.RecordID,
		&result.Status,
		&result.ExistingValueRef,
		&expiresAt,
	); err != nil {
		return ReserveDedupeRecordResult{}, err
	}

	result.ExpiresAt = &expiresAt
	return result, nil
}
