package plugins

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type pluginLoaderRowMock struct {
	values []any
	err    error
}

func (r *pluginLoaderRowMock) Scan(dest ...any) error {
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

type pluginLoaderQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *pluginLoaderQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestLoadPluginSQLStoreLoadPlugin_Success(t *testing.T) {
	db := &pluginLoaderQueryRowProviderMock{
		row: &pluginLoaderRowMock{
			values: []any{
				"erp.logo_export",
				2,
				"wasm",
				"logo_export_v2",
				"tenant_ops",
				true,
				true,
			},
		},
	}

	store := NewLoadPluginSQLStore(db)

	result, err := store.LoadPlugin(context.Background(), LoadPluginCommand{
		TenantID:    "tenant-a",
		PluginKey:   "erp.logo_export",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.PluginKey != "erp.logo_export" {
		t.Fatalf("beklenen plugin_key erp.logo_export, alinan: %s", result.PluginKey)
	}

	if result.Version != 2 {
		t.Fatalf("beklenen version 2, alinan: %d", result.Version)
	}

	if result.RuntimeMode != "wasm" {
		t.Fatalf("beklenen runtime_mode wasm, alinan: %s", result.RuntimeMode)
	}

	if result.EntrypointRef != "logo_export_v2" {
		t.Fatalf("beklenen entrypoint_ref logo_export_v2, alinan: %s", result.EntrypointRef)
	}

	if result.PermissionProfile != "tenant_ops" {
		t.Fatalf("beklenen permission_profile tenant_ops, alinan: %s", result.PermissionProfile)
	}

	if !result.SandboxRequired {
		t.Fatalf("beklenen sandbox_required true")
	}

	if !result.Loaded {
		t.Fatalf("beklenen loaded true")
	}

	if !strings.Contains(db.lastQuery, "runtime.plugins") {
		t.Fatalf("plugins query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "is_active = true") {
		t.Fatalf("aktif plugin filtresi query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "ORDER BY p.version DESC") {
		t.Fatalf("version desc query icinde olmaliydi")
	}

	if len(db.lastArgs) != 2 {
		t.Fatalf("beklenen 2 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestLoadPluginSQLStoreLoadPlugin_NativeSuccess(t *testing.T) {
	db := &pluginLoaderQueryRowProviderMock{
		row: &pluginLoaderRowMock{
			values: []any{
				"crm.sync_agent",
				1,
				"native",
				"crm_sync_agent",
				"system_ops",
				false,
				true,
			},
		},
	}

	store := NewLoadPluginSQLStore(db)

	result, err := store.LoadPlugin(context.Background(), LoadPluginCommand{
		PluginKey:   "crm.sync_agent",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.RuntimeMode != "native" {
		t.Fatalf("beklenen runtime_mode native, alinan: %s", result.RuntimeMode)
	}

	if result.PermissionProfile != "system_ops" {
		t.Fatalf("beklenen permission_profile system_ops, alinan: %s", result.PermissionProfile)
	}

	if result.SandboxRequired {
		t.Fatalf("beklenen sandbox_required false")
	}
}

func TestLoadPluginSQLStoreLoadPlugin_NoDB(t *testing.T) {
	store := NewLoadPluginSQLStore(nil)

	_, err := store.LoadPlugin(context.Background(), LoadPluginCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestLoadPluginSQLStoreLoadPlugin_ScanError(t *testing.T) {
	db := &pluginLoaderQueryRowProviderMock{
		row: &pluginLoaderRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewLoadPluginSQLStore(db)

	_, err := store.LoadPlugin(context.Background(), LoadPluginCommand{
		TenantID:    "tenant-a",
		PluginKey:   "erp.logo_export",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
