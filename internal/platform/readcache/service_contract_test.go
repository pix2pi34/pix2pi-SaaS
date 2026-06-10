package readcache

import "testing"

func TestServiceCacheContractRegistry_RegisterAndGet(t *testing.T) {
	registry := NewServiceCacheContractRegistry()

	contract := ServiceCacheContract{
		Service: ServiceContractIdentity,
		Rules: []ServiceCacheRule{
			{
				Entity:                  "user_profile",
				Usage:                   "lookup_by_id",
				Decision:                CacheDecisionAllow,
				TTLClass:                TTLClassMedium,
				InvalidationMode:        InvalidationModeWrite,
				Freshness:               FreshnessBalanced,
				RequiresTenantIsolation: true,
				Reason:                  "identity profile cache",
			},
		},
	}

	if err := registry.Register(contract); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	got, ok := registry.Get(ServiceContractIdentity)
	if !ok {
		t.Fatal("expected registered contract")
	}
	if got.Service != ServiceContractIdentity {
		t.Fatalf("expected identity, got %s", got.Service)
	}
	if len(got.Rules) != 1 {
		t.Fatalf("expected 1 rule, got %d", len(got.Rules))
	}
}

func TestServiceCacheContractRegistry_DuplicateContract(t *testing.T) {
	registry := NewServiceCacheContractRegistry()

	contract := ServiceCacheContract{
		Service: ServiceContractIdentity,
		Rules: []ServiceCacheRule{
			{
				Entity:                  "user_profile",
				Usage:                   "lookup_by_id",
				Decision:                CacheDecisionAllow,
				TTLClass:                TTLClassMedium,
				InvalidationMode:        InvalidationModeWrite,
				Freshness:               FreshnessBalanced,
				RequiresTenantIsolation: true,
				Reason:                  "identity profile cache",
			},
		},
	}

	if err := registry.Register(contract); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err := registry.Register(contract)
	if err == nil {
		t.Fatal("expected duplicate contract error")
	}
	if err != ErrDuplicateServiceContract {
		t.Fatalf("expected ErrDuplicateServiceContract, got %v", err)
	}
}

func TestServiceCacheContractRegistry_FindRule(t *testing.T) {
	registry := DefaultServiceCacheContracts()

	rule, ok := registry.FindRule(ServiceContractERP, "ledger_entries", "posted_financial_list")
	if !ok {
		t.Fatal("expected erp ledger rule")
	}
	if rule.Decision != CacheDecisionDeny {
		t.Fatalf("expected deny, got %s", rule.Decision)
	}
	if rule.Freshness != FreshnessCritical {
		t.Fatalf("expected critical freshness, got %s", rule.Freshness)
	}
}

func TestDefaultServiceCacheContracts(t *testing.T) {
	registry := DefaultServiceCacheContracts()

	services := registry.ListServices()
	if len(services) != 4 {
		t.Fatalf("expected 4 services, got %d", len(services))
	}

	identity, ok := registry.Get(ServiceContractIdentity)
	if !ok {
		t.Fatal("expected identity contract")
	}
	if len(identity.Rules) != 2 {
		t.Fatalf("expected 2 identity rules, got %d", len(identity.Rules))
	}

	gateway, ok := registry.Get(ServiceContractGateway)
	if !ok {
		t.Fatal("expected gateway contract")
	}
	if len(gateway.Rules) != 2 {
		t.Fatalf("expected 2 gateway rules, got %d", len(gateway.Rules))
	}

	erp, ok := registry.Get(ServiceContractERP)
	if !ok {
		t.Fatal("expected erp contract")
	}
	if len(erp.Rules) != 2 {
		t.Fatalf("expected 2 erp rules, got %d", len(erp.Rules))
	}

	reporting, ok := registry.Get(ServiceContractReporting)
	if !ok {
		t.Fatal("expected reporting contract")
	}
	if len(reporting.Rules) != 2 {
		t.Fatalf("expected 2 reporting rules, got %d", len(reporting.Rules))
	}
}

func TestServiceCacheContractRegistry_FindUnknownRule(t *testing.T) {
	registry := DefaultServiceCacheContracts()

	_, ok := registry.FindRule(ServiceContractIdentity, "unknown_entity", "unknown_usage")
	if ok {
		t.Fatal("expected unknown rule to be absent")
	}
}

func TestServiceCacheContract_InvalidDuplicateRule(t *testing.T) {
	registry := NewServiceCacheContractRegistry()

	err := registry.Register(ServiceCacheContract{
		Service: ServiceContractReporting,
		Rules: []ServiceCacheRule{
			{
				Entity:                  "dashboard_kpi",
				Usage:                   "summary_cards",
				Decision:                CacheDecisionAllow,
				TTLClass:                TTLClassShort,
				InvalidationMode:        InvalidationModeEvent,
				Freshness:               FreshnessHot,
				RequiresTenantIsolation: true,
				Reason:                  "rule a",
			},
			{
				Entity:                  "dashboard_kpi",
				Usage:                   "summary_cards",
				Decision:                CacheDecisionCaution,
				TTLClass:                TTLClassShort,
				InvalidationMode:        InvalidationModeEvent,
				Freshness:               FreshnessHot,
				RequiresTenantIsolation: true,
				Reason:                  "rule b",
			},
		},
	})
	if err == nil {
		t.Fatal("expected duplicate service rule error")
	}
	if err != ErrDuplicateServiceRule {
		t.Fatalf("expected ErrDuplicateServiceRule, got %v", err)
	}
}
