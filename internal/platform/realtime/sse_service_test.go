package realtime

import (
	"context"
	"errors"
	"testing"
	"time"
)

type sseConnectionStoreMock struct {
	lastCmd OpenSSEConnectionCommand
	result  OpenSSEConnectionResult
	err     error
	called  bool
}

func (m *sseConnectionStoreMock) OpenStream(_ context.Context, cmd OpenSSEConnectionCommand) (OpenSSEConnectionResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestOpenSSEConnectionRequestValidate_Success(t *testing.T) {
	req := OpenSSEConnectionRequest{
		TenantID:     "tenant-a",
		ConnectionID: "sse-conn-001",
		ChannelName:  "tenant.events",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "sse",
		LastEventID:  "event-000",
		RemoteAddr:   "127.0.0.1:9010",
		Origin:       "https://panel.pix2pi.com.tr",
		RequestedBy:  "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestOpenSSEConnectionRequestValidate_InvalidProtocol(t *testing.T) {
	req := OpenSSEConnectionRequest{
		ConnectionID: "sse-conn-001",
		ChannelName:  "tenant.events",
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

func TestOpenSSEConnectionRequestValidate_InvalidLastEventID(t *testing.T) {
	req := OpenSSEConnectionRequest{
		ConnectionID: "sse-conn-001",
		ChannelName:  "tenant.events",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "sse",
		LastEventID:  "event 000",
		RemoteAddr:   "127.0.0.1:9010",
		RequestedBy:  "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestOpenSSEConnectionRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := OpenSSEConnectionRequest{
		ConnectionID: "sse-conn-001",
		ChannelName:  "tenant.events",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "sse",
		RemoteAddr:   "127.0.0.1:9010",
		RequestedBy:  "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestOpenSSEConnectionUsecaseOpen_Success(t *testing.T) {
	store := &sseConnectionStoreMock{
		result: OpenSSEConnectionResult{
			ConnectionID: "sse-conn-001",
			ChannelName:  "tenant.events",
			ClientID:     "client-001",
			UserRef:      "user-001",
			Protocol:     "sse",
			LastEventID:  "event-000",
			ServerNode:   "node-01",
			Status:       "streaming",
			Accepted:     true,
		},
	}

	usecase := NewOpenSSEConnectionUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 11, 30, 0, 0, time.UTC)
	}

	resp, err := usecase.Open(context.Background(), OpenSSEConnectionRequest{
		TenantID:     "tenant-a",
		ConnectionID: "sse-conn-001",
		ChannelName:  "tenant.events",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "sse",
		LastEventID:  "event-000",
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

	if store.lastCmd.LastEventID != "event-000" {
		t.Fatalf("beklenen last_event_id event-000, alinan: %s", store.lastCmd.LastEventID)
	}

	if !resp.Accepted {
		t.Fatalf("beklenen accepted true")
	}

	if resp.Status != "streaming" {
		t.Fatalf("beklenen status streaming, alinan: %s", resp.Status)
	}

	if resp.ServerNode != "node-01" {
		t.Fatalf("beklenen server_node node-01, alinan: %s", resp.ServerNode)
	}

	if !resp.StreamOpenedAt.Equal(time.Date(2026, 4, 26, 11, 30, 0, 0, time.UTC)) {
		t.Fatalf("beklenen stream_opened_at sabit zaman")
	}
}

func TestOpenSSEConnectionUsecaseOpen_RejectedSuccess(t *testing.T) {
	store := &sseConnectionStoreMock{
		result: OpenSSEConnectionResult{
			ConnectionID:    "sse-conn-002",
			ChannelName:     "tenant.events",
			ClientID:        "client-002",
			UserRef:         "user-002",
			Protocol:        "sse",
			ServerNode:      "node-01",
			Status:          "rejected",
			Accepted:        false,
			RejectionReason: "stream limit exceeded",
		},
	}

	usecase := NewOpenSSEConnectionUsecase(store)

	resp, err := usecase.Open(context.Background(), OpenSSEConnectionRequest{
		ConnectionID: "sse-conn-002",
		ChannelName:  "tenant.events",
		ClientID:     "client-002",
		UserRef:      "user-002",
		Protocol:     "sse",
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

func TestOpenSSEConnectionUsecaseOpen_ValidationError(t *testing.T) {
	store := &sseConnectionStoreMock{}
	usecase := NewOpenSSEConnectionUsecase(store)

	_, err := usecase.Open(context.Background(), OpenSSEConnectionRequest{
		ConnectionID: "sse-conn-001",
		ChannelName:  "tenant.events",
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

func TestOpenSSEConnectionUsecaseOpen_StoreError(t *testing.T) {
	store := &sseConnectionStoreMock{
		err: errors.New("open sse stream failed"),
	}

	usecase := NewOpenSSEConnectionUsecase(store)

	_, err := usecase.Open(context.Background(), OpenSSEConnectionRequest{
		ConnectionID: "sse-conn-001",
		ChannelName:  "tenant.events",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "sse",
		RemoteAddr:   "127.0.0.1:9010",
		RequestedBy:  "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestOpenSSEConnectionResponseValidate_InvalidStreamOpenedAt(t *testing.T) {
	resp := OpenSSEConnectionResponse{
		ConnectionID: "sse-conn-001",
		ChannelName:  "tenant.events",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "sse",
		ServerNode:   "node-01",
		Status:       "streaming",
		Accepted:     true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
