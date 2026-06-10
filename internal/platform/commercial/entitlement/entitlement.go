package entitlement

import (
	"fmt"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/catalog"
)

type DecisionStatus string
type ReasonCode string

const (
	DecisionAllow DecisionStatus = "ALLOW"
	DecisionDeny  DecisionStatus = "DENY"
)

const (
	ReasonAllowFeatureIncluded ReasonCode = "ALLOW_FEATURE_INCLUDED"
	ReasonAllowLimitAvailable  ReasonCode = "ALLOW_LIMIT_AVAILABLE"
	ReasonDenyTenantRequired   ReasonCode = "DENY_TENANT_REQUIRED"
	ReasonDenyUserRequired     ReasonCode = "DENY_USER_REQUIRED"
	ReasonDenyPlanRequired     ReasonCode = "DENY_PLAN_REQUIRED"
	ReasonDenyPlanUnknown      ReasonCode = "DENY_PLAN_UNKNOWN"
	ReasonDenyFeatureMissing   ReasonCode = "DENY_FEATURE_NOT_INCLUDED"
	ReasonDenyLimitUnknown     ReasonCode = "DENY_LIMIT_UNKNOWN"
	ReasonDenyLimitExceeded    ReasonCode = "DENY_LIMIT_EXCEEDED"
)

type RuntimeContext struct {
	TenantID string
	UserID   string
	Plan    catalog.PlanCode
}

type Decision struct {
	Status        DecisionStatus
	ReasonCode    ReasonCode
	ReasonMessage string

	TenantID    string
	UserID      string
	PlanCode    catalog.PlanCode
	FeatureCode catalog.FeatureCode
	LimitCode   catalog.LimitCode

	LimitValue   int
	CurrentUsage int
	RequestedAdd int
	NextUsage    int
}

type Runtime struct {
	catalog catalog.Catalog
}

func NewRuntime(c catalog.Catalog) (*Runtime, error) {
	if err := c.Validate(); err != nil {
		return nil, fmt.Errorf("invalid catalog: %w", err)
	}

	return &Runtime{catalog: c}, nil
}

func NewDefaultRuntime() (*Runtime, error) {
	return NewRuntime(catalog.DefaultCatalog())
}

func (r *Runtime) CheckFeature(ctx RuntimeContext, feature catalog.FeatureCode) Decision {
	if decision, ok := r.validateContext(ctx); !ok {
		decision.FeatureCode = feature
		return decision
	}

	if _, ok := r.catalog.Plan(ctx.Plan); !ok {
		return r.deny(ctx, feature, "", ReasonDenyPlanUnknown, "plan is not defined in catalog")
	}

	if !r.catalog.HasFeature(ctx.Plan, feature) {
		return r.deny(ctx, feature, "", ReasonDenyFeatureMissing, "feature is not included in plan")
	}

	return Decision{
		Status:        DecisionAllow,
		ReasonCode:    ReasonAllowFeatureIncluded,
		ReasonMessage: "feature is included in plan",
		TenantID:      ctx.TenantID,
		UserID:        ctx.UserID,
		PlanCode:      ctx.Plan,
		FeatureCode:   feature,
	}
}

func (r *Runtime) CheckLimit(ctx RuntimeContext, limit catalog.LimitCode, currentUsage int, requestedAdd int) Decision {
	if decision, ok := r.validateContext(ctx); !ok {
		decision.LimitCode = limit
		decision.CurrentUsage = currentUsage
		decision.RequestedAdd = requestedAdd
		decision.NextUsage = currentUsage + requestedAdd
		return decision
	}

	limitValue, ok := r.catalog.Limit(ctx.Plan, limit)
	if !ok {
		return r.denyLimit(ctx, limit, currentUsage, requestedAdd, 0, ReasonDenyLimitUnknown, "limit is not defined in plan")
	}

	nextUsage := currentUsage + requestedAdd
	if nextUsage > limitValue {
		return r.denyLimit(ctx, limit, currentUsage, requestedAdd, limitValue, ReasonDenyLimitExceeded, "limit would be exceeded")
	}

	return Decision{
		Status:        DecisionAllow,
		ReasonCode:    ReasonAllowLimitAvailable,
		ReasonMessage: "limit is available",
		TenantID:      ctx.TenantID,
		UserID:        ctx.UserID,
		PlanCode:      ctx.Plan,
		LimitCode:     limit,
		LimitValue:    limitValue,
		CurrentUsage:  currentUsage,
		RequestedAdd:  requestedAdd,
		NextUsage:     nextUsage,
	}
}

func (r *Runtime) CheckFeatureAndLimit(ctx RuntimeContext, feature catalog.FeatureCode, limit catalog.LimitCode, currentUsage int, requestedAdd int) Decision {
	featureDecision := r.CheckFeature(ctx, feature)
	if featureDecision.Status == DecisionDeny {
		return featureDecision
	}

	limitDecision := r.CheckLimit(ctx, limit, currentUsage, requestedAdd)
	if limitDecision.Status == DecisionDeny {
		limitDecision.FeatureCode = feature
		return limitDecision
	}

	limitDecision.FeatureCode = feature
	return limitDecision
}

func (r *Runtime) validateContext(ctx RuntimeContext) (Decision, bool) {
	if ctx.TenantID == "" {
		return Decision{
			Status:        DecisionDeny,
			ReasonCode:    ReasonDenyTenantRequired,
			ReasonMessage: "tenant id is required",
			UserID:        ctx.UserID,
			PlanCode:      ctx.Plan,
		}, false
	}

	if ctx.UserID == "" {
		return Decision{
			Status:        DecisionDeny,
			ReasonCode:    ReasonDenyUserRequired,
			ReasonMessage: "user id is required",
			TenantID:      ctx.TenantID,
			PlanCode:      ctx.Plan,
		}, false
	}

	if ctx.Plan == "" {
		return Decision{
			Status:        DecisionDeny,
			ReasonCode:    ReasonDenyPlanRequired,
			ReasonMessage: "plan code is required",
			TenantID:      ctx.TenantID,
			UserID:        ctx.UserID,
		}, false
	}

	return Decision{}, true
}

func (r *Runtime) deny(ctx RuntimeContext, feature catalog.FeatureCode, limit catalog.LimitCode, code ReasonCode, message string) Decision {
	return Decision{
		Status:        DecisionDeny,
		ReasonCode:    code,
		ReasonMessage: message,
		TenantID:      ctx.TenantID,
		UserID:        ctx.UserID,
		PlanCode:      ctx.Plan,
		FeatureCode:   feature,
		LimitCode:     limit,
	}
}

func (r *Runtime) denyLimit(ctx RuntimeContext, limit catalog.LimitCode, currentUsage int, requestedAdd int, limitValue int, code ReasonCode, message string) Decision {
	return Decision{
		Status:        DecisionDeny,
		ReasonCode:    code,
		ReasonMessage: message,
		TenantID:      ctx.TenantID,
		UserID:        ctx.UserID,
		PlanCode:      ctx.Plan,
		LimitCode:     limit,
		LimitValue:    limitValue,
		CurrentUsage:  currentUsage,
		RequestedAdd:  requestedAdd,
		NextUsage:     currentUsage + requestedAdd,
	}
}
