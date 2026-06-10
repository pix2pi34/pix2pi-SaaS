package readmodel

import "testing"

func TestProjectionRepositoryDescriptor_TenantQueryTarget_Success(t *testing.T) {
	desc := ProjectionRepositoryDescriptor{
		Name:          "dashboard_kpi",
		TableName:     "rm_dashboard_kpi",
		FullTableName: "readmodel.rm_dashboard_kpi",
		TenantColumn:  "tenant_id",
	}

	target, err := desc.TenantQueryTarget()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if target.ProjectionName != "dashboard_kpi" {
		t.Fatalf("expected dashboard_kpi, got %s", target.ProjectionName)
	}
	if target.FullTableName != "readmodel.rm_dashboard_kpi" {
		t.Fatalf("expected readmodel.rm_dashboard_kpi, got %s", target.FullTableName)
	}
	if target.TenantColumn != "tenant_id" {
		t.Fatalf("expected tenant_id, got %s", target.TenantColumn)
	}
}

func TestProjectionRepositoryDescriptor_TenantAccessPlan_Success(t *testing.T) {
	desc := ProjectionRepositoryDescriptor{
		Name:          "sales_reports",
		TableName:     "rm_sales_reports",
		FullTableName: "readmodel.rm_sales_reports",
		TenantColumn:  "tenant_id",
	}

	plan, err := desc.TenantAccessPlan("tenant_42")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if plan.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", plan.TenantID)
	}
	if plan.WhereClause != "tenant_id = ?" {
		t.Fatalf("expected tenant_id = ?, got %s", plan.WhereClause)
	}
}

func TestProjectionRepositoryDescriptor_TenantAccessPlan_EmptyTenant(t *testing.T) {
	desc := ProjectionRepositoryDescriptor{
		Name:          "sales_reports",
		TableName:     "rm_sales_reports",
		FullTableName: "readmodel.rm_sales_reports",
		TenantColumn:  "tenant_id",
	}

	_, err := desc.TenantAccessPlan("")
	if err == nil {
		t.Fatal("expected tenant error")
	}
}
