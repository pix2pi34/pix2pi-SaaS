package plugins

import (
	"context"
	"errors"
	"testing"
	"time"
)

type pluginLoaderStoreMock struct {
	lastCmd LoadPluginCommand
	result  LoadPluginResult
	err     error
	called  bool
}

func (m *pluginLoaderStoreMock) LoadPlugin(_ context.Context, cmd LoadPluginCommand) (LoadPluginResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestLoadPluginRequestValidate_Success(t *testing.T) {
	req := LoadPluginRequest{
		TenantID:    "tenant-a",
		PluginKey:   "erp.logo_export",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestLoadPluginRequestValidate_InvalidPluginKey(t *testing.T) {
	req := LoadPluginRequest{
		PluginKey:   "erp logo export",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestLoadPluginRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := LoadPluginRequest{
		PluginKey:   "erp.logo_export",
		RequestedBy: "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestLoadPluginUsecaseLoad_Success(t *testing.T) {
	store := &pluginLoaderStoreMock{
		result: LoadPluginResult{
			PluginKey:         "erp.logo_export",
			Version:           2,
			RuntimeMode:       "wasm",
			EntrypointRef:     "logo_export_v2",
			PermissionProfile: "tenant_ops",
			SandboxRequired:   true,
			Loaded:            true,
		},
	}

	usecase := NewLoadPluginUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 2, 30, 0, 0, time.UTC)
	}

	resp, err := usecase.Load(context.Background(), LoadPluginRequest{
		TenantID:    "tenant-a",
		PluginKey:   "erp.logo_export",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.PluginKey != "erp.logo_export" {
		t.Fatalf("beklenen plugin_key erp.logo_export, alinan: %s", store.lastCmd.PluginKey)
	}

	if !resp.Loaded {
		t.Fatalf("beklenen loaded true")
	}

	if resp.RuntimeMode != "wasm" {
		t.Fatalf("beklenen runtime_mode wasm, alinan: %s", resp.RuntimeMode)
	}

	if resp.PermissionProfile != "tenant_ops" {
		t.Fatalf("beklenen permission_profile tenant_ops, alinan: %s", resp.PermissionProfile)
	}

	if !resp.SandboxRequired {
		t.Fatalf("beklenen sandbox_required true")
	}

	if !resp.LoadedAt.Equal(time.Date(2026, 4, 26, 2, 30, 0, 0, time.UTC)) {
		t.Fatalf("beklenen loaded_at sabit zaman")
	}
}

func TestLoadPluginUsecaseLoad_NotFoundSuccess(t *testing.T) {
	store := &pluginLoaderStoreMock{
		result: LoadPluginResult{
			PluginKey: "erp.logo_export",
			Loaded:    false,
		},
	}

	usecase := NewLoadPluginUsecase(store)

	resp, err := usecase.Load(context.Background(), LoadPluginRequest{
		PluginKey:   "erp.logo_export",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Loaded {
		t.Fatalf("beklenen loaded false")
	}
}

func TestLoadPluginUsecaseLoad_ValidationError(t *testing.T) {
	store := &pluginLoaderStoreMock{}
	usecase := NewLoadPluginUsecase(store)

	_, err := usecase.Load(context.Background(), LoadPluginRequest{
		PluginKey:   "erp logo export",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestLoadPluginUsecaseLoad_StoreError(t *testing.T) {
	store := &pluginLoaderStoreMock{
		err: errors.New("load plugin failed"),
	}
	usecase := NewLoadPluginUsecase(store)

	_, err := usecase.Load(context.Background(), LoadPluginRequest{
		PluginKey:   "erp.logo_export",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestLoadPluginResponseValidate_InvalidLoadedAt(t *testing.T) {
	resp := LoadPluginResponse{
		PluginKey: "erp.logo_export",
		Loaded:    false,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
