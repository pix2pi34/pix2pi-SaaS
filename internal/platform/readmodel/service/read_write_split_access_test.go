package service

import (
	"testing"

	readmodel "github.com/divrigili/pix2pi-SaaS/internal/platform/readmodel"
)

func newReadSplitAccessPlan() readmodel.TenantQueryAccessPlan {
	target := readmodel.TenantQueryTarget{
		ProjectionName: "ledger_projection",
		TableName:      "rm_ledger_projection",
		FullTableName:  "readmodel.rm_ledger_projection",
		TenantColumn:   "tenant_id",
	}

	return readmodel.TenantQueryAccessPlan{
		TenantID:      "tenant_42",
		Target:        target,
		WhereClause:   "tenant_id = ?",
		Args:          []any{"tenant_42"},
		GuardRequired: true,
	}
}

func TestBuildReadSplitAccessSpec_Success(t *testing.T) {
	plan := newReadSplitAccessPlan()

	spec, err := BuildReadSplitAccessSpec("tenant_42", "120.01", plan)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if spec.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", spec.TenantID)
	}
	if spec.AccountCode != "120.01" {
		t.Fatalf("expected 120.01, got %s", spec.AccountCode)
	}
}

func TestBuildReadSplitAccessSpec_TenantMismatch(t *testing.T) {
	plan := newReadSplitAccessPlan()

	_, err := BuildReadSplitAccessSpec("tenant_99", "120.01", plan)
	if err == nil {
		t.Fatal("expected tenant mismatch error")
	}
}

func TestBuildReadSplitAccessSpec_EmptyAccountCode(t *testing.T) {
	plan := newReadSplitAccessPlan()

	_, err := BuildReadSplitAccessSpec("tenant_42", "", plan)
	if err == nil {
		t.Fatal("expected account code error")
	}
}
