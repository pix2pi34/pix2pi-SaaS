package readcache

import (
	"context"
	"errors"
	"testing"
	"time"
)

type reportingStore struct {
	items          map[string]fakeEntry
	deletePatterns []string
	getErr         error
	setErr         error
	deleteErr      error
	deleteMatchErr error
}

func newReportingStore() *reportingStore {
	return &reportingStore{
		items:          make(map[string]fakeEntry),
		deletePatterns: make([]string, 0),
	}
}

func (f *reportingStore) Get(_ context.Context, key string, dest any) (bool, error) {
	if f.getErr != nil {
		return false, f.getErr
	}

	entry, ok := f.items[key]
	if !ok {
		return false, nil
	}

	switch d := dest.(type) {
	case *sampleProjection:
		v, ok := entry.value.(sampleProjection)
		if !ok {
			return false, errors.New("unexpected sampleProjection type")
		}
		*d = v
		return true, nil
	default:
		return false, errors.New("unsupported destination type")
	}
}

func (f *reportingStore) Set(_ context.Context, key string, value any, ttl time.Duration) error {
	if f.setErr != nil {
		return f.setErr
	}
	f.items[key] = fakeEntry{
		value: value,
		ttl:   ttl,
	}
	return nil
}

func (f *reportingStore) Delete(_ context.Context, key string) error {
	if f.deleteErr != nil {
		return f.deleteErr
	}
	delete(f.items, key)
	return nil
}

func (f *reportingStore) DeletePattern(_ context.Context, pattern string) error {
	if f.deleteMatchErr != nil {
		return f.deleteMatchErr
	}
	f.deletePatterns = append(f.deletePatterns, pattern)
	return nil
}

func TestNewReportingBridge(t *testing.T) {
	store := newReportingStore()

	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	bridge, err := NewReportingBridge(DefaultReportingProfiles(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if bridge == nil {
		t.Fatal("expected reporting bridge")
	}
}

func TestExecuteReportingQuery_Dashboard_FirstMissThenHit(t *testing.T) {
	store := newReportingStore()

	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	bridge, err := NewReportingBridge(DefaultReportingProfiles(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	loaderCount := 0

	first, err := ExecuteReportingQuery(
		context.Background(),
		bridge,
		"tenant_42",
		"dashboard_kpi",
		"summary_cards",
		1,
		20,
		"created_desc",
		map[string]any{"branch": "istanbul"},
		func(_ context.Context) (sampleProjection, error) {
			loaderCount++
			return sampleProjection{
				ID:    "dash_1",
				Count: 7,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !first.CacheUsed {
		t.Fatal("expected dashboard cache used")
	}
	if first.CacheHit {
		t.Fatal("expected first dashboard call miss")
	}
	if first.Surface != ReportingSurfaceDashboard {
		t.Fatalf("expected dashboard surface, got %s", first.Surface)
	}
	if first.SupportsWarmup != true {
		t.Fatal("expected dashboard profile to support warmup")
	}

	second, err := ExecuteReportingQuery(
		context.Background(),
		bridge,
		"tenant_42",
		"dashboard_kpi",
		"summary_cards",
		1,
		20,
		"created_desc",
		map[string]any{"branch": "istanbul"},
		func(_ context.Context) (sampleProjection, error) {
			loaderCount++
			return sampleProjection{
				ID:    "dash_2",
				Count: 99,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !second.CacheHit {
		t.Fatal("expected second dashboard call hit")
	}
	if second.Data.Count != 7 {
		t.Fatalf("expected cached count 7, got %d", second.Data.Count)
	}
	if loaderCount != 1 {
		t.Fatalf("expected loader count 1, got %d", loaderCount)
	}
}

func TestExecuteReportingQuery_Report_UsesCache(t *testing.T) {
	store := newReportingStore()

	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	bridge, err := NewReportingBridge(DefaultReportingProfiles(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	first, err := ExecuteReportingQuery(
		context.Background(),
		bridge,
		"tenant_42",
		"sales_reports",
		"monthly_summary",
		1,
		50,
		"created_desc",
		map[string]any{"month": "2026-04"},
		func(_ context.Context) (sampleProjection, error) {
			return sampleProjection{
				ID:    "rep_1",
				Count: 14,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if first.Surface != ReportingSurfaceReport {
		t.Fatalf("expected report surface, got %s", first.Surface)
	}
	if first.SupportsExportSeed != true {
		t.Fatal("expected report profile to support export seed")
	}

	second, err := ExecuteReportingQuery(
		context.Background(),
		bridge,
		"tenant_42",
		"sales_reports",
		"monthly_summary",
		1,
		50,
		"created_desc",
		map[string]any{"month": "2026-04"},
		func(_ context.Context) (sampleProjection, error) {
			return sampleProjection{
				ID:    "rep_2",
				Count: 88,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !second.CacheHit {
		t.Fatal("expected report cache hit")
	}
	if second.Data.Count != 14 {
		t.Fatalf("expected cached count 14, got %d", second.Data.Count)
	}
}

func TestExecuteReportingQuery_Export_CautionUsesCache(t *testing.T) {
	store := newReportingStore()

	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	bridge, err := NewReportingBridge(DefaultReportingProfiles(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	loaderCount := 0

	first, err := ExecuteReportingQuery(
		context.Background(),
		bridge,
		"tenant_42",
		"export_sales",
		"prepare_excel_monthly",
		1,
		10,
		"created_desc",
		map[string]any{"month": "2026-04"},
		func(_ context.Context) (sampleProjection, error) {
			loaderCount++
			return sampleProjection{
				ID:    "exp_1",
				Count: 3,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if first.Decision != CacheDecisionCaution {
		t.Fatalf("expected caution, got %s", first.Decision)
	}
	if first.Surface != ReportingSurfaceExport {
		t.Fatalf("expected export surface, got %s", first.Surface)
	}
	if first.RefreshModel != RefreshModelManual {
		t.Fatalf("expected manual refresh, got %s", first.RefreshModel)
	}

	second, err := ExecuteReportingQuery(
		context.Background(),
		bridge,
		"tenant_42",
		"export_sales",
		"prepare_excel_monthly",
		1,
		10,
		"created_desc",
		map[string]any{"month": "2026-04"},
		func(_ context.Context) (sampleProjection, error) {
			loaderCount++
			return sampleProjection{
				ID:    "exp_2",
				Count: 9,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !second.CacheHit {
		t.Fatal("expected export cache hit")
	}
	if loaderCount != 1 {
		t.Fatalf("expected loader count 1, got %d", loaderCount)
	}
}

func TestExecuteReportingQuery_Deny_BypassesCache(t *testing.T) {
	registry := NewReportingProfileRegistry()
	registry.MustRegister(ReportingProfile{
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
		Reason:             "kritik export cache disi",
	})

	store := newReportingStore()

	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	bridge, err := NewReportingBridge(registry, cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	loaderCount := 0

	first, err := ExecuteReportingQuery(
		context.Background(),
		bridge,
		"tenant_42",
		"ledger_export",
		"exact_financial_dump",
		1,
		10,
		"created_desc",
		map[string]any{"month": "2026-04"},
		func(_ context.Context) (sampleProjection, error) {
			loaderCount++
			return sampleProjection{
				ID:    "led_1",
				Count: 1,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	second, err := ExecuteReportingQuery(
		context.Background(),
		bridge,
		"tenant_42",
		"ledger_export",
		"exact_financial_dump",
		1,
		10,
		"created_desc",
		map[string]any{"month": "2026-04"},
		func(_ context.Context) (sampleProjection, error) {
			loaderCount++
			return sampleProjection{
				ID:    "led_2",
				Count: 2,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if first.CacheUsed || second.CacheUsed {
		t.Fatal("expected deny reporting query to bypass cache")
	}
	if loaderCount != 2 {
		t.Fatalf("expected loader count 2, got %d", loaderCount)
	}
	if second.Data.Count != 2 {
		t.Fatalf("expected latest loader result 2, got %d", second.Data.Count)
	}
}

func TestReportingBridgeInvalidateReportingProjection(t *testing.T) {
	store := newReportingStore()

	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	bridge, err := NewReportingBridge(DefaultReportingProfiles(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err = bridge.InvalidateReportingProjection(context.Background(), "tenant_42", "dashboard_kpi", "summary_cards")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(store.deletePatterns) != 1 {
		t.Fatalf("expected 1 delete pattern, got %d", len(store.deletePatterns))
	}

	expected := "pix2pi:prod:reporting:tenant:tenant_42:projection:dashboard_kpi:*"
	if store.deletePatterns[0] != expected {
		t.Fatalf("expected %q, got %q", expected, store.deletePatterns[0])
	}
}

func TestReportingBridgeInvalidateReportingSurface(t *testing.T) {
	store := newReportingStore()

	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	bridge, err := NewReportingBridge(DefaultReportingProfiles(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err = bridge.InvalidateReportingSurface(context.Background(), "tenant_42", ReportingSurfaceDashboard)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(store.deletePatterns) != 2 {
		t.Fatalf("expected 2 dashboard invalidation patterns, got %d", len(store.deletePatterns))
	}

	expectedA := "pix2pi:prod:reporting:tenant:tenant_42:projection:dashboard_kpi:*"
	expectedB := "pix2pi:prod:reporting:tenant:tenant_42:projection:dashboard_sales:*"

	foundA := false
	foundB := false

	for _, item := range store.deletePatterns {
		if item == expectedA {
			foundA = true
		}
		if item == expectedB {
			foundB = true
		}
	}

	if !foundA || !foundB {
		t.Fatalf("expected both dashboard invalidation patterns, got %+v", store.deletePatterns)
	}
}
