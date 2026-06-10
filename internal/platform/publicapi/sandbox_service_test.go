package publicapi

import (
	"context"
	"errors"
	"testing"
	"time"
)

type publicAPISandboxStoreMock struct {
	lastCmd EnsurePublicAPISandboxCommand
	result  EnsurePublicAPISandboxResult
	err     error
	called  bool
}

func (m *publicAPISandboxStoreMock) EnsureSandbox(_ context.Context, cmd EnsurePublicAPISandboxCommand) (EnsurePublicAPISandboxResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestEnsurePublicAPISandboxRequestValidate_Success(t *testing.T) {
	req := EnsurePublicAPISandboxRequest{
		TenantID:    "tenant-a",
		AppID:       "app-001",
		Environment: "sandbox",
		SandboxName: "dev-sandbox",
		DataMode:    "sample_data",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestEnsurePublicAPISandboxRequestValidate_ProductionRejected(t *testing.T) {
	req := EnsurePublicAPISandboxRequest{
		AppID:       "app-001",
		Environment: "production",
		SandboxName: "dev-sandbox",
		DataMode:    "sample_data",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestEnsurePublicAPISandboxRequestValidate_InvalidDataMode(t *testing.T) {
	req := EnsurePublicAPISandboxRequest{
		AppID:       "app-001",
		Environment: "sandbox",
		SandboxName: "dev-sandbox",
		DataMode:    "copy_prod",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestEnsurePublicAPISandboxRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := EnsurePublicAPISandboxRequest{
		AppID:       "app-001",
		Environment: "sandbox",
		SandboxName: "dev-sandbox",
		DataMode:    "sample_data",
		RequestedBy: "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestEnsurePublicAPISandboxUsecaseEnsure_Success(t *testing.T) {
	store := &publicAPISandboxStoreMock{
		result: EnsurePublicAPISandboxResult{
			SandboxID:     "sandbox-001",
			AppID:         "app-001",
			Environment:   "sandbox",
			SandboxName:   "dev-sandbox",
			DataMode:      "sample_data",
			BaseURL:       "https://sandbox.pix2pi.com.tr/app-001/dev-sandbox",
			Isolated:      true,
			SandboxStatus: "ready",
			Ready:         true,
		},
	}

	usecase := NewEnsurePublicAPISandboxUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 17, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Ensure(context.Background(), EnsurePublicAPISandboxRequest{
		TenantID:    "tenant-a",
		AppID:       "app-001",
		Environment: "sandbox",
		SandboxName: "dev-sandbox",
		DataMode:    "sample_data",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.Environment != "sandbox" {
		t.Fatalf("beklenen environment sandbox, alinan: %s", store.lastCmd.Environment)
	}

	if !resp.Ready {
		t.Fatalf("beklenen ready true")
	}

	if !resp.Isolated {
		t.Fatalf("beklenen isolated true")
	}

	if resp.SandboxStatus != "ready" {
		t.Fatalf("beklenen sandbox_status ready, alinan: %s", resp.SandboxStatus)
	}

	if !resp.ProvisionedAt.Equal(time.Date(2026, 4, 26, 17, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen provisioned_at sabit zaman")
	}
}

func TestEnsurePublicAPISandboxUsecaseEnsure_FallbackSuccess(t *testing.T) {
	store := &publicAPISandboxStoreMock{
		result: EnsurePublicAPISandboxResult{},
	}

	usecase := NewEnsurePublicAPISandboxUsecase(store)

	resp, err := usecase.Ensure(context.Background(), EnsurePublicAPISandboxRequest{
		AppID:       "app-002",
		Environment: "sandbox",
		SandboxName: "qa",
		DataMode:    "empty",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.SandboxID == "" {
		t.Fatalf("fallback sandbox_id dolu olmaliydi")
	}

	if resp.BaseURL == "" {
		t.Fatalf("fallback base_url dolu olmaliydi")
	}

	if !resp.Ready {
		t.Fatalf("fallback ready true olmaliydi")
	}

	if !resp.Isolated {
		t.Fatalf("fallback isolated true olmaliydi")
	}
}

func TestEnsurePublicAPISandboxUsecaseEnsure_BlockedSuccess(t *testing.T) {
	store := &publicAPISandboxStoreMock{
		result: EnsurePublicAPISandboxResult{
			SandboxID:     "sandbox-003",
			AppID:         "app-003",
			Environment:   "sandbox",
			SandboxName:   "blocked-sandbox",
			DataMode:      "mirror_schema",
			BaseURL:       "https://sandbox.pix2pi.com.tr/app-003/blocked-sandbox",
			Isolated:      false,
			SandboxStatus: "blocked",
			Ready:         false,
			DenialReason:  "sandbox quota dolu",
		},
	}

	usecase := NewEnsurePublicAPISandboxUsecase(store)

	resp, err := usecase.Ensure(context.Background(), EnsurePublicAPISandboxRequest{
		AppID:       "app-003",
		Environment: "sandbox",
		SandboxName: "blocked-sandbox",
		DataMode:    "mirror_schema",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Ready {
		t.Fatalf("blocked durumda ready false olmali")
	}

	if resp.SandboxStatus != "blocked" {
		t.Fatalf("beklenen sandbox_status blocked, alinan: %s", resp.SandboxStatus)
	}

	if resp.DenialReason == "" {
		t.Fatalf("blocked durumda denial_reason dolu olmali")
	}
}

func TestEnsurePublicAPISandboxUsecaseEnsure_ValidationError(t *testing.T) {
	store := &publicAPISandboxStoreMock{}
	usecase := NewEnsurePublicAPISandboxUsecase(store)

	_, err := usecase.Ensure(context.Background(), EnsurePublicAPISandboxRequest{
		AppID:       "app-001",
		Environment: "production",
		SandboxName: "dev-sandbox",
		DataMode:    "sample_data",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestEnsurePublicAPISandboxUsecaseEnsure_StoreError(t *testing.T) {
	store := &publicAPISandboxStoreMock{
		err: errors.New("ensure sandbox failed"),
	}

	usecase := NewEnsurePublicAPISandboxUsecase(store)

	_, err := usecase.Ensure(context.Background(), EnsurePublicAPISandboxRequest{
		AppID:       "app-001",
		Environment: "sandbox",
		SandboxName: "dev-sandbox",
		DataMode:    "sample_data",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestEnsurePublicAPISandboxResponseValidate_InvalidProvisionedAt(t *testing.T) {
	resp := EnsurePublicAPISandboxResponse{
		SandboxID:     "sandbox-001",
		AppID:         "app-001",
		Environment:   "sandbox",
		SandboxName:   "dev-sandbox",
		DataMode:      "sample_data",
		BaseURL:       "https://sandbox.pix2pi.com.tr/app-001/dev-sandbox",
		Isolated:      true,
		SandboxStatus: "ready",
		Ready:         true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
