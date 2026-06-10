package publicapi

import (
	"context"
	"errors"
	"strings"
)

type AuthenticatePublicAPIAppSQLStore struct {
	db QueryRowProvider
}

func NewAuthenticatePublicAPIAppSQLStore(db QueryRowProvider) *AuthenticatePublicAPIAppSQLStore {
	return &AuthenticatePublicAPIAppSQLStore{
		db: db,
	}
}

func (s *AuthenticatePublicAPIAppSQLStore) AuthenticateApp(ctx context.Context, cmd AuthenticatePublicAPIAppCommand) (AuthenticatePublicAPIAppResult, error) {
	if s == nil || s.db == nil {
		return AuthenticatePublicAPIAppResult{}, errors.New("public api app auth sql store hazir degil")
	}

	const query = `
WITH matched_key AS (
  SELECT
    pak.app_id,
    pak.api_key_id,
    pak.environment,
    pak.scopes,
    pak.status,
    pak.expires_at
  FROM runtime.public_api_keys pak
  WHERE pak.app_id = $2
    AND pak.api_key_id = $3
    AND pak.key_fingerprint = $4
    AND pak.environment = $5
    AND (
      (NULLIF($1, '') IS NULL AND pak.tenant_id IS NULL)
      OR
      (pak.tenant_id::text = NULLIF($1, ''))
    )
  ORDER BY pak.updated_at DESC
  LIMIT 1
),
auth_result AS (
  SELECT
    $6::text AS request_id,
    COALESCE((SELECT app_id FROM matched_key), $2) AS app_id,
    COALESCE((SELECT api_key_id FROM matched_key), $3) AS api_key_id,
    COALESCE((SELECT environment FROM matched_key), $5) AS environment,
    COALESCE((SELECT scopes FROM matched_key), $7) AS granted_scopes,
    CASE
      WHEN NOT EXISTS (SELECT 1 FROM matched_key) THEN 'denied'
      WHEN (SELECT status FROM matched_key) <> 'active' THEN 'denied'
      WHEN (SELECT expires_at FROM matched_key) IS NOT NULL
        AND (SELECT expires_at FROM matched_key) < now() THEN 'denied'
      WHEN NOT ($7 <@ (SELECT scopes FROM matched_key)) THEN 'denied'
      ELSE 'authenticated'
    END AS auth_status,
    CASE
      WHEN NOT EXISTS (SELECT 1 FROM matched_key) THEN false
      WHEN (SELECT status FROM matched_key) <> 'active' THEN false
      WHEN (SELECT expires_at FROM matched_key) IS NOT NULL
        AND (SELECT expires_at FROM matched_key) < now() THEN false
      WHEN NOT ($7 <@ (SELECT scopes FROM matched_key)) THEN false
      ELSE true
    END AS authenticated,
    CASE
      WHEN NOT EXISTS (SELECT 1 FROM matched_key) THEN 'api key bulunamadi'
      WHEN (SELECT status FROM matched_key) <> 'active' THEN 'api key aktif degil'
      WHEN (SELECT expires_at FROM matched_key) IS NOT NULL
        AND (SELECT expires_at FROM matched_key) < now() THEN 'api key suresi dolmus'
      WHEN NOT ($7 <@ (SELECT scopes FROM matched_key)) THEN 'scope yetkisi yok'
      ELSE ''
    END AS denial_reason
)
SELECT
  ar.request_id,
  ar.app_id,
  ar.api_key_id,
  ar.environment,
  ar.granted_scopes,
  ar.auth_status,
  ar.authenticated,
  ar.denial_reason
FROM auth_result ar;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.AppID),
		strings.TrimSpace(cmd.APIKeyID),
		strings.TrimSpace(cmd.KeyFingerprint),
		strings.TrimSpace(cmd.Environment),
		strings.TrimSpace(cmd.RequestID),
		cloneStringSlice(cmd.RequiredScopes),
		strings.TrimSpace(cmd.RequestedBy),
	)

	var result AuthenticatePublicAPIAppResult
	if err := row.Scan(
		&result.RequestID,
		&result.AppID,
		&result.APIKeyID,
		&result.Environment,
		&result.GrantedScopes,
		&result.AuthStatus,
		&result.Authenticated,
		&result.DenialReason,
	); err != nil {
		return AuthenticatePublicAPIAppResult{}, err
	}

	return result, nil
}
