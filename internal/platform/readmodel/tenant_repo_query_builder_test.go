package readmodel

import "testing"

func newTenantRepoQueryTarget() TenantQueryTarget {
	return TenantQueryTarget{
		ProjectionName: "dashboard_kpi",
		TableName:      "rm_dashboard_kpi",
		FullTableName:  "readmodel.rm_dashboard_kpi",
		TenantColumn:   "tenant_id",
	}
}

func newTenantRepoAccessPlan() TenantQueryAccessPlan {
	target := newTenantRepoQueryTarget()

	return TenantQueryAccessPlan{
		TenantID:      "tenant_42",
		Target:        target,
		WhereClause:   "tenant_id = ?",
		Args:          []any{"tenant_42"},
		GuardRequired: true,
	}
}

func TestBuildTenantRepositoryQuery_Success(t *testing.T) {
	target := newTenantRepoQueryTarget()
	plan := newTenantRepoAccessPlan()

	query, err := BuildTenantRepositoryQuery(target, plan)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if query.ProjectionName != "dashboard_kpi" {
		t.Fatalf("expected dashboard_kpi, got %s", query.ProjectionName)
	}
	if query.SourceTable != "readmodel.rm_dashboard_kpi" {
		t.Fatalf("expected readmodel.rm_dashboard_kpi, got %s", query.SourceTable)
	}
	if query.WhereClause != "tenant_id = ?" {
		t.Fatalf("expected tenant_id = ?, got %s", query.WhereClause)
	}
	if len(query.Args) != 1 {
		t.Fatalf("expected 1 arg, got %d", len(query.Args))
	}
}

func TestBuildTenantRepositoryQuery_GuardRequired(t *testing.T) {
	target := newTenantRepoQueryTarget()
	plan := newTenantRepoAccessPlan()
	plan.GuardRequired = false

	_, err := BuildTenantRepositoryQuery(target, plan)
	if err == nil {
		t.Fatal("expected guard required error")
	}
	if err != ErrTenantAccessPlanGuardRequired {
		t.Fatalf("expected ErrTenantAccessPlanGuardRequired, got %v", err)
	}
}

func TestBuildTenantRepositoryQuery_ProjectionMismatch(t *testing.T) {
	target := newTenantRepoQueryTarget()
	plan := newTenantRepoAccessPlan()
	plan.Target.ProjectionName = "sales_reports"

	_, err := BuildTenantRepositoryQuery(target, plan)
	if err == nil {
		t.Fatal("expected projection mismatch error")
	}
	if err != ErrTenantAccessPlanProjectionMismatch {
		t.Fatalf("expected ErrTenantAccessPlanProjectionMismatch, got %v", err)
	}
}

func TestBuildTenantRepositoryQuery_SourceMismatch(t *testing.T) {
	target := newTenantRepoQueryTarget()
	plan := newTenantRepoAccessPlan()
	plan.Target.FullTableName = "readmodel.rm_other"

	_, err := BuildTenantRepositoryQuery(target, plan)
	if err == nil {
		t.Fatal("expected source mismatch error")
	}
	if err != ErrTenantAccessPlanSourceMismatch {
		t.Fatalf("expected ErrTenantAccessPlanSourceMismatch, got %v", err)
	}
}

func TestBuildTenantRepositoryQuery_ColumnMismatch(t *testing.T) {
	target := newTenantRepoQueryTarget()
	plan := newTenantRepoAccessPlan()
	plan.Target.TenantColumn = "tenant_uuid"

	_, err := BuildTenantRepositoryQuery(target, plan)
	if err == nil {
		t.Fatal("expected column mismatch error")
	}
	if err != ErrTenantAccessPlanColumnMismatch {
		t.Fatalf("expected ErrTenantAccessPlanColumnMismatch, got %v", err)
	}
}

func TestBuildTenantFilteredSelectSQL_Success(t *testing.T) {
	target := newTenantRepoQueryTarget()
	plan := newTenantRepoAccessPlan()

	sql, args, err := BuildTenantFilteredSelectSQL("*", target, plan)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expectedSQL := "SELECT * FROM readmodel.rm_dashboard_kpi WHERE tenant_id = ?"
	if sql != expectedSQL {
		t.Fatalf("expected %s, got %s", expectedSQL, sql)
	}

	if len(args) != 1 {
		t.Fatalf("expected 1 arg, got %d", len(args))
	}
	arg0, ok := args[0].(string)
	if !ok {
		t.Fatalf("expected string arg, got %T", args[0])
	}
	if arg0 != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", arg0)
	}
}

func TestBuildTenantFilteredSelectSQL_EmptySelect(t *testing.T) {
	target := newTenantRepoQueryTarget()
	plan := newTenantRepoAccessPlan()

	_, _, err := BuildTenantFilteredSelectSQL("", target, plan)
	if err == nil {
		t.Fatal("expected empty select clause error")
	}
	if err != ErrEmptySelectClause {
		t.Fatalf("expected ErrEmptySelectClause, got %v", err)
	}
}

func TestBuildDashboardRepositoryQuery_Success(t *testing.T) {
	desc := ProjectionRepositoryDescriptor{
		Name:          "dashboard_kpi",
		TableName:     "rm_dashboard_kpi",
		FullTableName: "readmodel.rm_dashboard_kpi",
		TenantColumn:  "tenant_id",
	}
	plan := newTenantRepoAccessPlan()

	query, err := BuildDashboardRepositoryQuery(desc, plan)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if query.SourceTable != "readmodel.rm_dashboard_kpi" {
		t.Fatalf("expected readmodel.rm_dashboard_kpi, got %s", query.SourceTable)
	}
}

func TestBuildExportRepositoryQuery_Success(t *testing.T) {
	desc := ProjectionRepositoryDescriptor{
		Name:          "dashboard_kpi",
		TableName:     "rm_dashboard_kpi",
		FullTableName: "readmodel.rm_dashboard_kpi",
		TenantColumn:  "tenant_id",
	}
	plan := newTenantRepoAccessPlan()

	query, err := BuildExportRepositoryQuery(desc, plan)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if query.WhereClause != "tenant_id = ?" {
		t.Fatalf("expected tenant_id = ?, got %s", query.WhereClause)
	}
}
