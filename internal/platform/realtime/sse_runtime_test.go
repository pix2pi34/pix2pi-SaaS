package realtime

import (
	"bufio"
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestSSERuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewSSERuntime(DefaultSSERuntimeConfig())
	server := httptest.NewServer(runtime)
	defer server.Close()

	resp, err := server.Client().Get(server.URL + "?channel=orders")
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", resp.StatusCode)
	}
}

func TestSSERuntimeRejectsMissingChannel(t *testing.T) {
	runtime := NewSSERuntime(DefaultSSERuntimeConfig())
	server := httptest.NewServer(runtime)
	defer server.Close()

	req, err := http.NewRequest(http.MethodGet, server.URL, nil)
	if err != nil {
		t.Fatalf("request build failed: %v", err)
	}
	req.Header.Set(DefaultTenantHeader, "tenant_7")

	resp, err := server.Client().Do(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", resp.StatusCode)
	}
}

func TestSSERuntimeSendsWelcomeEvent(t *testing.T) {
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
	req.Header.Set("X-Correlation-ID", "corr_1")

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
	if !strings.Contains(dataLine, `"tenant_id":"tenant_7"`) {
		t.Fatalf("expected tenant id in data line, got %q", dataLine)
	}
	if !strings.Contains(dataLine, `"channel":"orders"`) {
		t.Fatalf("expected channel in data line, got %q", dataLine)
	}

	if runtime.ActiveConnectionCount() != 1 {
		t.Fatalf("expected active count 1, got %d", runtime.ActiveConnectionCount())
	}
}

func TestSSERuntimeSendsHeartbeatEvent(t *testing.T) {
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
}
