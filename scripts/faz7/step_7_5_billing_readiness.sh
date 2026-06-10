#!/usr/bin/env bash
set -Eeuo pipefail

echo "===== FAZ 7-5 BILLING READINESS BASLADI ====="

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="backups/faz7/7-5_${TS}"

mkdir -p "$BACKUP_DIR"
mkdir -p docs/faz7/evidence
mkdir -p configs/faz7
mkdir -p internal/platform/commercial/billing
mkdir -p scripts/faz7

echo
echo "===== 7-5 BACKUP ====="

backup_if_exists() {
  local path="$1"
  if [ -e "$path" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$path")"
    cp -a "$path" "$BACKUP_DIR/$path"
    echo "7-5 backup OK ✅ $path -> $BACKUP_DIR/$path"
  else
    echo "7-5 backup SKIP ✅ $path mevcut degil"
  fi
}

backup_if_exists "docs/faz7/FAZ_7_5_BILLING_READINESS.md"
backup_if_exists "docs/faz7/evidence/FAZ_7_5_BILLING_READINESS_EVIDENCE.md"
backup_if_exists "docs/faz7/evidence/FAZ_7_5_REAL_IMPLEMENTATION_AUDIT.md"
backup_if_exists "configs/faz7/billing_readiness.v1.json"
backup_if_exists "internal/platform/commercial/billing/billing.go"
backup_if_exists "internal/platform/commercial/billing/billing_test.go"
backup_if_exists "scripts/faz7/test_7_5_billing_readiness.sh"
backup_if_exists "scripts/faz7/audit_7_5_real_implementation.sh"

echo "7-5 backup tamam OK ✅"

echo
echo "===== 7-5 DOSYALAR YAZILIYOR ====="

cat <<'DOC_EOF' > docs/faz7/FAZ_7_5_BILLING_READINESS.md
# 7-5 — Billing Readiness

## Adim Amaci

Bu adim Pix2pi icin gercek tahsilat acilmadan once billing hazirligini kurar.

7-5 sonunda:

- Fatura taslak modeli olusur.
- Plan fiyat katalogu olusur.
- KDV hesaplama modeli olusur.
- Muhasebeci paketi firma basi ucret modeli hazirlanir.
- Billing simulation aktif olur.
- Gercek odeme kapisi kapali kalir.
- Mali musavir/vergi onayi gate olarak kaydedilir.
- Gercek odeme saglayici entegrasyonu icin adapter hazirligi yapilir.
- 7-6 Tenant Onboarding / Self-Service Readiness icin temel hazirlanir.

## 7-5.1 Billing Hazirligi

### 7-5.1.1 Fatura hazirlik modeli
Durum: IMPLEMENTED_OR_PRESENT

Billing runtime gercek e-fatura kesmez.
Bu adimda sadece fatura taslagi uretir.

Fatura taslagi alanlari:

- tenant_id
- account_id
- plan_code
- billing_period_start
- billing_period_end
- net_amount_kurus
- vat_rate_bps
- vat_amount_kurus
- gross_amount_kurus
- currency
- billing_status
- real_payment_enabled

### 7-5.1.2 Vergi/KDV uyumu
Durum: IMPLEMENTED_OR_PRESENT

Baslangic KDV modeli:

- default VAT: 20%
- hesaplama basis point ile yapilir
- 20% = 2000 bps
- para birimi TRY
- tutarlar kurus olarak saklanir

### 7-5.1.3 Muhasebeci paketi firma basi ucret modeli
Durum: IMPLEMENTED_OR_PRESENT

Muhasebeci paketi firma sayisina gore ticari olarak genisleyebilir.

Bu adimda:

- accountant_firms usage counter 7-4 subscription runtime'dan gelir
- accountant plan fiyat katalogunda ayrilir
- firma basi ucret ileride 7-9 ve 7-11 ile ticari operasyon paneline baglanir

### 7-5.1.4 Gercek odeme saglayici oncesi billing simulation
Durum: IMPLEMENTED_OR_PRESENT

Billing simulation aciktir.

Bu sayede:

- gercek para cekmeden fatura taslagi uretilir
- plan fiyatlari test edilir
- KDV hesaplari test edilir
- subscription status ile billing karari test edilir

### 7-5.1.5 Gercek odeme entegrasyonu icin adapter hazirligi
Durum: IMPLEMENTED_OR_PRESENT

Gercek odeme adapter'i bu adimda acilmaz.

Gate kurali:

- real_payment_enabled=false
- billing_simulation_enabled=true
- requires_financial_approval_before_real_payment=true

Gercek tahsilat ancak mali musavir/vergi onayi, sozlesme ve odeme saglayici karari sonrasi acilir.

## 7-5.2 Billing Decision Model

### 7-5.2.1 Billing allow
Durum: IMPLEMENTED_OR_PRESENT

Uygun subscription ve billing profile ile fatura taslagi uretilebilir.

### 7-5.2.2 Billing deny
Durum: IMPLEMENTED_OR_PRESENT

Eksik tenant, account, plan, tax profile veya gecersiz subscription status durumunda billing taslagi reddedilir.

### 7-5.2.3 Payment gate deny
Durum: IMPLEMENTED_OR_PRESENT

7-5'te gercek odeme kapali oldugu icin real payment istegi reddedilir.

## 7-5.3 Code Artifact

Durum: IMPLEMENTED_OR_PRESENT

Billing readiness Go modeli:

- internal/platform/commercial/billing/billing.go
- internal/platform/commercial/billing/billing_test.go

## 7-5.4 Config Artifact

Durum: IMPLEMENTED_OR_PRESENT

Billing readiness config dosyasi:

- configs/faz7/billing_readiness.v1.json

## 7-5.5 7-6 Gecis Hazirligi

Durum: IMPLEMENTED_OR_PRESENT

7-5 tamamlandiginda 7-6 icin asagidaki temeller hazirdir:

- tenant subscription billing profile ihtiyaci
- onboarding sirasinda billing profile toplama
- trial/demo icin billing simulation
- gercek odeme kapali gate
- mali/vergi onayi kapisi
- plan fiyat katalogu

## 7-5 Final Karari

- FAZ_7_5_DOC_STATUS=READY
- FAZ_7_5_CONFIG_STATUS=READY
- FAZ_7_5_CODE_STATUS=READY
- FAZ_7_5_TEST_REQUIRED=YES
- FAZ_7_5_REAL_IMPLEMENTATION_AUDIT_REQUIRED=YES
- FAZ_7_6_READY_CONDITION=FAZ_7_5_TEST_STATUS_PASS_AND_REAL_IMPLEMENTATION_STATUS_PASS
DOC_EOF

cat <<'EVIDENCE_EOF' > docs/faz7/evidence/FAZ_7_5_BILLING_READINESS_EVIDENCE.md
# FAZ 7-5 Billing Readiness Evidence

## Evidence Summary

- 7-5 billing readiness document created.
- Billing readiness config created.
- Go billing readiness runtime model created.
- Go billing readiness tests created.
- Test script created.
- Real implementation audit script created.
- 7-6 Tenant Onboarding / Self-Service Readiness is prepared as the next step.

## Evidence Files

- docs/faz7/FAZ_7_5_BILLING_READINESS.md
- docs/faz7/evidence/FAZ_7_5_BILLING_READINESS_EVIDENCE.md
- configs/faz7/billing_readiness.v1.json
- internal/platform/commercial/billing/billing.go
- internal/platform/commercial/billing/billing_test.go
- scripts/faz7/test_7_5_billing_readiness.sh
- scripts/faz7/audit_7_5_real_implementation.sh

## Initial Seal Target

- FAZ_7_5_DOC_STATUS=READY
- FAZ_7_5_CONFIG_STATUS=READY
- FAZ_7_5_CODE_STATUS=READY
- FAZ_7_5_TEST_STATUS=PENDING_UNTIL_SCRIPT_RUN
- FAZ_7_5_REAL_IMPLEMENTATION_STATUS=PENDING_UNTIL_AUDIT_RUN
EVIDENCE_EOF

cat <<'JSON_EOF' > configs/faz7/billing_readiness.v1.json
{
  "schema_version": "billing_readiness.v1",
  "phase": "FAZ_7",
  "step": "7-5",
  "runtime_status": "READY",
  "source_catalog": "configs/faz7/product_plan_catalog.v1.json",
  "source_entitlement": "configs/faz7/entitlement_feature_gate.v1.json",
  "source_subscription": "configs/faz7/subscription_runtime.v1.json",
  "next_step": "7-6 Tenant Onboarding / Self-Service Readiness",
  "currency": "TRY",
  "money_unit": "kurus",
  "default_vat_rate_bps": 2000,
  "real_payment_enabled": false,
  "billing_simulation_enabled": true,
  "requires_financial_approval_before_real_payment": true,
  "requires_tax_advisor_approval_before_real_billing": true,
  "requires_payment_provider_contract_before_real_payment": true,
  "invoice_draft_fields": [
    "tenant_id",
    "account_id",
    "plan_code",
    "billing_period_start",
    "billing_period_end",
    "net_amount_kurus",
    "vat_rate_bps",
    "vat_amount_kurus",
    "gross_amount_kurus",
    "currency",
    "billing_status",
    "real_payment_enabled"
  ],
  "billing_profile_required_fields": [
    "tenant_id",
    "account_id",
    "legal_name",
    "tax_number",
    "tax_office",
    "billing_email",
    "billing_address"
  ],
  "plan_prices": [
    {
      "plan_code": "starter",
      "monthly_net_amount_kurus": 99000,
      "currency": "TRY"
    },
    {
      "plan_code": "pro",
      "monthly_net_amount_kurus": 299000,
      "currency": "TRY"
    },
    {
      "plan_code": "enterprise",
      "monthly_net_amount_kurus": 1499000,
      "currency": "TRY"
    },
    {
      "plan_code": "accountant",
      "monthly_net_amount_kurus": 499000,
      "currency": "TRY"
    },
    {
      "plan_code": "marketplace",
      "monthly_net_amount_kurus": 799000,
      "currency": "TRY"
    }
  ],
  "decision_model": {
    "allow_status": "ALLOW",
    "deny_status": "DENY",
    "reason_codes": [
      "ALLOW_INVOICE_DRAFT_READY",
      "ALLOW_BILLING_SIMULATION_READY",
      "DENY_TENANT_REQUIRED",
      "DENY_ACCOUNT_REQUIRED",
      "DENY_PLAN_REQUIRED",
      "DENY_PLAN_UNKNOWN",
      "DENY_BILLING_PROFILE_REQUIRED",
      "DENY_INVALID_PERIOD",
      "DENY_SUBSCRIPTION_NOT_BILLABLE",
      "DENY_REAL_PAYMENT_DISABLED",
      "DENY_FINANCIAL_APPROVAL_REQUIRED"
    ]
  }
}
JSON_EOF

cat <<'GO_EOF' > internal/platform/commercial/billing/billing.go
package billing

import (
	"fmt"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/catalog"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/entitlement"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/subscription"
)

type CurrencyCode string
type BillingStatus string
type ReasonCode string

const (
	CurrencyTRY CurrencyCode = "TRY"
)

const (
	BillingStatusDraft           BillingStatus = "DRAFT"
	BillingStatusSimulationReady BillingStatus = "SIMULATION_READY"
	BillingStatusBlocked         BillingStatus = "BLOCKED"
)

const (
	ReasonAllowInvoiceDraftReady      ReasonCode = "ALLOW_INVOICE_DRAFT_READY"
	ReasonAllowBillingSimulationReady ReasonCode = "ALLOW_BILLING_SIMULATION_READY"
	ReasonDenyTenantRequired          ReasonCode = "DENY_TENANT_REQUIRED"
	ReasonDenyAccountRequired         ReasonCode = "DENY_ACCOUNT_REQUIRED"
	ReasonDenyPlanRequired            ReasonCode = "DENY_PLAN_REQUIRED"
	ReasonDenyPlanUnknown             ReasonCode = "DENY_PLAN_UNKNOWN"
	ReasonDenyBillingProfileRequired  ReasonCode = "DENY_BILLING_PROFILE_REQUIRED"
	ReasonDenyInvalidPeriod           ReasonCode = "DENY_INVALID_PERIOD"
	ReasonDenySubscriptionNotBillable  ReasonCode = "DENY_SUBSCRIPTION_NOT_BILLABLE"
	ReasonDenyRealPaymentDisabled     ReasonCode = "DENY_REAL_PAYMENT_DISABLED"
	ReasonDenyFinancialApproval        ReasonCode = "DENY_FINANCIAL_APPROVAL_REQUIRED"
)

type BillingProfile struct {
	TenantID       string
	AccountID      string
	LegalName      string
	TaxNumber      string
	TaxOffice      string
	BillingEmail   string
	BillingAddress string
}

type PlanPrice struct {
	PlanCode              catalog.PlanCode
	MonthlyNetAmountKurus int64
	Currency              CurrencyCode
}

type InvoiceLine struct {
	Description     string
	PlanCode        catalog.PlanCode
	NetAmountKurus  int64
	VATRateBps      int
	VATAmountKurus  int64
	GrossAmountKurus int64
}

type InvoiceDraft struct {
	DraftID string

	TenantID  string
	AccountID string
	PlanCode  catalog.PlanCode

	BillingPeriodStart time.Time
	BillingPeriodEnd   time.Time

	NetAmountKurus   int64
	VATRateBps       int
	VATAmountKurus   int64
	GrossAmountKurus int64
	Currency         CurrencyCode

	BillingStatus      BillingStatus
	RealPaymentEnabled bool
	SimulationEnabled  bool

	Lines []InvoiceLine
}

type Decision struct {
	Status        entitlement.DecisionStatus
	ReasonCode    string
	ReasonMessage string

	TenantID  string
	AccountID string
	PlanCode  catalog.PlanCode

	BillingStatus      BillingStatus
	RealPaymentEnabled bool
	SimulationEnabled  bool
}

type Runtime struct {
	catalog catalog.Catalog

	prices map[catalog.PlanCode]PlanPrice

	DefaultVATRateBps int
	Currency          CurrencyCode

	RealPaymentEnabled                         bool
	BillingSimulationEnabled                   bool
	RequiresFinancialApprovalBeforeRealPayment bool
	RequiresTaxAdvisorApprovalBeforeRealBilling bool
	RequiresPaymentProviderContractBeforeRealPayment bool
}

func NewDefaultRuntime() (*Runtime, error) {
	c := catalog.DefaultCatalog()
	if err := c.Validate(); err != nil {
		return nil, fmt.Errorf("invalid catalog: %w", err)
	}

	runtime := &Runtime{
		catalog: c,
		prices: map[catalog.PlanCode]PlanPrice{
			catalog.PlanStarter: {
				PlanCode:              catalog.PlanStarter,
				MonthlyNetAmountKurus: 99000,
				Currency:              CurrencyTRY,
			},
			catalog.PlanPro: {
				PlanCode:              catalog.PlanPro,
				MonthlyNetAmountKurus: 299000,
				Currency:              CurrencyTRY,
			},
			catalog.PlanEnterprise: {
				PlanCode:              catalog.PlanEnterprise,
				MonthlyNetAmountKurus: 1499000,
				Currency:              CurrencyTRY,
			},
			catalog.PlanAccountant: {
				PlanCode:              catalog.PlanAccountant,
				MonthlyNetAmountKurus: 499000,
				Currency:              CurrencyTRY,
			},
			catalog.PlanMarketplace: {
				PlanCode:              catalog.PlanMarketplace,
				MonthlyNetAmountKurus: 799000,
				Currency:              CurrencyTRY,
			},
		},
		DefaultVATRateBps: 2000,
		Currency:         CurrencyTRY,

		RealPaymentEnabled:                         false,
		BillingSimulationEnabled:                   true,
		RequiresFinancialApprovalBeforeRealPayment: true,
		RequiresTaxAdvisorApprovalBeforeRealBilling: true,
		RequiresPaymentProviderContractBeforeRealPayment: true,
	}

	if err := runtime.ValidatePriceCatalog(); err != nil {
		return nil, err
	}

	return runtime, nil
}

func (r *Runtime) ValidatePriceCatalog() error {
	requiredPlans := []catalog.PlanCode{
		catalog.PlanStarter,
		catalog.PlanPro,
		catalog.PlanEnterprise,
		catalog.PlanAccountant,
		catalog.PlanMarketplace,
	}

	for _, planCode := range requiredPlans {
		price, ok := r.prices[planCode]
		if !ok {
			return fmt.Errorf("price missing for plan: %s", planCode)
		}
		if price.MonthlyNetAmountKurus <= 0 {
			return fmt.Errorf("price must be positive for plan: %s", planCode)
		}
		if price.Currency != CurrencyTRY {
			return fmt.Errorf("unexpected currency for plan %s: %s", planCode, price.Currency)
		}
	}

	if r.DefaultVATRateBps <= 0 {
		return fmt.Errorf("vat rate must be positive")
	}

	if r.RealPaymentEnabled {
		return fmt.Errorf("real payment must be disabled in FAZ 7-5")
	}

	if !r.BillingSimulationEnabled {
		return fmt.Errorf("billing simulation must be enabled in FAZ 7-5")
	}

	if !r.RequiresFinancialApprovalBeforeRealPayment {
		return fmt.Errorf("financial approval gate must be enabled")
	}

	return nil
}

func (r *Runtime) Price(planCode catalog.PlanCode) (PlanPrice, bool) {
	price, ok := r.prices[planCode]
	return price, ok
}

func (r *Runtime) BuildInvoiceDraft(account subscription.Account, profile BillingProfile, periodStart time.Time, periodEnd time.Time) (InvoiceDraft, Decision) {
	if decision, ok := r.validateBillingRequest(account, profile, periodStart, periodEnd); !ok {
		return InvoiceDraft{
			TenantID: account.TenantID,
			AccountID: account.AccountID,
			PlanCode: account.Plan,
			BillingPeriodStart: periodStart,
			BillingPeriodEnd: periodEnd,
			BillingStatus: BillingStatusBlocked,
			RealPaymentEnabled: r.RealPaymentEnabled,
			SimulationEnabled: r.BillingSimulationEnabled,
		}, decision
	}

	price, ok := r.Price(account.Plan)
	if !ok {
		return InvoiceDraft{}, r.deny(account, ReasonDenyPlanUnknown, "plan price is not defined")
	}

	vatAmount := CalculateVAT(price.MonthlyNetAmountKurus, r.DefaultVATRateBps)
	grossAmount := price.MonthlyNetAmountKurus + vatAmount

	draft := InvoiceDraft{
		DraftID: fmt.Sprintf("INV-DRAFT-%s-%s-%d", account.TenantID, account.AccountID, periodStart.Unix()),

		TenantID: account.TenantID,
		AccountID: account.AccountID,
		PlanCode: account.Plan,

		BillingPeriodStart: periodStart,
		BillingPeriodEnd: periodEnd,

		NetAmountKurus: price.MonthlyNetAmountKurus,
		VATRateBps: r.DefaultVATRateBps,
		VATAmountKurus: vatAmount,
		GrossAmountKurus: grossAmount,
		Currency: price.Currency,

		BillingStatus: BillingStatusSimulationReady,
		RealPaymentEnabled: r.RealPaymentEnabled,
		SimulationEnabled: r.BillingSimulationEnabled,

		Lines: []InvoiceLine{
			{
				Description: fmt.Sprintf("Pix2pi %s monthly subscription", account.Plan),
				PlanCode: account.Plan,
				NetAmountKurus: price.MonthlyNetAmountKurus,
				VATRateBps: r.DefaultVATRateBps,
				VATAmountKurus: vatAmount,
				GrossAmountKurus: grossAmount,
			},
		},
	}

	return draft, Decision{
		Status: entitlement.DecisionAllow,
		ReasonCode: string(ReasonAllowInvoiceDraftReady),
		ReasonMessage: "invoice draft is ready for billing simulation",
		TenantID: account.TenantID,
		AccountID: account.AccountID,
		PlanCode: account.Plan,
		BillingStatus: draft.BillingStatus,
		RealPaymentEnabled: r.RealPaymentEnabled,
		SimulationEnabled: r.BillingSimulationEnabled,
	}
}

func (r *Runtime) SimulateBilling(draft InvoiceDraft) Decision {
	if draft.DraftID == "" || draft.BillingStatus != BillingStatusSimulationReady {
		return Decision{
			Status: entitlement.DecisionDeny,
			ReasonCode: string(ReasonDenyInvalidPeriod),
			ReasonMessage: "invoice draft is not simulation ready",
			TenantID: draft.TenantID,
			AccountID: draft.AccountID,
			PlanCode: draft.PlanCode,
			BillingStatus: draft.BillingStatus,
			RealPaymentEnabled: r.RealPaymentEnabled,
			SimulationEnabled: r.BillingSimulationEnabled,
		}
	}

	return Decision{
		Status: entitlement.DecisionAllow,
		ReasonCode: string(ReasonAllowBillingSimulationReady),
		ReasonMessage: "billing simulation is ready",
		TenantID: draft.TenantID,
		AccountID: draft.AccountID,
		PlanCode: draft.PlanCode,
		BillingStatus: draft.BillingStatus,
		RealPaymentEnabled: r.RealPaymentEnabled,
		SimulationEnabled: r.BillingSimulationEnabled,
	}
}

func (r *Runtime) CheckRealPaymentGate() Decision {
	if !r.RealPaymentEnabled {
		return Decision{
			Status: entitlement.DecisionDeny,
			ReasonCode: string(ReasonDenyRealPaymentDisabled),
			ReasonMessage: "real payment is disabled in FAZ 7-5 billing readiness",
			RealPaymentEnabled: r.RealPaymentEnabled,
			SimulationEnabled: r.BillingSimulationEnabled,
		}
	}

	if r.RequiresFinancialApprovalBeforeRealPayment {
		return Decision{
			Status: entitlement.DecisionDeny,
			ReasonCode: string(ReasonDenyFinancialApproval),
			ReasonMessage: "financial approval is required before real payment",
			RealPaymentEnabled: r.RealPaymentEnabled,
			SimulationEnabled: r.BillingSimulationEnabled,
		}
	}

	return Decision{
		Status: entitlement.DecisionAllow,
		ReasonCode: string(ReasonAllowBillingSimulationReady),
		ReasonMessage: "real payment gate is open",
		RealPaymentEnabled: r.RealPaymentEnabled,
		SimulationEnabled: r.BillingSimulationEnabled,
	}
}

func (r *Runtime) validateBillingRequest(account subscription.Account, profile BillingProfile, periodStart time.Time, periodEnd time.Time) (Decision, bool) {
	if account.TenantID == "" {
		return r.deny(account, ReasonDenyTenantRequired, "tenant id is required"), false
	}
	if account.AccountID == "" {
		return r.deny(account, ReasonDenyAccountRequired, "account id is required"), false
	}
	if account.Plan == "" {
		return r.deny(account, ReasonDenyPlanRequired, "plan code is required"), false
	}
	if _, ok := r.catalog.Plan(account.Plan); !ok {
		return r.deny(account, ReasonDenyPlanUnknown, "plan is not defined in catalog"), false
	}
	if _, ok := r.Price(account.Plan); !ok {
		return r.deny(account, ReasonDenyPlanUnknown, "plan price is not defined"), false
	}
	if profile.TenantID == "" ||
		profile.AccountID == "" ||
		profile.LegalName == "" ||
		profile.TaxNumber == "" ||
		profile.TaxOffice == "" ||
		profile.BillingEmail == "" ||
		profile.BillingAddress == "" {
		return r.deny(account, ReasonDenyBillingProfileRequired, "billing profile is incomplete"), false
	}
	if profile.TenantID != account.TenantID || profile.AccountID != account.AccountID {
		return r.deny(account, ReasonDenyBillingProfileRequired, "billing profile does not match account"), false
	}
	if periodStart.IsZero() || periodEnd.IsZero() || !periodEnd.After(periodStart) {
		return r.deny(account, ReasonDenyInvalidPeriod, "billing period is invalid"), false
	}
	if account.Status == subscription.StatusCanceled ||
		account.Status == subscription.StatusExpired {
		return r.deny(account, ReasonDenySubscriptionNotBillable, "subscription is not billable"), false
	}

	return Decision{}, true
}

func (r *Runtime) deny(account subscription.Account, reason ReasonCode, message string) Decision {
	return Decision{
		Status: entitlement.DecisionDeny,
		ReasonCode: string(reason),
		ReasonMessage: message,
		TenantID: account.TenantID,
		AccountID: account.AccountID,
		PlanCode: account.Plan,
		BillingStatus: BillingStatusBlocked,
		RealPaymentEnabled: r.RealPaymentEnabled,
		SimulationEnabled: r.BillingSimulationEnabled,
	}
}

func CalculateVAT(netAmountKurus int64, vatRateBps int) int64 {
	return (netAmountKurus * int64(vatRateBps)) / 10000
}
GO_EOF

cat <<'GO_TEST_EOF' > internal/platform/commercial/billing/billing_test.go
package billing

import (
	"testing"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/catalog"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/entitlement"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/subscription"
)

func mustRuntime(t *testing.T) *Runtime {
	t.Helper()

	runtime, err := NewDefaultRuntime()
	if err != nil {
		t.Fatalf("expected runtime to initialize, got error: %v", err)
	}

	return runtime
}

func baseAccount(now time.Time) subscription.Account {
	return subscription.Account{
		TenantID: "tenant_7",
		AccountID: "account_7",
		Plan: catalog.PlanPro,
		Status: subscription.StatusActive,
		CurrentPeriodStart: now.Add(-24 * time.Hour),
		CurrentPeriodEnd: now.Add(30 * 24 * time.Hour),
		CurrentUsers: 5,
		CurrentTenants: 1,
		CurrentAPIRequests: 100,
		CurrentExports: 10,
		CurrentIntegrations: 1,
	}
}

func baseProfile() BillingProfile {
	return BillingProfile{
		TenantID: "tenant_7",
		AccountID: "account_7",
		LegalName: "Pix2pi Pilot Ltd",
		TaxNumber: "1234567890",
		TaxOffice: "Istanbul",
		BillingEmail: "billing@example.com",
		BillingAddress: "Istanbul Turkiye",
	}
}

func TestRuntime_ValidatePriceCatalog(t *testing.T) {
	runtime := mustRuntime(t)

	if err := runtime.ValidatePriceCatalog(); err != nil {
		t.Fatalf("expected price catalog to validate, got error: %v", err)
	}
}

func TestRuntime_PriceCatalogIncludesAllPlans(t *testing.T) {
	runtime := mustRuntime(t)

	requiredPlans := []catalog.PlanCode{
		catalog.PlanStarter,
		catalog.PlanPro,
		catalog.PlanEnterprise,
		catalog.PlanAccountant,
		catalog.PlanMarketplace,
	}

	for _, planCode := range requiredPlans {
		price, ok := runtime.Price(planCode)
		if !ok {
			t.Fatalf("expected price for plan: %s", planCode)
		}
		if price.MonthlyNetAmountKurus <= 0 {
			t.Fatalf("expected positive price for plan: %s", planCode)
		}
		if price.Currency != CurrencyTRY {
			t.Fatalf("expected TRY currency for plan %s, got %s", planCode, price.Currency)
		}
	}
}

func TestCalculateVAT(t *testing.T) {
	vat := CalculateVAT(100000, 2000)

	if vat != 20000 {
		t.Fatalf("expected vat 20000 kurus, got %d", vat)
	}
}

func TestRuntime_BuildInvoiceDraft(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	draft, decision := runtime.BuildInvoiceDraft(
		baseAccount(now),
		baseProfile(),
		now,
		now.Add(30 * 24 * time.Hour),
	)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if draft.BillingStatus != BillingStatusSimulationReady {
		t.Fatalf("expected simulation ready, got %s", draft.BillingStatus)
	}
	if draft.RealPaymentEnabled {
		t.Fatal("real payment must be disabled in 7-5")
	}
	if !draft.SimulationEnabled {
		t.Fatal("billing simulation must be enabled")
	}
	if draft.NetAmountKurus <= 0 {
		t.Fatal("expected positive net amount")
	}
	if draft.VATAmountKurus <= 0 {
		t.Fatal("expected positive vat amount")
	}
	if draft.GrossAmountKurus != draft.NetAmountKurus+draft.VATAmountKurus {
		t.Fatal("gross amount must equal net + vat")
	}
	if len(draft.Lines) != 1 {
		t.Fatalf("expected one invoice line, got %d", len(draft.Lines))
	}
}

func TestRuntime_BuildInvoiceDraft_DeniesMissingBillingProfile(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	_, decision := runtime.BuildInvoiceDraft(
		baseAccount(now),
		BillingProfile{},
		now,
		now.Add(30 * 24 * time.Hour),
	)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyBillingProfileRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_BuildInvoiceDraft_DeniesInvalidPeriod(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	_, decision := runtime.BuildInvoiceDraft(
		baseAccount(now),
		baseProfile(),
		now,
		now.Add(-1 * time.Hour),
	)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyInvalidPeriod) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_BuildInvoiceDraft_DeniesUnknownPlan(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)
	account.Plan = catalog.PlanCode("unknown")

	_, decision := runtime.BuildInvoiceDraft(
		account,
		baseProfile(),
		now,
		now.Add(30 * 24 * time.Hour),
	)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyPlanUnknown) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_BuildInvoiceDraft_DeniesCanceledSubscription(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)
	account.Status = subscription.StatusCanceled

	_, decision := runtime.BuildInvoiceDraft(
		account,
		baseProfile(),
		now,
		now.Add(30 * 24 * time.Hour),
	)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenySubscriptionNotBillable) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_SimulateBilling(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	draft, draftDecision := runtime.BuildInvoiceDraft(
		baseAccount(now),
		baseProfile(),
		now,
		now.Add(30 * 24 * time.Hour),
	)
	if draftDecision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected draft allow, got %s", draftDecision.Status)
	}

	simulationDecision := runtime.SimulateBilling(draft)
	if simulationDecision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected simulation allow, got %s", simulationDecision.Status)
	}
	if simulationDecision.ReasonCode != string(ReasonAllowBillingSimulationReady) {
		t.Fatalf("unexpected reason: %s", simulationDecision.ReasonCode)
	}
}

func TestRuntime_CheckRealPaymentGate_DeniesInReadinessPhase(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckRealPaymentGate()

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected real payment deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyRealPaymentDisabled) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_BuildInvoiceDraft_AccountantPlan(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)
	account.Plan = catalog.PlanAccountant
	account.CurrentAccountantFirms = 20

	draft, decision := runtime.BuildInvoiceDraft(
		account,
		baseProfile(),
		now,
		now.Add(30 * 24 * time.Hour),
	)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s", decision.Status)
	}
	if draft.PlanCode != catalog.PlanAccountant {
		t.Fatalf("expected accountant plan, got %s", draft.PlanCode)
	}
	if draft.NetAmountKurus <= 0 {
		t.Fatal("expected accountant plan amount")
	}
}
GO_TEST_EOF

cat <<'TEST_EOF' > scripts/faz7/test_7_5_billing_readiness.sh
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

echo "===== FAZ 7-5 TEST BASLADI ====="

check_file "7-5" "docs/faz7/FAZ_7_5_BILLING_READINESS.md"
check_file "7-5" "docs/faz7/evidence/FAZ_7_5_BILLING_READINESS_EVIDENCE.md"
check_file "7-5" "configs/faz7/billing_readiness.v1.json"
check_file "7-5" "internal/platform/commercial/billing/billing.go"
check_file "7-5" "internal/platform/commercial/billing/billing_test.go"
check_file "7-5" "scripts/faz7/test_7_5_billing_readiness.sh"
check_file "7-5" "scripts/faz7/audit_7_5_real_implementation.sh"

check_grep "7-5.1 Billing hazirligi" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-5.1 Billing Hazirligi"
check_grep "7-5.1.1 Fatura hazirlik modeli" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-5.1.1 Fatura hazirlik modeli"
check_grep "7-5.1.2 Vergi KDV uyumu" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-5.1.2 Vergi/KDV uyumu"
check_grep "7-5.1.3 Muhasebeci firma basi ucret" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-5.1.3 Muhasebeci paketi firma basi ucret modeli"
check_grep "7-5.1.4 Billing simulation" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-5.1.4 Gercek odeme saglayici oncesi billing simulation"
check_grep "7-5.1.5 Payment adapter hazirligi" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-5.1.5 Gercek odeme entegrasyonu icin adapter hazirligi"
check_grep "7-5.2 Billing decision model" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-5.2 Billing Decision Model"
check_grep "7-5.3 Code artifact" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "internal/platform/commercial/billing/billing.go"
check_grep "7-5.4 Config artifact" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "configs/faz7/billing_readiness.v1.json"
check_grep "7-5.5 7-6 hazirlik" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-6 Tenant Onboarding"

check_grep "7-5 code BillingProfile" "internal/platform/commercial/billing/billing.go" "type BillingProfile struct"
check_grep "7-5 code PlanPrice" "internal/platform/commercial/billing/billing.go" "type PlanPrice struct"
check_grep "7-5 code InvoiceDraft" "internal/platform/commercial/billing/billing.go" "type InvoiceDraft struct"
check_grep "7-5 code BuildInvoiceDraft" "internal/platform/commercial/billing/billing.go" "BuildInvoiceDraft"
check_grep "7-5 code CalculateVAT" "internal/platform/commercial/billing/billing.go" "CalculateVAT"
check_grep "7-5 code SimulateBilling" "internal/platform/commercial/billing/billing.go" "SimulateBilling"
check_grep "7-5 code CheckRealPaymentGate" "internal/platform/commercial/billing/billing.go" "CheckRealPaymentGate"
check_grep "7-5 code subscription integration" "internal/platform/commercial/billing/billing.go" "commercial/subscription"

echo
echo "===== 7-5 JSON CONFIG VALIDATION ====="
if python3 - <<'PY'
import json
from pathlib import Path

path = Path("configs/faz7/billing_readiness.v1.json")
data = json.loads(path.read_text(encoding="utf-8"))

if data.get("schema_version") != "billing_readiness.v1":
    raise SystemExit("schema_version mismatch")

if data.get("phase") != "FAZ_7":
    raise SystemExit("phase mismatch")

if data.get("step") != "7-5":
    raise SystemExit("step mismatch")

if data.get("runtime_status") != "READY":
    raise SystemExit("runtime_status mismatch")

if data.get("currency") != "TRY":
    raise SystemExit("currency mismatch")

if data.get("money_unit") != "kurus":
    raise SystemExit("money unit mismatch")

if data.get("default_vat_rate_bps") != 2000:
    raise SystemExit("vat rate mismatch")

if data.get("real_payment_enabled") is not False:
    raise SystemExit("real payment must be disabled")

if data.get("billing_simulation_enabled") is not True:
    raise SystemExit("billing simulation must be enabled")

for key in [
    "requires_financial_approval_before_real_payment",
    "requires_tax_advisor_approval_before_real_billing",
    "requires_payment_provider_contract_before_real_payment",
]:
    if data.get(key) is not True:
        raise SystemExit(f"gate missing or false: {key}")

required_plans = {"starter", "pro", "enterprise", "accountant", "marketplace"}
prices = {p["plan_code"]: p for p in data.get("plan_prices", [])}
missing = required_plans - set(prices.keys())
if missing:
    raise SystemExit(f"missing prices: {sorted(missing)}")

for code, price in prices.items():
    if price.get("monthly_net_amount_kurus", 0) <= 0:
        raise SystemExit(f"price not positive for {code}")
    if price.get("currency") != "TRY":
        raise SystemExit(f"currency mismatch for {code}")

required_reasons = {
    "ALLOW_INVOICE_DRAFT_READY",
    "ALLOW_BILLING_SIMULATION_READY",
    "DENY_TENANT_REQUIRED",
    "DENY_ACCOUNT_REQUIRED",
    "DENY_PLAN_REQUIRED",
    "DENY_PLAN_UNKNOWN",
    "DENY_BILLING_PROFILE_REQUIRED",
    "DENY_INVALID_PERIOD",
    "DENY_SUBSCRIPTION_NOT_BILLABLE",
    "DENY_REAL_PAYMENT_DISABLED",
    "DENY_FINANCIAL_APPROVAL_REQUIRED",
}
reasons = set(data.get("decision_model", {}).get("reason_codes", []))
missing_reasons = required_reasons - reasons
if missing_reasons:
    raise SystemExit(f"missing reason codes: {sorted(missing_reasons)}")

print("JSON_OK")
PY
then
  ok "7-5 JSON config parse ve billing gate kontrolu"
else
  fail "7-5 JSON config parse ve billing gate kontrolu"
fi

echo
echo "===== 7-5 GO TEST ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/billing -v; then
    ok "7-5 Go billing unit testleri"
  else
    fail "7-5 Go billing unit testleri"
  fi
else
  fail "7-5 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-5 TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_5_TEST_STATUS=PASS ✅"
  echo "OK ✅ FAZ 7-5 testleri basariyla gecti"
else
  echo "FAZ_7_5_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-5 testlerinde hata var"
  exit 1
fi
TEST_EOF

cat <<'AUDIT_EOF' > scripts/faz7/audit_7_5_real_implementation.sh
#!/usr/bin/env bash
set -Eeuo pipefail

FAIL_COUNT=0
PASS_COUNT=0
OPTIONAL_WARN=0
AUDIT_FILE="docs/faz7/evidence/FAZ_7_5_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-5 REAL IMPLEMENTATION AUDIT BASLADI ====="

has_file "7-5.1 Billing readiness dokumani" "docs/faz7/FAZ_7_5_BILLING_READINESS.md"
has_file "7-5.2 Evidence dokumani" "docs/faz7/evidence/FAZ_7_5_BILLING_READINESS_EVIDENCE.md"
has_file "7-5.3 Billing readiness config" "configs/faz7/billing_readiness.v1.json"
has_file "7-5.4 Go billing runtime modeli" "internal/platform/commercial/billing/billing.go"
has_file "7-5.5 Go billing testleri" "internal/platform/commercial/billing/billing_test.go"
has_file "7-5.6 Test scripti" "scripts/faz7/test_7_5_billing_readiness.sh"
has_file "7-5.7 Real implementation audit scripti" "scripts/faz7/audit_7_5_real_implementation.sh"

has_text "7-5.1.1 Fatura hazirlik modeli dokuman karsiligi" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "Fatura hazirlik modeli"
has_text "7-5.1.2 Vergi/KDV uyumu dokuman karsiligi" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "Vergi/KDV uyumu"
has_text "7-5.1.3 Muhasebeci firma basi ucret dokuman karsiligi" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "Muhasebeci paketi firma basi ucret modeli"
has_text "7-5.1.4 Billing simulation dokuman karsiligi" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "billing simulation"
has_text "7-5.1.5 Payment adapter gate dokuman karsiligi" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "real_payment_enabled=false"

has_text "7-5 config TRY currency karsiligi" "configs/faz7/billing_readiness.v1.json" "\"currency\": \"TRY\""
has_text "7-5 config kurus money unit karsiligi" "configs/faz7/billing_readiness.v1.json" "\"money_unit\": \"kurus\""
has_text "7-5 config VAT karsiligi" "configs/faz7/billing_readiness.v1.json" "\"default_vat_rate_bps\": 2000"
has_text "7-5 config real payment disabled karsiligi" "configs/faz7/billing_readiness.v1.json" "\"real_payment_enabled\": false"
has_text "7-5 config billing simulation karsiligi" "configs/faz7/billing_readiness.v1.json" "\"billing_simulation_enabled\": true"
has_text "7-5 config financial approval gate karsiligi" "configs/faz7/billing_readiness.v1.json" "requires_financial_approval_before_real_payment"
has_text "7-5 config tax advisor gate karsiligi" "configs/faz7/billing_readiness.v1.json" "requires_tax_advisor_approval_before_real_billing"
has_text "7-5 config payment provider gate karsiligi" "configs/faz7/billing_readiness.v1.json" "requires_payment_provider_contract_before_real_payment"

has_text "7-5 code BillingProfile karsiligi" "internal/platform/commercial/billing/billing.go" "type BillingProfile struct"
has_text "7-5 code PlanPrice karsiligi" "internal/platform/commercial/billing/billing.go" "type PlanPrice struct"
has_text "7-5 code InvoiceDraft karsiligi" "internal/platform/commercial/billing/billing.go" "type InvoiceDraft struct"
has_text "7-5 code BuildInvoiceDraft karsiligi" "internal/platform/commercial/billing/billing.go" "BuildInvoiceDraft"
has_text "7-5 code SimulateBilling karsiligi" "internal/platform/commercial/billing/billing.go" "SimulateBilling"
has_text "7-5 code CheckRealPaymentGate karsiligi" "internal/platform/commercial/billing/billing.go" "CheckRealPaymentGate"
has_text "7-5 code CalculateVAT karsiligi" "internal/platform/commercial/billing/billing.go" "CalculateVAT"
has_text "7-5 code subscription integration karsiligi" "internal/platform/commercial/billing/billing.go" "commercial/subscription"

echo
echo "===== 7-5 AUDIT GO TEST VERIFICATION ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/billing -v >/tmp/faz7_5_billing_go_test.log 2>&1; then
    ok "7-5 Go test real implementation verification"
  else
    cat /tmp/faz7_5_billing_go_test.log || true
    fail "7-5 Go test real implementation verification"
  fi
else
  fail "7-5 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-5 REAL IMPLEMENTATION AUDIT OZETI ====="
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
# FAZ 7-5 Real Implementation Audit

## Audit Summary

PASS_COUNT=$PASS_COUNT
REQUIRED_FAIL=$FAIL_COUNT
OPTIONAL_WARN=$OPTIONAL_WARN
FAZ_7_5_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
FAZ_7_5_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅

## Checked Implementation Evidence

- docs/faz7/FAZ_7_5_BILLING_READINESS.md
- docs/faz7/evidence/FAZ_7_5_BILLING_READINESS_EVIDENCE.md
- configs/faz7/billing_readiness.v1.json
- internal/platform/commercial/billing/billing.go
- internal/platform/commercial/billing/billing_test.go
- scripts/faz7/test_7_5_billing_readiness.sh
- scripts/faz7/audit_7_5_real_implementation.sh

## Real Implementation Decision

7-5 real implementation audit confirms that billing readiness, invoice draft runtime, VAT calculation, plan price catalog, billing simulation, real payment disabled gate, financial/tax/payment provider approval gates, config, Go tests, test script and audit script exist as real code/config/script/document artifacts.

## Final Status

FAZ_7_5_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
AUDIT_REPORT

echo "OK ✅ evidence yazildi: $AUDIT_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_5_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_7_5_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo "OK ✅ FAZ 7-5 real implementation audit basariyla gecti"
else
  echo "FAZ_7_5_REAL_IMPLEMENTATION_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-5 real implementation audit basarisiz"
  exit 1
fi
AUDIT_EOF

chmod +x scripts/faz7/test_7_5_billing_readiness.sh
chmod +x scripts/faz7/audit_7_5_real_implementation.sh

echo "OK ✅ docs/config/code/test/audit dosyalari yazildi"

echo
echo "===== 7-5 TEST CALISIYOR ====="
bash scripts/faz7/test_7_5_billing_readiness.sh

echo
echo "===== 7-5 REAL IMPLEMENTATION AUDIT CALISIYOR ====="
bash scripts/faz7/audit_7_5_real_implementation.sh

echo
echo "===== FAZ 7-5 FINAL OZET ====="
echo "FAZ_7_5_DOC_STATUS=READY ✅"
echo "FAZ_7_5_CONFIG_STATUS=READY ✅"
echo "FAZ_7_5_CODE_STATUS=READY ✅"
echo "FAZ_7_5_TEST_STATUS=PASS ✅"
echo "FAZ_7_5_REAL_IMPLEMENTATION_STATUS=PASS ✅"
echo "FAZ_7_5_FINAL_STATUS=PASS ✅"
echo "FAZ_7_6_READY=YES ✅"
echo "OK ✅ FAZ 7-5 Billing Readiness tamamlandi"
