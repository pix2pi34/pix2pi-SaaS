package integrationcatalog

import (
	"fmt"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/catalog"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/entitlement"
)

type IntegrationCode string
type Category string
type Status string
type ReasonCode string

const (
	IntegrationParasut                IntegrationCode = "parasut"
	IntegrationMarketplaceDiscovery   IntegrationCode = "marketplace_discovery"
	IntegrationMarketplaceOrders      IntegrationCode = "marketplace_orders"
	IntegrationMarketplaceStockSync   IntegrationCode = "marketplace_stock_sync"
	IntegrationWebhook                IntegrationCode = "webhook"
	IntegrationPublicAPI              IntegrationCode = "public_api"
	IntegrationTDHPExport             IntegrationCode = "tdhp_export"
	IntegrationAccountantPortalBridge IntegrationCode = "accountant_portal_bridge"
)

const (
	CategoryAccounting  Category = "accounting"
	CategoryMarketplace Category = "marketplace"
	CategoryWebhook     Category = "webhook"
	CategoryPublicAPI   Category = "public_api"
	CategoryExport      Category = "export"
	CategoryAccountant  Category = "accountant"
)

const (
	StatusDiscovery Status = "DISCOVERY"
	StatusReady     Status = "READY"
	StatusGated     Status = "GATED"
	StatusDisabled  Status = "DISABLED"
)

const (
	ReasonAllowIntegrationAccess         ReasonCode = "ALLOW_INTEGRATION_ACCESS"
	ReasonAllowIntegrationLimitAvailable ReasonCode = "ALLOW_INTEGRATION_LIMIT_AVAILABLE"
	ReasonDenyTenantRequired            ReasonCode = "DENY_TENANT_REQUIRED"
	ReasonDenyUserRequired              ReasonCode = "DENY_USER_REQUIRED"
	ReasonDenyPlanRequired              ReasonCode = "DENY_PLAN_REQUIRED"
	ReasonDenyPlanUnknown               ReasonCode = "DENY_PLAN_UNKNOWN"
	ReasonDenyIntegrationUnknown        ReasonCode = "DENY_INTEGRATION_UNKNOWN"
	ReasonDenyIntegrationDisabled       ReasonCode = "DENY_INTEGRATION_DISABLED"
	ReasonDenyFeatureMissing            ReasonCode = "DENY_FEATURE_NOT_INCLUDED"
	ReasonDenyLimitUnknown              ReasonCode = "DENY_LIMIT_UNKNOWN"
	ReasonDenyLimitExceeded             ReasonCode = "DENY_LIMIT_EXCEEDED"
)

type Integration struct {
	Code             IntegrationCode
	Name             string
	Category         Category
	Status           Status
	RequiredFeatures []catalog.FeatureCode
	RequiredLimit    catalog.LimitCode
	CommercialNote   string
}

type RuntimeContext struct {
	TenantID string
	UserID   string
	Plan     catalog.PlanCode
}

type Decision struct {
	Status        entitlement.DecisionStatus
	ReasonCode    string
	ReasonMessage string

	TenantID        string
	UserID          string
	PlanCode        catalog.PlanCode
	IntegrationCode IntegrationCode
	Category        Category
	IntegrationStatus Status

	FeatureCode catalog.FeatureCode
	LimitCode   catalog.LimitCode

	LimitValue   int
	CurrentUsage int
	RequestedAdd int
	NextUsage    int
}

type Runtime struct {
	catalog      catalog.Catalog
	integrations map[IntegrationCode]Integration
}

func NewDefaultRuntime() (*Runtime, error) {
	c := catalog.DefaultCatalog()
	if err := c.Validate(); err != nil {
		return nil, fmt.Errorf("invalid catalog: %w", err)
	}

	runtime := &Runtime{
		catalog: c,
		integrations: defaultIntegrations(),
	}

	if err := runtime.Validate(); err != nil {
		return nil, err
	}

	return runtime, nil
}

func defaultIntegrations() map[IntegrationCode]Integration {
	return map[IntegrationCode]Integration{
		IntegrationParasut: {
			Code: IntegrationParasut,
			Name: "Parasut",
			Category: CategoryAccounting,
			Status: StatusGated,
			RequiredFeatures: []catalog.FeatureCode{
				catalog.FeatureIntegrationCatalog,
			},
			RequiredLimit: catalog.LimitIntegrations,
			CommercialNote: "Gercek Parasut API baglantisi sonraki entegrasyon fazinda acilacak.",
		},
		IntegrationMarketplaceDiscovery: {
			Code: IntegrationMarketplaceDiscovery,
			Name: "Marketplace Discovery",
			Category: CategoryMarketplace,
			Status: StatusReady,
			RequiredFeatures: []catalog.FeatureCode{
				catalog.FeatureMarketplaceDiscovery,
			},
			RequiredLimit: catalog.LimitIntegrations,
			CommercialNote: "Pazaryeri kesif ve ticari hazirlik akisi.",
		},
		IntegrationMarketplaceOrders: {
			Code: IntegrationMarketplaceOrders,
			Name: "Marketplace Orders",
			Category: CategoryMarketplace,
			Status: StatusGated,
			RequiredFeatures: []catalog.FeatureCode{
				catalog.FeatureIntegrationCatalog,
			},
			RequiredLimit: catalog.LimitIntegrations,
			CommercialNote: "Siparis senkronizasyonu sonraki runtime fazina bagli.",
		},
		IntegrationMarketplaceStockSync: {
			Code: IntegrationMarketplaceStockSync,
			Name: "Marketplace Stock Sync",
			Category: CategoryMarketplace,
			Status: StatusGated,
			RequiredFeatures: []catalog.FeatureCode{
				catalog.FeatureIntegrationCatalog,
			},
			RequiredLimit: catalog.LimitIntegrations,
			CommercialNote: "Stok senkronizasyonu sonraki runtime fazina bagli.",
		},
		IntegrationWebhook: {
			Code: IntegrationWebhook,
			Name: "Webhook Access",
			Category: CategoryWebhook,
			Status: StatusReady,
			RequiredFeatures: []catalog.FeatureCode{
				catalog.FeatureWebhookAccess,
			},
			RequiredLimit: catalog.LimitIntegrations,
			CommercialNote: "Webhook erisimi paket bazli entitlement ile acilir.",
		},
		IntegrationPublicAPI: {
			Code: IntegrationPublicAPI,
			Name: "Public API",
			Category: CategoryPublicAPI,
			Status: StatusReady,
			RequiredFeatures: []catalog.FeatureCode{
				catalog.FeatureAPIAccessAdvanced,
			},
			RequiredLimit: catalog.LimitAPIMonthlyRequests,
			CommercialNote: "Public API ileri paketlerde acilir.",
		},
		IntegrationTDHPExport: {
			Code: IntegrationTDHPExport,
			Name: "TDHP Export",
			Category: CategoryExport,
			Status: StatusReady,
			RequiredFeatures: []catalog.FeatureCode{
				catalog.FeatureTDHPExportReady,
			},
			RequiredLimit: catalog.LimitMonthlyExports,
			CommercialNote: "Muhasebeci paketi ve export temelli ticari model icin hazirlik.",
		},
		IntegrationAccountantPortalBridge: {
			Code: IntegrationAccountantPortalBridge,
			Name: "Accountant Portal Bridge",
			Category: CategoryAccountant,
			Status: StatusReady,
			RequiredFeatures: []catalog.FeatureCode{
				catalog.FeatureAccountantPortal,
			},
			RequiredLimit: catalog.LimitAccountantFirms,
			CommercialNote: "7-9 muhasebeci portal ticari yuzeyi icin hazirlik.",
		},
	}
}

func (r *Runtime) Validate() error {
	if len(r.integrations) < 8 {
		return fmt.Errorf("expected at least 8 integrations, got %d", len(r.integrations))
	}

	required := []IntegrationCode{
		IntegrationParasut,
		IntegrationMarketplaceDiscovery,
		IntegrationMarketplaceOrders,
		IntegrationMarketplaceStockSync,
		IntegrationWebhook,
		IntegrationPublicAPI,
		IntegrationTDHPExport,
		IntegrationAccountantPortalBridge,
	}

	for _, code := range required {
		integration, ok := r.integrations[code]
		if !ok {
			return fmt.Errorf("required integration missing: %s", code)
		}
		if integration.Code == "" {
			return fmt.Errorf("integration code is required")
		}
		if integration.Name == "" {
			return fmt.Errorf("integration name is required for %s", integration.Code)
		}
		if integration.Category == "" {
			return fmt.Errorf("integration category is required for %s", integration.Code)
		}
		if integration.Status == "" {
			return fmt.Errorf("integration status is required for %s", integration.Code)
		}
		if len(integration.RequiredFeatures) == 0 {
			return fmt.Errorf("integration required features are required for %s", integration.Code)
		}
		if integration.RequiredLimit == "" {
			return fmt.Errorf("integration required limit is required for %s", integration.Code)
		}
	}

	return nil
}

func (r *Runtime) Integration(code IntegrationCode) (Integration, bool) {
	integration, ok := r.integrations[code]
	return integration, ok
}

func (r *Runtime) ListByCategory(category Category) []Integration {
	result := []Integration{}
	for _, integration := range r.integrations {
		if integration.Category == category {
			result = append(result, integration)
		}
	}
	return result
}

func (r *Runtime) CheckAccess(ctx RuntimeContext, integrationCode IntegrationCode) Decision {
	if decision, ok := r.validateContext(ctx); !ok {
		decision.IntegrationCode = integrationCode
		return decision
	}

	integration, ok := r.Integration(integrationCode)
	if !ok {
		return r.deny(ctx, Integration{Code: integrationCode}, "", ReasonDenyIntegrationUnknown, "integration is not defined in catalog")
	}

	if integration.Status == StatusDisabled {
		return r.deny(ctx, integration, "", ReasonDenyIntegrationDisabled, "integration is disabled")
	}

	for _, feature := range integration.RequiredFeatures {
		if !r.catalog.HasFeature(ctx.Plan, feature) {
			return r.deny(ctx, integration, feature, ReasonDenyFeatureMissing, "required feature is not included in plan")
		}
	}

	return Decision{
		Status:            entitlement.DecisionAllow,
		ReasonCode:        string(ReasonAllowIntegrationAccess),
		ReasonMessage:     "integration access is allowed",
		TenantID:          ctx.TenantID,
		UserID:            ctx.UserID,
		PlanCode:          ctx.Plan,
		IntegrationCode:   integration.Code,
		Category:          integration.Category,
		IntegrationStatus: integration.Status,
	}
}

func (r *Runtime) CheckIntegrationLimit(ctx RuntimeContext, integrationCode IntegrationCode, currentUsage int, requestedAdd int) Decision {
	if decision, ok := r.validateContext(ctx); !ok {
		decision.IntegrationCode = integrationCode
		decision.CurrentUsage = currentUsage
		decision.RequestedAdd = requestedAdd
		decision.NextUsage = currentUsage + requestedAdd
		return decision
	}

	integration, ok := r.Integration(integrationCode)
	if !ok {
		return r.denyLimit(ctx, Integration{Code: integrationCode}, currentUsage, requestedAdd, 0, ReasonDenyIntegrationUnknown, "integration is not defined in catalog")
	}

	limitValue, ok := r.catalog.Limit(ctx.Plan, integration.RequiredLimit)
	if !ok {
		return r.denyLimit(ctx, integration, currentUsage, requestedAdd, 0, ReasonDenyLimitUnknown, "required limit is not defined in plan")
	}

	nextUsage := currentUsage + requestedAdd
	if nextUsage > limitValue {
		return r.denyLimit(ctx, integration, currentUsage, requestedAdd, limitValue, ReasonDenyLimitExceeded, "integration limit would be exceeded")
	}

	return Decision{
		Status:            entitlement.DecisionAllow,
		ReasonCode:        string(ReasonAllowIntegrationLimitAvailable),
		ReasonMessage:     "integration limit is available",
		TenantID:          ctx.TenantID,
		UserID:            ctx.UserID,
		PlanCode:          ctx.Plan,
		IntegrationCode:   integration.Code,
		Category:          integration.Category,
		IntegrationStatus: integration.Status,
		LimitCode:         integration.RequiredLimit,
		LimitValue:        limitValue,
		CurrentUsage:      currentUsage,
		RequestedAdd:      requestedAdd,
		NextUsage:         nextUsage,
	}
}

func (r *Runtime) CheckAccessAndLimit(ctx RuntimeContext, integrationCode IntegrationCode, currentUsage int, requestedAdd int) Decision {
	accessDecision := r.CheckAccess(ctx, integrationCode)
	if accessDecision.Status == entitlement.DecisionDeny {
		return accessDecision
	}

	limitDecision := r.CheckIntegrationLimit(ctx, integrationCode, currentUsage, requestedAdd)
	if limitDecision.Status == entitlement.DecisionDeny {
		return limitDecision
	}

	limitDecision.FeatureCode = accessDecision.FeatureCode
	return limitDecision
}

func (r *Runtime) validateContext(ctx RuntimeContext) (Decision, bool) {
	if ctx.TenantID == "" {
		return Decision{
			Status:        entitlement.DecisionDeny,
			ReasonCode:    string(ReasonDenyTenantRequired),
			ReasonMessage: "tenant id is required",
			UserID:        ctx.UserID,
			PlanCode:      ctx.Plan,
		}, false
	}

	if ctx.UserID == "" {
		return Decision{
			Status:        entitlement.DecisionDeny,
			ReasonCode:    string(ReasonDenyUserRequired),
			ReasonMessage: "user id is required",
			TenantID:      ctx.TenantID,
			PlanCode:      ctx.Plan,
		}, false
	}

	if ctx.Plan == "" {
		return Decision{
			Status:        entitlement.DecisionDeny,
			ReasonCode:    string(ReasonDenyPlanRequired),
			ReasonMessage: "plan code is required",
			TenantID:      ctx.TenantID,
			UserID:        ctx.UserID,
		}, false
	}

	if _, ok := r.catalog.Plan(ctx.Plan); !ok {
		return Decision{
			Status:        entitlement.DecisionDeny,
			ReasonCode:    string(ReasonDenyPlanUnknown),
			ReasonMessage: "plan is not defined in catalog",
			TenantID:      ctx.TenantID,
			UserID:        ctx.UserID,
			PlanCode:      ctx.Plan,
		}, false
	}

	return Decision{}, true
}

func (r *Runtime) deny(ctx RuntimeContext, integration Integration, feature catalog.FeatureCode, reason ReasonCode, message string) Decision {
	return Decision{
		Status:            entitlement.DecisionDeny,
		ReasonCode:        string(reason),
		ReasonMessage:     message,
		TenantID:          ctx.TenantID,
		UserID:            ctx.UserID,
		PlanCode:          ctx.Plan,
		IntegrationCode:   integration.Code,
		Category:          integration.Category,
		IntegrationStatus: integration.Status,
		FeatureCode:       feature,
		LimitCode:         integration.RequiredLimit,
	}
}

func (r *Runtime) denyLimit(ctx RuntimeContext, integration Integration, currentUsage int, requestedAdd int, limitValue int, reason ReasonCode, message string) Decision {
	return Decision{
		Status:            entitlement.DecisionDeny,
		ReasonCode:        string(reason),
		ReasonMessage:     message,
		TenantID:          ctx.TenantID,
		UserID:            ctx.UserID,
		PlanCode:          ctx.Plan,
		IntegrationCode:   integration.Code,
		Category:          integration.Category,
		IntegrationStatus: integration.Status,
		LimitCode:         integration.RequiredLimit,
		LimitValue:        limitValue,
		CurrentUsage:      currentUsage,
		RequestedAdd:      requestedAdd,
		NextUsage:         currentUsage + requestedAdd,
	}
}
