package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

type testGatewayRouteRecord struct {
	Method      string `json:"method"`
	Path        string `json:"path"`
	Scope       string `json:"scope"`
	Auth        string `json:"auth"`
	Description string `json:"description"`
}

type internalRoutesBody struct {
	Status        string `json:"status"`
	Service       string `json:"service"`
	Scope         string `json:"scope"`
	TotalRoutes   int    `json:"total_routes"`
	RequestID     string `json:"request_id"`
	CorrelationID string `json:"correlation_id"`
	Routes        struct {
		Public    []testGatewayRouteRecord `json:"public"`
		Protected []testGatewayRouteRecord `json:"protected"`
		Internal  []testGatewayRouteRecord `json:"internal"`
	} `json:"routes"`
}

type internalPolicyBody struct {
	Status        string `json:"status"`
	Service       string `json:"service"`
	Scope         string `json:"scope"`
	RequestID     string `json:"request_id"`
	CorrelationID string `json:"correlation_id"`
	Policy        struct {
		InternalKeyConfigured bool `json:"internal_key_configured"`
	} `json:"policy"`
}

func decodeInternalRoutesBody(
	t *testing.T,
	rr *httptest.ResponseRecorder,
) internalRoutesBody {
	t.Helper()

	var body internalRoutesBody
	if err := json.Unmarshal(rr.Body.Bytes(), &body); err != nil {
		t.Fatalf("internal routes json parse hatasi: %v", err)
	}

	return body
}

func decodeInternalPolicyBody(
	t *testing.T,
	rr *httptest.ResponseRecorder,
) internalPolicyBody {
	t.Helper()

	var body internalPolicyBody
	if err := json.Unmarshal(rr.Body.Bytes(), &body); err != nil {
		t.Fatalf("internal policy json parse hatasi: %v", err)
	}

	return body
}

func TestInternalRoutesRequireInternalKey(t *testing.T) {
	t.Setenv("GATEWAY_INTERNAL_KEY", "route-secret-001")

	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              3000,
		QueryTimeoutMS:            5000,
	}

	handler := newGatewayHandler(cfg, &stubLimiter{}, &stubLimiter{})

	req := httptest.NewRequest(http.MethodGet, "/internal/routes", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusForbidden {
		t.Fatalf("beklenen 403, gelen %d", rr.Code)
	}

	body := decodeGatewayError(t, rr)
	if body.Code != "missing_internal_gateway_key" {
		t.Fatalf("beklenen missing_internal_gateway_key, gelen %s", body.Code)
	}
}

func TestInternalRoutesAllowValidInternalKey(t *testing.T) {
	t.Setenv("GATEWAY_INTERNAL_KEY", "route-secret-001")

	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              3000,
		QueryTimeoutMS:            5000,
	}

	handler := newGatewayHandler(cfg, &stubLimiter{}, &stubLimiter{})

	req := httptest.NewRequest(http.MethodGet, "/internal/routes", nil)
	req.Header.Set("X-Gateway-Internal-Key", "route-secret-001")

	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("beklenen 200, gelen %d", rr.Code)
	}

	body := decodeInternalRoutesBody(t, rr)

	if body.Scope != "internal_routes" {
		t.Fatalf("beklenen internal_routes, gelen %s", body.Scope)
	}

	if body.TotalRoutes <= 0 {
		t.Fatalf("route catalog bos olmamali")
	}

	if len(body.Routes.Public) == 0 {
		t.Fatalf("public route listesi bos olmamali")
	}

	if len(body.Routes.Protected) == 0 {
		t.Fatalf("protected route listesi bos olmamali")
	}

	if len(body.Routes.Internal) == 0 {
		t.Fatalf("internal route listesi bos olmamali")
	}

	if body.RequestID == "" || body.CorrelationID == "" {
		t.Fatalf("request/correlation id bos olmamali")
	}
}

func TestInternalPolicyAllowValidInternalKey(t *testing.T) {
	t.Setenv("GATEWAY_INTERNAL_KEY", "route-secret-001")

	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              3000,
		QueryTimeoutMS:            5000,
	}

	handler := newGatewayHandler(cfg, &stubLimiter{}, &stubLimiter{})

	req := httptest.NewRequest(http.MethodGet, "/internal/policy", nil)
	req.Header.Set("X-Gateway-Internal-Key", "route-secret-001")

	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("beklenen 200, gelen %d", rr.Code)
	}

	body := decodeInternalPolicyBody(t, rr)

	if body.Scope != "internal_policy" {
		t.Fatalf("beklenen internal_policy, gelen %s", body.Scope)
	}

	if !body.Policy.InternalKeyConfigured {
		t.Fatalf("internal key configured true olmali")
	}
}

func TestRouteStandardRejectsWrongMethod(t *testing.T) {
	t.Setenv("GATEWAY_INTERNAL_KEY", "route-secret-001")

	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              3000,
		QueryTimeoutMS:            5000,
	}

	handler := newGatewayHandler(cfg, &stubLimiter{}, &stubLimiter{})

	req := httptest.NewRequest(http.MethodPost, "/health/live", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusMethodNotAllowed {
		t.Fatalf("beklenen 405, gelen %d", rr.Code)
	}

	body := decodeGatewayError(t, rr)

	if body.Code != "method_not_allowed" {
		t.Fatalf("beklenen method_not_allowed, gelen %s", body.Code)
	}
}
