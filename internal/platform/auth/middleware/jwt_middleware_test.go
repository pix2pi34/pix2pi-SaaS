package middleware

import (
	"net/http"
	"testing"
	"time"

	authdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/auth/domain"
	authservice "github.com/divrigili/pix2pi-SaaS/internal/platform/auth/service"
	"github.com/golang-jwt/jwt/v5"
)

func testRequestWithToken(t *testing.T, svc *authservice.JWTService) *http.Request {
	t.Helper()

	token, err := svc.TokenUret(
		"user_1",
		"user@example.com",
		"tenant_42",
		"uuid-42",
	)
	if err != nil {
		t.Fatalf("unexpected token create error: %v", err)
	}

	req, err := http.NewRequest(http.MethodGet, "http://localhost/test", nil)
	if err != nil {
		t.Fatalf("unexpected request error: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)
	return req
}

func testRequestWithRawToken(t *testing.T, token string) *http.Request {
	t.Helper()

	req, err := http.NewRequest(http.MethodGet, "http://localhost/test", nil)
	if err != nil {
		t.Fatalf("unexpected request error: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)
	return req
}

func signCustomToken(
	t *testing.T,
	secret string,
	claims authdomain.TenantClaims,
) string {
	t.Helper()

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	tokenStr, err := token.SignedString([]byte(secret))
	if err != nil {
		t.Fatalf("unexpected sign error: %v", err)
	}

	return tokenStr
}

func TestJWTMiddleware_TokenDogrulaVeContexteYaz(t *testing.T) {
	svc := authservice.NewJWTService("super-secret")
	mw := NewJWTMiddleware(svc)

	req := testRequestWithToken(t, svc)

	enriched, err := mw.TokenDogrulaVeContexteYaz(req)
	if err != nil {
		t.Fatalf("unexpected middleware error: %v", err)
	}

	identity, err := ContextTenantIdentityAl(enriched)
	if err != nil {
		t.Fatalf("unexpected identity error: %v", err)
	}

	if identity.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", identity.TenantID)
	}
	if identity.TenantUUID != "uuid-42" {
		t.Fatalf("expected uuid-42, got %s", identity.TenantUUID)
	}
	if identity.UserID != "user_1" {
		t.Fatalf("expected user_1, got %s", identity.UserID)
	}
	if identity.Email != "user@example.com" {
		t.Fatalf("expected user@example.com, got %s", identity.Email)
	}
}

func TestJWTMiddleware_TokenDogrulaVeContexteYaz_MissingHeader(t *testing.T) {
	svc := authservice.NewJWTService("super-secret")
	mw := NewJWTMiddleware(svc)

	req, err := http.NewRequest(http.MethodGet, "http://localhost/test", nil)
	if err != nil {
		t.Fatalf("unexpected request error: %v", err)
	}

	_, err = mw.TokenDogrulaVeContexteYaz(req)
	if err == nil {
		t.Fatal("expected missing header error")
	}
}

func TestJWTMiddleware_TokenDogrulaVeContexteYaz_InvalidBearerFormat(t *testing.T) {
	svc := authservice.NewJWTService("super-secret")
	mw := NewJWTMiddleware(svc)

	req, err := http.NewRequest(http.MethodGet, "http://localhost/test", nil)
	if err != nil {
		t.Fatalf("unexpected request error: %v", err)
	}
	req.Header.Set("Authorization", "Token abc")

	_, err = mw.TokenDogrulaVeContexteYaz(req)
	if err == nil {
		t.Fatal("expected invalid bearer format error")
	}
}

func TestJWTMiddleware_TokenDogrulaVeContexteYaz_ExpiredToken(t *testing.T) {
	svc := authservice.NewJWTService("super-secret")
	mw := NewJWTMiddleware(svc)
	now := time.Now()

	tokenStr := signCustomToken(t, "super-secret", authdomain.TenantClaims{
		UserID:     "user_1",
		Email:      "user@example.com",
		TenantID:   "tenant_42",
		TenantUUID: "uuid-42",
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   "user_1",
			Issuer:    authservice.DefaultJWTIssuer,
			Audience:  jwt.ClaimStrings{authservice.DefaultJWTAudience},
			IssuedAt:  jwt.NewNumericDate(now.Add(-2 * time.Hour)),
			NotBefore: jwt.NewNumericDate(now.Add(-2 * time.Hour)),
			ExpiresAt: jwt.NewNumericDate(now.Add(-1 * time.Hour)),
		},
	})

	req := testRequestWithRawToken(t, tokenStr)

	_, err := mw.TokenDogrulaVeContexteYaz(req)
	if err == nil {
		t.Fatal("expected expired token error")
	}
	if err != authdomain.ErrJWTExpired {
		t.Fatalf("expected ErrJWTExpired, got %v", err)
	}
}

func TestJWTMiddleware_TokenDogrulaVeContexteYaz_InvalidIssuer(t *testing.T) {
	svc := authservice.NewJWTService("super-secret")
	mw := NewJWTMiddleware(svc)
	now := time.Now()

	tokenStr := signCustomToken(t, "super-secret", authdomain.TenantClaims{
		UserID:     "user_1",
		Email:      "user@example.com",
		TenantID:   "tenant_42",
		TenantUUID: "uuid-42",
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   "user_1",
			Issuer:    "wrong-issuer",
			Audience:  jwt.ClaimStrings{authservice.DefaultJWTAudience},
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(30 * time.Minute)),
		},
	})

	req := testRequestWithRawToken(t, tokenStr)

	_, err := mw.TokenDogrulaVeContexteYaz(req)
	if err == nil {
		t.Fatal("expected invalid issuer error")
	}
	if err != authdomain.ErrJWTInvalidIssuer {
		t.Fatalf("expected ErrJWTInvalidIssuer, got %v", err)
	}
}

func TestJWTMiddleware_TokenDogrulaVeContexteYaz_InvalidAudience(t *testing.T) {
	svc := authservice.NewJWTService("super-secret")
	mw := NewJWTMiddleware(svc)
	now := time.Now()

	tokenStr := signCustomToken(t, "super-secret", authdomain.TenantClaims{
		UserID:     "user_1",
		Email:      "user@example.com",
		TenantID:   "tenant_42",
		TenantUUID: "uuid-42",
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   "user_1",
			Issuer:    authservice.DefaultJWTIssuer,
			Audience:  jwt.ClaimStrings{"wrong-audience"},
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(30 * time.Minute)),
		},
	})

	req := testRequestWithRawToken(t, tokenStr)

	_, err := mw.TokenDogrulaVeContexteYaz(req)
	if err == nil {
		t.Fatal("expected invalid audience error")
	}
	if err != authdomain.ErrJWTInvalidAudience {
		t.Fatalf("expected ErrJWTInvalidAudience, got %v", err)
	}
}

func TestJWTMiddleware_TokenDogrulaVeContexteYaz_MissingTenantUUID(t *testing.T) {
	svc := authservice.NewJWTService("super-secret")
	mw := NewJWTMiddleware(svc)
	now := time.Now()

	tokenStr := signCustomToken(t, "super-secret", authdomain.TenantClaims{
		UserID:     "user_1",
		Email:      "user@example.com",
		TenantID:   "tenant_42",
		TenantUUID: "",
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   "user_1",
			Issuer:    authservice.DefaultJWTIssuer,
			Audience:  jwt.ClaimStrings{authservice.DefaultJWTAudience},
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(30 * time.Minute)),
		},
	})

	req := testRequestWithRawToken(t, tokenStr)

	_, err := mw.TokenDogrulaVeContexteYaz(req)
	if err == nil {
		t.Fatal("expected tenant uuid required error")
	}
	if err != authdomain.ErrJWTTenantUUIDRequired {
		t.Fatalf("expected ErrJWTTenantUUIDRequired, got %v", err)
	}
}

func TestJWTMiddleware_TokenDogrulaVeContexteYaz_NilJWTService(t *testing.T) {
	mw := NewJWTMiddleware(nil)

	req, err := http.NewRequest(http.MethodGet, "http://localhost/test", nil)
	if err != nil {
		t.Fatalf("unexpected request error: %v", err)
	}
	req.Header.Set("Authorization", "Bearer dummy")

	_, err = mw.TokenDogrulaVeContexteYaz(req)
	if err == nil {
		t.Fatal("expected nil jwt service error")
	}
}

func TestContextTenantIdentityAl_MissingContext(t *testing.T) {
	req, err := http.NewRequest(http.MethodGet, "http://localhost/test", nil)
	if err != nil {
		t.Fatalf("unexpected request error: %v", err)
	}

	_, err = ContextTenantIdentityAl(req)
	if err == nil {
		t.Fatal("expected missing context error")
	}
}
