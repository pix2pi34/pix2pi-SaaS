package plugins

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type pluginVersionCompatibilityRowMock struct {
	values []any
	err    error
}

func (r *pluginVersionCompatibilityRowMock) Scan(dest ...any) error {
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

type pluginVersionCompatibilityQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *pluginVersionCompatibilityQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestCheckPluginVersionCompatibilitySQLStoreCheckVersionCompatibility_Success(t *testing.T) {
	db := &pluginVersionCompatibilityQueryRowProviderMock{
		row: &pluginVersionCompatibilityRowMock{
			values: []any{
				"erp.logo_export",
				4,
				"wasm",
				4,
				3,
				5,
				"compatible",
				true,
				"",
			},
		},
	}

	store := NewCheckPluginVersionCompatibilitySQLStore(db)

	result, err := store.CheckVersionCompatibility(context.Background(), CheckPluginVersionCompatibilityCommand{
		TenantID:       "tenant-a",
		PluginKey:      "erp.logo_export",
		PluginVersion:  4,
		RuntimeMode:    "wasm",
		HostAPIVersion: 4,
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.PluginKey != "erp.logo_export" {
		t.Fatalf("beklenen plugin_key erp.logo_export, alinan: %s", result.PluginKey)
	}

	if result.PluginVersion != 4 {
		t.Fatalf("beklenen plugin_version 4, alinan: %d", result.PluginVersion)
	}

	if result.RuntimeMode != "wasm" {
		t.Fatalf("beklenen runtime_mode wasm, alinan: %s", result.RuntimeMode)
	}

	if result.HostAPIVersion != 4 {
		t.Fatalf("beklenen host_api_version 4, alinan: %d", result.HostAPIVersion)
	}

	if result.MinSupportedHostVersion != 3 || result.MaxSupportedHostVersion != 5 {
		t.Fatalf("beklenen destek araligi 3-5")
	}

	if result.CompatibilityStatus != "compatible" {
		t.Fatalf("beklenen compatibility_status compatible, alinan: %s", result.CompatibilityStatus)
	}

	if !result.Compatible {
		t.Fatalf("beklenen compatible true")
	}

	if result.Reason != "" {
		t.Fatalf("compatible durumda reason bos olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.plugin_version_compatibility") {
		t.Fatalf("plugin_version_compatibility query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "plugin_version = $3") {
		t.Fatalf("plugin_version filtresi query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime_mode = $4") {
		t.Fatalf("runtime_mode filtresi query icinde olmaliydi")
	}

	if len(db.lastArgs) != 5 {
		t.Fatalf("beklenen 5 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestCheckPluginVersionCompatibilitySQLStoreCheckVersionCompatibility_BlockedSuccess(t *testing.T) {
	db := &pluginVersionCompatibilityQueryRowProviderMock{
		row: &pluginVersionCompatibilityRowMock{
			values: []any{
				"erp.logo_export",
				4,
				"wasm",
				8,
				3,
				5,
				"blocked",
				false,
				"host api surumu destek araligi disinda",
			},
		},
	}

	store := NewCheckPluginVersionCompatibilitySQLStore(db)

	result, err := store.CheckVersionCompatibility(context.Background(), CheckPluginVersionCompatibilityCommand{
		PluginKey:      "erp.logo_export",
		PluginVersion:  4,
		RuntimeMode:    "wasm",
		HostAPIVersion: 8,
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Compatible {
		t.Fatalf("beklenen compatible false")
	}

	if result.CompatibilityStatus != "blocked" {
		t.Fatalf("beklenen compatibility_status blocked, alinan: %s", result.CompatibilityStatus)
	}

	if result.Reason == "" {
		t.Fatalf("beklenen reason dolu")
	}
}

func TestCheckPluginVersionCompatibilitySQLStoreCheckVersionCompatibility_NoDB(t *testing.T) {
	store := NewCheckPluginVersionCompatibilitySQLStore(nil)

	_, err := store.CheckVersionCompatibility(context.Background(), CheckPluginVersionCompatibilityCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestCheckPluginVersionCompatibilitySQLStoreCheckVersionCompatibility_ScanError(t *testing.T) {
	db := &pluginVersionCompatibilityQueryRowProviderMock{
		row: &pluginVersionCompatibilityRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewCheckPluginVersionCompatibilitySQLStore(db)

	_, err := store.CheckVersionCompatibility(context.Background(), CheckPluginVersionCompatibilityCommand{
		TenantID:       "tenant-a",
		PluginKey:      "erp.logo_export",
		PluginVersion:  4,
		RuntimeMode:    "wasm",
		HostAPIVersion: 5,
		RequestedBy:    "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
