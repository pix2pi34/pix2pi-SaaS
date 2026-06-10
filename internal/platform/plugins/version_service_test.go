package plugins

import (
	"context"
	"errors"
	"testing"
	"time"
)

type pluginVersionCompatibilityStoreMock struct {
	lastCmd CheckPluginVersionCompatibilityCommand
	result  CheckPluginVersionCompatibilityResult
	err     error
	called  bool
}

func (m *pluginVersionCompatibilityStoreMock) CheckVersionCompatibility(_ context.Context, cmd CheckPluginVersionCompatibilityCommand) (CheckPluginVersionCompatibilityResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestCheckPluginVersionCompatibilityRequestValidate_Success(t *testing.T) {
	req := CheckPluginVersionCompatibilityRequest{
		TenantID:       "tenant-a",
		PluginKey:      "erp.logo_export",
		PluginVersion:  4,
		RuntimeMode:    "wasm",
		HostAPIVersion: 5,
		RequestedBy:    "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestCheckPluginVersionCompatibilityRequestValidate_InvalidPluginVersion(t *testing.T) {
	req := CheckPluginVersionCompatibilityRequest{
		PluginKey:      "erp.logo_export",
		PluginVersion:  0,
		RuntimeMode:    "wasm",
		HostAPIVersion: 5,
		RequestedBy:    "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCheckPluginVersionCompatibilityRequestValidate_InvalidRuntimeMode(t *testing.T) {
	req := CheckPluginVersionCompatibilityRequest{
		PluginKey:      "erp.logo_export",
		PluginVersion:  4,
		RuntimeMode:    "container",
		HostAPIVersion: 5,
		RequestedBy:    "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCheckPluginVersionCompatibilityRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := CheckPluginVersionCompatibilityRequest{
		PluginKey:      "erp.logo_export",
		PluginVersion:  4,
		RuntimeMode:    "wasm",
		HostAPIVersion: 5,
		RequestedBy:    "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCheckPluginVersionCompatibilityUsecaseCheck_Success(t *testing.T) {
	store := &pluginVersionCompatibilityStoreMock{
		result: CheckPluginVersionCompatibilityResult{
			PluginKey:               "erp.logo_export",
			PluginVersion:           4,
			RuntimeMode:             "wasm",
			HostAPIVersion:          5,
			MinSupportedHostVersion: 3,
			MaxSupportedHostVersion: 5,
			CompatibilityStatus:     "compatible",
			Compatible:              true,
		},
	}

	usecase := NewCheckPluginVersionCompatibilityUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 4, 30, 0, 0, time.UTC)
	}

	resp, err := usecase.Check(context.Background(), CheckPluginVersionCompatibilityRequest{
		TenantID:       "tenant-a",
		PluginKey:      "erp.logo_export",
		PluginVersion:  4,
		RuntimeMode:    "wasm",
		HostAPIVersion: 5,
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.HostAPIVersion != 5 {
		t.Fatalf("beklenen host_api_version 5, alinan: %d", store.lastCmd.HostAPIVersion)
	}

	if !resp.Compatible {
		t.Fatalf("beklenen compatible true")
	}

	if resp.CompatibilityStatus != "compatible" {
		t.Fatalf("beklenen compatibility_status compatible, alinan: %s", resp.CompatibilityStatus)
	}

	if resp.MinSupportedHostVersion != 3 || resp.MaxSupportedHostVersion != 5 {
		t.Fatalf("beklenen destek araligi 3-5")
	}

	if !resp.CheckedAt.Equal(time.Date(2026, 4, 26, 4, 30, 0, 0, time.UTC)) {
		t.Fatalf("beklenen checked_at sabit zaman")
	}
}

func TestCheckPluginVersionCompatibilityUsecaseCheck_FallbackWarning(t *testing.T) {
	store := &pluginVersionCompatibilityStoreMock{
		result: CheckPluginVersionCompatibilityResult{},
	}

	usecase := NewCheckPluginVersionCompatibilityUsecase(store)

	resp, err := usecase.Check(context.Background(), CheckPluginVersionCompatibilityRequest{
		PluginKey:      "erp.logo_export",
		PluginVersion:  4,
		RuntimeMode:    "wasm",
		HostAPIVersion: 5,
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !resp.Compatible {
		t.Fatalf("beklenen compatible true")
	}

	if resp.CompatibilityStatus != "warning" {
		t.Fatalf("beklenen compatibility_status warning, alinan: %s", resp.CompatibilityStatus)
	}
}

func TestCheckPluginVersionCompatibilityUsecaseCheck_ValidationError(t *testing.T) {
	store := &pluginVersionCompatibilityStoreMock{}
	usecase := NewCheckPluginVersionCompatibilityUsecase(store)

	_, err := usecase.Check(context.Background(), CheckPluginVersionCompatibilityRequest{
		PluginKey:      "erp.logo_export",
		PluginVersion:  0,
		RuntimeMode:    "wasm",
		HostAPIVersion: 5,
		RequestedBy:    "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestCheckPluginVersionCompatibilityUsecaseCheck_StoreError(t *testing.T) {
	store := &pluginVersionCompatibilityStoreMock{
		err: errors.New("check plugin version compatibility failed"),
	}
	usecase := NewCheckPluginVersionCompatibilityUsecase(store)

	_, err := usecase.Check(context.Background(), CheckPluginVersionCompatibilityRequest{
		PluginKey:      "erp.logo_export",
		PluginVersion:  4,
		RuntimeMode:    "wasm",
		HostAPIVersion: 5,
		RequestedBy:    "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestCheckPluginVersionCompatibilityResponseValidate_InvalidCheckedAt(t *testing.T) {
	resp := CheckPluginVersionCompatibilityResponse{
		PluginKey:               "erp.logo_export",
		PluginVersion:           4,
		RuntimeMode:             "wasm",
		HostAPIVersion:          5,
		MinSupportedHostVersion: 3,
		MaxSupportedHostVersion: 5,
		CompatibilityStatus:     "compatible",
		Compatible:              true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
