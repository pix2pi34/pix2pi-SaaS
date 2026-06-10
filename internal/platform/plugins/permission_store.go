package plugins

import (
	"context"
	"errors"
	"strings"
)

type EvaluatePluginPermissionSQLStore struct {
	db QueryRowProvider
}

func NewEvaluatePluginPermissionSQLStore(db QueryRowProvider) *EvaluatePluginPermissionSQLStore {
	return &EvaluatePluginPermissionSQLStore{
		db: db,
	}
}

func (s *EvaluatePluginPermissionSQLStore) EvaluatePermission(ctx context.Context, cmd EvaluatePluginPermissionCommand) (EvaluatePluginPermissionResult, error) {
	if s == nil || s.db == nil {
		return EvaluatePluginPermissionResult{}, errors.New("plugin permission sql store hazir degil")
	}

	const query = `
WITH matched_rule AS (
  SELECT
    pp.plugin_key,
    pp.permission_profile,
    pp.operation,
    pp.resource_scope,
    pp.permitted,
    coalesce(pp.denial_reason, '') AS denial_reason
  FROM runtime.plugin_permissions pp
  WHERE pp.plugin_key = $2
    AND pp.permission_profile = $3
    AND pp.operation = $4
    AND pp.resource_scope = $5
    AND (
      (NULLIF($1, '') IS NULL AND pp.tenant_id IS NULL)
      OR
      (pp.tenant_id::text = NULLIF($1, ''))
    )
  ORDER BY pp.updated_at DESC
  LIMIT 1
)
SELECT
  COALESCE(
    (SELECT plugin_key FROM matched_rule),
    $2
  ) AS plugin_key,
  COALESCE(
    (SELECT permission_profile FROM matched_rule),
    $3
  ) AS permission_profile,
  COALESCE(
    (SELECT operation FROM matched_rule),
    $4
  ) AS operation,
  COALESCE(
    (SELECT resource_scope FROM matched_rule),
    $5
  ) AS resource_scope,
  COALESCE(
    (SELECT permitted FROM matched_rule),
    false
  ) AS permitted,
  COALESCE(
    (SELECT denial_reason FROM matched_rule),
    ''
  ) AS denial_reason;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.PluginKey),
		strings.TrimSpace(cmd.PermissionProfile),
		strings.TrimSpace(cmd.Operation),
		strings.TrimSpace(cmd.ResourceScope),
	)

	var result EvaluatePluginPermissionResult
	if err := row.Scan(
		&result.PluginKey,
		&result.PermissionProfile,
		&result.Operation,
		&result.ResourceScope,
		&result.Permitted,
		&result.DenialReason,
	); err != nil {
		return EvaluatePluginPermissionResult{}, err
	}

	return result, nil
}
