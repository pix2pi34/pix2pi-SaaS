package readcache

import "testing"

func TestCacheLifecycleRegistry_RegisterAndGet(t *testing.T) {
	registry := NewCacheLifecycleRegistry()

	profile := CacheLifecycleProfile{
		Name:               "dashboard_hot",
		TTLClass:           TTLClassShort,
		Warmup:             WarmupModeStartup,
		Eviction:           EvictionPolicyLRULike,
		Fallback:           FallbackModeServeStale,
		HotKeyCandidate:    true,
		RequiresTenantSafe: true,
		Reason:             "dashboard cache lifecycle",
	}

	if err := registry.Register(profile); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	got, ok := registry.Get("dashboard_hot")
	if !ok {
		t.Fatal("expected lifecycle profile")
	}
	if got.Warmup != WarmupModeStartup {
		t.Fatalf("expected startup warmup, got %s", got.Warmup)
	}
	if got.Fallback != FallbackModeServeStale {
		t.Fatalf("expected serve stale fallback, got %s", got.Fallback)
	}
}

func TestCacheLifecycleRegistry_Duplicate(t *testing.T) {
	registry := NewCacheLifecycleRegistry()

	profile := CacheLifecycleProfile{
		Name:               "dashboard_hot",
		TTLClass:           TTLClassShort,
		Warmup:             WarmupModeStartup,
		Eviction:           EvictionPolicyLRULike,
		Fallback:           FallbackModeServeStale,
		HotKeyCandidate:    true,
		RequiresTenantSafe: true,
		Reason:             "dashboard cache lifecycle",
	}

	if err := registry.Register(profile); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err := registry.Register(profile)
	if err == nil {
		t.Fatal("expected duplicate error")
	}
	if err != ErrDuplicateLifecycleProfile {
		t.Fatalf("expected ErrDuplicateLifecycleProfile, got %v", err)
	}
}

func TestDefaultCacheLifecycleProfiles(t *testing.T) {
	registry := DefaultCacheLifecycleProfiles()

	items := registry.List()
	if len(items) != 4 {
		t.Fatalf("expected 4 lifecycle profiles, got %d", len(items))
	}

	dashboard, ok := registry.Get("dashboard_hot")
	if !ok {
		t.Fatal("expected dashboard_hot")
	}
	if dashboard.HotKeyCandidate != true {
		t.Fatal("expected dashboard_hot to be hot key candidate")
	}

	report, ok := registry.Get("report_balanced")
	if !ok {
		t.Fatal("expected report_balanced")
	}
	if report.Eviction != EvictionPolicyTTLOnly {
		t.Fatalf("expected ttl_only eviction, got %s", report.Eviction)
	}

	exporting, ok := registry.Get("export_prepared")
	if !ok {
		t.Fatal("expected export_prepared")
	}
	if exporting.Warmup != WarmupModeScheduled {
		t.Fatalf("expected scheduled warmup, got %s", exporting.Warmup)
	}

	critical, ok := registry.Get("critical_reference")
	if !ok {
		t.Fatal("expected critical_reference")
	}
	if critical.Fallback != FallbackModeFailClosed {
		t.Fatalf("expected fail_closed, got %s", critical.Fallback)
	}
}

func TestCacheLifecycleProfile_Invalid(t *testing.T) {
	profile := CacheLifecycleProfile{
		Name:               "bad profile",
		TTLClass:           TTLClassShort,
		Warmup:             WarmupModeStartup,
		Eviction:           EvictionPolicyLRULike,
		Fallback:           FallbackModeServeStale,
		HotKeyCandidate:    true,
		RequiresTenantSafe: true,
		Reason:             "invalid because of space in name",
	}

	err := profile.Validate()
	if err == nil {
		t.Fatal("expected validation error")
	}
}
