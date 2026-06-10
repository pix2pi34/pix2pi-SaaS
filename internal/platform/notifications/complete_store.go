package notifications

import (
	"context"
	"errors"
	"strings"
)

type CompleteNotificationDeliverySQLStore struct {
	db QueryRowProvider
}

func NewCompleteNotificationDeliverySQLStore(db QueryRowProvider) *CompleteNotificationDeliverySQLStore {
	return &CompleteNotificationDeliverySQLStore{
		db: db,
	}
}

func (s *CompleteNotificationDeliverySQLStore) CompleteNotificationDelivery(ctx context.Context, cmd CompleteNotificationDeliveryCommand) (CompleteNotificationDeliveryResult, error) {
	if s == nil || s.db == nil {
		return CompleteNotificationDeliveryResult{}, errors.New("complete notification delivery sql store hazir degil")
	}

	const query = `
WITH updated_notification AS (
  UPDATE runtime.notifications n
  SET
    status = $4,
    delivery_ref = NULLIF($6, ''),
    provider_code = NULLIF($7, ''),
    error_code = NULLIF($8, ''),
    completion_note = NULLIF($9, ''),
    lease_expires_at = NULL,
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
    coalesce(n.completion_note, '') AS completion_note
)
SELECT
  u.notification_id,
  u.status,
  u.attempt_no,
  u.delivery_ref,
  u.provider_code,
  u.error_code,
  u.completion_note,
  true AS lease_released
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
		strings.TrimSpace(cmd.CompletionNote),
	)

	var result CompleteNotificationDeliveryResult
	if err := row.Scan(
		&result.NotificationID,
		&result.Status,
		&result.AttemptNo,
		&result.DeliveryRef,
		&result.ProviderCode,
		&result.ErrorCode,
		&result.CompletionNote,
		&result.LeaseReleased,
	); err != nil {
		return CompleteNotificationDeliveryResult{}, err
	}

	return result, nil
}
