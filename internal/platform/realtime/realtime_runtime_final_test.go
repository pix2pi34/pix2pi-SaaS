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

func TestRealtimeFinalWebSocketTenantAuthPresencePingPong(t *testing.T) {
	runtime := NewWebSocketRuntime(DefaultWebSocketRuntimeConfig())
	server := httptest.NewServer(runtime)
	defer server.Close()

	url := "ws" + strings.TrimPrefix(server.URL, "http") + "?channel=orders&user_id=user_final"

	header := http.Header{}
	header.Set(DefaultTenantHeader, "tenant_final")
	header.Set("X-Correlation-ID", "corr_final_ws")

	conn, _, err := websocket.DefaultDialer.Dial(url, header)
	if err != nil {
		t.Fatalf("dial failed: %v", err)
	}
	defer conn.Close()

	var welcome ServerMessage
	if err := conn.ReadJSON(&welcome); err != nil {
		t.Fatalf("read welcome failed: %v", err)
	}

	if welcome.Type != MessageTypeWelcome {
		t.Fatalf("expected welcome, got %s", welcome.Type)
	}
	if welcome.TenantID != "tenant_final" {
		t.Fatalf("expected tenant_final, got %s", welcome.TenantID)
	}
	if welcome.Channel != "orders" {
		t.Fatalf("expected orders channel, got %s", welcome.Channel)
	}

	payload, ok := welcome.Payload.(map[string]interface{})
	if !ok {
		t.Fatalf("expected welcome payload map, got %#v", welcome.Payload)
	}

	if payload["auth_decision"] != ChannelAuthDecisionAllow {
		t.Fatalf("expected auth ALLOW, got %#v", payload["auth_decision"])
	}
	if payload["connection_id"] == "" {
		t.Fatal("expected connection_id in welcome payload")
	}
	if payload["presence_status"] != PresenceStatusConnected {
		t.Fatalf("expected presence CONNECTED, got %#v", payload["presence_status"])
	}

	if runtime.PresenceConnectionCount("tenant_final") != 1 {
		t.Fatalf("expected presence count 1, got %d", runtime.PresenceConnectionCount("tenant_final"))
	}

	if err := conn.WriteJSON(ClientMessage{Type: MessageTypePing}); err != nil {
		t.Fatalf("write ping failed: %v", err)
	}

	var pong ServerMessage
	if err := conn.ReadJSON(&pong); err != nil {
		t.Fatalf("read pong failed: %v", err)
	}

	if pong.Type != MessageTypePong {
		t.Fatalf("expected pong, got %s", pong.Type)
	}
	if pong.TenantID != "tenant_final" {
		t.Fatalf("expected pong tenant_final, got %s", pong.TenantID)
	}
}

func TestRealtimeFinalWebSocketCrossTenantDenied(t *testing.T) {
	runtime := NewWebSocketRuntime(DefaultWebSocketRuntimeConfig())
	server := httptest.NewServer(runtime)
	defer server.Close()

	url := "ws" + strings.TrimPrefix(server.URL, "http") + "?channel=tenant:tenant_other:orders"

	header := http.Header{}
	header.Set(DefaultTenantHeader, "tenant_final")

	_, resp, err := websocket.DefaultDialer.Dial(url, header)
	if err == nil {
		t.Fatal("expected cross-tenant websocket dial to fail")
	}
	if resp == nil {
		t.Fatal("expected HTTP response")
	}
	if resp.StatusCode != http.StatusForbidden {
		t.Fatalf("expected 403, got %d", resp.StatusCode)
	}
}

func TestRealtimeFinalSSETenantAuthPresenceWelcomeHeartbeat(t *testing.T) {
	config := DefaultSSERuntimeConfig()
	config.HeartbeatIntervalSeconds = 1

	runtime := NewSSERuntime(config)
	server := httptest.NewServer(runtime)
	defer server.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, server.URL+"?channel=stock&user_id=user_final", nil)
	if err != nil {
		t.Fatalf("request build failed: %v", err)
	}
	req.Header.Set(DefaultTenantHeader, "tenant_final")
	req.Header.Set("X-Correlation-ID", "corr_final_sse")

	resp, err := server.Client().Do(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	defer resp.Body.Close()

	if got := resp.Header.Get("Content-Type"); !strings.Contains(got, "text/event-stream") {
		t.Fatalf("expected text/event-stream content type, got %s", got)
	}

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

	var welcome SSEServerEvent
	raw := strings.TrimSpace(strings.TrimPrefix(dataLine, "data: "))
	if err := json.Unmarshal([]byte(raw), &welcome); err != nil {
		t.Fatalf("unmarshal welcome failed: %v", err)
	}

	if welcome.TenantID != "tenant_final" {
		t.Fatalf("expected tenant_final, got %s", welcome.TenantID)
	}
	if welcome.Channel != "stock" {
		t.Fatalf("expected stock, got %s", welcome.Channel)
	}

	payload, ok := welcome.Payload.(map[string]interface{})
	if !ok {
		t.Fatalf("expected welcome payload map, got %#v", welcome.Payload)
	}
	if payload["auth_decision"] != ChannelAuthDecisionAllow {
		t.Fatalf("expected auth ALLOW, got %#v", payload["auth_decision"])
	}
	if payload["connection_id"] == "" {
		t.Fatal("expected connection_id in SSE welcome payload")
	}
	if payload["presence_status"] != PresenceStatusConnected {
		t.Fatalf("expected presence CONNECTED, got %#v", payload["presence_status"])
	}

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
			t.Fatalf("read line failed: %v", err)
		}

		if strings.TrimSpace(line) == "event: heartbeat" {
			foundHeartbeat = true
		}
	}

	if runtime.PresenceConnectionCount("tenant_final") != 1 {
		t.Fatalf("expected presence count 1, got %d", runtime.PresenceConnectionCount("tenant_final"))
	}
}

func TestRealtimeFinalSSECrossTenantDenied(t *testing.T) {
	runtime := NewSSERuntime(DefaultSSERuntimeConfig())
	server := httptest.NewServer(runtime)
	defer server.Close()

	req, err := http.NewRequest(http.MethodGet, server.URL+"?channel=tenant:tenant_other:stock", nil)
	if err != nil {
		t.Fatalf("request build failed: %v", err)
	}
	req.Header.Set(DefaultTenantHeader, "tenant_final")

	resp, err := server.Client().Do(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusForbidden {
		t.Fatalf("expected 403, got %d", resp.StatusCode)
	}
}

func TestRealtimeFinalPresenceTenantIsolation(t *testing.T) {
	runtime := NewPresenceRuntime()

	conn, err := runtime.Connect(PresenceConnectRequest{
		TenantID:  "tenant_a",
		Channel:   "orders",
		UserID:    "user_a",
		Transport: RealtimeTransportWebSocket,
	})
	if err != nil {
		t.Fatalf("connect failed: %v", err)
	}

	if _, err := runtime.Get("tenant_b", conn.ConnectionID); err != ErrPresenceCrossTenant {
		t.Fatalf("expected ErrPresenceCrossTenant on Get, got %v", err)
	}

	if _, err := runtime.Heartbeat("tenant_b", conn.ConnectionID); err != ErrPresenceCrossTenant {
		t.Fatalf("expected ErrPresenceCrossTenant on Heartbeat, got %v", err)
	}

	if _, err := runtime.Disconnect("tenant_b", conn.ConnectionID, "wrong_tenant"); err != ErrPresenceCrossTenant {
		t.Fatalf("expected ErrPresenceCrossTenant on Disconnect, got %v", err)
	}

	if runtime.CountTenantConnections("tenant_a") != 1 {
		t.Fatalf("expected tenant_a count 1, got %d", runtime.CountTenantConnections("tenant_a"))
	}
	if runtime.CountTenantConnections("tenant_b") != 0 {
		t.Fatalf("expected tenant_b count 0, got %d", runtime.CountTenantConnections("tenant_b"))
	}
}

func TestRealtimeFinalChannelPolicyNormalization(t *testing.T) {
	auth := NewChannelAuthRuntime(DefaultChannelAuthRuntimeConfig())

	decision := auth.AuthorizeChannel(ChannelAuthRequest{
		TenantID:  "tenant_final",
		Channel:   "inventory/updates",
		UserID:    "user_final",
		Transport: RealtimeTransportWebSocket,
	})

	if !decision.Allowed {
		t.Fatalf("expected allow, got reason=%s", decision.Reason)
	}
	if decision.NormalizedKey != "tenant:tenant_final:inventory/updates" {
		t.Fatalf("unexpected normalized key %s", decision.NormalizedKey)
	}
}
