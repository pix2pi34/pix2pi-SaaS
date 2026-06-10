package db

import "testing"

func TestTenantSchemaName_Success(t *testing.T) {
	got, err := TenantSchemaName(42)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if got != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", got)
	}
}

func TestTenantSchemaName_ZeroTenant(t *testing.T) {
	_, err := TenantSchemaName(0)
	if err == nil {
		t.Fatal("expected zero tenant error")
	}
}

func TestBuildTenantSessionStatements_Success(t *testing.T) {
	stmts, schema, err := BuildTenantSessionStatements(42)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if schema != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", schema)
	}

	if len(stmts) != 3 {
		t.Fatalf("expected 3 statements, got %d", len(stmts))
	}

	expected0 := "SELECT set_config('app.tenant_id', '42', true)"
	expected1 := "SELECT set_config('app.tenant_schema', 'tenant_42', true)"
	expected2 := `SET LOCAL search_path TO "tenant_42", public`

	if stmts[0] != expected0 {
		t.Fatalf("expected %s, got %s", expected0, stmts[0])
	}
	if stmts[1] != expected1 {
		t.Fatalf("expected %s, got %s", expected1, stmts[1])
	}
	if stmts[2] != expected2 {
		t.Fatalf("expected %s, got %s", expected2, stmts[2])
	}
}

func TestBuildTenantSessionStatements_InvalidTenant(t *testing.T) {
	_, _, err := BuildTenantSessionStatements(0)
	if err == nil {
		t.Fatal("expected invalid tenant error")
	}
}
