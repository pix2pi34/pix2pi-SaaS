package readcache

import (
	"context"
	"testing"
	"time"
)

type plannerStore struct {
	items          map[string]fakeEntry
	deletePatterns []string
}

func newPlannerStore() *plannerStore {
	return &plannerStore{
		items:          make(map[string]fakeEntry),
		deletePatterns: make([]string, 0),
	}
}

func (f *plannerStore) Get(_ context.Context, key string, dest any) (bool, error) {
	entry, ok := f.items[key]
	if !ok {
		return false, nil
	}

	switch d := dest.(type) {
	case *sampleProjection:
		v, ok := entry.value.(sampleProjection)
		if !ok {
			return false, nil
		}
		*d = v
		return true, nil
	default:
		return false, nil
	}
}

func (f *plannerStore) Set(_ context.Context, key string, value any, ttl time.Duration) error {
	f.items[key] = fakeEntry{
		value: value,
		ttl:   ttl,
	}
	return nil
}

func (f *plannerStore) Delete(_ context.Context, key string) error {
	delete(f.items, key)
	return nil
}

func (f *plannerStore) DeletePattern(_ context.Context, pattern string) error {
	f.deletePatterns = append(f.deletePatterns, pattern)
	return nil
}

func TestNewServiceInvalidationPlanner(t *testing.T) {
	store := newPlannerStore()

	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	planner, err := NewServiceInvalidationPlanner(DefaultServiceCacheContracts(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if planner == nil {
		t.Fatal("expected planner")
	}
}

func TestServiceInvalidationPlanner_PlanIdentityRule(t *testing.T) {
	store := newPlannerStore()

	cache, err := NewProjectionCache(store, "prod", "identity", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	planner, err := NewServiceInvalidationPlanner(DefaultServiceCacheContracts(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	plan, err := planner.Plan(
		ServiceContractIdentity,
		"tenant_42",
		"user_profile",
		"lookup_by_id",
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if plan.Service != ServiceContractIdentity {
		t.Fatalf("expected identity, got %s", plan.Service)
	}
	if plan.Decision != CacheDecisionAllow {
		t.Fatalf("expected allow, got %s", plan.Decision)
	}
	if plan.RequiresTenantIsolation != true {
		t.Fatal("expected tenant isolation required")
	}
	if len(plan.Actions) != 1 {
		t.Fatalf("expected 1 action, got %d", len(plan.Actions))
	}
	if plan.Actions[0].Projection != "user_profile" {
		t.Fatalf("expected projection user_profile, got %s", plan.Actions[0].Projection)
	}
	if plan.Actions[0].Mode != InvalidationModeWrite {
		t.Fatalf("expected write invalidation, got %s", plan.Actions[0].Mode)
	}
}

func TestServiceInvalidationPlanner_PlanERPDenyNoAction(t *testing.T) {
	store := newPlannerStore()

	cache, err := NewProjectionCache(store, "prod", "erp", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	planner, err := NewServiceInvalidationPlanner(DefaultServiceCacheContracts(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	plan, err := planner.Plan(
		ServiceContractERP,
		"tenant_42",
		"ledger_entries",
		"posted_financial_list",
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if plan.Decision != CacheDecisionDeny {
		t.Fatalf("expected deny, got %s", plan.Decision)
	}
	if len(plan.Actions) != 0 {
		t.Fatalf("expected 0 actions, got %d", len(plan.Actions))
	}
}

func TestExecuteServiceInvalidationPlan(t *testing.T) {
	store := newPlannerStore()

	cache, err := NewProjectionCache(store, "prod", "reporting", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	planner, err := NewServiceInvalidationPlanner(DefaultServiceCacheContracts(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	plan, err := planner.Plan(
		ServiceContractReporting,
		"tenant_42",
		"dashboard_kpi",
		"summary_cards",
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err = ExecuteServiceInvalidationPlan(context.Background(), planner, plan)
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

func TestInvalidateServiceCache(t *testing.T) {
	store := newPlannerStore()

	cache, err := NewProjectionCache(store, "prod", "gateway", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	planner, err := NewServiceInvalidationPlanner(DefaultServiceCacheContracts(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err = InvalidateServiceCache(
		context.Background(),
		planner,
		ServiceContractGateway,
		"tenant_42",
		"tenant_route_policy",
		"resolve_for_request",
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(store.deletePatterns) != 1 {
		t.Fatalf("expected 1 delete pattern, got %d", len(store.deletePatterns))
	}

	expected := "pix2pi:prod:gateway:tenant:tenant_42:projection:tenant_route_policy:*"
	if store.deletePatterns[0] != expected {
		t.Fatalf("expected %q, got %q", expected, store.deletePatterns[0])
	}
}

func TestServiceInvalidationPlanner_UnknownRule(t *testing.T) {
	store := newPlannerStore()

	cache, err := NewProjectionCache(store, "prod", "gateway", DefaultTTLPolicy())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	planner, err := NewServiceInvalidationPlanner(DefaultServiceCacheContracts(), cache)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	_, err = planner.Plan(
		ServiceContractGateway,
		"tenant_42",
		"unknown_entity",
		"unknown_usage",
	)
	if err == nil {
		t.Fatal("expected unknown rule error")
	}
}
