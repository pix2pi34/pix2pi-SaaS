package notifications

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ClaimNotificationDeliverySQLStore struct {
	db QueryRowProvider
}

func NewClaimNotificationDeliverySQLStore(db QueryRowProvider) *ClaimNotificationDeliverySQLStore {
	return &ClaimNotificationDeliverySQLStore{
		db: db,
	}
}

func (s *ClaimNotificationDeliverySQLStore) ClaimNotificationForDelivery(ctx context.Context, cmd ClaimNotificationDeliveryCommand) (ClaimNotificationDeliveryResult, error) {
	if s == nil || s.db == nil {
		return ClaimNotificationDeliveryResult{}, errors.New("claim notification delivery sql store hazir degil")
	}

	const query = `
WITH candidate_notification AS (
  SELECT
    n.id,
    n.notification_key,
    n.channel,
    n.recipient_ref,
    coalesce(n.subject, '') AS subject,
    coalesce(n.message_body, '') AS message_body,
    coalesce(n.template_ref, '') AS template_ref,
    n.priority::text AS priority,
    coalesce(n.attempt_no, 0) AS attempt_no
  FROM runtime.notifications n
  WHERE n.channel = $2
    AND n.status IN ('queued', 'scheduled')
    AND (
      n.scheduled_at IS NULL
      OR n.scheduled_at <= now()
    )
    AND (
      (NULLIF($1, '') IS NULL AND n.tenant_id IS NULL)
      OR
      (n.tenant_id::text = NULLIF($1, ''))
    )
  ORDER BY
    CASE n.priority::text
      WHEN 'critical' THEN 1
      WHEN 'high' THEN 2
      WHEN 'normal' THEN 3
      WHEN 'low' THEN 4
      ELSE 5
    END,
    n.created_at ASC
  LIMIT 1
  FOR UPDATE SKIP LOCKED
),
updated_notification AS (
  UPDATE runtime.notifications n
  SET
    status = 'sending',
    worker_id = $3,
    lease_expires_at = now() + make_interval(secs => $4),
    attempt_no = coalesce(n.attempt_no, 0) + 1,
    updated_at = now()
  FROM candidate_notification c
  WHERE n.id = c.id
  RETURNING
    n.id::text AS notification_id,
    n.channel,
    n.notification_key,
    n.recipient_ref,
    coalesce(n.subject, '') AS subject,
    coalesce(n.message_body, '') AS message_body,
    coalesce(n.template_ref, '') AS template_ref,
    n.priority::text AS priority,
    n.status::text AS status,
    n.attempt_no,
    n.lease_expires_at
)
SELECT
  u.notification_id,
  u.channel,
  u.notification_key,
  u.recipient_ref,
  u.subject,
  u.message_body,
  u.template_ref,
  u.priority,
  u.status,
  u.attempt_no,
  u.lease_expires_at
FROM updated_notification u;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.Channel),
		strings.TrimSpace(cmd.WorkerID),
		cmd.LeaseSeconds,
	)

	var result ClaimNotificationDeliveryResult
	var leaseExpiresAt time.Time

	if err := row.Scan(
		&result.NotificationID,
		&result.Channel,
		&result.NotificationKey,
		&result.RecipientRef,
		&result.Subject,
		&result.MessageBody,
		&result.TemplateRef,
		&result.Priority,
		&result.Status,
		&result.AttemptNo,
		&leaseExpiresAt,
	); err != nil {
		return ClaimNotificationDeliveryResult{}, err
	}

	result.Claimed = true
	result.LeaseExpiresAt = &leaseExpiresAt

	return result, nil
}
