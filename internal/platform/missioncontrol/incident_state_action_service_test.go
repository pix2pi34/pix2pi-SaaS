package missioncontrol

import (
	"context"
	"errors"
	"testing"
	"time"
)

type incidentStateActionStoreMock struct {
	lastCmd RequestIncidentStateActionCommand
	result  RequestIncidentStateActionResult
	err     error
	called  bool
}

func (m *incidentStateActionStoreMock) RequestIncidentStateAction(_ context.Context, cmd RequestIncidentStateActionCommand) (RequestIncidentStateActionResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestIncidentStateActionRequestValidate_Success(t *testing.T) {
	req := IncidentStateActionRequest{
		TenantID:     "tenant-a",
		IncidentID:   "inc-1",
		ServiceID:    "svc-1",
		ActionType:   "acknowledge",
		RequestedBy:  "operator-a",
		ResponseNote: "ilk inceleme alindi",
		DryRun:       false,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestIncidentStateActionRequestValidate_InvalidActionType(t *testing.T) {
	req := IncidentStateActionRequest{
		IncidentID:  "inc-1",
		ServiceID:   "svc-1",
		ActionType:  "close",
		RequestedBy: "operator-a",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestIncidentStateActionRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := IncidentStateActionRequest{
		IncidentID:  "inc-1",
		ServiceID:   "svc-1",
		ActionType:  "resolve",
		RequestedBy: "Operator A",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestIncidentStateActionRequestValidate_MissingIncidentID(t *testing.T) {
	req := IncidentStateActionRequest{
		ServiceID:   "svc-1",
		ActionType:  "acknowledge",
		RequestedBy: "operator-a",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestIncidentStateActionUsecaseRequest_Success(t *testing.T) {
	store := &incidentStateActionStoreMock{
		result: RequestIncidentStateActionResult{
			ActionID:       "act-incident-1",
			ActionStatus:   "requested",
			IncidentStatus: "acknowledged",
		},
	}

	usecase := NewIncidentStateActionUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 0, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Request(context.Background(), IncidentStateActionRequest{
		TenantID:     "tenant-a",
		IncidentID:   "inc-1",
		ServiceID:    "svc-1",
		ActionType:   "acknowledge",
		RequestedBy:  "operator-a",
		ResponseNote: "ilk inceleme alindi",
		DryRun:       true,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ActionType != "acknowledge" {
		t.Fatalf("beklenen action_type acknowledge, alinan: %s", store.lastCmd.ActionType)
	}

	if resp.ActionID != "act-incident-1" {
		t.Fatalf("beklenen action_id act-incident-1, alinan: %s", resp.ActionID)
	}

	if resp.IncidentStatus != "acknowledged" {
		t.Fatalf("beklenen incident_status acknowledged, alinan: %s", resp.IncidentStatus)
	}

	if !resp.RequestedAt.Equal(time.Date(2026, 4, 25, 0, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen requested_at sabit zaman")
	}
}

func TestIncidentStateActionUsecaseRequest_DefaultResolveStatus(t *testing.T) {
	store := &incidentStateActionStoreMock{
		result: RequestIncidentStateActionResult{
			ActionID:     "act-incident-2",
			ActionStatus: "requested",
		},
	}

	usecase := NewIncidentStateActionUsecase(store)

	resp, err := usecase.Request(context.Background(), IncidentStateActionRequest{
		IncidentID:   "inc-2",
		ServiceID:    "svc-2",
		ActionType:   "resolve",
		RequestedBy:  "operator-b",
		ResponseNote: "problem giderildi",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.IncidentStatus != "resolved" {
		t.Fatalf("beklenen incident_status resolved, alinan: %s", resp.IncidentStatus)
	}
}

func TestIncidentStateActionUsecaseRequest_ValidationError(t *testing.T) {
	store := &incidentStateActionStoreMock{}
	usecase := NewIncidentStateActionUsecase(store)

	_, err := usecase.Request(context.Background(), IncidentStateActionRequest{
		IncidentID:  "inc-1",
		ServiceID:   "svc-1",
		ActionType:  "wrong",
		RequestedBy: "operator-a",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestIncidentStateActionUsecaseRequest_StoreError(t *testing.T) {
	store := &incidentStateActionStoreMock{
		err: errors.New("incident action failed"),
	}
	usecase := NewIncidentStateActionUsecase(store)

	_, err := usecase.Request(context.Background(), IncidentStateActionRequest{
		IncidentID:  "inc-1",
		ServiceID:   "svc-1",
		ActionType:  "acknowledge",
		RequestedBy: "operator-a",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestIncidentStateActionResponseValidate_InvalidRequestedAt(t *testing.T) {
	resp := IncidentStateActionResponse{
		ActionID:       "act-1",
		IncidentID:     "inc-1",
		ServiceID:      "svc-1",
		ActionType:     "acknowledge",
		ActionStatus:   "requested",
		IncidentStatus: "acknowledged",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
