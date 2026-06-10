package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type stubLimiter struct {
	tanimCalls int
	istekCalls int
	lastTenant string
	lastLimit  int
	tanimErr   error
	istekErr   error
}

type gatewayErrorBody struct {
	Status        string `json:"status"`
	Code          string `json:"code"`
	Error         string `json:"error"`
	HTTPStatus    int    `json:"http_status"`
	Source        string `json:"source"`
	RequestID     string `json:"request_id"`
	CorrelationID string `json:"correlation_id"`
	TenantID      string `json:"tenant_id"`
	Middleware    string `json:"middleware"`
	TimeoutPolicy string `json:"timeout_policy"`
	TimeoutMS     int64  `json:"timeout_ms"`
	Limit         int    `json:"limit"`
	Quota         int    `json:"quota"`
}

type healthComponentBody struct {
	Name       string         `json:"name"`
	OK         bool           `json:"ok"`
	Status     string         `json:"status"`
	HTTPStatus int            `json:"http_status"`
	DurationMS int64          `json:"duration_ms"`
	Error      string         `json:"error"`
	Details    map[string]any `json:"details"`
}

type healthAggregateBody struct {
	Status        string                `json:"status"`
	Service       string                `json:"service"`
	Scope         string                `json:"scope"`
	TimeoutMS     int64                 `json:"timeout_ms"`
	Components    []healthComponentBody `json:"components"`
	RequestID     string                `json:"request_id"`
	CorrelationID string                `json:"correlation_id"`
}

func (s *stubLimiter) TenantTanimla(tenantID string, limit int) error {
	s.tanimCalls++
	s.lastTenant = tenantID
	s.lastLimit = limit
	return s.tanimErr
}

func (s *stubLimiter) IstekGecir(tenantID string) error {
	s.istekCalls++
	s.lastTenant = tenantID
	return s.istekErr
}

func testTokenOlustur(
	t *testing.T,
	secret string,
	tenantID string,
) string {
	t.Helper()

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"tenant_id": tenantID,
		"role":      "admin",
		"sub":       "1",
	})

	signed, err := token.SignedString([]byte(secret))
	if err != nil {
		t.Fatalf("token olusturma hatasi: %v", err)
	}

	return signed
}

func decodeGatewayError(
	t *testing.T,
	rr *httptest.ResponseRecorder,
) gatewayErrorBody {
	t.Helper()

	var body gatewayErrorBody
	if err := json.Unmarshal(rr.Body.Bytes(), &body); err != nil {
		t.Fatalf("json parse hatasi: %v", err)
	}

	return body
}

func decodeHealthAggregate(
	t *testing.T,
	rr *httptest.ResponseRecorder,
) healthAggregateBody {
	t.Helper()

	var body healthAggregateBody
	if err := json.Unmarshal(rr.Body.Bytes(), &body); err != nil {
		t.Fatalf("health json parse hatasi: %v", err)
	}

	return body
}

func findHealthComponent(
	t *testing.T,
	components []healthComponentBody,
	name string,
) healthComponentBody {
	t.Helper()

	for _, item := range components {
		if item.Name == name {
			return item
		}
	}

	t.Fatalf("component bulunamadi: %s", name)
	return healthComponentBody{}
}

func TestRequestIdentityGeneratesHeadersAndContext(t *testing.T) {
	finalHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestID := requestIDFromContext(r.Context())
		correlationID := correlationIDFromContext(r.Context())

		if requestID == "" {
			t.Fatalf("request id bos olmamali")
		}

		if correlationID == "" {
			t.Fatalf("correlation id bos olmamali")
		}

		if correlationID != requestID {
			t.Fatalf("header yokken correlation id request id ile ayni olmali")
		}

		w.WriteHeader(http.StatusOK)
	})

	handler := chain(
		finalHandler,
		requestIdentityMiddleware(),
	)

	req := httptest.NewRequest(http.MethodGet, "/health/live", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("beklenen 200, gelen %d", rr.Code)
	}

	if rr.Header().Get("X-Request-ID") == "" {
		t.Fatalf("response header X-Request-ID bos olmamali")
	}

	if rr.Header().Get("X-Correlation-ID") == "" {
		t.Fatalf("response header X-Correlation-ID bos olmamali")
	}
}

func TestRequestIdentityUsesIncomingHeaders(t *testing.T) {
	finalHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestID := requestIDFromContext(r.Context())
		correlationID := correlationIDFromContext(r.Context())

		if requestID != "req-manuel-001" {
			t.Fatalf("beklenen req-manuel-001, gelen %s", requestID)
		}

		if correlationID != "corr-manuel-001" {
			t.Fatalf("beklenen corr-manuel-001, gelen %s", correlationID)
		}

		w.WriteHeader(http.StatusOK)
	})

	handler := chain(
		finalHandler,
		requestIdentityMiddleware(),
	)

	req := httptest.NewRequest(http.MethodGet, "/health/live", nil)
	req.Header.Set("X-Request-ID", "req-manuel-001")
	req.Header.Set("X-Correlation-ID", "corr-manuel-001")

	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Header().Get("X-Request-ID") != "req-manuel-001" {
		t.Fatalf("response X-Request-ID beklenen req-manuel-001")
	}

	if rr.Header().Get("X-Correlation-ID") != "corr-manuel-001" {
		t.Fatalf("response X-Correlation-ID beklenen corr-manuel-001")
	}
}

func TestTraceMiddlewareKeepsStatusAndHeaders(t *testing.T) {
	finalHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if requestIDFromContext(r.Context()) == "" {
			t.Fatalf("trace icinde request id gorunmeli")
		}

		if correlationIDFromContext(r.Context()) == "" {
			t.Fatalf("trace icinde correlation id gorunmeli")
		}

		w.WriteHeader(http.StatusNoContent)
	})

	handler := chain(
		finalHandler,
		requestIdentityMiddleware(),
		traceMiddleware(),
	)

	req := httptest.NewRequest(http.MethodGet, "/api/me", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusNoContent {
		t.Fatalf("beklenen 204, gelen %d", rr.Code)
	}

	if rr.Header().Get("X-Request-ID") == "" {
		t.Fatalf("trace response icinde request id olmali")
	}

	if rr.Header().Get("X-Correlation-ID") == "" {
		t.Fatalf("trace response icinde correlation id olmali")
	}
}

func TestTimeoutMiddlewareTimesOut(t *testing.T) {
	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           5,
		APITimeoutMS:              5,
		QueryTimeoutMS:            5,
	}

	finalHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(30 * time.Millisecond)
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("gecmemeli"))
	})

	handler := chain(
		finalHandler,
		requestIdentityMiddleware(),
		timeoutPolicyMiddleware(cfg),
	)

	req := httptest.NewRequest(http.MethodGet, "/api/me", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusGatewayTimeout {
		t.Fatalf("beklenen 504, gelen %d", rr.Code)
	}

	body := decodeGatewayError(t, rr)

	if body.Code != "gateway_timeout" {
		t.Fatalf("beklenen gateway_timeout, gelen %s", body.Code)
	}

	if body.HTTPStatus != http.StatusGatewayTimeout {
		t.Fatalf("beklenen http_status 504, gelen %d", body.HTTPStatus)
	}

	if body.Source != "api_gateway" {
		t.Fatalf("beklenen source api_gateway, gelen %s", body.Source)
	}

	if body.TimeoutPolicy != "api" {
		t.Fatalf("beklenen timeout policy api, gelen %s", body.TimeoutPolicy)
	}

	if body.RequestID == "" || body.CorrelationID == "" {
		t.Fatalf("request/correlation id bos olmamali")
	}
}

func TestTimeoutMiddlewareAllowsFastHandler(t *testing.T) {
	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           50,
		APITimeoutMS:              50,
		QueryTimeoutMS:            50,
	}

	finalHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(1 * time.Millisecond)
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})

	handler := chain(
		finalHandler,
		requestIdentityMiddleware(),
		timeoutPolicyMiddleware(cfg),
	)

	req := httptest.NewRequest(http.MethodGet, "/api/me", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("beklenen 200, gelen %d", rr.Code)
	}
}

func TestJWTMiddlewareMissingBearer(t *testing.T) {
	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              3000,
		QueryTimeoutMS:            5000,
	}

	handler := jwtAuthMiddleware(cfg)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Fatalf("next cagrilmamali")
	}))

	req := httptest.NewRequest(http.MethodGet, "/api/me", nil)
	req = req.WithContext(contextWithRequestIdentity(req.Context(), "req-001", "corr-001"))

	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Fatalf("beklenen 401, gelen %d", rr.Code)
	}

	body := decodeGatewayError(t, rr)

	if body.Code != "missing_authorization_header" {
		t.Fatalf("beklenen missing_authorization_header, gelen %s", body.Code)
	}

	if body.Source != "api_gateway" {
		t.Fatalf("beklenen source api_gateway, gelen %s", body.Source)
	}
}

func TestTenantMiddlewareRejectsMismatch(t *testing.T) {
	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              3000,
		QueryTimeoutMS:            5000,
	}

	finalHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Fatalf("mismatch durumda next cagrilmamali")
	})

	handler := chain(
		finalHandler,
		jwtAuthMiddleware(cfg),
		tenantMiddleware(),
	)

	req := httptest.NewRequest(http.MethodGet, "/api/me", nil)
	req = req.WithContext(contextWithRequestIdentity(req.Context(), "req-002", "corr-002"))
	req.Header.Set("Authorization", "Bearer "+testTokenOlustur(t, cfg.JWTSecret, "tenant-001"))
	req.Header.Set("X-Tenant-ID", "tenant-002")

	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusForbidden {
		t.Fatalf("beklenen 403, gelen %d", rr.Code)
	}

	body := decodeGatewayError(t, rr)

	if body.Code != "tenant_header_mismatch" {
		t.Fatalf("beklenen tenant_header_mismatch, gelen %s", body.Code)
	}

	if body.TenantID != "tenant-001" {
		t.Fatalf("beklenen tenant-001, gelen %s", body.TenantID)
	}
}

func TestRateLimitMiddlewareBlocksExceeded(t *testing.T) {
	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              3000,
		QueryTimeoutMS:            5000,
	}

	rateStub := &stubLimiter{
		istekErr: fmt.Errorf("rate limit asildi"),
	}
	quotaStub := &stubLimiter{}

	finalHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Fatalf("rate limit asildiginda next cagrilmamali")
	})

	handler := chain(
		finalHandler,
		jwtAuthMiddleware(cfg),
		tenantMiddleware(),
		rateLimitMiddleware(rateStub, cfg),
		quotaMiddleware(quotaStub, cfg),
	)

	req := httptest.NewRequest(http.MethodGet, "/api/me", nil)
	req = req.WithContext(contextWithRequestIdentity(req.Context(), "req-003", "corr-003"))
	req.Header.Set("Authorization", "Bearer "+testTokenOlustur(t, cfg.JWTSecret, "tenant-001"))
	req.Header.Set("X-Tenant-ID", "tenant-001")

	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusTooManyRequests {
		t.Fatalf("beklenen 429, gelen %d", rr.Code)
	}

	if quotaStub.istekCalls != 0 {
		t.Fatalf("rate limit fail iken quota cagrilmamali")
	}

	body := decodeGatewayError(t, rr)

	if body.Code != "rate_limit_exceeded" {
		t.Fatalf("beklenen rate_limit_exceeded, gelen %s", body.Code)
	}

	if body.Middleware != "rate_limit" {
		t.Fatalf("beklenen middleware rate_limit, gelen %s", body.Middleware)
	}

	if body.Limit != 3 {
		t.Fatalf("beklenen limit 3, gelen %d", body.Limit)
	}
}

func TestQuotaMiddlewareBlocksExceeded(t *testing.T) {
	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              3000,
		QueryTimeoutMS:            5000,
	}

	rateStub := &stubLimiter{}
	quotaStub := &stubLimiter{
		istekErr: fmt.Errorf("gunluk quota asildi"),
	}

	finalHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Fatalf("quota asildiginda next cagrilmamali")
	})

	handler := chain(
		finalHandler,
		jwtAuthMiddleware(cfg),
		tenantMiddleware(),
		rateLimitMiddleware(rateStub, cfg),
		quotaMiddleware(quotaStub, cfg),
	)

	req := httptest.NewRequest(http.MethodGet, "/api/me", nil)
	req = req.WithContext(contextWithRequestIdentity(req.Context(), "req-004", "corr-004"))
	req.Header.Set("Authorization", "Bearer "+testTokenOlustur(t, cfg.JWTSecret, "tenant-001"))
	req.Header.Set("X-Tenant-ID", "tenant-001")

	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusTooManyRequests {
		t.Fatalf("beklenen 429, gelen %d", rr.Code)
	}

	body := decodeGatewayError(t, rr)

	if body.Code != "quota_exceeded" {
		t.Fatalf("beklenen quota_exceeded, gelen %s", body.Code)
	}

	if body.Middleware != "quota" {
		t.Fatalf("beklenen middleware quota, gelen %s", body.Middleware)
	}

	if body.Quota != 10 {
		t.Fatalf("beklenen quota 10, gelen %d", body.Quota)
	}
}

func TestHealthAggregateReturnsCoreComponents(t *testing.T) {
	t.Setenv("IDENTITY_HEALTH_URL", "")
	t.Setenv("QUERY_READ_MODEL_HEALTH_URL", "")
	t.Setenv("MISSION_CONTROL_HEALTH_URL", "")
	t.Setenv("SERVICE_REGISTRY_HEALTH_URL", "")
	t.Setenv("CACHE_HEALTH_URL", "")

	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              3000,
		QueryTimeoutMS:            5000,
	}

	handler := newGatewayHandler(cfg, &stubLimiter{}, &stubLimiter{})

	req := httptest.NewRequest(http.MethodGet, "/health/aggregate", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusServiceUnavailable {
		t.Fatalf("beklenen 503, gelen %d", rr.Code)
	}

	body := decodeHealthAggregate(t, rr)

	if body.Scope != "aggregate" {
		t.Fatalf("beklenen aggregate, gelen %s", body.Scope)
	}

	if body.RequestID == "" || body.CorrelationID == "" {
		t.Fatalf("request/correlation id bos olmamali")
	}

	_ = findHealthComponent(t, body.Components, "gateway_policy")
	_ = findHealthComponent(t, body.Components, "write_db")
	_ = findHealthComponent(t, body.Components, "read_db")
	_ = findHealthComponent(t, body.Components, "replica_mode")
}

func TestHealthUpstreamsHealthyWhenConfiguredServiceUp(t *testing.T) {
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	}))
	defer upstream.Close()

	t.Setenv("IDENTITY_HEALTH_URL", upstream.URL)
	t.Setenv("QUERY_READ_MODEL_HEALTH_URL", "")
	t.Setenv("MISSION_CONTROL_HEALTH_URL", "")
	t.Setenv("SERVICE_REGISTRY_HEALTH_URL", "")
	t.Setenv("CACHE_HEALTH_URL", "")

	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              3000,
		QueryTimeoutMS:            5000,
	}

	handler := newGatewayHandler(cfg, &stubLimiter{}, &stubLimiter{})

	req := httptest.NewRequest(http.MethodGet, "/health/upstreams", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("beklenen 200, gelen %d", rr.Code)
	}

	body := decodeHealthAggregate(t, rr)

	if body.Scope != "upstreams" {
		t.Fatalf("beklenen upstreams, gelen %s", body.Scope)
	}

	component := findHealthComponent(t, body.Components, "identity_api")
	if !component.OK {
		t.Fatalf("identity_api ok olmali")
	}
}

func TestHealthUpstreamsDegradedWhenServiceFails(t *testing.T) {
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		_, _ = w.Write([]byte(`{"status":"error"}`))
	}))
	defer upstream.Close()

	t.Setenv("IDENTITY_HEALTH_URL", upstream.URL)
	t.Setenv("QUERY_READ_MODEL_HEALTH_URL", "")
	t.Setenv("MISSION_CONTROL_HEALTH_URL", "")
	t.Setenv("SERVICE_REGISTRY_HEALTH_URL", "")
	t.Setenv("CACHE_HEALTH_URL", "")

	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              3000,
		QueryTimeoutMS:            5000,
	}

	handler := newGatewayHandler(cfg, &stubLimiter{}, &stubLimiter{})

	req := httptest.NewRequest(http.MethodGet, "/health/upstreams", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusServiceUnavailable {
		t.Fatalf("beklenen 503, gelen %d", rr.Code)
	}

	body := decodeHealthAggregate(t, rr)

	component := findHealthComponent(t, body.Components, "identity_api")
	if component.OK {
		t.Fatalf("identity_api fail olmali")
	}
}

func TestGatewayNotFoundMappedJSON(t *testing.T) {
	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              3000,
		QueryTimeoutMS:            5000,
	}

	handler := newGatewayHandler(cfg, &stubLimiter{}, &stubLimiter{})

	req := httptest.NewRequest(http.MethodGet, "/olmayan-route", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusNotFound {
		t.Fatalf("beklenen 404, gelen %d", rr.Code)
	}

	body := decodeGatewayError(t, rr)

	if body.Code != "route_not_found" {
		t.Fatalf("beklenen route_not_found, gelen %s", body.Code)
	}

	if body.Source != "api_gateway" {
		t.Fatalf("beklenen source api_gateway, gelen %s", body.Source)
	}

	if body.RequestID == "" || body.CorrelationID == "" {
		t.Fatalf("request/correlation id bos olmamali")
	}
}

func TestProtectedChainAllowsValidTokenTenantRateAndQuota(t *testing.T) {
	cfg := gatewayConfig{
		JWTSecret:                 "test-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              3000,
		QueryTimeoutMS:            5000,
	}

	rateStub := &stubLimiter{}
	quotaStub := &stubLimiter{}

	finalHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		tenantID := tenantIDFromContext(r.Context())
		if tenantID != "tenant-001" {
			t.Fatalf("beklenen tenant-001, gelen %s", tenantID)
		}

		if requestIDFromContext(r.Context()) == "" {
			t.Fatalf("request id contextte olmali")
		}

		if correlationIDFromContext(r.Context()) == "" {
			t.Fatalf("correlation id contextte olmali")
		}

		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})

	handler := chain(
		finalHandler,
		jwtAuthMiddleware(cfg),
		tenantMiddleware(),
		rateLimitMiddleware(rateStub, cfg),
		quotaMiddleware(quotaStub, cfg),
	)

	req := httptest.NewRequest(http.MethodGet, "/api/me", nil)
	req = req.WithContext(contextWithRequestIdentity(req.Context(), "req-005", "corr-005"))
	req.Header.Set("Authorization", "Bearer "+testTokenOlustur(t, cfg.JWTSecret, "tenant-001"))
	req.Header.Set("X-Tenant-ID", "tenant-001")

	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("beklenen 200, gelen %d", rr.Code)
	}

	if rateStub.istekCalls != 1 {
		t.Fatalf("rate limit middleware 1 kez calismali")
	}

	if quotaStub.istekCalls != 1 {
		t.Fatalf("quota middleware 1 kez calismali")
	}
}

func contextWithRequestIdentity(
	ctx context.Context,
	requestID string,
	correlationID string,
) context.Context {
	ctx = context.WithValue(ctx, gatewayRequestIDKey, requestID)
	ctx = context.WithValue(ctx, gatewayCorrelationIDKey, correlationID)
	return ctx
}

func TestGatewayListenAddrFromPortDefaultBind(t *testing.T) {
	t.Setenv("GATEWAY_BIND_ADDR", "")
	got := gatewayListenAddrFromPort("9010")
	want := "127.0.0.1:9010"
	if got != want {
		t.Fatalf("beklenen %s, gelen %s", want, got)
	}
}

func TestGatewayListenAddrFromPortUsesEnvBind(t *testing.T) {
	t.Setenv("GATEWAY_BIND_ADDR", "127.0.0.1")
	got := gatewayListenAddrFromPort("9901")
	want := "127.0.0.1:9901"
	if got != want {
		t.Fatalf("beklenen %s, gelen %s", want, got)
	}
}
