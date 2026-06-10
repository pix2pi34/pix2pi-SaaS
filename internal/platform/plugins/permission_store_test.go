package plugins

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type pluginPermissionRowMock struct {
	values []any
	err    error
}

func (r *pluginPermissionRowMock) Scan(dest ...any) error {
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

type pluginPermissionQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *pluginPermissionQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestEvaluatePluginPermissionSQLStoreEvaluatePermission_Success(t *testing.T) {
	db := &pluginPermissionQueryRowProviderMock{
		row: &pluginPermissionRowMock{
			values: []any{
				"erp.logo_export",
				"tenant_ops",
				"write",
				"tenant_runtime",
				true,
				"",
			},
		},
	}

	store := NewEvaluatePluginPermissionSQLStore(db)

	result, err := store.EvaluatePermission(context.Background(), EvaluatePluginPermissionCommand{
		TenantID:          "tenant-a",
		PluginKey:         "erp.logo_export",
		PermissionProfile: "tenant_ops",
		Operation:         "write",
		ResourceScope:     "tenant_runtime",
		RequestedBy:       "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.PluginKey != "erp.logo_export" {
		t.Fatalf("beklenen plugin_key erp.logo_export, alinan: %s", result.PluginKey)
	}

	if result.PermissionProfile != "tenant_ops" {
		t.Fatalf("beklenen permission_profile tenant_ops, alinan: %s", result.PermissionProfile)
	}

	if result.Operation != "write" {
		t.Fatalf("beklenen operation write, alinan: %s", result.Operation)
	}

	if result.ResourceScope != "tenant_runtime" {
		t.Fatalf("beklenen resource_scope tenant_runtime, alinan: %s", result.ResourceScope)
	}

	if !result.Permitted {
		t.Fatalf("beklenen permitted true")
	}

	if result.DenialReason != "" {
		t.Fatalf("izin verilen durumda denial_reason bos olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.plugin_permissions") {
		t.Fatalf("plugin_permissions query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "permission_profile = $3") {
		t.Fatalf("permission_profile filtresi query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "resource_scope = $5") {
		t.Fatalf("resource_scope filtresi query icinde olmaliydi")
	}

	if len(db.lastArgs) != 5 {
		t.Fatalf("beklenen 5 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestEvaluatePluginPermissionSQLStoreEvaluatePermission_DeniedSuccess(t *testing.T) {
	db := &pluginPermissionQueryRowProviderMock{
		row: &pluginPermissionRowMock{
			values: []any{
				"erp.logo_export",
				"read_only",
				"write",
				"tenant_data",
				false,
				"read_only profili sadece tenant_data read izni verir",
			},
		},
	}

	store := NewEvaluatePluginPermissionSQLStore(db)

	result, err := store.EvaluatePermission(context.Background(), EvaluatePluginPermissionCommand{
		PluginKey:         "erp.logo_export",
		PermissionProfile: "read_only",
		Operation:         "write",
		ResourceScope:     "tenant_data",
		RequestedBy:       "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Permitted {
		t.Fatalf("beklenen permitted false")
	}

	if result.DenialReason == "" {
		t.Fatalf("beklenen denial_reason dolu")
	}
}

func TestEvaluatePluginPermissionSQLStoreEvaluatePermission_NoDB(t *testing.T) {
	store := NewEvaluatePluginPermissionSQLStore(nil)

	_, err := store.EvaluatePermission(context.Background(), EvaluatePluginPermissionCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestEvaluatePluginPermissionSQLStoreEvaluatePermission_ScanError(t *testing.T) {
	db := &pluginPermissionQueryRowProviderMock{
		row: &pluginPermissionRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewEvaluatePluginPermissionSQLStore(db)

	_, err := store.EvaluatePermission(context.Background(), EvaluatePluginPermissionCommand{
		TenantID:          "tenant-a",
		PluginKey:         "erp.logo_export",
		PermissionProfile: "tenant_ops",
		Operation:         "write",
		ResourceScope:     "tenant_runtime",
		RequestedBy:       "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
