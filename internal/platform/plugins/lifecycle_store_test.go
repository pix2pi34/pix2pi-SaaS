package plugins

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type pluginLifecycleRowMock struct {
	values []any
	err    error
}

func (r *pluginLifecycleRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *bool:
			*d = r.values[i].(bool)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type pluginLifecycleQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *pluginLifecycleQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestApplyPluginLifecycleSQLStoreApplyPluginLifecycle_ActivateSuccess(t *testing.T) {
	db := &pluginLifecycleQueryRowProviderMock{
		row: &pluginLifecycleRowMock{
			values: []any{
				"erp.logo_export",
				"activate",
				"active",
				true,
				true,
			},
		},
	}

	store := NewApplyPluginLifecycleSQLStore(db)

	result, err := store.ApplyPluginLifecycle(context.Background(), ApplyPluginLifecycleCommand{
		TenantID:    "tenant-a",
		PluginKey:   "erp.logo_export",
		ActionType:  "activate",
		RequestedBy: "worker-01",
		Reason:      "canliya aliniyor",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.PluginKey != "erp.logo_export" {
		t.Fatalf("beklenen plugin_key erp.logo_export, alinan: %s", result.PluginKey)
	}

	if result.ActionType != "activate" {
		t.Fatalf("beklenen action_type activate, alinan: %s", result.ActionType)
	}

	if result.LifecycleStatus != "active" {
		t.Fatalf("beklenen lifecycle_status active, alinan: %s", result.LifecycleStatus)
	}

	if !result.RuntimeEnabled {
		t.Fatalf("beklenen runtime_enabled true")
	}

	if !result.Applied {
		t.Fatalf("beklenen applied true")
	}

	if !strings.Contains(db.lastQuery, "runtime.plugins") {
		t.Fatalf("plugins query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "lifecycle_status = CASE") {
		t.Fatalf("lifecycle_status update query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime_enabled = CASE") {
		t.Fatalf("runtime_enabled update query icinde olmaliydi")
	}

	if len(db.lastArgs) != 5 {
		t.Fatalf("beklenen 5 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestApplyPluginLifecycleSQLStoreApplyPluginLifecycle_SuspendSuccess(t *testing.T) {
	db := &pluginLifecycleQueryRowProviderMock{
		row: &pluginLifecycleRowMock{
			values: []any{
				"erp.logo_export",
				"suspend",
				"suspended",
				false,
				true,
			},
		},
	}

	store := NewApplyPluginLifecycleSQLStore(db)

	result, err := store.ApplyPluginLifecycle(context.Background(), ApplyPluginLifecycleCommand{
		PluginKey:   "erp.logo_export",
		ActionType:  "suspend",
		RequestedBy: "worker-01",
		Reason:      "guvenlik incelemesi",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.LifecycleStatus != "suspended" {
		t.Fatalf("beklenen lifecycle_status suspended, alinan: %s", result.LifecycleStatus)
	}

	if result.RuntimeEnabled {
		t.Fatalf("beklenen runtime_enabled false")
	}
}

func TestApplyPluginLifecycleSQLStoreApplyPluginLifecycle_NoDB(t *testing.T) {
	store := NewApplyPluginLifecycleSQLStore(nil)

	_, err := store.ApplyPluginLifecycle(context.Background(), ApplyPluginLifecycleCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestApplyPluginLifecycleSQLStoreApplyPluginLifecycle_ScanError(t *testing.T) {
	db := &pluginLifecycleQueryRowProviderMock{
		row: &pluginLifecycleRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewApplyPluginLifecycleSQLStore(db)

	_, err := store.ApplyPluginLifecycle(context.Background(), ApplyPluginLifecycleCommand{
		TenantID:    "tenant-a",
		PluginKey:   "erp.logo_export",
		ActionType:  "activate",
		RequestedBy: "worker-01",
		Reason:      "canliya aliniyor",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
