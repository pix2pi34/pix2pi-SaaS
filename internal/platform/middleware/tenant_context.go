package middleware

import (
	"context"
	"net/http"
)

type TenantKey string

const TenantID TenantKey = "tenant_id"

func TenantContext(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

		tenant := r.Header.Get("X-Tenant-ID")

		ctx := context.WithValue(r.Context(), TenantID, tenant)

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}
