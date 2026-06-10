package readmodel

import "testing"

func TestTenantSafeQueryPlan_Normalize_LegacyFields(t *testing.T) {
	plan := TenantSafeQueryPlan{
		TenantID:            "tenant_42",
		Projection:          "dashboard_kpi",
		QueryName:           "branch_dashboard",
		SourceTable:         "readmodel.rm_dashboard_kpi",
		TenantColumn:        "tenant_id",
		EnforceTenantFilter: true,
	}

	normalized, err := plan.normalize()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if normalized.QueryTarget.ProjectionName != "dashboard_kpi" {
		t.Fatalf("expected dashboard_kpi, got %s", normalized.QueryTarget.ProjectionName)
	}
	if normalized.QueryTarget.TableName != "rm_dashboard_kpi" {
		t.Fatalf("expected rm_dashboard_kpi, got %s", normalized.QueryTarget.TableName)
	}
	if normalized.AccessPlan.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", normalized.AccessPlan.TenantID)
	}
	if normalized.AccessPlan.WhereClause != "tenant_id = ?" {
		t.Fatalf("expected tenant_id = ?, got %s", normalized.AccessPlan.WhereClause)
	}
}

func TestTenantSafeQueryPlan_Normalize_KeepsExplicitAccessPlan(t *testing.T) {
	plan := TenantSafeQueryPlan{
		TenantID:            "tenant_42",
		Projection:          "sales_reports",
		QueryName:           "monthly_export",
		SourceTable:         "readmodel.rm_sales_reports",
		TenantColumn:        "tenant_id",
		EnforceTenantFilter: true,
		QueryTarget: TenantQueryTarget{
			ProjectionName: "sales_reports",
			TableName:      "rm_sales_reports",
			FullTableName:  "readmodel.rm_sales_reports",
			TenantColumn:   "tenant_id",
		},
		AccessPlan: TenantQueryAccessPlan{
			TenantID:      "tenant_42",
			Target: TenantQueryTarget{
				ProjectionName: "sales_reports",
				TableName:      "rm_sales_reports",
				FullTableName:  "readmodel.rm_sales_reports",
				TenantColumn:   "tenant_id",
			},
			WhereClause:   "tenant_id = ?",
			Args:          []any{"tenant_42"},
			GuardRequired: true,
		},
	}

	normalized, err := plan.normalize()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if normalized.AccessPlan.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", normalized.AccessPlan.TenantID)
	}
	if normalized.QueryTarget.TableName != "rm_sales_reports" {
		t.Fatalf("expected rm_sales_reports, got %s", normalized.QueryTarget.TableName)
	}
}
