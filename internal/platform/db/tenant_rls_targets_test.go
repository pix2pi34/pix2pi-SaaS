package db

import "testing"

func TestSnapshotTenantRLSTarget(t *testing.T) {
	target := SnapshotTenantRLSTarget()

	if target.TableName != "snapshots" {
		t.Fatalf("expected snapshots, got %s", target.TableName)
	}

	if target.TenantColumn != "tenant_id" {
		t.Fatalf("expected tenant_id, got %s", target.TenantColumn)
	}

	if target.PolicyName != "rls_snapshots_tenant_isolation" {
		t.Fatalf("expected rls_snapshots_tenant_isolation, got %s", target.PolicyName)
	}
}

func TestJournalEntriesTenantRLSTarget(t *testing.T) {
	target := JournalEntriesTenantRLSTarget()

	if target.TableName != "journal_entries" {
		t.Fatalf("expected journal_entries, got %s", target.TableName)
	}

	if target.TenantColumn != "tenant_id" {
		t.Fatalf("expected tenant_id, got %s", target.TenantColumn)
	}

	if target.PolicyName != "rls_journal_entries_tenant_isolation" {
		t.Fatalf("expected rls_journal_entries_tenant_isolation, got %s", target.PolicyName)
	}
}

func TestTenantRLSTarget_Validate_Success(t *testing.T) {
	target := TenantRLSTarget{
		TableName:    "snapshots",
		TenantColumn: "tenant_id",
		PolicyName:   "rls_snapshots_tenant_isolation",
	}

	if err := target.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestTenantRLSTarget_Validate_InvalidTable(t *testing.T) {
	target := TenantRLSTarget{
		TableName:    "bad-table",
		TenantColumn: "tenant_id",
		PolicyName:   "rls_snapshots_tenant_isolation",
	}

	if err := target.Validate(); err == nil {
		t.Fatal("expected invalid table error")
	}
}

func TestTenantRLSTarget_Validate_InvalidPolicy(t *testing.T) {
	target := TenantRLSTarget{
		TableName:    "snapshots",
		TenantColumn: "tenant_id",
		PolicyName:   "bad-policy-name",
	}

	if err := target.Validate(); err == nil {
		t.Fatal("expected invalid policy error")
	}
}

func TestDefaultCoreTenantRLSTargets(t *testing.T) {
	targets := DefaultCoreTenantRLSTargets()

	if len(targets) != 2 {
		t.Fatalf("expected 2 targets, got %d", len(targets))
	}

	if targets[0].TableName != "snapshots" {
		t.Fatalf("expected snapshots, got %s", targets[0].TableName)
	}

	if targets[1].TableName != "journal_entries" {
		t.Fatalf("expected journal_entries, got %s", targets[1].TableName)
	}
}

func TestApplyTenantRLSTarget_NilTx(t *testing.T) {
	err := ApplyTenantRLSTarget(nil, SnapshotTenantRLSTarget())
	if err == nil {
		t.Fatal("expected nil tx error")
	}
}
