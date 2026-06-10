package readcache

import (
	"context"
	"testing"
)

func TestNewQueryBridge(t *testing.T) {
	store := newFakeStore()
	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	bridge, err := NewQueryBridge(DefaultProjectionQueryScopes(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if bridge == nil {
		t.Fatal("expected bridge")
	}
}

func TestExecuteQuery_Allow_FirstMissThenHit(t *testing.T) {
	store := newFakeStore()
	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	bridge, err := NewQueryBridge(DefaultProjectionQueryScopes(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	loaderCount := 0

	first, err := ExecuteQuery(
		context.Background(),
		bridge,
		"tenant_42",
		"sales_summary",
		"list_monthly",
		1,
		20,
		"created_desc",
		map[string]any{"month": "2026-04"},
		func(_ context.Context) (sampleProjection, error) {
			loaderCount++
			return sampleProjection{
				ID:    "row_1",
				Count: 11,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if first.CacheUsed != true {
		t.Fatal("expected cache used on allow query")
	}
	if first.CacheHit {
		t.Fatal("expected first call to be miss")
	}
	if first.Decision != CacheDecisionAllow {
		t.Fatalf("expected allow, got %s", first.Decision)
	}
	if first.Data.Count != 11 {
		t.Fatalf("expected count 11, got %d", first.Data.Count)
	}

	second, err := ExecuteQuery(
		context.Background(),
		bridge,
		"tenant_42",
		"sales_summary",
		"list_monthly",
		1,
		20,
		"created_desc",
		map[string]any{"month": "2026-04"},
		func(_ context.Context) (sampleProjection, error) {
			loaderCount++
			return sampleProjection{
				ID:    "row_2",
				Count: 99,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if second.CacheUsed != true {
		t.Fatal("expected cache used on second call")
	}
	if !second.CacheHit {
		t.Fatal("expected second call to be hit")
	}
	if second.Data.Count != 11 {
		t.Fatalf("expected cached count 11, got %d", second.Data.Count)
	}
	if loaderCount != 1 {
		t.Fatalf("expected loader count 1, got %d", loaderCount)
	}
}

func TestExecuteQuery_Caution_UsesCache(t *testing.T) {
	store := newFakeStore()
	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	bridge, err := NewQueryBridge(DefaultProjectionQueryScopes(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	loaderCount := 0

	first, err := ExecuteQuery(
		context.Background(),
		bridge,
		"tenant_42",
		"stock_snapshot",
		"list_by_branch",
		1,
		20,
		"updated_desc",
		map[string]any{"branch": "istanbul"},
		func(_ context.Context) (sampleProjection, error) {
			loaderCount++
			return sampleProjection{
				ID:    "stock_1",
				Count: 5,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if first.Decision != CacheDecisionCaution {
		t.Fatalf("expected caution, got %s", first.Decision)
	}
	if !first.CacheUsed {
		t.Fatal("expected cache used")
	}
	if first.CacheHit {
		t.Fatal("expected first caution call miss")
	}

	second, err := ExecuteQuery(
		context.Background(),
		bridge,
		"tenant_42",
		"stock_snapshot",
		"list_by_branch",
		1,
		20,
		"updated_desc",
		map[string]any{"branch": "istanbul"},
		func(_ context.Context) (sampleProjection, error) {
			loaderCount++
			return sampleProjection{
				ID:    "stock_2",
				Count: 9,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !second.CacheHit {
		t.Fatal("expected second caution call hit")
	}
	if loaderCount != 1 {
		t.Fatalf("expected loader count 1, got %d", loaderCount)
	}
}

func TestExecuteQuery_Deny_BypassesCache(t *testing.T) {
	store := newFakeStore()
	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	bridge, err := NewQueryBridge(DefaultProjectionQueryScopes(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	loaderCount := 0

	first, err := ExecuteQuery(
		context.Background(),
		bridge,
		"tenant_42",
		"ledger_entries",
		"list_posted_entries",
		1,
		20,
		"created_desc",
		map[string]any{"month": "2026-04"},
		func(_ context.Context) (sampleProjection, error) {
			loaderCount++
			return sampleProjection{
				ID:    "ledger_1",
				Count: 3,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	second, err := ExecuteQuery(
		context.Background(),
		bridge,
		"tenant_42",
		"ledger_entries",
		"list_posted_entries",
		1,
		20,
		"created_desc",
		map[string]any{"month": "2026-04"},
		func(_ context.Context) (sampleProjection, error) {
			loaderCount++
			return sampleProjection{
				ID:    "ledger_2",
				Count: 7,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if first.CacheUsed {
		t.Fatal("expected deny query to bypass cache")
	}
	if second.CacheUsed {
		t.Fatal("expected deny query to bypass cache")
	}
	if loaderCount != 2 {
		t.Fatalf("expected loader count 2, got %d", loaderCount)
	}
	if second.Data.Count != 7 {
		t.Fatalf("expected latest loader result 7, got %d", second.Data.Count)
	}
}

func TestQueryBridgeInvalidateProjection(t *testing.T) {
	store := newFakeStore()
	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	bridge, err := NewQueryBridge(DefaultProjectionQueryScopes(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err = bridge.InvalidateProjection(context.Background(), "tenant_42", "sales_summary")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expected := "pix2pi:prod:reporting:tenant:tenant_42:projection:sales_summary:*"
	if store.lastDeleteMatch != expected {
		t.Fatalf("expected %q, got %q", expected, store.lastDeleteMatch)
	}
}
