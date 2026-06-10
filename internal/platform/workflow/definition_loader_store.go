package workflow

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
)

type LoadWorkflowDefinitionSQLStore struct {
	db QueryRowProvider
}

func NewLoadWorkflowDefinitionSQLStore(db QueryRowProvider) *LoadWorkflowDefinitionSQLStore {
	return &LoadWorkflowDefinitionSQLStore{
		db: db,
	}
}

func (s *LoadWorkflowDefinitionSQLStore) LoadDefinition(ctx context.Context, cmd LoadWorkflowDefinitionCommand) (LoadWorkflowDefinitionResult, error) {
	if s == nil || s.db == nil {
		return LoadWorkflowDefinitionResult{}, errors.New("workflow definition loader sql store hazir degil")
	}

	const query = `
SELECT
  wd.definition_key,
  wd.version,
  wd.initial_state,
  COALESCE(wd.steps_json, '[]') AS steps_json,
  true AS loaded
FROM runtime.workflow_definitions wd
WHERE wd.definition_key = $2
  AND wd.is_active = true
  AND (
    (NULLIF($1, '') IS NULL AND wd.tenant_id IS NULL)
    OR
    (wd.tenant_id::text = NULLIF($1, ''))
  )
ORDER BY wd.version DESC
LIMIT 1;
`

	row := s.db.QueryRowContext(
		ctx,
		query,
		strings.TrimSpace(cmd.TenantID),
		strings.TrimSpace(cmd.DefinitionKey),
	)

	var result LoadWorkflowDefinitionResult
	var stepsJSON string
	var loaded bool

	if err := row.Scan(
		&result.DefinitionKey,
		&result.Version,
		&result.InitialState,
		&stepsJSON,
		&loaded,
	); err != nil {
		return LoadWorkflowDefinitionResult{}, err
	}

	result.Loaded = loaded
	result.Steps = []WorkflowDefinitionStep{}

	if strings.TrimSpace(stepsJSON) != "" {
		if err := json.Unmarshal([]byte(stepsJSON), &result.Steps); err != nil {
			return LoadWorkflowDefinitionResult{}, err
		}
	}

	return result, nil
}
