package workflow

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type workflowDefinitionLoaderRowMock struct {
	values []any
	err    error
}

func (r *workflowDefinitionLoaderRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *int:
			*d = r.values[i].(int)
		case *bool:
			*d = r.values[i].(bool)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type workflowDefinitionLoaderQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *workflowDefinitionLoaderQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestLoadWorkflowDefinitionSQLStoreLoadDefinition_Success(t *testing.T) {
	db := &workflowDefinitionLoaderQueryRowProviderMock{
		row: &workflowDefinitionLoaderRowMock{
			values: []any{
				"purchase_approval",
				3,
				"draft",
				`[
					{"step_key":"submit-step","step_type":"task","next_on_success":"approval-step-1","requires_manual_approval":false},
					{"step_key":"approval-step-1","step_type":"approval","next_on_success":"complete-step","next_on_failure":"reject-step","requires_manual_approval":true}
				]`,
				true,
			},
		},
	}

	store := NewLoadWorkflowDefinitionSQLStore(db)

	result, err := store.LoadDefinition(context.Background(), LoadWorkflowDefinitionCommand{
		TenantID:      "tenant-a",
		DefinitionKey: "purchase_approval",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.DefinitionKey != "purchase_approval" {
		t.Fatalf("beklenen definition_key purchase_approval, alinan: %s", result.DefinitionKey)
	}

	if result.Version != 3 {
		t.Fatalf("beklenen version 3, alinan: %d", result.Version)
	}

	if result.InitialState != "draft" {
		t.Fatalf("beklenen initial_state draft, alinan: %s", result.InitialState)
	}

	if !result.Loaded {
		t.Fatalf("beklenen loaded true")
	}

	if len(result.Steps) != 2 {
		t.Fatalf("beklenen 2 step, alinan: %d", len(result.Steps))
	}

	if result.Steps[1].StepType != "approval" {
		t.Fatalf("beklenen ikinci step approval, alinan: %s", result.Steps[1].StepType)
	}

	if !strings.Contains(db.lastQuery, "runtime.workflow_definitions") {
		t.Fatalf("workflow_definitions query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "is_active = true") {
		t.Fatalf("aktif definition filtresi query icinde olmaliydi")
	}

	if len(db.lastArgs) != 2 {
		t.Fatalf("beklenen 2 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestLoadWorkflowDefinitionSQLStoreLoadDefinition_EmptyStepsJSONSuccess(t *testing.T) {
	db := &workflowDefinitionLoaderQueryRowProviderMock{
		row: &workflowDefinitionLoaderRowMock{
			values: []any{
				"simple_flow",
				1,
				"draft",
				"[]",
				true,
			},
		},
	}

	store := NewLoadWorkflowDefinitionSQLStore(db)

	result, err := store.LoadDefinition(context.Background(), LoadWorkflowDefinitionCommand{
		DefinitionKey: "simple_flow",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if len(result.Steps) != 0 {
		t.Fatalf("beklenen 0 step, alinan: %d", len(result.Steps))
	}
}

func TestLoadWorkflowDefinitionSQLStoreLoadDefinition_InvalidJSON(t *testing.T) {
	db := &workflowDefinitionLoaderQueryRowProviderMock{
		row: &workflowDefinitionLoaderRowMock{
			values: []any{
				"broken_flow",
				1,
				"draft",
				"{invalid-json}",
				true,
			},
		},
	}

	store := NewLoadWorkflowDefinitionSQLStore(db)

	_, err := store.LoadDefinition(context.Background(), LoadWorkflowDefinitionCommand{
		DefinitionKey: "broken_flow",
		RequestedBy:   "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen json parse hatasi")
	}
}

func TestLoadWorkflowDefinitionSQLStoreLoadDefinition_NoDB(t *testing.T) {
	store := NewLoadWorkflowDefinitionSQLStore(nil)

	_, err := store.LoadDefinition(context.Background(), LoadWorkflowDefinitionCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestLoadWorkflowDefinitionSQLStoreLoadDefinition_ScanError(t *testing.T) {
	db := &workflowDefinitionLoaderQueryRowProviderMock{
		row: &workflowDefinitionLoaderRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewLoadWorkflowDefinitionSQLStore(db)

	_, err := store.LoadDefinition(context.Background(), LoadWorkflowDefinitionCommand{
		TenantID:      "tenant-a",
		DefinitionKey: "purchase_approval",
		RequestedBy:   "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
