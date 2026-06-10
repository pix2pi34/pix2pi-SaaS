package catalog

import (
	"errors"
	"fmt"
	"slices"
)

type PlanCode string
type FeatureCode string
type LimitCode string

const (
	PlanStarter     PlanCode = "starter"
	PlanPro         PlanCode = "pro"
	PlanEnterprise  PlanCode = "enterprise"
	PlanAccountant  PlanCode = "accountant"
	PlanMarketplace PlanCode = "marketplace"
)

const (
	FeatureERPCore              FeatureCode = "erp_core"
	FeaturePOSReady             FeatureCode = "pos_ready"
	FeatureStockBasic           FeatureCode = "stock_basic"
	FeatureStockAdvanced        FeatureCode = "stock_advanced"
	FeatureCustomerBasic        FeatureCode = "customer_basic"
	FeatureCustomerAdvanced     FeatureCode = "customer_advanced"
	FeatureReportingBasic       FeatureCode = "reporting_basic"
	FeatureReportingAdvanced    FeatureCode = "reporting_advanced"
	FeatureAPIAccessBasic       FeatureCode = "api_access_basic"
	FeatureAPIAccessAdvanced    FeatureCode = "api_access_advanced"
	FeatureMarketplaceDiscovery FeatureCode = "marketplace_discovery"
	FeatureIntegrationCatalog   FeatureCode = "integration_catalog"
	FeatureWebhookAccess        FeatureCode = "webhook_access"
	FeatureCommercialOps        FeatureCode = "commercial_ops"
	FeatureAccountantPortal     FeatureCode = "accountant_portal"
	FeatureMultiCompanyAccess   FeatureCode = "multi_company_access"
	FeatureTDHPExportReady      FeatureCode = "tdhp_export_ready"
	FeatureExportLimited        FeatureCode = "export_limited"
	FeatureExportStandard       FeatureCode = "export_standard"
	FeatureExportAdvanced       FeatureCode = "export_advanced"
	FeatureAuditAdvanced        FeatureCode = "audit_advanced"
)

const (
	LimitUsers              LimitCode = "users"
	LimitTenants            LimitCode = "tenants"
	LimitAPIMonthlyRequests LimitCode = "api_monthly_requests"
	LimitMonthlyExports     LimitCode = "monthly_exports"
	LimitAccountantFirms    LimitCode = "accountant_firms"
	LimitIntegrations       LimitCode = "integrations"
)

type Plan struct {
	Code        PlanCode
	Name        string
	Category    string
	Description string
	Features    []FeatureCode
	Limits      map[LimitCode]int
}

type Catalog struct {
	SchemaVersion string
	Phase         string
	Step          string
	Status        string
	Plans         []Plan
}

func DefaultCatalog() Catalog {
	return Catalog{
		SchemaVersion: "product_plan_catalog.v1",
		Phase:         "FAZ_7",
		Step:          "7-2",
		Status:        "READY",
		Plans: []Plan{
			{
				Code:        PlanStarter,
				Name:        "Starter",
				Category:    "business",
				Description: "Kucuk isletmeler ve pilot/demo kullanimlar icin temel SaaS paketi.",
				Features: []FeatureCode{
					FeatureERPCore,
					FeatureStockBasic,
					FeatureCustomerBasic,
					FeatureReportingBasic,
					FeatureExportLimited,
				},
				Limits: map[LimitCode]int{
					LimitUsers:              3,
					LimitTenants:            1,
					LimitAPIMonthlyRequests: 0,
					LimitMonthlyExports:     10,
					LimitAccountantFirms:    0,
					LimitIntegrations:       0,
				},
			},
			{
				Code:        PlanPro,
				Name:        "Pro",
				Category:    "business",
				Description: "Aktif isletmelerin gunluk operasyonlari icin ana ticari paket.",
				Features: []FeatureCode{
					FeatureERPCore,
					FeaturePOSReady,
					FeatureStockAdvanced,
					FeatureCustomerAdvanced,
					FeatureReportingBasic,
					FeatureReportingAdvanced,
					FeatureAPIAccessBasic,
					FeatureMarketplaceDiscovery,
					FeatureExportStandard,
				},
				Limits: map[LimitCode]int{
					LimitUsers:              15,
					LimitTenants:            1,
					LimitAPIMonthlyRequests: 50000,
					LimitMonthlyExports:     250,
					LimitAccountantFirms:    0,
					LimitIntegrations:       2,
				},
			},
			{
				Code:        PlanEnterprise,
				Name:        "Enterprise",
				Category:    "business",
				Description: "Cok subeli, yuksek hacimli ve ozel ihtiyaclari olan firmalar icin kurumsal paket.",
				Features: []FeatureCode{
					FeatureERPCore,
					FeaturePOSReady,
					FeatureStockAdvanced,
					FeatureCustomerAdvanced,
					FeatureReportingBasic,
					FeatureReportingAdvanced,
					FeatureAPIAccessAdvanced,
					FeatureMarketplaceDiscovery,
					FeatureIntegrationCatalog,
					FeatureWebhookAccess,
					FeatureCommercialOps,
					FeatureAuditAdvanced,
					FeatureExportAdvanced,
				},
				Limits: map[LimitCode]int{
					LimitUsers:              250,
					LimitTenants:            50,
					LimitAPIMonthlyRequests: 1000000,
					LimitMonthlyExports:     10000,
					LimitAccountantFirms:    0,
					LimitIntegrations:       50,
				},
			},
			{
				Code:        PlanAccountant,
				Name:        "Muhasebeci",
				Category:    "accountant",
				Description: "Bir muhasebecinin birden fazla firmaya erisebilmesi icin ticari paket.",
				Features: []FeatureCode{
					FeatureAccountantPortal,
					FeatureMultiCompanyAccess,
					FeatureExportStandard,
					FeatureExportAdvanced,
					FeatureTDHPExportReady,
					FeatureReportingBasic,
					FeatureReportingAdvanced,
				},
				Limits: map[LimitCode]int{
					LimitUsers:              20,
					LimitTenants:            100,
					LimitAPIMonthlyRequests: 100000,
					LimitMonthlyExports:     5000,
					LimitAccountantFirms:    100,
					LimitIntegrations:       5,
				},
			},
			{
				Code:        PlanMarketplace,
				Name:        "Marketplace Integration",
				Category:    "integration",
				Description: "Pazaryeri, webhook, public API ve entegrasyon kullanimlari icin paket.",
				Features: []FeatureCode{
					FeatureMarketplaceDiscovery,
					FeatureIntegrationCatalog,
					FeatureWebhookAccess,
					FeatureAPIAccessAdvanced,
					FeatureExportStandard,
					FeatureCommercialOps,
				},
				Limits: map[LimitCode]int{
					LimitUsers:              10,
					LimitTenants:            5,
					LimitAPIMonthlyRequests: 500000,
					LimitMonthlyExports:     1000,
					LimitAccountantFirms:    0,
					LimitIntegrations:       25,
				},
			},
		},
	}
}

func (c Catalog) Validate() error {
	if c.SchemaVersion == "" {
		return errors.New("schema version is required")
	}
	if c.Phase != "FAZ_7" {
		return fmt.Errorf("unexpected phase: %s", c.Phase)
	}
	if c.Step != "7-2" {
		return fmt.Errorf("unexpected step: %s", c.Step)
	}
	if c.Status != "READY" {
		return fmt.Errorf("unexpected status: %s", c.Status)
	}
	if len(c.Plans) != 5 {
		return fmt.Errorf("expected 5 plans, got %d", len(c.Plans))
	}

	seen := map[PlanCode]bool{}
	for _, plan := range c.Plans {
		if plan.Code == "" {
			return errors.New("plan code is required")
		}
		if plan.Name == "" {
			return fmt.Errorf("plan name is required for %s", plan.Code)
		}
		if seen[plan.Code] {
			return fmt.Errorf("duplicate plan code: %s", plan.Code)
		}
		seen[plan.Code] = true
		if len(plan.Features) == 0 {
			return fmt.Errorf("plan %s must have at least one feature", plan.Code)
		}
		for _, limit := range []LimitCode{
			LimitUsers,
			LimitTenants,
			LimitAPIMonthlyRequests,
			LimitMonthlyExports,
			LimitAccountantFirms,
			LimitIntegrations,
		} {
			if _, ok := plan.Limits[limit]; !ok {
				return fmt.Errorf("plan %s missing limit %s", plan.Code, limit)
			}
		}
	}

	for _, required := range []PlanCode{
		PlanStarter,
		PlanPro,
		PlanEnterprise,
		PlanAccountant,
		PlanMarketplace,
	} {
		if !seen[required] {
			return fmt.Errorf("required plan missing: %s", required)
		}
	}

	return nil
}

func (c Catalog) Plan(code PlanCode) (Plan, bool) {
	for _, plan := range c.Plans {
		if plan.Code == code {
			return plan, true
		}
	}
	return Plan{}, false
}

func (c Catalog) HasFeature(planCode PlanCode, feature FeatureCode) bool {
	plan, ok := c.Plan(planCode)
	if !ok {
		return false
	}
	return slices.Contains(plan.Features, feature)
}

func (c Catalog) Limit(planCode PlanCode, limit LimitCode) (int, bool) {
	plan, ok := c.Plan(planCode)
	if !ok {
		return 0, false
	}
	value, ok := plan.Limits[limit]
	return value, ok
}
