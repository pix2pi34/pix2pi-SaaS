package plugins

import (
	"context"
	"errors"
	"testing"
	"time"
)

type pluginPermissionStoreMock struct {
	lastCmd EvaluatePluginPermissionCommand
	result  EvaluatePluginPermissionResult
	err     error
	called  bool
}

func (m *pluginPermissionStoreMock) EvaluatePermission(_ context.Context, cmd EvaluatePluginPermissionCommand) (EvaluatePluginPermissionResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestEvaluatePluginPermissionRequestValidate_Success(t *testing.T) {
	req := EvaluatePluginPermissionRequest{
		TenantID:          "tenant-a",
		PluginKey:         "erp.logo_export",
		PermissionProfile: "tenant_ops",
		Operation:         "write",
		ResourceScope:     "tenant_runtime",
		RequestedBy:       "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestEvaluatePluginPermissionRequestValidate_InvalidOperation(t *testing.T) {
	req := EvaluatePluginPermissionRequest{
		PluginKey:         "erp.logo_export",
		PermissionProfile: "tenant_ops",
		Operation:         "delete",
		ResourceScope:     "tenant_runtime",
		RequestedBy:       "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestEvaluatePluginPermissionRequestValidate_InvalidResourceScope(t *testing.T) {
	req := EvaluatePluginPermissionRequest{
		PluginKey:         "erp.logo_export",
		PermissionProfile: "tenant_ops",
		Operation:         "write",
		ResourceScope:     "prod_db",
		RequestedBy:       "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestEvaluatePluginPermissionRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := EvaluatePluginPermissionRequest{
		PluginKey:         "erp.logo_export",
		PermissionProfile: "tenant_ops",
		Operation:         "write",
		ResourceScope:     "tenant_runtime",
		RequestedBy:       "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestEvaluatePluginPermissionUsecaseEvaluate_Success(t *testing.T) {
	store := &pluginPermissionStoreMock{
		result: EvaluatePluginPermissionResult{
			PluginKey:         "erp.logo_export",
			PermissionProfile: "tenant_ops",
			Operation:         "write",
			ResourceScope:     "tenant_runtime",
			Permitted:         true,
		},
	}

	usecase := NewEvaluatePluginPermissionUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 3, 30, 0, 0, time.UTC)
	}

	resp, err := usecase.Evaluate(context.Background(), EvaluatePluginPermissionRequest{
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

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.Operation != "write" {
		t.Fatalf("beklenen operation write, alinan: %s", store.lastCmd.Operation)
	}

	if !resp.Permitted {
		t.Fatalf("beklenen permitted true")
	}

	if resp.DenialReason != "" {
		t.Fatalf("izin verilince denial_reason bos olmaliydi")
	}

	if !resp.EvaluatedAt.Equal(time.Date(2026, 4, 26, 3, 30, 0, 0, time.UTC)) {
		t.Fatalf("beklenen evaluated_at sabit zaman")
	}
}

func TestEvaluatePluginPermissionUsecaseEvaluate_FallbackDenied(t *testing.T) {
	store := &pluginPermissionStoreMock{
		result: EvaluatePluginPermissionResult{},
	}

	usecase := NewEvaluatePluginPermissionUsecase(store)

	resp, err := usecase.Evaluate(context.Background(), EvaluatePluginPermissionRequest{
		PluginKey:         "erp.logo_export",
		PermissionProfile: "read_only",
		Operation:         "write",
		ResourceScope:     "tenant_data",
		RequestedBy:       "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Permitted {
		t.Fatalf("beklenen permitted false")
	}

	if resp.DenialReason == "" {
		t.Fatalf("beklenen denial_reason dolu")
	}
}

func TestEvaluatePluginPermissionUsecaseEvaluate_ValidationError(t *testing.T) {
	store := &pluginPermissionStoreMock{}
	usecase := NewEvaluatePluginPermissionUsecase(store)

	_, err := usecase.Evaluate(context.Background(), EvaluatePluginPermissionRequest{
		PluginKey:         "erp.logo_export",
		PermissionProfile: "tenant_ops",
		Operation:         "delete",
		ResourceScope:     "tenant_runtime",
		RequestedBy:       "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestEvaluatePluginPermissionUsecaseEvaluate_StoreError(t *testing.T) {
	store := &pluginPermissionStoreMock{
		err: errors.New("evaluate plugin permission failed"),
	}
	usecase := NewEvaluatePluginPermissionUsecase(store)

	_, err := usecase.Evaluate(context.Background(), EvaluatePluginPermissionRequest{
		PluginKey:         "erp.logo_export",
		PermissionProfile: "tenant_ops",
		Operation:         "write",
		ResourceScope:     "tenant_runtime",
		RequestedBy:       "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestEvaluatePluginPermissionResponseValidate_InvalidEvaluatedAt(t *testing.T) {
	resp := EvaluatePluginPermissionResponse{
		PluginKey:         "erp.logo_export",
		PermissionProfile: "tenant_ops",
		Operation:         "write",
		ResourceScope:     "tenant_runtime",
		Permitted:         true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
