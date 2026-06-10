package tenancy

import "testing"

func TestNewTenantIdentity_Success(t *testing.T) {
	got, err := NewTenantIdentity("tenant_42", "uuid-42")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if got.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", got.TenantID)
	}
	if got.TenantUUID != "uuid-42" {
		t.Fatalf("expected uuid-42, got %s", got.TenantUUID)
	}
}

func TestNewTenantIdentity_RequiresTenantID(t *testing.T) {
	_, err := NewTenantIdentity("", "uuid-42")
	if err == nil {
		t.Fatal("expected tenant id error")
	}
	if err != ErrEmptyTenantID {
		t.Fatalf("expected ErrEmptyTenantID, got %v", err)
	}
}

func TestNewTenantIdentity_RequiresTenantUUID(t *testing.T) {
	_, err := NewTenantIdentity("tenant_42", "")
	if err == nil {
		t.Fatal("expected tenant uuid error")
	}
	if err != ErrEmptyTenantUUID {
		t.Fatalf("expected ErrEmptyTenantUUID, got %v", err)
	}
}

func TestTenantIdentity_RequireHeaderMatch_Success(t *testing.T) {
	ti, err := NewTenantIdentity("tenant_42", "uuid-42")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if err := ti.RequireHeaderMatch("tenant_42"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestTenantIdentity_RequireHeaderMatch_Mismatch(t *testing.T) {
	ti, err := NewTenantIdentity("tenant_42", "uuid-42")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err = ti.RequireHeaderMatch("tenant_99")
	if err == nil {
		t.Fatal("expected boundary violation")
	}
	if err != ErrTenantBoundaryViolation {
		t.Fatalf("expected ErrTenantBoundaryViolation, got %v", err)
	}
}
