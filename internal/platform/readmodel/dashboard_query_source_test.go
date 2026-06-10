package readmodel

import (
	"context"
	"testing"
)

type fakeDashboardRepository struct {
	data     DashboardQueryData
	err      error
	lastDesc ProjectionRepositoryDescriptor
	lastPlan TenantQueryAccessPlan
	lastReq  DashboardQueryRequest
}

func (r *fakeDashboardRepository) QueryDashboard(
	ctx context.Context,
	descriptor ProjectionRepositoryDescriptor,
	accessPlan TenantQueryAccessPlan,
	req DashboardQueryRequest,
) (DashboardQueryData, error) {
	r.lastDesc = descriptor
	r.lastPlan = accessPlan
	r.lastReq = req
	return r.data, r.err
}

func newDashboardQueryTestStore(t *testing.T) *ReportingStore {
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

func TestNewDashboardQueryService(t *testing.T) {
	store := newDashboardQueryTestStore(t)
	repo := &fakeDashboardRepository{}

	svc, err := NewDashboardQueryService(store, repo)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if svc == nil {
		t.Fatal("expected dashboard query service")
	}
}

func TestDashboardQueryRequest_Validate(t *testing.T) {
	err := DashboardQueryRequest{
		TenantID:   "tenant_42",
		Projection: "dashboard_kpi",
		QueryName:  "branch_dashboard",
		BranchID:   "branch_1",
		PeriodKey:  "2026_04",
		Limit:      10,
	}.Validate()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestDashboardQueryService_Query(t *testing.T) {
	store := newDashboardQueryTestStore(t)
	repo := &fakeDashboardRepository{
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

	svc, err := NewDashboardQueryService(store, repo)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
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
		t.Fatalf("unexpected error: %v", err)
	}

	if repo.lastDesc.FullTableName != "readmodel.rm_dashboard_kpi" {
		t.Fatalf("expected readmodel.rm_dashboard_kpi, got %s", repo.lastDesc.FullTableName)
	}
	if repo.lastPlan.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", repo.lastPlan.TenantID)
	}
	if repo.lastPlan.WhereClause != "tenant_id = ?" {
		t.Fatalf("expected tenant_id = ?, got %s", repo.lastPlan.WhereClause)
	}
	if result.SourceTable != "readmodel.rm_dashboard_kpi" {
		t.Fatalf("expected source table readmodel.rm_dashboard_kpi, got %s", result.SourceTable)
	}
	if result.RecordsCount != 1 {
		t.Fatalf("expected 1 record, got %d", result.RecordsCount)
	}
}

func TestDashboardQueryService_Query_UnknownProjection(t *testing.T) {
	store := newDashboardQueryTestStore(t)
	repo := &fakeDashboardRepository{}

	svc, err := NewDashboardQueryService(store, repo)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	_, err = svc.Query(context.Background(), DashboardQueryRequest{
		TenantID:   "tenant_42",
		Projection: "unknown_projection",
		QueryName:  "branch_dashboard",
		BranchID:   "branch_1",
		PeriodKey:  "2026_04",
		Limit:      10,
	})
	if err == nil {
		t.Fatal("expected unknown projection error")
	}
}

func TestDashboardQueryService_Query_RepoError(t *testing.T) {
	store := newDashboardQueryTestStore(t)
	repo := &fakeDashboardRepository{
		err: ErrNilDashboardRepository,
	}

	svc, err := NewDashboardQueryService(store, repo)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	_, err = svc.Query(context.Background(), DashboardQueryRequest{
		TenantID:   "tenant_42",
		Projection: "dashboard_kpi",
		QueryName:  "branch_dashboard",
		BranchID:   "branch_1",
		PeriodKey:  "2026_04",
		Limit:      10,
	})
	if err == nil {
		t.Fatal("expected repo error")
	}
}

func TestDashboardQueryData_InvalidCard(t *testing.T) {
	err := DashboardQueryData{
		Cards: []DashboardCard{
			{
				MetricKey: "",
				Label:     "Broken",
				Value:     1,
				SortOrder: 1,
			},
		},
	}.Validate()
	if err == nil {
		t.Fatal("expected invalid card error")
	}
}
