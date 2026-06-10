package readmodel

import "testing"

func TestProjectionContractRegistry_RegisterAndGet(t *testing.T) {
	registry := NewProjectionContractRegistry()

	schema := ProjectionSchema{
		Name:              "sales_summary",
		TableName:         "rm_sales_summary",
		TenantColumn:      "tenant_id",
		PrimaryKeyColumns: []string{"tenant_id", "sale_id"},
		VersionColumn:     "projection_version",
		UpdatedAtColumn:   "updated_at",
		SupportsRebuild:   true,
		Description:       "test schema",
	}

	if err := registry.Register(schema); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	got, ok := registry.Get("sales_summary")
	if !ok {
		t.Fatal("expected registered schema")
	}
	if got.TableName != "rm_sales_summary" {
		t.Fatalf("expected rm_sales_summary, got %s", got.TableName)
	}
	if got.SupportsRebuild != true {
		t.Fatal("expected rebuild support")
	}
}

func TestProjectionContractRegistry_Duplicate(t *testing.T) {
	registry := NewProjectionContractRegistry()

	schema := ProjectionSchema{
		Name:              "sales_summary",
		TableName:         "rm_sales_summary",
		TenantColumn:      "tenant_id",
		PrimaryKeyColumns: []string{"tenant_id", "sale_id"},
		VersionColumn:     "projection_version",
		UpdatedAtColumn:   "updated_at",
		SupportsRebuild:   true,
		Description:       "test schema",
	}

	if err := registry.Register(schema); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err := registry.Register(schema)
	if err == nil {
		t.Fatal("expected duplicate schema error")
	}
	if err != ErrDuplicateProjectionSchema {
		t.Fatalf("expected ErrDuplicateProjectionSchema, got %v", err)
	}
}

func TestDefaultProjectionContracts(t *testing.T) {
	registry := DefaultProjectionContracts()

	items := registry.List()
	if len(items) != 3 {
		t.Fatalf("expected 3 projection contracts, got %d", len(items))
	}

	sales, ok := registry.Get("sales_summary")
	if !ok {
		t.Fatal("expected sales_summary schema")
	}
	if sales.TenantColumn != "tenant_id" {
		t.Fatalf("expected tenant_id, got %s", sales.TenantColumn)
	}

	dashboard, ok := registry.Get("dashboard_kpi")
	if !ok {
		t.Fatal("expected dashboard_kpi schema")
	}
	if dashboard.VersionColumn != "projection_version" {
		t.Fatalf("expected projection_version, got %s", dashboard.VersionColumn)
	}

	reporting, ok := registry.Get("sales_reports")
	if !ok {
		t.Fatal("expected sales_reports schema")
	}
	if reporting.UpdatedAtColumn != "updated_at" {
		t.Fatalf("expected updated_at, got %s", reporting.UpdatedAtColumn)
	}
}

func TestProjectionSchema_InvalidDuplicatePrimaryKey(t *testing.T) {
	schema := ProjectionSchema{
		Name:              "sales_summary",
		TableName:         "rm_sales_summary",
		TenantColumn:      "tenant_id",
		PrimaryKeyColumns: []string{"tenant_id", "tenant_id"},
		VersionColumn:     "projection_version",
		UpdatedAtColumn:   "updated_at",
		SupportsRebuild:   true,
		Description:       "bad schema",
	}

	err := schema.Validate()
	if err == nil {
		t.Fatal("expected duplicate primary key error")
	}
	if err != ErrDuplicatePrimaryKeyColumn {
		t.Fatalf("expected ErrDuplicatePrimaryKeyColumn, got %v", err)
	}
}

func TestProjectionSchema_InvalidName(t *testing.T) {
	schema := ProjectionSchema{
		Name:              "sales summary",
		TableName:         "rm_sales_summary",
		TenantColumn:      "tenant_id",
		PrimaryKeyColumns: []string{"tenant_id", "sale_id"},
		VersionColumn:     "projection_version",
		UpdatedAtColumn:   "updated_at",
		SupportsRebuild:   true,
		Description:       "bad schema",
	}

	err := schema.Validate()
	if err == nil {
		t.Fatal("expected invalid name error")
	}
}
