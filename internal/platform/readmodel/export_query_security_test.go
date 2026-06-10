package readmodel

import (
	"context"
	"testing"
)

type exportSecurityRepo struct {
	data     ExportQueryData
	err      error
	lastPlan TenantQueryAccessPlan
}

func (r *exportSecurityRepo) QueryExport(
	ctx context.Context,
	descriptor ProjectionRepositoryDescriptor,
	accessPlan TenantQueryAccessPlan,
	req ExportQueryRequest,
) (ExportQueryData, error) {
	r.lastPlan = accessPlan
	return r.data, r.err
}

func newExportSecurityStore(t *testing.T, tenantColumn string) *ReportingStore {
	t.Helper()

	registry := NewProjectionContractRegistry()

	err := registry.Register(ProjectionSchema{
		Name:              "sales_reports",
		TableName:         "rm_sales_reports",
		TenantColumn:      tenantColumn,
		PrimaryKeyColumns: []string{"tenant_id", "report_key"},
		VersionColumn:     "projection_version",
		UpdatedAtColumn:   "updated_at",
		SupportsRebuild:   true,
		Description:       "export security projection",
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

func TestExportQueryService_Query_UsesTenantGuardAndQualityGate(t *testing.T) {
	repo := &exportSecurityRepo{
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

	store := newExportSecurityStore(t, "tenant_id")

	svc, err := NewExportQueryService(store, repo)
	if err != nil {
		t.Fatalf("unexpected service error: %v", err)
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
		t.Fatalf("unexpected query error: %v", err)
	}

	if result.SourceTable != "readmodel.rm_sales_reports" {
		t.Fatalf("expected readmodel.rm_sales_reports, got %s", result.SourceTable)
	}
	if result.RowCount != 1 {
		t.Fatalf("expected 1 row, got %d", result.RowCount)
	}
	if repo.lastPlan.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", repo.lastPlan.TenantID)
	}
	if repo.lastPlan.WhereClause != "tenant_id = ?" {
		t.Fatalf("expected tenant_id = ?, got %s", repo.lastPlan.WhereClause)
	}
}

func TestExportProjectionSchema_RejectsEmptyTenantColumn(t *testing.T) {
	registry := NewProjectionContractRegistry()

	err := registry.Register(ProjectionSchema{
		Name:              "sales_reports",
		TableName:         "rm_sales_reports",
		TenantColumn:      "",
		PrimaryKeyColumns: []string{"tenant_id", "report_key"},
		VersionColumn:     "projection_version",
		UpdatedAtColumn:   "updated_at",
		SupportsRebuild:   true,
		Description:       "export security projection",
	})
	if err == nil {
		t.Fatal("expected empty tenant column error")
	}

	if err != ErrEmptyTenantColumn {
		t.Fatalf("expected ErrEmptyTenantColumn, got %v", err)
	}
}
