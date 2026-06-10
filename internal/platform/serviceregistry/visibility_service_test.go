package serviceregistry

import (
	"context"
	"errors"
	"testing"
	"time"
)

type visibilityStoreMock struct {
	lastCmd ListVisibleServicesCommand
	items   []VisibleServiceInstance
	err     error
	called  bool
}

func (m *visibilityStoreMock) ListVisibleServiceInstances(_ context.Context, cmd ListVisibleServicesCommand) ([]VisibleServiceInstance, error) {
	m.called = true
	m.lastCmd = cmd
	return m.items, m.err
}

func TestListVisibleServicesRequestValidate_Success(t *testing.T) {
	req := ListVisibleServicesRequest{
		TenantID:       "tenant-a",
		IncludeGlobal:  true,
		ServiceKeyPrefix: "identity",
		InstanceStatus: "healthy",
		Limit:          50,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestListVisibleServicesRequestValidate_InvalidLimit(t *testing.T) {
	req := ListVisibleServicesRequest{
		Limit: 0,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestListVisibleServicesRequestValidate_InvalidStatus(t *testing.T) {
	req := ListVisibleServicesRequest{
		InstanceStatus: "green",
		Limit:          10,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestVisibilityUsecaseList_Success(t *testing.T) {
	store := &visibilityStoreMock{
		items: []VisibleServiceInstance{
			{
				ServiceID:       "svc-1",
				InstanceID:      "ins-1",
				TenantID:        "tenant-a",
				ServiceKey:      "identity-api",
				DisplayName:     "Identity API",
				ServiceKind:     "api",
				VisibilityScope: "tenant",
				InstanceKey:     "identity-api-01",
				InstanceStatus:  "healthy",
				Host:            "10.10.10.11",
				Port:            9001,
				Version:         "1.0.0",
				LastHeartbeatAt: time.Date(2026, 4, 24, 16, 30, 0, 0, time.UTC),
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
				InstanceStatus:  "healthy",
				Host:            "10.10.10.12",
				Port:            9010,
				Version:         "1.0.0",
				LastHeartbeatAt: time.Date(2026, 4, 24, 16, 31, 0, 0, time.UTC),
			},
		},
	}

	usecase := NewVisibilityUsecase(store)

	resp, err := usecase.List(context.Background(), ListVisibleServicesRequest{
		TenantID:         "tenant-a",
		IncludeGlobal:    true,
		ServiceKeyPrefix: "id",
		InstanceStatus:   "healthy",
		Limit:            50,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.TenantID != "tenant-a" {
		t.Fatalf("beklenen tenant_id tenant-a, alinan: %s", store.lastCmd.TenantID)
	}

	if !store.lastCmd.IncludeGlobal {
		t.Fatalf("include_global true olmaliydi")
	}

	if resp.Count != 2 {
		t.Fatalf("beklenen count 2, alinan: %d", resp.Count)
	}
}

func TestVisibilityUsecaseList_ValidationError(t *testing.T) {
	store := &visibilityStoreMock{}
	usecase := NewVisibilityUsecase(store)

	_, err := usecase.List(context.Background(), ListVisibleServicesRequest{
		InstanceStatus: "wrong",
		Limit:          10,
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestVisibilityUsecaseList_StoreError(t *testing.T) {
	store := &visibilityStoreMock{
		err: errors.New("list failed"),
	}
	usecase := NewVisibilityUsecase(store)

	_, err := usecase.List(context.Background(), ListVisibleServicesRequest{
		TenantID:       "tenant-a",
		IncludeGlobal:  true,
		InstanceStatus: "healthy",
		Limit:          10,
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}
