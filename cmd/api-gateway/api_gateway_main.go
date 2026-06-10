package main

import (
	"context"
	reportingruntime "github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/runtime"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	gatewayservice "github.com/divrigili/pix2pi-SaaS/internal/platform/gateway/service"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/kernel"
	query "github.com/divrigili/pix2pi-SaaS/internal/services/query_read_model"
	"gorm.io/gorm"
	"net"
)

type healthComponent struct {
	Name       string         `json:"name"`
	OK         bool           `json:"ok"`
	Status     string         `json:"status"`
	HTTPStatus int            `json:"http_status,omitempty"`
	DurationMS int64          `json:"duration_ms,omitempty"`
	Error      string         `json:"error,omitempty"`
	Details    map[string]any `json:"details,omitempty"`
}

type healthAggregateResponse struct {
	Status        string            `json:"status"`
	Service       string            `json:"service"`
	Scope         string            `json:"scope"`
	TimeoutMS     int64             `json:"timeout_ms"`
	Components    []healthComponent `json:"components"`
	RequestID     string            `json:"request_id"`
	CorrelationID string            `json:"correlation_id"`
}

type upstreamHealthTarget struct {
	Name string
	URL  string
}

type routeScope string

const (
	routeScopePublic    routeScope = "public"
	routeScopeProtected routeScope = "protected"
	routeScopeInternal  routeScope = "internal"
)

type routeRule struct {
	Name           string     `json:"name"`
	Path           string     `json:"path"`
	Scope          routeScope `json:"scope"`
	Methods        []string   `json:"methods"`
	Prefix         bool       `json:"prefix"`
	AuthRequired   bool       `json:"auth_required"`
	TenantRequired bool       `json:"tenant_required"`
	Description    string     `json:"description"`
}

type routeCatalogResponse struct {
	Status        string      `json:"status"`
	Service       string      `json:"service"`
	Scope         string      `json:"scope"`
	TotalRoutes   int         `json:"total_routes"`
	Routes        []routeRule `json:"routes"`
	RequestID     string      `json:"request_id"`
	CorrelationID string      `json:"correlation_id"`
}

func gatewayPortGetir() string {
	port := strings.TrimSpace(os.Getenv("API_GATEWAY_PORT"))
	if port != "" {
		return port
	}

	port = strings.TrimSpace(os.Getenv("GATEWAY_PORT"))
	if port != "" {
		return port
	}

	return "9010"
}

func gatewayRouteRules() []routeRule {
	rules := []routeRule{
		{
			Name:           "health_root",
			Path:           "/health",
			Scope:          routeScopePublic,
			Methods:        []string{http.MethodGet},
			Prefix:         false,
			AuthRequired:   false,
			TenantRequired: false,
			Description:    "gateway basic health root",
		},
		{
			Name:           "health_live",
			Path:           "/health/live",
			Scope:          routeScopePublic,
			Methods:        []string{http.MethodGet},
			Prefix:         false,
			AuthRequired:   false,
			TenantRequired: false,
			Description:    "gateway liveness",
		},
		{
			Name:           "health_ready",
			Path:           "/health/ready",
			Scope:          routeScopePublic,
			Methods:        []string{http.MethodGet},
			Prefix:         false,
			AuthRequired:   false,
			TenantRequired: false,
			Description:    "gateway readiness",
		},
		{
			Name:           "health_db",
			Path:           "/health/db",
			Scope:          routeScopePublic,
			Methods:        []string{http.MethodGet},
			Prefix:         false,
			AuthRequired:   false,
			TenantRequired: false,
			Description:    "gateway db health",
		},
		{
			Name:           "health_replica",
			Path:           "/health/replica",
			Scope:          routeScopePublic,
			Methods:        []string{http.MethodGet},
			Prefix:         false,
			AuthRequired:   false,
			TenantRequired: false,
			Description:    "gateway replica health",
		},
		{
			Name:           "health_gateway_policy",
			Path:           "/health/gateway-policy",
			Scope:          routeScopePublic,
			Methods:        []string{http.MethodGet},
			Prefix:         false,
			AuthRequired:   false,
			TenantRequired: false,
			Description:    "gateway policy health",
		},
		{
			Name:           "health_upstreams",
			Path:           "/health/upstreams",
			Scope:          routeScopePublic,
			Methods:        []string{http.MethodGet},
			Prefix:         false,
			AuthRequired:   false,
			TenantRequired: false,
			Description:    "gateway upstream aggregation",
		},
		{
			Name:           "health_aggregate",
			Path:           "/health/aggregate",
			Scope:          routeScopePublic,
			Methods:        []string{http.MethodGet},
			Prefix:         false,
			AuthRequired:   false,
			TenantRequired: false,
			Description:    "gateway full aggregate health",
		},
		{
			Name:           "health_routes",
			Path:           "/health/routes",
			Scope:          routeScopePublic,
			Methods:        []string{http.MethodGet},
			Prefix:         false,
			AuthRequired:   false,
			TenantRequired: false,
			Description:    "gateway route catalog",
		},
		{
			Name:           "api_me",
			Path:           "/api/me",
			Scope:          routeScopeProtected,
			Methods:        []string{http.MethodGet},
			Prefix:         false,
			AuthRequired:   true,
			TenantRequired: true,
			Description:    "protected self route",
		},
		{
			Name:           "api_query_users_count",
			Path:           "/api/query/users",
			Scope:          routeScopeProtected,
			Methods:        []string{http.MethodGet},
			Prefix:         false,
			AuthRequired:   true,
			TenantRequired: true,
			Description:    "protected user count route",
		},
		{
			Name:           "api_query_users_list",
			Path:           "/api/query/users/list",
			Scope:          routeScopeProtected,
			Methods:        []string{http.MethodGet},
			Prefix:         false,
			AuthRequired:   true,
			TenantRequired: true,
			Description:    "protected user list route",
		},
		{
			Name:           "api_query_user_detail",
			Path:           "/api/query/users/",
			Scope:          routeScopeProtected,
			Methods:        []string{http.MethodGet},
			Prefix:         true,
			AuthRequired:   true,
			TenantRequired: true,
			Description:    "protected user detail prefix",
		},
		{
			Name:           "internal_reserved",
			Path:           "/internal/",
			Scope:          routeScopeInternal,
			Methods:        []string{http.MethodGet, http.MethodPost, http.MethodPut, http.MethodPatch, http.MethodDelete},
			Prefix:         true,
			AuthRequired:   true,
			TenantRequired: false,
			Description:    "internal service-to-service namespace, external traffic blocked",
		},
	}
	return appendERPRuntimeGatewayRouteRule(rules)
}

func matchRouteRule(path string) (routeRule, bool) {
	rules := gatewayRouteRules()

	for _, rule := range rules {
		if rule.Prefix {
			continue
		}
		if rule.Path == path {
			return rule, true
		}
	}

	for _, rule := range rules {
		if !rule.Prefix {
			continue
		}
		if strings.HasPrefix(path, rule.Path) {
			return rule, true
		}
	}

	return routeRule{}, false
}

func methodAllowed(rule routeRule, method string) bool {
	normalized := strings.ToUpper(strings.TrimSpace(method))

	for _, allowed := range rule.Methods {
		if strings.ToUpper(strings.TrimSpace(allowed)) == normalized {
			return true
		}
		if normalized == http.MethodHead && strings.EqualFold(allowed, http.MethodGet) {
			return true
		}
	}

	return false
}

func applyRouteHeaders(w http.ResponseWriter, rule routeRule) {
	w.Header().Set("X-Gateway-Route-Name", rule.Name)
	w.Header().Set("X-Gateway-Route-Scope", string(rule.Scope))
	if rule.Prefix {
		w.Header().Set("X-Gateway-Route-Match", "prefix")
	} else {
		w.Header().Set("X-Gateway-Route-Match", "exact")
	}
}

func buildDBHealthComponent(name string, db *gorm.DB) healthComponent {
	start := time.Now()

	if db == nil {
		return healthComponent{
			Name:       name,
			OK:         false,
			Status:     "error",
			HTTPStatus: http.StatusServiceUnavailable,
			DurationMS: time.Since(start).Milliseconds(),
			Error:      name + " nil",
		}
	}

	if err := db.Exec("select 1").Error; err != nil {
		return healthComponent{
			Name:       name,
			OK:         false,
			Status:     "error",
			HTTPStatus: http.StatusServiceUnavailable,
			DurationMS: time.Since(start).Milliseconds(),
			Error:      err.Error(),
		}
	}

	return healthComponent{
		Name:       name,
		OK:         true,
		Status:     "ok",
		HTTPStatus: http.StatusOK,
		DurationMS: time.Since(start).Milliseconds(),
	}
}

func buildReplicaHealthComponent() healthComponent {
	start := time.Now()
	readDB := kernel.GetReadDB()

	if readDB == nil {
		return healthComponent{
			Name:       "replica_mode",
			OK:         false,
			Status:     "error",
			HTTPStatus: http.StatusServiceUnavailable,
			DurationMS: time.Since(start).Milliseconds(),
			Error:      "read db nil",
		}
	}

	var inRecovery bool
	if err := readDB.Raw("select pg_is_in_recovery()").Scan(&inRecovery).Error; err != nil {
		return healthComponent{
			Name:       "replica_mode",
			OK:         false,
			Status:     "error",
			HTTPStatus: http.StatusServiceUnavailable,
			DurationMS: time.Since(start).Milliseconds(),
			Error:      err.Error(),
		}
	}

	if !inRecovery {
		return healthComponent{
			Name:       "replica_mode",
			OK:         false,
			Status:     "warning",
			HTTPStatus: http.StatusConflict,
			DurationMS: time.Since(start).Milliseconds(),
			Error:      "read db replica modunda degil",
			Details: map[string]any{
				"replica_mode": false,
			},
		}
	}

	return healthComponent{
		Name:       "replica_mode",
		OK:         true,
		Status:     "ok",
		HTTPStatus: http.StatusOK,
		DurationMS: time.Since(start).Milliseconds(),
		Details: map[string]any{
			"replica_mode": true,
		},
	}
}

func buildGatewayPolicyHealthComponent(cfg gatewayConfig) healthComponent {
	return healthComponent{
		Name:       "gateway_policy",
		OK:         true,
		Status:     "ok",
		HTTPStatus: http.StatusOK,
		DurationMS: 0,
		Details: map[string]any{
			"rate_limit_per_minute": cfg.DefaultRateLimitPerMinute,
			"daily_quota":           cfg.DefaultDailyQuota,
			"health_timeout_ms":     cfg.HealthTimeoutMS,
			"api_timeout_ms":        cfg.APITimeoutMS,
			"query_timeout_ms":      cfg.QueryTimeoutMS,
		},
	}
}

func configuredHealthUpstreams() []upstreamHealthTarget {
	candidates := []upstreamHealthTarget{
		{Name: "identity_api", URL: strings.TrimSpace(os.Getenv("IDENTITY_HEALTH_URL"))},
		{Name: "query_read_model", URL: strings.TrimSpace(os.Getenv("QUERY_READ_MODEL_HEALTH_URL"))},
		{Name: "mission_control", URL: strings.TrimSpace(os.Getenv("MISSION_CONTROL_HEALTH_URL"))},
		{Name: "service_registry", URL: strings.TrimSpace(os.Getenv("SERVICE_REGISTRY_HEALTH_URL"))},
		{Name: "cache_service", URL: strings.TrimSpace(os.Getenv("CACHE_HEALTH_URL"))},
	}

	out := make([]upstreamHealthTarget, 0, len(candidates))
	for _, item := range candidates {
		if item.URL != "" {
			out = append(out, item)
		}
	}

	return out
}

func buildUpstreamHealthComponent(
	parentCtx context.Context,
	name string,
	url string,
	timeout time.Duration,
) healthComponent {
	start := time.Now()

	ctx, cancel := context.WithTimeout(parentCtx, timeout)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return healthComponent{
			Name:       name,
			OK:         false,
			Status:     "error",
			HTTPStatus: http.StatusInternalServerError,
			DurationMS: time.Since(start).Milliseconds(),
			Error:      err.Error(),
			Details: map[string]any{
				"url": url,
			},
		}
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return healthComponent{
			Name:       name,
			OK:         false,
			Status:     "error",
			HTTPStatus: http.StatusServiceUnavailable,
			DurationMS: time.Since(start).Milliseconds(),
			Error:      err.Error(),
			Details: map[string]any{
				"url": url,
			},
		}
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return healthComponent{
			Name:       name,
			OK:         false,
			Status:     "error",
			HTTPStatus: resp.StatusCode,
			DurationMS: time.Since(start).Milliseconds(),
			Error:      "upstream saglik cevabi basarisiz",
			Details: map[string]any{
				"url":         url,
				"status_code": resp.StatusCode,
			},
		}
	}

	return healthComponent{
		Name:       name,
		OK:         true,
		Status:     "ok",
		HTTPStatus: resp.StatusCode,
		DurationMS: time.Since(start).Milliseconds(),
		Details: map[string]any{
			"url":         url,
			"status_code": resp.StatusCode,
		},
	}
}

func buildUpstreamHealthComponents(
	ctx context.Context,
	cfg gatewayConfig,
) []healthComponent {
	timeout := time.Duration(cfg.HealthTimeoutMS) * time.Millisecond
	targets := configuredHealthUpstreams()

	components := make([]healthComponent, 0, len(targets))
	for _, target := range targets {
		components = append(
			components,
			buildUpstreamHealthComponent(ctx, target.Name, target.URL, timeout),
		)
	}

	return components
}

func aggregateHealthStatus(components []healthComponent) string {
	if len(components) == 0 {
		return "ok"
	}

	hasWarning := false
	for _, item := range components {
		if !item.OK && item.Status == "error" {
			return "degraded"
		}
		if item.Status == "warning" {
			hasWarning = true
		}
	}

	if hasWarning {
		return "degraded"
	}

	return "ok"
}

func aggregateHealthHTTPStatus(components []healthComponent) int {
	if aggregateHealthStatus(components) == "ok" {
		return http.StatusOK
	}

	return http.StatusServiceUnavailable
}

func registerPublicRoutes(
	mux *http.ServeMux,
	cfg gatewayConfig,
) {
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte("Pix2pi API Gateway OK"))
	})

	mux.HandleFunc("/health/live", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"status":         "ok",
			"service":        "api-gateway",
			"check":          "live",
			"request_id":     requestIDFromContext(r.Context()),
			"correlation_id": correlationIDFromContext(r.Context()),
		})
	})

	mux.HandleFunc("/health/ready", func(w http.ResponseWriter, r *http.Request) {
		writeDB := kernel.GetWriteDB()
		readDB := kernel.GetReadDB()

		writeOK := writeDB != nil
		readOK := readDB != nil

		statusCode := http.StatusOK
		status := "ok"

		if !writeOK || !readOK {
			statusCode = http.StatusServiceUnavailable
			status = "degraded"
		}

		writeJSON(w, statusCode, map[string]any{
			"status":            status,
			"service":           "api-gateway",
			"write_db_ok":       writeOK,
			"read_db_ok":        readOK,
			"replica_connected": writeOK && readOK && writeDB != readDB,
			"request_id":        requestIDFromContext(r.Context()),
			"correlation_id":    correlationIDFromContext(r.Context()),
		})
	})

	mux.HandleFunc("/health/db", func(w http.ResponseWriter, r *http.Request) {
		components := []healthComponent{
			buildDBHealthComponent("write_db", kernel.GetWriteDB()),
			buildDBHealthComponent("read_db", kernel.GetReadDB()),
		}

		status := aggregateHealthStatus(components)
		statusCode := aggregateHealthHTTPStatus(components)

		writeJSON(w, statusCode, map[string]any{
			"status":         status,
			"service":        "api-gateway",
			"scope":          "db",
			"components":     components,
			"request_id":     requestIDFromContext(r.Context()),
			"correlation_id": correlationIDFromContext(r.Context()),
		})
	})

	mux.HandleFunc("/health/replica", func(w http.ResponseWriter, r *http.Request) {
		component := buildReplicaHealthComponent()
		statusCode := http.StatusOK
		if !component.OK {
			if component.HTTPStatus != 0 {
				statusCode = component.HTTPStatus
			} else {
				statusCode = http.StatusServiceUnavailable
			}
		}

		writeJSON(w, statusCode, map[string]any{
			"status":         component.Status,
			"service":        "api-gateway",
			"scope":          "replica",
			"component":      component,
			"request_id":     requestIDFromContext(r.Context()),
			"correlation_id": correlationIDFromContext(r.Context()),
		})
	})

	mux.HandleFunc("/health/gateway-policy", func(w http.ResponseWriter, r *http.Request) {
		component := buildGatewayPolicyHealthComponent(cfg)

		writeJSON(w, http.StatusOK, map[string]any{
			"status":         component.Status,
			"service":        "api-gateway",
			"scope":          "gateway_policy",
			"component":      component,
			"request_id":     requestIDFromContext(r.Context()),
			"correlation_id": correlationIDFromContext(r.Context()),
		})
	})

	mux.HandleFunc("/health/upstreams", func(w http.ResponseWriter, r *http.Request) {
		_, timeout := routeTimeoutPolicyGetir(cfg, r.URL.Path)
		components := buildUpstreamHealthComponents(r.Context(), cfg)
		status := aggregateHealthStatus(components)
		statusCode := aggregateHealthHTTPStatus(components)

		writeJSON(w, statusCode, healthAggregateResponse{
			Status:        status,
			Service:       "api-gateway",
			Scope:         "upstreams",
			TimeoutMS:     timeout.Milliseconds(),
			Components:    components,
			RequestID:     requestIDFromContext(r.Context()),
			CorrelationID: correlationIDFromContext(r.Context()),
		})
	})

	mux.HandleFunc("/health/aggregate", func(w http.ResponseWriter, r *http.Request) {
		_, timeout := routeTimeoutPolicyGetir(cfg, r.URL.Path)

		components := []healthComponent{
			buildGatewayPolicyHealthComponent(cfg),
			buildDBHealthComponent("write_db", kernel.GetWriteDB()),
			buildDBHealthComponent("read_db", kernel.GetReadDB()),
			buildReplicaHealthComponent(),
		}

		components = append(
			components,
			buildUpstreamHealthComponents(r.Context(), cfg)...,
		)

		status := aggregateHealthStatus(components)
		statusCode := aggregateHealthHTTPStatus(components)

		writeJSON(w, statusCode, healthAggregateResponse{
			Status:        status,
			Service:       "api-gateway",
			Scope:         "aggregate",
			TimeoutMS:     timeout.Milliseconds(),
			Components:    components,
			RequestID:     requestIDFromContext(r.Context()),
			CorrelationID: correlationIDFromContext(r.Context()),
		})
	})

	mux.HandleFunc("/health/routes", func(w http.ResponseWriter, r *http.Request) {
		rules := gatewayRouteRules()

		writeJSON(w, http.StatusOK, routeCatalogResponse{
			Status:        "ok",
			Service:       "api-gateway",
			Scope:         "routes",
			TotalRoutes:   len(rules),
			Routes:        rules,
			RequestID:     requestIDFromContext(r.Context()),
			CorrelationID: correlationIDFromContext(r.Context()),
		})
	})
}

func registerProtectedRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/me", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"status":         "ok",
			"tenant_id":      tenantIDFromContext(r.Context()),
			"message":        "protected route ok",
			"request_id":     requestIDFromContext(r.Context()),
			"correlation_id": correlationIDFromContext(r.Context()),
		})
	})

	mux.HandleFunc("/api/query/users", func(w http.ResponseWriter, r *http.Request) {
		svc := query.New()

		count, err := svc.GetUsers()
		if err != nil {
			writeGatewayError(
				w,
				r.Context(),
				http.StatusInternalServerError,
				"query_user_count_failed",
				err.Error(),
				nil,
			)
			return
		}

		writeJSON(w, http.StatusOK, map[string]any{
			"status":         "ok",
			"tenant_id":      tenantIDFromContext(r.Context()),
			"user_count":     count,
			"request_id":     requestIDFromContext(r.Context()),
			"correlation_id": correlationIDFromContext(r.Context()),
		})
	})

	mux.HandleFunc("/api/query/users/list", func(w http.ResponseWriter, r *http.Request) {
		limit := 20
		rawLimit := strings.TrimSpace(r.URL.Query().Get("limit"))
		if rawLimit != "" {
			parsed, err := strconv.Atoi(rawLimit)
			if err != nil {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusBadRequest,
					"invalid_limit",
					"limit sayi olmali",
					nil,
				)
				return
			}
			limit = parsed
		}

		offset := 0
		rawOffset := strings.TrimSpace(r.URL.Query().Get("offset"))
		if rawOffset != "" {
			parsed, err := strconv.Atoi(rawOffset)
			if err != nil {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusBadRequest,
					"invalid_offset",
					"offset sayi olmali",
					nil,
				)
				return
			}
			offset = parsed
		}

		username := strings.TrimSpace(r.URL.Query().Get("username"))

		svc := query.New()

		result, err := svc.ListUsersAdvanced(limit, offset, username)
		if err != nil {
			writeGatewayError(
				w,
				r.Context(),
				http.StatusInternalServerError,
				"query_user_list_failed",
				err.Error(),
				nil,
			)
			return
		}

		writeJSON(w, http.StatusOK, map[string]any{
			"status":         "ok",
			"tenant_id":      tenantIDFromContext(r.Context()),
			"user_count":     result.Meta.TotalUsers,
			"meta":           result.Meta,
			"filters":        result.Filters,
			"users":          result.Users,
			"request_id":     requestIDFromContext(r.Context()),
			"correlation_id": correlationIDFromContext(r.Context()),
		})
	})

	mux.HandleFunc("/api/query/users/", func(w http.ResponseWriter, r *http.Request) {
		userID := strings.TrimSpace(strings.TrimPrefix(r.URL.Path, "/api/query/users/"))
		if userID == "" {
			writeGatewayError(
				w,
				r.Context(),
				http.StatusBadRequest,
				"empty_user_id",
				"user_id bos",
				nil,
			)
			return
		}

		svc := query.New()

		user, err := svc.GetUserByID(userID)
		if err != nil {
			writeGatewayError(
				w,
				r.Context(),
				http.StatusInternalServerError,
				"query_user_detail_failed",
				err.Error(),
				nil,
			)
			return
		}

		if user == nil {
			writeGatewayError(
				w,
				r.Context(),
				http.StatusNotFound,
				"user_not_found",
				"user bulunamadi",
				nil,
			)
			return
		}

		writeJSON(w, http.StatusOK, map[string]any{
			"status":         "ok",
			"tenant_id":      tenantIDFromContext(r.Context()),
			"user":           user,
			"request_id":     requestIDFromContext(r.Context()),
			"correlation_id": correlationIDFromContext(r.Context()),
		})
	})
}

func newGatewayHandler(
	cfg gatewayConfig,
	rateSvc rateLimiter,
	quotaSvc quotaLimiter,
) http.Handler {
	rootMux := http.NewServeMux()
	if err := reportingruntime.RegisterReportingRoutes(rootMux); err != nil {
		panic(err)
	}

	routeCatalog := newGatewayRouteCatalog()
	registerInternalRoutes(rootMux, routeCatalog, cfg)
	registerPublicRoutes(rootMux, cfg)

	protectedMux := http.NewServeMux()
	registerProtectedRoutes(protectedMux)
	erpRuntimeBundle, erpRuntimeErr := newERPRuntimeGatewayAPIServiceBundleFromEnv(context.Background())
	if erpRuntimeErr != nil {
		log.Printf("WARN ⚠️ ERP Runtime gateway service hazirlanamadi: %v", erpRuntimeErr)
		if err := registerERPRuntimeUnavailableProtectedRoute(protectedMux, erpRuntimeErr); err != nil {
			log.Printf("WARN ⚠️ ERP Runtime unavailable route kaydedilemedi: %v", err)
		}
	} else {
		if _, err := registerERPRuntimeProtectedRoutes(protectedMux, erpRuntimeBundle.service); err != nil {
			log.Printf("WARN ⚠️ ERP Runtime protected route mount basarisiz: %v", err)
			if fallbackErr := registerERPRuntimeUnavailableProtectedRoute(protectedMux, err); fallbackErr != nil {
				log.Printf("WARN ⚠️ ERP Runtime unavailable route kaydedilemedi: %v", fallbackErr)
			}
		} else {
			log.Printf("OK ✅ ERP Runtime protected route mounted: %s", erpRuntimeGatewayRouteRule().Path)
		}
	}

	protectedDispatch := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rule, ok := matchRouteRule(r.URL.Path)
		if !ok || rule.Scope != routeScopeProtected {
			writeGatewayError(
				w,
				r.Context(),
				http.StatusNotFound,
				"route_not_found",
				"route bulunamadi",
				nil,
			)
			return
		}

		if !methodAllowed(rule, r.Method) {
			writeGatewayError(
				w,
				r.Context(),
				http.StatusMethodNotAllowed,
				"method_not_allowed",
				"bu route icin method desteklenmiyor",
				map[string]any{
					"route_name":      rule.Name,
					"route_scope":     string(rule.Scope),
					"allowed_methods": rule.Methods,
				},
			)
			return
		}

		handler, pattern := protectedMux.Handler(r)
		if pattern == "" {
			writeGatewayError(
				w,
				r.Context(),
				http.StatusInternalServerError,
				"route_handler_missing",
				"route policy var ama handler yok",
				map[string]any{
					"route_name":  rule.Name,
					"route_scope": string(rule.Scope),
				},
			)
			return
		}

		handler.ServeHTTP(w, r)
	})

	protectedHandler := chain(
		protectedDispatch,
		jwtAuthMiddleware(cfg),
		tenantMiddleware(),
		rateLimitMiddleware(rateSvc, cfg),
		quotaMiddleware(quotaSvc, cfg),
	)

	rootMux.Handle("/api/", protectedHandler)

	rootDispatch := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rule, ok := matchRouteRule(r.URL.Path)
		if ok {
			if !methodAllowed(rule, r.Method) {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusMethodNotAllowed,
					"method_not_allowed",
					"bu route icin method desteklenmiyor",
					map[string]any{
						"route_name":      rule.Name,
						"route_scope":     string(rule.Scope),
						"allowed_methods": rule.Methods,
					},
				)
				return
			}

			applyRouteHeaders(w, rule)
		}

		handler, pattern := rootMux.Handler(r)
		if pattern == "" {
			writeGatewayError(
				w,
				r.Context(),
				http.StatusNotFound,
				"route_not_found",
				"route bulunamadi",
				nil,
			)
			return
		}

		handler.ServeHTTP(w, r)
	})

	return chain(
		rootDispatch,
		requestIdentityMiddleware(),
		recoverMiddleware,
		requestLogMiddleware,
		traceMiddleware(),
		timeoutPolicyMiddleware(cfg),
	)
}

func gatewayBindAddr() string {
	bindAddr := strings.TrimSpace(os.Getenv("GATEWAY_BIND_ADDR"))
	if bindAddr == "" {
		return "127.0.0.1"
	}
	return bindAddr
}

func gatewayListenAddrFromPort(port string) string {
	cleanPort := strings.TrimSpace(port)
	if cleanPort == "" {
		cleanPort = "9010"
	}
	return net.JoinHostPort(gatewayBindAddr(), cleanPort)
}

func main() {
	log.Println("STEP ▶ API Gateway boot basladi")

	kernel.InitDB()
	log.Println("OK ✅ kernel.InitDB tamam")

	cfg := loadGatewayConfig()

	rateSvc := gatewayservice.NewRateLimitService()
	defer func() {
		if err := rateSvc.Close(); err != nil {
			log.Println("WARN ⚠ gateway rate limit close:", err)
		}
	}()

	quotaSvc := gatewayservice.NewQuotaService()
	defer func() {
		if err := quotaSvc.Close(); err != nil {
			log.Println("WARN ⚠ gateway quota close:", err)
		}
	}()

	handler := newGatewayHandler(cfg, rateSvc, quotaSvc)
	port := gatewayPortGetir()

	log.Printf(
		"OK ✅ Pix2pi API Gateway running on %s | rate_limit=%d | daily_quota=%d | health_timeout_ms=%d | api_timeout_ms=%d | query_timeout_ms=%d\n",
		port,
		cfg.DefaultRateLimitPerMinute,
		cfg.DefaultDailyQuota,
		cfg.HealthTimeoutMS,
		cfg.APITimeoutMS,
		cfg.QueryTimeoutMS,
	)

	listenAddr := gatewayListenAddrFromPort(port)
	err := http.ListenAndServe(listenAddr, handler)
	if err != nil {
		log.Fatal(err)
	}
}
