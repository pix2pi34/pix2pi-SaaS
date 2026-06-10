package missioncontrol

import (
	"context"
	"errors"
	"testing"
	"time"
)

type incidentTimelineStoreMock struct {
	lastCmd ListIncidentTimelineCommand
	items   []IncidentTimelineItem
	err     error
	called  bool
}

func (m *incidentTimelineStoreMock) ListIncidentTimeline(_ context.Context, cmd ListIncidentTimelineCommand) ([]IncidentTimelineItem, error) {
	m.called = true
	m.lastCmd = cmd
	return m.items, m.err
}

func TestIncidentTimelineRequestValidate_Success(t *testing.T) {
	req := IncidentTimelineRequest{
		TenantID:            "tenant-a",
		IncidentID:          "inc-1",
		ServiceID:           "svc-1",
		IncludeActions:      true,
		IncludeStateChanges: true,
		IncludeNotes:        false,
		Limit:               50,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestIncidentTimelineRequestValidate_MissingIncidentID(t *testing.T) {
	req := IncidentTimelineRequest{
		ServiceID:      "svc-1",
		IncludeActions: true,
		Limit:          10,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestIncidentTimelineRequestValidate_InvalidLimit(t *testing.T) {
	req := IncidentTimelineRequest{
		IncidentID:     "inc-1",
		ServiceID:      "svc-1",
		IncludeActions: true,
		Limit:          0,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestIncidentTimelineRequestValidate_NoIncludeFlags(t *testing.T) {
	req := IncidentTimelineRequest{
		IncidentID: "inc-1",
		ServiceID:  "svc-1",
		Limit:      10,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestIncidentTimelineUsecaseList_Success(t *testing.T) {
	store := &incidentTimelineStoreMock{
		items: []IncidentTimelineItem{
			{
				EventID:        "evt-1",
				IncidentID:     "inc-1",
				ServiceID:      "svc-1",
				EventType:      "action",
				ActionType:     "restart",
				ActionStatus:   "requested",
				IncidentStatus: "open",
				ActorRef:       "operator-a",
				Message:        "restart istendi",
				OccurredAt:     time.Date(2026, 4, 25, 0, 10, 0, 0, time.UTC),
			},
			{
				EventID:        "evt-2",
				IncidentID:     "inc-1",
				ServiceID:      "svc-1",
				EventType:      "state_change",
				IncidentStatus: "acknowledged",
				ActorRef:       "operator-b",
				Message:        "incident acknowledge edildi",
				OccurredAt:     time.Date(2026, 4, 25, 0, 20, 0, 0, time.UTC),
			},
		},
	}

	usecase := NewIncidentTimelineUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 0, 30, 0, 0, time.UTC)
	}

	resp, err := usecase.List(context.Background(), IncidentTimelineRequest{
		TenantID:            "tenant-a",
		IncidentID:          "inc-1",
		ServiceID:           "svc-1",
		IncludeActions:      true,
		IncludeStateChanges: true,
		IncludeNotes:        false,
		Limit:               50,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if resp.Count != 2 {
		t.Fatalf("beklenen count 2, alinan: %d", resp.Count)
	}

	if resp.Items[0].EventID != "evt-2" {
		t.Fatalf("beklenen en yeni event evt-2, alinan: %s", resp.Items[0].EventID)
	}

	if !resp.GeneratedAt.Equal(time.Date(2026, 4, 25, 0, 30, 0, 0, time.UTC)) {
		t.Fatalf("beklenen generated_at sabit zaman")
	}
}

func TestIncidentTimelineUsecaseList_ValidationError(t *testing.T) {
	store := &incidentTimelineStoreMock{}
	usecase := NewIncidentTimelineUsecase(store)

	_, err := usecase.List(context.Background(), IncidentTimelineRequest{
		IncidentID:     "inc-1",
		ServiceID:      "svc-1",
		IncludeActions: false,
		Limit:          10,
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestIncidentTimelineUsecaseList_StoreError(t *testing.T) {
	store := &incidentTimelineStoreMock{
		err: errors.New("timeline read failed"),
	}
	usecase := NewIncidentTimelineUsecase(store)

	_, err := usecase.List(context.Background(), IncidentTimelineRequest{
		IncidentID:          "inc-1",
		ServiceID:           "svc-1",
		IncludeActions:      true,
		IncludeStateChanges: true,
		Limit:               10,
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestIncidentTimelineResponseValidate_InvalidGeneratedAt(t *testing.T) {
	resp := IncidentTimelineResponse{
		Count: 1,
		Items: []IncidentTimelineItem{
			{
				EventID:        "evt-1",
				IncidentID:     "inc-1",
				ServiceID:      "svc-1",
				EventType:      "action",
				OccurredAt:     time.Date(2026, 4, 25, 0, 10, 0, 0, time.UTC),
			},
		},
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
