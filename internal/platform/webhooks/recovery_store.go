package webhooks

import (
	"context"
	"database/sql"
	"errors"
	"strings"
)

type ApplyWebhookRecoverySQLStore struct {
	db QueryRowProvider
}

func NewApplyWebhookRecoverySQLStore(db QueryRowProvider) *ApplyWebhookRecoverySQLStore {
	return &ApplyWebhookRecoverySQLStore{
		db: db,
	}
}

func (s *ApplyWebhookRecoverySQLStore) ApplyRecovery(ctx context.Context, cmd ApplyWebhookRecoveryCommand) (ApplyWebhookRecoveryResult, error) {
	if s == nil || s.db == nil {
		return ApplyWebhookRecoveryResult{}, errors.New("webhook recovery sql store hazir degil")
	}

	const query = `
WITH updated_delivery AS (
  UPDATE runtime.webhook_deliveries wd
  SET
    status = CASE
      WHEN $4 = 'dead_letter' THEN 'dead_letter'
      ELSE 'pending'
    END,
    lease_expires_at = NULL,
    worker_id = NULL,
    attempt_no = CASE
      WHEN $7 THEN 0
      ELSE coalesce(wd.attempt_no, 0)
    END,
    next_attempt_at = CASE
      WHEN $4 = 'requeue' THEN $8
      ELSE wd.next_attempt_at
    END,
    updated_at = now()
  WHERE wd.webhook_id = $2
    AND wd.delivery_ref = $3
    AND (
      (NULLIF($1, '') IS NULL AND wd.tenant_id IS NULL)
      OR
      (wd.tenant_id::text = NULLIF($1, ''))
    )
  RETURNING
    wd.webhook_id,
    wd.delivery_ref,
    $4 AS action_type,
    wd.status::text AS status,
    wd.attempt_no,
    wd.next_attempt_at,
    true AS lease_released
)
SELECT
  ud.webhook_id,
  ud.delivery_ref,
  ud.action_type,
  ud.status,
  ud.attempt_no,
  ud.next_attempt_at,
  ud.lease_released
FROM updated_delivery ud;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.WebhookID),
		strings.TrimSpace(cmd.DeliveryRef),
		strings.TrimSpace(cmd.ActionType),
		strings.TrimSpace(cmd.RequestedBy),
		strings.TrimSpace(cmd.Reason),
		cmd.ResetAttempts,
		cloneWebhookTimePtr(cmd.NextAttemptAt),
	)

	var result ApplyWebhookRecoveryResult
	var nextAttemptAt sql.NullTime

	if err := row.Scan(
		&result.WebhookID,
		&result.DeliveryRef,
		&result.ActionType,
		&result.Status,
		&result.AttemptNo,
		&nextAttemptAt,
		&result.LeaseReleased,
	); err != nil {
		return ApplyWebhookRecoveryResult{}, err
	}

	if nextAttemptAt.Valid {
		t := nextAttemptAt.Time.UTC()
		result.NextAttemptAt = &t
	}

	return result, nil
}
