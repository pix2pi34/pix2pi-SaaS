#!/usr/bin/env bash
set -Eeuo pipefail

echo "===== FAZ 7-6 TENANT ONBOARDING / SELF-SERVICE READINESS BASLADI ====="

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="backups/faz7/7-6_${TS}"

mkdir -p "$BACKUP_DIR"
mkdir -p docs/faz7/evidence
mkdir -p configs/faz7
mkdir -p internal/platform/commercial/onboarding
mkdir -p scripts/faz7

echo
echo "===== 7-6 BACKUP ====="

backup_if_exists() {
  local path="$1"
  if [ -e "$path" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$path")"
    cp -a "$path" "$BACKUP_DIR/$path"
    echo "7-6 backup OK ✅ $path -> $BACKUP_DIR/$path"
  else
    echo "7-6 backup SKIP ✅ $path mevcut degil"
  fi
}

backup_if_exists "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md"
backup_if_exists "docs/faz7/evidence/FAZ_7_6_TENANT_ONBOARDING_EVIDENCE.md"
backup_if_exists "docs/faz7/evidence/FAZ_7_6_REAL_IMPLEMENTATION_AUDIT.md"
backup_if_exists "configs/faz7/tenant_onboarding.v1.json"
backup_if_exists "internal/platform/commercial/onboarding/onboarding.go"
backup_if_exists "internal/platform/commercial/onboarding/onboarding_test.go"
backup_if_exists "scripts/faz7/test_7_6_tenant_onboarding_self_service_readiness.sh"
backup_if_exists "scripts/faz7/audit_7_6_real_implementation.sh"

echo "7-6 backup tamam OK ✅"

echo
echo "===== 7-6 DOSYALAR YAZILIYOR ====="

cat <<'DOC_EOF' > docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md
# 7-6 — Tenant Onboarding / Self-Service Readiness

## Adim Amaci

Bu adim Pix2pi icin self-service tenant onboarding hazirligini kurar.

7-6 sonunda:

- Yeni isletme kayit akisi modellenir.
- Tenant olusturma modeli hazirlanir.
- Ilk admin kullanici modeli hazirlanir.
- Demo veri / bos baslangic secimi modellenir.
- Trial subscription baslatma akisi 7-4 subscription runtime ile baglanir.
- Billing profile hazirligi 7-5 billing readiness ile baglanir.
- Onboarding audit izi olusturulur.
- 7-7 Public Website / Landing / Demo Flow icin temel hazirlanir.

## 7-6.1 Onboarding Akisi

### 7-6.1.1 Yeni isletme kayit akisi
Durum: IMPLEMENTED_OR_PRESENT

Yeni isletme kaydi asagidaki alanlarla baslar:

- business_name
- legal_name
- tax_number
- tax_office
- billing_email
- billing_address
- admin_user_id
- admin_email
- plan_code
- start_mode

### 7-6.1.2 Tenant olusturma
Durum: IMPLEMENTED_OR_PRESENT

Tenant olusturma hazirlik modeli:

- tenant_id zorunludur
- account_id zorunludur
- plan_code zorunludur
- tenant_status ACTIVE olarak hazirlanir
- onboarding_status READY_FOR_TRIAL olarak uretilebilir

### 7-6.1.3 Ilk admin kullanici
Durum: IMPLEMENTED_OR_PRESENT

Ilk admin kullanici zorunlu alanlari:

- admin_user_id
- admin_email
- role=TENANT_ADMIN
- tenant_id baglantisi

Admin kullanici olmadan onboarding reddedilir.

### 7-6.1.4 Demo veri / bos baslangic secimi
Durum: IMPLEMENTED_OR_PRESENT

Baslangic modu iki sekilde tanimlanir:

- demo_data
- blank

Gecersiz start_mode reddedilir.

### 7-6.1.5 Onboarding audit izi
Durum: IMPLEMENTED_OR_PRESENT

Onboarding sonucu audit edilebilir alanlar uretir:

- tenant_id
- account_id
- admin_user_id
- admin_email
- plan_code
- start_mode
- onboarding_status
- subscription_status
- billing_status
- decision
- reason_code

## 7-6.2 Subscription Baglantisi

Durum: IMPLEMENTED_OR_PRESENT

Onboarding runtime, 7-4 subscription runtime ile baglanir.

Basarili onboarding sonucunda:

- trial subscription baslar
- subscription status TRIALING olur
- trial_ends_at olusur
- tenant subscription account hazirlanir

## 7-6.3 Billing Profile Baglantisi

Durum: IMPLEMENTED_OR_PRESENT

Onboarding runtime, 7-5 billing readiness ile baglanir.

Basarili onboarding sonucunda:

- billing profile olusur
- invoice draft simulation hazirlanir
- real payment kapali kalir
- billing simulation acik kalir

## 7-6.4 Code Artifact

Durum: IMPLEMENTED_OR_PRESENT

Tenant onboarding Go modeli:

- internal/platform/commercial/onboarding/onboarding.go
- internal/platform/commercial/onboarding/onboarding_test.go

## 7-6.5 Config Artifact

Durum: IMPLEMENTED_OR_PRESENT

Tenant onboarding config dosyasi:

- configs/faz7/tenant_onboarding.v1.json

## 7-6.6 7-7 Gecis Hazirligi

Durum: IMPLEMENTED_OR_PRESENT

7-6 tamamlandiginda 7-7 icin asagidaki temeller hazirdir:

- public landing demo request model
- trial baslatma modeli
- onboarding form alanlari
- billing profile alanlari
- tenant/account/admin hazirlik modeli
- demo_data / blank secimi
- audit edilebilir onboarding sonucu

## 7-6 Final Karari

- FAZ_7_6_DOC_STATUS=READY
- FAZ_7_6_CONFIG_STATUS=READY
- FAZ_7_6_CODE_STATUS=READY
- FAZ_7_6_TEST_REQUIRED=YES
- FAZ_7_6_REAL_IMPLEMENTATION_AUDIT_REQUIRED=YES
- FAZ_7_7_READY_CONDITION=FAZ_7_6_TEST_STATUS_PASS_AND_REAL_IMPLEMENTATION_STATUS_PASS
DOC_EOF

cat <<'EVIDENCE_EOF' > docs/faz7/evidence/FAZ_7_6_TENANT_ONBOARDING_EVIDENCE.md
# FAZ 7-6 Tenant Onboarding / Self-Service Readiness Evidence

## Evidence Summary

- 7-6 tenant onboarding document created.
- Tenant onboarding config created.
- Go tenant onboarding runtime model created.
- Go tenant onboarding tests created.
- Test script created.
- Real implementation audit script created.
- 7-7 Public Website / Landing / Demo Flow is prepared as the next step.

## Evidence Files

- docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md
- docs/faz7/evidence/FAZ_7_6_TENANT_ONBOARDING_EVIDENCE.md
- configs/faz7/tenant_onboarding.v1.json
- internal/platform/commercial/onboarding/onboarding.go
- internal/platform/commercial/onboarding/onboarding_test.go
- scripts/faz7/test_7_6_tenant_onboarding_self_service_readiness.sh
- scripts/faz7/audit_7_6_real_implementation.sh

## Initial Seal Target

- FAZ_7_6_DOC_STATUS=READY
- FAZ_7_6_CONFIG_STATUS=READY
- FAZ_7_6_CODE_STATUS=READY
- FAZ_7_6_TEST_STATUS=PENDING_UNTIL_SCRIPT_RUN
- FAZ_7_6_REAL_IMPLEMENTATION_STATUS=PENDING_UNTIL_AUDIT_RUN
EVIDENCE_EOF

cat <<'JSON_EOF' > configs/faz7/tenant_onboarding.v1.json
{
  "schema_version": "tenant_onboarding.v1",
  "phase": "FAZ_7",
  "step": "7-6",
  "runtime_status": "READY",
  "source_catalog": "configs/faz7/product_plan_catalog.v1.json",
  "source_entitlement": "configs/faz7/entitlement_feature_gate.v1.json",
  "source_subscription": "configs/faz7/subscription_runtime.v1.json",
  "source_billing": "configs/faz7/billing_readiness.v1.json",
  "next_step": "7-7 Public Website / Landing / Demo Flow",
  "required_onboarding_fields": [
    "tenant_id",
    "account_id",
    "business_name",
    "legal_name",
    "tax_number",
    "tax_office",
    "billing_email",
    "billing_address",
    "admin_user_id",
    "admin_email",
    "plan_code",
    "start_mode"
  ],
  "tenant_statuses": [
    "ACTIVE",
    "PENDING",
    "BLOCKED"
  ],
  "onboarding_statuses": [
    "READY_FOR_TRIAL",
    "COMPLETED",
    "DENIED"
  ],
  "admin_roles": [
    "TENANT_ADMIN"
  ],
  "start_modes": [
    "demo_data",
    "blank"
  ],
  "trial": {
    "trial_enabled": true,
    "default_trial_days": 14,
    "real_payment_enabled": false,
    "billing_simulation_enabled": true
  },
  "audit_fields": [
    "tenant_id",
    "account_id",
    "admin_user_id",
    "admin_email",
    "plan_code",
    "start_mode",
    "tenant_status",
    "onboarding_status",
    "subscription_status",
    "billing_status",
    "decision",
    "reason_code"
  ],
  "decision_model": {
    "allow_status": "ALLOW",
    "deny_status": "DENY",
    "reason_codes": [
      "ALLOW_ONBOARDING_READY",
      "DENY_TENANT_REQUIRED",
      "DENY_ACCOUNT_REQUIRED",
      "DENY_BUSINESS_REQUIRED",
      "DENY_LEGAL_REQUIRED",
      "DENY_TAX_PROFILE_REQUIRED",
      "DENY_BILLING_PROFILE_REQUIRED",
      "DENY_ADMIN_REQUIRED",
      "DENY_PLAN_REQUIRED",
      "DENY_PLAN_UNKNOWN",
      "DENY_START_MODE_INVALID",
      "DENY_SUBSCRIPTION_FAILED",
      "DENY_BILLING_FAILED"
    ]
  }
}
JSON_EOF

cat <<'GO_EOF' > internal/platform/commercial/onboarding/onboarding.go
package onboarding

import (
	"fmt"
	"net/mail"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/billing"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/catalog"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/entitlement"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/subscription"
)

type TenantStatus string
type Status string
type StartMode string
type AdminRole string
type ReasonCode string

const (
	TenantStatusActive  TenantStatus = "ACTIVE"
	TenantStatusPending TenantStatus = "PENDING"
	TenantStatusBlocked TenantStatus = "BLOCKED"
)

const (
	StatusReadyForTrial Status = "READY_FOR_TRIAL"
	StatusCompleted     Status = "COMPLETED"
	StatusDenied        Status = "DENIED"
)

const (
	StartModeDemoData StartMode = "demo_data"
	StartModeBlank    StartMode = "blank"
)

const (
	AdminRoleTenantAdmin AdminRole = "TENANT_ADMIN"
)

const (
	ReasonAllowOnboardingReady     ReasonCode = "ALLOW_ONBOARDING_READY"
	ReasonDenyTenantRequired      ReasonCode = "DENY_TENANT_REQUIRED"
	ReasonDenyAccountRequired     ReasonCode = "DENY_ACCOUNT_REQUIRED"
	ReasonDenyBusinessRequired    ReasonCode = "DENY_BUSINESS_REQUIRED"
	ReasonDenyLegalRequired       ReasonCode = "DENY_LEGAL_REQUIRED"
	ReasonDenyTaxProfileRequired  ReasonCode = "DENY_TAX_PROFILE_REQUIRED"
	ReasonDenyBillingRequired     ReasonCode = "DENY_BILLING_PROFILE_REQUIRED"
	ReasonDenyAdminRequired       ReasonCode = "DENY_ADMIN_REQUIRED"
	ReasonDenyPlanRequired        ReasonCode = "DENY_PLAN_REQUIRED"
	ReasonDenyPlanUnknown         ReasonCode = "DENY_PLAN_UNKNOWN"
	ReasonDenyStartModeInvalid    ReasonCode = "DENY_START_MODE_INVALID"
	ReasonDenySubscriptionFailed  ReasonCode = "DENY_SUBSCRIPTION_FAILED"
	ReasonDenyBillingFailed       ReasonCode = "DENY_BILLING_FAILED"
)

type Request struct {
	TenantID string
	AccountID string

	BusinessName string
	LegalName string
	TaxNumber string
	TaxOffice string

	BillingEmail string
	BillingAddress string

	AdminUserID string
	AdminEmail string

	Plan catalog.PlanCode
	StartMode StartMode

	RequestedAt time.Time
	TrialDays int
}

type TenantRecord struct {
	TenantID string
	AccountID string
	BusinessName string
	LegalName string
	TaxNumber string
	TaxOffice string
	Status TenantStatus
	StartMode StartMode
	CreatedAt time.Time
}

type AdminUserRecord struct {
	TenantID string
	UserID string
	Email string
	Role AdminRole
	CreatedAt time.Time
}

type Decision struct {
	Status entitlement.DecisionStatus
	ReasonCode string
	ReasonMessage string

	TenantID string
	AccountID string
	AdminUserID string
	AdminEmail string
	PlanCode catalog.PlanCode
	StartMode StartMode

	TenantStatus TenantStatus
	OnboardingStatus Status
	SubscriptionStatus subscription.Status
	BillingStatus billing.BillingStatus
}

type Result struct {
	Tenant TenantRecord
	AdminUser AdminUserRecord
	Subscription subscription.Account
	BillingProfile billing.BillingProfile
	InvoiceDraft billing.InvoiceDraft
	Decision Decision
}

type Runtime struct {
	catalog catalog.Catalog
	subscriptionRuntime *subscription.Runtime
	billingRuntime *billing.Runtime

	DefaultTrialDays int
	RealPaymentEnabled bool
	BillingSimulationEnabled bool
}

func NewDefaultRuntime() (*Runtime, error) {
	c := catalog.DefaultCatalog()
	if err := c.Validate(); err != nil {
		return nil, fmt.Errorf("invalid catalog: %w", err)
	}

	subscriptionRuntime, err := subscription.NewRuntime(c)
	if err != nil {
		return nil, fmt.Errorf("invalid subscription runtime: %w", err)
	}

	billingRuntime, err := billing.NewDefaultRuntime()
	if err != nil {
		return nil, fmt.Errorf("invalid billing runtime: %w", err)
	}

	return &Runtime{
		catalog: c,
		subscriptionRuntime: subscriptionRuntime,
		billingRuntime: billingRuntime,
		DefaultTrialDays: 14,
		RealPaymentEnabled: false,
		BillingSimulationEnabled: true,
	}, nil
}

func (r *Runtime) StartTrialOnboarding(req Request) (Result, Decision) {
	if req.RequestedAt.IsZero() {
		req.RequestedAt = time.Now().UTC()
	}
	if req.TrialDays == 0 {
		req.TrialDays = r.DefaultTrialDays
	}

	if decision, ok := r.validateRequest(req); !ok {
		return Result{Decision: decision}, decision
	}

	tenant := TenantRecord{
		TenantID: req.TenantID,
		AccountID: req.AccountID,
		BusinessName: req.BusinessName,
		LegalName: req.LegalName,
		TaxNumber: req.TaxNumber,
		TaxOffice: req.TaxOffice,
		Status: TenantStatusActive,
		StartMode: req.StartMode,
		CreatedAt: req.RequestedAt,
	}

	admin := AdminUserRecord{
		TenantID: req.TenantID,
		UserID: req.AdminUserID,
		Email: req.AdminEmail,
		Role: AdminRoleTenantAdmin,
		CreatedAt: req.RequestedAt,
	}

	account, subscriptionDecision := r.subscriptionRuntime.StartTrial(
		req.TenantID,
		req.AccountID,
		req.Plan,
		req.RequestedAt,
		time.Duration(req.TrialDays) * 24 * time.Hour,
	)
	if subscriptionDecision.Status == entitlement.DecisionDeny {
		decision := r.deny(req, ReasonDenySubscriptionFailed, subscriptionDecision.ReasonMessage)
		decision.SubscriptionStatus = account.Status
		return Result{
			Tenant: tenant,
			AdminUser: admin,
			Subscription: account,
			Decision: decision,
		}, decision
	}

	profile := billing.BillingProfile{
		TenantID: req.TenantID,
		AccountID: req.AccountID,
		LegalName: req.LegalName,
		TaxNumber: req.TaxNumber,
		TaxOffice: req.TaxOffice,
		BillingEmail: req.BillingEmail,
		BillingAddress: req.BillingAddress,
	}

	invoiceDraft, billingDecision := r.billingRuntime.BuildInvoiceDraft(
		account,
		profile,
		req.RequestedAt,
		req.RequestedAt.Add(time.Duration(req.TrialDays) * 24 * time.Hour),
	)
	if billingDecision.Status == entitlement.DecisionDeny {
		decision := r.deny(req, ReasonDenyBillingFailed, billingDecision.ReasonMessage)
		decision.SubscriptionStatus = account.Status
		decision.BillingStatus = invoiceDraft.BillingStatus
		return Result{
			Tenant: tenant,
			AdminUser: admin,
			Subscription: account,
			BillingProfile: profile,
			InvoiceDraft: invoiceDraft,
			Decision: decision,
		}, decision
	}

	decision := Decision{
		Status: entitlement.DecisionAllow,
		ReasonCode: string(ReasonAllowOnboardingReady),
		ReasonMessage: "tenant onboarding is ready for trial",
		TenantID: req.TenantID,
		AccountID: req.AccountID,
		AdminUserID: req.AdminUserID,
		AdminEmail: req.AdminEmail,
		PlanCode: req.Plan,
		StartMode: req.StartMode,
		TenantStatus: tenant.Status,
		OnboardingStatus: StatusReadyForTrial,
		SubscriptionStatus: account.Status,
		BillingStatus: invoiceDraft.BillingStatus,
	}

	return Result{
		Tenant: tenant,
		AdminUser: admin,
		Subscription: account,
		BillingProfile: profile,
		InvoiceDraft: invoiceDraft,
		Decision: decision,
	}, decision
}

func (r *Runtime) CompleteOnboarding(result Result) (Result, Decision) {
	if result.Tenant.TenantID == "" || result.Subscription.TenantID == "" {
		decision := Decision{
			Status: entitlement.DecisionDeny,
			ReasonCode: string(ReasonDenyTenantRequired),
			ReasonMessage: "tenant result is required",
			OnboardingStatus: StatusDenied,
		}
		result.Decision = decision
		return result, decision
	}
	if result.AdminUser.UserID == "" {
		decision := Decision{
			Status: entitlement.DecisionDeny,
			ReasonCode: string(ReasonDenyAdminRequired),
			ReasonMessage: "admin user result is required",
			TenantID: result.Tenant.TenantID,
			AccountID: result.Tenant.AccountID,
			OnboardingStatus: StatusDenied,
		}
		result.Decision = decision
		return result, decision
	}

	result.Decision.Status = entitlement.DecisionAllow
	result.Decision.ReasonCode = string(ReasonAllowOnboardingReady)
	result.Decision.ReasonMessage = "tenant onboarding completed"
	result.Decision.OnboardingStatus = StatusCompleted

	return result, result.Decision
}

func (r *Runtime) validateRequest(req Request) (Decision, bool) {
	if req.TenantID == "" {
		return r.deny(req, ReasonDenyTenantRequired, "tenant id is required"), false
	}
	if req.AccountID == "" {
		return r.deny(req, ReasonDenyAccountRequired, "account id is required"), false
	}
	if req.BusinessName == "" {
		return r.deny(req, ReasonDenyBusinessRequired, "business name is required"), false
	}
	if req.LegalName == "" {
		return r.deny(req, ReasonDenyLegalRequired, "legal name is required"), false
	}
	if req.TaxNumber == "" || req.TaxOffice == "" {
		return r.deny(req, ReasonDenyTaxProfileRequired, "tax number and tax office are required"), false
	}
	if req.BillingEmail == "" || req.BillingAddress == "" {
		return r.deny(req, ReasonDenyBillingRequired, "billing email and address are required"), false
	}
	if _, err := mail.ParseAddress(req.BillingEmail); err != nil {
		return r.deny(req, ReasonDenyBillingRequired, "billing email is invalid"), false
	}
	if req.AdminUserID == "" || req.AdminEmail == "" {
		return r.deny(req, ReasonDenyAdminRequired, "admin user id and email are required"), false
	}
	if _, err := mail.ParseAddress(req.AdminEmail); err != nil {
		return r.deny(req, ReasonDenyAdminRequired, "admin email is invalid"), false
	}
	if req.Plan == "" {
		return r.deny(req, ReasonDenyPlanRequired, "plan code is required"), false
	}
	if _, ok := r.catalog.Plan(req.Plan); !ok {
		return r.deny(req, ReasonDenyPlanUnknown, "plan is not defined in catalog"), false
	}
	if req.StartMode != StartModeDemoData && req.StartMode != StartModeBlank {
		return r.deny(req, ReasonDenyStartModeInvalid, "start mode must be demo_data or blank"), false
	}
	if req.TrialDays < 0 {
		return r.deny(req, ReasonDenySubscriptionFailed, "trial days cannot be negative"), false
	}

	return Decision{}, true
}

func (r *Runtime) deny(req Request, reason ReasonCode, message string) Decision {
	return Decision{
		Status: entitlement.DecisionDeny,
		ReasonCode: string(reason),
		ReasonMessage: message,
		TenantID: req.TenantID,
		AccountID: req.AccountID,
		AdminUserID: req.AdminUserID,
		AdminEmail: req.AdminEmail,
		PlanCode: req.Plan,
		StartMode: req.StartMode,
		TenantStatus: TenantStatusBlocked,
		OnboardingStatus: StatusDenied,
	}
}
GO_EOF

cat <<'GO_TEST_EOF' > internal/platform/commercial/onboarding/onboarding_test.go
package onboarding

import (
	"testing"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/billing"
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

func baseRequest() Request {
	return Request{
		TenantID: "tenant_7",
		AccountID: "account_7",
		BusinessName: "Pix2pi Pilot",
		LegalName: "Pix2pi Pilot Ltd",
		TaxNumber: "1234567890",
		TaxOffice: "Istanbul",
		BillingEmail: "billing@example.com",
		BillingAddress: "Istanbul Turkiye",
		AdminUserID: "user_admin_7",
		AdminEmail: "admin@example.com",
		Plan: catalog.PlanPro,
		StartMode: StartModeDemoData,
		RequestedAt: time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC),
		TrialDays: 14,
	}
}

func TestRuntime_StartTrialOnboarding_Success(t *testing.T) {
	runtime := mustRuntime(t)

	result, decision := runtime.StartTrialOnboarding(baseRequest())

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if decision.ReasonCode != string(ReasonAllowOnboardingReady) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
	if result.Tenant.Status != TenantStatusActive {
		t.Fatalf("expected tenant active, got %s", result.Tenant.Status)
	}
	if result.AdminUser.Role != AdminRoleTenantAdmin {
		t.Fatalf("expected tenant admin role, got %s", result.AdminUser.Role)
	}
	if result.Subscription.Status != subscription.StatusTrialing {
		t.Fatalf("expected trialing subscription, got %s", result.Subscription.Status)
	}
	if result.InvoiceDraft.BillingStatus != billing.BillingStatusSimulationReady {
		t.Fatalf("expected billing simulation ready, got %s", result.InvoiceDraft.BillingStatus)
	}
	if result.InvoiceDraft.RealPaymentEnabled {
		t.Fatal("real payment must be disabled during onboarding readiness")
	}
}

func TestRuntime_StartTrialOnboarding_BlankStartMode(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.StartMode = StartModeBlank

	result, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s", decision.Status)
	}
	if result.Tenant.StartMode != StartModeBlank {
		t.Fatalf("expected blank start mode, got %s", result.Tenant.StartMode)
	}
}

func TestRuntime_StartTrialOnboarding_UsesDefaultTrialDays(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.TrialDays = 0

	result, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s", decision.Status)
	}

	expectedEnd := req.RequestedAt.Add(14 * 24 * time.Hour)
	if !result.Subscription.TrialEndsAt.Equal(expectedEnd) {
		t.Fatalf("expected default trial end %s, got %s", expectedEnd, result.Subscription.TrialEndsAt)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesMissingTenant(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.TenantID = ""

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyTenantRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesMissingAccount(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.AccountID = ""

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyAccountRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesMissingBusinessName(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.BusinessName = ""

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyBusinessRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesMissingLegalName(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.LegalName = ""

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyLegalRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesMissingTaxProfile(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.TaxNumber = ""

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyTaxProfileRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesMissingBillingProfile(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.BillingEmail = ""

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyBillingRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesInvalidBillingEmail(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.BillingEmail = "invalid"

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyBillingRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesMissingAdmin(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.AdminUserID = ""

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyAdminRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesInvalidAdminEmail(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.AdminEmail = "invalid"

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyAdminRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesUnknownPlan(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.Plan = catalog.PlanCode("unknown")

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyPlanUnknown) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesInvalidStartMode(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.StartMode = StartMode("invalid")

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyStartModeInvalid) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CompleteOnboarding(t *testing.T) {
	runtime := mustRuntime(t)

	result, decision := runtime.StartTrialOnboarding(baseRequest())
	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected initial allow, got %s", decision.Status)
	}

	completed, completeDecision := runtime.CompleteOnboarding(result)

	if completeDecision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected complete allow, got %s", completeDecision.Status)
	}
	if completed.Decision.OnboardingStatus != StatusCompleted {
		t.Fatalf("expected completed onboarding, got %s", completed.Decision.OnboardingStatus)
	}
}
GO_TEST_EOF

cat <<'TEST_EOF' > scripts/faz7/test_7_6_tenant_onboarding_self_service_readiness.sh
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

echo "===== FAZ 7-6 TEST BASLADI ====="

check_file "7-6" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md"
check_file "7-6" "docs/faz7/evidence/FAZ_7_6_TENANT_ONBOARDING_EVIDENCE.md"
check_file "7-6" "configs/faz7/tenant_onboarding.v1.json"
check_file "7-6" "internal/platform/commercial/onboarding/onboarding.go"
check_file "7-6" "internal/platform/commercial/onboarding/onboarding_test.go"
check_file "7-6" "scripts/faz7/test_7_6_tenant_onboarding_self_service_readiness.sh"
check_file "7-6" "scripts/faz7/audit_7_6_real_implementation.sh"

check_grep "7-6.1 Onboarding akisi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.1 Onboarding Akisi"
check_grep "7-6.1.1 Yeni isletme kayit akisi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.1.1 Yeni isletme kayit akisi"
check_grep "7-6.1.2 Tenant olusturma" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.1.2 Tenant olusturma"
check_grep "7-6.1.3 Ilk admin kullanici" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.1.3 Ilk admin kullanici"
check_grep "7-6.1.4 Demo veri bos baslangic secimi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.1.4 Demo veri / bos baslangic secimi"
check_grep "7-6.1.5 Onboarding audit izi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.1.5 Onboarding audit izi"
check_grep "7-6.2 Subscription baglantisi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.2 Subscription Baglantisi"
check_grep "7-6.3 Billing profile baglantisi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.3 Billing Profile Baglantisi"
check_grep "7-6.4 Code artifact" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "internal/platform/commercial/onboarding/onboarding.go"
check_grep "7-6.5 Config artifact" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "configs/faz7/tenant_onboarding.v1.json"
check_grep "7-6.6 7-7 hazirlik" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-7 Public Website"

check_grep "7-6 code Request" "internal/platform/commercial/onboarding/onboarding.go" "type Request struct"
check_grep "7-6 code TenantRecord" "internal/platform/commercial/onboarding/onboarding.go" "type TenantRecord struct"
check_grep "7-6 code AdminUserRecord" "internal/platform/commercial/onboarding/onboarding.go" "type AdminUserRecord struct"
check_grep "7-6 code Result" "internal/platform/commercial/onboarding/onboarding.go" "type Result struct"
check_grep "7-6 code Runtime" "internal/platform/commercial/onboarding/onboarding.go" "type Runtime struct"
check_grep "7-6 code StartTrialOnboarding" "internal/platform/commercial/onboarding/onboarding.go" "StartTrialOnboarding"
check_grep "7-6 code CompleteOnboarding" "internal/platform/commercial/onboarding/onboarding.go" "CompleteOnboarding"
check_grep "7-6 code subscription integration" "internal/platform/commercial/onboarding/onboarding.go" "commercial/subscription"
check_grep "7-6 code billing integration" "internal/platform/commercial/onboarding/onboarding.go" "commercial/billing"

echo
echo "===== 7-6 JSON CONFIG VALIDATION ====="
if python3 - <<'PY'
import json
from pathlib import Path

path = Path("configs/faz7/tenant_onboarding.v1.json")
data = json.loads(path.read_text(encoding="utf-8"))

if data.get("schema_version") != "tenant_onboarding.v1":
    raise SystemExit("schema_version mismatch")

if data.get("phase") != "FAZ_7":
    raise SystemExit("phase mismatch")

if data.get("step") != "7-6":
    raise SystemExit("step mismatch")

if data.get("runtime_status") != "READY":
    raise SystemExit("runtime_status mismatch")

required_fields = {
    "tenant_id",
    "account_id",
    "business_name",
    "legal_name",
    "tax_number",
    "tax_office",
    "billing_email",
    "billing_address",
    "admin_user_id",
    "admin_email",
    "plan_code",
    "start_mode",
}
fields = set(data.get("required_onboarding_fields", []))
missing_fields = required_fields - fields
if missing_fields:
    raise SystemExit(f"missing required fields: {sorted(missing_fields)}")

required_modes = {"demo_data", "blank"}
modes = set(data.get("start_modes", []))
missing_modes = required_modes - modes
if missing_modes:
    raise SystemExit(f"missing start modes: {sorted(missing_modes)}")

trial = data.get("trial", {})
if trial.get("trial_enabled") is not True:
    raise SystemExit("trial must be enabled")
if trial.get("default_trial_days") != 14:
    raise SystemExit("default trial days mismatch")
if trial.get("real_payment_enabled") is not False:
    raise SystemExit("real payment must be disabled")
if trial.get("billing_simulation_enabled") is not True:
    raise SystemExit("billing simulation must be enabled")

required_reasons = {
    "ALLOW_ONBOARDING_READY",
    "DENY_TENANT_REQUIRED",
    "DENY_ACCOUNT_REQUIRED",
    "DENY_BUSINESS_REQUIRED",
    "DENY_LEGAL_REQUIRED",
    "DENY_TAX_PROFILE_REQUIRED",
    "DENY_BILLING_PROFILE_REQUIRED",
    "DENY_ADMIN_REQUIRED",
    "DENY_PLAN_REQUIRED",
    "DENY_PLAN_UNKNOWN",
    "DENY_START_MODE_INVALID",
    "DENY_SUBSCRIPTION_FAILED",
    "DENY_BILLING_FAILED",
}
reasons = set(data.get("decision_model", {}).get("reason_codes", []))
missing_reasons = required_reasons - reasons
if missing_reasons:
    raise SystemExit(f"missing reason codes: {sorted(missing_reasons)}")

print("JSON_OK")
PY
then
  ok "7-6 JSON config parse ve onboarding gate kontrolu"
else
  fail "7-6 JSON config parse ve onboarding gate kontrolu"
fi

echo
echo "===== 7-6 GO TEST ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/onboarding -v; then
    ok "7-6 Go onboarding unit testleri"
  else
    fail "7-6 Go onboarding unit testleri"
  fi
else
  fail "7-6 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-6 TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_6_TEST_STATUS=PASS ✅"
  echo "OK ✅ FAZ 7-6 testleri basariyla gecti"
else
  echo "FAZ_7_6_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-6 testlerinde hata var"
  exit 1
fi
TEST_EOF

cat <<'AUDIT_EOF' > scripts/faz7/audit_7_6_real_implementation.sh
#!/usr/bin/env bash
set -Eeuo pipefail

FAIL_COUNT=0
PASS_COUNT=0
OPTIONAL_WARN=0
AUDIT_FILE="docs/faz7/evidence/FAZ_7_6_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-6 REAL IMPLEMENTATION AUDIT BASLADI ====="

has_file "7-6.1 Tenant onboarding dokumani" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md"
has_file "7-6.2 Evidence dokumani" "docs/faz7/evidence/FAZ_7_6_TENANT_ONBOARDING_EVIDENCE.md"
has_file "7-6.3 Tenant onboarding config" "configs/faz7/tenant_onboarding.v1.json"
has_file "7-6.4 Go onboarding runtime modeli" "internal/platform/commercial/onboarding/onboarding.go"
has_file "7-6.5 Go onboarding testleri" "internal/platform/commercial/onboarding/onboarding_test.go"
has_file "7-6.6 Test scripti" "scripts/faz7/test_7_6_tenant_onboarding_self_service_readiness.sh"
has_file "7-6.7 Real implementation audit scripti" "scripts/faz7/audit_7_6_real_implementation.sh"

has_text "7-6.1.1 Yeni isletme kayit akisi dokuman karsiligi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "Yeni isletme kayit akisi"
has_text "7-6.1.2 Tenant olusturma dokuman karsiligi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "Tenant olusturma"
has_text "7-6.1.3 Ilk admin kullanici dokuman karsiligi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "Ilk admin kullanici"
has_text "7-6.1.4 Demo/bos baslangic dokuman karsiligi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "Demo veri / bos baslangic secimi"
has_text "7-6.1.5 Audit izi dokuman karsiligi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "Onboarding audit izi"

has_text "7-6 config tenant_id karsiligi" "configs/faz7/tenant_onboarding.v1.json" "tenant_id"
has_text "7-6 config admin role karsiligi" "configs/faz7/tenant_onboarding.v1.json" "TENANT_ADMIN"
has_text "7-6 config demo_data karsiligi" "configs/faz7/tenant_onboarding.v1.json" "demo_data"
has_text "7-6 config blank karsiligi" "configs/faz7/tenant_onboarding.v1.json" "blank"
has_text "7-6 config trial 14 gun karsiligi" "configs/faz7/tenant_onboarding.v1.json" "\"default_trial_days\": 14"
has_text "7-6 config real payment disabled karsiligi" "configs/faz7/tenant_onboarding.v1.json" "\"real_payment_enabled\": false"
has_text "7-6 config billing simulation karsiligi" "configs/faz7/tenant_onboarding.v1.json" "\"billing_simulation_enabled\": true"

has_text "7-6 code Request karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "type Request struct"
has_text "7-6 code TenantRecord karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "type TenantRecord struct"
has_text "7-6 code AdminUserRecord karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "type AdminUserRecord struct"
has_text "7-6 code StartModeDemoData karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "StartModeDemoData"
has_text "7-6 code StartModeBlank karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "StartModeBlank"
has_text "7-6 code AdminRoleTenantAdmin karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "AdminRoleTenantAdmin"
has_text "7-6 code StartTrialOnboarding karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "StartTrialOnboarding"
has_text "7-6 code CompleteOnboarding karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "CompleteOnboarding"
has_text "7-6 code subscription integration karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "commercial/subscription"
has_text "7-6 code billing integration karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "commercial/billing"

echo
echo "===== 7-6 AUDIT GO TEST VERIFICATION ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/onboarding -v >/tmp/faz7_6_onboarding_go_test.log 2>&1; then
    ok "7-6 Go test real implementation verification"
  else
    cat /tmp/faz7_6_onboarding_go_test.log || true
    fail "7-6 Go test real implementation verification"
  fi
else
  fail "7-6 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-6 REAL IMPLEMENTATION AUDIT OZETI ====="
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
# FAZ 7-6 Real Implementation Audit

## Audit Summary

PASS_COUNT=$PASS_COUNT
REQUIRED_FAIL=$FAIL_COUNT
OPTIONAL_WARN=$OPTIONAL_WARN
FAZ_7_6_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
FAZ_7_6_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅

## Checked Implementation Evidence

- docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md
- docs/faz7/evidence/FAZ_7_6_TENANT_ONBOARDING_EVIDENCE.md
- configs/faz7/tenant_onboarding.v1.json
- internal/platform/commercial/onboarding/onboarding.go
- internal/platform/commercial/onboarding/onboarding_test.go
- scripts/faz7/test_7_6_tenant_onboarding_self_service_readiness.sh
- scripts/faz7/audit_7_6_real_implementation.sh

## Real Implementation Decision

7-6 real implementation audit confirms that tenant onboarding readiness, new business registration model, tenant/account/admin model, demo_data/blank start mode, trial subscription start, billing profile preparation, invoice draft simulation, config, Go tests, test script and audit script exist as real code/config/script/document artifacts.

## Final Status

FAZ_7_6_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
AUDIT_REPORT

echo "OK ✅ evidence yazildi: $AUDIT_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_6_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_7_6_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo "OK ✅ FAZ 7-6 real implementation audit basariyla gecti"
else
  echo "FAZ_7_6_REAL_IMPLEMENTATION_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-6 real implementation audit basarisiz"
  exit 1
fi
AUDIT_EOF

chmod +x scripts/faz7/test_7_6_tenant_onboarding_self_service_readiness.sh
chmod +x scripts/faz7/audit_7_6_real_implementation.sh

echo "OK ✅ docs/config/code/test/audit dosyalari yazildi"

echo
echo "===== 7-6 TEST CALISIYOR ====="
bash scripts/faz7/test_7_6_tenant_onboarding_self_service_readiness.sh

echo
echo "===== 7-6 REAL IMPLEMENTATION AUDIT CALISIYOR ====="
bash scripts/faz7/audit_7_6_real_implementation.sh

echo
echo "===== FAZ 7-6 FINAL OZET ====="
echo "FAZ_7_6_DOC_STATUS=READY ✅"
echo "FAZ_7_6_CONFIG_STATUS=READY ✅"
echo "FAZ_7_6_CODE_STATUS=READY ✅"
echo "FAZ_7_6_TEST_STATUS=PASS ✅"
echo "FAZ_7_6_REAL_IMPLEMENTATION_STATUS=PASS ✅"
echo "FAZ_7_6_FINAL_STATUS=PASS ✅"
echo "FAZ_7_7_READY=YES ✅"
echo "OK ✅ FAZ 7-6 Tenant Onboarding / Self-Service Readiness tamamlandi"
