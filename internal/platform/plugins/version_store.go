package plugins

import (
	"context"
	"errors"
	"strings"
)

type CheckPluginVersionCompatibilitySQLStore struct {
	db QueryRowProvider
}

func NewCheckPluginVersionCompatibilitySQLStore(db QueryRowProvider) *CheckPluginVersionCompatibilitySQLStore {
	return &CheckPluginVersionCompatibilitySQLStore{
		db: db,
	}
}

func (s *CheckPluginVersionCompatibilitySQLStore) CheckVersionCompatibility(ctx context.Context, cmd CheckPluginVersionCompatibilityCommand) (CheckPluginVersionCompatibilityResult, error) {
	if s == nil || s.db == nil {
		return CheckPluginVersionCompatibilityResult{}, errors.New("plugin version compatibility sql store hazir degil")
	}

	const query = `
WITH matched_rule AS (
  SELECT
    pvc.plugin_key,
    pvc.plugin_version,
    pvc.runtime_mode,
    pvc.min_supported_host_version,
    pvc.max_supported_host_version
  FROM runtime.plugin_version_compatibility pvc
  WHERE pvc.plugin_key = $2
    AND pvc.plugin_version = $3
    AND pvc.runtime_mode = $4
    AND (
      (NULLIF($1, '') IS NULL AND pvc.tenant_id IS NULL)
      OR
      (pvc.tenant_id::text = NULLIF($1, ''))
    )
  ORDER BY pvc.updated_at DESC
  LIMIT 1
)
SELECT
  COALESCE(
    (SELECT plugin_key FROM matched_rule),
    $2
  ) AS plugin_key,
  COALESCE(
    (SELECT plugin_version FROM matched_rule),
    $3
  ) AS plugin_version,
  COALESCE(
    (SELECT runtime_mode FROM matched_rule),
    $4
  ) AS runtime_mode,
  $5 AS host_api_version,
  COALESCE(
    (SELECT min_supported_host_version FROM matched_rule),
    0
  ) AS min_supported_host_version,
  COALESCE(
    (SELECT max_supported_host_version FROM matched_rule),
    0
  ) AS max_supported_host_version,
  CASE
    WHEN $5 < COALESCE((SELECT min_supported_host_version FROM matched_rule), 0)
      OR $5 > COALESCE((SELECT max_supported_host_version FROM matched_rule), 0)
      THEN 'blocked'
    WHEN $5 = COALESCE((SELECT max_supported_host_version FROM matched_rule), 0)
      THEN 'warning'
    ELSE 'compatible'
  END AS compatibility_status,
  CASE
    WHEN $5 < COALESCE((SELECT min_supported_host_version FROM matched_rule), 0)
      OR $5 > COALESCE((SELECT max_supported_host_version FROM matched_rule), 0)
      THEN false
    ELSE true
  END AS compatible,
  CASE
    WHEN $5 < COALESCE((SELECT min_supported_host_version FROM matched_rule), 0)
      OR $5 > COALESCE((SELECT max_supported_host_version FROM matched_rule), 0)
      THEN 'host api surumu destek araligi disinda'
    WHEN $5 = COALESCE((SELECT max_supported_host_version FROM matched_rule), 0)
      THEN 'desteklenen ust sinirda calisiyor'
    ELSE ''
  END AS reason;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.PluginKey),
		cmd.PluginVersion,
		strings.TrimSpace(cmd.RuntimeMode),
		cmd.HostAPIVersion,
	)

	var result CheckPluginVersionCompatibilityResult
	if err := row.Scan(
		&result.PluginKey,
		&result.PluginVersion,
		&result.RuntimeMode,
		&result.HostAPIVersion,
		&result.MinSupportedHostVersion,
		&result.MaxSupportedHostVersion,
		&result.CompatibilityStatus,
		&result.Compatible,
		&result.Reason,
	); err != nil {
		return CheckPluginVersionCompatibilityResult{}, err
	}

	return result, nil
}
