package plugins

import (
	"context"
	"errors"
	"strings"
)

type ApplyPluginLifecycleSQLStore struct {
	db QueryRowProvider
}

func NewApplyPluginLifecycleSQLStore(db QueryRowProvider) *ApplyPluginLifecycleSQLStore {
	return &ApplyPluginLifecycleSQLStore{
		db: db,
	}
}

func (s *ApplyPluginLifecycleSQLStore) ApplyPluginLifecycle(ctx context.Context, cmd ApplyPluginLifecycleCommand) (ApplyPluginLifecycleResult, error) {
	if s == nil || s.db == nil {
		return ApplyPluginLifecycleResult{}, errors.New("plugin lifecycle sql store hazir degil")
	}

	const query = `
WITH updated_plugin AS (
  UPDATE runtime.plugins p
  SET
    lifecycle_status = CASE
      WHEN $3 IN ('activate', 'resume') THEN 'active'
      WHEN $3 = 'deactivate' THEN 'inactive'
      WHEN $3 = 'suspend' THEN 'suspended'
      ELSE p.lifecycle_status
    END,
    runtime_enabled = CASE
      WHEN $3 IN ('activate', 'resume') THEN true
      WHEN $3 IN ('deactivate', 'suspend') THEN false
      ELSE p.runtime_enabled
    END,
    updated_at = now()
  WHERE p.plugin_key = $2
    AND (
      (NULLIF($1, '') IS NULL AND p.tenant_id IS NULL)
      OR
      (p.tenant_id::text = NULLIF($1, ''))
    )
  RETURNING
    p.plugin_key,
    $3 AS action_type,
    p.lifecycle_status::text AS lifecycle_status,
    p.runtime_enabled
)
SELECT
  up.plugin_key,
  up.action_type,
  up.lifecycle_status,
  up.runtime_enabled,
  true AS applied
FROM updated_plugin up;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.PluginKey),
		strings.TrimSpace(cmd.ActionType),
		strings.TrimSpace(cmd.RequestedBy),
		strings.TrimSpace(cmd.Reason),
	)

	var result ApplyPluginLifecycleResult
	if err := row.Scan(
		&result.PluginKey,
		&result.ActionType,
		&result.LifecycleStatus,
		&result.RuntimeEnabled,
		&result.Applied,
	); err != nil {
		return ApplyPluginLifecycleResult{}, err
	}

	return result, nil
}
