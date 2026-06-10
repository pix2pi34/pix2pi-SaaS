package service

import (
	"testing"
	"time"

	authdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/auth/domain"
	"github.com/golang-jwt/jwt/v5"
)

func TestJWTService_TokenUretVeTokenCoz_Success(t *testing.T) {
	svc := NewJWTService("super-secret")

	token, err := svc.TokenUret(
		"user_1",
		"user@example.com",
		"tenant_42",
		"uuid-42",
	)
	if err != nil {
		t.Fatalf("unexpected token uret error: %v", err)
	}

	claims, err := svc.TokenCoz(token)
	if err != nil {
		t.Fatalf("unexpected token coz error: %v", err)
	}

	if claims.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", claims.TenantID)
	}
	if claims.TenantUUID != "uuid-42" {
		t.Fatalf("expected uuid-42, got %s", claims.TenantUUID)
	}
	if claims.Subject != "user_1" {
		t.Fatalf("expected subject user_1, got %s", claims.Subject)
	}
	if claims.Issuer != DefaultJWTIssuer {
		t.Fatalf("expected issuer %s, got %s", DefaultJWTIssuer, claims.Issuer)
	}
	if len(claims.Audience) != 1 || claims.Audience[0] != DefaultJWTAudience {
		t.Fatalf("expected audience %s, got %v", DefaultJWTAudience, claims.Audience)
	}
}

func TestJWTService_TokenCoz_InvalidAudience(t *testing.T) {
	svc := NewJWTService("super-secret")
	now := time.Now()

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, authdomain.TenantClaims{
		UserID:     "user_1",
		Email:      "user@example.com",
		TenantID:   "tenant_42",
		TenantUUID: "uuid-42",
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   "user_1",
			Issuer:    DefaultJWTIssuer,
			Audience:  jwt.ClaimStrings{"wrong-audience"},
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(30 * time.Minute)),
		},
	})

	tokenStr, err := token.SignedString([]byte("super-secret"))
	if err != nil {
		t.Fatalf("unexpected sign error: %v", err)
	}

	_, err = svc.TokenCoz(tokenStr)
	if err == nil {
		t.Fatal("expected invalid audience error")
	}
	if err != authdomain.ErrJWTInvalidAudience {
		t.Fatalf("expected ErrJWTInvalidAudience, got %v", err)
	}
}

func TestJWTService_TokenCoz_Expired(t *testing.T) {
	svc := NewJWTService("super-secret")
	now := time.Now()

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, authdomain.TenantClaims{
		UserID:     "user_1",
		Email:      "user@example.com",
		TenantID:   "tenant_42",
		TenantUUID: "uuid-42",
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   "user_1",
			Issuer:    DefaultJWTIssuer,
			Audience:  jwt.ClaimStrings{DefaultJWTAudience},
			IssuedAt:  jwt.NewNumericDate(now.Add(-2 * time.Hour)),
			NotBefore: jwt.NewNumericDate(now.Add(-2 * time.Hour)),
			ExpiresAt: jwt.NewNumericDate(now.Add(-1 * time.Hour)),
		},
	})

	tokenStr, err := token.SignedString([]byte("super-secret"))
	if err != nil {
		t.Fatalf("unexpected sign error: %v", err)
	}

	_, err = svc.TokenCoz(tokenStr)
	if err == nil {
		t.Fatal("expected expired error")
	}
	if err != authdomain.ErrJWTExpired {
		t.Fatalf("expected ErrJWTExpired, got %v", err)
	}
}
