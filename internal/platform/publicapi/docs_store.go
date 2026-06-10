package publicapi

import (
	"context"
	"errors"
	"strings"
)

type PublishDeveloperDocsSQLStore struct {
	db QueryRowProvider
}

func NewPublishDeveloperDocsSQLStore(db QueryRowProvider) *PublishDeveloperDocsSQLStore {
	return &PublishDeveloperDocsSQLStore{
		db: db,
	}
}

func (s *PublishDeveloperDocsSQLStore) PublishDocs(ctx context.Context, cmd PublishDeveloperDocsCommand) (PublishDeveloperDocsResult, error) {
	if s == nil || s.db == nil {
		return PublishDeveloperDocsResult{}, errors.New("public api docs publisher sql store hazir degil")
	}

	publicURL := buildFallbackPublicAPIDocsURL(cmd.Environment, cmd.TargetPath)

	const query = `
WITH published_docs AS (
  INSERT INTO runtime.public_api_docs (
    tenant_id,
    app_id,
    docs_version,
    environment,
    docs_format,
    source_ref,
    target_path,
    public_url,
    publish_status,
    published,
    denial_reason,
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
    'published',
    true,
    '',
    $9,
    now(),
    now()
  )
  ON CONFLICT (app_id, docs_version, environment, docs_format)
  DO UPDATE SET
    source_ref = EXCLUDED.source_ref,
    target_path = EXCLUDED.target_path,
    public_url = EXCLUDED.public_url,
    publish_status = 'published',
    published = true,
    denial_reason = '',
    requested_by = EXCLUDED.requested_by,
    updated_at = now()
  RETURNING
    docs_id,
    app_id,
    docs_version,
    environment,
    docs_format,
    source_ref,
    target_path,
    public_url,
    publish_status::text AS publish_status,
    published,
    coalesce(denial_reason, '') AS denial_reason
)
SELECT
  pd.docs_id,
  pd.app_id,
  pd.docs_version,
  pd.environment,
  pd.docs_format,
  pd.source_ref,
  pd.target_path,
  pd.public_url,
  pd.publish_status,
  pd.published,
  pd.denial_reason
FROM published_docs pd;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.AppID),
		strings.TrimSpace(cmd.DocsVersion),
		strings.TrimSpace(cmd.Environment),
		strings.TrimSpace(cmd.DocsFormat),
		strings.TrimSpace(cmd.SourceRef),
		normalizePublicAPIPath(cmd.TargetPath),
		publicURL,
		strings.TrimSpace(cmd.RequestedBy),
	)

	var result PublishDeveloperDocsResult
	if err := row.Scan(
		&result.DocsID,
		&result.AppID,
		&result.DocsVersion,
		&result.Environment,
		&result.DocsFormat,
		&result.SourceRef,
		&result.TargetPath,
		&result.PublicURL,
		&result.PublishStatus,
		&result.Published,
		&result.DenialReason,
	); err != nil {
		return PublishDeveloperDocsResult{}, err
	}

	return result, nil
}
