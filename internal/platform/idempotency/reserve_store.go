package idempotency

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ReserveIdempotencySQLStore struct {
	db QueryRowProvider
}

func NewReserveIdempotencySQLStore(db QueryRowProvider) *ReserveIdempotencySQLStore {
	return &ReserveIdempotencySQLStore{
		db: db,
	}
}

func (s *ReserveIdempotencySQLStore) ReserveOrCheckKey(ctx context.Context, cmd ReserveIdempotencyKeyCommand) (ReserveIdempotencyKeyResult, error) {
	if s == nil || s.db == nil {
		return ReserveIdempotencyKeyResult{}, errors.New("reserve idempotency sql store hazir degil")
	}

	const query = `
WITH existing_key AS (
  SELECT
    k.id::text AS reservation_id,
    k.request_hash,
    coalesce(k.result_ref, '') AS existing_result_ref,
    k.expires_at
  FROM runtime.idempotency_keys k
  WHERE k.scope_key = $2
    AND k.idempotency_key = $3
    AND (
      (NULLIF($1, '') IS NULL AND k.tenant_id IS NULL)
      OR
      (k.tenant_id::text = NULLIF($1, ''))
    )
    AND k.expires_at > now()
  ORDER BY k.created_at DESC
  LIMIT 1
),
inserted_key AS (
  INSERT INTO runtime.idempotency_keys (
    tenant_id,
    business_code,
    scope_key,
    idempotency_key,
    request_hash,
    requested_by,
    expires_at
  )
  SELECT
    NULLIF($1, '')::uuid,
    'IDEMP_' || upper(replace($2, '-', '_')) || '_' || upper(replace($3, '-', '_')),
    $2,
    $3,
    $4,
    $6,
    now() + make_interval(secs => $5)
  WHERE NOT EXISTS (SELECT 1 FROM existing_key)
  RETURNING
    id::text AS reservation_id,
    expires_at
)
SELECT
  COALESCE(
    (SELECT reservation_id FROM existing_key),
    (SELECT reservation_id FROM inserted_key)
  ) AS reservation_id,
  CASE
    WHEN EXISTS (SELECT 1 FROM existing_key WHERE request_hash = $4) THEN 'existing'
    WHEN EXISTS (SELECT 1 FROM existing_key WHERE request_hash <> $4) THEN 'conflict'
    ELSE 'reserved'
  END AS status,
  COALESCE(
    (SELECT existing_result_ref FROM existing_key),
    ''
  ) AS existing_result_ref,
  COALESCE(
    (SELECT expires_at FROM existing_key),
    (SELECT expires_at FROM inserted_key)
  ) AS expires_at;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.ScopeKey),
		strings.TrimSpace(cmd.IdempotencyKey),
		strings.TrimSpace(cmd.RequestHash),
		cmd.TTLSeconds,
		strings.TrimSpace(cmd.RequestedBy),
	)

	var result ReserveIdempotencyKeyResult
	var expiresAt time.Time

	if err := row.Scan(
		&result.ReservationID,
		&result.Status,
		&result.ExistingResultRef,
		&expiresAt,
	); err != nil {
		return ReserveIdempotencyKeyResult{}, err
	}

	result.ExpiresAt = &expiresAt
	return result, nil
}
