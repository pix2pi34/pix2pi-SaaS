package db

import (
	"strings"
	"testing"
)

func TestValidateSQLIdentifier_Success(t *testing.T) {
	err := ValidateSQLIdentifier("snapshots")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestValidateSQLIdentifier_Invalid(t *testing.T) {
	err := ValidateSQLIdentifier("bad-table-name")
	if err == nil {
		t.Fatal("expected invalid identifier error")
	}
}

func TestDefaultTenantRLSPolicyName(t *testing.T) {
	got := DefaultTenantRLSPolicyName("snapshots")
	if got != "rls_snapshots_tenant_isolation" {
		t.Fatalf("expected rls_snapshots_tenant_isolation, got %s", got)
	}
}

func TestBuildTenantRLSPolicyStatements_DefaultPolicy(t *testing.T) {
	stmts, err := BuildTenantRLSPolicyStatements("snapshots", "tenant_id", "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(stmts) != 4 {
		t.Fatalf("expected 4 statements, got %d", len(stmts))
	}

	if stmts[0] != "ALTER TABLE snapshots ENABLE ROW LEVEL SECURITY" {
		t.Fatalf("unexpected stmt[0]: %s", stmts[0])
	}

	if stmts[1] != "ALTER TABLE snapshots FORCE ROW LEVEL SECURITY" {
		t.Fatalf("unexpected stmt[1]: %s", stmts[1])
	}

	if stmts[2] != "DROP POLICY IF EXISTS rls_snapshots_tenant_isolation ON snapshots" {
		t.Fatalf("unexpected stmt[2]: %s", stmts[2])
	}

	if !strings.Contains(stmts[3], "CREATE POLICY rls_snapshots_tenant_isolation ON snapshots") {
		t.Fatalf("unexpected stmt[3]: %s", stmts[3])
	}

	if !strings.Contains(stmts[3], "tenant_id::text = current_setting('app.tenant_id', true)") {
		t.Fatalf("stmt[3] tenant match eksik: %s", stmts[3])
	}
}

func TestBuildTenantRLSPolicyStatements_CustomPolicy(t *testing.T) {
	stmts, err := BuildTenantRLSPolicyStatements("journal_entries", "tenant_id", "journal_tenant_guard")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if stmts[2] != "DROP POLICY IF EXISTS journal_tenant_guard ON journal_entries" {
		t.Fatalf("unexpected stmt[2]: %s", stmts[2])
	}

	if !strings.Contains(stmts[3], "CREATE POLICY journal_tenant_guard ON journal_entries") {
		t.Fatalf("unexpected stmt[3]: %s", stmts[3])
	}
}

func TestBuildTenantRLSPolicyStatements_InvalidTable(t *testing.T) {
	_, err := BuildTenantRLSPolicyStatements("bad-table", "tenant_id", "")
	if err == nil {
		t.Fatal("expected invalid table error")
	}
}

func TestBuildTenantRLSPolicyStatements_InvalidColumn(t *testing.T) {
	_, err := BuildTenantRLSPolicyStatements("snapshots", "tenant-id", "")
	if err == nil {
		t.Fatal("expected invalid column error")
	}
}
