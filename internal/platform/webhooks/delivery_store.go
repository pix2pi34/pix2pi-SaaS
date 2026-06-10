package webhooks

import (
	"context"
	"errors"
	"strings"
)

type DeliverWebhookSQLStore struct {
	db QueryRowProvider
}

func NewDeliverWebhookSQLStore(db QueryRowProvider) *DeliverWebhookSQLStore {
	return &DeliverWebhookSQLStore{
		db: db,
	}
}

func (s *DeliverWebhookSQLStore) DeliverWebhook(ctx context.Context, cmd DeliverWebhookCommand) (DeliverWebhookResult, error) {
	if s == nil || s.db == nil {
		return DeliverWebhookResult{}, errors.New("webhook delivery sql store hazir degil")
	}

	const query = `
WITH inserted_delivery AS (
  INSERT INTO runtime.webhook_deliveries (
    tenant_id,
    webhook_id,
    subscription_id,
    event_id,
    event_type,
    target_url,
    secret_ref,
    signature,
    signed_payload,
    payload_json,
    requested_by,
    status,
    attempt_no,
    delivery_ref,
    created_at,
    updated_at
  )
  VALUES (
    NULLIF($1, ''),
    $2,
    $3,
    $4,
    $5,
    $6,
    $7,
    $8,
    $9,
    $10,
    $11,
    'sending',
    1,
    $4 || '-delivery-1',
    now(),
    now()
  )
  RETURNING
    webhook_id,
    subscription_id,
    event_id,
    event_type,
    target_url,
    signature,
    status::text AS status,
    attempt_no,
    delivery_ref
)
SELECT
  id.webhook_id,
  id.subscription_id,
  id.event_id,
  id.event_type,
  id.target_url,
  id.signature,
  id.status,
  id.attempt_no,
  id.delivery_ref
FROM inserted_delivery id;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.WebhookID),
		strings.TrimSpace(cmd.SubscriptionID),
		strings.TrimSpace(cmd.EventID),
		strings.TrimSpace(cmd.EventType),
		strings.TrimSpace(cmd.TargetURL),
		strings.TrimSpace(cmd.SecretRef),
		strings.TrimSpace(cmd.Signature),
		strings.TrimSpace(cmd.SignedPayload),
		cloneMap(cmd.Payload),
		strings.TrimSpace(cmd.RequestedBy),
	)

	var result DeliverWebhookResult
	if err := row.Scan(
		&result.WebhookID,
		&result.SubscriptionID,
		&result.EventID,
		&result.EventType,
		&result.TargetURL,
		&result.Signature,
		&result.Status,
		&result.AttemptNo,
		&result.DeliveryRef,
	); err != nil {
		return DeliverWebhookResult{}, err
	}

	return result, nil
}
