package notifications

import (
	"context"
	"errors"
	"strings"
)

type RecoverNotificationSQLStore struct {
	db QueryRowProvider
}

func NewRecoverNotificationSQLStore(db QueryRowProvider) *RecoverNotificationSQLStore {
	return &RecoverNotificationSQLStore{
		db: db,
	}
}

func (s *RecoverNotificationSQLStore) RecoverNotification(ctx context.Context, cmd RecoverNotificationCommand) (RecoverNotificationResult, error) {
	if s == nil || s.db == nil {
		return RecoverNotificationResult{}, errors.New("recover notification sql store hazir degil")
	}

	const query = `
WITH updated_notification AS (
  UPDATE runtime.notifications n
  SET
    status = CASE
      WHEN $3 = 'dead_letter' THEN 'dead_letter'
      ELSE 'queued'
    END,
    channel = CASE
      WHEN $3 = 'requeue' AND NULLIF($5, '') IS NOT NULL THEN $5
      ELSE n.channel
    END,
    lease_expires_at = NULL,
    worker_id = NULL,
    attempt_no = CASE
      WHEN $7 THEN 0
      ELSE coalesce(n.attempt_no, 0)
    END,
    updated_at = now()
  WHERE n.id::text = $2
    AND (
      (NULLIF($1, '') IS NULL AND n.tenant_id IS NULL)
      OR
      (n.tenant_id::text = NULLIF($1, ''))
    )
  RETURNING
    n.id::text AS notification_id,
    n.status::text AS status,
    n.channel,
    n.attempt_no
)
SELECT
  u.notification_id,
  u.status,
  u.channel,
  u.attempt_no,
  true AS lease_released
FROM updated_notification u;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.NotificationID),
		strings.TrimSpace(cmd.ActionType),
		strings.TrimSpace(cmd.RequestedBy),
		strings.TrimSpace(cmd.TargetChannel),
		strings.TrimSpace(cmd.Reason),
		cmd.ResetAttempts,
	)

	var result RecoverNotificationResult
	if err := row.Scan(
		&result.NotificationID,
		&result.Status,
		&result.Channel,
		&result.AttemptNo,
		&result.LeaseReleased,
	); err != nil {
		return RecoverNotificationResult{}, err
	}

	return result, nil
}
