package readcache

import (
	"testing"
	"time"
)

func TestReportingProfileRegistry_RegisterAndGet(t *testing.T) {
	registry := NewReportingProfileRegistry()

	profile := ReportingProfile{
		Projection:         "dashboard_kpi",
		QueryName:          "summary_cards",
		Surface:            ReportingSurfaceDashboard,
		Decision:           CacheDecisionAllow,
		TTLClass:           TTLClassShort,
		InvalidationMode:   InvalidationModeEvent,
		RefreshModel:       RefreshModelEvent,
		SupportsWarmup:     true,
		SupportsExportSeed: false,
		StaleTolerance:     30 * time.Second,
		Reason:             "dashboard cache profili",
	}

	if err := registry.Register(profile); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	got, ok := registry.Get("dashboard_kpi", "summary_cards")
	if !ok {
		t.Fatal("expected registered profile")
	}
	if got.Surface != ReportingSurfaceDashboard {
		t.Fatalf("expected dashboard surface, got %s", got.Surface)
	}
	if got.Decision != CacheDecisionAllow {
		t.Fatalf("expected allow, got %s", got.Decision)
	}
}

func TestReportingProfileRegistry_Duplicate(t *testing.T) {
	registry := NewReportingProfileRegistry()

	profile := ReportingProfile{
		Projection:         "dashboard_kpi",
		QueryName:          "summary_cards",
		Surface:            ReportingSurfaceDashboard,
		Decision:           CacheDecisionAllow,
		TTLClass:           TTLClassShort,
		InvalidationMode:   InvalidationModeEvent,
		RefreshModel:       RefreshModelEvent,
		SupportsWarmup:     true,
		SupportsExportSeed: false,
		StaleTolerance:     30 * time.Second,
		Reason:             "dashboard cache profili",
	}

	if err := registry.Register(profile); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err := registry.Register(profile)
	if err == nil {
		t.Fatal("expected duplicate error")
	}
	if err != ErrDuplicateReportingProfile {
		t.Fatalf("expected ErrDuplicateReportingProfile, got %v", err)
	}
}

func TestDefaultReportingProfiles(t *testing.T) {
	registry := DefaultReportingProfiles()

	dashboard, ok := registry.Get("dashboard_kpi", "summary_cards")
	if !ok {
		t.Fatal("expected dashboard_kpi/summary_cards")
	}
	if dashboard.Surface != ReportingSurfaceDashboard {
		t.Fatalf("expected dashboard surface, got %s", dashboard.Surface)
	}
	if dashboard.SupportsWarmup != true {
		t.Fatal("expected dashboard profile to support warmup")
	}

	reporting, ok := registry.Get("sales_reports", "monthly_summary")
	if !ok {
		t.Fatal("expected sales_reports/monthly_summary")
	}
	if reporting.Surface != ReportingSurfaceReport {
		t.Fatalf("expected report surface, got %s", reporting.Surface)
	}
	if reporting.SupportsExportSeed != true {
		t.Fatal("expected reporting profile to support export seed")
	}

	exporting, ok := registry.Get("export_sales", "prepare_excel_monthly")
	if !ok {
		t.Fatal("expected export_sales/prepare_excel_monthly")
	}
	if exporting.Surface != ReportingSurfaceExport {
		t.Fatalf("expected export surface, got %s", exporting.Surface)
	}
	if exporting.RefreshModel != RefreshModelManual {
		t.Fatalf("expected manual refresh model, got %s", exporting.RefreshModel)
	}
}

func TestReportingProfileRegistry_ListBySurface(t *testing.T) {
	registry := DefaultReportingProfiles()

	dashboards := registry.ListBySurface(ReportingSurfaceDashboard)
	if len(dashboards) != 2 {
		t.Fatalf("expected 2 dashboard profiles, got %d", len(dashboards))
	}

	reports := registry.ListBySurface(ReportingSurfaceReport)
	if len(reports) != 1 {
		t.Fatalf("expected 1 report profile, got %d", len(reports))
	}

	exports := registry.ListBySurface(ReportingSurfaceExport)
	if len(exports) != 1 {
		t.Fatalf("expected 1 export profile, got %d", len(exports))
	}
}

func TestBuildReportingQuerySpec(t *testing.T) {
	profile := ReportingProfile{
		Projection:         "sales_reports",
		QueryName:          "monthly_summary",
		Surface:            ReportingSurfaceReport,
		Decision:           CacheDecisionAllow,
		TTLClass:           TTLClassMedium,
		InvalidationMode:   InvalidationModeEvent,
		RefreshModel:       RefreshModelDelayed,
		SupportsWarmup:     false,
		SupportsExportSeed: true,
		StaleTolerance:     2 * time.Minute,
		Reason:             "report cache profili",
	}

	spec, err := BuildReportingQuerySpec(
		profile,
		"tenant_42",
		1,
		50,
		"created_desc",
		map[string]any{"month": "2026-04"},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if spec.Projection != "sales_reports" {
		t.Fatalf("expected sales_reports, got %s", spec.Projection)
	}
	if spec.TTLClass != TTLClassMedium {
		t.Fatalf("expected medium ttl, got %s", spec.TTLClass)
	}
}

func TestBuildReportingQuerySpec_Deny(t *testing.T) {
	profile := ReportingProfile{
		Projection:         "ledger_export",
		QueryName:          "exact_financial_dump",
		Surface:            ReportingSurfaceExport,
		Decision:           CacheDecisionDeny,
		TTLClass:           "",
		InvalidationMode:   InvalidationModeNone,
		RefreshModel:       RefreshModelManual,
		SupportsWarmup:     false,
		SupportsExportSeed: false,
		StaleTolerance:     0,
		Reason:             "kritik kesin sonuc exportu cache disi",
	}

	_, err := BuildReportingQuerySpec(
		profile,
		"tenant_42",
		1,
		50,
		"created_desc",
		map[string]any{"month": "2026-04"},
	)
	if err == nil {
		t.Fatal("expected deny error")
	}
}
