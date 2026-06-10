package readcache

import "testing"

func TestNewWarmupPlanner(t *testing.T) {
	planner, err := NewWarmupPlanner(
		DefaultCacheLifecycleProfiles(),
		DefaultReportingProfiles(),
		DefaultWarmupTargets(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if planner == nil {
		t.Fatal("expected warmup planner")
	}
}

func TestDefaultWarmupTargets(t *testing.T) {
	targets := DefaultWarmupTargets().List()
	if len(targets) != 4 {
		t.Fatalf("expected 4 warmup targets, got %d", len(targets))
	}
}

func TestWarmupPlanner_PlanStartup(t *testing.T) {
	planner, err := NewWarmupPlanner(
		DefaultCacheLifecycleProfiles(),
		DefaultReportingProfiles(),
		DefaultWarmupTargets(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	tasks, err := planner.Plan("tenant_42", WarmupModeStartup)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(tasks) != 2 {
		t.Fatalf("expected 2 startup tasks, got %d", len(tasks))
	}

	if tasks[0].Priority != WarmupPriorityHigh {
		t.Fatalf("expected high priority first, got %s", tasks[0].Priority)
	}
	if tasks[0].Warmup != WarmupModeStartup {
		t.Fatalf("expected startup warmup, got %s", tasks[0].Warmup)
	}
	if tasks[0].Surface != ReportingSurfaceDashboard {
		t.Fatalf("expected dashboard surface, got %s", tasks[0].Surface)
	}
	if tasks[0].TTLClass != TTLClassShort {
		t.Fatalf("expected short ttl, got %s", tasks[0].TTLClass)
	}
}

func TestWarmupPlanner_PlanBySurface(t *testing.T) {
	planner, err := NewWarmupPlanner(
		DefaultCacheLifecycleProfiles(),
		DefaultReportingProfiles(),
		DefaultWarmupTargets(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	tasks, err := planner.PlanBySurface("tenant_42", WarmupModeStartup, ReportingSurfaceDashboard)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(tasks) != 2 {
		t.Fatalf("expected 2 dashboard startup tasks, got %d", len(tasks))
	}
	for _, item := range tasks {
		if item.Surface != ReportingSurfaceDashboard {
			t.Fatalf("expected dashboard surface, got %s", item.Surface)
		}
	}
}

func TestWarmupPlanner_PlanLazySkipsUnsupportedProfiles(t *testing.T) {
	planner, err := NewWarmupPlanner(
		DefaultCacheLifecycleProfiles(),
		DefaultReportingProfiles(),
		DefaultWarmupTargets(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	tasks, err := planner.Plan("tenant_42", WarmupModeLazy)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(tasks) != 0 {
		t.Fatalf("expected 0 lazy warmup tasks because profile warmup support is false, got %d", len(tasks))
	}
}

func TestBuildWarmupQuerySpec(t *testing.T) {
	spec, err := BuildWarmupQuerySpec(WarmupTask{
		TenantID:      "tenant_42",
		LifecycleName: "dashboard_hot",
		Projection:    "dashboard_kpi",
		QueryName:     "summary_cards",
		Surface:       ReportingSurfaceDashboard,
		TTLClass:      TTLClassShort,
		Warmup:        WarmupModeStartup,
		Priority:      WarmupPriorityHigh,
		Reason:        "warmup",
	}, map[string]any{"branch": "istanbul"})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if spec.Projection != "dashboard_kpi" {
		t.Fatalf("expected dashboard_kpi, got %s", spec.Projection)
	}
	if spec.QueryName != "summary_cards" {
		t.Fatalf("expected summary_cards, got %s", spec.QueryName)
	}
	if spec.Sort != "warmup" {
		t.Fatalf("expected warmup sort, got %s", spec.Sort)
	}
}
