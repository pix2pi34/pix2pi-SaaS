package publicdeveloperwebtests

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type SurfaceStatus string

const (
	StatusReady       SurfaceStatus = "READY"
	StatusPendingNext SurfaceStatus = "PENDING_NEXT"
	StatusBlocked     SurfaceStatus = "BLOCKED"
)

type SurfaceDomain string

const (
	DomainDeveloperDocs SurfaceDomain = "DEVELOPER_DOCS"
	DomainAPIKeyScreen  SurfaceDomain = "API_KEY_SCREEN"
	DomainSandbox       SurfaceDomain = "SANDBOX_SURFACE"
	DomainPricingPages  SurfaceDomain = "PRICING_PAGES"
	DomainLaunchGuard   SurfaceDomain = "LAUNCH_GUARD"
	DomainHTMLQuality   SurfaceDomain = "HTML_QUALITY"
	DomainSecurity      SurfaceDomain = "SECURITY_GUARD"
	DomainClosureNext   SurfaceDomain = "CLOSURE_NEXT"
)

type WebSurface struct {
	Key                                     string
	Domain                                  SurfaceDomain
	Title                                   string
	Path                                    string
	Owner                                   string
	Status                                  SurfaceStatus
	Required                                bool
	HasEvidence                             bool
	HasCounterBasedAudit                    bool
	RequiredFailCount                       int
	OptionalWarnCount                       int
	StaticHTMLReady                         bool
	HasNoIndex                              bool
	HasViewport                             bool
	HasStartMarker                          bool
	HasLaunchGuard                          bool
	HasProductionDisabledMarker             bool
	HasRealAccessDisabledMarker             bool
	HasCheckoutDisabledMarker               bool
	HasPaymentCollectionDisabledMarker      bool
	HasAPIKeyCreationDisabledMarker         bool
	HasSandboxLiveDisabledMarker            bool
	HasTenantSafetyText                     bool
	HasSecurityNotice                       bool
	HasSupportPath                          bool
	ProductionPublished                     bool
	RealCustomerEnabled                     bool
	RealDeveloperAccessEnabled              bool
	CheckoutEnabled                         bool
	PaymentCollectionEnabled                bool
	APIKeyCreationEnabled                   bool
	SandboxLiveEnabled                      bool
	RequiresFileExists                      bool
	RequiresNoIndex                         bool
	RequiresViewport                        bool
	RequiresStartMarker                     bool
	RequiresLaunchGuard                     bool
	RequiresProductionDisabledMarker        bool
	RequiresRealAccessDisabledMarker        bool
	RequiresCheckoutDisabledMarker          bool
	RequiresPaymentCollectionDisabledMarker bool
	RequiresAPIKeyCreationDisabledMarker    bool
	RequiresSandboxLiveDisabledMarker       bool
	RequiresTenantSafetyText                bool
	RequiresSecurityNotice                  bool
	RequiresSupportPath                     bool
	BlocksProductionPublish                 bool
	BlocksRealCustomer                      bool
	BlocksRealDeveloperAccess               bool
	BlocksCheckout                          bool
	BlocksPaymentCollection                 bool
	BlocksAPIKeyCreation                    bool
	BlocksSandboxLive                       bool
	DeferredToFinalClosure                  bool
	DeferredReason                          string
}

type WebTestInput struct {
	Phase                                  string
	Target                                 string
	InternalWebTestsReady                  bool
	PublicDeveloperSurfaceTestsReady       bool
	ProductionPublishAllowed               bool
	RealCustomerAccessEnabled              bool
	RealDeveloperAccessEnabled             bool
	CheckoutEnabled                        bool
	PaymentCollectionEnabled               bool
	APIKeyCreationEnabled                  bool
	SandboxLiveEnabled                     bool
	RequiredSurfaceKeys                    []string
	RequiredDomains                        []SurfaceDomain
	Surfaces                               []WebSurface
	RequireEvidence                        bool
	RequireCounterBasedAudit               bool
	RequireNoRequiredFail                  bool
	RequireNoOptionalWarn                  bool
	RequireStaticHTMLReady                 bool
	RequireFileExists                      bool
	RequireNoIndex                         bool
	RequireViewport                        bool
	RequireStartMarker                     bool
	RequireLaunchGuard                     bool
	RequireProductionDisabledMarker        bool
	RequireRealAccessDisabledMarker        bool
	RequireCheckoutDisabledMarker          bool
	RequirePaymentCollectionDisabledMarker bool
	RequireAPIKeyCreationDisabledMarker    bool
	RequireSandboxLiveDisabledMarker       bool
	RequireTenantSafetyText                bool
	RequireSecurityNotice                  bool
	RequireSupportPath                     bool
	RequireProductionPublishBlock          bool
	RequireRealCustomerBlock               bool
	RequireRealDeveloperAccessBlock        bool
	RequireCheckoutBlock                   bool
	RequirePaymentCollectionBlock          bool
	RequireAPIKeyCreationBlock             bool
	RequireSandboxLiveBlock                bool
	AllowFinalClosureDeferred              bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type WebTestResult struct {
	Status                           string
	InternalWebTestsReady            bool
	PublicDeveloperSurfaceTestsReady bool
	ProductionPublishAllowed         bool
	RealCustomerAccessEnabled        bool
	RealDeveloperAccessEnabled       bool
	CheckoutEnabled                  bool
	PaymentCollectionEnabled         bool
	APIKeyCreationEnabled            bool
	SandboxLiveEnabled               bool
	RequiredFailCount                int
	OptionalWarnCount                int
	PassCount                        int
	Findings                         []Finding
}

func Evaluate(input WebTestInput) (WebTestResult, error) {
	result := WebTestResult{
		Status:                           "PASS",
		InternalWebTestsReady:            false,
		PublicDeveloperSurfaceTestsReady: false,
		ProductionPublishAllowed:         false,
		RealCustomerAccessEnabled:        false,
		RealDeveloperAccessEnabled:       false,
		CheckoutEnabled:                  false,
		PaymentCollectionEnabled:         false,
		APIKeyCreationEnabled:            false,
		SandboxLiveEnabled:               false,
		Findings:                         []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&result, "PHASE_MISSING", "phase boş olamaz")
	}
	if strings.TrimSpace(input.Target) == "" {
		addFail(&result, "TARGET_MISSING", "target boş olamaz")
	}
	if input.ProductionPublishAllowed {
		addFail(&result, "PRODUCTION_PUBLISH_BLOCKED", "bu fazda production publish açılamaz")
	}
	if input.RealCustomerAccessEnabled {
		addFail(&result, "REAL_CUSTOMER_ACCESS_BLOCKED", "bu fazda gerçek müşteri erişimi açılamaz")
	}
	if input.RealDeveloperAccessEnabled {
		addFail(&result, "REAL_DEVELOPER_ACCESS_BLOCKED", "bu fazda gerçek developer erişimi açılamaz")
	}
	if input.CheckoutEnabled {
		addFail(&result, "CHECKOUT_BLOCKED", "bu fazda checkout açılamaz")
	}
	if input.PaymentCollectionEnabled {
		addFail(&result, "PAYMENT_COLLECTION_BLOCKED", "bu fazda ödeme/tahsilat açılamaz")
	}
	if input.APIKeyCreationEnabled {
		addFail(&result, "API_KEY_CREATION_BLOCKED", "bu fazda API key creation açılamaz")
	}
	if input.SandboxLiveEnabled {
		addFail(&result, "SANDBOX_LIVE_BLOCKED", "bu fazda live sandbox açılamaz")
	}

	surfaceByKey := map[string]WebSurface{}
	domainCoverage := map[SurfaceDomain]bool{}

	for _, surface := range input.Surfaces {
		key := strings.TrimSpace(surface.Key)
		if key == "" {
			addFail(&result, "WEB_SURFACE_KEY_MISSING", "web surface key boş olamaz")
			continue
		}
		if _, exists := surfaceByKey[key]; exists {
			addFail(&result, "WEB_SURFACE_DUPLICATE", fmt.Sprintf("web surface duplicate: %s", key))
			continue
		}

		surfaceByKey[key] = surface
		domainCoverage[surface.Domain] = true

		if surface.Required && surface.Status != StatusReady {
			if surface.DeferredToFinalClosure && input.AllowFinalClosureDeferred {
				result.PassCount++
			} else {
				addFail(&result, "REQUIRED_SURFACE_NOT_READY", fmt.Sprintf("required web surface READY değil: %s", key))
			}
		} else if surface.Required {
			result.PassCount++
		}

		checkBool(&result, input.RequireEvidence, surface.Required, surface.HasEvidence, "EVIDENCE_REQUIRED", key)
		checkBool(&result, input.RequireCounterBasedAudit, surface.Required, surface.HasCounterBasedAudit, "COUNTER_BASED_AUDIT_REQUIRED", key)
		checkZero(&result, input.RequireNoRequiredFail, surface.Required, surface.RequiredFailCount, "REQUIRED_FAIL_MUST_BE_ZERO", key)
		checkZero(&result, input.RequireNoOptionalWarn, surface.Required, surface.OptionalWarnCount, "OPTIONAL_WARN_MUST_BE_ZERO", key)
		checkBool(&result, input.RequireStaticHTMLReady, surface.Required, surface.StaticHTMLReady, "STATIC_HTML_READY_REQUIRED", key)
		checkBool(&result, input.RequireFileExists, surface.Required, surface.RequiresFileExists, "FILE_EXISTS_REQUIRED", key)
		checkBool(&result, input.RequireNoIndex, surface.Required, surface.RequiresNoIndex && surface.HasNoIndex, "NOINDEX_REQUIRED", key)
		checkBool(&result, input.RequireViewport, surface.Required, surface.RequiresViewport && surface.HasViewport, "VIEWPORT_REQUIRED", key)
		checkBool(&result, input.RequireStartMarker, surface.Required, surface.RequiresStartMarker && surface.HasStartMarker, "START_MARKER_REQUIRED", key)
		checkBool(&result, input.RequireLaunchGuard, surface.Required, surface.RequiresLaunchGuard && surface.HasLaunchGuard, "LAUNCH_GUARD_REQUIRED", key)
		checkBool(&result, input.RequireProductionDisabledMarker, surface.Required, surface.RequiresProductionDisabledMarker && surface.HasProductionDisabledMarker, "PRODUCTION_DISABLED_MARKER_REQUIRED", key)
		checkBool(&result, input.RequireRealAccessDisabledMarker, surface.Required, surface.RequiresRealAccessDisabledMarker && surface.HasRealAccessDisabledMarker, "REAL_ACCESS_DISABLED_MARKER_REQUIRED", key)
		checkBool(&result, input.RequireCheckoutDisabledMarker, surface.Required, surface.RequiresCheckoutDisabledMarker && surface.HasCheckoutDisabledMarker, "CHECKOUT_DISABLED_MARKER_REQUIRED", key)
		checkBool(&result, input.RequirePaymentCollectionDisabledMarker, surface.Required, surface.RequiresPaymentCollectionDisabledMarker && surface.HasPaymentCollectionDisabledMarker, "PAYMENT_COLLECTION_DISABLED_MARKER_REQUIRED", key)
		checkBool(&result, input.RequireAPIKeyCreationDisabledMarker, surface.Required, surface.RequiresAPIKeyCreationDisabledMarker && surface.HasAPIKeyCreationDisabledMarker, "API_KEY_CREATION_DISABLED_MARKER_REQUIRED", key)
		checkBool(&result, input.RequireSandboxLiveDisabledMarker, surface.Required, surface.RequiresSandboxLiveDisabledMarker && surface.HasSandboxLiveDisabledMarker, "SANDBOX_LIVE_DISABLED_MARKER_REQUIRED", key)
		checkBool(&result, input.RequireTenantSafetyText, surface.Required, surface.RequiresTenantSafetyText && surface.HasTenantSafetyText, "TENANT_SAFETY_TEXT_REQUIRED", key)
		checkBool(&result, input.RequireSecurityNotice, surface.Required, surface.RequiresSecurityNotice && surface.HasSecurityNotice, "SECURITY_NOTICE_REQUIRED", key)
		checkBool(&result, input.RequireSupportPath, surface.Required, surface.RequiresSupportPath && surface.HasSupportPath, "SUPPORT_PATH_REQUIRED", key)
		checkBool(&result, input.RequireProductionPublishBlock, surface.Required, surface.BlocksProductionPublish, "PRODUCTION_PUBLISH_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireRealCustomerBlock, surface.Required, surface.BlocksRealCustomer, "REAL_CUSTOMER_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireRealDeveloperAccessBlock, surface.Required, surface.BlocksRealDeveloperAccess, "REAL_DEVELOPER_ACCESS_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireCheckoutBlock, surface.Required, surface.BlocksCheckout, "CHECKOUT_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequirePaymentCollectionBlock, surface.Required, surface.BlocksPaymentCollection, "PAYMENT_COLLECTION_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireAPIKeyCreationBlock, surface.Required, surface.BlocksAPIKeyCreation, "API_KEY_CREATION_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireSandboxLiveBlock, surface.Required, surface.BlocksSandboxLive, "SANDBOX_LIVE_BLOCK_REQUIRED", key)

		if surface.ProductionPublished {
			addFail(&result, "SURFACE_PRODUCTION_PUBLISHED_BLOCKED", fmt.Sprintf("production published açık olamaz: %s", key))
		}
		if surface.RealCustomerEnabled {
			addFail(&result, "SURFACE_REAL_CUSTOMER_ENABLED_BLOCKED", fmt.Sprintf("real customer enabled açık olamaz: %s", key))
		}
		if surface.RealDeveloperAccessEnabled {
			addFail(&result, "SURFACE_REAL_DEVELOPER_ACCESS_BLOCKED", fmt.Sprintf("real developer access açık olamaz: %s", key))
		}
		if surface.CheckoutEnabled {
			addFail(&result, "SURFACE_CHECKOUT_ENABLED_BLOCKED", fmt.Sprintf("checkout açık olamaz: %s", key))
		}
		if surface.PaymentCollectionEnabled {
			addFail(&result, "SURFACE_PAYMENT_COLLECTION_BLOCKED", fmt.Sprintf("payment collection açık olamaz: %s", key))
		}
		if surface.APIKeyCreationEnabled {
			addFail(&result, "SURFACE_API_KEY_CREATION_BLOCKED", fmt.Sprintf("api key creation açık olamaz: %s", key))
		}
		if surface.SandboxLiveEnabled {
			addFail(&result, "SURFACE_SANDBOX_LIVE_BLOCKED", fmt.Sprintf("sandbox live açık olamaz: %s", key))
		}
		if surface.DeferredToFinalClosure && strings.TrimSpace(surface.DeferredReason) == "" {
			addFail(&result, "DEFERRED_REASON_REQUIRED", fmt.Sprintf("deferred reason eksik: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredSurfaceKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}
		surface, exists := surfaceByKey[requiredKey]
		if !exists {
			addFail(&result, "REQUIRED_SURFACE_NOT_REGISTERED", fmt.Sprintf("required listesinde olup web tests içinde yok: %s", requiredKey))
			continue
		}
		if !surface.Required {
			addFail(&result, "REQUIRED_SURFACE_FLAG_FALSE", fmt.Sprintf("required listesinde ama surface required=false: %s", requiredKey))
			continue
		}
		result.PassCount++
	}

	for _, domain := range input.RequiredDomains {
		if !domainCoverage[domain] {
			addFail(&result, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("web tests domain eksik: %s", domain))
			continue
		}
		result.PassCount++
	}

	if result.RequiredFailCount > 0 {
		result.Status = "FAIL"
		return result, nil
	}

	result.Status = "PASS"
	result.InternalWebTestsReady = input.InternalWebTestsReady
	result.PublicDeveloperSurfaceTestsReady = input.PublicDeveloperSurfaceTestsReady
	result.ProductionPublishAllowed = false
	result.RealCustomerAccessEnabled = false
	result.RealDeveloperAccessEnabled = false
	result.CheckoutEnabled = false
	result.PaymentCollectionEnabled = false
	result.APIKeyCreationEnabled = false
	result.SandboxLiveEnabled = false
	return result, nil
}

func RequiredSurfaceKeys(input WebTestInput) []string {
	keys := make([]string, 0, len(input.RequiredSurfaceKeys))
	keys = append(keys, input.RequiredSurfaceKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(result WebTestResult) error {
	if result.RequiredFailCount > 0 || result.Status != "PASS" {
		return errors.New("public developer web tests failed")
	}
	return nil
}

func checkBool(result *WebTestResult, required bool, surfaceRequired bool, actual bool, code string, key string) {
	if required && surfaceRequired && !actual {
		addFail(result, code, fmt.Sprintf("%s eksik: %s", code, key))
	} else if surfaceRequired {
		result.PassCount++
	}
}

func checkZero(result *WebTestResult, required bool, surfaceRequired bool, actual int, code string, key string) {
	if required && surfaceRequired && actual != 0 {
		addFail(result, code, fmt.Sprintf("%s sıfır değil: %s", code, key))
	} else if surfaceRequired {
		result.PassCount++
	}
}

func addFail(result *WebTestResult, code, message string) {
	result.RequiredFailCount++
	result.Findings = append(result.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
