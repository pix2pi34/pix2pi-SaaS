package readmodel

import "testing"

func newSubscriberAccessDescriptor() ProjectionRepositoryDescriptor {
	return ProjectionRepositoryDescriptor{
		Name:          "ledger_projection",
		TableName:     "rm_ledger_projection",
		FullTableName: "readmodel.rm_ledger_projection",
		TenantColumn:  "tenant_id",
	}
}

func newSubscriberAccessPlan() TenantQueryAccessPlan {
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

func TestBuildSubscriberAccessSpec_Success(t *testing.T) {
	desc := newSubscriberAccessDescriptor()
	plan := newSubscriberAccessPlan()

	spec, err := BuildSubscriberAccessSpec(
		"tenant_42",
		"ledger_projection_subscriber",
		desc,
		plan,
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if spec.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", spec.TenantID)
	}
	if spec.SubscriberName != "ledger_projection_subscriber" {
		t.Fatalf("expected ledger_projection_subscriber, got %s", spec.SubscriberName)
	}
}

func TestBuildSubscriberAccessSpec_TenantMismatch(t *testing.T) {
	desc := newSubscriberAccessDescriptor()
	plan := newSubscriberAccessPlan()

	_, err := BuildSubscriberAccessSpec(
		"tenant_99",
		"ledger_projection_subscriber",
		desc,
		plan,
	)
	if err == nil {
		t.Fatal("expected tenant mismatch error")
	}
	if err != ErrSubscriberAccessTenantMismatch {
		t.Fatalf("expected ErrSubscriberAccessTenantMismatch, got %v", err)
	}
}

func TestBuildSubscriberAccessSpec_ProjectionMismatch(t *testing.T) {
	desc := newSubscriberAccessDescriptor()
	plan := newSubscriberAccessPlan()
	plan.Target.ProjectionName = "other_projection"

	_, err := BuildSubscriberAccessSpec(
		"tenant_42",
		"ledger_projection_subscriber",
		desc,
		plan,
	)
	if err == nil {
		t.Fatal("expected projection mismatch error")
	}
	if err != ErrSubscriberAccessProjectionMismatch {
		t.Fatalf("expected ErrSubscriberAccessProjectionMismatch, got %v", err)
	}
}

func TestBuildSubscriberAccessSpec_SourceMismatch(t *testing.T) {
	desc := newSubscriberAccessDescriptor()
	plan := newSubscriberAccessPlan()
	plan.Target.FullTableName = "readmodel.rm_other_projection"

	_, err := BuildSubscriberAccessSpec(
		"tenant_42",
		"ledger_projection_subscriber",
		desc,
		plan,
	)
	if err == nil {
		t.Fatal("expected source mismatch error")
	}
	if err != ErrSubscriberAccessSourceMismatch {
		t.Fatalf("expected ErrSubscriberAccessSourceMismatch, got %v", err)
	}
}

func TestBuildSubscriberAccessSpec_ColumnMismatch(t *testing.T) {
	desc := newSubscriberAccessDescriptor()
	plan := newSubscriberAccessPlan()
	plan.Target.TenantColumn = "tenant_uuid"

	_, err := BuildSubscriberAccessSpec(
		"tenant_42",
		"ledger_projection_subscriber",
		desc,
		plan,
	)
	if err == nil {
		t.Fatal("expected column mismatch error")
	}
	if err != ErrSubscriberAccessColumnMismatch {
		t.Fatalf("expected ErrSubscriberAccessColumnMismatch, got %v", err)
	}
}

func TestBuildSubscriberAccessSpec_EmptySubscriberName(t *testing.T) {
	desc := newSubscriberAccessDescriptor()
	plan := newSubscriberAccessPlan()

	_, err := BuildSubscriberAccessSpec(
		"tenant_42",
		"",
		desc,
		plan,
	)
	if err == nil {
		t.Fatal("expected empty subscriber name error")
	}
	if err != ErrSubscriberAccessEmptyName {
		t.Fatalf("expected ErrSubscriberAccessEmptyName, got %v", err)
	}
}
