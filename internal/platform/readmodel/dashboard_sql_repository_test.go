package readmodel

import (
	"context"
	"testing"
)

type fakeDashboardRowExecutor struct {
	rows    []DashboardCard
	err     error
	lastSQL string
	lastArgs []any
}

func (f *fakeDashboardRowExecutor) QueryDashboardRows(
	ctx context.Context,
	sql string,
	args []any,
) ([]DashboardCard, error) {
	f.lastSQL = sql
	f.lastArgs = append([]any(nil), args...)
	return append([]DashboardCard(nil), f.rows...), f.err
}

func TestNewDashboardSQLRepository(t *testing.T) {
	repo, err := NewDashboardSQLRepository(&fakeDashboardRowExecutor{})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if repo == nil {
		t.Fatal("expected dashboard sql repository")
	}
}

func TestDashboardSQLRepository_QueryDashboard_Success(t *testing.T) {
	executor := &fakeDashboardRowExecutor{
		rows: []DashboardCard{
			{
				MetricKey: "sales_total",
				Label:     "Sales Total",
				Value:     100,
				SortOrder: 1,
			},
		},
	}

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

	data, err := repo.QueryDashboard(context.Background(), desc, plan, DashboardQueryRequest{
		TenantID:   "tenant_42",
		Projection: "dashboard_kpi",
		QueryName:  "branch_dashboard",
		BranchID:   "branch_1",
		PeriodKey:  "2026_04",
		Limit:      10,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expectedSQL := "SELECT metric_key, label, value, sort_order FROM readmodel.rm_dashboard_kpi WHERE tenant_id = ? LIMIT 10"
	if executor.lastSQL != expectedSQL {
		t.Fatalf("expected %s, got %s", expectedSQL, executor.lastSQL)
	}

	if len(executor.lastArgs) != 1 {
		t.Fatalf("expected 1 arg, got %d", len(executor.lastArgs))
	}

	arg0, ok := executor.lastArgs[0].(string)
	if !ok {
		t.Fatalf("expected string arg, got %T", executor.lastArgs[0])
	}
	if arg0 != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", arg0)
	}

	if len(data.Cards) != 1 {
		t.Fatalf("expected 1 card, got %d", len(data.Cards))
	}
}

func TestDashboardSQLRepository_QueryDashboard_Mismatch(t *testing.T) {
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
		ProjectionName: "other_projection",
		TableName:      "rm_other",
		FullTableName:  "readmodel.rm_other",
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
		t.Fatal("expected mismatch error")
	}
	if err != ErrTenantAccessPlanProjectionMismatch {
		t.Fatalf("expected ErrTenantAccessPlanProjectionMismatch, got %v", err)
	}
}
