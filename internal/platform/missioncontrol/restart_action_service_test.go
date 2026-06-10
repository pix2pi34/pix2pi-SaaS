package missioncontrol

import (
	"context"
	"errors"
	"testing"
	"time"
)

type restartActionStoreMock struct {
	lastCmd RequestRestartActionCommand
	result  RequestRestartActionResult
	err     error
	called  bool
}

func (m *restartActionStoreMock) RequestRestartAction(_ context.Context, cmd RequestRestartActionCommand) (RequestRestartActionResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestRestartActionRequestValidate_Success(t *testing.T) {
	req := RestartActionRequest{
		TenantID:        "tenant-a",
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		InstanceID:      "ins-1",
		RequestedBy:     "operator-a",
		RequestedReason: "timeout artisi",
		DryRun:          false,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestRestartActionRequestValidate_MissingIncidentID(t *testing.T) {
	req := RestartActionRequest{
		ServiceID:       "svc-1",
		RequestedBy:     "operator-a",
		RequestedReason: "timeout artisi",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestRestartActionRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := RestartActionRequest{
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		RequestedBy:     "Operator A",
		RequestedReason: "timeout artisi",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestRestartActionRequestValidate_MissingReason(t *testing.T) {
	req := RestartActionRequest{
		IncidentID:  "inc-1",
		ServiceID:   "svc-1",
		RequestedBy: "operator-a",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestRestartActionUsecaseRequest_Success(t *testing.T) {
	store := &restartActionStoreMock{
		result: RequestRestartActionResult{
			ActionID:     "act-1",
			ActionStatus: "requested",
		},
	}

	usecase := NewRestartActionUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 24, 22, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Request(context.Background(), RestartActionRequest{
		TenantID:        "tenant-a",
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		InstanceID:      "ins-1",
		RequestedBy:     "operator-a",
		RequestedReason: "timeout artisi",
		DryRun:          false,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.RequestedBy != "operator-a" {
		t.Fatalf("beklenen requested_by operator-a, alinan: %s", store.lastCmd.RequestedBy)
	}

	if resp.ActionID != "act-1" {
		t.Fatalf("beklenen action_id act-1, alinan: %s", resp.ActionID)
	}

	if resp.ActionStatus != "requested" {
		t.Fatalf("beklenen action_status requested, alinan: %s", resp.ActionStatus)
	}

	if !resp.RequestedAt.Equal(time.Date(2026, 4, 24, 22, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen requested_at sabit zaman")
	}
}

func TestRestartActionUsecaseRequest_ValidationError(t *testing.T) {
	store := &restartActionStoreMock{}
	usecase := NewRestartActionUsecase(store)

	_, err := usecase.Request(context.Background(), RestartActionRequest{
		IncidentID:      "",
		ServiceID:       "svc-1",
		RequestedBy:     "operator-a",
		RequestedReason: "timeout artisi",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestRestartActionUsecaseRequest_StoreError(t *testing.T) {
	store := &restartActionStoreMock{
		err: errors.New("restart request failed"),
	}
	usecase := NewRestartActionUsecase(store)

	_, err := usecase.Request(context.Background(), RestartActionRequest{
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		RequestedBy:     "operator-a",
		RequestedReason: "timeout artisi",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestRestartActionResponseValidate_InvalidRequestedAt(t *testing.T) {
	resp := RestartActionResponse{
		ActionID:     "act-1",
		IncidentID:   "inc-1",
		ServiceID:    "svc-1",
		ActionType:   "restart",
		ActionStatus: "requested",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
