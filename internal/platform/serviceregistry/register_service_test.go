package serviceregistry

import (
	"context"
	"errors"
	"testing"
	"time"
)

type registerServiceStoreMock struct {
	lastCmd UpsertServiceInstanceCommand
	result  UpsertServiceInstanceResult
	err     error
	called  bool
}

func (m *registerServiceStoreMock) UpsertServiceInstance(_ context.Context, cmd UpsertServiceInstanceCommand) (UpsertServiceInstanceResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestRegisterServiceUsecaseRegister_Success(t *testing.T) {
	store := &registerServiceStoreMock{
		result: UpsertServiceInstanceResult{
			ServiceID:   "svc-1",
			InstanceID:  "ins-1",
			ServiceKey:  "identity-api",
			InstanceKey: "identity-api-01",
		},
	}

	usecase := NewRegisterServiceUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 24, 12, 0, 0, 0, time.UTC)
	}

	req := RegisterServiceRequest{
		TenantID:                 "tenant-a",
		ServiceKey:               "identity-api",
		DisplayName:              "Identity API",
		ServiceKind:              "api",
		VisibilityScope:          "tenant",
		Protocol:                 "http",
		BasePath:                 "/api/v1",
		HealthPath:               "/health",
		DefaultPort:              9001,
		OwnerTeam:                "identity",
		Metadata:                 map[string]any{"region": "eu"},
		InstanceKey:              "identity-api-01",
		NodeName:                 "node-a",
		Host:                     "10.10.10.11",
		Port:                     9001,
		Version:                  "1.0.0",
		Status:                   "healthy",
		HeartbeatIntervalSeconds: 30,
		InstanceMetadata:         map[string]any{"zone": "az-1"},
	}

	resp, err := usecase.Register(context.Background(), req)
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ServiceKey != "identity-api" {
		t.Fatalf("beklenen service_key identity-api, alinan: %s", store.lastCmd.ServiceKey)
	}

	if store.lastCmd.InstanceKey != "identity-api-01" {
		t.Fatalf("beklenen instance_key identity-api-01, alinan: %s", store.lastCmd.InstanceKey)
	}

	if resp.ServiceID != "svc-1" {
		t.Fatalf("beklenen service id svc-1, alinan: %s", resp.ServiceID)
	}

	if resp.InstanceID != "ins-1" {
		t.Fatalf("beklenen instance id ins-1, alinan: %s", resp.InstanceID)
	}

	if !resp.RegisteredAt.Equal(time.Date(2026, 4, 24, 12, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen registered_at sabit zaman")
	}
}

func TestRegisterServiceUsecaseRegister_ValidationError(t *testing.T) {
	store := &registerServiceStoreMock{}
	usecase := NewRegisterServiceUsecase(store)

	req := RegisterServiceRequest{
		ServiceKey:               "Identity API",
		DisplayName:              "Identity API",
		ServiceKind:              "api",
		VisibilityScope:          "tenant",
		Protocol:                 "http",
		BasePath:                 "/api/v1",
		HealthPath:               "/health",
		DefaultPort:              9001,
		InstanceKey:              "identity-api-01",
		NodeName:                 "node-a",
		Host:                     "10.10.10.11",
		Port:                     9001,
		Status:                   "healthy",
		HeartbeatIntervalSeconds: 30,
	}

	_, err := usecase.Register(context.Background(), req)
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestRegisterServiceUsecaseRegister_StoreError(t *testing.T) {
	store := &registerServiceStoreMock{
		err: errors.New("db write failed"),
	}

	usecase := NewRegisterServiceUsecase(store)

	req := RegisterServiceRequest{
		ServiceKey:               "identity-api",
		DisplayName:              "Identity API",
		ServiceKind:              "api",
		VisibilityScope:          "tenant",
		Protocol:                 "http",
		BasePath:                 "/api/v1",
		HealthPath:               "/health",
		DefaultPort:              9001,
		InstanceKey:              "identity-api-01",
		NodeName:                 "node-a",
		Host:                     "10.10.10.11",
		Port:                     9001,
		Status:                   "healthy",
		HeartbeatIntervalSeconds: 30,
	}

	_, err := usecase.Register(context.Background(), req)
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestRegisterServiceUsecaseRegister_GeneratesFallbackIDs(t *testing.T) {
	store := &registerServiceStoreMock{
		result: UpsertServiceInstanceResult{},
	}

	usecase := NewRegisterServiceUsecase(store)

	req := RegisterServiceRequest{
		ServiceKey:               "identity-api",
		DisplayName:              "Identity API",
		ServiceKind:              "api",
		VisibilityScope:          "tenant",
		Protocol:                 "http",
		BasePath:                 "/api/v1",
		HealthPath:               "/health",
		DefaultPort:              9001,
		InstanceKey:              "identity-api-01",
		NodeName:                 "node-a",
		Host:                     "10.10.10.11",
		Port:                     9001,
		Status:                   "healthy",
		HeartbeatIntervalSeconds: 30,
	}

	resp, err := usecase.Register(context.Background(), req)
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.ServiceID == "" {
		t.Fatalf("fallback service id uretilmedi")
	}

	if resp.InstanceID == "" {
		t.Fatalf("fallback instance id uretilmedi")
	}

	if resp.ServiceKey != "identity-api" {
		t.Fatalf("beklenen service_key identity-api, alinan: %s", resp.ServiceKey)
	}

	if resp.InstanceKey != "identity-api-01" {
		t.Fatalf("beklenen instance_key identity-api-01, alinan: %s", resp.InstanceKey)
	}
}
