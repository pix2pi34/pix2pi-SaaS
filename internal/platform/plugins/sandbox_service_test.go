package plugins

import (
	"context"
	"errors"
	"testing"
	"time"
)

type pluginSandboxStoreMock struct {
	lastCmd EnsurePluginSandboxCommand
	result  EnsurePluginSandboxResult
	err     error
	called  bool
}

func (m *pluginSandboxStoreMock) EnsureTenantSandbox(_ context.Context, cmd EnsurePluginSandboxCommand) (EnsurePluginSandboxResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestEnsurePluginSandboxRequestValidate_Success(t *testing.T) {
	req := EnsurePluginSandboxRequest{
		TenantID:          "tenant-a",
		PluginKey:         "erp.logo_export",
		RuntimeMode:       "wasm",
		PermissionProfile: "tenant_ops",
		RequestedBy:       "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestEnsurePluginSandboxRequestValidate_InvalidRuntimeMode(t *testing.T) {
	req := EnsurePluginSandboxRequest{
		PluginKey:         "erp.logo_export",
		RuntimeMode:       "container",
		PermissionProfile: "tenant_ops",
		RequestedBy:       "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestEnsurePluginSandboxRequestValidate_InvalidPermissionProfile(t *testing.T) {
	req := EnsurePluginSandboxRequest{
		PluginKey:         "erp.logo_export",
		RuntimeMode:       "wasm",
		PermissionProfile: "full_access",
		RequestedBy:       "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestEnsurePluginSandboxRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := EnsurePluginSandboxRequest{
		PluginKey:         "erp.logo_export",
		RuntimeMode:       "wasm",
		PermissionProfile: "tenant_ops",
		RequestedBy:       "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestEnsurePluginSandboxUsecaseEnsure_Success(t *testing.T) {
	store := &pluginSandboxStoreMock{
		result: EnsurePluginSandboxResult{
			PluginKey:         "erp.logo_export",
			RuntimeMode:       "wasm",
			PermissionProfile: "tenant_ops",
			SandboxID:         "erp.logo_export_sandbox",
			IsolationMode:     "tenant_process",
			NetworkPolicy:     "disabled",
			TenantScoped:      true,
			Ready:             true,
		},
	}

	usecase := NewEnsurePluginSandboxUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 4, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Ensure(context.Background(), EnsurePluginSandboxRequest{
		TenantID:          "tenant-a",
		PluginKey:         "erp.logo_export",
		RuntimeMode:       "wasm",
		PermissionProfile: "tenant_ops",
		RequestedBy:       "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.RuntimeMode != "wasm" {
		t.Fatalf("beklenen runtime_mode wasm, alinan: %s", store.lastCmd.RuntimeMode)
	}

	if !resp.Ready {
		t.Fatalf("beklenen ready true")
	}

	if resp.IsolationMode != "tenant_process" {
		t.Fatalf("beklenen isolation_mode tenant_process, alinan: %s", resp.IsolationMode)
	}

	if resp.NetworkPolicy != "disabled" {
		t.Fatalf("beklenen network_policy disabled, alinan: %s", resp.NetworkPolicy)
	}

	if !resp.CheckedAt.Equal(time.Date(2026, 4, 26, 4, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen checked_at sabit zaman")
	}
}

func TestEnsurePluginSandboxUsecaseEnsure_FallbackDenied(t *testing.T) {
	store := &pluginSandboxStoreMock{
		result: EnsurePluginSandboxResult{},
	}

	usecase := NewEnsurePluginSandboxUsecase(store)

	resp, err := usecase.Ensure(context.Background(), EnsurePluginSandboxRequest{
		PluginKey:         "crm.sync_agent",
		RuntimeMode:       "native",
		PermissionProfile: "system_ops",
		RequestedBy:       "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Ready {
		t.Fatalf("beklenen ready false")
	}

	if resp.DenialReason == "" {
		t.Fatalf("beklenen denial_reason dolu")
	}
}

func TestEnsurePluginSandboxUsecaseEnsure_ValidationError(t *testing.T) {
	store := &pluginSandboxStoreMock{}
	usecase := NewEnsurePluginSandboxUsecase(store)

	_, err := usecase.Ensure(context.Background(), EnsurePluginSandboxRequest{
		PluginKey:         "erp.logo_export",
		RuntimeMode:       "container",
		PermissionProfile: "tenant_ops",
		RequestedBy:       "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestEnsurePluginSandboxUsecaseEnsure_StoreError(t *testing.T) {
	store := &pluginSandboxStoreMock{
		err: errors.New("ensure plugin sandbox failed"),
	}
	usecase := NewEnsurePluginSandboxUsecase(store)

	_, err := usecase.Ensure(context.Background(), EnsurePluginSandboxRequest{
		PluginKey:         "erp.logo_export",
		RuntimeMode:       "wasm",
		PermissionProfile: "tenant_ops",
		RequestedBy:       "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestEnsurePluginSandboxResponseValidate_InvalidCheckedAt(t *testing.T) {
	resp := EnsurePluginSandboxResponse{
		PluginKey:         "erp.logo_export",
		RuntimeMode:       "wasm",
		PermissionProfile: "tenant_ops",
		SandboxID:         "erp.logo_export_sandbox",
		IsolationMode:     "tenant_process",
		NetworkPolicy:     "disabled",
		TenantScoped:      true,
		Ready:             true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
