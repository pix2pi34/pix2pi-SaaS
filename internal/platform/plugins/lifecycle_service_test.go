package plugins

import (
	"context"
	"errors"
	"testing"
	"time"
)

type pluginLifecycleStoreMock struct {
	lastCmd ApplyPluginLifecycleCommand
	result  ApplyPluginLifecycleResult
	err     error
	called  bool
}

func (m *pluginLifecycleStoreMock) ApplyPluginLifecycle(_ context.Context, cmd ApplyPluginLifecycleCommand) (ApplyPluginLifecycleResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestApplyPluginLifecycleRequestValidate_Success(t *testing.T) {
	req := ApplyPluginLifecycleRequest{
		TenantID:    "tenant-a",
		PluginKey:   "erp.logo_export",
		ActionType:  "activate",
		RequestedBy: "worker-01",
		Reason:      "canliya aliniyor",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestApplyPluginLifecycleRequestValidate_InvalidPluginKey(t *testing.T) {
	req := ApplyPluginLifecycleRequest{
		PluginKey:   "erp logo export",
		ActionType:  "activate",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyPluginLifecycleRequestValidate_InvalidActionType(t *testing.T) {
	req := ApplyPluginLifecycleRequest{
		PluginKey:   "erp.logo_export",
		ActionType:  "enable",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyPluginLifecycleRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := ApplyPluginLifecycleRequest{
		PluginKey:   "erp.logo_export",
		ActionType:  "activate",
		RequestedBy: "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyPluginLifecycleUsecaseApply_ActivateSuccess(t *testing.T) {
	store := &pluginLifecycleStoreMock{
		result: ApplyPluginLifecycleResult{
			PluginKey:       "erp.logo_export",
			ActionType:      "activate",
			LifecycleStatus: "active",
			RuntimeEnabled:  true,
			Applied:         true,
		},
	}

	usecase := NewApplyPluginLifecycleUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 3, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Apply(context.Background(), ApplyPluginLifecycleRequest{
		TenantID:    "tenant-a",
		PluginKey:   "erp.logo_export",
		ActionType:  "activate",
		RequestedBy: "worker-01",
		Reason:      "canliya aliniyor",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ActionType != "activate" {
		t.Fatalf("beklenen action_type activate, alinan: %s", store.lastCmd.ActionType)
	}

	if !resp.Applied {
		t.Fatalf("beklenen applied true")
	}

	if resp.LifecycleStatus != "active" {
		t.Fatalf("beklenen lifecycle_status active, alinan: %s", resp.LifecycleStatus)
	}

	if !resp.RuntimeEnabled {
		t.Fatalf("beklenen runtime_enabled true")
	}

	if !resp.AppliedAt.Equal(time.Date(2026, 4, 26, 3, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen applied_at sabit zaman")
	}
}

func TestApplyPluginLifecycleUsecaseApply_SuspendFallbackSuccess(t *testing.T) {
	store := &pluginLifecycleStoreMock{
		result: ApplyPluginLifecycleResult{},
	}

	usecase := NewApplyPluginLifecycleUsecase(store)

	resp, err := usecase.Apply(context.Background(), ApplyPluginLifecycleRequest{
		PluginKey:   "erp.logo_export",
		ActionType:  "suspend",
		RequestedBy: "worker-01",
		Reason:      "guvenlik incelemesi",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.LifecycleStatus != "suspended" {
		t.Fatalf("beklenen lifecycle_status suspended, alinan: %s", resp.LifecycleStatus)
	}

	if resp.RuntimeEnabled {
		t.Fatalf("beklenen runtime_enabled false")
	}
}

func TestApplyPluginLifecycleUsecaseApply_ValidationError(t *testing.T) {
	store := &pluginLifecycleStoreMock{}
	usecase := NewApplyPluginLifecycleUsecase(store)

	_, err := usecase.Apply(context.Background(), ApplyPluginLifecycleRequest{
		PluginKey:   "erp.logo_export",
		ActionType:  "enable",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestApplyPluginLifecycleUsecaseApply_StoreError(t *testing.T) {
	store := &pluginLifecycleStoreMock{
		err: errors.New("apply plugin lifecycle failed"),
	}
	usecase := NewApplyPluginLifecycleUsecase(store)

	_, err := usecase.Apply(context.Background(), ApplyPluginLifecycleRequest{
		PluginKey:   "erp.logo_export",
		ActionType:  "activate",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestApplyPluginLifecycleResponseValidate_InvalidAppliedAt(t *testing.T) {
	resp := ApplyPluginLifecycleResponse{
		PluginKey:       "erp.logo_export",
		ActionType:      "activate",
		LifecycleStatus: "active",
		RuntimeEnabled:  true,
		Applied:         true,
		RequestedBy:     "worker-01",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
