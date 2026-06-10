package readmodel

import "testing"

func TestNewReportingTenantGuard(t *testing.T) {
	store, err := NewReportingStore(sampleReportingConfig(), DefaultProjectionContracts())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	guard, err := NewReportingTenantGuard(store)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if guard == nil {
		t.Fatal("expected tenant guard")
	}
}

func TestReportingTenantGuard_GuardDashboardRequest(t *testing.T) {
	store, err := NewReportingStore(sampleReportingConfig(), DefaultProjectionContracts())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	guard, err := NewReportingTenantGuard(store)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	plan, err := guard.GuardDashboardRequest(DashboardQueryRequest{
		TenantID:   "tenant_42",
		Projection: "dashboard_kpi",
		QueryName:  "summary_cards",
		BranchID:   "branch_1",
		PeriodKey:  "2026_04",
		Limit:      10,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !plan.EnforceTenantFilter {
		t.Fatal("expected tenant filter enforcement")
	}
	if plan.TenantColumn != "tenant_id" {
		t.Fatalf("expected tenant_id, got %s", plan.TenantColumn)
	}
	if plan.SourceTable != "readmodel.rm_dashboard_kpi" {
		t.Fatalf("expected readmodel.rm_dashboard_kpi, got %s", plan.SourceTable)
	}
}

func TestReportingTenantGuard_GuardExportRequest(t *testing.T) {
	store, err := NewReportingStore(sampleReportingConfig(), DefaultProjectionContracts())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	guard, err := NewReportingTenantGuard(store)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	plan, err := guard.GuardExportRequest(ExportQueryRequest{
		TenantID:   "tenant_42",
		Projection: "sales_reports",
		QueryName:  "monthly_export",
		Format:     ExportFormatExcel,
		BatchSize:  100,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !plan.EnforceTenantFilter {
		t.Fatal("expected tenant filter enforcement")
	}
	if plan.SourceTable != "readmodel.rm_sales_reports" {
		t.Fatalf("expected readmodel.rm_sales_reports, got %s", plan.SourceTable)
	}
}

func TestReportingQualityGate_ValidateDashboardResult(t *testing.T) {
	gate := NewReportingQualityGate()

	req := DashboardQueryRequest{
		TenantID:   "tenant_42",
		Projection: "dashboard_kpi",
		QueryName:  "summary_cards",
		Limit:      10,
	}

	plan := TenantSafeQueryPlan{
		TenantID:            "tenant_42",
		Projection:          "dashboard_kpi",
		QueryName:           "summary_cards",
		SourceTable:         "readmodel.rm_dashboard_kpi",
		TenantColumn:        "tenant_id",
		EnforceTenantFilter: true,
	}

	result := DashboardQueryResult{
		TenantID:     "tenant_42",
		Projection:   "dashboard_kpi",
		QueryName:    "summary_cards",
		SourceTable:  "readmodel.rm_dashboard_kpi",
		Records: []DashboardCard{
			{MetricKey: "total_sales", Label: "Toplam", Value: 100, SortOrder: 1},
			{MetricKey: "order_count", Label: "Adet", Value: 20, SortOrder: 2},
		},
		RecordsCount: 2,
	}

	if err := gate.ValidateDashboardResult(req, result, plan); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestReportingQualityGate_ValidateExportResult(t *testing.T) {
	gate := NewReportingQualityGate()

	req := ExportQueryRequest{
		TenantID:   "tenant_42",
		Projection: "sales_reports",
		QueryName:  "monthly_export",
		Format:     ExportFormatExcel,
		BatchSize:  100,
	}

	plan := TenantSafeQueryPlan{
		TenantID:            "tenant_42",
		Projection:          "sales_reports",
		QueryName:           "monthly_export",
		SourceTable:         "readmodel.rm_sales_reports",
		TenantColumn:        "tenant_id",
		EnforceTenantFilter: true,
	}

	result := ExportQueryResult{
		TenantID:    "tenant_42",
		Projection:  "sales_reports",
		QueryName:   "monthly_export",
		Format:      ExportFormatExcel,
		SourceTable: "readmodel.rm_sales_reports",
		Rows: []ExportRecord{
			{RecordKey: "row_1", Columns: map[string]string{"sale_id": "sale_1"}},
			{RecordKey: "row_2", Columns: map[string]string{"sale_id": "sale_2"}},
		},
		RowCount:   2,
		NextCursor: "page_2",
	}

	if err := gate.ValidateExportResult(req, result, plan); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestReportingQualityGate_TenantMismatch(t *testing.T) {
	gate := NewReportingQualityGate()

	req := DashboardQueryRequest{
		TenantID:   "tenant_42",
		Projection: "dashboard_kpi",
		QueryName:  "summary_cards",
		Limit:      10,
	}

	plan := TenantSafeQueryPlan{
		TenantID:            "tenant_42",
		Projection:          "dashboard_kpi",
		QueryName:           "summary_cards",
		SourceTable:         "readmodel.rm_dashboard_kpi",
		TenantColumn:        "tenant_id",
		EnforceTenantFilter: true,
	}

	result := DashboardQueryResult{
		TenantID:     "tenant_99",
		Projection:   "dashboard_kpi",
		QueryName:    "summary_cards",
		SourceTable:  "readmodel.rm_dashboard_kpi",
		Records:      []DashboardCard{{MetricKey: "total_sales", Label: "Toplam", Value: 100, SortOrder: 1}},
		RecordsCount: 1,
	}

	err := gate.ValidateDashboardResult(req, result, plan)
	if err == nil {
		t.Fatal("expected tenant mismatch error")
	}
	if err != ErrTenantMismatch {
		t.Fatalf("expected ErrTenantMismatch, got %v", err)
	}
}

func TestReportingQualityGate_ValidateRebuildPlan(t *testing.T) {
	gate := NewReportingQualityGate()

	err := gate.ValidateRebuildPlan(ProjectionRebuildPlan{
		TenantID:             "tenant_42",
		Projection:           "sales_reports",
		TableName:            "rm_sales_reports",
		FullTableName:        "readmodel.rm_sales_reports",
		Mode:                 RebuildModeTruncateReplay,
		ReplayFromEventID:    "",
		TruncateBeforeReplay: true,
		RequiresReplay:       true,
		SupportsRebuild:      true,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestReportingQualityGate_ValidateRebuildPlan_Invalid(t *testing.T) {
	gate := NewReportingQualityGate()

	err := gate.ValidateRebuildPlan(ProjectionRebuildPlan{
		TenantID:             "tenant_42",
		Projection:           "",
		TableName:            "",
		FullTableName:        "",
		Mode:                 RebuildModeTruncateReplay,
		RequiresReplay:       false,
		SupportsRebuild:      false,
	})
	if err == nil {
		t.Fatal("expected rebuild plan invalid error")
	}
}
