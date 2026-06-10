package realtime

import (
	"context"
	"errors"
	"testing"
	"time"
)

type websocketConnectionStoreMock struct {
	lastCmd OpenWebSocketConnectionCommand
	result  OpenWebSocketConnectionResult
	err     error
	called  bool
}

func (m *websocketConnectionStoreMock) OpenConnection(_ context.Context, cmd OpenWebSocketConnectionCommand) (OpenWebSocketConnectionResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestOpenWebSocketConnectionRequestValidate_Success(t *testing.T) {
	req := OpenWebSocketConnectionRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "websocket",
		RemoteAddr:   "127.0.0.1:9010",
		Origin:       "https://panel.pix2pi.com.tr",
		RequestedBy:  "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestOpenWebSocketConnectionRequestValidate_InvalidProtocol(t *testing.T) {
	req := OpenWebSocketConnectionRequest{
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "socketio",
		RemoteAddr:   "127.0.0.1:9010",
		RequestedBy:  "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestOpenWebSocketConnectionRequestValidate_InvalidChannelName(t *testing.T) {
	req := OpenWebSocketConnectionRequest{
		ConnectionID: "conn-001",
		ChannelName:  "tenant notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "websocket",
		RemoteAddr:   "127.0.0.1:9010",
		RequestedBy:  "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestOpenWebSocketConnectionRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := OpenWebSocketConnectionRequest{
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "websocket",
		RemoteAddr:   "127.0.0.1:9010",
		RequestedBy:  "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestOpenWebSocketConnectionUsecaseOpen_Success(t *testing.T) {
	store := &websocketConnectionStoreMock{
		result: OpenWebSocketConnectionResult{
			ConnectionID: "conn-001",
			ChannelName:  "tenant.notifications",
			ClientID:     "client-001",
			UserRef:      "user-001",
			Protocol:     "websocket",
			ServerNode:   "node-01",
			Status:       "connected",
			Accepted:     true,
		},
	}

	usecase := NewOpenWebSocketConnectionUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 11, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Open(context.Background(), OpenWebSocketConnectionRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "websocket",
		RemoteAddr:   "127.0.0.1:9010",
		Origin:       "https://panel.pix2pi.com.tr",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ConnectionID != "conn-001" {
		t.Fatalf("beklenen connection_id conn-001, alinan: %s", store.lastCmd.ConnectionID)
	}

	if !resp.Accepted {
		t.Fatalf("beklenen accepted true")
	}

	if resp.Status != "connected" {
		t.Fatalf("beklenen status connected, alinan: %s", resp.Status)
	}

	if resp.ServerNode != "node-01" {
		t.Fatalf("beklenen server_node node-01, alinan: %s", resp.ServerNode)
	}

	if !resp.ConnectedAt.Equal(time.Date(2026, 4, 26, 11, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen connected_at sabit zaman")
	}
}

func TestOpenWebSocketConnectionUsecaseOpen_RejectedSuccess(t *testing.T) {
	store := &websocketConnectionStoreMock{
		result: OpenWebSocketConnectionResult{
			ConnectionID:    "conn-002",
			ChannelName:     "tenant.notifications",
			ClientID:        "client-002",
			UserRef:         "user-002",
			Protocol:        "websocket",
			ServerNode:      "node-01",
			Status:          "rejected",
			Accepted:        false,
			RejectionReason: "connection limit exceeded",
		},
	}

	usecase := NewOpenWebSocketConnectionUsecase(store)

	resp, err := usecase.Open(context.Background(), OpenWebSocketConnectionRequest{
		ConnectionID: "conn-002",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-002",
		UserRef:      "user-002",
		Protocol:     "websocket",
		RemoteAddr:   "127.0.0.1:9010",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Accepted {
		t.Fatalf("beklenen accepted false")
	}

	if resp.Status != "rejected" {
		t.Fatalf("beklenen status rejected, alinan: %s", resp.Status)
	}

	if resp.RejectionReason == "" {
		t.Fatalf("beklenen rejection_reason dolu")
	}
}

func TestOpenWebSocketConnectionUsecaseOpen_ValidationError(t *testing.T) {
	store := &websocketConnectionStoreMock{}
	usecase := NewOpenWebSocketConnectionUsecase(store)

	_, err := usecase.Open(context.Background(), OpenWebSocketConnectionRequest{
		ConnectionID: "conn-001",
		ChannelName:  "tenant notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "websocket",
		RemoteAddr:   "127.0.0.1:9010",
		RequestedBy:  "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestOpenWebSocketConnectionUsecaseOpen_StoreError(t *testing.T) {
	store := &websocketConnectionStoreMock{
		err: errors.New("open websocket connection failed"),
	}

	usecase := NewOpenWebSocketConnectionUsecase(store)

	_, err := usecase.Open(context.Background(), OpenWebSocketConnectionRequest{
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "websocket",
		RemoteAddr:   "127.0.0.1:9010",
		RequestedBy:  "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestOpenWebSocketConnectionResponseValidate_InvalidConnectedAt(t *testing.T) {
	resp := OpenWebSocketConnectionResponse{
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "websocket",
		ServerNode:   "node-01",
		Status:       "connected",
		Accepted:     true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
