package sandboxsurface

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type SectionStatus string

const (
	StatusReady       SectionStatus = "READY"
	StatusPendingNext SectionStatus = "PENDING_NEXT"
	StatusBlocked     SectionStatus = "BLOCKED"
)

type SandboxDomain string

const (
	DomainSandboxOverview SandboxDomain = "SANDBOX_OVERVIEW"
	DomainMockCredential  SandboxDomain = "MOCK_CREDENTIAL"
	DomainAPISample       SandboxDomain = "API_SAMPLE"
	DomainWebhookMock     SandboxDomain = "WEBHOOK_MOCK"
	DomainTenantScope     SandboxDomain = "TENANT_SCOPE"
	DomainDataReset       SandboxDomain = "DATA_RESET"
	DomainSecurity        SandboxDomain = "SECURITY"
	DomainPricingNext     SandboxDomain = "PRICING_NEXT"
)

type SandboxSection struct {
	Key                           string
	Domain                        SandboxDomain
	Title                         string
	Owner                         string
	Status                        SectionStatus
	Required                      bool
	HasEvidence                   bool
	HasCounterBasedAudit          bool
	RequiredFailCount             int
	OptionalWarnCount             int
	ProductionSandboxPublished    bool
	RealDeveloperAccessEnabled    bool
	LiveAPICallEnabled            bool
	LiveDataMutationEnabled       bool
	PaymentSimulationLiveEnabled  bool
	APIKeyCreationEnabled         bool
	RequiresTenantID              bool
	RequiresMockCredential        bool
	RequiresSampleRequest         bool
	RequiresSampleResponse        bool
	RequiresTenantIsolationNotice bool
	RequiresRateLimitPreview      bool
	RequiresWebhookMockGuide      bool
	RequiresDataResetPolicy       bool
	RequiresAuditTrail            bool
	RequiresSecurityNotice        bool
	RequiresSupportPath           bool
	RequiresLegalReview           bool
	RequiresFounderApproval       bool
	RequiresChangeLog             bool
	BlocksProductionPublish       bool
	BlocksRealDeveloperAccess     bool
	BlocksLiveAPICall             bool
	BlocksLiveDataMutation        bool
	BlocksPaymentSimulationLive   bool
	BlocksAPIKeyCreation          bool
	DeferredToPricingPages        bool
	DeferredReason                string
}

type SandboxInput struct {
	Phase                             string
	Target                            string
	InternalSandboxSurfaceReady       bool
	StaticHTMLReady                   bool
	ProductionSandboxPublished        bool
	RealDeveloperAccessEnabled        bool
	LiveAPICallEnabled                bool
	LiveDataMutationEnabled           bool
	PaymentSimulationLiveEnabled      bool
	APIKeyCreationEnabled             bool
	RequiredSectionKeys               []string
	RequiredDomains                   []SandboxDomain
	Sections                          []SandboxSection
	RequireEvidence                   bool
	RequireCounterBasedAudit          bool
	RequireNoRequiredFail             bool
	RequireNoOptionalWarn             bool
	RequireTenantID                   bool
	RequireMockCredential             bool
	RequireSampleRequest              bool
	RequireSampleResponse             bool
	RequireTenantIsolationNotice      bool
	RequireRateLimitPreview           bool
	RequireWebhookMockGuide           bool
	RequireDataResetPolicy            bool
	RequireAuditTrail                 bool
	RequireSecurityNotice             bool
	RequireSupportPath                bool
	RequireLegalReview                bool
	RequireFounderApproval            bool
	RequireChangeLog                  bool
	RequireProductionPublishBlock     bool
	RequireRealDeveloperAccessBlock   bool
	RequireLiveAPICallBlock           bool
	RequireLiveDataMutationBlock      bool
	RequirePaymentSimulationLiveBlock bool
	RequireAPIKeyCreationBlock        bool
	AllowPricingPagesDeferred         bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type SandboxResult struct {
	Status                       string
	InternalSandboxSurfaceReady  bool
	StaticHTMLReady              bool
	ProductionSandboxPublished   bool
	RealDeveloperAccessEnabled   bool
	LiveAPICallEnabled           bool
	LiveDataMutationEnabled      bool
	PaymentSimulationLiveEnabled bool
	APIKeyCreationEnabled        bool
	RequiredFailCount            int
	OptionalWarnCount            int
	PassCount                    int
	Findings                     []Finding
}

func Evaluate(input SandboxInput) (SandboxResult, error) {
	result := SandboxResult{
		Status:                       "PASS",
		InternalSandboxSurfaceReady:  false,
		StaticHTMLReady:              false,
		ProductionSandboxPublished:   false,
		RealDeveloperAccessEnabled:   false,
		LiveAPICallEnabled:           false,
		LiveDataMutationEnabled:      false,
		PaymentSimulationLiveEnabled: false,
		APIKeyCreationEnabled:        false,
		Findings:                     []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&result, "PHASE_MISSING", "phase boş olamaz")
	}
	if strings.TrimSpace(input.Target) == "" {
		addFail(&result, "TARGET_MISSING", "target boş olamaz")
	}
	if input.ProductionSandboxPublished {
		addFail(&result, "PRODUCTION_SANDBOX_PUBLISH_BLOCKED", "bu fazda sandbox production yayını açılamaz")
	}
	if input.RealDeveloperAccessEnabled {
		addFail(&result, "REAL_DEVELOPER_ACCESS_BLOCKED", "bu fazda gerçek developer erişimi açılamaz")
	}
	if input.LiveAPICallEnabled {
		addFail(&result, "LIVE_API_CALL_BLOCKED", "bu fazda canlı API çağrısı açılamaz")
	}
	if input.LiveDataMutationEnabled {
		addFail(&result, "LIVE_DATA_MUTATION_BLOCKED", "bu fazda canlı veri mutasyonu açılamaz")
	}
	if input.PaymentSimulationLiveEnabled {
		addFail(&result, "PAYMENT_SIMULATION_LIVE_BLOCKED", "bu fazda canlı ödeme simülasyonu açılamaz")
	}
	if input.APIKeyCreationEnabled {
		addFail(&result, "API_KEY_CREATION_BLOCKED", "bu fazda gerçek API key oluşturma açılamaz")
	}

	sectionByKey := map[string]SandboxSection{}
	domainCoverage := map[SandboxDomain]bool{}

	for _, section := range input.Sections {
		key := strings.TrimSpace(section.Key)
		if key == "" {
			addFail(&result, "SANDBOX_SECTION_KEY_MISSING", "sandbox section key boş olamaz")
			continue
		}
		if _, exists := sectionByKey[key]; exists {
			addFail(&result, "SANDBOX_SECTION_DUPLICATE", fmt.Sprintf("sandbox section duplicate: %s", key))
			continue
		}

		sectionByKey[key] = section
		domainCoverage[section.Domain] = true

		if section.Required && section.Status != StatusReady {
			if section.DeferredToPricingPages && input.AllowPricingPagesDeferred {
				result.PassCount++
			} else {
				addFail(&result, "REQUIRED_SECTION_NOT_READY", fmt.Sprintf("required sandbox section READY değil: %s", key))
			}
		} else if section.Required {
			result.PassCount++
		}

		checkBool(&result, input.RequireEvidence, section.Required, section.HasEvidence, "EVIDENCE_REQUIRED", key)
		checkBool(&result, input.RequireCounterBasedAudit, section.Required, section.HasCounterBasedAudit, "COUNTER_BASED_AUDIT_REQUIRED", key)
		checkZero(&result, input.RequireNoRequiredFail, section.Required, section.RequiredFailCount, "REQUIRED_FAIL_MUST_BE_ZERO", key)
		checkZero(&result, input.RequireNoOptionalWarn, section.Required, section.OptionalWarnCount, "OPTIONAL_WARN_MUST_BE_ZERO", key)
		checkBool(&result, input.RequireTenantID, section.Required, section.RequiresTenantID, "TENANT_ID_REQUIRED", key)
		checkBool(&result, input.RequireMockCredential, section.Required, section.RequiresMockCredential, "MOCK_CREDENTIAL_REQUIRED", key)
		checkBool(&result, input.RequireSampleRequest, section.Required, section.RequiresSampleRequest, "SAMPLE_REQUEST_REQUIRED", key)
		checkBool(&result, input.RequireSampleResponse, section.Required, section.RequiresSampleResponse, "SAMPLE_RESPONSE_REQUIRED", key)
		checkBool(&result, input.RequireTenantIsolationNotice, section.Required, section.RequiresTenantIsolationNotice, "TENANT_ISOLATION_NOTICE_REQUIRED", key)
		checkBool(&result, input.RequireRateLimitPreview, section.Required, section.RequiresRateLimitPreview, "RATE_LIMIT_PREVIEW_REQUIRED", key)
		checkBool(&result, input.RequireWebhookMockGuide, section.Required, section.RequiresWebhookMockGuide, "WEBHOOK_MOCK_GUIDE_REQUIRED", key)
		checkBool(&result, input.RequireDataResetPolicy, section.Required, section.RequiresDataResetPolicy, "DATA_RESET_POLICY_REQUIRED", key)
		checkBool(&result, input.RequireAuditTrail, section.Required, section.RequiresAuditTrail, "AUDIT_TRAIL_REQUIRED", key)
		checkBool(&result, input.RequireSecurityNotice, section.Required, section.RequiresSecurityNotice, "SECURITY_NOTICE_REQUIRED", key)
		checkBool(&result, input.RequireSupportPath, section.Required, section.RequiresSupportPath, "SUPPORT_PATH_REQUIRED", key)
		checkBool(&result, input.RequireLegalReview, section.Required, section.RequiresLegalReview, "LEGAL_REVIEW_REQUIRED", key)
		checkBool(&result, input.RequireFounderApproval, section.Required, section.RequiresFounderApproval, "FOUNDER_APPROVAL_REQUIRED", key)
		checkBool(&result, input.RequireChangeLog, section.Required, section.RequiresChangeLog, "CHANGE_LOG_REQUIRED", key)
		checkBool(&result, input.RequireProductionPublishBlock, section.Required, section.BlocksProductionPublish, "PRODUCTION_PUBLISH_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireRealDeveloperAccessBlock, section.Required, section.BlocksRealDeveloperAccess, "REAL_DEVELOPER_ACCESS_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireLiveAPICallBlock, section.Required, section.BlocksLiveAPICall, "LIVE_API_CALL_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireLiveDataMutationBlock, section.Required, section.BlocksLiveDataMutation, "LIVE_DATA_MUTATION_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequirePaymentSimulationLiveBlock, section.Required, section.BlocksPaymentSimulationLive, "PAYMENT_SIMULATION_LIVE_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireAPIKeyCreationBlock, section.Required, section.BlocksAPIKeyCreation, "API_KEY_CREATION_BLOCK_REQUIRED", key)

		if section.ProductionSandboxPublished {
			addFail(&result, "SECTION_PRODUCTION_SANDBOX_PUBLISHED_BLOCKED", fmt.Sprintf("production sandbox published açık olamaz: %s", key))
		}
		if section.RealDeveloperAccessEnabled {
			addFail(&result, "SECTION_REAL_DEVELOPER_ACCESS_BLOCKED", fmt.Sprintf("real developer access açık olamaz: %s", key))
		}
		if section.LiveAPICallEnabled {
			addFail(&result, "SECTION_LIVE_API_CALL_BLOCKED", fmt.Sprintf("live api call açık olamaz: %s", key))
		}
		if section.LiveDataMutationEnabled {
			addFail(&result, "SECTION_LIVE_DATA_MUTATION_BLOCKED", fmt.Sprintf("live data mutation açık olamaz: %s", key))
		}
		if section.PaymentSimulationLiveEnabled {
			addFail(&result, "SECTION_PAYMENT_SIMULATION_LIVE_BLOCKED", fmt.Sprintf("payment simulation live açık olamaz: %s", key))
		}
		if section.APIKeyCreationEnabled {
			addFail(&result, "SECTION_API_KEY_CREATION_BLOCKED", fmt.Sprintf("api key creation açık olamaz: %s", key))
		}
		if section.DeferredToPricingPages && strings.TrimSpace(section.DeferredReason) == "" {
			addFail(&result, "DEFERRED_REASON_REQUIRED", fmt.Sprintf("deferred reason eksik: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredSectionKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}
		section, exists := sectionByKey[requiredKey]
		if !exists {
			addFail(&result, "REQUIRED_SECTION_NOT_REGISTERED", fmt.Sprintf("required listesinde olup sandbox içinde yok: %s", requiredKey))
			continue
		}
		if !section.Required {
			addFail(&result, "REQUIRED_SECTION_FLAG_FALSE", fmt.Sprintf("required listesinde ama section required=false: %s", requiredKey))
			continue
		}
		result.PassCount++
	}

	for _, domain := range input.RequiredDomains {
		if !domainCoverage[domain] {
			addFail(&result, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("sandbox surface domain eksik: %s", domain))
			continue
		}
		result.PassCount++
	}

	if result.RequiredFailCount > 0 {
		result.Status = "FAIL"
		return result, nil
	}

	result.Status = "PASS"
	result.InternalSandboxSurfaceReady = input.InternalSandboxSurfaceReady
	result.StaticHTMLReady = input.StaticHTMLReady
	result.ProductionSandboxPublished = false
	result.RealDeveloperAccessEnabled = false
	result.LiveAPICallEnabled = false
	result.LiveDataMutationEnabled = false
	result.PaymentSimulationLiveEnabled = false
	result.APIKeyCreationEnabled = false
	return result, nil
}

func RequiredSectionKeys(input SandboxInput) []string {
	keys := make([]string, 0, len(input.RequiredSectionKeys))
	keys = append(keys, input.RequiredSectionKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(result SandboxResult) error {
	if result.RequiredFailCount > 0 || result.Status != "PASS" {
		return errors.New("sandbox surface failed")
	}
	return nil
}

func checkBool(result *SandboxResult, required bool, sectionRequired bool, actual bool, code string, key string) {
	if required && sectionRequired && !actual {
		addFail(result, code, fmt.Sprintf("%s eksik: %s", code, key))
	} else if sectionRequired {
		result.PassCount++
	}
}

func checkZero(result *SandboxResult, required bool, sectionRequired bool, actual int, code string, key string) {
	if required && sectionRequired && actual != 0 {
		addFail(result, code, fmt.Sprintf("%s sıfır değil: %s", code, key))
	} else if sectionRequired {
		result.PassCount++
	}
}

func addFail(result *SandboxResult, code, message string) {
	result.RequiredFailCount++
	result.Findings = append(result.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
