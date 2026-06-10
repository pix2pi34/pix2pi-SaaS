package serviceregistry

import (
	"context"
	"errors"
	"testing"
	"time"
)

type heartbeatStoreMock struct {
	lastCmd RecordHeartbeatCommand
	result  RecordHeartbeatResult
	err     error
	called  bool
}

func (m *heartbeatStoreMock) RecordHeartbeat(_ context.Context, cmd RecordHeartbeatCommand) (RecordHeartbeatResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestHeartbeatUsecaseAccept_Success(t *testing.T) {
	store := &heartbeatStoreMock{
		result: RecordHeartbeatResult{
			NextHeartbeatInSeconds: 45,
			HealthPullRequested:    false,
		},
	}

	usecase := NewHeartbeatUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 24, 15, 30, 0, 0, time.UTC)
	}

	req := HeartbeatRequest{
		TenantID:                 "tenant-a",
		ServiceKey:               "identity-api",
		InstanceKey:              "identity-api-01",
		Status:                   "healthy",
		Mode:                     "push",
		ResponseTimeMS:           23,
		HeartbeatIntervalSeconds: 30,
		Metadata: map[string]any{
			"cpu": "low",
		},
	}

	resp, err := usecase.Accept(context.Background(), req)
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ServiceKey != "identity-api" {
		t.Fatalf("beklenen service_key identity-api, alinan: %s", store.lastCmd.ServiceKey)
	}

	if resp.NextHeartbeatInSeconds != 45 {
		t.Fatalf("beklenen next heartbeat 45, alinan: %d", resp.NextHeartbeatInSeconds)
	}

	if resp.HealthPullRequested {
		t.Fatalf("healthy durumda health pull false olmaliydi")
	}

	if !resp.HeartbeatAcceptedAt.Equal(time.Date(2026, 4, 24, 15, 30, 0, 0, time.UTC)) {
		t.Fatalf("beklenen accepted_at sabit zaman")
	}
}

func TestHeartbeatUsecaseAccept_ValidationError(t *testing.T) {
	store := &heartbeatStoreMock{}
	usecase := NewHeartbeatUsecase(store)

	req := HeartbeatRequest{
		ServiceKey:               "identity api",
		InstanceKey:              "identity-api-01",
		Status:                   "healthy",
		Mode:                     "push",
		ResponseTimeMS:           20,
		HeartbeatIntervalSeconds: 30,
	}

	_, err := usecase.Accept(context.Background(), req)
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestHeartbeatUsecaseAccept_StoreError(t *testing.T) {
	store := &heartbeatStoreMock{
		err: errors.New("heartbeat persist failed"),
	}
	usecase := NewHeartbeatUsecase(store)

	req := HeartbeatRequest{
		ServiceKey:               "identity-api",
		InstanceKey:              "identity-api-01",
		Status:                   "healthy",
		Mode:                     "push",
		ResponseTimeMS:           20,
		HeartbeatIntervalSeconds: 30,
	}

	_, err := usecase.Accept(context.Background(), req)
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestHeartbeatUsecaseAccept_DefaultsNextHeartbeatFromRequest(t *testing.T) {
	store := &heartbeatStoreMock{
		result: RecordHeartbeatResult{},
	}
	usecase := NewHeartbeatUsecase(store)

	req := HeartbeatRequest{
		ServiceKey:               "identity-api",
		InstanceKey:              "identity-api-01",
		Status:                   "healthy",
		Mode:                     "push",
		ResponseTimeMS:           20,
		HeartbeatIntervalSeconds: 30,
	}

	resp, err := usecase.Accept(context.Background(), req)
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.NextHeartbeatInSeconds != 30 {
		t.Fatalf("beklenen next heartbeat 30, alinan: %d", resp.NextHeartbeatInSeconds)
	}
}

func TestHeartbeatUsecaseAccept_RequestsHealthPullOnDegradedState(t *testing.T) {
	store := &heartbeatStoreMock{
		result: RecordHeartbeatResult{},
	}
	usecase := NewHeartbeatUsecase(store)

	req := HeartbeatRequest{
		ServiceKey:               "identity-api",
		InstanceKey:              "identity-api-01",
		Status:                   "degraded",
		Mode:                     "push",
		ResponseTimeMS:           120,
		HeartbeatIntervalSeconds: 30,
	}

	resp, err := usecase.Accept(context.Background(), req)
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !resp.HealthPullRequested {
		t.Fatalf("degraded durumda health pull true olmaliydi")
	}
}
