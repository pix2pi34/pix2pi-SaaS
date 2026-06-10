package readmodel

import (
	"context"
	"testing"
)

type fakeExportRepository struct {
	data     ExportQueryData
	err      error
	lastDesc ProjectionRepositoryDescriptor
	lastPlan TenantQueryAccessPlan
	lastReq  ExportQueryRequest
}

func (r *fakeExportRepository) QueryExport(
	ctx context.Context,
	descriptor ProjectionRepositoryDescriptor,
	accessPlan TenantQueryAccessPlan,
	req ExportQueryRequest,
) (ExportQueryData, error) {
	r.lastDesc = descriptor
	r.lastPlan = accessPlan
	r.lastReq = req
	return r.data, r.err
}

func newExportQueryTestStore(t *testing.T) *ReportingStore {
	t.Helper()

	registry := NewProjectionContractRegistry()

	err := registry.Register(ProjectionSchema{
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

func TestNewExportQueryService(t *testing.T) {
	store := newExportQueryTestStore(t)
	repo := &fakeExportRepository{}

	svc, err := NewExportQueryService(store, repo)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if svc == nil {
		t.Fatal("expected export query service")
	}
}

func TestExportQueryRequest_Validate(t *testing.T) {
	err := ExportQueryRequest{
		TenantID:   "tenant_42",
		Projection: "sales_reports",
		QueryName:  "monthly_export",
		Format:     ExportFormatCSV,
		BranchID:   "branch_1",
		PeriodKey:  "2026_04",
		BatchSize:  100,
	}.Validate()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestExportQueryService_Query(t *testing.T) {
	store := newExportQueryTestStore(t)
	repo := &fakeExportRepository{
		data: ExportQueryData{
			Rows: []ExportRecord{
				{
					RecordKey: "row_1",
					Columns: map[string]string{
						"total": "100",
					},
				},
			},
			NextCursor: "cursor_2",
		},
	}

	svc, err := NewExportQueryService(store, repo)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	result, err := svc.Query(context.Background(), ExportQueryRequest{
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

	if repo.lastDesc.FullTableName != "readmodel.rm_sales_reports" {
		t.Fatalf("expected readmodel.rm_sales_reports, got %s", repo.lastDesc.FullTableName)
	}
	if repo.lastPlan.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", repo.lastPlan.TenantID)
	}
	if repo.lastPlan.WhereClause != "tenant_id = ?" {
		t.Fatalf("expected tenant_id = ?, got %s", repo.lastPlan.WhereClause)
	}
	if result.SourceTable != "readmodel.rm_sales_reports" {
		t.Fatalf("expected readmodel.rm_sales_reports, got %s", result.SourceTable)
	}
	if result.RowCount != 1 {
		t.Fatalf("expected 1 row, got %d", result.RowCount)
	}
}

func TestExportQueryService_Query_UnknownProjection(t *testing.T) {
	store := newExportQueryTestStore(t)
	repo := &fakeExportRepository{}

	svc, err := NewExportQueryService(store, repo)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	_, err = svc.Query(context.Background(), ExportQueryRequest{
		TenantID:   "tenant_42",
		Projection: "unknown_projection",
		QueryName:  "monthly_export",
		Format:     ExportFormatCSV,
		BranchID:   "branch_1",
		PeriodKey:  "2026_04",
		BatchSize:  100,
	})
	if err == nil {
		t.Fatal("expected unknown projection error")
	}
}

func TestExportQueryService_Query_RepoError(t *testing.T) {
	store := newExportQueryTestStore(t)
	repo := &fakeExportRepository{
		err: ErrNilExportRepository,
	}

	svc, err := NewExportQueryService(store, repo)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	_, err = svc.Query(context.Background(), ExportQueryRequest{
		TenantID:   "tenant_42",
		Projection: "sales_reports",
		QueryName:  "monthly_export",
		Format:     ExportFormatCSV,
		BranchID:   "branch_1",
		PeriodKey:  "2026_04",
		BatchSize:  100,
	})
	if err == nil {
		t.Fatal("expected repo error")
	}
}

func TestExportQueryData_InvalidRow(t *testing.T) {
	err := ExportQueryData{
		Rows: []ExportRecord{
			{
				RecordKey: "",
				Columns: map[string]string{
					"total": "100",
				},
			},
		},
	}.Validate()
	if err == nil {
		t.Fatal("expected invalid row error")
	}
}
