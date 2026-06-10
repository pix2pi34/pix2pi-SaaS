package missioncontrol

import (
	"context"
	"errors"
	"testing"
	"time"
)

type statusPanelStoreMock struct {
	lastReq StatusPanelRequest
	items   []ServiceStatusCard
	err     error
	called  bool
}

func (m *statusPanelStoreMock) ListRuntimeStatusCards(_ context.Context, req StatusPanelRequest) ([]ServiceStatusCard, error) {
	m.called = true
	m.lastReq = req
	return m.items, m.err
}

func TestStatusPanelRequestValidate_Success(t *testing.T) {
	req := StatusPanelRequest{
		TenantID:       "tenant-a",
		IncludeGlobal:  true,
		ServiceKeyLike: "identity-api",
		StatusFilter:   "healthy",
		Limit:          50,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestStatusPanelRequestValidate_InvalidLimit(t *testing.T) {
	req := StatusPanelRequest{
		Limit: 0,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestStatusPanelRequestValidate_InvalidStatus(t *testing.T) {
	req := StatusPanelRequest{
		StatusFilter: "green",
		Limit:        10,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestStatusPanelRequestValidate_InvalidServiceKeyLike(t *testing.T) {
	req := StatusPanelRequest{
		ServiceKeyLike: "Identity API",
		Limit:          10,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestStatusPanelUsecaseGet_Success(t *testing.T) {
	store := &statusPanelStoreMock{
		items: []ServiceStatusCard{
			{
				ServiceID:       "svc-1",
				InstanceID:      "ins-1",
				TenantID:        "tenant-a",
				ServiceKey:      "identity-api",
				DisplayName:     "Identity API",
				ServiceKind:     "api",
				VisibilityScope: "tenant",
				InstanceKey:     "identity-api-01",
				RuntimeStatus:   "healthy",
				Host:            "10.10.10.11",
				Port:            9001,
				Version:         "1.0.0",
				LastHeartbeatAt: time.Date(2026, 4, 24, 20, 0, 0, 0, time.UTC),
			},
			{
				ServiceID:       "svc-2",
				InstanceID:      "ins-2",
				TenantID:        "",
				ServiceKey:      "gateway-public",
				DisplayName:     "Gateway Public",
				ServiceKind:     "gateway",
				VisibilityScope: "global",
				InstanceKey:     "gateway-public-01",
				RuntimeStatus:   "degraded",
				Host:            "10.10.10.12",
				Port:            9010,
				Version:         "1.0.0",
				LastHeartbeatAt: time.Date(2026, 4, 24, 20, 1, 0, 0, time.UTC),
			},
		},
	}

	usecase := NewStatusPanelUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 24, 20, 5, 0, 0, time.UTC)
	}

	resp, err := usecase.Get(context.Background(), StatusPanelRequest{
		TenantID:       "tenant-a",
		IncludeGlobal:  true,
		ServiceKeyLike: "identity-api",
		StatusFilter:   "",
		Limit:          50,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if resp.Summary.Total != 2 {
		t.Fatalf("beklenen total 2, alinan: %d", resp.Summary.Total)
	}

	if resp.Summary.Healthy != 1 {
		t.Fatalf("beklenen healthy 1, alinan: %d", resp.Summary.Healthy)
	}

	if resp.Summary.Degraded != 1 {
		t.Fatalf("beklenen degraded 1, alinan: %d", resp.Summary.Degraded)
	}

	if !resp.GeneratedAt.Equal(time.Date(2026, 4, 24, 20, 5, 0, 0, time.UTC)) {
		t.Fatalf("beklenen generated_at sabit zaman")
	}
}

func TestStatusPanelUsecaseGet_ValidationError(t *testing.T) {
	store := &statusPanelStoreMock{}
	usecase := NewStatusPanelUsecase(store)

	_, err := usecase.Get(context.Background(), StatusPanelRequest{
		StatusFilter: "wrong",
		Limit:        10,
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestStatusPanelUsecaseGet_StoreError(t *testing.T) {
	store := &statusPanelStoreMock{
		err: errors.New("status panel read failed"),
	}
	usecase := NewStatusPanelUsecase(store)

	_, err := usecase.Get(context.Background(), StatusPanelRequest{
		TenantID:      "tenant-a",
		IncludeGlobal: true,
		Limit:         10,
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestStatusPanelResponseValidate_InvalidGeneratedAt(t *testing.T) {
	resp := StatusPanelResponse{
		Summary: StatusPanelSummary{
			Total: 1,
		},
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
