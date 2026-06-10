package readcache

import (
	"context"
	"errors"
	"fmt"
	"strings"
)

var (
	ErrNilServiceInvalidationPlanner = errors.New("readcache: nil service invalidation planner")
	ErrNilServiceContractRegistry    = errors.New("readcache: nil service contract registry")
)

type ServiceInvalidationAction struct {
	Projection string
	Mode       InvalidationMode
	Reason     string
}

type ServiceInvalidationPlan struct {
	Service                 ServiceContractName
	TenantID                string
	Entity                  string
	Usage                   string
	Decision                CacheDecision
	Freshness               FreshnessClass
	RequiresTenantIsolation bool
	Actions                 []ServiceInvalidationAction
}

type ServiceInvalidationPlanner struct {
	contracts *ServiceCacheContractRegistry
	cache     *ProjectionCache
}

func NewServiceInvalidationPlanner(
	contracts *ServiceCacheContractRegistry,
	cache *ProjectionCache,
) (*ServiceInvalidationPlanner, error) {
	if contracts == nil {
		return nil, ErrNilServiceContractRegistry
	}
	if cache == nil {
		return nil, ErrNilProjectionCache
	}

	return &ServiceInvalidationPlanner{
		contracts: contracts,
		cache:     cache,
	}, nil
}

func (p *ServiceInvalidationPlanner) Plan(
	service ServiceContractName,
	tenantID string,
	entity string,
	usage string,
) (ServiceInvalidationPlan, error) {
	if p == nil {
		return ServiceInvalidationPlan{}, ErrNilServiceInvalidationPlanner
	}
	if strings.TrimSpace(entity) == "" {
		return ServiceInvalidationPlan{}, ErrEmptyServiceRuleEntity
	}
	if strings.TrimSpace(usage) == "" {
		return ServiceInvalidationPlan{}, ErrEmptyServiceRuleUsage
	}
	if err := validateKeyPart(entity); err != nil {
		return ServiceInvalidationPlan{}, fmt.Errorf("entity: %w", err)
	}
	if err := validateKeyPart(usage); err != nil {
		return ServiceInvalidationPlan{}, fmt.Errorf("usage: %w", err)
	}

	rule, ok := p.contracts.FindRule(service, entity, usage)
	if !ok {
		return ServiceInvalidationPlan{}, fmt.Errorf("%w: %s/%s/%s", ErrUnknownServiceRule, service, entity, usage)
	}

	if rule.RequiresTenantIsolation {
		if strings.TrimSpace(tenantID) == "" {
			return ServiceInvalidationPlan{}, ErrEmptyTenantID
		}
		if err := validateKeyPart(tenantID); err != nil {
			return ServiceInvalidationPlan{}, fmt.Errorf("tenant id: %w", err)
		}
	}

	plan := ServiceInvalidationPlan{
		Service:                 service,
		TenantID:                tenantID,
		Entity:                  entity,
		Usage:                   usage,
		Decision:                rule.Decision,
		Freshness:               rule.Freshness,
		RequiresTenantIsolation: rule.RequiresTenantIsolation,
		Actions:                 make([]ServiceInvalidationAction, 0),
	}

	switch rule.InvalidationMode {
	case InvalidationModeWrite, InvalidationModeEvent, InvalidationModeRebuild:
		plan.Actions = append(plan.Actions, ServiceInvalidationAction{
			Projection: entity,
			Mode:       rule.InvalidationMode,
			Reason:     rule.Reason,
		})
	case InvalidationModeNone:
	default:
		return ServiceInvalidationPlan{}, ErrInvalidKeyPart
	}

	return plan, nil
}

func ExecuteServiceInvalidationPlan(
	ctx context.Context,
	planner *ServiceInvalidationPlanner,
	plan ServiceInvalidationPlan,
) error {
	if planner == nil {
		return ErrNilServiceInvalidationPlanner
	}

	for _, action := range plan.Actions {
		if strings.TrimSpace(action.Projection) == "" {
			return ErrEmptyProjection
		}
		if err := planner.cache.DeleteProjection(ctx, plan.TenantID, action.Projection); err != nil {
			return err
		}
	}

	return nil
}

func InvalidateServiceCache(
	ctx context.Context,
	planner *ServiceInvalidationPlanner,
	service ServiceContractName,
	tenantID string,
	entity string,
	usage string,
) error {
	if planner == nil {
		return ErrNilServiceInvalidationPlanner
	}

	plan, err := planner.Plan(service, tenantID, entity, usage)
	if err != nil {
		return err
	}

	return ExecuteServiceInvalidationPlan(ctx, planner, plan)
}
