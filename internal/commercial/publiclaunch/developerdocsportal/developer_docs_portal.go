package developerdocsportal

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

type DocsDomain string

const (
	DomainOverview     DocsDomain = "OVERVIEW"
	DomainAuthAPI      DocsDomain = "AUTH_API"
	DomainTenantAPI    DocsDomain = "TENANT_API"
	DomainAPIReference DocsDomain = "API_REFERENCE"
	DomainWebhookAPI   DocsDomain = "WEBHOOK_API"
	DomainSandbox      DocsDomain = "SANDBOX"
	DomainSecurity     DocsDomain = "SECURITY"
	DomainSupport      DocsDomain = "SUPPORT"
	DomainNextPriority DocsDomain = "NEXT_PRIORITY"
)

type DocsSection struct {
	Key                              string
	Domain                           DocsDomain
	Title                            string
	Owner                            string
	Status                           SectionStatus
	Required                         bool
	HasEvidence                      bool
	HasCounterBasedAudit             bool
	RequiredFailCount                int
	OptionalWarnCount                int
	ProductionDocsPublished          bool
	RealDeveloperAccessEnabled       bool
	APIKeyCreationEnabled            bool
	SandboxLiveEnabled               bool
	RequiresPublicCopyGuard          bool
	RequiresVersioning               bool
	RequiresEndpointCatalog          bool
	RequiresAuthGuide                bool
	RequiresTenantHeaderGuide        bool
	RequiresRateLimitNotice          bool
	RequiresWebhookGuide             bool
	RequiresSandboxGuide             bool
	RequiresSecurityNotice           bool
	RequiresSupportPath              bool
	RequiresLegalReview              bool
	RequiresFounderApproval          bool
	RequiresChangeLog                bool
	RequiresAuditTrail               bool
	BlocksProductionPublish          bool
	BlocksRealDeveloperAccess        bool
	BlocksAPIKeyCreation             bool
	BlocksSandboxLive                bool
	DeferredToAPIKeyManagementScreen bool
	DeferredReason                   string
}

type PortalInput struct {
	Phase                               string
	Target                              string
	InternalDeveloperDocsPortalReady    bool
	StaticHTMLReady                     bool
	ProductionDocsPublished             bool
	RealDeveloperAccessEnabled          bool
	APIKeyCreationEnabled               bool
	SandboxLiveEnabled                  bool
	RequiredSectionKeys                 []string
	RequiredDomains                     []DocsDomain
	Sections                            []DocsSection
	RequireEvidence                     bool
	RequireCounterBasedAudit            bool
	RequireNoRequiredFail               bool
	RequireNoOptionalWarn               bool
	RequirePublicCopyGuard              bool
	RequireVersioning                   bool
	RequireEndpointCatalog              bool
	RequireAuthGuide                    bool
	RequireTenantHeaderGuide            bool
	RequireRateLimitNotice              bool
	RequireWebhookGuide                 bool
	RequireSandboxGuide                 bool
	RequireSecurityNotice               bool
	RequireSupportPath                  bool
	RequireLegalReview                  bool
	RequireFounderApproval              bool
	RequireChangeLog                    bool
	RequireAuditTrail                   bool
	RequireProductionPublishBlock       bool
	RequireRealDeveloperAccessBlock     bool
	RequireAPIKeyCreationBlock          bool
	RequireSandboxLiveBlock             bool
	AllowAPIKeyManagementScreenDeferred bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type PortalResult struct {
	Status                           string
	InternalDeveloperDocsPortalReady bool
	StaticHTMLReady                  bool
	ProductionDocsPublished          bool
	RealDeveloperAccessEnabled       bool
	APIKeyCreationEnabled            bool
	SandboxLiveEnabled               bool
	RequiredFailCount                int
	OptionalWarnCount                int
	PassCount                        int
	Findings                         []Finding
}

func Evaluate(input PortalInput) (PortalResult, error) {
	result := PortalResult{
		Status:                           "PASS",
		InternalDeveloperDocsPortalReady: false,
		StaticHTMLReady:                  false,
		ProductionDocsPublished:          false,
		RealDeveloperAccessEnabled:       false,
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
	if input.ProductionDocsPublished {
		addFail(&result, "PRODUCTION_DOCS_PUBLISH_BLOCKED", "bu fazda developer docs production yayını açılamaz")
	}
	if input.RealDeveloperAccessEnabled {
		addFail(&result, "REAL_DEVELOPER_ACCESS_BLOCKED", "bu fazda gerçek developer erişimi açılamaz")
	}
	if input.APIKeyCreationEnabled {
		addFail(&result, "API_KEY_CREATION_BLOCKED", "bu fazda API key oluşturma açılamaz")
	}
	if input.SandboxLiveEnabled {
		addFail(&result, "SANDBOX_LIVE_BLOCKED", "bu fazda canlı sandbox erişimi açılamaz")
	}

	sectionByKey := map[string]DocsSection{}
	domainCoverage := map[DocsDomain]bool{}

	for _, section := range input.Sections {
		key := strings.TrimSpace(section.Key)
		if key == "" {
			addFail(&result, "DOCS_SECTION_KEY_MISSING", "docs section key boş olamaz")
			continue
		}
		if _, exists := sectionByKey[key]; exists {
			addFail(&result, "DOCS_SECTION_DUPLICATE", fmt.Sprintf("docs section duplicate: %s", key))
			continue
		}

		sectionByKey[key] = section
		domainCoverage[section.Domain] = true

		if section.Required && section.Status != StatusReady {
			if section.DeferredToAPIKeyManagementScreen && input.AllowAPIKeyManagementScreenDeferred {
				result.PassCount++
			} else {
				addFail(&result, "REQUIRED_SECTION_NOT_READY", fmt.Sprintf("required docs section READY değil: %s", key))
			}
		} else if section.Required {
			result.PassCount++
		}

		checkBool(&result, input.RequireEvidence, section.Required, section.HasEvidence, "EVIDENCE_REQUIRED", key)
		checkBool(&result, input.RequireCounterBasedAudit, section.Required, section.HasCounterBasedAudit, "COUNTER_BASED_AUDIT_REQUIRED", key)
		checkZero(&result, input.RequireNoRequiredFail, section.Required, section.RequiredFailCount, "REQUIRED_FAIL_MUST_BE_ZERO", key)
		checkZero(&result, input.RequireNoOptionalWarn, section.Required, section.OptionalWarnCount, "OPTIONAL_WARN_MUST_BE_ZERO", key)
		checkBool(&result, input.RequirePublicCopyGuard, section.Required, section.RequiresPublicCopyGuard, "PUBLIC_COPY_GUARD_REQUIRED", key)
		checkBool(&result, input.RequireVersioning, section.Required, section.RequiresVersioning, "VERSIONING_REQUIRED", key)
		checkBool(&result, input.RequireEndpointCatalog, section.Required, section.RequiresEndpointCatalog, "ENDPOINT_CATALOG_REQUIRED", key)
		checkBool(&result, input.RequireAuthGuide, section.Required, section.RequiresAuthGuide, "AUTH_GUIDE_REQUIRED", key)
		checkBool(&result, input.RequireTenantHeaderGuide, section.Required, section.RequiresTenantHeaderGuide, "TENANT_HEADER_GUIDE_REQUIRED", key)
		checkBool(&result, input.RequireRateLimitNotice, section.Required, section.RequiresRateLimitNotice, "RATE_LIMIT_NOTICE_REQUIRED", key)
		checkBool(&result, input.RequireWebhookGuide, section.Required, section.RequiresWebhookGuide, "WEBHOOK_GUIDE_REQUIRED", key)
		checkBool(&result, input.RequireSandboxGuide, section.Required, section.RequiresSandboxGuide, "SANDBOX_GUIDE_REQUIRED", key)
		checkBool(&result, input.RequireSecurityNotice, section.Required, section.RequiresSecurityNotice, "SECURITY_NOTICE_REQUIRED", key)
		checkBool(&result, input.RequireSupportPath, section.Required, section.RequiresSupportPath, "SUPPORT_PATH_REQUIRED", key)
		checkBool(&result, input.RequireLegalReview, section.Required, section.RequiresLegalReview, "LEGAL_REVIEW_REQUIRED", key)
		checkBool(&result, input.RequireFounderApproval, section.Required, section.RequiresFounderApproval, "FOUNDER_APPROVAL_REQUIRED", key)
		checkBool(&result, input.RequireChangeLog, section.Required, section.RequiresChangeLog, "CHANGE_LOG_REQUIRED", key)
		checkBool(&result, input.RequireAuditTrail, section.Required, section.RequiresAuditTrail, "AUDIT_TRAIL_REQUIRED", key)
		checkBool(&result, input.RequireProductionPublishBlock, section.Required, section.BlocksProductionPublish, "PRODUCTION_PUBLISH_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireRealDeveloperAccessBlock, section.Required, section.BlocksRealDeveloperAccess, "REAL_DEVELOPER_ACCESS_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireAPIKeyCreationBlock, section.Required, section.BlocksAPIKeyCreation, "API_KEY_CREATION_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireSandboxLiveBlock, section.Required, section.BlocksSandboxLive, "SANDBOX_LIVE_BLOCK_REQUIRED", key)

		if section.ProductionDocsPublished {
			addFail(&result, "SECTION_PRODUCTION_DOCS_PUBLISHED_BLOCKED", fmt.Sprintf("production docs published açık olamaz: %s", key))
		}
		if section.RealDeveloperAccessEnabled {
			addFail(&result, "SECTION_REAL_DEVELOPER_ACCESS_BLOCKED", fmt.Sprintf("real developer access açık olamaz: %s", key))
		}
		if section.APIKeyCreationEnabled {
			addFail(&result, "SECTION_API_KEY_CREATION_BLOCKED", fmt.Sprintf("api key creation açık olamaz: %s", key))
		}
		if section.SandboxLiveEnabled {
			addFail(&result, "SECTION_SANDBOX_LIVE_BLOCKED", fmt.Sprintf("sandbox live açık olamaz: %s", key))
		}
		if section.DeferredToAPIKeyManagementScreen && strings.TrimSpace(section.DeferredReason) == "" {
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
			addFail(&result, "REQUIRED_SECTION_NOT_REGISTERED", fmt.Sprintf("required listesinde olup portal içinde yok: %s", requiredKey))
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
			addFail(&result, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("developer docs portal domain eksik: %s", domain))
			continue
		}
		result.PassCount++
	}

	if result.RequiredFailCount > 0 {
		result.Status = "FAIL"
		return result, nil
	}

	result.Status = "PASS"
	result.InternalDeveloperDocsPortalReady = input.InternalDeveloperDocsPortalReady
	result.StaticHTMLReady = input.StaticHTMLReady
	result.ProductionDocsPublished = false
	result.RealDeveloperAccessEnabled = false
	result.APIKeyCreationEnabled = false
	result.SandboxLiveEnabled = false
	return result, nil
}

func RequiredSectionKeys(input PortalInput) []string {
	keys := make([]string, 0, len(input.RequiredSectionKeys))
	keys = append(keys, input.RequiredSectionKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(result PortalResult) error {
	if result.RequiredFailCount > 0 || result.Status != "PASS" {
		return errors.New("developer docs portal failed")
	}
	return nil
}

func checkBool(result *PortalResult, required bool, sectionRequired bool, actual bool, code string, key string) {
	if required && sectionRequired && !actual {
		addFail(result, code, fmt.Sprintf("%s eksik: %s", code, key))
	} else if sectionRequired {
		result.PassCount++
	}
}

func checkZero(result *PortalResult, required bool, sectionRequired bool, actual int, code string, key string) {
	if required && sectionRequired && actual != 0 {
		addFail(result, code, fmt.Sprintf("%s sıfır değil: %s", code, key))
	} else if sectionRequired {
		result.PassCount++
	}
}

func addFail(result *PortalResult, code, message string) {
	result.RequiredFailCount++
	result.Findings = append(result.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
