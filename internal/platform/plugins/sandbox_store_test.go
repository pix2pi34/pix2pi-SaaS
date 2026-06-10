package plugins

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type pluginSandboxRowMock struct {
	values []any
	err    error
}

func (r *pluginSandboxRowMock) Scan(dest ...any) error {
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

type pluginSandboxQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *pluginSandboxQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestEnsurePluginSandboxSQLStoreEnsureTenantSandbox_Success(t *testing.T) {
	db := &pluginSandboxQueryRowProviderMock{
		row: &pluginSandboxRowMock{
			values: []any{
				"erp.logo_export",
				"wasm",
				"tenant_ops",
				"erp.logo_export_sandbox",
				"tenant_process",
				"disabled",
				true,
				true,
				"",
			},
		},
	}

	store := NewEnsurePluginSandboxSQLStore(db)

	result, err := store.EnsureTenantSandbox(context.Background(), EnsurePluginSandboxCommand{
		TenantID:          "tenant-a",
		PluginKey:         "erp.logo_export",
		RuntimeMode:       "wasm",
		PermissionProfile: "tenant_ops",
		RequestedBy:       "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.PluginKey != "erp.logo_export" {
		t.Fatalf("beklenen plugin_key erp.logo_export, alinan: %s", result.PluginKey)
	}

	if result.RuntimeMode != "wasm" {
		t.Fatalf("beklenen runtime_mode wasm, alinan: %s", result.RuntimeMode)
	}

	if result.PermissionProfile != "tenant_ops" {
		t.Fatalf("beklenen permission_profile tenant_ops, alinan: %s", result.PermissionProfile)
	}

	if result.SandboxID != "erp.logo_export_sandbox" {
		t.Fatalf("beklenen sandbox_id erp.logo_export_sandbox, alinan: %s", result.SandboxID)
	}

	if result.IsolationMode != "tenant_process" {
		t.Fatalf("beklenen isolation_mode tenant_process, alinan: %s", result.IsolationMode)
	}

	if result.NetworkPolicy != "disabled" {
		t.Fatalf("beklenen network_policy disabled, alinan: %s", result.NetworkPolicy)
	}

	if !result.TenantScoped {
		t.Fatalf("beklenen tenant_scoped true")
	}

	if !result.Ready {
		t.Fatalf("beklenen ready true")
	}

	if result.DenialReason != "" {
		t.Fatalf("ready durumda denial_reason bos olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.plugin_sandboxes") {
		t.Fatalf("plugin_sandboxes query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime_mode = $3") {
		t.Fatalf("runtime_mode filtresi query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "permission_profile = $4") {
		t.Fatalf("permission_profile filtresi query icinde olmaliydi")
	}

	if len(db.lastArgs) != 4 {
		t.Fatalf("beklenen 4 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestEnsurePluginSandboxSQLStoreEnsureTenantSandbox_DeniedSuccess(t *testing.T) {
	db := &pluginSandboxQueryRowProviderMock{
		row: &pluginSandboxRowMock{
			values: []any{
				"crm.sync_agent",
				"native",
				"system_ops",
				"",
				"",
				"",
				false,
				false,
				"system_ops native plugin tenant-safe sandbox zorunlulugunu karsilamiyor",
			},
		},
	}

	store := NewEnsurePluginSandboxSQLStore(db)

	result, err := store.EnsureTenantSandbox(context.Background(), EnsurePluginSandboxCommand{
		PluginKey:         "crm.sync_agent",
		RuntimeMode:       "native",
		PermissionProfile: "system_ops",
		RequestedBy:       "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Ready {
		t.Fatalf("beklenen ready false")
	}

	if result.DenialReason == "" {
		t.Fatalf("beklenen denial_reason dolu")
	}
}

func TestEnsurePluginSandboxSQLStoreEnsureTenantSandbox_NoDB(t *testing.T) {
	store := NewEnsurePluginSandboxSQLStore(nil)

	_, err := store.EnsureTenantSandbox(context.Background(), EnsurePluginSandboxCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestEnsurePluginSandboxSQLStoreEnsureTenantSandbox_ScanError(t *testing.T) {
	db := &pluginSandboxQueryRowProviderMock{
		row: &pluginSandboxRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewEnsurePluginSandboxSQLStore(db)

	_, err := store.EnsureTenantSandbox(context.Background(), EnsurePluginSandboxCommand{
		TenantID:          "tenant-a",
		PluginKey:         "erp.logo_export",
		RuntimeMode:       "wasm",
		PermissionProfile: "tenant_ops",
		RequestedBy:       "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
