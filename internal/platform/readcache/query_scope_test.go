package readcache

import "testing"

func TestQueryScopeRegistry_RegisterAndGet(t *testing.T) {
	registry := NewQueryScopeRegistry()

	scope := QueryScope{
		Projection:             "sales_summary",
		QueryName:              "list_monthly",
		ReadFrequency:          ReadFrequencyHigh,
		ChangeFrequency:        ChangeFrequencyMedium,
		ParameterCardinality:   ParameterCardinalityMedium,
		RequiresStrongFresh:    false,
		FinancialSourceOfTruth: false,
		SupportsPagination:     true,
		Reason:                 "cache uygun query",
		Decision:               CacheDecisionAllow,
		TTLClass:               TTLClassMedium,
		InvalidationMode:       InvalidationModeEvent,
	}

	if err := registry.Register(scope); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	got, ok := registry.Get("sales_summary", "list_monthly")
	if !ok {
		t.Fatal("expected registered scope")
	}
	if got.Decision != CacheDecisionAllow {
		t.Fatalf("expected allow, got %s", got.Decision)
	}
	if got.TTLClass != TTLClassMedium {
		t.Fatalf("expected medium ttl, got %s", got.TTLClass)
	}
}

func TestQueryScopeRegistry_Duplicate(t *testing.T) {
	registry := NewQueryScopeRegistry()

	scope := QueryScope{
		Projection:             "sales_summary",
		QueryName:              "list_monthly",
		ReadFrequency:          ReadFrequencyHigh,
		ChangeFrequency:        ChangeFrequencyMedium,
		ParameterCardinality:   ParameterCardinalityMedium,
		RequiresStrongFresh:    false,
		FinancialSourceOfTruth: false,
		SupportsPagination:     true,
		Reason:                 "cache uygun query",
		Decision:               CacheDecisionAllow,
		TTLClass:               TTLClassMedium,
		InvalidationMode:       InvalidationModeEvent,
	}

	if err := registry.Register(scope); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err := registry.Register(scope)
	if err == nil {
		t.Fatal("expected duplicate error")
	}
	if err != ErrDuplicateQueryScope {
		t.Fatalf("expected ErrDuplicateQueryScope, got %v", err)
	}
}

func TestDefaultProjectionQueryScopes(t *testing.T) {
	registry := DefaultProjectionQueryScopes()

	sales, ok := registry.Get("sales_summary", "list_monthly")
	if !ok {
		t.Fatal("expected sales_summary/list_monthly")
	}
	if sales.Decision != CacheDecisionAllow {
		t.Fatalf("expected allow, got %s", sales.Decision)
	}

	stock, ok := registry.Get("stock_snapshot", "list_by_branch")
	if !ok {
		t.Fatal("expected stock_snapshot/list_by_branch")
	}
	if stock.Decision != CacheDecisionCaution {
		t.Fatalf("expected caution, got %s", stock.Decision)
	}
	if stock.TTLClass != TTLClassShort {
		t.Fatalf("expected short ttl, got %s", stock.TTLClass)
	}

	ledger, ok := registry.Get("ledger_entries", "list_posted_entries")
	if !ok {
		t.Fatal("expected ledger_entries/list_posted_entries")
	}
	if ledger.Decision != CacheDecisionDeny {
		t.Fatalf("expected deny, got %s", ledger.Decision)
	}
	if ledger.FinancialSourceOfTruth != true {
		t.Fatal("expected financial source of truth")
	}
}

func TestBuildQuerySpecFromScope_Allow(t *testing.T) {
	scope := QueryScope{
		Projection:             "sales_summary",
		QueryName:              "list_monthly",
		ReadFrequency:          ReadFrequencyHigh,
		ChangeFrequency:        ChangeFrequencyMedium,
		ParameterCardinality:   ParameterCardinalityMedium,
		RequiresStrongFresh:    false,
		FinancialSourceOfTruth: false,
		SupportsPagination:     true,
		Reason:                 "cache uygun query",
		Decision:               CacheDecisionAllow,
		TTLClass:               TTLClassMedium,
		InvalidationMode:       InvalidationModeEvent,
	}

	spec, err := BuildQuerySpecFromScope(
		scope,
		"tenant_42",
		1,
		20,
		"created_desc",
		map[string]any{"month": "2026-04"},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if spec.Projection != "sales_summary" {
		t.Fatalf("expected sales_summary, got %s", spec.Projection)
	}
	if spec.TTLClass != TTLClassMedium {
		t.Fatalf("expected medium ttl, got %s", spec.TTLClass)
	}
}

func TestBuildQuerySpecFromScope_Deny(t *testing.T) {
	scope := QueryScope{
		Projection:             "ledger_entries",
		QueryName:              "list_posted_entries",
		ReadFrequency:          ReadFrequencyMedium,
		ChangeFrequency:        ChangeFrequencyMedium,
		ParameterCardinality:   ParameterCardinalityHigh,
		RequiresStrongFresh:    true,
		FinancialSourceOfTruth: true,
		SupportsPagination:     true,
		Reason:                 "kritik finansal query",
		Decision:               CacheDecisionDeny,
		TTLClass:               "",
		InvalidationMode:       InvalidationModeNone,
	}

	_, err := BuildQuerySpecFromScope(
		scope,
		"tenant_42",
		1,
		20,
		"created_desc",
		map[string]any{"month": "2026-04"},
	)
	if err == nil {
		t.Fatal("expected deny error")
	}
}

func TestQueryScopeRegistry_List(t *testing.T) {
	registry := DefaultProjectionQueryScopes()

	items := registry.List()
	if len(items) != 3 {
		t.Fatalf("expected 3 items, got %d", len(items))
	}
	if items[0].Projection == "" {
		t.Fatal("expected sorted items with projection")
	}
}
