package readcache

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
)

type fakeEntry struct {
	value any
	ttl   time.Duration
}

type fakeStore struct {
	items           map[string]fakeEntry
	lastDeleteKey   string
	lastDeleteMatch string
	getErr          error
	setErr          error
	deleteErr       error
	deleteMatchErr  error
}

func newFakeStore() *fakeStore {
	return &fakeStore{
		items: make(map[string]fakeEntry),
	}
}

func (f *fakeStore) Get(_ context.Context, key string, dest any) (bool, error) {
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
			return false, errors.New("unexpected type")
		}
		*d = v
		return true, nil
	default:
		return false, errors.New("unsupported destination type")
	}
}

func (f *fakeStore) Set(_ context.Context, key string, value any, ttl time.Duration) error {
	if f.setErr != nil {
		return f.setErr
	}
	f.items[key] = fakeEntry{
		value: value,
		ttl:   ttl,
	}
	return nil
}

func (f *fakeStore) Delete(_ context.Context, key string) error {
	if f.deleteErr != nil {
		return f.deleteErr
	}
	f.lastDeleteKey = key
	delete(f.items, key)
	return nil
}

func (f *fakeStore) DeletePattern(_ context.Context, pattern string) error {
	if f.deleteMatchErr != nil {
		return f.deleteMatchErr
	}
	f.lastDeleteMatch = pattern
	return nil
}

type sampleProjection struct {
	ID    string
	Count int
}

func TestNewProjectionCache(t *testing.T) {
	store := newFakeStore()

	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cache == nil {
		t.Fatal("expected cache instance")
	}
}

func TestBuildKey(t *testing.T) {
	store := newFakeStore()
	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	spec := QuerySpec{
		TenantID:   "tenant_42",
		Projection: "sales_summary",
		QueryName:  "list_monthly",
		Page:       1,
		PageSize:   20,
		Sort:       "created_desc",
		FilterData: map[string]any{
			"month": "2026-04",
			"branch": "istanbul",
		},
		TTLClass: TTLClassMedium,
	}

	key, err := cache.BuildKey(spec)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expectedParts := []string{
		"pix2pi:prod:reporting:tenant:tenant_42:projection:sales_summary:query:list_monthly:page:1:size:20:sort:created_desc:hash:",
	}
	for _, part := range expectedParts {
		if !strings.Contains(key, part) {
			t.Fatalf("expected key to contain %q, got %q", part, key)
		}
	}
}

func TestBuildProjectionPattern(t *testing.T) {
	store := newFakeStore()
	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	pattern, err := cache.BuildProjectionPattern("tenant_42", "sales_summary")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expected := "pix2pi:prod:reporting:tenant:tenant_42:projection:sales_summary:*"
	if pattern != expected {
		t.Fatalf("expected %q, got %q", expected, pattern)
	}
}

func TestGetOrLoad_MissThenSet(t *testing.T) {
	store := newFakeStore()
	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	spec := QuerySpec{
		TenantID:   "tenant_42",
		Projection: "sales_summary",
		QueryName:  "list_monthly",
		Page:       1,
		PageSize:   20,
		Sort:       "created_desc",
		FilterData: map[string]any{
			"month": "2026-04",
		},
		TTLClass: TTLClassMedium,
	}

	loaderCalled := 0
	got, hit, err := GetOrLoad(context.Background(), cache, spec, func(_ context.Context) (sampleProjection, error) {
		loaderCalled++
		return sampleProjection{
			ID:    "row_1",
			Count: 12,
		}, nil
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if hit {
		t.Fatal("expected cache miss on first load")
	}
	if loaderCalled != 1 {
		t.Fatalf("expected loader to be called once, got %d", loaderCalled)
	}
	if got.Count != 12 {
		t.Fatalf("expected count 12, got %d", got.Count)
	}

	key, err := cache.BuildKey(spec)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	entry, ok := store.items[key]
	if !ok {
		t.Fatal("expected item to be written to store")
	}
	if entry.ttl != 5*time.Minute {
		t.Fatalf("expected ttl 5m, got %v", entry.ttl)
	}
}

func TestGetOrLoad_Hit(t *testing.T) {
	store := newFakeStore()
	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	spec := QuerySpec{
		TenantID:   "tenant_42",
		Projection: "sales_summary",
		QueryName:  "list_monthly",
		Page:       1,
		PageSize:   20,
		Sort:       "created_desc",
		FilterData: map[string]any{
			"month": "2026-04",
		},
		TTLClass: TTLClassMedium,
	}

	key, err := cache.BuildKey(spec)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	store.items[key] = fakeEntry{
		value: sampleProjection{
			ID:    "row_cached",
			Count: 99,
		},
		ttl: 5 * time.Minute,
	}

	loaderCalled := 0
	got, hit, err := GetOrLoad(context.Background(), cache, spec, func(_ context.Context) (sampleProjection, error) {
		loaderCalled++
		return sampleProjection{}, nil
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !hit {
		t.Fatal("expected cache hit")
	}
	if loaderCalled != 0 {
		t.Fatalf("expected loader not to be called, got %d", loaderCalled)
	}
	if got.Count != 99 {
		t.Fatalf("expected cached count 99, got %d", got.Count)
	}
}

func TestDeleteProjection(t *testing.T) {
	store := newFakeStore()
	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err = cache.DeleteProjection(context.Background(), "tenant_42", "sales_summary")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expected := "pix2pi:prod:reporting:tenant:tenant_42:projection:sales_summary:*"
	if store.lastDeleteMatch != expected {
		t.Fatalf("expected pattern %q, got %q", expected, store.lastDeleteMatch)
	}
}

func TestBuildKey_InvalidTenant(t *testing.T) {
	store := newFakeStore()
	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	spec := QuerySpec{
		TenantID:   "tenant 42",
		Projection: "sales_summary",
		QueryName:  "list_monthly",
		Page:       1,
		PageSize:   20,
		TTLClass:   TTLClassMedium,
	}

	_, err = cache.BuildKey(spec)
	if err == nil {
		t.Fatal("expected validation error")
	}
}
