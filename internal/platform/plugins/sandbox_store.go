package plugins

import (
	"context"
	"errors"
	"strings"
)

type EnsurePluginSandboxSQLStore struct {
	db QueryRowProvider
}

func NewEnsurePluginSandboxSQLStore(db QueryRowProvider) *EnsurePluginSandboxSQLStore {
	return &EnsurePluginSandboxSQLStore{
		db: db,
	}
}

func (s *EnsurePluginSandboxSQLStore) EnsureTenantSandbox(ctx context.Context, cmd EnsurePluginSandboxCommand) (EnsurePluginSandboxResult, error) {
	if s == nil || s.db == nil {
		return EnsurePluginSandboxResult{}, errors.New("plugin sandbox sql store hazir degil")
	}

	const query = `
WITH matched_sandbox AS (
  SELECT
    ps.plugin_key,
    ps.runtime_mode,
    ps.permission_profile,
    coalesce(ps.sandbox_id, '') AS sandbox_id,
    coalesce(ps.isolation_mode, '') AS isolation_mode,
    coalesce(ps.network_policy, '') AS network_policy,
    ps.tenant_scoped,
    ps.ready,
    coalesce(ps.denial_reason, '') AS denial_reason
  FROM runtime.plugin_sandboxes ps
  WHERE ps.plugin_key = $2
    AND ps.runtime_mode = $3
    AND ps.permission_profile = $4
    AND (
      (NULLIF($1, '') IS NULL AND ps.tenant_id IS NULL)
      OR
      (ps.tenant_id::text = NULLIF($1, ''))
    )
  ORDER BY ps.updated_at DESC
  LIMIT 1
)
SELECT
  COALESCE(
    (SELECT plugin_key FROM matched_sandbox),
    $2
  ) AS plugin_key,
  COALESCE(
    (SELECT runtime_mode FROM matched_sandbox),
    $3
  ) AS runtime_mode,
  COALESCE(
    (SELECT permission_profile FROM matched_sandbox),
    $4
  ) AS permission_profile,
  COALESCE(
    (SELECT sandbox_id FROM matched_sandbox),
    ''
  ) AS sandbox_id,
  COALESCE(
    (SELECT isolation_mode FROM matched_sandbox),
    ''
  ) AS isolation_mode,
  COALESCE(
    (SELECT network_policy FROM matched_sandbox),
    ''
  ) AS network_policy,
  COALESCE(
    (SELECT tenant_scoped FROM matched_sandbox),
    false
  ) AS tenant_scoped,
  COALESCE(
    (SELECT ready FROM matched_sandbox),
    false
  ) AS ready,
  COALESCE(
    (SELECT denial_reason FROM matched_sandbox),
    ''
  ) AS denial_reason;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.PluginKey),
		strings.TrimSpace(cmd.RuntimeMode),
		strings.TrimSpace(cmd.PermissionProfile),
	)

	var result EnsurePluginSandboxResult
	if err := row.Scan(
		&result.PluginKey,
		&result.RuntimeMode,
		&result.PermissionProfile,
		&result.SandboxID,
		&result.IsolationMode,
		&result.NetworkPolicy,
		&result.TenantScoped,
		&result.Ready,
		&result.DenialReason,
	); err != nil {
		return EnsurePluginSandboxResult{}, err
	}

	return result, nil
}
