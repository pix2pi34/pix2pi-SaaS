package realtime

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"testing"
	"time"
)

type realtimeRuntimeConnectionRecord struct {
	TenantID         string
	ConnectionID     string
	ChannelName      string
	ClientID         string
	UserRef          string
	Protocol         string
	LastEventID      string
	RemoteAddr       string
	Origin           string
	ServerNode       string
	Status           string
	Accepted         bool
	PresenceStatus   string
	ConnectionClosed bool
	LastSeenAt       time.Time
	ClosedAt         *time.Time
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

type realtimeRuntimeIntegrationStore struct {
	mu          sync.Mutex
	nowFn       func() time.Time
	connections map[string]*realtimeRuntimeConnectionRecord
}

func newRealtimeRuntimeIntegrationStore() *realtimeRuntimeIntegrationStore {
	return &realtimeRuntimeIntegrationStore{
		nowFn: func() time.Time {
			return time.Now().UTC()
		},
		connections: make(map[string]*realtimeRuntimeConnectionRecord),
	}
}

func realtimeRuntimeConnectionKey(tenantID, connectionID string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(connectionID)
}

func (s *realtimeRuntimeIntegrationStore) OpenConnection(_ context.Context, cmd OpenWebSocketConnectionCommand) (OpenWebSocketConnectionResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn().UTC()

	rec := &realtimeRuntimeConnectionRecord{
		TenantID:         strings.TrimSpace(cmd.TenantID),
		ConnectionID:     strings.TrimSpace(cmd.ConnectionID),
		ChannelName:      strings.TrimSpace(cmd.ChannelName),
		ClientID:         strings.TrimSpace(cmd.ClientID),
		UserRef:          strings.TrimSpace(cmd.UserRef),
		Protocol:         strings.TrimSpace(cmd.Protocol),
		RemoteAddr:       strings.TrimSpace(cmd.RemoteAddr),
		Origin:           strings.TrimSpace(cmd.Origin),
		ServerNode:       "node-01",
		Status:           "connected",
		Accepted:         true,
		PresenceStatus:   "online",
		ConnectionClosed: false,
		LastSeenAt:       now,
		CreatedAt:        now,
		UpdatedAt:        now,
	}

	s.connections[realtimeRuntimeConnectionKey(rec.TenantID, rec.ConnectionID)] = rec

	return OpenWebSocketConnectionResult{
		ConnectionID: rec.ConnectionID,
		ChannelName:  rec.ChannelName,
		ClientID:     rec.ClientID,
		UserRef:      rec.UserRef,
		Protocol:     rec.Protocol,
		ServerNode:   rec.ServerNode,
		Status:       rec.Status,
		Accepted:     rec.Accepted,
	}, nil
}

func (s *realtimeRuntimeIntegrationStore) OpenStream(_ context.Context, cmd OpenSSEConnectionCommand) (OpenSSEConnectionResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn().UTC()

	rec := &realtimeRuntimeConnectionRecord{
		TenantID:         strings.TrimSpace(cmd.TenantID),
		ConnectionID:     strings.TrimSpace(cmd.ConnectionID),
		ChannelName:      strings.TrimSpace(cmd.ChannelName),
		ClientID:         strings.TrimSpace(cmd.ClientID),
		UserRef:          strings.TrimSpace(cmd.UserRef),
		Protocol:         strings.TrimSpace(cmd.Protocol),
		LastEventID:      strings.TrimSpace(cmd.LastEventID),
		RemoteAddr:       strings.TrimSpace(cmd.RemoteAddr),
		Origin:           strings.TrimSpace(cmd.Origin),
		ServerNode:       "node-01",
		Status:           "streaming",
		Accepted:         true,
		PresenceStatus:   "online",
		ConnectionClosed: false,
		LastSeenAt:       now,
		CreatedAt:        now,
		UpdatedAt:        now,
	}

	s.connections[realtimeRuntimeConnectionKey(rec.TenantID, rec.ConnectionID)] = rec

	return OpenSSEConnectionResult{
		ConnectionID: rec.ConnectionID,
		ChannelName:  rec.ChannelName,
		ClientID:     rec.ClientID,
		UserRef:      rec.UserRef,
		Protocol:     rec.Protocol,
		LastEventID:  rec.LastEventID,
		ServerNode:   rec.ServerNode,
		Status:       rec.Status,
		Accepted:     rec.Accepted,
	}, nil
}

func (s *realtimeRuntimeIntegrationStore) AuthorizeChannel(_ context.Context, cmd AuthorizeRealtimeChannelCommand) (AuthorizeRealtimeChannelResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	rec, ok := s.connections[realtimeRuntimeConnectionKey(cmd.TenantID, cmd.ConnectionID)]
	if !ok {
		return AuthorizeRealtimeChannelResult{}, fmt.Errorf("connection not found: %s", cmd.ConnectionID)
	}

	if rec.ClientID != strings.TrimSpace(cmd.ClientID) || rec.UserRef != strings.TrimSpace(cmd.UserRef) {
		return AuthorizeRealtimeChannelResult{}, fmt.Errorf("connection identity mismatch")
	}

	channelName := strings.TrimSpace(cmd.ChannelName)

	if strings.HasPrefix(channelName, "tenant.") {
		return AuthorizeRealtimeChannelResult{
			TenantID:      rec.TenantID,
			ConnectionID:  rec.ConnectionID,
			ChannelName:   rec.ChannelName,
			ClientID:      rec.ClientID,
			UserRef:       rec.UserRef,
			Operation:     strings.TrimSpace(cmd.Operation),
			ChannelScope:  "tenant",
			AuthStatus:    "granted",
			AccessGranted: true,
		}, nil
	}

	if strings.HasPrefix(channelName, "platform.") {
		return AuthorizeRealtimeChannelResult{
			TenantID:      rec.TenantID,
			ConnectionID:  rec.ConnectionID,
			ChannelName:   rec.ChannelName,
			ClientID:      rec.ClientID,
			UserRef:       rec.UserRef,
			Operation:     strings.TrimSpace(cmd.Operation),
			ChannelScope:  "platform",
			AuthStatus:    "denied",
			AccessGranted: false,
			DenialReason:  "platform kanali tenant runtime icin kapali",
		}, nil
	}

	return AuthorizeRealtimeChannelResult{
		TenantID:      rec.TenantID,
		ConnectionID:  rec.ConnectionID,
		ChannelName:   rec.ChannelName,
		ClientID:      rec.ClientID,
		UserRef:       rec.UserRef,
		Operation:     strings.TrimSpace(cmd.Operation),
		ChannelScope:  "tenant",
		AuthStatus:    "denied",
		AccessGranted: false,
		DenialReason:  "kanal tenant guvenlik kuralina uymuyor",
	}, nil
}

func (s *realtimeRuntimeIntegrationStore) ApplyPresence(_ context.Context, cmd ApplyRealtimePresenceCommand) (ApplyRealtimePresenceResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	rec, ok := s.connections[realtimeRuntimeConnectionKey(cmd.TenantID, cmd.ConnectionID)]
	if !ok {
		return ApplyRealtimePresenceResult{}, fmt.Errorf("connection not found: %s", cmd.ConnectionID)
	}

	if rec.ChannelName != strings.TrimSpace(cmd.ChannelName) ||
		rec.ClientID != strings.TrimSpace(cmd.ClientID) ||
		rec.UserRef != strings.TrimSpace(cmd.UserRef) {
		return ApplyRealtimePresenceResult{}, fmt.Errorf("connection context mismatch")
	}

	now := s.nowFn().UTC()

	switch strings.TrimSpace(cmd.ActionType) {
	case "heartbeat":
		rec.PresenceStatus = "online"
		rec.ConnectionClosed = false
		rec.ClosedAt = nil
	case "disconnect":
		rec.PresenceStatus = "offline"
		rec.ConnectionClosed = true
		rec.ClosedAt = &now
	case "expire":
		rec.PresenceStatus = "expired"
		rec.ConnectionClosed = true
		rec.ClosedAt = &now
	default:
		return ApplyRealtimePresenceResult{}, fmt.Errorf("unsupported presence action: %s", cmd.ActionType)
	}

	rec.LastSeenAt = now
	rec.UpdatedAt = now

	return ApplyRealtimePresenceResult{
		TenantID:         rec.TenantID,
		ConnectionID:     rec.ConnectionID,
		ChannelName:      rec.ChannelName,
		ClientID:         rec.ClientID,
		UserRef:          rec.UserRef,
		ActionType:       strings.TrimSpace(cmd.ActionType),
		PresenceStatus:   rec.PresenceStatus,
		ConnectionClosed: rec.ConnectionClosed,
		ServerNode:       rec.ServerNode,
		LastSeenAt:       rec.LastSeenAt,
		ClosedAt:         cloneRealtimeTimePtr(rec.ClosedAt),
		Applied:          true,
	}, nil
}

func (s *realtimeRuntimeIntegrationStore) snapshotConnection(tenantID, connectionID string) (realtimeRuntimeConnectionRecord, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()

	rec, ok := s.connections[realtimeRuntimeConnectionKey(tenantID, connectionID)]
	if !ok {
		return realtimeRuntimeConnectionRecord{}, false
	}

	out := *rec
	out.ClosedAt = cloneRealtimeTimePtr(rec.ClosedAt)

	return out, true
}

func TestRealtimeRuntimeIntegration_WebSocketAuthPresenceLifecycleFlow(t *testing.T) {
	store := newRealtimeRuntimeIntegrationStore()

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 13, 0, 0, 0, time.UTC)
	}

	wsUsecase := NewOpenWebSocketConnectionUsecase(store)
	authUsecase := NewAuthorizeRealtimeChannelUsecase(store)
	presenceUsecase := NewApplyRealtimePresenceUsecase(store)

	wsUsecase.nowFn = store.nowFn
	authUsecase.nowFn = store.nowFn
	presenceUsecase.nowFn = store.nowFn

	openResp, err := wsUsecase.Open(context.Background(), OpenWebSocketConnectionRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-ws-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "websocket",
		RemoteAddr:   "127.0.0.1:9010",
		Origin:       "https://panel.pix2pi.com.tr",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("websocket open hatasi: %v", err)
	}

	if !openResp.Accepted || openResp.Status != "connected" {
		t.Fatalf("websocket connected olmaliydi")
	}

	authResp, err := authUsecase.Authorize(context.Background(), AuthorizeRealtimeChannelRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-ws-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Operation:    "subscribe",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("channel auth hatasi: %v", err)
	}

	if !authResp.AccessGranted || authResp.AuthStatus != "granted" {
		t.Fatalf("tenant channel auth granted olmaliydi")
	}

	heartbeatResp, err := presenceUsecase.Apply(context.Background(), ApplyRealtimePresenceRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-ws-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		ActionType:   "heartbeat",
		ServerNode:   "node-01",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("heartbeat hatasi: %v", err)
	}

	if heartbeatResp.PresenceStatus != "online" || heartbeatResp.ConnectionClosed {
		t.Fatalf("heartbeat online/acik olmaliydi")
	}

	disconnectResp, err := presenceUsecase.Apply(context.Background(), ApplyRealtimePresenceRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-ws-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		ActionType:   "disconnect",
		ServerNode:   "node-01",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("disconnect hatasi: %v", err)
	}

	if disconnectResp.PresenceStatus != "offline" || !disconnectResp.ConnectionClosed {
		t.Fatalf("disconnect offline/kapali olmaliydi")
	}

	snapshot, ok := store.snapshotConnection("tenant-a", "conn-ws-001")
	if !ok {
		t.Fatalf("connection snapshot bulunamadi")
	}

	if snapshot.PresenceStatus != "offline" || !snapshot.ConnectionClosed || snapshot.ClosedAt == nil {
		t.Fatalf("final connection lifecycle beklenen gibi degil")
	}
}

func TestRealtimeRuntimeIntegration_SSELastEventAndPlatformDenyFlow(t *testing.T) {
	store := newRealtimeRuntimeIntegrationStore()

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 13, 30, 0, 0, time.UTC)
	}

	sseUsecase := NewOpenSSEConnectionUsecase(store)
	authUsecase := NewAuthorizeRealtimeChannelUsecase(store)
	presenceUsecase := NewApplyRealtimePresenceUsecase(store)

	sseUsecase.nowFn = store.nowFn
	authUsecase.nowFn = store.nowFn
	presenceUsecase.nowFn = store.nowFn

	openResp, err := sseUsecase.Open(context.Background(), OpenSSEConnectionRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-sse-001",
		ChannelName:  "platform.ops",
		ClientID:     "client-010",
		UserRef:      "user-010",
		Protocol:     "sse",
		LastEventID:  "event-099",
		RemoteAddr:   "127.0.0.1:9010",
		Origin:       "https://panel.pix2pi.com.tr",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("sse open hatasi: %v", err)
	}

	if !openResp.Accepted || openResp.Status != "streaming" {
		t.Fatalf("sse streaming olmaliydi")
	}

	if openResp.LastEventID != "event-099" {
		t.Fatalf("last_event_id korunmaliydi")
	}

	authResp, err := authUsecase.Authorize(context.Background(), AuthorizeRealtimeChannelRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-sse-001",
		ChannelName:  "platform.ops",
		ClientID:     "client-010",
		UserRef:      "user-010",
		Operation:    "subscribe",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("platform channel auth hatasi: %v", err)
	}

	if authResp.AccessGranted {
		t.Fatalf("platform channel tenant runtime icin denied olmaliydi")
	}

	if authResp.AuthStatus != "denied" || authResp.DenialReason == "" {
		t.Fatalf("platform channel denial reason dolu olmaliydi")
	}

	expireResp, err := presenceUsecase.Apply(context.Background(), ApplyRealtimePresenceRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-sse-001",
		ChannelName:  "platform.ops",
		ClientID:     "client-010",
		UserRef:      "user-010",
		ActionType:   "expire",
		ServerNode:   "node-01",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("expire hatasi: %v", err)
	}

	if expireResp.PresenceStatus != "expired" || !expireResp.ConnectionClosed {
		t.Fatalf("expire expired/kapali olmaliydi")
	}
}

func TestRealtimeRuntimeIntegration_TenantIsolationFlow(t *testing.T) {
	store := newRealtimeRuntimeIntegrationStore()

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 14, 0, 0, 0, time.UTC)
	}

	wsUsecase := NewOpenWebSocketConnectionUsecase(store)
	authUsecase := NewAuthorizeRealtimeChannelUsecase(store)
	presenceUsecase := NewApplyRealtimePresenceUsecase(store)

	wsUsecase.nowFn = store.nowFn
	authUsecase.nowFn = store.nowFn
	presenceUsecase.nowFn = store.nowFn

	_, err := wsUsecase.Open(context.Background(), OpenWebSocketConnectionRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-tenant-a",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-a",
		UserRef:      "user-a",
		Protocol:     "websocket",
		RemoteAddr:   "127.0.0.1:9010",
		RequestedBy:  "worker-a",
	})
	if err != nil {
		t.Fatalf("tenant-a websocket open hatasi: %v", err)
	}

	_, err = wsUsecase.Open(context.Background(), OpenWebSocketConnectionRequest{
		TenantID:     "tenant-b",
		ConnectionID: "conn-tenant-b",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-b",
		UserRef:      "user-b",
		Protocol:     "websocket",
		RemoteAddr:   "127.0.0.1:9010",
		RequestedBy:  "worker-b",
	})
	if err != nil {
		t.Fatalf("tenant-b websocket open hatasi: %v", err)
	}

	tenantBAuth, err := authUsecase.Authorize(context.Background(), AuthorizeRealtimeChannelRequest{
		TenantID:     "tenant-b",
		ConnectionID: "conn-tenant-b",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-b",
		UserRef:      "user-b",
		Operation:    "publish",
		RequestedBy:  "worker-b",
	})
	if err != nil {
		t.Fatalf("tenant-b auth hatasi: %v", err)
	}

	if !tenantBAuth.AccessGranted {
		t.Fatalf("tenant-b auth granted olmaliydi")
	}

	_, err = presenceUsecase.Apply(context.Background(), ApplyRealtimePresenceRequest{
		TenantID:     "tenant-b",
		ConnectionID: "conn-tenant-b",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-b",
		UserRef:      "user-b",
		ActionType:   "disconnect",
		ServerNode:   "node-01",
		RequestedBy:  "worker-b",
	})
	if err != nil {
		t.Fatalf("tenant-b disconnect hatasi: %v", err)
	}

	tenantASnapshot, ok := store.snapshotConnection("tenant-a", "conn-tenant-a")
	if !ok {
		t.Fatalf("tenant-a snapshot bulunamadi")
	}

	tenantBSnapshot, ok := store.snapshotConnection("tenant-b", "conn-tenant-b")
	if !ok {
		t.Fatalf("tenant-b snapshot bulunamadi")
	}

	if tenantASnapshot.ConnectionClosed {
		t.Fatalf("tenant-a connection tenant-b disconnect ile etkilenmemeliydi")
	}

	if !tenantBSnapshot.ConnectionClosed || tenantBSnapshot.PresenceStatus != "offline" {
		t.Fatalf("tenant-b offline/closed olmaliydi")
	}
}
