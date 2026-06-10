package publicapi

import (
	"context"
	"errors"
	"strings"
)

type EnsurePublicAPISandboxSQLStore struct {
	db QueryRowProvider
}

func NewEnsurePublicAPISandboxSQLStore(db QueryRowProvider) *EnsurePublicAPISandboxSQLStore {
	return &EnsurePublicAPISandboxSQLStore{
		db: db,
	}
}

func (s *EnsurePublicAPISandboxSQLStore) EnsureSandbox(ctx context.Context, cmd EnsurePublicAPISandboxCommand) (EnsurePublicAPISandboxResult, error) {
	if s == nil || s.db == nil {
		return EnsurePublicAPISandboxResult{}, errors.New("public api sandbox sql store hazir degil")
	}

	baseURL := buildFallbackPublicAPISandboxBaseURL(cmd.AppID, cmd.SandboxName)

	const query = `
WITH ensured_sandbox AS (
  INSERT INTO runtime.public_api_sandboxes (
    tenant_id,
    app_id,
    environment,
    sandbox_name,
    data_mode,
    base_url,
    isolated,
    sandbox_status,
    requested_by,
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
    true,
    'ready',
    $7,
    now(),
    now()
  )
  ON CONFLICT (app_id, sandbox_name)
  DO UPDATE SET
    environment = EXCLUDED.environment,
    data_mode = EXCLUDED.data_mode,
    base_url = EXCLUDED.base_url,
    isolated = true,
    sandbox_status = 'ready',
    requested_by = EXCLUDED.requested_by,
    updated_at = now()
  RETURNING
    sandbox_id,
    app_id,
    environment,
    sandbox_name,
    data_mode,
    base_url,
    isolated,
    sandbox_status::text AS sandbox_status,
    true AS ready,
    coalesce(denial_reason, '') AS denial_reason
)
SELECT
  es.sandbox_id,
  es.app_id,
  es.environment,
  es.sandbox_name,
  es.data_mode,
  es.base_url,
  es.isolated,
  es.sandbox_status,
  es.ready,
  es.denial_reason
FROM ensured_sandbox es;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.AppID),
		strings.TrimSpace(cmd.Environment),
		strings.TrimSpace(cmd.SandboxName),
		strings.TrimSpace(cmd.DataMode),
		baseURL,
		strings.TrimSpace(cmd.RequestedBy),
	)

	var result EnsurePublicAPISandboxResult
	if err := row.Scan(
		&result.SandboxID,
		&result.AppID,
		&result.Environment,
		&result.SandboxName,
		&result.DataMode,
		&result.BaseURL,
		&result.Isolated,
		&result.SandboxStatus,
		&result.Ready,
		&result.DenialReason,
	); err != nil {
		return EnsurePublicAPISandboxResult{}, err
	}

	return result, nil
}
