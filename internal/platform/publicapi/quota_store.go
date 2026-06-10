package publicapi

import (
	"context"
	"errors"
	"strings"
)

type EvaluatePublicAPIQuotaSQLStore struct {
	db QueryRowProvider
}

func NewEvaluatePublicAPIQuotaSQLStore(db QueryRowProvider) *EvaluatePublicAPIQuotaSQLStore {
	return &EvaluatePublicAPIQuotaSQLStore{
		db: db,
	}
}

func (s *EvaluatePublicAPIQuotaSQLStore) EvaluateQuota(ctx context.Context, cmd EvaluatePublicAPIQuotaCommand) (EvaluatePublicAPIQuotaResult, error) {
	if s == nil || s.db == nil {
		return EvaluatePublicAPIQuotaResult{}, errors.New("public api quota sql store hazir degil")
	}

	const query = `
WITH quota_policy AS (
  SELECT
    paq.limit_amount,
    paq.retry_after_seconds
  FROM runtime.public_api_quotas paq
  WHERE paq.app_id = $2
    AND paq.api_key_id = $3
    AND paq.environment = $4
    AND paq.quota_window = $5
    AND (
      (NULLIF($1, '') IS NULL AND paq.tenant_id IS NULL)
      OR
      (paq.tenant_id::text = NULLIF($1, ''))
    )
  ORDER BY paq.updated_at DESC
  LIMIT 1
),
usage_before AS (
  SELECT
    COALESCE(SUM(pau.cost), 0)::int AS used_before
  FROM runtime.public_api_usage pau
  WHERE pau.app_id = $2
    AND pau.api_key_id = $3
    AND pau.environment = $4
    AND pau.quota_window = $5
    AND (
      (NULLIF($1, '') IS NULL AND pau.tenant_id IS NULL)
      OR
      (pau.tenant_id::text = NULLIF($1, ''))
    )
),
quota_eval AS (
  SELECT
    $6::text AS request_id,
    $2::text AS app_id,
    $3::text AS api_key_id,
    $4::text AS environment,
    $5::text AS quota_window,
    COALESCE((SELECT limit_amount FROM quota_policy), 1000)::int AS limit_amount,
    COALESCE((SELECT used_before FROM usage_before), 0)::int AS used_before,
    $7::int AS cost
),
insert_usage AS (
  INSERT INTO runtime.public_api_usage (
    tenant_id,
    request_id,
    app_id,
    api_key_id,
    environment,
    quota_window,
    cost,
    requested_by,
    created_at,
    updated_at
  )
  SELECT
    NULLIF($1, ''),
    qe.request_id,
    qe.app_id,
    qe.api_key_id,
    qe.environment,
    qe.quota_window,
    qe.cost,
    $8,
    now(),
    now()
  FROM quota_eval qe
  WHERE (qe.used_before + qe.cost) <= qe.limit_amount
  RETURNING cost
)
SELECT
  qe.request_id,
  qe.app_id,
  qe.api_key_id,
  qe.environment,
  qe.quota_window,
  qe.limit_amount AS limit,
  qe.used_before,
  qe.cost,
  (qe.used_before + qe.cost)::int AS used_after,
  GREATEST(qe.limit_amount - (qe.used_before + qe.cost), 0)::int AS remaining,
  CASE
    WHEN (qe.used_before + qe.cost) <= qe.limit_amount THEN 'allowed'
    ELSE 'limited'
  END AS rate_limit_status,
  CASE
    WHEN (qe.used_before + qe.cost) <= qe.limit_amount THEN true
    ELSE false
  END AS allowed,
  CASE
    WHEN (qe.used_before + qe.cost) <= qe.limit_amount THEN 0
    ELSE COALESCE((SELECT retry_after_seconds FROM quota_policy), 60)
  END AS retry_after_seconds,
  CASE
    WHEN (qe.used_before + qe.cost) <= qe.limit_amount THEN ''
    ELSE 'quota limit asildi'
  END AS denial_reason
FROM quota_eval qe;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.AppID),
		strings.TrimSpace(cmd.APIKeyID),
		strings.TrimSpace(cmd.Environment),
		strings.TrimSpace(cmd.QuotaWindow),
		strings.TrimSpace(cmd.RequestID),
		cmd.Cost,
		strings.TrimSpace(cmd.RequestedBy),
	)

	var result EvaluatePublicAPIQuotaResult
	if err := row.Scan(
		&result.RequestID,
		&result.AppID,
		&result.APIKeyID,
		&result.Environment,
		&result.QuotaWindow,
		&result.Limit,
		&result.UsedBefore,
		&result.Cost,
		&result.UsedAfter,
		&result.Remaining,
		&result.RateLimitStatus,
		&result.Allowed,
		&result.RetryAfterSeconds,
		&result.DenialReason,
	); err != nil {
		return EvaluatePublicAPIQuotaResult{}, err
	}

	return result, nil
}
