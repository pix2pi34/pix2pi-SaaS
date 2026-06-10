package readmodel

import (
	"context"
	"testing"
)

type fakeExportRowExecutor struct {
	data     ExportQueryData
	err      error
	lastSQL  string
	lastArgs []any
}

func (f *fakeExportRowExecutor) QueryExportRows(
	ctx context.Context,
	sql string,
	args []any,
) (ExportQueryData, error) {
	f.lastSQL = sql
	f.lastArgs = append([]any(nil), args...)
	return f.data, f.err
}

func TestNewExportSQLRepository(t *testing.T) {
	repo, err := NewExportSQLRepository(&fakeExportRowExecutor{})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if repo == nil {
		t.Fatal("expected export sql repository")
	}
}

func TestExportSQLRepository_QueryExport_Success(t *testing.T) {
	executor := &fakeExportRowExecutor{
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

	repo, err := NewExportSQLRepository(executor)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	desc := ProjectionRepositoryDescriptor{
		Name:          "sales_reports",
		TableName:     "rm_sales_reports",
		FullTableName: "readmodel.rm_sales_reports",
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

	data, err := repo.QueryExport(context.Background(), desc, plan, ExportQueryRequest{
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

	expectedSQL := "SELECT * FROM readmodel.rm_sales_reports WHERE tenant_id = ? LIMIT 100"
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

	if len(data.Rows) != 1 {
		t.Fatalf("expected 1 row, got %d", len(data.Rows))
	}
}

func TestExportSQLRepository_QueryExport_Mismatch(t *testing.T) {
	executor := &fakeExportRowExecutor{}

	repo, err := NewExportSQLRepository(executor)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	desc := ProjectionRepositoryDescriptor{
		Name:          "sales_reports",
		TableName:     "rm_sales_reports",
		FullTableName: "readmodel.rm_sales_reports",
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

	_, err = repo.QueryExport(context.Background(), desc, plan, ExportQueryRequest{
		TenantID:   "tenant_42",
		Projection: "sales_reports",
		QueryName:  "monthly_export",
		Format:     ExportFormatCSV,
		BranchID:   "branch_1",
		PeriodKey:  "2026_04",
		BatchSize:  100,
	})
	if err == nil {
		t.Fatal("expected mismatch error")
	}
	if err != ErrTenantAccessPlanProjectionMismatch {
		t.Fatalf("expected ErrTenantAccessPlanProjectionMismatch, got %v", err)
	}
}
