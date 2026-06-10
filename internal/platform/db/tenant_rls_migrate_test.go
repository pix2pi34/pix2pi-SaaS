package db

import "testing"

func TestBuildTenantRLSMigrationPlan_Success(t *testing.T) {
	targets := []TenantRLSTarget{
		{
			TableName:    "snapshots",
			TenantColumn: "tenant_id",
			PolicyName:   "rls_snapshots_tenant_isolation",
		},
		{
			TableName:    "journal_entries",
			TenantColumn: "tenant_id",
			PolicyName:   "rls_journal_entries_tenant_isolation",
		},
	}

	plan, err := BuildTenantRLSMigrationPlan(
		targets,
		func(tableName string) bool {
			return tableName == "snapshots"
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(plan.ApplyTargets) != 1 {
		t.Fatalf("expected 1 apply target, got %d", len(plan.ApplyTargets))
	}

	if len(plan.SkipTargets) != 1 {
		t.Fatalf("expected 1 skip target, got %d", len(plan.SkipTargets))
	}

	if plan.ApplyTargets[0].TableName != "snapshots" {
		t.Fatalf("expected snapshots, got %s", plan.ApplyTargets[0].TableName)
	}

	if plan.SkipTargets[0].TableName != "journal_entries" {
		t.Fatalf("expected journal_entries, got %s", plan.SkipTargets[0].TableName)
	}
}

func TestBuildTenantRLSMigrationPlan_InvalidTarget(t *testing.T) {
	targets := []TenantRLSTarget{
		{
			TableName:    "bad-table",
			TenantColumn: "tenant_id",
			PolicyName:   "rls_bad_table_tenant_isolation",
		},
	}

	_, err := BuildTenantRLSMigrationPlan(
		targets,
		func(tableName string) bool {
			return true
		},
	)
	if err == nil {
		t.Fatal("expected invalid target error")
	}
}

func TestBuildTenantRLSMigrationPlan_NilHasTable(t *testing.T) {
	_, err := BuildTenantRLSMigrationPlan(DefaultCoreTenantRLSTargets(), nil)
	if err == nil {
		t.Fatal("expected nil hasTable error")
	}
}
