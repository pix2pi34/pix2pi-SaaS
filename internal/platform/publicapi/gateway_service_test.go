package publicapi

import (
	"context"
	"errors"
	"testing"
	"time"
)

type publicAPIGatewayStoreMock struct {
	lastCmd ResolvePublicAPIGatewayCommand
	result  ResolvePublicAPIGatewayResult
	err     error
	called  bool
}

func (m *publicAPIGatewayStoreMock) ResolveRoute(_ context.Context, cmd ResolvePublicAPIGatewayCommand) (ResolvePublicAPIGatewayResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestResolvePublicAPIGatewayRequestValidate_Success(t *testing.T) {
	req := ResolvePublicAPIGatewayRequest{
		TenantID:    "tenant-a",
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Method:      "GET",
		Path:        "/v1/erp/customers",
		Origin:      "https://developer.pix2pi.com.tr",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestResolvePublicAPIGatewayRequestValidate_InvalidMethod(t *testing.T) {
	req := ResolvePublicAPIGatewayRequest{
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Method:      "CONNECT",
		Path:        "/v1/erp/customers",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestResolvePublicAPIGatewayRequestValidate_InvalidPath(t *testing.T) {
	req := ResolvePublicAPIGatewayRequest{
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Method:      "GET",
		Path:        "v1 erp customers",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestResolvePublicAPIGatewayRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := ResolvePublicAPIGatewayRequest{
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Method:      "GET",
		Path:        "/v1/erp/customers",
		RequestedBy: "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestResolvePublicAPIGatewayUsecaseResolve_Success(t *testing.T) {
	store := &publicAPIGatewayStoreMock{
		result: ResolvePublicAPIGatewayResult{
			RequestID:     "req-001",
			AppID:         "app-001",
			APIKeyID:      "key-001",
			Method:        "GET",
			Path:          "/v1/erp/customers",
			TargetService: "erp-api",
			TargetPath:    "/v1/erp/customers",
			GatewayStatus: "accepted",
			Accepted:      true,
		},
	}

	usecase := NewResolvePublicAPIGatewayUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 15, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Resolve(context.Background(), ResolvePublicAPIGatewayRequest{
		TenantID:    "tenant-a",
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Method:      "get",
		Path:        "/v1/erp/customers",
		Origin:      "https://developer.pix2pi.com.tr",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.Method != "GET" {
		t.Fatalf("beklenen method GET, alinan: %s", store.lastCmd.Method)
	}

	if !resp.Accepted {
		t.Fatalf("beklenen accepted true")
	}

	if resp.GatewayStatus != "accepted" {
		t.Fatalf("beklenen gateway_status accepted, alinan: %s", resp.GatewayStatus)
	}

	if resp.TargetService != "erp-api" {
		t.Fatalf("beklenen target_service erp-api, alinan: %s", resp.TargetService)
	}

	if !resp.ResolvedAt.Equal(time.Date(2026, 4, 26, 15, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen resolved_at sabit zaman")
	}
}

func TestResolvePublicAPIGatewayUsecaseResolve_FallbackTargetSuccess(t *testing.T) {
	store := &publicAPIGatewayStoreMock{
		result: ResolvePublicAPIGatewayResult{},
	}

	usecase := NewResolvePublicAPIGatewayUsecase(store)

	resp, err := usecase.Resolve(context.Background(), ResolvePublicAPIGatewayRequest{
		RequestID:   "req-002",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Method:      "POST",
		Path:        "/v1/developer/apps",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !resp.Accepted {
		t.Fatalf("beklenen accepted true")
	}

	if resp.TargetService != "developer-api" {
		t.Fatalf("beklenen target_service developer-api, alinan: %s", resp.TargetService)
	}

	if resp.TargetPath != "/v1/developer/apps" {
		t.Fatalf("beklenen target_path /v1/developer/apps, alinan: %s", resp.TargetPath)
	}
}

func TestResolvePublicAPIGatewayUsecaseResolve_RejectedSuccess(t *testing.T) {
	store := &publicAPIGatewayStoreMock{
		result: ResolvePublicAPIGatewayResult{
			RequestID:       "req-003",
			AppID:           "app-001",
			APIKeyID:        "key-001",
			Method:          "DELETE",
			Path:            "/v1/erp/customers",
			GatewayStatus:   "rejected",
			Accepted:        false,
			RejectionReason: "method not allowed for app",
		},
	}

	usecase := NewResolvePublicAPIGatewayUsecase(store)

	resp, err := usecase.Resolve(context.Background(), ResolvePublicAPIGatewayRequest{
		RequestID:   "req-003",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Method:      "DELETE",
		Path:        "/v1/erp/customers",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Accepted {
		t.Fatalf("beklenen accepted false")
	}

	if resp.GatewayStatus != "rejected" {
		t.Fatalf("beklenen gateway_status rejected, alinan: %s", resp.GatewayStatus)
	}

	if resp.RejectionReason == "" {
		t.Fatalf("beklenen rejection_reason dolu")
	}
}

func TestResolvePublicAPIGatewayUsecaseResolve_ValidationError(t *testing.T) {
	store := &publicAPIGatewayStoreMock{}
	usecase := NewResolvePublicAPIGatewayUsecase(store)

	_, err := usecase.Resolve(context.Background(), ResolvePublicAPIGatewayRequest{
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Method:      "CONNECT",
		Path:        "/v1/erp/customers",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestResolvePublicAPIGatewayUsecaseResolve_StoreError(t *testing.T) {
	store := &publicAPIGatewayStoreMock{
		err: errors.New("resolve public api route failed"),
	}

	usecase := NewResolvePublicAPIGatewayUsecase(store)

	_, err := usecase.Resolve(context.Background(), ResolvePublicAPIGatewayRequest{
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Method:      "GET",
		Path:        "/v1/erp/customers",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestResolvePublicAPIGatewayResponseValidate_InvalidResolvedAt(t *testing.T) {
	resp := ResolvePublicAPIGatewayResponse{
		RequestID:     "req-001",
		AppID:         "app-001",
		APIKeyID:      "key-001",
		Method:        "GET",
		Path:          "/v1/erp/customers",
		TargetService: "erp-api",
		TargetPath:    "/v1/erp/customers",
		GatewayStatus: "accepted",
		Accepted:      true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
