package plugins

import (
	"context"
	"errors"
	"strings"
)

type LoadPluginSQLStore struct {
	db QueryRowProvider
}

func NewLoadPluginSQLStore(db QueryRowProvider) *LoadPluginSQLStore {
	return &LoadPluginSQLStore{
		db: db,
	}
}

func (s *LoadPluginSQLStore) LoadPlugin(ctx context.Context, cmd LoadPluginCommand) (LoadPluginResult, error) {
	if s == nil || s.db == nil {
		return LoadPluginResult{}, errors.New("plugin loader sql store hazir degil")
	}

	const query = `
SELECT
  p.plugin_key,
  p.version,
  p.runtime_mode,
  p.entrypoint_ref,
  p.permission_profile,
  p.sandbox_required,
  true AS loaded
FROM runtime.plugins p
WHERE p.plugin_key = $2
  AND p.is_active = true
  AND (
    (NULLIF($1, '') IS NULL AND p.tenant_id IS NULL)
    OR
    (p.tenant_id::text = NULLIF($1, ''))
  )
ORDER BY p.version DESC
LIMIT 1;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.PluginKey),
	)

	var result LoadPluginResult
	if err := row.Scan(
		&result.PluginKey,
		&result.Version,
		&result.RuntimeMode,
		&result.EntrypointRef,
		&result.PermissionProfile,
		&result.SandboxRequired,
		&result.Loaded,
	); err != nil {
		return LoadPluginResult{}, err
	}

	return result, nil
}
