#!/usr/bin/env bash
set -Eeuo pipefail

echo "===== FAZ 7-2 PRODUCT PACKAGING / PLAN CATALOG BASLADI ====="

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="backups/faz7/7-2_${TS}"

mkdir -p "$BACKUP_DIR"
mkdir -p docs/faz7/evidence
mkdir -p configs/faz7
mkdir -p internal/platform/commercial/catalog
mkdir -p scripts/faz7

echo
echo "===== 7-2 BACKUP ====="

backup_if_exists() {
  local path="$1"
  if [ -e "$path" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$path")"
    cp -a "$path" "$BACKUP_DIR/$path"
    echo "7-2 backup OK ✅ $path -> $BACKUP_DIR/$path"
  else
    echo "7-2 backup SKIP ✅ $path mevcut degil"
  fi
}

backup_if_exists "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md"
backup_if_exists "docs/faz7/evidence/FAZ_7_2_PRODUCT_PACKAGING_EVIDENCE.md"
backup_if_exists "docs/faz7/evidence/FAZ_7_2_REAL_IMPLEMENTATION_AUDIT.md"
backup_if_exists "configs/faz7/product_plan_catalog.v1.json"
backup_if_exists "internal/platform/commercial/catalog/catalog.go"
backup_if_exists "internal/platform/commercial/catalog/catalog_test.go"
backup_if_exists "scripts/faz7/test_7_2_product_packaging_plan_catalog.sh"
backup_if_exists "scripts/faz7/audit_7_2_real_implementation.sh"

echo "7-2 backup tamam OK ✅"

echo
echo "===== 7-2 DOSYALAR YAZILIYOR ====="

cat <<'DOC_EOF' > docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md
# 7-2 — Product Packaging / Plan Catalog

## Adim Amaci

Bu adim Pix2pi icin urun paketlerini, plan katalogunu, feature matrix yapisini ve limit kurallarini sabitler.

7-2 sonunda:

- Starter paket tanimlanir.
- Pro paket tanimlanir.
- Enterprise paket tanimlanir.
- Muhasebeci paketi tanimlanir.
- Marketplace / entegrasyon paketi tanimlanir.
- Feature matrix olusturulur.
- Kullanici, tenant, API ve export limitleri tanimlanir.
- 7-3 Entitlement Runtime / Feature Gate icin hazirlik yapilir.

## 7-2.1 Paket Mimarisi

### 7-2.1.1 Starter Paket
Durum: IMPLEMENTED_OR_PRESENT

Starter paket, kucuk isletmeler ve ilk pilot/demo kullanimlar icin temel SaaS paketidir.

Ana haklar:

- Temel ERP yuzeyi
- Temel stok takibi
- Temel cari yonetimi
- Temel rapor goruntuleme
- Sinirli kullanici hakki
- Sinirli export hakki
- API erisimi kapali veya sinirli

### 7-2.1.2 Pro Paket
Durum: IMPLEMENTED_OR_PRESENT

Pro paket, aktif isletmelerin gunluk operasyonlari icin ana ticari pakettir.

Ana haklar:

- ERP core
- POS hazirligi
- Gelismis stok
- Gelismis rapor
- API temel erisim
- Marketplace discovery erisimi
- Daha yuksek kullanici limiti

### 7-2.1.3 Enterprise Paket
Durum: IMPLEMENTED_OR_PRESENT

Enterprise paket, cok subeli, yuksek hacimli ve ozel ihtiyaclari olan firmalar icin kurumsal pakettir.

Ana haklar:

- Tum Pro haklari
- Yuksek kullanici limiti
- Yuksek API limiti
- Ozel entegrasyon hazirligi
- SLA / support hazirligi
- Gelismis audit ve ops gorunumu

### 7-2.1.4 Muhasebeci Paketi
Durum: IMPLEMENTED_OR_PRESENT

Muhasebeci paketi, bir muhasebecinin birden fazla firmaya erisim saglayabilmesi icin ticari modeldir.

Ana haklar:

- Cok firmali erisim
- Firma basi yetkilendirme
- Excel/PDF/TDHP export hazirligi
- Firma basi aylik hak modeli
- Muhasebeci portal entitlement hazirligi

### 7-2.1.5 Marketplace / Entegrasyon Paketi
Durum: IMPLEMENTED_OR_PRESENT

Marketplace / entegrasyon paketi, pazaryeri, Paraşut benzeri entegrasyonlar, webhook ve public API kullanimlari icin hazirlik paketidir.

Ana haklar:

- Entegrasyon katalogu
- Webhook hazirligi
- Public API hazirligi
- Pazaryeri entegrasyon hazirligi
- Entegrasyon bazli upsell modeli

## 7-2.2 Feature Matrix

### 7-2.2.1 Modul Bazli Yetki
Durum: IMPLEMENTED_OR_PRESENT

Her paket hangi modulun acik veya kapali oldugunu acik sekilde tasir.

Modul ornekleri:

- erp_core
- pos_ready
- reporting_basic
- reporting_advanced
- api_access
- marketplace_discovery
- accountant_portal
- integration_catalog
- webhook_access
- commercial_ops

### 7-2.2.2 Kullanici Limiti
Durum: IMPLEMENTED_OR_PRESENT

Her paketin kullanici sayisi limiti ayridir.

Baslangic modeli:

- Starter: 3 kullanici
- Pro: 15 kullanici
- Enterprise: 250 kullanici
- Accountant: 20 kullanici
- Marketplace: 10 kullanici

### 7-2.2.3 Tenant Limiti
Durum: IMPLEMENTED_OR_PRESENT

Her paket kac tenant/firma yonetebilecegini belirtir.

Baslangic modeli:

- Starter: 1 tenant
- Pro: 1 tenant
- Enterprise: 50 tenant veya sube/firma kapsami
- Accountant: 100 firma baglantisi
- Marketplace: 5 entegrasyon tenant kapsami

### 7-2.2.4 API Hakki
Durum: IMPLEMENTED_OR_PRESENT

API hakki paket bazli belirlenir.

Baslangic modeli:

- Starter: 0 veya cok sinirli
- Pro: temel API
- Enterprise: yuksek API
- Accountant: export odakli API
- Marketplace: entegrasyon odakli API

### 7-2.2.5 Export Hakki
Durum: IMPLEMENTED_OR_PRESENT

Export hakki paket bazli belirlenir.

Baslangic modeli:

- Starter: sinirli export
- Pro: standart export
- Enterprise: gelismis export
- Accountant: cok firmali export
- Marketplace: entegrasyon veri cikisi

### 7-2.2.6 Muhasebeci Erisim Hakki
Durum: IMPLEMENTED_OR_PRESENT

Muhasebeci erisimi sadece ilgili paket veya entitlement ile acilir.

## 7-2.3 Plan Catalog Config

Durum: IMPLEMENTED_OR_PRESENT

Plan catalog config dosyasi:

- configs/faz7/product_plan_catalog.v1.json

Bu dosya 7-3 entitlement runtime icin kaynak olarak kullanilacaktir.

## 7-2.4 Code Artifact

Durum: IMPLEMENTED_OR_PRESENT

Plan catalog Go modeli:

- internal/platform/commercial/catalog/catalog.go
- internal/platform/commercial/catalog/catalog_test.go

Bu model paketlerin ve feature matrix kurallarinin kod karsiligidir.

## 7-2.5 7-3 Gecis Hazirligi

Durum: IMPLEMENTED_OR_PRESENT

7-2 tamamlandiginda 7-3 icin asagidaki bilgiler hazirdir:

- Plan kodlari
- Feature kodlari
- Limit kodlari
- Plan-feature iliskisi
- Plan-limit iliskisi
- Entitlement runtime icin temel source of truth

## 7-2 Final Karari

- FAZ_7_2_DOC_STATUS=READY
- FAZ_7_2_CONFIG_STATUS=READY
- FAZ_7_2_CODE_STATUS=READY
- FAZ_7_2_TEST_REQUIRED=YES
- FAZ_7_2_REAL_IMPLEMENTATION_AUDIT_REQUIRED=YES
- FAZ_7_3_READY_CONDITION=FAZ_7_2_TEST_STATUS_PASS_AND_REAL_IMPLEMENTATION_STATUS_PASS
DOC_EOF

cat <<'EVIDENCE_EOF' > docs/faz7/evidence/FAZ_7_2_PRODUCT_PACKAGING_EVIDENCE.md
# FAZ 7-2 Product Packaging / Plan Catalog Evidence

## Evidence Summary

- 7-2 product packaging document created.
- Plan catalog config created.
- Go catalog model created.
- Go catalog tests created.
- Test script created.
- Real implementation audit script created.
- 7-3 Entitlement Runtime / Feature Gate is prepared as the next step.

## Evidence Files

- docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md
- docs/faz7/evidence/FAZ_7_2_PRODUCT_PACKAGING_EVIDENCE.md
- configs/faz7/product_plan_catalog.v1.json
- internal/platform/commercial/catalog/catalog.go
- internal/platform/commercial/catalog/catalog_test.go
- scripts/faz7/test_7_2_product_packaging_plan_catalog.sh
- scripts/faz7/audit_7_2_real_implementation.sh

## Initial Seal Target

- FAZ_7_2_DOC_STATUS=READY
- FAZ_7_2_CONFIG_STATUS=READY
- FAZ_7_2_CODE_STATUS=READY
- FAZ_7_2_TEST_STATUS=PENDING_UNTIL_SCRIPT_RUN
- FAZ_7_2_REAL_IMPLEMENTATION_STATUS=PENDING_UNTIL_AUDIT_RUN
EVIDENCE_EOF

cat <<'JSON_EOF' > configs/faz7/product_plan_catalog.v1.json
{
  "schema_version": "product_plan_catalog.v1",
  "phase": "FAZ_7",
  "step": "7-2",
  "catalog_status": "READY",
  "next_step": "7-3 Entitlement Runtime / Feature Gate",
  "plans": [
    {
      "code": "starter",
      "name": "Starter",
      "category": "business",
      "description": "Kucuk isletmeler ve pilot/demo kullanimlar icin temel SaaS paketi.",
      "features": [
        "erp_core",
        "stock_basic",
        "customer_basic",
        "reporting_basic",
        "export_limited"
      ],
      "limits": {
        "users": 3,
        "tenants": 1,
        "api_monthly_requests": 0,
        "monthly_exports": 10,
        "accountant_firms": 0,
        "integrations": 0
      }
    },
    {
      "code": "pro",
      "name": "Pro",
      "category": "business",
      "description": "Aktif isletmelerin gunluk operasyonlari icin ana ticari paket.",
      "features": [
        "erp_core",
        "pos_ready",
        "stock_advanced",
        "customer_advanced",
        "reporting_basic",
        "reporting_advanced",
        "api_access_basic",
        "marketplace_discovery",
        "export_standard"
      ],
      "limits": {
        "users": 15,
        "tenants": 1,
        "api_monthly_requests": 50000,
        "monthly_exports": 250,
        "accountant_firms": 0,
        "integrations": 2
      }
    },
    {
      "code": "enterprise",
      "name": "Enterprise",
      "category": "business",
      "description": "Cok subeli, yuksek hacimli ve ozel ihtiyaclari olan firmalar icin kurumsal paket.",
      "features": [
        "erp_core",
        "pos_ready",
        "stock_advanced",
        "customer_advanced",
        "reporting_basic",
        "reporting_advanced",
        "api_access_advanced",
        "marketplace_discovery",
        "integration_catalog",
        "webhook_access",
        "commercial_ops",
        "audit_advanced",
        "export_advanced"
      ],
      "limits": {
        "users": 250,
        "tenants": 50,
        "api_monthly_requests": 1000000,
        "monthly_exports": 10000,
        "accountant_firms": 0,
        "integrations": 50
      }
    },
    {
      "code": "accountant",
      "name": "Muhasebeci",
      "category": "accountant",
      "description": "Bir muhasebecinin birden fazla firmaya erisebilmesi icin ticari paket.",
      "features": [
        "accountant_portal",
        "multi_company_access",
        "export_standard",
        "export_advanced",
        "tdhp_export_ready",
        "reporting_basic",
        "reporting_advanced"
      ],
      "limits": {
        "users": 20,
        "tenants": 100,
        "api_monthly_requests": 100000,
        "monthly_exports": 5000,
        "accountant_firms": 100,
        "integrations": 5
      }
    },
    {
      "code": "marketplace",
      "name": "Marketplace Integration",
      "category": "integration",
      "description": "Pazaryeri, webhook, public API ve entegrasyon kullanimlari icin paket.",
      "features": [
        "marketplace_discovery",
        "integration_catalog",
        "webhook_access",
        "api_access_advanced",
        "export_standard",
        "commercial_ops"
      ],
      "limits": {
        "users": 10,
        "tenants": 5,
        "api_monthly_requests": 500000,
        "monthly_exports": 1000,
        "accountant_firms": 0,
        "integrations": 25
      }
    }
  ],
  "required_features": [
    "erp_core",
    "reporting_basic",
    "export_limited",
    "export_standard",
    "export_advanced",
    "api_access_basic",
    "api_access_advanced",
    "accountant_portal",
    "integration_catalog",
    "webhook_access",
    "marketplace_discovery",
    "commercial_ops"
  ],
  "launch_gates": {
    "real_payment_requires_financial_approval": true,
    "public_launch_requires_legal_approval": true,
    "public_launch_requires_kvkk_approval": true,
    "public_launch_requires_cloudflare_green_mode": true,
    "public_launch_requires_waf_rate_limit": true
  }
}
JSON_EOF

cat <<'GO_EOF' > internal/platform/commercial/catalog/catalog.go
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
GO_EOF

cat <<'GO_TEST_EOF' > internal/platform/commercial/catalog/catalog_test.go
package catalog

import "testing"

func TestDefaultCatalog_Validate(t *testing.T) {
	c := DefaultCatalog()

	if err := c.Validate(); err != nil {
		t.Fatalf("expected catalog to validate, got error: %v", err)
	}
}

func TestDefaultCatalog_PlansExist(t *testing.T) {
	c := DefaultCatalog()

	requiredPlans := []PlanCode{
		PlanStarter,
		PlanPro,
		PlanEnterprise,
		PlanAccountant,
		PlanMarketplace,
	}

	for _, planCode := range requiredPlans {
		if _, ok := c.Plan(planCode); !ok {
			t.Fatalf("expected plan to exist: %s", planCode)
		}
	}
}

func TestDefaultCatalog_FeatureMatrix(t *testing.T) {
	c := DefaultCatalog()

	if !c.HasFeature(PlanStarter, FeatureERPCore) {
		t.Fatal("starter must have erp_core")
	}

	if c.HasFeature(PlanStarter, FeatureAPIAccessAdvanced) {
		t.Fatal("starter must not have advanced api access")
	}

	if !c.HasFeature(PlanPro, FeatureMarketplaceDiscovery) {
		t.Fatal("pro must have marketplace discovery")
	}

	if !c.HasFeature(PlanEnterprise, FeatureWebhookAccess) {
		t.Fatal("enterprise must have webhook access")
	}
}

func TestDefaultCatalog_AccountantPlan(t *testing.T) {
	c := DefaultCatalog()

	if !c.HasFeature(PlanAccountant, FeatureAccountantPortal) {
		t.Fatal("accountant plan must have accountant portal")
	}

	if !c.HasFeature(PlanAccountant, FeatureMultiCompanyAccess) {
		t.Fatal("accountant plan must have multi company access")
	}

	firms, ok := c.Limit(PlanAccountant, LimitAccountantFirms)
	if !ok {
		t.Fatal("accountant_firms limit missing")
	}
	if firms < 100 {
		t.Fatalf("expected accountant plan to support at least 100 firms, got %d", firms)
	}
}

func TestDefaultCatalog_MarketplacePlan(t *testing.T) {
	c := DefaultCatalog()

	if !c.HasFeature(PlanMarketplace, FeatureIntegrationCatalog) {
		t.Fatal("marketplace plan must have integration catalog")
	}

	if !c.HasFeature(PlanMarketplace, FeatureWebhookAccess) {
		t.Fatal("marketplace plan must have webhook access")
	}

	integrations, ok := c.Limit(PlanMarketplace, LimitIntegrations)
	if !ok {
		t.Fatal("integrations limit missing")
	}
	if integrations < 25 {
		t.Fatalf("expected marketplace plan to support at least 25 integrations, got %d", integrations)
	}
}

func TestDefaultCatalog_Limits(t *testing.T) {
	c := DefaultCatalog()

	starterUsers, ok := c.Limit(PlanStarter, LimitUsers)
	if !ok {
		t.Fatal("starter users limit missing")
	}
	if starterUsers != 3 {
		t.Fatalf("expected starter users limit 3, got %d", starterUsers)
	}

	proAPI, ok := c.Limit(PlanPro, LimitAPIMonthlyRequests)
	if !ok {
		t.Fatal("pro api limit missing")
	}
	if proAPI <= 0 {
		t.Fatalf("expected pro api limit to be positive, got %d", proAPI)
	}

	enterpriseUsers, ok := c.Limit(PlanEnterprise, LimitUsers)
	if !ok {
		t.Fatal("enterprise users limit missing")
	}
	if enterpriseUsers < 250 {
		t.Fatalf("expected enterprise users limit at least 250, got %d", enterpriseUsers)
	}
}
GO_TEST_EOF

cat <<'TEST_EOF' > scripts/faz7/test_7_2_product_packaging_plan_catalog.sh
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

echo "===== FAZ 7-2 TEST BASLADI ====="

check_file "7-2" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md"
check_file "7-2" "docs/faz7/evidence/FAZ_7_2_PRODUCT_PACKAGING_EVIDENCE.md"
check_file "7-2" "configs/faz7/product_plan_catalog.v1.json"
check_file "7-2" "internal/platform/commercial/catalog/catalog.go"
check_file "7-2" "internal/platform/commercial/catalog/catalog_test.go"
check_file "7-2" "scripts/faz7/test_7_2_product_packaging_plan_catalog.sh"
check_file "7-2" "scripts/faz7/audit_7_2_real_implementation.sh"

check_grep "7-2.1 Paket mimarisi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.1 Paket Mimarisi"
check_grep "7-2.1.1 Starter paket" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.1.1 Starter Paket"
check_grep "7-2.1.2 Pro paket" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.1.2 Pro Paket"
check_grep "7-2.1.3 Enterprise paket" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.1.3 Enterprise Paket"
check_grep "7-2.1.4 Muhasebeci paketi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.1.4 Muhasebeci Paketi"
check_grep "7-2.1.5 Marketplace entegrasyon paketi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.1.5 Marketplace / Entegrasyon Paketi"

check_grep "7-2.2 Feature matrix" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.2 Feature Matrix"
check_grep "7-2.2.1 Modul bazli yetki" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.2.1 Modul Bazli Yetki"
check_grep "7-2.2.2 Kullanici limiti" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.2.2 Kullanici Limiti"
check_grep "7-2.2.3 Tenant limiti" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.2.3 Tenant Limiti"
check_grep "7-2.2.4 API hakki" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.2.4 API Hakki"
check_grep "7-2.2.5 Export hakki" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.2.5 Export Hakki"
check_grep "7-2.2.6 Muhasebeci erisim hakki" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.2.6 Muhasebeci Erisim Hakki"

check_grep "7-2.3 Plan catalog config" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "configs/faz7/product_plan_catalog.v1.json"
check_grep "7-2.4 Go code artifact" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "internal/platform/commercial/catalog/catalog.go"
check_grep "7-2.5 7-3 hazirlik" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-3 entitlement runtime"

echo
echo "===== 7-2 JSON CONFIG VALIDATION ====="
if python3 - <<'PY'
import json
from pathlib import Path

path = Path("configs/faz7/product_plan_catalog.v1.json")
data = json.loads(path.read_text(encoding="utf-8"))

required_plans = {"starter", "pro", "enterprise", "accountant", "marketplace"}
plans = {p["code"]: p for p in data.get("plans", [])}

missing = required_plans - set(plans.keys())
if missing:
    raise SystemExit(f"missing plans: {sorted(missing)}")

if data.get("schema_version") != "product_plan_catalog.v1":
    raise SystemExit("schema_version mismatch")

if data.get("phase") != "FAZ_7":
    raise SystemExit("phase mismatch")

if data.get("step") != "7-2":
    raise SystemExit("step mismatch")

if data.get("catalog_status") != "READY":
    raise SystemExit("catalog_status mismatch")

for code, plan in plans.items():
    if not plan.get("features"):
        raise SystemExit(f"plan has no features: {code}")
    limits = plan.get("limits", {})
    for key in ["users", "tenants", "api_monthly_requests", "monthly_exports", "accountant_firms", "integrations"]:
        if key not in limits:
            raise SystemExit(f"plan {code} missing limit {key}")

gates = data.get("launch_gates", {})
for key in [
    "real_payment_requires_financial_approval",
    "public_launch_requires_legal_approval",
    "public_launch_requires_kvkk_approval",
    "public_launch_requires_cloudflare_green_mode",
    "public_launch_requires_waf_rate_limit",
]:
    if gates.get(key) is not True:
        raise SystemExit(f"launch gate missing or false: {key}")

print("JSON_OK")
PY
then
  ok "7-2 JSON config parse ve gate kontrolu"
else
  fail "7-2 JSON config parse ve gate kontrolu"
fi

echo
echo "===== 7-2 GO TEST ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/catalog -v; then
    ok "7-2 Go catalog unit testleri"
  else
    fail "7-2 Go catalog unit testleri"
  fi
else
  fail "7-2 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-2 TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_2_TEST_STATUS=PASS ✅"
  echo "OK ✅ FAZ 7-2 testleri basariyla gecti"
else
  echo "FAZ_7_2_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-2 testlerinde hata var"
  exit 1
fi
TEST_EOF

cat <<'AUDIT_EOF' > scripts/faz7/audit_7_2_real_implementation.sh
#!/usr/bin/env bash
set -Eeuo pipefail

FAIL_COUNT=0
PASS_COUNT=0
OPTIONAL_WARN=0
AUDIT_FILE="docs/faz7/evidence/FAZ_7_2_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-2 REAL IMPLEMENTATION AUDIT BASLADI ====="

has_file "7-2.1 Product packaging dokumani" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md"
has_file "7-2.2 Evidence dokumani" "docs/faz7/evidence/FAZ_7_2_PRODUCT_PACKAGING_EVIDENCE.md"
has_file "7-2.3 Plan catalog config" "configs/faz7/product_plan_catalog.v1.json"
has_file "7-2.4 Go catalog modeli" "internal/platform/commercial/catalog/catalog.go"
has_file "7-2.5 Go catalog testleri" "internal/platform/commercial/catalog/catalog_test.go"
has_file "7-2.6 Test scripti" "scripts/faz7/test_7_2_product_packaging_plan_catalog.sh"
has_file "7-2.7 Real implementation audit scripti" "scripts/faz7/audit_7_2_real_implementation.sh"

has_text "7-2.1.1 Starter paket dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Starter Paket"
has_text "7-2.1.2 Pro paket dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Pro Paket"
has_text "7-2.1.3 Enterprise paket dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Enterprise Paket"
has_text "7-2.1.4 Muhasebeci paket dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Muhasebeci Paket"
has_text "7-2.1.5 Marketplace paket dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Marketplace / Entegrasyon Paketi"

has_text "7-2.2.1 Feature matrix dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Feature Matrix"
has_text "7-2.2.2 Kullanici limit dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Kullanici Limiti"
has_text "7-2.2.3 Tenant limit dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Tenant Limiti"
has_text "7-2.2.4 API hakki dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "API Hakki"
has_text "7-2.2.5 Export hakki dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Export Hakki"
has_text "7-2.2.6 Muhasebeci erisim dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Muhasebeci Erisim Hakki"

has_text "7-2 config starter karsiligi" "configs/faz7/product_plan_catalog.v1.json" "\"code\": \"starter\""
has_text "7-2 config pro karsiligi" "configs/faz7/product_plan_catalog.v1.json" "\"code\": \"pro\""
has_text "7-2 config enterprise karsiligi" "configs/faz7/product_plan_catalog.v1.json" "\"code\": \"enterprise\""
has_text "7-2 config accountant karsiligi" "configs/faz7/product_plan_catalog.v1.json" "\"code\": \"accountant\""
has_text "7-2 config marketplace karsiligi" "configs/faz7/product_plan_catalog.v1.json" "\"code\": \"marketplace\""

has_text "7-2 code PlanStarter karsiligi" "internal/platform/commercial/catalog/catalog.go" "PlanStarter"
has_text "7-2 code PlanPro karsiligi" "internal/platform/commercial/catalog/catalog.go" "PlanPro"
has_text "7-2 code PlanEnterprise karsiligi" "internal/platform/commercial/catalog/catalog.go" "PlanEnterprise"
has_text "7-2 code PlanAccountant karsiligi" "internal/platform/commercial/catalog/catalog.go" "PlanAccountant"
has_text "7-2 code PlanMarketplace karsiligi" "internal/platform/commercial/catalog/catalog.go" "PlanMarketplace"

echo
echo "===== 7-2 AUDIT GO TEST VERIFICATION ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/catalog -v >/tmp/faz7_2_catalog_go_test.log 2>&1; then
    ok "7-2 Go test real implementation verification"
  else
    cat /tmp/faz7_2_catalog_go_test.log || true
    fail "7-2 Go test real implementation verification"
  fi
else
  fail "7-2 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-2 REAL IMPLEMENTATION AUDIT OZETI ====="
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
# FAZ 7-2 Real Implementation Audit

## Audit Summary

PASS_COUNT=$PASS_COUNT
REQUIRED_FAIL=$FAIL_COUNT
OPTIONAL_WARN=$OPTIONAL_WARN
FAZ_7_2_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
FAZ_7_2_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅

## Checked Implementation Evidence

- docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md
- docs/faz7/evidence/FAZ_7_2_PRODUCT_PACKAGING_EVIDENCE.md
- configs/faz7/product_plan_catalog.v1.json
- internal/platform/commercial/catalog/catalog.go
- internal/platform/commercial/catalog/catalog_test.go
- scripts/faz7/test_7_2_product_packaging_plan_catalog.sh
- scripts/faz7/audit_7_2_real_implementation.sh

## Real Implementation Decision

7-2 real implementation audit confirms that the product packaging plan, plan catalog config, Go catalog model, Go unit tests, test script and audit script exist as real code/config/script/document artifacts.

## Final Status

FAZ_7_2_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
AUDIT_REPORT

echo "OK ✅ evidence yazildi: $AUDIT_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_2_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_7_2_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo "OK ✅ FAZ 7-2 real implementation audit basariyla gecti"
else
  echo "FAZ_7_2_REAL_IMPLEMENTATION_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-2 real implementation audit basarisiz"
  exit 1
fi
AUDIT_EOF

chmod +x scripts/faz7/test_7_2_product_packaging_plan_catalog.sh
chmod +x scripts/faz7/audit_7_2_real_implementation.sh

echo "OK ✅ docs/config/code/test/audit dosyalari yazildi"

echo
echo "===== 7-2 TEST CALISIYOR ====="
bash scripts/faz7/test_7_2_product_packaging_plan_catalog.sh

echo
echo "===== 7-2 REAL IMPLEMENTATION AUDIT CALISIYOR ====="
bash scripts/faz7/audit_7_2_real_implementation.sh

echo
echo "===== FAZ 7-2 FINAL OZET ====="
echo "FAZ_7_2_DOC_STATUS=READY ✅"
echo "FAZ_7_2_CONFIG_STATUS=READY ✅"
echo "FAZ_7_2_CODE_STATUS=READY ✅"
echo "FAZ_7_2_TEST_STATUS=PASS ✅"
echo "FAZ_7_2_REAL_IMPLEMENTATION_STATUS=PASS ✅"
echo "FAZ_7_2_FINAL_STATUS=PASS ✅"
echo "FAZ_7_3_READY=YES ✅"
echo "OK ✅ FAZ 7-2 Product Packaging / Plan Catalog tamamlandi"
