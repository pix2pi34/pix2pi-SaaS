package realtime

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

func TestWebSocketRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewWebSocketRuntime(DefaultWebSocketRuntimeConfig())
	server := httptest.NewServer(runtime)
	defer server.Close()

	url := "ws" + strings.TrimPrefix(server.URL, "http") + "?channel=orders"

	_, resp, err := websocket.DefaultDialer.Dial(url, nil)
	if err == nil {
		t.Fatal("expected websocket dial error for missing tenant")
	}
	if resp == nil {
		t.Fatal("expected HTTP response")
	}
	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", resp.StatusCode)
	}
}

func TestWebSocketRuntimeAcceptsTenantAndSendsWelcome(t *testing.T) {
	runtime := NewWebSocketRuntime(DefaultWebSocketRuntimeConfig())
	server := httptest.NewServer(runtime)
	defer server.Close()

	url := "ws" + strings.TrimPrefix(server.URL, "http") + "?channel=orders&user_id=user_1"

	header := http.Header{}
	header.Set(DefaultTenantHeader, "tenant_7")
	header.Set("X-Correlation-ID", "corr_1")

	conn, _, err := websocket.DefaultDialer.Dial(url, header)
	if err != nil {
		t.Fatalf("dial failed: %v", err)
	}
	defer conn.Close()

	var msg ServerMessage
	if err := conn.ReadJSON(&msg); err != nil {
		t.Fatalf("read welcome failed: %v", err)
	}

	if msg.Type != MessageTypeWelcome {
		t.Fatalf("expected welcome, got %s", msg.Type)
	}
	if msg.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", msg.TenantID)
	}
	if msg.Channel != "orders" {
		t.Fatalf("expected channel orders, got %s", msg.Channel)
	}

	if runtime.ActiveConnectionCount() != 1 {
		t.Fatalf("expected active connection count 1, got %d", runtime.ActiveConnectionCount())
	}
}

func TestWebSocketRuntimePingPong(t *testing.T) {
	runtime := NewWebSocketRuntime(DefaultWebSocketRuntimeConfig())
	server := httptest.NewServer(runtime)
	defer server.Close()

	url := "ws" + strings.TrimPrefix(server.URL, "http") + "?channel=stock"

	header := http.Header{}
	header.Set(DefaultTenantHeader, "tenant_99")

	conn, _, err := websocket.DefaultDialer.Dial(url, header)
	if err != nil {
		t.Fatalf("dial failed: %v", err)
	}
	defer conn.Close()

	var welcome ServerMessage
	if err := conn.ReadJSON(&welcome); err != nil {
		t.Fatalf("read welcome failed: %v", err)
	}

	if err := conn.WriteJSON(ClientMessage{Type: MessageTypePing}); err != nil {
		t.Fatalf("write ping failed: %v", err)
	}

	_ = conn.SetReadDeadline(time.Now().Add(2 * time.Second))

	var pong ServerMessage
	if err := conn.ReadJSON(&pong); err != nil {
		t.Fatalf("read pong failed: %v", err)
	}

	if pong.Type != MessageTypePong {
		t.Fatalf("expected pong, got %s", pong.Type)
	}
	if pong.TenantID != "tenant_99" {
		t.Fatalf("expected tenant_99, got %s", pong.TenantID)
	}
	if pong.Channel != "stock" {
		t.Fatalf("expected channel stock, got %s", pong.Channel)
	}
}
