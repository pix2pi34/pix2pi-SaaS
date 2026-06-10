package kernel

import (
	"testing"

	tenancy "github.com/divrigili/pix2pi-SaaS/internal/platform/tenancy"
)

func TestResolveTenantContextIdentity_FullIdentitySuccess(t *testing.T) {
	got, err := ResolveTenantContextIdentity("42", "uuid-42", "42")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if got.TenantID != "42" {
		t.Fatalf("expected 42, got %s", got.TenantID)
	}
	if got.TenantUUID != "uuid-42" {
		t.Fatalf("expected uuid-42, got %s", got.TenantUUID)
	}
	if !got.IdentityVerified {
		t.Fatal("expected identity verified")
	}
	if !got.HeaderMatched {
		t.Fatal("expected header matched")
	}
}

func TestResolveTenantContextIdentity_FullIdentityMismatch(t *testing.T) {
	_, err := ResolveTenantContextIdentity("42", "uuid-42", "99")
	if err == nil {
		t.Fatal("expected mismatch error")
	}
	if err != tenancy.ErrTenantBoundaryViolation {
		t.Fatalf("expected ErrTenantBoundaryViolation, got %v", err)
	}
}

func TestResolveTenantContextIdentity_LegacyLocalSuccess(t *testing.T) {
	got, err := ResolveTenantContextIdentity("42", "", "42")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if got.TenantID != "42" {
		t.Fatalf("expected 42, got %s", got.TenantID)
	}
	if !got.UsedLegacyFallback {
		t.Fatal("expected legacy fallback")
	}
}

func TestResolveTenantContextIdentity_HeaderOnlyFallback(t *testing.T) {
	got, err := ResolveTenantContextIdentity("", "", "42")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if got.TenantID != "42" {
		t.Fatalf("expected 42, got %s", got.TenantID)
	}
	if !got.UsedLegacyFallback {
		t.Fatal("expected legacy fallback")
	}
}

func TestResolveTenantContextIdentity_EmptyTenant(t *testing.T) {
	_, err := ResolveTenantContextIdentity("", "", "")
	if err == nil {
		t.Fatal("expected tenant missing error")
	}
	if err != tenancy.ErrEmptyTenantID {
		t.Fatalf("expected ErrEmptyTenantID, got %v", err)
	}
}
