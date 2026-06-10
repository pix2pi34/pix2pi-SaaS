package realtime

import (
	"bufio"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

func TestPresenceRuntimeConnectHeartbeatDisconnect(t *testing.T) {
	runtime := NewPresenceRuntime()

	conn, err := runtime.Connect(PresenceConnectRequest{
		TenantID:  "tenant_7",
		Channel:   "orders",
		UserID:    "user_1",
		Transport: RealtimeTransportWebSocket,
	})
	if err != nil {
		t.Fatalf("connect failed: %v", err)
	}

	if conn.ConnectionID == "" {
		t.Fatal("expected connection id")
	}
	if conn.Status != PresenceStatusConnected {
		t.Fatalf("expected CONNECTED, got %s", conn.Status)
	}
	if runtime.CountTenantConnections("tenant_7") != 1 {
		t.Fatalf("expected 1 tenant connection")
	}

	heartbeat, err := runtime.Heartbeat("tenant_7", conn.ConnectionID)
	if err != nil {
		t.Fatalf("heartbeat failed: %v", err)
	}
	if heartbeat.LastSeenAt == "" {
		t.Fatal("expected last seen timestamp")
	}

	disconnected, err := runtime.Disconnect("tenant_7", conn.ConnectionID, "test_done")
	if err != nil {
		t.Fatalf("disconnect failed: %v", err)
	}
	if disconnected.Status != PresenceStatusDisconnected {
		t.Fatalf("expected DISCONNECTED, got %s", disconnected.Status)
	}
	if runtime.CountTenantConnections("tenant_7") != 0 {
		t.Fatalf("expected 0 tenant connections")
	}
}

func TestPresenceRuntimeRejectsCrossTenantAccess(t *testing.T) {
	runtime := NewPresenceRuntime()

	conn, err := runtime.Connect(PresenceConnectRequest{
		TenantID:  "tenant_7",
		Channel:   "orders",
		Transport: RealtimeTransportSSE,
	})
	if err != nil {
		t.Fatalf("connect failed: %v", err)
	}

	_, err = runtime.Get("tenant_8", conn.ConnectionID)
	if err != ErrPresenceCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
}

func TestWebSocketRuntimeWelcomeIncludesPresenceConnectionID(t *testing.T) {
	runtime := NewWebSocketRuntime(DefaultWebSocketRuntimeConfig())
	server := httptest.NewServer(runtime)
	defer server.Close()

	url := "ws" + strings.TrimPrefix(server.URL, "http") + "?channel=orders&user_id=user_1"

	header := http.Header{}
	header.Set(DefaultTenantHeader, "tenant_7")

	conn, _, err := websocket.DefaultDialer.Dial(url, header)
	if err != nil {
		t.Fatalf("dial failed: %v", err)
	}
	defer conn.Close()

	var msg ServerMessage
	if err := conn.ReadJSON(&msg); err != nil {
		t.Fatalf("read welcome failed: %v", err)
	}

	payload, ok := msg.Payload.(map[string]interface{})
	if !ok {
		t.Fatalf("expected map payload, got %#v", msg.Payload)
	}

	if payload["connection_id"] == "" {
		t.Fatalf("expected connection_id in welcome payload")
	}
	if payload["presence_status"] != PresenceStatusConnected {
		t.Fatalf("expected CONNECTED presence, got %#v", payload["presence_status"])
	}

	if runtime.PresenceConnectionCount("tenant_7") != 1 {
		t.Fatalf("expected presence connection count 1, got %d", runtime.PresenceConnectionCount("tenant_7"))
	}
}

func TestSSERuntimeWelcomeIncludesPresenceConnectionID(t *testing.T) {
	runtime := NewSSERuntime(DefaultSSERuntimeConfig())
	server := httptest.NewServer(runtime)
	defer server.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, server.URL+"?channel=orders&user_id=user_1", nil)
	if err != nil {
		t.Fatalf("request build failed: %v", err)
	}
	req.Header.Set(DefaultTenantHeader, "tenant_7")

	resp, err := server.Client().Do(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	defer resp.Body.Close()

	reader := bufio.NewReader(resp.Body)

	eventLine, err := reader.ReadString('\n')
	if err != nil {
		t.Fatalf("read event line failed: %v", err)
	}
	if strings.TrimSpace(eventLine) != "event: welcome" {
		t.Fatalf("expected welcome event, got %q", eventLine)
	}

	dataLine, err := reader.ReadString('\n')
	if err != nil {
		t.Fatalf("read data line failed: %v", err)
	}
	dataLine = strings.TrimSpace(strings.TrimPrefix(dataLine, "data: "))

	var msg SSEServerEvent
	if err := json.Unmarshal([]byte(dataLine), &msg); err != nil {
		t.Fatalf("unmarshal data failed: %v", err)
	}

	payload, ok := msg.Payload.(map[string]interface{})
	if !ok {
		t.Fatalf("expected map payload, got %#v", msg.Payload)
	}

	if payload["connection_id"] == "" {
		t.Fatalf("expected connection_id in SSE welcome payload")
	}
	if payload["presence_status"] != PresenceStatusConnected {
		t.Fatalf("expected CONNECTED presence, got %#v", payload["presence_status"])
	}

	if runtime.PresenceConnectionCount("tenant_7") != 1 {
		t.Fatalf("expected presence connection count 1, got %d", runtime.PresenceConnectionCount("tenant_7"))
	}
}

func TestSSERuntimeHeartbeatUpdatesPresence(t *testing.T) {
	config := DefaultSSERuntimeConfig()
	config.HeartbeatIntervalSeconds = 1

	runtime := NewSSERuntime(config)
	server := httptest.NewServer(runtime)
	defer server.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, server.URL+"?channel=stock", nil)
	if err != nil {
		t.Fatalf("request build failed: %v", err)
	}
	req.Header.Set(DefaultTenantHeader, "tenant_99")

	resp, err := server.Client().Do(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	defer resp.Body.Close()

	reader := bufio.NewReader(resp.Body)
	foundHeartbeat := false
	deadline := time.After(2500 * time.Millisecond)

	for !foundHeartbeat {
		select {
		case <-deadline:
			t.Fatal("heartbeat event not received")
		default:
		}

		line, err := reader.ReadString('\n')
		if err != nil {
			t.Fatalf("read failed: %v", err)
		}

		if strings.TrimSpace(line) == "event: heartbeat" {
			foundHeartbeat = true
		}
	}

	if runtime.PresenceConnectionCount("tenant_99") != 1 {
		t.Fatalf("expected tenant_99 presence connection count 1, got %d", runtime.PresenceConnectionCount("tenant_99"))
	}
}
