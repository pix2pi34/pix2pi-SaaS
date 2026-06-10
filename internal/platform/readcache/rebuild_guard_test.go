package readcache

import (
	"context"
	"errors"
	"testing"
	"time"
)

type guardCapableStore struct {
	items           map[string]fakeEntry
	lastDeleteKey   string
	lastDeleteMatch string
	getErr          error
	setErr          error
	deleteErr       error
	deleteMatchErr  error
}

func newGuardCapableStore() *guardCapableStore {
	return &guardCapableStore{
		items: make(map[string]fakeEntry),
	}
}

func (f *guardCapableStore) Get(_ context.Context, key string, dest any) (bool, error) {
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
	case *ProjectionGuardState:
		v, ok := entry.value.(ProjectionGuardState)
		if !ok {
			return false, errors.New("unexpected ProjectionGuardState type")
		}
		*d = v
		return true, nil
	default:
		return false, errors.New("unsupported destination type")
	}
}

func (f *guardCapableStore) Set(_ context.Context, key string, value any, ttl time.Duration) error {
	if f.setErr != nil {
		return f.setErr
	}
	f.items[key] = fakeEntry{
		value: value,
		ttl:   ttl,
	}
	return nil
}

func (f *guardCapableStore) Delete(_ context.Context, key string) error {
	if f.deleteErr != nil {
		return f.deleteErr
	}
	f.lastDeleteKey = key
	delete(f.items, key)
	return nil
}

func (f *guardCapableStore) DeletePattern(_ context.Context, pattern string) error {
	if f.deleteMatchErr != nil {
		return f.deleteMatchErr
	}
	f.lastDeleteMatch = pattern
	return nil
}

func TestNewProjectionRebuildGuard(t *testing.T) {
	store := newGuardCapableStore()

	guard, err := NewProjectionRebuildGuard(store, "prod", "reporting", 10*time.Minute)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if guard == nil {
		t.Fatal("expected guard")
	}
}

func TestProjectionRebuildGuard_ActivateAndIsActive(t *testing.T) {
	store := newGuardCapableStore()

	guard, err := NewProjectionRebuildGuard(store, "prod", "reporting", 10*time.Minute)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err = guard.Activate(context.Background(), "tenant_42", "sales_summary", GuardModeFreeze, 2*time.Minute, "projection rebuild")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	state, active, err := guard.IsActive(context.Background(), "tenant_42", "sales_summary")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !active {
		t.Fatal("expected guard active")
	}
	if state.Mode != GuardModeFreeze {
		t.Fatalf("expected freeze, got %s", state.Mode)
	}
}

func TestBeginAndEndProjectionRebuild(t *testing.T) {
	store := newGuardCapableStore()

	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	guard, err := NewProjectionRebuildGuard(store, "prod", "reporting", 10*time.Minute)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err = BeginProjectionRebuild(
		context.Background(),
		guard,
		cache,
		"tenant_42",
		"sales_summary",
		GuardModeFlush,
		3*time.Minute,
		"replay rebuild start",
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expectedPattern := "pix2pi:prod:reporting:tenant:tenant_42:projection:sales_summary:*"
	if store.lastDeleteMatch != expectedPattern {
		t.Fatalf("expected pattern %q, got %q", expectedPattern, store.lastDeleteMatch)
	}

	_, active, err := guard.IsActive(context.Background(), "tenant_42", "sales_summary")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !active {
		t.Fatal("expected guard active after begin")
	}

	err = EndProjectionRebuild(
		context.Background(),
		guard,
		cache,
		"tenant_42",
		"sales_summary",
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	_, active, err = guard.IsActive(context.Background(), "tenant_42", "sales_summary")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if active {
		t.Fatal("expected guard inactive after end")
	}
}

func TestExecuteQueryWithGuard_ActiveBypassesCache(t *testing.T) {
	store := newGuardCapableStore()

	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	guard, err := NewProjectionRebuildGuard(store, "prod", "reporting", 10*time.Minute)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	bridge, err := NewQueryBridge(DefaultProjectionQueryScopes(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err = BeginProjectionRebuild(
		context.Background(),
		guard,
		cache,
		"tenant_42",
		"sales_summary",
		GuardModeFreeze,
		5*time.Minute,
		"projection rebuild active",
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	loaderCount := 0

	first, err := ExecuteQueryWithGuard(
		context.Background(),
		bridge,
		guard,
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
				Count: 21,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	second, err := ExecuteQueryWithGuard(
		context.Background(),
		bridge,
		guard,
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
				Count: 33,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if first.CacheUsed {
		t.Fatal("expected cache bypass during active rebuild")
	}
	if second.CacheUsed {
		t.Fatal("expected cache bypass during active rebuild")
	}
	if !first.GuardActive || !second.GuardActive {
		t.Fatal("expected guard active flag")
	}
	if first.GuardMode != GuardModeFreeze || second.GuardMode != GuardModeFreeze {
		t.Fatal("expected freeze guard mode")
	}
	if loaderCount != 2 {
		t.Fatalf("expected loader count 2, got %d", loaderCount)
	}
	if second.Data.Count != 33 {
		t.Fatalf("expected latest loader result 33, got %d", second.Data.Count)
	}
}

func TestExecuteQueryWithGuard_NoActiveGuardFallsBackToCache(t *testing.T) {
	store := newGuardCapableStore()

	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	guard, err := NewProjectionRebuildGuard(store, "prod", "reporting", 10*time.Minute)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	bridge, err := NewQueryBridge(DefaultProjectionQueryScopes(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	loaderCount := 0

	first, err := ExecuteQueryWithGuard(
		context.Background(),
		bridge,
		guard,
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
				Count: 12,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	second, err := ExecuteQueryWithGuard(
		context.Background(),
		bridge,
		guard,
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
				Count: 77,
			}, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !first.CacheUsed || !second.CacheUsed {
		t.Fatal("expected cache usage when no active guard")
	}
	if second.CacheHit != true {
		t.Fatal("expected second call cache hit")
	}
	if first.GuardActive || second.GuardActive {
		t.Fatal("expected guard inactive")
	}
	if loaderCount != 1 {
		t.Fatalf("expected loader count 1, got %d", loaderCount)
	}
}
