package realtime

import (
	"context"
	"errors"
	"testing"
	"time"
)

type realtimePresenceStoreMock struct {
	lastCmd ApplyRealtimePresenceCommand
	result  ApplyRealtimePresenceResult
	err     error
	called  bool
}

func (m *realtimePresenceStoreMock) ApplyPresence(_ context.Context, cmd ApplyRealtimePresenceCommand) (ApplyRealtimePresenceResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestApplyRealtimePresenceRequestValidate_Success(t *testing.T) {
	req := ApplyRealtimePresenceRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		ActionType:   "heartbeat",
		ServerNode:   "node-01",
		RequestedBy:  "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestApplyRealtimePresenceRequestValidate_InvalidActionType(t *testing.T) {
	req := ApplyRealtimePresenceRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		ActionType:   "pause",
		ServerNode:   "node-01",
		RequestedBy:  "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyRealtimePresenceRequestValidate_InvalidServerNode(t *testing.T) {
	req := ApplyRealtimePresenceRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		ActionType:   "heartbeat",
		ServerNode:   "node 01",
		RequestedBy:  "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyRealtimePresenceRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := ApplyRealtimePresenceRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		ActionType:   "heartbeat",
		ServerNode:   "node-01",
		RequestedBy:  "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyRealtimePresenceUsecaseApply_HeartbeatSuccess(t *testing.T) {
	lastSeenAt := time.Date(2026, 4, 26, 12, 30, 0, 0, time.UTC)

	store := &realtimePresenceStoreMock{
		result: ApplyRealtimePresenceResult{
			TenantID:         "tenant-a",
			ConnectionID:     "conn-001",
			ChannelName:      "tenant.notifications",
			ClientID:         "client-001",
			UserRef:          "user-001",
			ActionType:       "heartbeat",
			PresenceStatus:   "online",
			ConnectionClosed: false,
			ServerNode:       "node-01",
			LastSeenAt:       lastSeenAt,
			Applied:          true,
		},
	}

	usecase := NewApplyRealtimePresenceUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 12, 30, 1, 0, time.UTC)
	}

	resp, err := usecase.Apply(context.Background(), ApplyRealtimePresenceRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		ActionType:   "heartbeat",
		ServerNode:   "node-01",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ActionType != "heartbeat" {
		t.Fatalf("beklenen action_type heartbeat, alinan: %s", store.lastCmd.ActionType)
	}

	if resp.PresenceStatus != "online" {
		t.Fatalf("beklenen presence_status online, alinan: %s", resp.PresenceStatus)
	}

	if resp.ConnectionClosed {
		t.Fatalf("heartbeat durumunda connection_closed false olmali")
	}

	if resp.ClosedAt != nil {
		t.Fatalf("heartbeat durumunda closed_at nil olmali")
	}

	if !resp.LastSeenAt.Equal(lastSeenAt) {
		t.Fatalf("beklenen last_seen_at korunmaliydi")
	}

	if !resp.AppliedAt.Equal(time.Date(2026, 4, 26, 12, 30, 1, 0, time.UTC)) {
		t.Fatalf("beklenen applied_at sabit zaman")
	}
}

func TestApplyRealtimePresenceUsecaseApply_DisconnectFallbackSuccess(t *testing.T) {
	store := &realtimePresenceStoreMock{
		result: ApplyRealtimePresenceResult{},
	}

	usecase := NewApplyRealtimePresenceUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 12, 40, 0, 0, time.UTC)
	}

	resp, err := usecase.Apply(context.Background(), ApplyRealtimePresenceRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-002",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-002",
		UserRef:      "user-002",
		ActionType:   "disconnect",
		ServerNode:   "node-01",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.PresenceStatus != "offline" {
		t.Fatalf("beklenen presence_status offline, alinan: %s", resp.PresenceStatus)
	}

	if !resp.ConnectionClosed {
		t.Fatalf("disconnect durumunda connection_closed true olmali")
	}

	if resp.ClosedAt == nil || !resp.ClosedAt.Equal(time.Date(2026, 4, 26, 12, 40, 0, 0, time.UTC)) {
		t.Fatalf("beklenen closed_at applied zamanina esit olmali")
	}
}

func TestApplyRealtimePresenceUsecaseApply_ExpireFallbackSuccess(t *testing.T) {
	store := &realtimePresenceStoreMock{
		result: ApplyRealtimePresenceResult{},
	}

	usecase := NewApplyRealtimePresenceUsecase(store)

	resp, err := usecase.Apply(context.Background(), ApplyRealtimePresenceRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-003",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-003",
		UserRef:      "user-003",
		ActionType:   "expire",
		ServerNode:   "node-01",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.PresenceStatus != "expired" {
		t.Fatalf("beklenen presence_status expired, alinan: %s", resp.PresenceStatus)
	}

	if !resp.ConnectionClosed {
		t.Fatalf("expire durumunda connection_closed true olmali")
	}
}

func TestApplyRealtimePresenceUsecaseApply_ValidationError(t *testing.T) {
	store := &realtimePresenceStoreMock{}
	usecase := NewApplyRealtimePresenceUsecase(store)

	_, err := usecase.Apply(context.Background(), ApplyRealtimePresenceRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		ActionType:   "pause",
		ServerNode:   "node-01",
		RequestedBy:  "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestApplyRealtimePresenceUsecaseApply_StoreError(t *testing.T) {
	store := &realtimePresenceStoreMock{
		err: errors.New("apply realtime presence failed"),
	}

	usecase := NewApplyRealtimePresenceUsecase(store)

	_, err := usecase.Apply(context.Background(), ApplyRealtimePresenceRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		ActionType:   "heartbeat",
		ServerNode:   "node-01",
		RequestedBy:  "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestApplyRealtimePresenceResponseValidate_InvalidAppliedAt(t *testing.T) {
	resp := ApplyRealtimePresenceResponse{
		TenantID:         "tenant-a",
		ConnectionID:     "conn-001",
		ChannelName:      "tenant.notifications",
		ClientID:         "client-001",
		UserRef:          "user-001",
		ActionType:       "heartbeat",
		PresenceStatus:   "online",
		ConnectionClosed: false,
		ServerNode:       "node-01",
		LastSeenAt:       time.Date(2026, 4, 26, 12, 30, 0, 0, time.UTC),
		Applied:          true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
