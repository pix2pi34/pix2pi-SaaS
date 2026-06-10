package readmodel

import (
	"context"
	"testing"
)

func TestExportSQLRepository_QueryExport_SourceMismatch(t *testing.T) {
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
		ProjectionName: "sales_reports",
		TableName:      "rm_sales_reports",
		FullTableName:  "readmodel.rm_other_table",
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
		t.Fatal("expected source mismatch error")
	}
	if err != ErrTenantAccessPlanSourceMismatch {
		t.Fatalf("expected ErrTenantAccessPlanSourceMismatch, got %v", err)
	}
}

func TestExportSQLRepository_QueryExport_ColumnMismatch(t *testing.T) {
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
		ProjectionName: "sales_reports",
		TableName:      "rm_sales_reports",
		FullTableName:  "readmodel.rm_sales_reports",
		TenantColumn:   "tenant_uuid",
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
		t.Fatal("expected column mismatch error")
	}
	if err != ErrTenantAccessPlanColumnMismatch {
		t.Fatalf("expected ErrTenantAccessPlanColumnMismatch, got %v", err)
	}
}

func TestExportSQLRepository_QueryExport_GuardDisabled(t *testing.T) {
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

	target, err := desc.TenantQueryTarget()
	if err != nil {
		t.Fatalf("unexpected target error: %v", err)
	}

	plan, err := BuildTenantQueryAccessPlan("tenant_42", target)
	if err != nil {
		t.Fatalf("unexpected access plan error: %v", err)
	}
	plan.GuardRequired = false

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
		t.Fatal("expected guard required error")
	}
	if err != ErrTenantAccessPlanGuardRequired {
		t.Fatalf("expected ErrTenantAccessPlanGuardRequired, got %v", err)
	}
}

func TestExportSQLRepository_QueryExport_InvalidArgs(t *testing.T) {
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
		t.Fatal("expected invalid args error")
	}
}
