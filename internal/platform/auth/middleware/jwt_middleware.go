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

type TenantIdentity struct {
	TenantID   string
	TenantUUID string
	UserID     string
	Email      string
}

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
	if m == nil || m.jwtService == nil {
		return nil, errors.New("jwt service zorunlu")
	}

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

	identity := TenantIdentity{
		TenantID:   claims.TenantID,
		TenantUUID: claims.TenantUUID,
		UserID:     claims.UserID,
		Email:      claims.Email,
	}

	ctx := context.WithValue(r.Context(), ContextTenantIDKey, identity.TenantID)
	ctx = context.WithValue(ctx, ContextTenantUUIDKey, identity.TenantUUID)
	ctx = context.WithValue(ctx, ContextUserIDKey, identity.UserID)
	ctx = context.WithValue(ctx, ContextEmailKey, identity.Email)

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

func ContextTenantIdentityAl(
	r *http.Request,
) (TenantIdentity, error) {
	tenantID, err := ContextTenantIDAl(r)
	if err != nil {
		return TenantIdentity{}, err
	}

	tenantUUID, err := ContextTenantUUIDAl(r)
	if err != nil {
		return TenantIdentity{}, err
	}

	userID, _ := r.Context().Value(ContextUserIDKey).(string)
	email, _ := r.Context().Value(ContextEmailKey).(string)

	return TenantIdentity{
		TenantID:   tenantID,
		TenantUUID: tenantUUID,
		UserID:     userID,
		Email:      email,
	}, nil
}
