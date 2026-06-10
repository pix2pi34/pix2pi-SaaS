package publicapi

import (
	"context"
	"database/sql"
	"errors"
	"strings"
)

type IssuePublicAPIKeySQLStore struct {
	db QueryRowProvider
}

func NewIssuePublicAPIKeySQLStore(db QueryRowProvider) *IssuePublicAPIKeySQLStore {
	return &IssuePublicAPIKeySQLStore{
		db: db,
	}
}

func (s *IssuePublicAPIKeySQLStore) IssueAPIKey(ctx context.Context, cmd IssuePublicAPIKeyCommand) (IssuePublicAPIKeyResult, error) {
	if s == nil || s.db == nil {
		return IssuePublicAPIKeyResult{}, errors.New("public api key issuer sql store hazir degil")
	}

	const query = `
WITH inserted_key AS (
  INSERT INTO runtime.public_api_keys (
    tenant_id,
    app_id,
    key_name,
    environment,
    scopes,
    key_prefix,
    key_hash,
    key_fingerprint,
    key_preview,
    status,
    expires_at,
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
    $7,
    $8,
    $9,
    'active',
    $10,
    $11,
    now(),
    now()
  )
  RETURNING
    api_key_id,
    app_id,
    key_name,
    environment,
    scopes,
    key_prefix,
    key_preview,
    key_fingerprint,
    status::text AS status,
    true AS issued,
    expires_at
)
SELECT
  ik.api_key_id,
  ik.app_id,
  ik.key_name,
  ik.environment,
  ik.scopes,
  ik.key_prefix,
  ik.key_preview,
  ik.key_fingerprint,
  ik.status,
  ik.issued,
  ik.expires_at
FROM inserted_key ik;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.AppID),
		strings.TrimSpace(cmd.KeyName),
		strings.TrimSpace(cmd.Environment),
		cloneStringSlice(cmd.Scopes),
		strings.TrimSpace(cmd.KeyPrefix),
		strings.TrimSpace(cmd.KeyHash),
		strings.TrimSpace(cmd.KeyFingerprint),
		strings.TrimSpace(cmd.KeyPreview),
		clonePublicAPITimePtr(cmd.ExpiresAt),
		strings.TrimSpace(cmd.RequestedBy),
	)

	var result IssuePublicAPIKeyResult
	var expiresAt sql.NullTime

	if err := row.Scan(
		&result.APIKeyID,
		&result.AppID,
		&result.KeyName,
		&result.Environment,
		&result.Scopes,
		&result.KeyPrefix,
		&result.KeyPreview,
		&result.KeyFingerprint,
		&result.Status,
		&result.Issued,
		&expiresAt,
	); err != nil {
		return IssuePublicAPIKeyResult{}, err
	}

	if expiresAt.Valid {
		t := expiresAt.Time.UTC()
		result.ExpiresAt = &t
	}

	return result, nil
}
