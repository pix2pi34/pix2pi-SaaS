package main

import (
	"net/http"
	"os"
	"sort"
	"strings"
)

type gatewayRouteRecord struct {
	Method      string `json:"method"`
	Path        string `json:"path"`
	Scope       string `json:"scope"`
	Auth        string `json:"auth"`
	Description string `json:"description"`
}

type gatewayRouteCatalog struct {
	Public    []gatewayRouteRecord `json:"public"`
	Protected []gatewayRouteRecord `json:"protected"`
	Internal  []gatewayRouteRecord `json:"internal"`
}

func newGatewayRouteCatalog() *gatewayRouteCatalog {
	return &gatewayRouteCatalog{
		Public:    make([]gatewayRouteRecord, 0),
		Protected: make([]gatewayRouteRecord, 0),
		Internal:  make([]gatewayRouteRecord, 0),
	}
}

func (c *gatewayRouteCatalog) has(
	method string,
	path string,
	scope routeScope,
) bool {
	targetScope := string(scope)

	all := make([]gatewayRouteRecord, 0, len(c.Public)+len(c.Protected)+len(c.Internal))
	all = append(all, c.Public...)
	all = append(all, c.Protected...)
	all = append(all, c.Internal...)

	for _, item := range all {
		if item.Method == method && item.Path == path && item.Scope == targetScope {
			return true
		}
	}

	return false
}

func (c *gatewayRouteCatalog) add(
	method string,
	path string,
	scope routeScope,
	auth string,
	description string,
) {
	if c.has(method, path, scope) {
		return
	}

	record := gatewayRouteRecord{
		Method:      method,
		Path:        path,
		Scope:       string(scope),
		Auth:        auth,
		Description: description,
	}

	switch scope {
	case routeScopePublic:
		c.Public = append(c.Public, record)
	case routeScopeProtected:
		c.Protected = append(c.Protected, record)
	case routeScopeInternal:
		c.Internal = append(c.Internal, record)
	}

	c.sort()
}

func (c *gatewayRouteCatalog) sort() {
	sort.Slice(c.Public, func(i, j int) bool {
		return c.Public[i].Path < c.Public[j].Path
	})
	sort.Slice(c.Protected, func(i, j int) bool {
		return c.Protected[i].Path < c.Protected[j].Path
	})
	sort.Slice(c.Internal, func(i, j int) bool {
		return c.Internal[i].Path < c.Internal[j].Path
	})
}

func (c *gatewayRouteCatalog) total() int {
	return len(c.Public) + len(c.Protected) + len(c.Internal)
}

func internalGatewayKeyGetir() string {
	return strings.TrimSpace(os.Getenv("GATEWAY_INTERNAL_KEY"))
}

func internalKeyMiddleware() middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			expected := internalGatewayKeyGetir()
			if expected == "" {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusServiceUnavailable,
					"internal_gateway_key_missing",
					"gateway internal key tanimli degil",
					map[string]any{
						"middleware": "internal_key",
					},
				)
				return
			}

			provided := strings.TrimSpace(r.Header.Get("X-Gateway-Internal-Key"))
			if provided == "" {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusForbidden,
					"missing_internal_gateway_key",
					"X-Gateway-Internal-Key zorunlu",
					map[string]any{
						"middleware": "internal_key",
					},
				)
				return
			}

			if provided != expected {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusForbidden,
					"invalid_internal_gateway_key",
					"gateway internal key gecersiz",
					map[string]any{
						"middleware": "internal_key",
					},
				)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

func handleStandardRoute(
	mux *http.ServeMux,
	catalog *gatewayRouteCatalog,
	method string,
	path string,
	scope routeScope,
	auth string,
	description string,
	handler http.HandlerFunc,
) {
	catalog.add(method, path, scope, auth, description)

	mux.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
		if r.Method != method {
			writeGatewayError(
				w,
				r.Context(),
				http.StatusMethodNotAllowed,
				"method_not_allowed",
				"bu route icin method desteklenmiyor",
				map[string]any{
					"allowed_method": method,
					"path":           path,
					"scope":          string(scope),
				},
			)
			return
		}

		handler(w, r)
	})
}

func seedGatewayCatalog(catalog *gatewayRouteCatalog) {
	// Public routes
	catalog.add(http.MethodGet, "/health", routeScopePublic, "none", "gateway genel health")
	catalog.add(http.MethodGet, "/health/live", routeScopePublic, "none", "liveness kontrolu")
	catalog.add(http.MethodGet, "/health/ready", routeScopePublic, "none", "readiness kontrolu")
	catalog.add(http.MethodGet, "/health/db", routeScopePublic, "none", "db health kontrolu")
	catalog.add(http.MethodGet, "/health/replica", routeScopePublic, "none", "replica health kontrolu")
	catalog.add(http.MethodGet, "/health/gateway-policy", routeScopePublic, "none", "gateway policy health")
	catalog.add(http.MethodGet, "/health/upstreams", routeScopePublic, "none", "upstream servis health")
	catalog.add(http.MethodGet, "/health/aggregate", routeScopePublic, "none", "aggregate health")
	catalog.add(http.MethodGet, "/health/routes", routeScopePublic, "none", "public route ozeti")

	// Protected routes
	catalog.add(http.MethodGet, "/api/me", routeScopeProtected, "jwt+tenant", "kullanici baglam bilgisi")
	catalog.add(http.MethodGet, "/api/query/users", routeScopeProtected, "jwt+tenant", "query users")
	catalog.add(http.MethodGet, "/api/query/users/list", routeScopeProtected, "jwt+tenant", "query user list")
	catalog.add(http.MethodGet, "/api/query/users/", routeScopeProtected, "jwt+tenant", "tekil user query")
	catalog.add(http.MethodPost, "/api/v1/erp/runtime/flows", routeScopeProtected, "jwt+tenant", "erp runtime flow create")
}

func registerInternalRoutes(
	mux *http.ServeMux,
	catalog *gatewayRouteCatalog,
	cfg gatewayConfig,
) {
	seedGatewayCatalog(catalog)

	routesHandler := internalKeyMiddleware()(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"status":         "ok",
			"service":        "api-gateway",
			"scope":          "internal_routes",
			"total_routes":   catalog.total(),
			"routes":         catalog,
			"request_id":     requestIDFromContext(r.Context()),
			"correlation_id": correlationIDFromContext(r.Context()),
		})
	}))

	policyHandler := internalKeyMiddleware()(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"status":  "ok",
			"service": "api-gateway",
			"scope":   "internal_policy",
			"policy": map[string]any{
				"public_prefixes": []string{
					"/health",
				},
				"protected_prefixes": []string{
					"/api",
				},
				"internal_prefixes": []string{
					"/internal",
				},
				"internal_key_header":     "X-Gateway-Internal-Key",
				"internal_key_configured": internalGatewayKeyGetir() != "",
				"rate_limit_per_minute":   cfg.DefaultRateLimitPerMinute,
				"daily_quota":             cfg.DefaultDailyQuota,
				"health_timeout_ms":       cfg.HealthTimeoutMS,
				"api_timeout_ms":          cfg.APITimeoutMS,
				"query_timeout_ms":        cfg.QueryTimeoutMS,
			},
			"request_id":     requestIDFromContext(r.Context()),
			"correlation_id": correlationIDFromContext(r.Context()),
		})
	}))

	handleStandardRoute(
		mux,
		catalog,
		http.MethodGet,
		"/internal/routes",
		routeScopeInternal,
		"internal_key",
		"gateway route catalog",
		func(w http.ResponseWriter, r *http.Request) {
			routesHandler.ServeHTTP(w, r)
		},
	)

	handleStandardRoute(
		mux,
		catalog,
		http.MethodGet,
		"/internal/policy",
		routeScopeInternal,
		"internal_key",
		"gateway route policy summary",
		func(w http.ResponseWriter, r *http.Request) {
			policyHandler.ServeHTTP(w, r)
		},
	)
}
