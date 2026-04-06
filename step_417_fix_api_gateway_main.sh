#!/bin/bash
set -euo pipefail

echo "=== STEP 417C / FIX API GATEWAY MAIN ==="

cat <<'INNER' > "$HOME/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go"
package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strconv"
	"strings"
	"time"

	query "github.com/divrigili/pix2pi-SaaS/internal/services/query_read_model"
	"github.com/redis/go-redis/v9"
)

type contextKey string

const tenantKey contextKey = "tenant_id"
const roleKey contextKey = "role"

type RedisRateLimiter struct {
	client   *redis.Client
	limit    int64
	interval time.Duration
	ctx      context.Context
}

type TokenInfo struct {
	TenantID string
	Role     string
}

func NewRedisRateLimiter(addr string, limit int64, interval time.Duration) *RedisRateLimiter {
	rdb := redis.NewClient(&redis.Options{
		Addr: addr,
	})

	return &RedisRateLimiter{
		client:   rdb,
		limit:    limit,
		interval: interval,
		ctx:      context.Background(),
	}
}

func (rl *RedisRateLimiter) Allow(tenantID string, scope string) (bool, int64, error) {
	key := "tenant:" + tenantID + ":gateway:" + scope + ":rate_limit"

	count, err := rl.client.Incr(rl.ctx, key).Result()
	if err != nil {
		return false, 0, err
	}

	if count == 1 {
		err = rl.client.Expire(rl.ctx, key, rl.interval).Err()
		if err != nil {
			return false, count, err
		}
	}

	if count > rl.limit {
		return false, count, nil
	}

	return true, count, nil
}

func tokenRegistry() map[string]TokenInfo {
	return map[string]TokenInfo{
		"pix2pi-token-tenant-001": {
			TenantID: "tenant-001",
			Role:     "tenant-user",
		},
		"pix2pi-token-tenant-002": {
			TenantID: "tenant-002",
			Role:     "tenant-user",
		},
		"pix2pi-admin-token": {
			TenantID: "",
			Role:     "super-admin",
		},
	}
}

func proxyWithPrefixTrim(target string, trimPrefix string) http.Handler {
	u, err := url.Parse(target)
	if err != nil {
		log.Fatalf("target parse hatasi: %v", err)
	}

	p := httputil.NewSingleHostReverseProxy(u)
	originalDirector := p.Director

	p.Director = func(r *http.Request) {
		originalDirector(r)

		r.Host = u.Host

		newPath := strings.TrimPrefix(r.URL.Path, trimPrefix)
		if newPath == "" {
			newPath = "/"
		}
		if !strings.HasPrefix(newPath, "/") {
			newPath = "/" + newPath
		}

		r.URL.Path = newPath
		r.URL.RawPath = newPath

		tenantID, _ := r.Context().Value(tenantKey).(string)
		role, _ := r.Context().Value(roleKey).(string)

		if tenantID != "" {
			r.Header.Set("X-Tenant-ID", tenantID)
		}
		if role != "" {
			r.Header.Set("X-Role", role)
		}
	}

	return p
}

func withBearerAuth(next http.Handler) http.Handler {
	registry := tokenRegistry()

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
		if authHeader == "" {
			w.WriteHeader(http.StatusUnauthorized)
			_, _ = w.Write([]byte("authorization bearer zorunlu"))
			return
		}

		if !strings.HasPrefix(authHeader, "Bearer ") {
			w.WriteHeader(http.StatusUnauthorized)
			_, _ = w.Write([]byte("authorization bearer zorunlu"))
			return
		}

		token := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
		tokenInfo, ok := registry[token]
		if !ok {
			w.WriteHeader(http.StatusUnauthorized)
			_, _ = w.Write([]byte("gecersiz bearer token"))
			return
		}

		ctx := context.WithValue(r.Context(), tenantKey, tokenInfo.TenantID)
		ctx = context.WithValue(ctx, roleKey, tokenInfo.Role)

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func withTenantMatch(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestTenant := strings.TrimSpace(r.Header.Get("X-Tenant-ID"))
		tokenTenant, _ := r.Context().Value(tenantKey).(string)
		role, _ := r.Context().Value(roleKey).(string)

		if role == "super-admin" {
			if requestTenant == "" {
				w.WriteHeader(http.StatusBadRequest)
				_, _ = w.Write([]byte("super admin icin tenant id zorunlu"))
				return
			}
			ctx := context.WithValue(r.Context(), tenantKey, requestTenant)
			next.ServeHTTP(w, r.WithContext(ctx))
			return
		}

		if requestTenant == "" {
			w.WriteHeader(http.StatusBadRequest)
			_, _ = w.Write([]byte("tenant id zorunlu"))
			return
		}

		if tokenTenant == "" {
			w.WriteHeader(http.StatusUnauthorized)
			_, _ = w.Write([]byte("token tenant bos"))
			return
		}

		if requestTenant != tokenTenant {
			w.WriteHeader(http.StatusForbidden)
			_, _ = w.Write([]byte("token tenant ve request tenant uyusmuyor"))
			return
		}

		next.ServeHTTP(w, r)
	})
}

func withTenantRedisRateLimit(rl *RedisRateLimiter, scope string, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		tenantID, _ := r.Context().Value(tenantKey).(string)
		if tenantID == "" {
			w.WriteHeader(http.StatusBadRequest)
			_, _ = w.Write([]byte("tenant id zorunlu"))
			return
		}

		allowed, count, err := rl.Allow(tenantID, scope)
		if err != nil {
			log.Printf("redis rate limit hatasi tenant=%s scope=%s err=%v", tenantID, scope, err)
			w.WriteHeader(http.StatusInternalServerError)
			_, _ = w.Write([]byte("redis rate limit hatasi"))
			return
		}

		w.Header().Set("X-RateLimit-Count", strconv.FormatInt(count, 10))

		if !allowed {
			w.WriteHeader(http.StatusTooManyRequests)
			_, _ = w.Write([]byte("tenant redis rate limit asildi"))
			return
		}

		next.ServeHTTP(w, r)
	})
}

func chain(h http.Handler, middlewares ...func(http.Handler) http.Handler) http.Handler {
	for i := len(middlewares) - 1; i >= 0; i-- {
		h = middlewares[i](h)
	}
	return h
}

func main() {
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte("Pix2pi API Gateway OK"))
	})

	redisLimiter := NewRedisRateLimiter("127.0.0.1:6379", 5, time.Minute)

	identityHandler := proxyWithPrefixTrim("http://127.0.0.1:9001", "/api/identity")
	authHandler := proxyWithPrefixTrim("http://127.0.0.1:9002", "/api/auth")

	http.Handle(
		"/api/identity/",
		chain(
			identityHandler,
			func(next http.Handler) http.Handler { return withBearerAuth(next) },
			func(next http.Handler) http.Handler { return withTenantMatch(next) },
			func(next http.Handler) http.Handler { return withTenantRedisRateLimit(redisLimiter, "identity", next) },
		),
	)

	http.Handle(
		"/api/auth/",
		chain(
			authHandler,
			func(next http.Handler) http.Handler { return withBearerAuth(next) },
			func(next http.Handler) http.Handler { return withTenantMatch(next) },
			func(next http.Handler) http.Handler { return withTenantRedisRateLimit(redisLimiter, "auth", next) },
		),
	)

	http.HandleFunc("/api/query/users", func(w http.ResponseWriter, r *http.Request) {
		svc := query.New()

		count, err := svc.GetUsers()
		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			_ = json.NewEncoder(w).Encode(map[string]interface{}{
				"status":  "error",
				"message": "query read model hatasi",
				"error":   err.Error(),
			})
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"status":     "ok",
			"message":    "read model calisti",
			"user_count": count,
		})
	})

	log.Println("Pix2pi API Gateway starting on port 9010")

	if err := http.ListenAndServe(":9010", nil); err != nil {
		log.Fatal(err)
	}
}
INNER

gofmt -w "$HOME/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go"

echo "OK ✅ api gateway main yeniden yazildi"
echo "=== STEP 417C TAMAM ✅ ==="
