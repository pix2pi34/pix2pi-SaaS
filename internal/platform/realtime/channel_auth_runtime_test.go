package realtime

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gorilla/websocket"
)

func TestChannelAuthRuntimeAllowsImplicitTenantScopedChannel(t *testing.T) {
	runtime := NewChannelAuthRuntime(DefaultChannelAuthRuntimeConfig())

	decision := runtime.AuthorizeChannel(ChannelAuthRequest{
		TenantID:  "tenant_7",
		Channel:   "orders",
		UserID:    "user_1",
		Transport: "websocket",
	})

	if !decision.Allowed {
		t.Fatalf("expected allow, got reason=%s", decision.Reason)
	}
	if decision.Decision != ChannelAuthDecisionAllow {
		t.Fatalf("expected ALLOW, got %s", decision.Decision)
	}
	if decision.NormalizedKey != "tenant:tenant_7:orders" {
		t.Fatalf("unexpected normalized key: %s", decision.NormalizedKey)
	}
}

func TestChannelAuthRuntimeDeniesCrossTenantChannel(t *testing.T) {
	runtime := NewChannelAuthRuntime(DefaultChannelAuthRuntimeConfig())

	decision := runtime.AuthorizeChannel(ChannelAuthRequest{
		TenantID:  "tenant_7",
		Channel:   "tenant:tenant_8:orders",
		UserID:    "user_1",
		Transport: "sse",
	})

	if decision.Allowed {
		t.Fatal("expected deny for cross-tenant channel")
	}
	if decision.Reason != ChannelAuthReasonCrossTenantChannel {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestChannelAuthRuntimeDeniesInvalidChannelName(t *testing.T) {
	runtime := NewChannelAuthRuntime(DefaultChannelAuthRuntimeConfig())

	decision := runtime.AuthorizeChannel(ChannelAuthRequest{
		TenantID:  "tenant_7",
		Channel:   "orders bad",
		UserID:    "user_1",
		Transport: "websocket",
	})

	if decision.Allowed {
		t.Fatal("expected deny for invalid channel")
	}
	if decision.Reason != ChannelAuthReasonInvalidChannelName {
		t.Fatalf("expected invalid channel reason, got %s", decision.Reason)
	}
}

func TestChannelAuthRuntimeDeniesForbiddenSystemZoneForNormalUser(t *testing.T) {
	runtime := NewChannelAuthRuntime(DefaultChannelAuthRuntimeConfig())

	decision := runtime.AuthorizeChannel(ChannelAuthRequest{
		TenantID:  "tenant_7",
		Channel:   "global:ops",
		UserID:    "user_1",
		Transport: "websocket",
	})

	if decision.Allowed {
		t.Fatal("expected deny for forbidden system zone")
	}
	if decision.Reason != ChannelAuthReasonForbiddenSystemZone {
		t.Fatalf("expected forbidden system zone reason, got %s", decision.Reason)
	}
}

func TestWebSocketRuntimeDeniesCrossTenantChannel(t *testing.T) {
	runtime := NewWebSocketRuntime(DefaultWebSocketRuntimeConfig())
	server := httptest.NewServer(runtime)
	defer server.Close()

	url := "ws" + strings.TrimPrefix(server.URL, "http") + "?channel=tenant:tenant_8:orders"

	header := http.Header{}
	header.Set(DefaultTenantHeader, "tenant_7")

	_, resp, err := websocket.DefaultDialer.Dial(url, header)
	if err == nil {
		t.Fatal("expected websocket dial error for cross-tenant channel")
	}
	if resp == nil {
		t.Fatal("expected HTTP response")
	}
	if resp.StatusCode != http.StatusForbidden {
		t.Fatalf("expected 403, got %d", resp.StatusCode)
	}
}

func TestSSERuntimeDeniesCrossTenantChannel(t *testing.T) {
	runtime := NewSSERuntime(DefaultSSERuntimeConfig())
	server := httptest.NewServer(runtime)
	defer server.Close()

	req, err := http.NewRequest(http.MethodGet, server.URL+"?channel=tenant:tenant_8:orders", nil)
	if err != nil {
		t.Fatalf("request build failed: %v", err)
	}
	req.Header.Set(DefaultTenantHeader, "tenant_7")

	resp, err := server.Client().Do(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusForbidden {
		t.Fatalf("expected 403, got %d", resp.StatusCode)
	}
}
