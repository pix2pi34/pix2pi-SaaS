package db

import (
	"strings"
	"testing"
)

func TestBuildTenantRLSCheckExpression_Success(t *testing.T) {
	got, err := BuildTenantRLSCheckExpression("tenant_id")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expected := "tenant_id::text = current_setting('app.tenant_id', true)"
	if got != expected {
		t.Fatalf("expected %s, got %s", expected, got)
	}
}

func TestBuildTenantRLSCheckExpression_InvalidColumn(t *testing.T) {
	_, err := BuildTenantRLSCheckExpression("tenant-id")
	if err == nil {
		t.Fatal("expected invalid column error")
	}
}

func TestValidateTenantRLSGuardStatements_Success(t *testing.T) {
	stmts, err := BuildTenantRLSPolicyStatements("snapshots", "tenant_id", "")
	if err != nil {
		t.Fatalf("unexpected build error: %v", err)
	}

	err = ValidateTenantRLSGuardStatements(
		stmts,
		"snapshots",
		"tenant_id",
		"",
	)
	if err != nil {
		t.Fatalf("unexpected validation error: %v", err)
	}
}

func TestValidateTenantRLSGuardStatements_MissingForce(t *testing.T) {
	stmts, err := BuildTenantRLSPolicyStatements("snapshots", "tenant_id", "")
	if err != nil {
		t.Fatalf("unexpected build error: %v", err)
	}

	stmts[1] = "ALTER TABLE snapshots ENABLE ROW LEVEL SECURITY"

	err = ValidateTenantRLSGuardStatements(
		stmts,
		"snapshots",
		"tenant_id",
		"",
	)
	if err == nil {
		t.Fatal("expected missing force validation error")
	}
}

func TestValidateTenantRLSGuardStatements_MissingTenantSessionGuard(t *testing.T) {
	stmts, err := BuildTenantRLSPolicyStatements("snapshots", "tenant_id", "")
	if err != nil {
		t.Fatalf("unexpected build error: %v", err)
	}

	stmts[3] = strings.ReplaceAll(
		stmts[3],
		"tenant_id::text = current_setting('app.tenant_id', true)",
		"tenant_id::text = 'broken'",
	)

	err = ValidateTenantRLSGuardStatements(
		stmts,
		"snapshots",
		"tenant_id",
		"",
	)
	if err == nil {
		t.Fatal("expected tenant session guard validation error")
	}
}

func TestValidateTenantRLSGuardStatements_InvalidCount(t *testing.T) {
	err := ValidateTenantRLSGuardStatements(
		[]string{"only-one"},
		"snapshots",
		"tenant_id",
		"",
	)
	if err == nil {
		t.Fatal("expected invalid statement count error")
	}
}
