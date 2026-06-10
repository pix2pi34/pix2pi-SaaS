package domain

import (
	"testing"
	"time"
)

func newValidJWTClaimContract(now time.Time) JWTClaimContract {
	return JWTClaimContract{
		Subject:       "user_1",
		Issuer:        "pix2pi-auth",
		Audience:      "pix2pi-api",
		TenantID:      "tenant_42",
		TenantUUID:    "uuid-42",
		IssuedAtUnix:  now.Add(-5 * time.Minute).Unix(),
		NotBeforeUnix: now.Add(-1 * time.Minute).Unix(),
		ExpiresAtUnix: now.Add(30 * time.Minute).Unix(),
	}
}

func newValidJWTValidationPolicy() JWTValidationPolicy {
	return JWTValidationPolicy{
		RequiredIssuer:   "pix2pi-auth",
		RequiredAudience: "pix2pi-api",
		ClockSkew:        30 * time.Second,
	}
}

func TestJWTValidationPolicy_Validate_Success(t *testing.T) {
	policy := newValidJWTValidationPolicy()

	if err := policy.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestJWTValidationPolicy_Validate_NegativeClockSkew(t *testing.T) {
	policy := JWTValidationPolicy{
		RequiredIssuer:   "pix2pi-auth",
		RequiredAudience: "pix2pi-api",
		ClockSkew:        -1 * time.Second,
	}

	err := policy.Validate()
	if err == nil {
		t.Fatal("expected negative clock skew error")
	}
	if err != ErrJWTNegativeClockSkew {
		t.Fatalf("expected ErrJWTNegativeClockSkew, got %v", err)
	}
}

func TestJWTClaimContract_Validate_Success(t *testing.T) {
	now := time.Now()
	claims := newValidJWTClaimContract(now)
	policy := newValidJWTValidationPolicy()

	if err := claims.Validate(policy, now); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestJWTClaimContract_Validate_MissingTenantUUID(t *testing.T) {
	now := time.Now()
	claims := newValidJWTClaimContract(now)
	claims.TenantUUID = ""

	err := claims.Validate(newValidJWTValidationPolicy(), now)
	if err == nil {
		t.Fatal("expected tenant uuid error")
	}
	if err != ErrJWTTenantUUIDRequired {
		t.Fatalf("expected ErrJWTTenantUUIDRequired, got %v", err)
	}
}

func TestJWTClaimContract_Validate_InvalidIssuer(t *testing.T) {
	now := time.Now()
	claims := newValidJWTClaimContract(now)
	claims.Issuer = "other-issuer"

	err := claims.Validate(newValidJWTValidationPolicy(), now)
	if err == nil {
		t.Fatal("expected invalid issuer error")
	}
	if err != ErrJWTInvalidIssuer {
		t.Fatalf("expected ErrJWTInvalidIssuer, got %v", err)
	}
}

func TestJWTClaimContract_Validate_InvalidAudience(t *testing.T) {
	now := time.Now()
	claims := newValidJWTClaimContract(now)
	claims.Audience = "other-audience"

	err := claims.Validate(newValidJWTValidationPolicy(), now)
	if err == nil {
		t.Fatal("expected invalid audience error")
	}
	if err != ErrJWTInvalidAudience {
		t.Fatalf("expected ErrJWTInvalidAudience, got %v", err)
	}
}

func TestJWTClaimContract_Validate_Expired(t *testing.T) {
	now := time.Now()
	claims := newValidJWTClaimContract(now)
	claims.ExpiresAtUnix = now.Add(-1 * time.Minute).Unix()

	err := claims.Validate(newValidJWTValidationPolicy(), now)
	if err == nil {
		t.Fatal("expected expired error")
	}
	if err != ErrJWTExpired {
		t.Fatalf("expected ErrJWTExpired, got %v", err)
	}
}

func TestJWTClaimContract_Validate_NotYetValid(t *testing.T) {
	now := time.Now()
	claims := newValidJWTClaimContract(now)
	claims.NotBeforeUnix = now.Add(2 * time.Minute).Unix()

	err := claims.Validate(newValidJWTValidationPolicy(), now)
	if err == nil {
		t.Fatal("expected not yet valid error")
	}
	if err != ErrJWTNotYetValid {
		t.Fatalf("expected ErrJWTNotYetValid, got %v", err)
	}
}

func TestJWTClaimContract_Validate_IssuedAtInFuture(t *testing.T) {
	now := time.Now()
	claims := newValidJWTClaimContract(now)
	claims.IssuedAtUnix = now.Add(2 * time.Minute).Unix()
	claims.ExpiresAtUnix = now.Add(30 * time.Minute).Unix()

	err := claims.Validate(newValidJWTValidationPolicy(), now)
	if err == nil {
		t.Fatal("expected issued at in future error")
	}
	if err != ErrJWTIssuedAtInFuture {
		t.Fatalf("expected ErrJWTIssuedAtInFuture, got %v", err)
	}
}

func TestJWTClaimContract_Validate_InvalidExpiryWindow(t *testing.T) {
	now := time.Now()
	claims := newValidJWTClaimContract(now)
	claims.IssuedAtUnix = now.Add(10 * time.Minute).Unix()
	claims.ExpiresAtUnix = now.Add(5 * time.Minute).Unix()

	err := claims.Validate(newValidJWTValidationPolicy(), now)
	if err == nil {
		t.Fatal("expected invalid expiry window error")
	}
	if err != ErrJWTInvalidExpiryWindow {
		t.Fatalf("expected ErrJWTInvalidExpiryWindow, got %v", err)
	}
}
