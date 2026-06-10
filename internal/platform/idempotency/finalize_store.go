package idempotency

import (
	"context"
	"errors"
	"strings"
)

type FinalizeIdempotencySQLStore struct {
	db QueryRowProvider
}

func NewFinalizeIdempotencySQLStore(db QueryRowProvider) *FinalizeIdempotencySQLStore {
	return &FinalizeIdempotencySQLStore{
		db: db,
	}
}

func (s *FinalizeIdempotencySQLStore) FinalizeKey(ctx context.Context, cmd FinalizeIdempotencyKeyCommand) (FinalizeIdempotencyKeyResult, error) {
	if s == nil || s.db == nil {
		return FinalizeIdempotencyKeyResult{}, errors.New("finalize idempotency sql store hazir degil")
	}

	const query = `
WITH updated_key AS (
  UPDATE runtime.idempotency_keys k
  SET
    request_hash = $4,
    result_ref = $5,
    status = $6,
    requested_by = $7,
    updated_at = now()
  WHERE k.scope_key = $2
    AND k.idempotency_key = $3
    AND (
      (NULLIF($1, '') IS NULL AND k.tenant_id IS NULL)
      OR
      (k.tenant_id::text = NULLIF($1, ''))
    )
    AND k.expires_at > now()
  RETURNING
    k.id::text AS reservation_id,
    coalesce(k.result_ref, '') AS result_ref,
    k.status::text AS final_status
)
SELECT
  reservation_id,
  result_ref,
  final_status
FROM updated_key;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.ScopeKey),
		strings.TrimSpace(cmd.IdempotencyKey),
		strings.TrimSpace(cmd.RequestHash),
		strings.TrimSpace(cmd.ResultRef),
		strings.TrimSpace(cmd.FinalStatus),
		strings.TrimSpace(cmd.RequestedBy),
	)

	var result FinalizeIdempotencyKeyResult
	if err := row.Scan(
		&result.ReservationID,
		&result.ResultRef,
		&result.FinalStatus,
	); err != nil {
		return FinalizeIdempotencyKeyResult{}, err
	}

	return result, nil
}
