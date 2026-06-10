package missioncontrol

import (
	"context"
	"errors"
	"testing"
	"time"
)

type isolationActionStoreMock struct {
	lastCmd RequestIsolationActionCommand
	result  RequestIsolationActionResult
	err     error
	called  bool
}

func (m *isolationActionStoreMock) RequestIsolationAction(_ context.Context, cmd RequestIsolationActionCommand) (RequestIsolationActionResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestIsolationActionRequestValidate_Success(t *testing.T) {
	req := IsolationActionRequest{
		TenantID:        "tenant-a",
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		InstanceID:      "ins-1",
		ActionType:      "isolate",
		RequestedBy:     "operator-a",
		RequestedReason: "riskli trafik goruldu",
		DryRun:          false,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestIsolationActionRequestValidate_InvalidActionType(t *testing.T) {
	req := IsolationActionRequest{
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		ActionType:      "block",
		RequestedBy:     "operator-a",
		RequestedReason: "riskli trafik goruldu",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestIsolationActionRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := IsolationActionRequest{
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		ActionType:      "quarantine",
		RequestedBy:     "Operator A",
		RequestedReason: "riskli trafik goruldu",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestIsolationActionRequestValidate_MissingReason(t *testing.T) {
	req := IsolationActionRequest{
		IncidentID:  "inc-1",
		ServiceID:   "svc-1",
		ActionType:  "isolate",
		RequestedBy: "operator-a",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestIsolationActionUsecaseRequest_Success(t *testing.T) {
	store := &isolationActionStoreMock{
		result: RequestIsolationActionResult{
			ActionID:     "act-iso-1",
			ActionStatus: "requested",
		},
	}

	usecase := NewIsolationActionUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 24, 22, 30, 0, 0, time.UTC)
	}

	resp, err := usecase.Request(context.Background(), IsolationActionRequest{
		TenantID:        "tenant-a",
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		InstanceID:      "ins-1",
		ActionType:      "quarantine",
		RequestedBy:     "operator-a",
		RequestedReason: "riskli trafik goruldu",
		DryRun:          true,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ActionType != "quarantine" {
		t.Fatalf("beklenen action_type quarantine, alinan: %s", store.lastCmd.ActionType)
	}

	if resp.ActionID != "act-iso-1" {
		t.Fatalf("beklenen action_id act-iso-1, alinan: %s", resp.ActionID)
	}

	if resp.ActionStatus != "requested" {
		t.Fatalf("beklenen action_status requested, alinan: %s", resp.ActionStatus)
	}

	if !resp.RequestedAt.Equal(time.Date(2026, 4, 24, 22, 30, 0, 0, time.UTC)) {
		t.Fatalf("beklenen requested_at sabit zaman")
	}
}

func TestIsolationActionUsecaseRequest_ValidationError(t *testing.T) {
	store := &isolationActionStoreMock{}
	usecase := NewIsolationActionUsecase(store)

	_, err := usecase.Request(context.Background(), IsolationActionRequest{
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		ActionType:      "wrong",
		RequestedBy:     "operator-a",
		RequestedReason: "riskli trafik goruldu",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestIsolationActionUsecaseRequest_StoreError(t *testing.T) {
	store := &isolationActionStoreMock{
		err: errors.New("isolation request failed"),
	}
	usecase := NewIsolationActionUsecase(store)

	_, err := usecase.Request(context.Background(), IsolationActionRequest{
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		ActionType:      "isolate",
		RequestedBy:     "operator-a",
		RequestedReason: "riskli trafik goruldu",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestIsolationActionResponseValidate_InvalidRequestedAt(t *testing.T) {
	resp := IsolationActionResponse{
		ActionID:     "act-1",
		IncidentID:   "inc-1",
		ServiceID:    "svc-1",
		ActionType:   "isolate",
		ActionStatus: "requested",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
