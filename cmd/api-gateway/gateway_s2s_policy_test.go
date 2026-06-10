package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

type internalPolicyTestResponse struct {
	Status string `json:"status"`
	Scope  string `json:"scope"`
	Policy struct {
		PublicPrefixes        []string `json:"public_prefixes"`
		ProtectedPrefixes     []string `json:"protected_prefixes"`
		InternalPrefixes      []string `json:"internal_prefixes"`
		InternalKeyHeader     string   `json:"internal_key_header"`
		InternalKeyConfigured bool     `json:"internal_key_configured"`
		RateLimitPerMinute    int      `json:"rate_limit_per_minute"`
		DailyQuota            int      `json:"daily_quota"`
		HealthTimeoutMS       int      `json:"health_timeout_ms"`
		APITimeoutMS          int      `json:"api_timeout_ms"`
		QueryTimeoutMS        int      `json:"query_timeout_ms"`
	} `json:"policy"`
}

type internalRoutesTestResponse struct {
	Status      string              `json:"status"`
	Scope       string              `json:"scope"`
	TotalRoutes int                 `json:"total_routes"`
	Routes      gatewayRouteCatalog `json:"routes"`
}

func containsString(list []string, target string) bool {
	for _, item := range list {
		if item == target {
			return true
		}
	}
	return false
}

func findRouteByPath(list []gatewayRouteRecord, path string) (gatewayRouteRecord, bool) {
	for _, item := range list {
		if item.Path == path {
			return item, true
		}
	}
	return gatewayRouteRecord{}, false
}

func TestS2SPolicyCatalogRegistersInternalRoutes(t *testing.T) {
	t.Setenv("GATEWAY_INTERNAL_KEY", "route-secret-001")

	cfg := gatewayConfig{
		JWTSecret:                 "dev-jwt-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              3000,
		QueryTimeoutMS:            5000,
	}

	mux := http.NewServeMux()
	catalog := newGatewayRouteCatalog()

	registerInternalRoutes(mux, catalog, cfg)

	if !catalog.has(http.MethodGet, "/internal/routes", routeScopeInternal) {
		t.Fatalf("internal routes katalogunda /internal/routes yok")
	}

	if !catalog.has(http.MethodGet, "/internal/policy", routeScopeInternal) {
		t.Fatalf("internal routes katalogunda /internal/policy yok")
	}

	if !catalog.has(http.MethodGet, "/api/me", routeScopeProtected) {
		t.Fatalf("protected katalogda /api/me yok")
	}

	if !catalog.has(http.MethodGet, "/health", routeScopePublic) {
		t.Fatalf("public katalogda /health yok")
	}

	if catalog.total() < 10 {
		t.Fatalf("toplam route sayisi beklenenden dusuk: %d", catalog.total())
	}
}

func TestS2SPolicyEndpointReturnsInternalContract(t *testing.T) {
	t.Setenv("GATEWAY_INTERNAL_KEY", "route-secret-001")

	cfg := gatewayConfig{
		JWTSecret:                 "dev-jwt-secret",
		DefaultRateLimitPerMinute: 7,
		DefaultDailyQuota:         70,
		HealthTimeoutMS:           1700,
		APITimeoutMS:              2700,
		QueryTimeoutMS:            3700,
	}

	mux := http.NewServeMux()
	catalog := newGatewayRouteCatalog()

	registerInternalRoutes(mux, catalog, cfg)

	req := httptest.NewRequest(http.MethodGet, "/internal/policy", nil)
	req.Header.Set("X-Gateway-Internal-Key", "route-secret-001")

	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("beklenen 200, gelen %d", rec.Code)
	}

	var resp internalPolicyTestResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("internal policy json parse hatasi: %v", err)
	}

	if resp.Status != "ok" {
		t.Fatalf("status ok olmali, gelen %q", resp.Status)
	}

	if resp.Scope != "internal_policy" {
		t.Fatalf("scope internal_policy olmali, gelen %q", resp.Scope)
	}

	if !containsString(resp.Policy.PublicPrefixes, "/health") {
		t.Fatalf("public prefix /health olmali")
	}

	if !containsString(resp.Policy.ProtectedPrefixes, "/api") {
		t.Fatalf("protected prefix /api olmali")
	}

	if !containsString(resp.Policy.InternalPrefixes, "/internal") {
		t.Fatalf("internal prefix /internal olmali")
	}

	if resp.Policy.InternalKeyHeader != "X-Gateway-Internal-Key" {
		t.Fatalf("internal key header beklenenden farkli: %q", resp.Policy.InternalKeyHeader)
	}

	if !resp.Policy.InternalKeyConfigured {
		t.Fatalf("internal key configured true olmali")
	}

	if resp.Policy.RateLimitPerMinute != 7 {
		t.Fatalf("rate limit 7 olmali, gelen %d", resp.Policy.RateLimitPerMinute)
	}

	if resp.Policy.DailyQuota != 70 {
		t.Fatalf("daily quota 70 olmali, gelen %d", resp.Policy.DailyQuota)
	}

	if resp.Policy.HealthTimeoutMS != 1700 {
		t.Fatalf("health timeout 1700 olmali, gelen %d", resp.Policy.HealthTimeoutMS)
	}

	if resp.Policy.APITimeoutMS != 2700 {
		t.Fatalf("api timeout 2700 olmali, gelen %d", resp.Policy.APITimeoutMS)
	}

	if resp.Policy.QueryTimeoutMS != 3700 {
		t.Fatalf("query timeout 3700 olmali, gelen %d", resp.Policy.QueryTimeoutMS)
	}
}

func TestS2SRoutesEndpointReturnsScopedAuthMetadata(t *testing.T) {
	t.Setenv("GATEWAY_INTERNAL_KEY", "route-secret-001")

	cfg := gatewayConfig{
		JWTSecret:                 "dev-jwt-secret",
		DefaultRateLimitPerMinute: 3,
		DefaultDailyQuota:         10,
		HealthTimeoutMS:           1500,
		APITimeoutMS:              3000,
		QueryTimeoutMS:            5000,
	}

	mux := http.NewServeMux()
	catalog := newGatewayRouteCatalog()

	registerInternalRoutes(mux, catalog, cfg)

	req := httptest.NewRequest(http.MethodGet, "/internal/routes", nil)
	req.Header.Set("X-Gateway-Internal-Key", "route-secret-001")

	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("beklenen 200, gelen %d", rec.Code)
	}

	var resp internalRoutesTestResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("internal routes json parse hatasi: %v", err)
	}

	if resp.Status != "ok" {
		t.Fatalf("status ok olmali, gelen %q", resp.Status)
	}

	if resp.Scope != "internal_routes" {
		t.Fatalf("scope internal_routes olmali, gelen %q", resp.Scope)
	}

	if resp.TotalRoutes != resp.Routes.total() {
		t.Fatalf("toplam route sayisi uyusmuyor: total=%d katalog=%d", resp.TotalRoutes, resp.Routes.total())
	}

	internalRoutesRecord, ok := findRouteByPath(resp.Routes.Internal, "/internal/routes")
	if !ok {
		t.Fatalf("/internal/routes internal katalogda bulunamadi")
	}

	if internalRoutesRecord.Auth != "internal_key" {
		t.Fatalf("/internal/routes auth internal_key olmali, gelen %q", internalRoutesRecord.Auth)
	}

	internalPolicyRecord, ok := findRouteByPath(resp.Routes.Internal, "/internal/policy")
	if !ok {
		t.Fatalf("/internal/policy internal katalogda bulunamadi")
	}

	if internalPolicyRecord.Auth != "internal_key" {
		t.Fatalf("/internal/policy auth internal_key olmali, gelen %q", internalPolicyRecord.Auth)
	}

	protectedMeRecord, ok := findRouteByPath(resp.Routes.Protected, "/api/me")
	if !ok {
		t.Fatalf("/api/me protected katalogda bulunamadi")
	}

	if protectedMeRecord.Auth != "jwt+tenant" {
		t.Fatalf("/api/me auth jwt+tenant olmali, gelen %q", protectedMeRecord.Auth)
	}

	publicHealthRecord, ok := findRouteByPath(resp.Routes.Public, "/health")
	if !ok {
		t.Fatalf("/health public katalogda bulunamadi")
	}

	if publicHealthRecord.Auth != "none" {
		t.Fatalf("/health auth none olmali, gelen %q", publicHealthRecord.Auth)
	}
}
