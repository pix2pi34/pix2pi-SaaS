package middleware

import (
	"context"
	"errors"
	"net/http"
	"strings"

	authservice "github.com/divrigili/pix2pi-SaaS/internal/platform/auth/service"
)

type contextKey string

const (
	ContextTenantIDKey   contextKey = "tenant_id"
	ContextTenantUUIDKey contextKey = "tenant_uuid"
	ContextUserIDKey     contextKey = "user_id"
	ContextEmailKey      contextKey = "email"
)

type JWTMiddleware struct {
	jwtService *authservice.JWTService
}

func NewJWTMiddleware(
	jwtService *authservice.JWTService,
) *JWTMiddleware {
	return &JWTMiddleware{
		jwtService: jwtService,
	}
}

func (m *JWTMiddleware) TokenDogrulaVeContexteYaz(
	r *http.Request,
) (*http.Request, error) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		return nil, errors.New("authorization header zorunlu")
	}

	if !strings.HasPrefix(authHeader, "Bearer ") {
		return nil, errors.New("authorization bearer formatinda olmali")
	}

	tokenStr := strings.TrimPrefix(authHeader, "Bearer ")
	tokenStr = strings.TrimSpace(tokenStr)
	if tokenStr == "" {
		return nil, errors.New("token bos olamaz")
	}

	claims, err := m.jwtService.TokenCoz(tokenStr)
	if err != nil {
		return nil, err
	}

	ctx := context.WithValue(r.Context(), ContextTenantIDKey, claims.TenantID)
	ctx = context.WithValue(ctx, ContextTenantUUIDKey, claims.TenantUUID)
	ctx = context.WithValue(ctx, ContextUserIDKey, claims.UserID)
	ctx = context.WithValue(ctx, ContextEmailKey, claims.Email)

	return r.WithContext(ctx), nil
}

func ContextTenantIDAl(
	r *http.Request,
) (string, error) {
	v := r.Context().Value(ContextTenantIDKey)
	tenantID, ok := v.(string)
	if !ok || tenantID == "" {
		return "", errors.New("request context icinde tenant id yok")
	}
	return tenantID, nil
}

func ContextTenantUUIDAl(
	r *http.Request,
) (string, error) {
	v := r.Context().Value(ContextTenantUUIDKey)
	tenantUUID, ok := v.(string)
	if !ok || tenantUUID == "" {
		return "", errors.New("request context icinde tenant uuid yok")
	}
	return tenantUUID, nil
}
