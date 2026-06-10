package readcache

import (
	"context"
	"errors"
	"testing"
)

func TestNewFallbackExecutor(t *testing.T) {
	executor, err := NewFallbackExecutor(DefaultCacheLifecycleProfiles())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if executor == nil {
		t.Fatal("expected fallback executor")
	}
}

func TestExecuteWithFallback_CacheHit(t *testing.T) {
	executor, err := NewFallbackExecutor(DefaultCacheLifecycleProfiles())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	result, err := ExecuteWithFallback(
		context.Background(),
		executor,
		"report_balanced",
		func(_ context.Context) (sampleProjection, bool, error) {
			return sampleProjection{ID: "hit_1", Count: 10}, true, nil
		},
		func(_ context.Context) (sampleProjection, error) {
			return sampleProjection{}, errors.New("source should not run")
		},
		nil,
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !result.CacheUsed || !result.CacheHit {
		t.Fatal("expected cache hit")
	}
	if result.FallbackUsed {
		t.Fatal("expected no fallback")
	}
	if result.Data.Count != 10 {
		t.Fatalf("expected count 10, got %d", result.Data.Count)
	}
}

func TestExecuteWithFallback_CacheMissLoadsSource(t *testing.T) {
	executor, err := NewFallbackExecutor(DefaultCacheLifecycleProfiles())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	sourceCalls := 0

	result, err := ExecuteWithFallback(
		context.Background(),
		executor,
		"report_balanced",
		func(_ context.Context) (sampleProjection, bool, error) {
			return sampleProjection{}, false, nil
		},
		func(_ context.Context) (sampleProjection, error) {
			sourceCalls++
			return sampleProjection{ID: "src_1", Count: 22}, nil
		},
		nil,
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !result.CacheUsed {
		t.Fatal("expected cache attempt used")
	}
	if result.CacheHit {
		t.Fatal("expected cache miss")
	}
	if result.FallbackUsed {
		t.Fatal("expected no fallback on normal miss")
	}
	if sourceCalls != 1 {
		t.Fatalf("expected source called once, got %d", sourceCalls)
	}
	if result.Data.Count != 22 {
		t.Fatalf("expected count 22, got %d", result.Data.Count)
	}
}

func TestExecuteWithFallback_BypassMode(t *testing.T) {
	executor, err := NewFallbackExecutor(DefaultCacheLifecycleProfiles())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	sourceCalls := 0

	result, err := ExecuteWithFallback(
		context.Background(),
		executor,
		"report_balanced",
		func(_ context.Context) (sampleProjection, bool, error) {
			return sampleProjection{}, false, errors.New("redis down")
		},
		func(_ context.Context) (sampleProjection, error) {
			sourceCalls++
			return sampleProjection{ID: "src_2", Count: 33}, nil
		},
		nil,
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if result.CacheUsed {
		t.Fatal("expected cache not used after bypass fallback")
	}
	if !result.FallbackUsed {
		t.Fatal("expected fallback used")
	}
	if result.ServedStale {
		t.Fatal("expected not stale")
	}
	if result.FallbackMode != FallbackModeBypass {
		t.Fatalf("expected bypass, got %s", result.FallbackMode)
	}
	if sourceCalls != 1 {
		t.Fatalf("expected source called once, got %d", sourceCalls)
	}
	if result.Data.Count != 33 {
		t.Fatalf("expected count 33, got %d", result.Data.Count)
	}
}

func TestExecuteWithFallback_ServeStaleMode(t *testing.T) {
	executor, err := NewFallbackExecutor(DefaultCacheLifecycleProfiles())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	result, err := ExecuteWithFallback(
		context.Background(),
		executor,
		"dashboard_hot",
		func(_ context.Context) (sampleProjection, bool, error) {
			return sampleProjection{}, false, errors.New("redis timeout")
		},
		func(_ context.Context) (sampleProjection, error) {
			return sampleProjection{ID: "src_3", Count: 44}, nil
		},
		func(_ context.Context) (sampleProjection, bool, error) {
			return sampleProjection{ID: "stale_1", Count: 55}, true, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !result.FallbackUsed {
		t.Fatal("expected fallback used")
	}
	if !result.ServedStale {
		t.Fatal("expected served stale")
	}
	if result.FallbackMode != FallbackModeServeStale {
		t.Fatalf("expected serve_stale, got %s", result.FallbackMode)
	}
	if result.Data.Count != 55 {
		t.Fatalf("expected stale count 55, got %d", result.Data.Count)
	}
}

func TestExecuteWithFallback_FailClosedMode(t *testing.T) {
	executor, err := NewFallbackExecutor(DefaultCacheLifecycleProfiles())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	_, err = ExecuteWithFallback(
		context.Background(),
		executor,
		"critical_reference",
		func(_ context.Context) (sampleProjection, bool, error) {
			return sampleProjection{}, false, errors.New("cache unavailable")
		},
		func(_ context.Context) (sampleProjection, error) {
			return sampleProjection{ID: "src_4", Count: 99}, nil
		},
		nil,
	)
	if err == nil {
		t.Fatal("expected fail_closed error")
	}
}

func TestExecuteWithFallback_ServeStaleFallsBackToSource(t *testing.T) {
	executor, err := NewFallbackExecutor(DefaultCacheLifecycleProfiles())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	sourceCalls := 0

	result, err := ExecuteWithFallback(
		context.Background(),
		executor,
		"dashboard_hot",
		func(_ context.Context) (sampleProjection, bool, error) {
			return sampleProjection{}, false, errors.New("cache unavailable")
		},
		func(_ context.Context) (sampleProjection, error) {
			sourceCalls++
			return sampleProjection{ID: "src_5", Count: 66}, nil
		},
		func(_ context.Context) (sampleProjection, bool, error) {
			return sampleProjection{}, false, nil
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !result.FallbackUsed {
		t.Fatal("expected fallback used")
	}
	if result.ServedStale {
		t.Fatal("expected stale false when stale data absent")
	}
	if sourceCalls != 1 {
		t.Fatalf("expected source called once, got %d", sourceCalls)
	}
	if result.Data.Count != 66 {
		t.Fatalf("expected count 66, got %d", result.Data.Count)
	}
}
