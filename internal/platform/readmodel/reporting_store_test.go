package readmodel

import "testing"

func sampleReportingConfig() ReportingDBConfig {
	return ReportingDBConfig{
		Driver:   ReportingDriverPostgres,
		Host:     "127.0.0.1",
		Port:     5433,
		User:     "pix2pi",
		Password: "secret",
		DBName:   "pix2pi_reporting",
		Schema:   "readmodel",
		SSLMode:  "disable",
	}
}

func TestReportingDBConfig_Validate(t *testing.T) {
	cfg := sampleReportingConfig()

	if err := cfg.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestReportingDBConfig_DSN(t *testing.T) {
	cfg := sampleReportingConfig()

	dsn, err := cfg.DSN()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expected := "host=127.0.0.1 port=5433 user=pix2pi password=secret dbname=pix2pi_reporting sslmode=disable search_path=readmodel"
	if dsn != expected {
		t.Fatalf("expected %q, got %q", expected, dsn)
	}
}

func TestReportingDBConfig_InvalidPort(t *testing.T) {
	cfg := sampleReportingConfig()
	cfg.Port = 0

	err := cfg.Validate()
	if err == nil {
		t.Fatal("expected invalid port error")
	}
	if err != ErrInvalidReportingDBPort {
		t.Fatalf("expected ErrInvalidReportingDBPort, got %v", err)
	}
}

func TestNewReportingStore(t *testing.T) {
	store, err := NewReportingStore(sampleReportingConfig(), DefaultProjectionContracts())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if store == nil {
		t.Fatal("expected reporting store")
	}
	if !store.Ready() {
		t.Fatal("expected store ready")
	}
}

func TestReportingStore_ResolveProjectionDescriptor(t *testing.T) {
	store, err := NewReportingStore(sampleReportingConfig(), DefaultProjectionContracts())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	desc, err := store.ResolveProjectionDescriptor("sales_summary")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if desc.Name != "sales_summary" {
		t.Fatalf("expected sales_summary, got %s", desc.Name)
	}
	if desc.TableName != "rm_sales_summary" {
		t.Fatalf("expected rm_sales_summary, got %s", desc.TableName)
	}
	if desc.FullTableName != "readmodel.rm_sales_summary" {
		t.Fatalf("expected readmodel.rm_sales_summary, got %s", desc.FullTableName)
	}
	if desc.TenantColumn != "tenant_id" {
		t.Fatalf("expected tenant_id, got %s", desc.TenantColumn)
	}
	if desc.VersionColumn != "projection_version" {
		t.Fatalf("expected projection_version, got %s", desc.VersionColumn)
	}
}

func TestReportingStore_ListProjectionDescriptors(t *testing.T) {
	store, err := NewReportingStore(sampleReportingConfig(), DefaultProjectionContracts())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	items, err := store.ListProjectionDescriptors()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(items) != 3 {
		t.Fatalf("expected 3 projection descriptors, got %d", len(items))
	}
	if items[0].Name == "" {
		t.Fatal("expected sorted descriptors")
	}
}

func TestReportingStore_UnknownProjection(t *testing.T) {
	store, err := NewReportingStore(sampleReportingConfig(), DefaultProjectionContracts())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	_, err = store.ResolveProjectionDescriptor("unknown_projection")
	if err == nil {
		t.Fatal("expected unknown projection error")
	}
}
