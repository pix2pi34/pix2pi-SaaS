#!/usr/bin/env bash
set -Eeuo pipefail

echo "===== FAZ 7-8 MARKETPLACE / INTEGRATION CATALOG FOUNDATION BASLADI ====="

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="backups/faz7/7-8_${TS}"

mkdir -p "$BACKUP_DIR"
mkdir -p docs/faz7/evidence
mkdir -p configs/faz7
mkdir -p internal/platform/commercial/integrationcatalog
mkdir -p scripts/faz7

echo
echo "===== 7-8 BACKUP ====="

backup_if_exists() {
  local path="$1"
  if [ -e "$path" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$path")"
    cp -a "$path" "$BACKUP_DIR/$path"
    echo "7-8 backup OK ✅ $path -> $BACKUP_DIR/$path"
  else
    echo "7-8 backup SKIP ✅ $path mevcut degil"
  fi
}

backup_if_exists "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md"
backup_if_exists "docs/faz7/evidence/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_EVIDENCE.md"
backup_if_exists "docs/faz7/evidence/FAZ_7_8_REAL_IMPLEMENTATION_AUDIT.md"
backup_if_exists "configs/faz7/integration_catalog.v1.json"
backup_if_exists "internal/platform/commercial/integrationcatalog/integrationcatalog.go"
backup_if_exists "internal/platform/commercial/integrationcatalog/integrationcatalog_test.go"
backup_if_exists "scripts/faz7/test_7_8_marketplace_integration_catalog_foundation.sh"
backup_if_exists "scripts/faz7/audit_7_8_real_implementation.sh"

echo "7-8 backup tamam OK ✅"

echo
echo "===== 7-8 DOSYALAR YAZILIYOR ====="

cat <<'DOC_EOF' > docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md
# 7-8 — Marketplace / Integration Catalog Foundation

## Adim Amaci

Bu adim Pix2pi icin marketplace ve entegrasyon katalog temelini kurar.

7-8 sonunda:

- Entegrasyon katalog modeli olusur.
- Parasut entegrasyon hazirligi tanimlanir.
- Pazaryeri entegrasyon hazirligi tanimlanir.
- Webhook/public API hazirligi tanimlanir.
- Entegrasyon paketleme ve upsell modeli hazirlanir.
- Plan bazli entegrasyon erisimi kontrol edilir.
- Tenant/user context zorunlu hale getirilir.
- Entegrasyon limit kontrolu yapilir.
- 7-9 Muhasebeci Portal Commercial Surface icin temel hazirlanir.

## 7-8.1 Entegrasyon Katalogu

### 7-8.1.1 Entegrasyon katalog modeli
Durum: IMPLEMENTED_OR_PRESENT

Entegrasyon katalogu her entegrasyonu su alanlarla temsil eder:

- integration_code
- integration_name
- category
- status
- required_features
- required_plan_limit
- tenant_context_required
- user_context_required
- commercial_note

### 7-8.1.2 Parasut entegrasyon hazirligi
Durum: IMPLEMENTED_OR_PRESENT

Parasut entegrasyonu muhasebe ve on muhasebe baglantisi icin katalogda hazirlik seviyesinde tutulur.

Bu adimda gercek Parasut API baglantisi acilmaz.
Sadece katalog, entitlement ve ticari paket hazirligi yapilir.

### 7-8.1.3 Pazaryeri entegrasyon hazirligi
Durum: IMPLEMENTED_OR_PRESENT

Pazaryeri entegrasyonlari discovery ve ileride siparis/stok senkronizasyonu icin hazirlik olarak modellenir.

Baslangic katalog kapsami:

- marketplace_discovery
- marketplace_orders
- marketplace_stock_sync

### 7-8.1.4 Webhook/public API hazirligi
Durum: IMPLEMENTED_OR_PRESENT

Webhook ve public API entegrasyonlari paket bazli entitlement'a baglanir.

Bu adimda:

- webhook_access feature kontrolu
- api_access_advanced feature kontrolu
- integration limit kontrolu

hazirlanir.

### 7-8.1.5 Entegrasyon paketleme ve ucretlendirme
Durum: IMPLEMENTED_OR_PRESENT

Entegrasyonlar 7-2 plan catalog ve 7-5 billing readiness ile uyumlu sekilde paketlenir.

Baslangic kurali:

- Starter: entegrasyon kapali
- Pro: marketplace discovery sinirli
- Enterprise: gelismis entegrasyonlar acik
- Accountant: muhasebe/export odakli entegrasyonlar acik
- Marketplace: marketplace/webhook/API odakli entegrasyonlar acik

## 7-8.2 Access Gate

### 7-8.2.1 Tenant context zorunlulugu
Durum: IMPLEMENTED_OR_PRESENT

tenant_id olmadan entegrasyon erisimi reddedilir.

### 7-8.2.2 User context zorunlulugu
Durum: IMPLEMENTED_OR_PRESENT

user_id olmadan entegrasyon erisimi reddedilir.

### 7-8.2.3 Plan kontrolu
Durum: IMPLEMENTED_OR_PRESENT

Plan katalogda yoksa entegrasyon erisimi reddedilir.

### 7-8.2.4 Feature kontrolu
Durum: IMPLEMENTED_OR_PRESENT

Entegrasyonun ihtiyac duydugu feature ilgili planda yoksa erisim reddedilir.

### 7-8.2.5 Entegrasyon limit kontrolu
Durum: IMPLEMENTED_OR_PRESENT

Plan integration limit asilirsa entegrasyon ekleme reddedilir.

## 7-8.3 Code Artifact

Durum: IMPLEMENTED_OR_PRESENT

Integration catalog Go modeli:

- internal/platform/commercial/integrationcatalog/integrationcatalog.go
- internal/platform/commercial/integrationcatalog/integrationcatalog_test.go

## 7-8.4 Config Artifact

Durum: IMPLEMENTED_OR_PRESENT

Integration catalog config dosyasi:

- configs/faz7/integration_catalog.v1.json

## 7-8.5 7-9 Gecis Hazirligi

Durum: IMPLEMENTED_OR_PRESENT

7-8 tamamlandiginda 7-9 icin asagidaki temeller hazirdir:

- accountant portal entegrasyon ilgisi
- tdhp_export_ready feature izi
- export entegrasyonlari
- cok firmali muhasebeci entegrasyon hazirligi
- commercial upsell modeli

## 7-8 Final Karari

- FAZ_7_8_DOC_STATUS=READY
- FAZ_7_8_CONFIG_STATUS=READY
- FAZ_7_8_CODE_STATUS=READY
- FAZ_7_8_TEST_REQUIRED=YES
- FAZ_7_8_REAL_IMPLEMENTATION_AUDIT_REQUIRED=YES
- FAZ_7_9_READY_CONDITION=FAZ_7_8_TEST_STATUS_PASS_AND_REAL_IMPLEMENTATION_STATUS_PASS
DOC_EOF

cat <<'EVIDENCE_EOF' > docs/faz7/evidence/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_EVIDENCE.md
# FAZ 7-8 Marketplace / Integration Catalog Foundation Evidence

## Evidence Summary

- 7-8 marketplace / integration catalog document created.
- Integration catalog config created.
- Go integration catalog runtime model created.
- Go integration catalog tests created.
- Test script created.
- Real implementation audit script created.
- 7-9 Muhasebeci Portal Commercial Surface is prepared as the next step.

## Evidence Files

- docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md
- docs/faz7/evidence/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_EVIDENCE.md
- configs/faz7/integration_catalog.v1.json
- internal/platform/commercial/integrationcatalog/integrationcatalog.go
- internal/platform/commercial/integrationcatalog/integrationcatalog_test.go
- scripts/faz7/test_7_8_marketplace_integration_catalog_foundation.sh
- scripts/faz7/audit_7_8_real_implementation.sh

## Initial Seal Target

- FAZ_7_8_DOC_STATUS=READY
- FAZ_7_8_CONFIG_STATUS=READY
- FAZ_7_8_CODE_STATUS=READY
- FAZ_7_8_TEST_STATUS=PENDING_UNTIL_SCRIPT_RUN
- FAZ_7_8_REAL_IMPLEMENTATION_STATUS=PENDING_UNTIL_AUDIT_RUN
EVIDENCE_EOF

cat <<'JSON_EOF' > configs/faz7/integration_catalog.v1.json
{
  "schema_version": "integration_catalog.v1",
  "phase": "FAZ_7",
  "step": "7-8",
  "runtime_status": "READY",
  "source_catalog": "configs/faz7/product_plan_catalog.v1.json",
  "source_entitlement": "configs/faz7/entitlement_feature_gate.v1.json",
  "source_billing": "configs/faz7/billing_readiness.v1.json",
  "next_step": "7-9 Muhasebeci Portal Commercial Surface",
  "integration_statuses": [
    "DISCOVERY",
    "READY",
    "GATED",
    "DISABLED"
  ],
  "categories": [
    "accounting",
    "marketplace",
    "webhook",
    "public_api",
    "export",
    "accountant"
  ],
  "required_context": {
    "tenant_id_required": true,
    "user_id_required": true,
    "plan_code_required": true
  },
  "integrations": [
    {
      "code": "parasut",
      "name": "Parasut",
      "category": "accounting",
      "status": "GATED",
      "required_features": ["integration_catalog"],
      "required_limit": "integrations",
      "commercial_note": "Gercek Parasut API baglantisi sonraki entegrasyon fazinda acilacak."
    },
    {
      "code": "marketplace_discovery",
      "name": "Marketplace Discovery",
      "category": "marketplace",
      "status": "READY",
      "required_features": ["marketplace_discovery"],
      "required_limit": "integrations",
      "commercial_note": "Pazaryeri kesif ve ticari hazirlik akisi."
    },
    {
      "code": "marketplace_orders",
      "name": "Marketplace Orders",
      "category": "marketplace",
      "status": "GATED",
      "required_features": ["integration_catalog"],
      "required_limit": "integrations",
      "commercial_note": "Siparis senkronizasyonu sonraki runtime fazina bagli."
    },
    {
      "code": "marketplace_stock_sync",
      "name": "Marketplace Stock Sync",
      "category": "marketplace",
      "status": "GATED",
      "required_features": ["integration_catalog"],
      "required_limit": "integrations",
      "commercial_note": "Stok senkronizasyonu sonraki runtime fazina bagli."
    },
    {
      "code": "webhook",
      "name": "Webhook Access",
      "category": "webhook",
      "status": "READY",
      "required_features": ["webhook_access"],
      "required_limit": "integrations",
      "commercial_note": "Webhook erisimi paket bazli entitlement ile acilir."
    },
    {
      "code": "public_api",
      "name": "Public API",
      "category": "public_api",
      "status": "READY",
      "required_features": ["api_access_advanced"],
      "required_limit": "api_monthly_requests",
      "commercial_note": "Public API ileri paketlerde acilir."
    },
    {
      "code": "tdhp_export",
      "name": "TDHP Export",
      "category": "export",
      "status": "READY",
      "required_features": ["tdhp_export_ready"],
      "required_limit": "monthly_exports",
      "commercial_note": "Muhasebeci paketi ve export temelli ticari model icin hazirlik."
    },
    {
      "code": "accountant_portal_bridge",
      "name": "Accountant Portal Bridge",
      "category": "accountant",
      "status": "READY",
      "required_features": ["accountant_portal"],
      "required_limit": "accountant_firms",
      "commercial_note": "7-9 muhasebeci portal ticari yuzeyi icin hazirlik."
    }
  ],
  "plan_packaging_rules": {
    "starter": {
      "integration_access": "disabled",
      "upsell_target": "pro"
    },
    "pro": {
      "integration_access": "marketplace_discovery_limited",
      "upsell_target": "enterprise"
    },
    "enterprise": {
      "integration_access": "advanced",
      "upsell_target": "custom"
    },
    "accountant": {
      "integration_access": "accounting_export_focused",
      "upsell_target": "enterprise"
    },
    "marketplace": {
      "integration_access": "marketplace_api_webhook_focused",
      "upsell_target": "enterprise"
    }
  },
  "decision_model": {
    "allow_status": "ALLOW",
    "deny_status": "DENY",
    "reason_codes": [
      "ALLOW_INTEGRATION_ACCESS",
      "ALLOW_INTEGRATION_LIMIT_AVAILABLE",
      "DENY_TENANT_REQUIRED",
      "DENY_USER_REQUIRED",
      "DENY_PLAN_REQUIRED",
      "DENY_PLAN_UNKNOWN",
      "DENY_INTEGRATION_UNKNOWN",
      "DENY_INTEGRATION_DISABLED",
      "DENY_FEATURE_NOT_INCLUDED",
      "DENY_LIMIT_UNKNOWN",
      "DENY_LIMIT_EXCEEDED"
    ]
  }
}
JSON_EOF

cat <<'GO_EOF' > internal/platform/commercial/integrationcatalog/integrationcatalog.go
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
GO_EOF

cat <<'GO_TEST_EOF' > internal/platform/commercial/integrationcatalog/integrationcatalog_test.go
package integrationcatalog

import (
	"testing"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/catalog"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/entitlement"
)

func mustRuntime(t *testing.T) *Runtime {
	t.Helper()

	runtime, err := NewDefaultRuntime()
	if err != nil {
		t.Fatalf("expected runtime to initialize, got error: %v", err)
	}

	return runtime
}

func baseContext(plan catalog.PlanCode) RuntimeContext {
	return RuntimeContext{
		TenantID: "tenant_7",
		UserID:   "user_1",
		Plan:     plan,
	}
}

func TestRuntime_Validate(t *testing.T) {
	runtime := mustRuntime(t)

	if err := runtime.Validate(); err != nil {
		t.Fatalf("expected runtime to validate, got error: %v", err)
	}
}

func TestRuntime_RequiredIntegrationsExist(t *testing.T) {
	runtime := mustRuntime(t)

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
		if _, ok := runtime.Integration(code); !ok {
			t.Fatalf("expected integration to exist: %s", code)
		}
	}
}

func TestRuntime_ListByCategory(t *testing.T) {
	runtime := mustRuntime(t)

	marketplaceIntegrations := runtime.ListByCategory(CategoryMarketplace)

	if len(marketplaceIntegrations) < 3 {
		t.Fatalf("expected at least 3 marketplace integrations, got %d", len(marketplaceIntegrations))
	}
}

func TestRuntime_CheckAccess_AllowsEnterpriseParasut(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccess(baseContext(catalog.PlanEnterprise), IntegrationParasut)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if decision.IntegrationCode != IntegrationParasut {
		t.Fatalf("expected parasut integration, got %s", decision.IntegrationCode)
	}
}

func TestRuntime_CheckAccess_DeniesStarterParasut(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccess(baseContext(catalog.PlanStarter), IntegrationParasut)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyFeatureMissing) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckAccess_AllowsProMarketplaceDiscovery(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccess(baseContext(catalog.PlanPro), IntegrationMarketplaceDiscovery)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
}

func TestRuntime_CheckAccess_AllowsMarketplaceWebhook(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccess(baseContext(catalog.PlanMarketplace), IntegrationWebhook)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
}

func TestRuntime_CheckAccess_AllowsAccountantTDHPExport(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccess(baseContext(catalog.PlanAccountant), IntegrationTDHPExport)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
}

func TestRuntime_CheckAccess_RequiresTenant(t *testing.T) {
	runtime := mustRuntime(t)

	ctx := baseContext(catalog.PlanEnterprise)
	ctx.TenantID = ""

	decision := runtime.CheckAccess(ctx, IntegrationParasut)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyTenantRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckAccess_RequiresUser(t *testing.T) {
	runtime := mustRuntime(t)

	ctx := baseContext(catalog.PlanEnterprise)
	ctx.UserID = ""

	decision := runtime.CheckAccess(ctx, IntegrationParasut)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyUserRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckAccess_DeniesUnknownPlan(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccess(baseContext(catalog.PlanCode("unknown")), IntegrationParasut)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyPlanUnknown) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckAccess_DeniesUnknownIntegration(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccess(baseContext(catalog.PlanEnterprise), IntegrationCode("unknown"))

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyIntegrationUnknown) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckIntegrationLimit_AllowsWithinLimit(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckIntegrationLimit(baseContext(catalog.PlanMarketplace), IntegrationWebhook, 24, 1)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if decision.NextUsage != 25 {
		t.Fatalf("expected next usage 25, got %d", decision.NextUsage)
	}
}

func TestRuntime_CheckIntegrationLimit_DeniesExceededLimit(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckIntegrationLimit(baseContext(catalog.PlanMarketplace), IntegrationWebhook, 25, 1)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyLimitExceeded) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckAccessAndLimit_Allows(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccessAndLimit(baseContext(catalog.PlanMarketplace), IntegrationWebhook, 24, 1)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if decision.IntegrationCode != IntegrationWebhook {
		t.Fatalf("expected webhook integration, got %s", decision.IntegrationCode)
	}
}

func TestRuntime_CheckAccessAndLimit_DeniesFeatureFirst(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccessAndLimit(baseContext(catalog.PlanStarter), IntegrationWebhook, 0, 1)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyFeatureMissing) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}
GO_TEST_EOF

cat <<'TEST_EOF' > scripts/faz7/test_7_8_marketplace_integration_catalog_foundation.sh
#!/usr/bin/env bash
set -Eeuo pipefail

FAIL_COUNT=0
PASS_COUNT=0

ok() {
  PASS_COUNT=$((PASS_COUNT+1))
  echo "$1 OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT+1))
  echo "$1 HATA ❌"
}

check_file() {
  local label="$1"
  local path="$2"
  if [ -f "$path" ]; then
    ok "$label file mevcut: $path"
  else
    fail "$label file eksik: $path"
  fi
}

check_grep() {
  local label="$1"
  local path="$2"
  local pattern="$3"
  if [ -f "$path" ] && grep -Fq "$pattern" "$path"; then
    ok "$label bulundu"
  else
    fail "$label bulunamadi"
  fi
}

echo "===== FAZ 7-8 TEST BASLADI ====="

check_file "7-8" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md"
check_file "7-8" "docs/faz7/evidence/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_EVIDENCE.md"
check_file "7-8" "configs/faz7/integration_catalog.v1.json"
check_file "7-8" "internal/platform/commercial/integrationcatalog/integrationcatalog.go"
check_file "7-8" "internal/platform/commercial/integrationcatalog/integrationcatalog_test.go"
check_file "7-8" "scripts/faz7/test_7_8_marketplace_integration_catalog_foundation.sh"
check_file "7-8" "scripts/faz7/audit_7_8_real_implementation.sh"

check_grep "7-8.1 Entegrasyon katalogu" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-8.1 Entegrasyon Katalogu"
check_grep "7-8.1.1 Entegrasyon katalog modeli" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-8.1.1 Entegrasyon katalog modeli"
check_grep "7-8.1.2 Parasut entegrasyon hazirligi" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-8.1.2 Parasut entegrasyon hazirligi"
check_grep "7-8.1.3 Pazaryeri entegrasyon hazirligi" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-8.1.3 Pazaryeri entegrasyon hazirligi"
check_grep "7-8.1.4 Webhook public API hazirligi" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-8.1.4 Webhook/public API hazirligi"
check_grep "7-8.1.5 Paketleme ucretlendirme" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-8.1.5 Entegrasyon paketleme ve ucretlendirme"
check_grep "7-8.2 Access gate" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-8.2 Access Gate"
check_grep "7-8.3 Code artifact" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "internal/platform/commercial/integrationcatalog/integrationcatalog.go"
check_grep "7-8.4 Config artifact" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "configs/faz7/integration_catalog.v1.json"
check_grep "7-8.5 7-9 hazirlik" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-9"

check_grep "7-8 config schema" "configs/faz7/integration_catalog.v1.json" "integration_catalog.v1"
check_grep "7-8 config parasut" "configs/faz7/integration_catalog.v1.json" "\"code\": \"parasut\""
check_grep "7-8 config marketplace discovery" "configs/faz7/integration_catalog.v1.json" "\"code\": \"marketplace_discovery\""
check_grep "7-8 config webhook" "configs/faz7/integration_catalog.v1.json" "\"code\": \"webhook\""
check_grep "7-8 config public api" "configs/faz7/integration_catalog.v1.json" "\"code\": \"public_api\""
check_grep "7-8 config tdhp export" "configs/faz7/integration_catalog.v1.json" "\"code\": \"tdhp_export\""
check_grep "7-8 config accountant bridge" "configs/faz7/integration_catalog.v1.json" "\"code\": \"accountant_portal_bridge\""

check_grep "7-8 code Integration struct" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "type Integration struct"
check_grep "7-8 code RuntimeContext" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "type RuntimeContext struct"
check_grep "7-8 code Runtime" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "type Runtime struct"
check_grep "7-8 code CheckAccess" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "CheckAccess"
check_grep "7-8 code CheckIntegrationLimit" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "CheckIntegrationLimit"
check_grep "7-8 code CheckAccessAndLimit" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "CheckAccessAndLimit"
check_grep "7-8 code catalog integration" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "commercial/catalog"

echo
echo "===== 7-8 JSON CONFIG VALIDATION ====="
if python3 - <<'PY'
import json
from pathlib import Path

path = Path("configs/faz7/integration_catalog.v1.json")
data = json.loads(path.read_text(encoding="utf-8"))

if data.get("schema_version") != "integration_catalog.v1":
    raise SystemExit("schema_version mismatch")

if data.get("phase") != "FAZ_7":
    raise SystemExit("phase mismatch")

if data.get("step") != "7-8":
    raise SystemExit("step mismatch")

if data.get("runtime_status") != "READY":
    raise SystemExit("runtime_status mismatch")

required_categories = {"accounting", "marketplace", "webhook", "public_api", "export", "accountant"}
categories = set(data.get("categories", []))
missing_categories = required_categories - categories
if missing_categories:
    raise SystemExit(f"missing categories: {sorted(missing_categories)}")

ctx = data.get("required_context", {})
for key in ["tenant_id_required", "user_id_required", "plan_code_required"]:
    if ctx.get(key) is not True:
        raise SystemExit(f"context gate missing: {key}")

required_integrations = {
    "parasut",
    "marketplace_discovery",
    "marketplace_orders",
    "marketplace_stock_sync",
    "webhook",
    "public_api",
    "tdhp_export",
    "accountant_portal_bridge",
}
integrations = {item["code"]: item for item in data.get("integrations", [])}
missing_integrations = required_integrations - set(integrations.keys())
if missing_integrations:
    raise SystemExit(f"missing integrations: {sorted(missing_integrations)}")

for code, item in integrations.items():
    if not item.get("required_features"):
        raise SystemExit(f"required_features missing for {code}")
    if not item.get("required_limit"):
        raise SystemExit(f"required_limit missing for {code}")

required_rules = {"starter", "pro", "enterprise", "accountant", "marketplace"}
rules = set(data.get("plan_packaging_rules", {}).keys())
missing_rules = required_rules - rules
if missing_rules:
    raise SystemExit(f"missing plan packaging rules: {sorted(missing_rules)}")

required_reasons = {
    "ALLOW_INTEGRATION_ACCESS",
    "ALLOW_INTEGRATION_LIMIT_AVAILABLE",
    "DENY_TENANT_REQUIRED",
    "DENY_USER_REQUIRED",
    "DENY_PLAN_REQUIRED",
    "DENY_PLAN_UNKNOWN",
    "DENY_INTEGRATION_UNKNOWN",
    "DENY_INTEGRATION_DISABLED",
    "DENY_FEATURE_NOT_INCLUDED",
    "DENY_LIMIT_UNKNOWN",
    "DENY_LIMIT_EXCEEDED",
}
reasons = set(data.get("decision_model", {}).get("reason_codes", []))
missing_reasons = required_reasons - reasons
if missing_reasons:
    raise SystemExit(f"missing reason codes: {sorted(missing_reasons)}")

print("JSON_OK")
PY
then
  ok "7-8 JSON config parse ve integration gate kontrolu"
else
  fail "7-8 JSON config parse ve integration gate kontrolu"
fi

echo
echo "===== 7-8 GO TEST ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/integrationcatalog -v; then
    ok "7-8 Go integration catalog unit testleri"
  else
    fail "7-8 Go integration catalog unit testleri"
  fi
else
  fail "7-8 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-8 TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_8_TEST_STATUS=PASS ✅"
  echo "OK ✅ FAZ 7-8 testleri basariyla gecti"
else
  echo "FAZ_7_8_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-8 testlerinde hata var"
  exit 1
fi
TEST_EOF

cat <<'AUDIT_EOF' > scripts/faz7/audit_7_8_real_implementation.sh
#!/usr/bin/env bash
set -Eeuo pipefail

FAIL_COUNT=0
PASS_COUNT=0
OPTIONAL_WARN=0
AUDIT_FILE="docs/faz7/evidence/FAZ_7_8_REAL_IMPLEMENTATION_AUDIT.md"

mkdir -p docs/faz7/evidence

ok() {
  PASS_COUNT=$((PASS_COUNT+1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT+1))
  echo "$1 REQUIRED_FAIL ❌"
}

warn() {
  OPTIONAL_WARN=$((OPTIONAL_WARN+1))
  echo "$1 OPTIONAL_WARN ⚠️"
}

has_file() {
  local label="$1"
  local path="$2"
  if [ -f "$path" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

has_text() {
  local label="$1"
  local path="$2"
  local pattern="$3"
  if [ -f "$path" ] && grep -Fq "$pattern" "$path"; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 7-8 REAL IMPLEMENTATION AUDIT BASLADI ====="

has_file "7-8.1 Marketplace integration catalog dokumani" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md"
has_file "7-8.2 Evidence dokumani" "docs/faz7/evidence/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_EVIDENCE.md"
has_file "7-8.3 Integration catalog config" "configs/faz7/integration_catalog.v1.json"
has_file "7-8.4 Go integration catalog runtime modeli" "internal/platform/commercial/integrationcatalog/integrationcatalog.go"
has_file "7-8.5 Go integration catalog testleri" "internal/platform/commercial/integrationcatalog/integrationcatalog_test.go"
has_file "7-8.6 Test scripti" "scripts/faz7/test_7_8_marketplace_integration_catalog_foundation.sh"
has_file "7-8.7 Real implementation audit scripti" "scripts/faz7/audit_7_8_real_implementation.sh"

has_text "7-8.1.1 Entegrasyon katalog modeli dokuman karsiligi" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "Entegrasyon katalog modeli"
has_text "7-8.1.2 Parasut hazirligi dokuman karsiligi" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "Parasut entegrasyon hazirligi"
has_text "7-8.1.3 Pazaryeri hazirligi dokuman karsiligi" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "Pazaryeri entegrasyon hazirligi"
has_text "7-8.1.4 Webhook public API hazirligi dokuman karsiligi" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "Webhook/public API hazirligi"
has_text "7-8.1.5 Paketleme ucretlendirme dokuman karsiligi" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "Entegrasyon paketleme ve ucretlendirme"

has_text "7-8 config parasut karsiligi" "configs/faz7/integration_catalog.v1.json" "\"code\": \"parasut\""
has_text "7-8 config marketplace discovery karsiligi" "configs/faz7/integration_catalog.v1.json" "\"code\": \"marketplace_discovery\""
has_text "7-8 config marketplace orders karsiligi" "configs/faz7/integration_catalog.v1.json" "\"code\": \"marketplace_orders\""
has_text "7-8 config marketplace stock sync karsiligi" "configs/faz7/integration_catalog.v1.json" "\"code\": \"marketplace_stock_sync\""
has_text "7-8 config webhook karsiligi" "configs/faz7/integration_catalog.v1.json" "\"code\": \"webhook\""
has_text "7-8 config public api karsiligi" "configs/faz7/integration_catalog.v1.json" "\"code\": \"public_api\""
has_text "7-8 config tdhp export karsiligi" "configs/faz7/integration_catalog.v1.json" "\"code\": \"tdhp_export\""
has_text "7-8 config accountant bridge karsiligi" "configs/faz7/integration_catalog.v1.json" "\"code\": \"accountant_portal_bridge\""

has_text "7-8 code Integration karsiligi" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "type Integration struct"
has_text "7-8 code Runtime karsiligi" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "type Runtime struct"
has_text "7-8 code CheckAccess karsiligi" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "CheckAccess"
has_text "7-8 code CheckIntegrationLimit karsiligi" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "CheckIntegrationLimit"
has_text "7-8 code CheckAccessAndLimit karsiligi" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "CheckAccessAndLimit"
has_text "7-8 code IntegrationParasut karsiligi" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "IntegrationParasut"
has_text "7-8 code IntegrationTDHPExport karsiligi" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "IntegrationTDHPExport"
has_text "7-8 code catalog integration karsiligi" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "commercial/catalog"

echo
echo "===== 7-8 AUDIT GO TEST VERIFICATION ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/integrationcatalog -v >/tmp/faz7_8_integrationcatalog_go_test.log 2>&1; then
    ok "7-8 Go test real implementation verification"
  else
    cat /tmp/faz7_8_integrationcatalog_go_test.log || true
    fail "7-8 Go test real implementation verification"
  fi
else
  fail "7-8 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-8 REAL IMPLEMENTATION AUDIT OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "REQUIRED_FAIL=$FAIL_COUNT"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"

if [ "$FAIL_COUNT" -eq 0 ]; then
  STATUS="PASS"
  STATUS_ICON="✅"
else
  STATUS="FAIL"
  STATUS_ICON="❌"
fi

cat > "$AUDIT_FILE" <<AUDIT_REPORT
# FAZ 7-8 Real Implementation Audit

## Audit Summary

PASS_COUNT=$PASS_COUNT
REQUIRED_FAIL=$FAIL_COUNT
OPTIONAL_WARN=$OPTIONAL_WARN
FAZ_7_8_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
FAZ_7_8_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅

## Checked Implementation Evidence

- docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md
- docs/faz7/evidence/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_EVIDENCE.md
- configs/faz7/integration_catalog.v1.json
- internal/platform/commercial/integrationcatalog/integrationcatalog.go
- internal/platform/commercial/integrationcatalog/integrationcatalog_test.go
- scripts/faz7/test_7_8_marketplace_integration_catalog_foundation.sh
- scripts/faz7/audit_7_8_real_implementation.sh

## Real Implementation Decision

7-8 real implementation audit confirms that marketplace/integration catalog foundation, Parasut preparation, marketplace preparation, webhook/public API preparation, TDHP export preparation, accountant portal bridge preparation, plan based access gate, tenant/user context validation, integration limit gate, config, Go tests, test script and audit script exist as real code/config/script/document artifacts.

## Final Status

FAZ_7_8_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
AUDIT_REPORT

echo "OK ✅ evidence yazildi: $AUDIT_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_8_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_7_8_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo "OK ✅ FAZ 7-8 real implementation audit basariyla gecti"
else
  echo "FAZ_7_8_REAL_IMPLEMENTATION_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-8 real implementation audit basarisiz"
  exit 1
fi
AUDIT_EOF

chmod +x scripts/faz7/test_7_8_marketplace_integration_catalog_foundation.sh
chmod +x scripts/faz7/audit_7_8_real_implementation.sh

echo "OK ✅ docs/config/code/test/audit dosyalari yazildi"

echo
echo "===== 7-8 TEST CALISIYOR ====="
bash scripts/faz7/test_7_8_marketplace_integration_catalog_foundation.sh

echo
echo "===== 7-8 REAL IMPLEMENTATION AUDIT CALISIYOR ====="
bash scripts/faz7/audit_7_8_real_implementation.sh

echo
echo "===== FAZ 7-8 FINAL OZET ====="
echo "FAZ_7_8_DOC_STATUS=READY ✅"
echo "FAZ_7_8_CONFIG_STATUS=READY ✅"
echo "FAZ_7_8_CODE_STATUS=READY ✅"
echo "FAZ_7_8_TEST_STATUS=PASS ✅"
echo "FAZ_7_8_REAL_IMPLEMENTATION_STATUS=PASS ✅"
echo "FAZ_7_8_FINAL_STATUS=PASS ✅"
echo "FAZ_7_9_READY=YES ✅"
echo "OK ✅ FAZ 7-8 Marketplace / Integration Catalog Foundation tamamlandi"
