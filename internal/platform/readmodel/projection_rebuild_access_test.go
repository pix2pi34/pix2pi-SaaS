package readmodel

import "testing"

func newProjectionRebuildAccessPlan() TenantQueryAccessPlan {
	target := TenantQueryTarget{
		ProjectionName: "ledger_projection",
		TableName:      "rm_ledger_projection",
		FullTableName:  "readmodel.rm_ledger_projection",
		TenantColumn:   "tenant_id",
	}

	return TenantQueryAccessPlan{
		TenantID:      "tenant_42",
		Target:        target,
		WhereClause:   "tenant_id = ?",
		Args:          []any{"tenant_42"},
		GuardRequired: true,
	}
}

func newProjectionRebuildPlan() ProjectionRebuildPlan {
	return ProjectionRebuildPlan{
		Projection:        "ledger_projection",
		TableName:         "rm_ledger_projection",
		FullTableName:     "readmodel.rm_ledger_projection",
		SupportsRebuild:   true,
		RequiresReplay:    true,
		Mode:              RebuildModeTruncateReplay,
	}
}

func TestBuildProjectionRebuildAccessSpec_Success(t *testing.T) {
	plan := newProjectionRebuildPlan()
	accessPlan := newProjectionRebuildAccessPlan()

	spec, err := BuildProjectionRebuildAccessSpec("tenant_42", plan, accessPlan)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if spec.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", spec.TenantID)
	}
	if spec.Plan.Projection != "ledger_projection" {
		t.Fatalf("expected ledger_projection, got %s", spec.Plan.Projection)
	}
}

func TestBuildProjectionRebuildAccessSpec_TenantMismatch(t *testing.T) {
	plan := newProjectionRebuildPlan()
	accessPlan := newProjectionRebuildAccessPlan()

	_, err := BuildProjectionRebuildAccessSpec("tenant_99", plan, accessPlan)
	if err == nil {
		t.Fatal("expected tenant mismatch error")
	}
	if err != ErrProjectionRebuildAccessTenantMismatch {
		t.Fatalf("expected ErrProjectionRebuildAccessTenantMismatch, got %v", err)
	}
}

func TestBuildProjectionRebuildAccessSpec_ProjectionMismatch(t *testing.T) {
	plan := newProjectionRebuildPlan()
	accessPlan := newProjectionRebuildAccessPlan()
	accessPlan.Target.ProjectionName = "other_projection"

	_, err := BuildProjectionRebuildAccessSpec("tenant_42", plan, accessPlan)
	if err == nil {
		t.Fatal("expected projection mismatch error")
	}
	if err != ErrProjectionRebuildAccessProjectionMismatch {
		t.Fatalf("expected ErrProjectionRebuildAccessProjectionMismatch, got %v", err)
	}
}

func TestBuildProjectionRebuildAccessSpec_SourceMismatch(t *testing.T) {
	plan := newProjectionRebuildPlan()
	accessPlan := newProjectionRebuildAccessPlan()
	accessPlan.Target.FullTableName = "readmodel.rm_other_projection"

	_, err := BuildProjectionRebuildAccessSpec("tenant_42", plan, accessPlan)
	if err == nil {
		t.Fatal("expected source mismatch error")
	}
	if err != ErrProjectionRebuildAccessSourceMismatch {
		t.Fatalf("expected ErrProjectionRebuildAccessSourceMismatch, got %v", err)
	}
}

func TestBuildProjectionRebuildAccessSpec_InvalidPlan(t *testing.T) {
	plan := newProjectionRebuildPlan()
	plan.RequiresReplay = false

	accessPlan := newProjectionRebuildAccessPlan()

	_, err := BuildProjectionRebuildAccessSpec("tenant_42", plan, accessPlan)
	if err == nil {
		t.Fatal("expected invalid rebuild plan error")
	}
}
