package readmodel

import "testing"

func newTenantGuardTestStore(t *testing.T) *ReportingStore {
	t.Helper()

	registry := NewProjectionContractRegistry()

	err := registry.Register(ProjectionSchema{
		Name:              "dashboard_kpi",
		TableName:         "rm_dashboard_kpi",
		TenantColumn:      "tenant_id",
		PrimaryKeyColumns: []string{"tenant_id", "metric_key"},
		VersionColumn:     "projection_version",
		UpdatedAtColumn:   "updated_at",
		SupportsRebuild:   true,
		Description:       "dashboard kpi projection kontrati",
	})
	if err != nil {
		t.Fatalf("unexpected registry error: %v", err)
	}

	err = registry.Register(ProjectionSchema{
		Name:              "sales_reports",
		TableName:         "rm_sales_reports",
		TenantColumn:      "tenant_id",
		PrimaryKeyColumns: []string{"tenant_id", "report_key"},
		VersionColumn:     "projection_version",
		UpdatedAtColumn:   "updated_at",
		SupportsRebuild:   true,
		Description:       "sales reports projection kontrati",
	})
	if err != nil {
		t.Fatalf("unexpected registry error: %v", err)
	}

	store, err := NewReportingStore(ReportingDBConfig{
		Driver:   ReportingDriverPostgres,
		Host:     "127.0.0.1",
		Port:     5433,
		User:     "pix2pi",
		Password: "secret",
		DBName:   "pix2pi_reporting",
		Schema:   "readmodel",
		SSLMode:  "disable",
	}, registry)
	if err != nil {
		t.Fatalf("unexpected store error: %v", err)
	}

	return store
}

func TestReportingTenantGuard_GuardDashboardRequest_BuildsAccessPlan(t *testing.T) {
	store := newTenantGuardTestStore(t)

	guard, err := NewReportingTenantGuard(store)
	if err != nil {
		t.Fatalf("unexpected guard error: %v", err)
	}

	plan, err := guard.GuardDashboardRequest(DashboardQueryRequest{
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

	if plan.QueryTarget.FullTableName != "readmodel.rm_dashboard_kpi" {
		t.Fatalf("expected readmodel.rm_dashboard_kpi, got %s", plan.QueryTarget.FullTableName)
	}
	if plan.AccessPlan.WhereClause != "tenant_id = ?" {
		t.Fatalf("expected tenant_id = ?, got %s", plan.AccessPlan.WhereClause)
	}
	if plan.AccessPlan.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", plan.AccessPlan.TenantID)
	}
}

func TestReportingTenantGuard_GuardExportRequest_BuildsAccessPlan(t *testing.T) {
	store := newTenantGuardTestStore(t)

	guard, err := NewReportingTenantGuard(store)
	if err != nil {
		t.Fatalf("unexpected guard error: %v", err)
	}

	plan, err := guard.GuardExportRequest(ExportQueryRequest{
		TenantID:   "tenant_42",
		Projection: "sales_reports",
		QueryName:  "monthly_export",
		Format:     ExportFormatCSV,
		BranchID:   "branch_1",
		PeriodKey:  "2026_04",
		BatchSize:  100,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if plan.QueryTarget.FullTableName != "readmodel.rm_sales_reports" {
		t.Fatalf("expected readmodel.rm_sales_reports, got %s", plan.QueryTarget.FullTableName)
	}
	if plan.AccessPlan.WhereClause != "tenant_id = ?" {
		t.Fatalf("expected tenant_id = ?, got %s", plan.AccessPlan.WhereClause)
	}
	if plan.AccessPlan.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", plan.AccessPlan.TenantID)
	}
}
