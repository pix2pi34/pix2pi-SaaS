package missioncontrol

import (
	"context"
	"errors"
	"testing"
	"time"
)

type maintenanceActionStoreMock struct {
	lastCmd RequestMaintenanceActionCommand
	result  RequestMaintenanceActionResult
	err     error
	called  bool
}

func (m *maintenanceActionStoreMock) RequestMaintenanceAction(_ context.Context, cmd RequestMaintenanceActionCommand) (RequestMaintenanceActionResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestMaintenanceActionRequestValidate_Success(t *testing.T) {
	req := MaintenanceActionRequest{
		TenantID:        "tenant-a",
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		InstanceID:      "ins-1",
		ActionType:      "maintenance_on",
		RequestedBy:     "operator-a",
		RequestedReason: "planned update",
		DryRun:          false,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestMaintenanceActionRequestValidate_InvalidActionType(t *testing.T) {
	req := MaintenanceActionRequest{
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		ActionType:      "pause",
		RequestedBy:     "operator-a",
		RequestedReason: "planned update",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestMaintenanceActionRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := MaintenanceActionRequest{
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		ActionType:      "maintenance_off",
		RequestedBy:     "Operator A",
		RequestedReason: "planned update",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestMaintenanceActionRequestValidate_MissingReason(t *testing.T) {
	req := MaintenanceActionRequest{
		IncidentID:  "inc-1",
		ServiceID:   "svc-1",
		ActionType:  "maintenance_on",
		RequestedBy: "operator-a",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestMaintenanceActionUsecaseRequest_Success(t *testing.T) {
	store := &maintenanceActionStoreMock{
		result: RequestMaintenanceActionResult{
			ActionID:     "act-maint-1",
			ActionStatus: "requested",
		},
	}

	usecase := NewMaintenanceActionUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 24, 23, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Request(context.Background(), MaintenanceActionRequest{
		TenantID:        "tenant-a",
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		InstanceID:      "ins-1",
		ActionType:      "maintenance_on",
		RequestedBy:     "operator-a",
		RequestedReason: "planned update",
		DryRun:          true,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ActionType != "maintenance_on" {
		t.Fatalf("beklenen action_type maintenance_on, alinan: %s", store.lastCmd.ActionType)
	}

	if resp.ActionID != "act-maint-1" {
		t.Fatalf("beklenen action_id act-maint-1, alinan: %s", resp.ActionID)
	}

	if resp.ActionStatus != "requested" {
		t.Fatalf("beklenen action_status requested, alinan: %s", resp.ActionStatus)
	}

	if !resp.RequestedAt.Equal(time.Date(2026, 4, 24, 23, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen requested_at sabit zaman")
	}
}

func TestMaintenanceActionUsecaseRequest_ValidationError(t *testing.T) {
	store := &maintenanceActionStoreMock{}
	usecase := NewMaintenanceActionUsecase(store)

	_, err := usecase.Request(context.Background(), MaintenanceActionRequest{
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		ActionType:      "wrong",
		RequestedBy:     "operator-a",
		RequestedReason: "planned update",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestMaintenanceActionUsecaseRequest_StoreError(t *testing.T) {
	store := &maintenanceActionStoreMock{
		err: errors.New("maintenance request failed"),
	}
	usecase := NewMaintenanceActionUsecase(store)

	_, err := usecase.Request(context.Background(), MaintenanceActionRequest{
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		ActionType:      "maintenance_off",
		RequestedBy:     "operator-a",
		RequestedReason: "planned update",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestMaintenanceActionResponseValidate_InvalidRequestedAt(t *testing.T) {
	resp := MaintenanceActionResponse{
		ActionID:     "act-1",
		IncidentID:   "inc-1",
		ServiceID:    "svc-1",
		ActionType:   "maintenance_on",
		ActionStatus: "requested",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
