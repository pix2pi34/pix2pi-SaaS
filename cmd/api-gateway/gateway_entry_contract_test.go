package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func buildGatewayEntryCatalogForTest(t *testing.T) *gatewayRouteCatalog {
	t.Helper()

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

	return catalog
}

func allGatewayRoutes(catalog *gatewayRouteCatalog) []gatewayRouteRecord {
	all := make([]gatewayRouteRecord, 0, len(catalog.Public)+len(catalog.Protected)+len(catalog.Internal))
	all = append(all, catalog.Public...)
	all = append(all, catalog.Protected...)
	all = append(all, catalog.Internal...)
	return all
}

func TestGatewayEntryCatalogUsesOnlyAllowedPrefixes(t *testing.T) {
	catalog := buildGatewayEntryCatalogForTest(t)

	allowedPrefixes := []string{
		"/health",
		"/api",
		"/internal",
	}

	for _, route := range allGatewayRoutes(catalog) {
		ok := false
		for _, prefix := range allowedPrefixes {
			if strings.HasPrefix(route.Path, prefix) {
				ok = true
				break
			}
		}

		if !ok {
			t.Fatalf("izin verilmeyen route bulundu: %s", route.Path)
		}
	}
}

func TestGatewayEntryCatalogHasNoLegacyRootLeaks(t *testing.T) {
	catalog := buildGatewayEntryCatalogForTest(t)

	for _, route := range allGatewayRoutes(catalog) {
		switch route.Path {
		case "/me", "/query/users", "/query/users/list", "/policy", "/routes":
			t.Fatalf("legacy kok route sizmasi bulundu: %s", route.Path)
		}
	}
}

func TestGatewayEntryCatalogScopeAuthContract(t *testing.T) {
	catalog := buildGatewayEntryCatalogForTest(t)

	for _, route := range catalog.Public {
		if route.Auth != "none" {
			t.Fatalf("public route auth none olmali | path=%s auth=%s", route.Path, route.Auth)
		}
		if !strings.HasPrefix(route.Path, "/health") {
			t.Fatalf("public route /health altinda olmali | path=%s", route.Path)
		}
	}

	for _, route := range catalog.Protected {
		if route.Auth != "jwt+tenant" {
			t.Fatalf("protected route auth jwt+tenant olmali | path=%s auth=%s", route.Path, route.Auth)
		}
		if !strings.HasPrefix(route.Path, "/api") {
			t.Fatalf("protected route /api altinda olmali | path=%s", route.Path)
		}
	}

	for _, route := range catalog.Internal {
		if route.Auth != "internal_key" {
			t.Fatalf("internal route auth internal_key olmali | path=%s auth=%s", route.Path, route.Auth)
		}
		if !strings.HasPrefix(route.Path, "/internal") {
			t.Fatalf("internal route /internal altinda olmali | path=%s", route.Path)
		}
	}
}

func TestGatewayEntryInternalRoutesAreActuallyMounted(t *testing.T) {
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
}
