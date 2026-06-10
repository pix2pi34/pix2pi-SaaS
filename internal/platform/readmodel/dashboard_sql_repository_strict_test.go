package readmodel

import (
	"context"
	"testing"
)

func TestDashboardSQLRepository_QueryDashboard_SourceMismatch(t *testing.T) {
	executor := &fakeDashboardRowExecutor{}

	repo, err := NewDashboardSQLRepository(executor)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	desc := ProjectionRepositoryDescriptor{
		Name:          "dashboard_kpi",
		TableName:     "rm_dashboard_kpi",
		FullTableName: "readmodel.rm_dashboard_kpi",
		TenantColumn:  "tenant_id",
	}

	target := TenantQueryTarget{
		ProjectionName: "dashboard_kpi",
		TableName:      "rm_dashboard_kpi",
		FullTableName:  "readmodel.rm_other_table",
		TenantColumn:   "tenant_id",
	}

	plan, err := BuildTenantQueryAccessPlan("tenant_42", target)
	if err != nil {
		t.Fatalf("unexpected access plan error: %v", err)
	}

	_, err = repo.QueryDashboard(context.Background(), desc, plan, DashboardQueryRequest{
		TenantID:   "tenant_42",
		Projection: "dashboard_kpi",
		QueryName:  "branch_dashboard",
		BranchID:   "branch_1",
		PeriodKey:  "2026_04",
		Limit:      10,
	})
	if err == nil {
		t.Fatal("expected source mismatch error")
	}
	if err != ErrTenantAccessPlanSourceMismatch {
		t.Fatalf("expected ErrTenantAccessPlanSourceMismatch, got %v", err)
	}
}

func TestDashboardSQLRepository_QueryDashboard_ColumnMismatch(t *testing.T) {
	executor := &fakeDashboardRowExecutor{}

	repo, err := NewDashboardSQLRepository(executor)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	desc := ProjectionRepositoryDescriptor{
		Name:          "dashboard_kpi",
		TableName:     "rm_dashboard_kpi",
		FullTableName: "readmodel.rm_dashboard_kpi",
		TenantColumn:  "tenant_id",
	}

	target := TenantQueryTarget{
		ProjectionName: "dashboard_kpi",
		TableName:      "rm_dashboard_kpi",
		FullTableName:  "readmodel.rm_dashboard_kpi",
		TenantColumn:   "tenant_uuid",
	}

	plan, err := BuildTenantQueryAccessPlan("tenant_42", target)
	if err != nil {
		t.Fatalf("unexpected access plan error: %v", err)
	}

	_, err = repo.QueryDashboard(context.Background(), desc, plan, DashboardQueryRequest{
		TenantID:   "tenant_42",
		Projection: "dashboard_kpi",
		QueryName:  "branch_dashboard",
		BranchID:   "branch_1",
		PeriodKey:  "2026_04",
		Limit:      10,
	})
	if err == nil {
		t.Fatal("expected column mismatch error")
	}
	if err != ErrTenantAccessPlanColumnMismatch {
		t.Fatalf("expected ErrTenantAccessPlanColumnMismatch, got %v", err)
	}
}

func TestDashboardSQLRepository_QueryDashboard_GuardDisabled(t *testing.T) {
	executor := &fakeDashboardRowExecutor{}

	repo, err := NewDashboardSQLRepository(executor)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	desc := ProjectionRepositoryDescriptor{
		Name:          "dashboard_kpi",
		TableName:     "rm_dashboard_kpi",
		FullTableName: "readmodel.rm_dashboard_kpi",
		TenantColumn:  "tenant_id",
	}

	target, err := desc.TenantQueryTarget()
	if err != nil {
		t.Fatalf("unexpected target error: %v", err)
	}

	plan, err := BuildTenantQueryAccessPlan("tenant_42", target)
	if err != nil {
		t.Fatalf("unexpected access plan error: %v", err)
	}
	plan.GuardRequired = false

	_, err = repo.QueryDashboard(context.Background(), desc, plan, DashboardQueryRequest{
		TenantID:   "tenant_42",
		Projection: "dashboard_kpi",
		QueryName:  "branch_dashboard",
		BranchID:   "branch_1",
		PeriodKey:  "2026_04",
		Limit:      10,
	})
	if err == nil {
		t.Fatal("expected guard required error")
	}
	if err != ErrTenantAccessPlanGuardRequired {
		t.Fatalf("expected ErrTenantAccessPlanGuardRequired, got %v", err)
	}
}

func TestDashboardSQLRepository_QueryDashboard_InvalidArgs(t *testing.T) {
	executor := &fakeDashboardRowExecutor{}

	repo, err := NewDashboardSQLRepository(executor)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	desc := ProjectionRepositoryDescriptor{
		Name:          "dashboard_kpi",
		TableName:     "rm_dashboard_kpi",
		FullTableName: "readmodel.rm_dashboard_kpi",
		TenantColumn:  "tenant_id",
	}

	target, err := desc.TenantQueryTarget()
	if err != nil {
		t.Fatalf("unexpected target error: %v", err)
	}

	plan := TenantQueryAccessPlan{
		TenantID:      "tenant_42",
		Target:        target,
		WhereClause:   "tenant_id = ?",
		Args:          []any{},
		GuardRequired: true,
	}

	_, err = repo.QueryDashboard(context.Background(), desc, plan, DashboardQueryRequest{
		TenantID:   "tenant_42",
		Projection: "dashboard_kpi",
		QueryName:  "branch_dashboard",
		BranchID:   "branch_1",
		PeriodKey:  "2026_04",
		Limit:      10,
	})
	if err == nil {
		t.Fatal("expected invalid args error")
	}
}
