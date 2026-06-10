package readmodel

import (
	"context"
	"testing"
)

type dashboardSecurityRepo struct {
	data     DashboardQueryData
	err      error
	lastPlan TenantQueryAccessPlan
}

func (r *dashboardSecurityRepo) QueryDashboard(
	ctx context.Context,
	descriptor ProjectionRepositoryDescriptor,
	accessPlan TenantQueryAccessPlan,
	req DashboardQueryRequest,
) (DashboardQueryData, error) {
	r.lastPlan = accessPlan
	return r.data, r.err
}

func newDashboardSecurityStore(t *testing.T, tenantColumn string) *ReportingStore {
	t.Helper()

	registry := NewProjectionContractRegistry()

	err := registry.Register(ProjectionSchema{
		Name:              "dashboard_kpi",
		TableName:         "rm_dashboard_kpi",
		TenantColumn:      tenantColumn,
		PrimaryKeyColumns: []string{"tenant_id", "metric_key"},
		VersionColumn:     "projection_version",
		UpdatedAtColumn:   "updated_at",
		SupportsRebuild:   true,
		Description:       "dashboard security projection",
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

func TestDashboardQueryService_Query_UsesTenantGuardAndQualityGate(t *testing.T) {
	repo := &dashboardSecurityRepo{
		data: DashboardQueryData{
			Cards: []DashboardCard{
				{
					MetricKey: "sales_total",
					Label:     "Sales Total",
					Value:     100,
					SortOrder: 1,
				},
			},
		},
	}

	store := newDashboardSecurityStore(t, "tenant_id")

	svc, err := NewDashboardQueryService(store, repo)
	if err != nil {
		t.Fatalf("unexpected service error: %v", err)
	}

	result, err := svc.Query(context.Background(), DashboardQueryRequest{
		TenantID:   "tenant_42",
		Projection: "dashboard_kpi",
		QueryName:  "branch_dashboard",
		BranchID:   "branch_1",
		PeriodKey:  "2026_04",
		Limit:      10,
	})
	if err != nil {
		t.Fatalf("unexpected query error: %v", err)
	}

	if result.SourceTable != "readmodel.rm_dashboard_kpi" {
		t.Fatalf("expected readmodel.rm_dashboard_kpi, got %s", result.SourceTable)
	}
	if result.RecordsCount != 1 {
		t.Fatalf("expected 1 record, got %d", result.RecordsCount)
	}
	if repo.lastPlan.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", repo.lastPlan.TenantID)
	}
	if repo.lastPlan.WhereClause != "tenant_id = ?" {
		t.Fatalf("expected tenant_id = ?, got %s", repo.lastPlan.WhereClause)
	}
}

func TestDashboardProjectionSchema_RejectsEmptyTenantColumn(t *testing.T) {
	registry := NewProjectionContractRegistry()

	err := registry.Register(ProjectionSchema{
		Name:              "dashboard_kpi",
		TableName:         "rm_dashboard_kpi",
		TenantColumn:      "",
		PrimaryKeyColumns: []string{"tenant_id", "metric_key"},
		VersionColumn:     "projection_version",
		UpdatedAtColumn:   "updated_at",
		SupportsRebuild:   true,
		Description:       "dashboard security projection",
	})
	if err == nil {
		t.Fatal("expected empty tenant column error")
	}

	if err != ErrEmptyTenantColumn {
		t.Fatalf("expected ErrEmptyTenantColumn, got %v", err)
	}
}
