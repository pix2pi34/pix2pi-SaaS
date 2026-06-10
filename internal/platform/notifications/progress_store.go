package notifications

import (
	"context"
	"errors"
	"strings"
	"time"
)

type UpdateNotificationDeliverySQLStore struct {
	db QueryRowProvider
}

func NewUpdateNotificationDeliverySQLStore(db QueryRowProvider) *UpdateNotificationDeliverySQLStore {
	return &UpdateNotificationDeliverySQLStore{
		db: db,
	}
}

func (s *UpdateNotificationDeliverySQLStore) UpdateNotificationDelivery(ctx context.Context, cmd UpdateNotificationDeliveryCommand) (UpdateNotificationDeliveryResult, error) {
	if s == nil || s.db == nil {
		return UpdateNotificationDeliveryResult{}, errors.New("update notification delivery sql store hazir degil")
	}

	const query = `
WITH updated_notification AS (
  UPDATE runtime.notifications n
  SET
    status = $4,
    delivery_ref = NULLIF($6, ''),
    provider_code = NULLIF($7, ''),
    error_code = NULLIF($8, ''),
    lease_expires_at = CASE
      WHEN $4 = 'sending' AND $9 > 0 THEN now() + make_interval(secs => $9)
      WHEN $4 IN ('sent', 'failed', 'cancelled') THEN NULL
      ELSE n.lease_expires_at
    END,
    updated_at = now()
  WHERE n.id::text = $2
    AND coalesce(n.worker_id, '') = $3
    AND coalesce(n.attempt_no, 0) = $5
    AND (
      (NULLIF($1, '') IS NULL AND n.tenant_id IS NULL)
      OR
      (n.tenant_id::text = NULLIF($1, ''))
    )
  RETURNING
    n.id::text AS notification_id,
    n.status::text AS status,
    n.attempt_no,
    coalesce(n.delivery_ref, '') AS delivery_ref,
    coalesce(n.provider_code, '') AS provider_code,
    coalesce(n.error_code, '') AS error_code,
    n.lease_expires_at
)
SELECT
  u.notification_id,
  u.status,
  u.attempt_no,
  u.delivery_ref,
  u.provider_code,
  u.error_code,
  u.lease_expires_at
FROM updated_notification u;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.NotificationID),
		strings.TrimSpace(cmd.WorkerID),
		strings.TrimSpace(cmd.Status),
		cmd.AttemptNo,
		strings.TrimSpace(cmd.DeliveryRef),
		strings.TrimSpace(cmd.ProviderCode),
		strings.TrimSpace(cmd.ErrorCode),
		cmd.LeaseExtendSeconds,
	)

	var result UpdateNotificationDeliveryResult
	var leaseExpiresAt time.Time

	if err := row.Scan(
		&result.NotificationID,
		&result.Status,
		&result.AttemptNo,
		&result.DeliveryRef,
		&result.ProviderCode,
		&result.ErrorCode,
		&leaseExpiresAt,
	); err != nil {
		return UpdateNotificationDeliveryResult{}, err
	}

	if !leaseExpiresAt.IsZero() {
		result.LeaseExpiresAt = &leaseExpiresAt
	}

	return result, nil
}
