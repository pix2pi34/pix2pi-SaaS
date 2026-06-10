package db

import "testing"

func TestBuildTenantQueryScopeSpec_Success(t *testing.T) {
	spec, err := BuildTenantQueryScopeSpec(42, "tenant_id")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if spec.TenantID != 42 {
		t.Fatalf("expected 42, got %d", spec.TenantID)
	}

	if spec.TenantColumn != "tenant_id" {
		t.Fatalf("expected tenant_id, got %s", spec.TenantColumn)
	}

	if spec.WhereClause != "tenant_id = ?" {
		t.Fatalf("expected tenant_id = ?, got %s", spec.WhereClause)
	}

	if len(spec.Args) != 1 {
		t.Fatalf("expected 1 arg, got %d", len(spec.Args))
	}

	arg0, ok := spec.Args[0].(uint)
	if !ok {
		t.Fatalf("expected uint arg, got %T", spec.Args[0])
	}

	if arg0 != 42 {
		t.Fatalf("expected arg 42, got %d", arg0)
	}
}

func TestBuildTenantQueryScopeSpec_DefaultColumn(t *testing.T) {
	spec, err := BuildTenantQueryScopeSpec(42, "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if spec.TenantColumn != "tenant_id" {
		t.Fatalf("expected tenant_id, got %s", spec.TenantColumn)
	}

	if spec.WhereClause != "tenant_id = ?" {
		t.Fatalf("expected tenant_id = ?, got %s", spec.WhereClause)
	}
}

func TestBuildTenantQueryScopeSpec_InvalidTenant(t *testing.T) {
	_, err := BuildTenantQueryScopeSpec(0, "tenant_id")
	if err == nil {
		t.Fatal("expected invalid tenant error")
	}
}

func TestBuildTenantQueryScopeSpec_InvalidColumn(t *testing.T) {
	_, err := BuildTenantQueryScopeSpec(42, "tenant-id")
	if err == nil {
		t.Fatal("expected invalid column error")
	}
}

func TestApplyTenantQueryScope_NilDB(t *testing.T) {
	_, err := ApplyTenantQueryScopeByID(nil, 42, "tenant_id")
	if err == nil {
		t.Fatal("expected nil db error")
	}
}
