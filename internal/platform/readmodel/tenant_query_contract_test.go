package readmodel

import "testing"

func TestTenantQueryTarget_Validate_Success(t *testing.T) {
	target := TenantQueryTarget{
		ProjectionName: "sales_summary",
		TableName:      "sales_summary",
		FullTableName:  "readmodel.sales_summary",
		TenantColumn:   "tenant_id",
	}

	if err := target.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestTenantQueryTarget_Validate_EmptyProjection(t *testing.T) {
	target := TenantQueryTarget{
		ProjectionName: "",
		TableName:      "sales_summary",
		FullTableName:  "readmodel.sales_summary",
		TenantColumn:   "tenant_id",
	}

	if err := target.Validate(); err == nil {
		t.Fatal("expected projection error")
	}
}

func TestBuildTenantQueryAccessPlan_Success(t *testing.T) {
	target := TenantQueryTarget{
		ProjectionName: "sales_summary",
		TableName:      "sales_summary",
		FullTableName:  "readmodel.sales_summary",
		TenantColumn:   "tenant_id",
	}

	plan, err := BuildTenantQueryAccessPlan("tenant_42", target)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if plan.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", plan.TenantID)
	}

	if plan.WhereClause != "tenant_id = ?" {
		t.Fatalf("expected tenant_id = ?, got %s", plan.WhereClause)
	}

	if len(plan.Args) != 1 {
		t.Fatalf("expected 1 arg, got %d", len(plan.Args))
	}

	arg0, ok := plan.Args[0].(string)
	if !ok {
		t.Fatalf("expected string arg, got %T", plan.Args[0])
	}

	if arg0 != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", arg0)
	}

	if !plan.GuardRequired {
		t.Fatal("expected guard required")
	}
}

func TestBuildTenantQueryAccessPlan_EmptyTenant(t *testing.T) {
	target := TenantQueryTarget{
		ProjectionName: "sales_summary",
		TableName:      "sales_summary",
		FullTableName:  "readmodel.sales_summary",
		TenantColumn:   "tenant_id",
	}

	_, err := BuildTenantQueryAccessPlan("", target)
	if err == nil {
		t.Fatal("expected tenant error")
	}
}

func TestTenantQueryAccessPlan_Validate_InvalidArgs(t *testing.T) {
	plan := TenantQueryAccessPlan{
		TenantID: "tenant_42",
		Target: TenantQueryTarget{
			ProjectionName: "sales_summary",
			TableName:      "sales_summary",
			FullTableName:  "readmodel.sales_summary",
			TenantColumn:   "tenant_id",
		},
		WhereClause:   "tenant_id = ?",
		Args:          []any{},
		GuardRequired: true,
	}

	if err := plan.Validate(); err == nil {
		t.Fatal("expected invalid args error")
	}
}
