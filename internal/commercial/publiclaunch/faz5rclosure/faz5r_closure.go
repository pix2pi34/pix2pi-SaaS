package faz5rclosure

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type ClosureStatus string

const (
	StatusReady   ClosureStatus = "READY"
	StatusPass    ClosureStatus = "PASS"
	StatusSealed  ClosureStatus = "SEALED"
	StatusBlocked ClosureStatus = "BLOCKED"
)

type ClosureDomain string

const (
	DomainCompliance       ClosureDomain = "COMPLIANCE_KVKK_CONTRACT_CONSENT"
	DomainSupportOps       ClosureDomain = "SUPPORT_OPS"
	DomainCommercialGate   ClosureDomain = "COMMERCIAL_GATE"
	DomainBillingLifecycle ClosureDomain = "BILLING_TENANT_LIFECYCLE_SALES_OPS"
	DomainPricing          ClosureDomain = "PRICING"
	DomainPublicDeveloper  ClosureDomain = "PUBLIC_DEVELOPER_SURFACES"
	DomainLaunchSafety     ClosureDomain = "PUBLIC_LAUNCH_SAFETY"
	DomainNextPhase        ClosureDomain = "NEXT_PHASE_HANDOFF"
)

type ClosureItem struct {
	Key                        string
	Domain                     ClosureDomain
	Title                      string
	Owner                      string
	Status                     ClosureStatus
	Required                   bool
	HasEvidence                bool
	HasCounterBasedAudit       bool
	RequiredFailCount          int
	OptionalWarnCount          int
	DocReady                   bool
	ConfigReady                bool
	CodeReady                  bool
	TestPass                   bool
	RealImplementationPass     bool
	ProductionLaunchAllowed    bool
	RealCustomerCollectionOpen bool
	RealBillingEnabled         bool
	PaymentCollectionEnabled   bool
	PublicDeveloperAccessOpen  bool
	CheckoutEnabled            bool
	SandboxLiveEnabled         bool
	RequiresEvidence           bool
	RequiresCounterAudit       bool
	RequiresDocReady           bool
	RequiresConfigReady        bool
	RequiresCodeReady          bool
	RequiresTestPass           bool
	RequiresRealImplementation bool
	RequiresLaunchBlocked      bool
	RequiresCustomerClosed     bool
	RequiresBillingClosed      bool
	RequiresPaymentClosed      bool
	RequiresDeveloperClosed    bool
	RequiresCheckoutClosed     bool
	RequiresSandboxClosed      bool
	BlocksProductionLaunch     bool
	BlocksRealCustomer         bool
	BlocksRealBilling          bool
	BlocksPaymentCollection    bool
	BlocksDeveloperAccess      bool
	BlocksCheckout             bool
	BlocksSandboxLive          bool
	ReadyForNextPhase          bool
}

type ClosureInput struct {
	Phase                          string
	Target                         string
	GeneralFinalReviewReady        bool
	FinalClosureSealRequested      bool
	ProductionLaunchAllowed        bool
	RealCustomerCollectionOpen     bool
	RealBillingEnabled             bool
	PaymentCollectionEnabled       bool
	PublicDeveloperAccessOpen      bool
	CheckoutEnabled                bool
	SandboxLiveEnabled             bool
	RequiredItemKeys               []string
	RequiredDomains                []ClosureDomain
	Items                          []ClosureItem
	RequireEvidence                bool
	RequireCounterBasedAudit       bool
	RequireNoRequiredFail          bool
	RequireNoOptionalWarn          bool
	RequireDocReady                bool
	RequireConfigReady             bool
	RequireCodeReady               bool
	RequireTestPass                bool
	RequireRealImplementationPass  bool
	RequireProductionLaunchBlocked bool
	RequireRealCustomerClosed      bool
	RequireRealBillingClosed       bool
	RequirePaymentClosed           bool
	RequireDeveloperAccessClosed   bool
	RequireCheckoutClosed          bool
	RequireSandboxClosed           bool
	RequireNextPhaseReady          bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type ClosureResult struct {
	Status                     string
	GeneralFinalReviewReady    bool
	FinalClosureSealed         bool
	ProductionLaunchAllowed    bool
	RealCustomerCollectionOpen bool
	RealBillingEnabled         bool
	PaymentCollectionEnabled   bool
	PublicDeveloperAccessOpen  bool
	CheckoutEnabled            bool
	SandboxLiveEnabled         bool
	ReadyForNextPhase          bool
	RequiredFailCount          int
	OptionalWarnCount          int
	PassCount                  int
	Findings                   []Finding
}

func Evaluate(input ClosureInput) (ClosureResult, error) {
	result := ClosureResult{
		Status:                     "PASS",
		GeneralFinalReviewReady:    false,
		FinalClosureSealed:         false,
		ProductionLaunchAllowed:    false,
		RealCustomerCollectionOpen: false,
		RealBillingEnabled:         false,
		PaymentCollectionEnabled:   false,
		PublicDeveloperAccessOpen:  false,
		CheckoutEnabled:            false,
		SandboxLiveEnabled:         false,
		ReadyForNextPhase:          false,
		Findings:                   []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&result, "PHASE_MISSING", "phase boş olamaz")
	}
	if strings.TrimSpace(input.Target) == "" {
		addFail(&result, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionLaunchAllowed {
		addFail(&result, "PRODUCTION_LAUNCH_MUST_REMAIN_BLOCKED", "FAZ 5-R final closure production launch açamaz")
	}
	if input.RealCustomerCollectionOpen {
		addFail(&result, "REAL_CUSTOMER_COLLECTION_MUST_REMAIN_CLOSED", "gerçek müşteri toplama kapalı kalmalı")
	}
	if input.RealBillingEnabled {
		addFail(&result, "REAL_BILLING_MUST_REMAIN_CLOSED", "gerçek billing kapalı kalmalı")
	}
	if input.PaymentCollectionEnabled {
		addFail(&result, "PAYMENT_COLLECTION_MUST_REMAIN_CLOSED", "gerçek tahsilat kapalı kalmalı")
	}
	if input.PublicDeveloperAccessOpen {
		addFail(&result, "PUBLIC_DEVELOPER_ACCESS_MUST_REMAIN_CLOSED", "gerçek developer erişimi kapalı kalmalı")
	}
	if input.CheckoutEnabled {
		addFail(&result, "CHECKOUT_MUST_REMAIN_CLOSED", "checkout kapalı kalmalı")
	}
	if input.SandboxLiveEnabled {
		addFail(&result, "SANDBOX_LIVE_MUST_REMAIN_CLOSED", "canlı sandbox kapalı kalmalı")
	}

	itemByKey := map[string]ClosureItem{}
	domainCoverage := map[ClosureDomain]bool{}

	for _, item := range input.Items {
		key := strings.TrimSpace(item.Key)
		if key == "" {
			addFail(&result, "CLOSURE_ITEM_KEY_MISSING", "closure item key boş olamaz")
			continue
		}
		if _, exists := itemByKey[key]; exists {
			addFail(&result, "CLOSURE_ITEM_DUPLICATE", fmt.Sprintf("closure item duplicate: %s", key))
			continue
		}

		itemByKey[key] = item
		domainCoverage[item.Domain] = true

		if item.Required && item.Status != StatusReady && item.Status != StatusPass && item.Status != StatusSealed {
			addFail(&result, "REQUIRED_ITEM_NOT_READY", fmt.Sprintf("required closure item READY/PASS/SEALED değil: %s", key))
		} else if item.Required {
			result.PassCount++
		}

		checkBool(&result, input.RequireEvidence || item.RequiresEvidence, item.Required, item.HasEvidence, "EVIDENCE_REQUIRED", key)
		checkBool(&result, input.RequireCounterBasedAudit || item.RequiresCounterAudit, item.Required, item.HasCounterBasedAudit, "COUNTER_BASED_AUDIT_REQUIRED", key)
		checkZero(&result, input.RequireNoRequiredFail, item.Required, item.RequiredFailCount, "REQUIRED_FAIL_MUST_BE_ZERO", key)
		checkZero(&result, input.RequireNoOptionalWarn, item.Required, item.OptionalWarnCount, "OPTIONAL_WARN_MUST_BE_ZERO", key)
		checkBool(&result, input.RequireDocReady || item.RequiresDocReady, item.Required, item.DocReady, "DOC_READY_REQUIRED", key)
		checkBool(&result, input.RequireConfigReady || item.RequiresConfigReady, item.Required, item.ConfigReady, "CONFIG_READY_REQUIRED", key)
		checkBool(&result, input.RequireCodeReady || item.RequiresCodeReady, item.Required, item.CodeReady, "CODE_READY_REQUIRED", key)
		checkBool(&result, input.RequireTestPass || item.RequiresTestPass, item.Required, item.TestPass, "TEST_PASS_REQUIRED", key)
		checkBool(&result, input.RequireRealImplementationPass || item.RequiresRealImplementation, item.Required, item.RealImplementationPass, "REAL_IMPLEMENTATION_PASS_REQUIRED", key)
		checkBool(&result, input.RequireProductionLaunchBlocked || item.RequiresLaunchBlocked, item.Required, !item.ProductionLaunchAllowed && item.BlocksProductionLaunch, "PRODUCTION_LAUNCH_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireRealCustomerClosed || item.RequiresCustomerClosed, item.Required, !item.RealCustomerCollectionOpen && item.BlocksRealCustomer, "REAL_CUSTOMER_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireRealBillingClosed || item.RequiresBillingClosed, item.Required, !item.RealBillingEnabled && item.BlocksRealBilling, "REAL_BILLING_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequirePaymentClosed || item.RequiresPaymentClosed, item.Required, !item.PaymentCollectionEnabled && item.BlocksPaymentCollection, "PAYMENT_COLLECTION_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireDeveloperAccessClosed || item.RequiresDeveloperClosed, item.Required, !item.PublicDeveloperAccessOpen && item.BlocksDeveloperAccess, "DEVELOPER_ACCESS_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireCheckoutClosed || item.RequiresCheckoutClosed, item.Required, !item.CheckoutEnabled && item.BlocksCheckout, "CHECKOUT_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireSandboxClosed || item.RequiresSandboxClosed, item.Required, !item.SandboxLiveEnabled && item.BlocksSandboxLive, "SANDBOX_LIVE_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireNextPhaseReady, item.Required, item.ReadyForNextPhase, "NEXT_PHASE_READY_REQUIRED", key)

		if item.ProductionLaunchAllowed {
			addFail(&result, "ITEM_PRODUCTION_LAUNCH_OPEN", fmt.Sprintf("production launch open olamaz: %s", key))
		}
		if item.RealCustomerCollectionOpen {
			addFail(&result, "ITEM_REAL_CUSTOMER_COLLECTION_OPEN", fmt.Sprintf("real customer collection open olamaz: %s", key))
		}
		if item.RealBillingEnabled {
			addFail(&result, "ITEM_REAL_BILLING_OPEN", fmt.Sprintf("real billing open olamaz: %s", key))
		}
		if item.PaymentCollectionEnabled {
			addFail(&result, "ITEM_PAYMENT_COLLECTION_OPEN", fmt.Sprintf("payment collection open olamaz: %s", key))
		}
		if item.PublicDeveloperAccessOpen {
			addFail(&result, "ITEM_DEVELOPER_ACCESS_OPEN", fmt.Sprintf("developer access open olamaz: %s", key))
		}
		if item.CheckoutEnabled {
			addFail(&result, "ITEM_CHECKOUT_OPEN", fmt.Sprintf("checkout open olamaz: %s", key))
		}
		if item.SandboxLiveEnabled {
			addFail(&result, "ITEM_SANDBOX_LIVE_OPEN", fmt.Sprintf("sandbox live open olamaz: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredItemKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}
		item, exists := itemByKey[requiredKey]
		if !exists {
			addFail(&result, "REQUIRED_ITEM_NOT_REGISTERED", fmt.Sprintf("required listesinde olup closure içinde yok: %s", requiredKey))
			continue
		}
		if !item.Required {
			addFail(&result, "REQUIRED_ITEM_FLAG_FALSE", fmt.Sprintf("required listesinde ama item required=false: %s", requiredKey))
			continue
		}
		result.PassCount++
	}

	for _, domain := range input.RequiredDomains {
		if !domainCoverage[domain] {
			addFail(&result, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("closure domain eksik: %s", domain))
			continue
		}
		result.PassCount++
	}

	if result.RequiredFailCount > 0 {
		result.Status = "FAIL"
		return result, nil
	}

	result.Status = "PASS"
	result.GeneralFinalReviewReady = input.GeneralFinalReviewReady
	result.FinalClosureSealed = input.FinalClosureSealRequested
	result.ProductionLaunchAllowed = false
	result.RealCustomerCollectionOpen = false
	result.RealBillingEnabled = false
	result.PaymentCollectionEnabled = false
	result.PublicDeveloperAccessOpen = false
	result.CheckoutEnabled = false
	result.SandboxLiveEnabled = false
	result.ReadyForNextPhase = true
	return result, nil
}

func RequiredItemKeys(input ClosureInput) []string {
	keys := make([]string, 0, len(input.RequiredItemKeys))
	keys = append(keys, input.RequiredItemKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(result ClosureResult) error {
	if result.RequiredFailCount > 0 || result.Status != "PASS" {
		return errors.New("faz 5-r closure failed")
	}
	return nil
}

func checkBool(result *ClosureResult, required bool, itemRequired bool, actual bool, code string, key string) {
	if required && itemRequired && !actual {
		addFail(result, code, fmt.Sprintf("%s eksik: %s", code, key))
	} else if itemRequired {
		result.PassCount++
	}
}

func checkZero(result *ClosureResult, required bool, itemRequired bool, actual int, code string, key string) {
	if required && itemRequired && actual != 0 {
		addFail(result, code, fmt.Sprintf("%s sıfır değil: %s", code, key))
	} else if itemRequired {
		result.PassCount++
	}
}

func addFail(result *ClosureResult, code, message string) {
	result.RequiredFailCount++
	result.Findings = append(result.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
