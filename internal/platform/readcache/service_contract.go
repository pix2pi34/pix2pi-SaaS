package readcache

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

var (
	ErrEmptyServiceContractName    = errors.New("readcache: empty service contract name")
	ErrDuplicateServiceContract    = errors.New("readcache: duplicate service contract")
	ErrUnknownServiceContract      = errors.New("readcache: unknown service contract")
	ErrEmptyServiceRuleEntity      = errors.New("readcache: empty service rule entity")
	ErrEmptyServiceRuleUsage       = errors.New("readcache: empty service rule usage")
	ErrDuplicateServiceRule        = errors.New("readcache: duplicate service rule")
	ErrUnknownServiceRule          = errors.New("readcache: unknown service rule")
	ErrInvalidServiceContractName  = errors.New("readcache: invalid service contract name")
	ErrInvalidFreshnessClass       = errors.New("readcache: invalid freshness class")
)

type ServiceContractName string

const (
	ServiceContractIdentity  ServiceContractName = "identity"
	ServiceContractGateway   ServiceContractName = "gateway"
	ServiceContractERP       ServiceContractName = "erp"
	ServiceContractReporting ServiceContractName = "reporting"
)

type FreshnessClass string

const (
	FreshnessCritical  FreshnessClass = "critical"
	FreshnessHot       FreshnessClass = "hot"
	FreshnessBalanced  FreshnessClass = "balanced"
	FreshnessReference FreshnessClass = "reference"
)

type ServiceCacheRule struct {
	Entity                 string
	Usage                  string
	Decision               CacheDecision
	TTLClass               TTLClass
	InvalidationMode       InvalidationMode
	Freshness              FreshnessClass
	RequiresTenantIsolation bool
	Reason                 string
}

func (r ServiceCacheRule) Validate() error {
	if strings.TrimSpace(r.Entity) == "" {
		return ErrEmptyServiceRuleEntity
	}
	if strings.TrimSpace(r.Usage) == "" {
		return ErrEmptyServiceRuleUsage
	}
	if err := validateKeyPart(r.Entity); err != nil {
		return fmt.Errorf("entity: %w", err)
	}
	if err := validateKeyPart(r.Usage); err != nil {
		return fmt.Errorf("usage: %w", err)
	}

	switch r.Decision {
	case CacheDecisionAllow, CacheDecisionCaution, CacheDecisionDeny:
	default:
		return ErrInvalidKeyPart
	}

	switch r.InvalidationMode {
	case InvalidationModeWrite, InvalidationModeEvent, InvalidationModeRebuild, InvalidationModeNone:
	default:
		return ErrInvalidKeyPart
	}

	switch r.Freshness {
	case FreshnessCritical, FreshnessHot, FreshnessBalanced, FreshnessReference:
	default:
		return ErrInvalidFreshnessClass
	}

	switch r.Decision {
	case CacheDecisionAllow, CacheDecisionCaution:
		if _, err := DefaultTTLPolicy().Resolve(r.TTLClass); err != nil {
			return err
		}
	case CacheDecisionDeny:
		if r.TTLClass != "" {
			if _, err := DefaultTTLPolicy().Resolve(r.TTLClass); err != nil {
				return err
			}
		}
	}

	return nil
}

type ServiceCacheContract struct {
	Service ServiceContractName
	Rules   []ServiceCacheRule
}

func (c ServiceCacheContract) Validate() error {
	switch c.Service {
	case ServiceContractIdentity, ServiceContractGateway, ServiceContractERP, ServiceContractReporting:
	default:
		return ErrInvalidServiceContractName
	}

	seen := make(map[string]struct{})
	for _, rule := range c.Rules {
		if err := rule.Validate(); err != nil {
			return err
		}

		key := rule.Entity + "::" + rule.Usage
		if _, exists := seen[key]; exists {
			return ErrDuplicateServiceRule
		}
		seen[key] = struct{}{}
	}

	return nil
}

type ServiceCacheContractRegistry struct {
	items map[ServiceContractName]ServiceCacheContract
}

func NewServiceCacheContractRegistry() *ServiceCacheContractRegistry {
	return &ServiceCacheContractRegistry{
		items: make(map[ServiceContractName]ServiceCacheContract),
	}
}

func (r *ServiceCacheContractRegistry) Register(contract ServiceCacheContract) error {
	if r == nil {
		return errors.New("readcache: nil service contract registry")
	}
	if err := contract.Validate(); err != nil {
		return err
	}

	if _, exists := r.items[contract.Service]; exists {
		return ErrDuplicateServiceContract
	}

	normalized := ServiceCacheContract{
		Service: contract.Service,
		Rules:   append([]ServiceCacheRule(nil), contract.Rules...),
	}
	sort.Slice(normalized.Rules, func(i, j int) bool {
		if normalized.Rules[i].Entity == normalized.Rules[j].Entity {
			return normalized.Rules[i].Usage < normalized.Rules[j].Usage
		}
		return normalized.Rules[i].Entity < normalized.Rules[j].Entity
	})

	r.items[contract.Service] = normalized
	return nil
}

func (r *ServiceCacheContractRegistry) MustRegister(contract ServiceCacheContract) {
	if err := r.Register(contract); err != nil {
		panic(err)
	}
}

func (r *ServiceCacheContractRegistry) Get(service ServiceContractName) (ServiceCacheContract, bool) {
	if r == nil {
		return ServiceCacheContract{}, false
	}
	item, ok := r.items[service]
	return item, ok
}

func (r *ServiceCacheContractRegistry) FindRule(service ServiceContractName, entity, usage string) (ServiceCacheRule, bool) {
	if r == nil {
		return ServiceCacheRule{}, false
	}

	contract, ok := r.items[service]
	if !ok {
		return ServiceCacheRule{}, false
	}

	for _, rule := range contract.Rules {
		if rule.Entity == entity && rule.Usage == usage {
			return rule, true
		}
	}

	return ServiceCacheRule{}, false
}

func (r *ServiceCacheContractRegistry) ListServices() []ServiceContractName {
	if r == nil {
		return nil
	}

	result := make([]ServiceContractName, 0, len(r.items))
	for service := range r.items {
		result = append(result, service)
	}

	sort.Slice(result, func(i, j int) bool {
		return string(result[i]) < string(result[j])
	})

	return result
}

func DefaultServiceCacheContracts() *ServiceCacheContractRegistry {
	registry := NewServiceCacheContractRegistry()

	registry.MustRegister(ServiceCacheContract{
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
				Reason:                  "kullanici profili okuma agirlikli yardimci cache",
			},
			{
				Entity:                  "role_permissions",
				Usage:                   "resolve_for_user",
				Decision:                CacheDecisionCaution,
				TTLClass:                TTLClassShort,
				InvalidationMode:        InvalidationModeWrite,
				Freshness:               FreshnessCritical,
				RequiresTenantIsolation: true,
				Reason:                  "yetki degisimi hizli yansimak zorunda",
			},
		},
	})

	registry.MustRegister(ServiceCacheContract{
		Service: ServiceContractGateway,
		Rules: []ServiceCacheRule{
			{
				Entity:                  "rate_limit_policy",
				Usage:                   "resolve_for_route",
				Decision:                CacheDecisionAllow,
				TTLClass:                TTLClassMedium,
				InvalidationMode:        InvalidationModeWrite,
				Freshness:               FreshnessBalanced,
				RequiresTenantIsolation: true,
				Reason:                  "gateway policy lookup icin uygun cache",
			},
			{
				Entity:                  "tenant_route_policy",
				Usage:                   "resolve_for_request",
				Decision:                CacheDecisionCaution,
				TTLClass:                TTLClassShort,
				InvalidationMode:        InvalidationModeWrite,
				Freshness:               FreshnessHot,
				RequiresTenantIsolation: true,
				Reason:                  "route bazli yetki degisimlerinde dikkatli cache",
			},
		},
	})

	registry.MustRegister(ServiceCacheContract{
		Service: ServiceContractERP,
		Rules: []ServiceCacheRule{
			{
				Entity:                  "stock_snapshot",
				Usage:                   "branch_list",
				Decision:                CacheDecisionCaution,
				TTLClass:                TTLClassShort,
				InvalidationMode:        InvalidationModeEvent,
				Freshness:               FreshnessHot,
				RequiresTenantIsolation: true,
				Reason:                  "stok hizli degisir event invalidation ister",
			},
			{
				Entity:                  "ledger_entries",
				Usage:                   "posted_financial_list",
				Decision:                CacheDecisionDeny,
				TTLClass:                "",
				InvalidationMode:        InvalidationModeNone,
				Freshness:               FreshnessCritical,
				RequiresTenantIsolation: true,
				Reason:                  "kritik finansal source of truth cache disi",
			},
		},
	})

	registry.MustRegister(ServiceCacheContract{
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
				Reason:                  "dashboard kpi cache icin uygun",
			},
			{
				Entity:                  "sales_reports",
				Usage:                   "monthly_summary",
				Decision:                CacheDecisionAllow,
				TTLClass:                TTLClassMedium,
				InvalidationMode:        InvalidationModeEvent,
				Freshness:               FreshnessBalanced,
				RequiresTenantIsolation: true,
				Reason:                  "aylik rapor cache icin uygun",
			},
		},
	})

	return registry
}
