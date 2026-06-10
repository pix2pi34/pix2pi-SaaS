package main

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type middleware func(http.Handler) http.Handler

type rateLimiter interface {
	TenantTanimla(tenantID string, limit int) error
	IstekGecir(tenantID string) error
}

type quotaLimiter interface {
	TenantTanimla(tenantID string, limit int) error
	IstekGecir(tenantID string) error
}

type gatewayContextKey string

const (
	gatewayRequestIDKey     gatewayContextKey = "gateway_request_id"
	gatewayCorrelationIDKey gatewayContextKey = "gateway_correlation_id"
	gatewayTenantIDKey      gatewayContextKey = "gateway_tenant_id"
	gatewayTokenTenantKey   gatewayContextKey = "gateway_token_tenant_id"
)

type statusRecorder struct {
	http.ResponseWriter
	statusCode int
}

func (s *statusRecorder) WriteHeader(code int) {
	s.statusCode = code
	s.ResponseWriter.WriteHeader(code)
}

func (s *statusRecorder) Write(data []byte) (int, error) {
	if s.statusCode == 0 {
		s.statusCode = http.StatusOK
	}
	return s.ResponseWriter.Write(data)
}

type bufferedResponseWriter struct {
	header     http.Header
	body       bytes.Buffer
	statusCode int
}

func newBufferedResponseWriter() *bufferedResponseWriter {
	return &bufferedResponseWriter{
		header: make(http.Header),
	}
}

func (b *bufferedResponseWriter) Header() http.Header {
	return b.header
}

func (b *bufferedResponseWriter) Write(data []byte) (int, error) {
	if b.statusCode == 0 {
		b.statusCode = http.StatusOK
	}
	return b.body.Write(data)
}

func (b *bufferedResponseWriter) WriteHeader(code int) {
	b.statusCode = code
}

func (b *bufferedResponseWriter) flushTo(w http.ResponseWriter) {
	for k, vals := range b.header {
		for _, v := range vals {
			w.Header().Add(k, v)
		}
	}

	if b.statusCode == 0 {
		b.statusCode = http.StatusOK
	}

	w.WriteHeader(b.statusCode)
	_, _ = w.Write(b.body.Bytes())
}

func chain(final http.Handler, mws ...middleware) http.Handler {
	h := final
	for i := len(mws) - 1; i >= 0; i-- {
		h = mws[i](h)
	}
	return h
}

func requestIDUret() string {
	buf := make([]byte, 16)
	if _, err := rand.Read(buf); err != nil {
		return fmt.Sprintf("req-%d", time.Now().UnixNano())
	}
	return hex.EncodeToString(buf)
}

func gatewayContextWithRequestIdentity(
	ctx context.Context,
	requestID string,
	correlationID string,
) context.Context {
	ctx = context.WithValue(ctx, gatewayRequestIDKey, requestID)
	ctx = context.WithValue(ctx, gatewayCorrelationIDKey, correlationID)
	return ctx
}

func requestIDFromContext(ctx context.Context) string {
	val, _ := ctx.Value(gatewayRequestIDKey).(string)
	return val
}

func correlationIDFromContext(ctx context.Context) string {
	val, _ := ctx.Value(gatewayCorrelationIDKey).(string)
	return val
}

func tenantIDFromContext(ctx context.Context) string {
	val, _ := ctx.Value(gatewayTenantIDKey).(string)
	return val
}

func tokenTenantIDFromContext(ctx context.Context) string {
	val, _ := ctx.Value(gatewayTokenTenantKey).(string)
	return val
}

func writeJSON(w http.ResponseWriter, statusCode int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	_ = json.NewEncoder(w).Encode(payload)
}

func writeGatewayError(
	w http.ResponseWriter,
	ctx context.Context,
	statusCode int,
	code string,
	message string,
	extra map[string]any,
) {
	payload := map[string]any{
		"status":         "error",
		"code":           code,
		"error":          message,
		"http_status":    statusCode,
		"source":         "api_gateway",
		"request_id":     requestIDFromContext(ctx),
		"correlation_id": correlationIDFromContext(ctx),
	}

	if tenantID := tenantIDFromContext(ctx); tenantID != "" {
		payload["tenant_id"] = tenantID
	}

	for k, v := range extra {
		payload[k] = v
	}

	writeJSON(w, statusCode, payload)
}

func requestIdentityMiddleware() middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			requestID := strings.TrimSpace(r.Header.Get("X-Request-ID"))
			if requestID == "" {
				requestID = requestIDUret()
			}

			correlationID := strings.TrimSpace(r.Header.Get("X-Correlation-ID"))
			if correlationID == "" {
				correlationID = requestID
			}

			w.Header().Set("X-Request-ID", requestID)
			w.Header().Set("X-Correlation-ID", correlationID)

			ctx := gatewayContextWithRequestIdentity(r.Context(), requestID, correlationID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func recoverMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if rec := recover(); rec != nil {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusInternalServerError,
					"panic_recovered",
					fmt.Sprint(rec),
					map[string]any{
						"middleware": "recover",
					},
				)
			}
		}()

		next.ServeHTTP(w, r)
	})
}

func requestLogMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf(
			"INFO gateway request | method=%s | path=%s | remote=%s | request_id=%s | correlation_id=%s\n",
			r.Method,
			r.URL.Path,
			r.RemoteAddr,
			requestIDFromContext(r.Context()),
			correlationIDFromContext(r.Context()),
		)

		next.ServeHTTP(w, r)
	})
}

func traceMiddleware() middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			rec := &statusRecorder{ResponseWriter: w}

			next.ServeHTTP(rec, r)

			statusCode := rec.statusCode
			if statusCode == 0 {
				statusCode = http.StatusOK
			}

			log.Printf(
				"TRACE gateway | method=%s | path=%s | status=%d | duration_ms=%d | request_id=%s | correlation_id=%s\n",
				r.Method,
				r.URL.Path,
				statusCode,
				time.Since(start).Milliseconds(),
				requestIDFromContext(r.Context()),
				correlationIDFromContext(r.Context()),
			)
		})
	}
}

func routeTimeoutPolicyGetir(
	cfg gatewayConfig,
	path string,
) (string, time.Duration) {
	switch {
	case strings.HasPrefix(path, "/health"):
		return "health", time.Duration(cfg.HealthTimeoutMS) * time.Millisecond
	case strings.HasPrefix(path, "/api/query"):
		return "query", time.Duration(cfg.QueryTimeoutMS) * time.Millisecond
	default:
		return "api", time.Duration(cfg.APITimeoutMS) * time.Millisecond
	}
}

func timeoutPolicyMiddleware(cfg gatewayConfig) middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			policy, timeout := routeTimeoutPolicyGetir(cfg, r.URL.Path)
			if timeout <= 0 {
				next.ServeHTTP(w, r)
				return
			}

			ctx, cancel := context.WithTimeout(r.Context(), timeout)
			defer cancel()

			done := make(chan struct{})
			buffered := newBufferedResponseWriter()

			go func() {
				defer close(done)
				next.ServeHTTP(buffered, r.WithContext(ctx))
			}()

			select {
			case <-done:
				buffered.flushTo(w)
				return

			case <-ctx.Done():
				log.Printf(
					"WARN ⚠ gateway timeout | method=%s | path=%s | policy=%s | timeout_ms=%d | request_id=%s | correlation_id=%s\n",
					r.Method,
					r.URL.Path,
					policy,
					timeout.Milliseconds(),
					requestIDFromContext(r.Context()),
					correlationIDFromContext(r.Context()),
				)

				writeGatewayError(
					w,
					r.Context(),
					http.StatusGatewayTimeout,
					"gateway_timeout",
					"gateway timeout",
					map[string]any{
						"middleware":     "timeout",
						"timeout_policy": policy,
						"timeout_ms":     timeout.Milliseconds(),
					},
				)
				return
			}
		})
	}
}

func jwtAuthMiddleware(cfg gatewayConfig) middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
			if authHeader == "" {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusUnauthorized,
					"missing_authorization_header",
					"authorization header zorunlu",
					map[string]any{
						"middleware": "jwt",
					},
				)
				return
			}

			if !strings.HasPrefix(authHeader, "Bearer ") {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusUnauthorized,
					"invalid_bearer_prefix",
					"bearer token formati gecersiz",
					map[string]any{
						"middleware": "jwt",
					},
				)
				return
			}

			tokenStr := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
			if tokenStr == "" {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusUnauthorized,
					"empty_bearer_token",
					"bearer token bos",
					map[string]any{
						"middleware": "jwt",
					},
				)
				return
			}

			token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (any, error) {
				return []byte(cfg.JWTSecret), nil
			})
			if err != nil || !token.Valid {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusUnauthorized,
					"invalid_token",
					"jwt gecersiz",
					map[string]any{
						"middleware": "jwt",
					},
				)
				return
			}

			claims, ok := token.Claims.(jwt.MapClaims)
			if !ok {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusUnauthorized,
					"invalid_claims",
					"jwt claims okunamadi",
					map[string]any{
						"middleware": "jwt",
					},
				)
				return
			}

			tenantVal, _ := claims["tenant_id"]
			tokenTenantID := strings.TrimSpace(fmt.Sprint(tenantVal))
			if tokenTenantID == "" || tokenTenantID == "<nil>" {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusUnauthorized,
					"missing_tenant_claim",
					"tenant_id claim zorunlu",
					map[string]any{
						"middleware": "jwt",
					},
				)
				return
			}

			ctx := context.WithValue(r.Context(), gatewayTokenTenantKey, tokenTenantID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func tenantMiddleware() middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			tokenTenantID := tokenTenantIDFromContext(r.Context())
			headerTenantID := strings.TrimSpace(r.Header.Get("X-Tenant-ID"))

			if headerTenantID != "" && tokenTenantID != "" && headerTenantID != tokenTenantID {
				ctx := context.WithValue(r.Context(), gatewayTenantIDKey, tokenTenantID)

				writeGatewayError(
					w,
					ctx,
					http.StatusForbidden,
					"tenant_header_mismatch",
					"tenant header jwt ile uyusmuyor",
					map[string]any{
						"middleware": "tenant",
					},
				)
				return
			}

			finalTenantID := tokenTenantID
			if headerTenantID != "" {
				finalTenantID = headerTenantID
			}

			if finalTenantID == "" {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusForbidden,
					"missing_tenant_context",
					"tenant context bos",
					map[string]any{
						"middleware": "tenant",
					},
				)
				return
			}

			ctx := context.WithValue(r.Context(), gatewayTenantIDKey, finalTenantID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func rateLimitMiddleware(rateSvc rateLimiter, cfg gatewayConfig) middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			tenantID := tenantIDFromContext(r.Context())
			if tenantID == "" {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusForbidden,
					"missing_tenant_context",
					"tenant context bos",
					map[string]any{
						"middleware": "rate_limit",
					},
				)
				return
			}

			if err := rateSvc.TenantTanimla(tenantID, cfg.DefaultRateLimitPerMinute); err != nil {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusTooManyRequests,
					"rate_limit_define_failed",
					err.Error(),
					map[string]any{
						"middleware": "rate_limit",
						"limit":      cfg.DefaultRateLimitPerMinute,
					},
				)
				return
			}

			if err := rateSvc.IstekGecir(tenantID); err != nil {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusTooManyRequests,
					"rate_limit_exceeded",
					err.Error(),
					map[string]any{
						"middleware": "rate_limit",
						"limit":      cfg.DefaultRateLimitPerMinute,
					},
				)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

func quotaMiddleware(quotaSvc quotaLimiter, cfg gatewayConfig) middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			tenantID := tenantIDFromContext(r.Context())
			if tenantID == "" {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusForbidden,
					"missing_tenant_context",
					"tenant context bos",
					map[string]any{
						"middleware": "quota",
					},
				)
				return
			}

			if err := quotaSvc.TenantTanimla(tenantID, cfg.DefaultDailyQuota); err != nil {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusTooManyRequests,
					"quota_define_failed",
					err.Error(),
					map[string]any{
						"middleware": "quota",
						"quota":      cfg.DefaultDailyQuota,
					},
				)
				return
			}

			if err := quotaSvc.IstekGecir(tenantID); err != nil {
				writeGatewayError(
					w,
					r.Context(),
					http.StatusTooManyRequests,
					"quota_exceeded",
					err.Error(),
					map[string]any{
						"middleware": "quota",
						"quota":      cfg.DefaultDailyQuota,
					},
				)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
