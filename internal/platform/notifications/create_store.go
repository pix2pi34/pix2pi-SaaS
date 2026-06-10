package notifications

import (
	"context"
	"errors"
	"strings"
)

type CreateNotificationSQLStore struct {
	db QueryRowProvider
}

func NewCreateNotificationSQLStore(db QueryRowProvider) *CreateNotificationSQLStore {
	return &CreateNotificationSQLStore{
		db: db,
	}
}

func (s *CreateNotificationSQLStore) CreateNotification(ctx context.Context, cmd CreateNotificationCommand) (CreateNotificationResult, error) {
	if s == nil || s.db == nil {
		return CreateNotificationResult{}, errors.New("create notification sql store hazir degil")
	}

	const query = `
WITH dedup_match AS (
  SELECT
    n.id::text AS notification_id,
    n.status::text AS status,
    n.scheduled_at
  FROM runtime.notifications n
  WHERE NULLIF($8, '') IS NOT NULL
    AND n.dedup_key = NULLIF($8, '')
    AND (
      (NULLIF($1, '') IS NULL AND n.tenant_id IS NULL)
      OR
      (n.tenant_id::text = NULLIF($1, ''))
    )
  ORDER BY n.created_at DESC
  LIMIT 1
),
inserted_notification AS (
  INSERT INTO runtime.notifications (
    tenant_id,
    business_code,
    channel,
    notification_key,
    recipient_ref,
    subject,
    message_body,
    template_ref,
    priority,
    dedup_key,
    scheduled_at,
    requested_by,
    metadata,
    status
  )
  SELECT
    NULLIF($1, '')::uuid,
    'NTF_' || upper(replace($3, '-', '_')),
    $2,
    $3,
    $4,
    NULLIF($5, ''),
    NULLIF($6, ''),
    NULLIF($7, ''),
    $9,
    NULLIF($8, ''),
    $10,
    $11,
    $12,
    CASE
      WHEN $10 IS NULL THEN 'queued'
      ELSE 'scheduled'
    END
  WHERE NOT EXISTS (SELECT 1 FROM dedup_match)
  RETURNING
    id::text AS notification_id,
    status::text AS status,
    scheduled_at
)
SELECT
  COALESCE(
    (SELECT notification_id FROM dedup_match),
    (SELECT notification_id FROM inserted_notification)
  ) AS notification_id,
  COALESCE(
    (SELECT status FROM dedup_match),
    (SELECT status FROM inserted_notification)
  ) AS status,
  COALESCE(
    (SELECT scheduled_at FROM dedup_match),
    (SELECT scheduled_at FROM inserted_notification)
  ) AS scheduled_at,
  EXISTS(SELECT 1 FROM dedup_match) AS dedup_matched;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.Channel),
		strings.TrimSpace(cmd.NotificationKey),
		strings.TrimSpace(cmd.RecipientRef),
		strings.TrimSpace(cmd.Subject),
		strings.TrimSpace(cmd.MessageBody),
		strings.TrimSpace(cmd.TemplateRef),
		strings.TrimSpace(cmd.DedupKey),
		strings.TrimSpace(cmd.Priority),
		cmd.ScheduledAt,
		strings.TrimSpace(cmd.RequestedBy),
		cloneMap(cmd.Metadata),
	)

	var result CreateNotificationResult
	if err := row.Scan(
		&result.NotificationID,
		&result.Status,
		&result.ScheduledAt,
		&result.DedupMatched,
	); err != nil {
		return CreateNotificationResult{}, err
	}

	return result, nil
}
