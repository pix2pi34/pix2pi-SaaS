package apikeymanagementscreen

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type ScreenStatus string

const (
	StatusReady       ScreenStatus = "READY"
	StatusPendingNext ScreenStatus = "PENDING_NEXT"
	StatusBlocked     ScreenStatus = "BLOCKED"
)

type ScreenDomain string

const (
	DomainKeyInventory ScreenDomain = "KEY_INVENTORY"
	DomainKeyLifecycle ScreenDomain = "KEY_LIFECYCLE"
	DomainPermission   ScreenDomain = "PERMISSION"
	DomainTenantScope  ScreenDomain = "TENANT_SCOPE"
	DomainAudit        ScreenDomain = "AUDIT"
	DomainSecurity     ScreenDomain = "SECURITY"
	DomainSandboxNext  ScreenDomain = "SANDBOX_NEXT"
)

type ScreenSection struct {
	Key                         string
	Domain                      ScreenDomain
	Title                       string
	Owner                       string
	Status                      ScreenStatus
	Required                    bool
	HasEvidence                 bool
	HasCounterBasedAudit        bool
	RequiredFailCount           int
	OptionalWarnCount           int
	ProductionScreenPublished   bool
	RealDeveloperAccessEnabled  bool
	APIKeyCreationEnabled       bool
	APIKeyRevealEnabled         bool
	APIKeyRotationEnabled       bool
	SandboxLiveEnabled          bool
	RequiresTenantID            bool
	RequiresDeveloperAccount    bool
	RequiresRoleGuard           bool
	RequiresPermissionScope     bool
	RequiresKeyName             bool
	RequiresMaskedSecretDisplay bool
	RequiresCreateDisabledGuard bool
	RequiresRevealDisabledGuard bool
	RequiresRotateDisabledGuard bool
	RequiresRevokePreview       bool
	RequiresAuditTrail          bool
	RequiresRateLimitPolicy     bool
	RequiresExpiryPolicy        bool
	RequiresSecurityNotice      bool
	RequiresLegalReview         bool
	RequiresFounderApproval     bool
	RequiresChangeLog           bool
	BlocksProductionPublish     bool
	BlocksRealDeveloperAccess   bool
	BlocksAPIKeyCreation        bool
	BlocksAPIKeyReveal          bool
	BlocksAPIKeyRotation        bool
	BlocksSandboxLive           bool
	DeferredToSandboxSurface    bool
	DeferredReason              string
}

type ScreenInput struct {
	Phase                           string
	Target                          string
	InternalAPIKeyScreenReady       bool
	StaticHTMLReady                 bool
	ProductionScreenPublished       bool
	RealDeveloperAccessEnabled      bool
	APIKeyCreationEnabled           bool
	APIKeyRevealEnabled             bool
	APIKeyRotationEnabled           bool
	SandboxLiveEnabled              bool
	RequiredSectionKeys             []string
	RequiredDomains                 []ScreenDomain
	Sections                        []ScreenSection
	RequireEvidence                 bool
	RequireCounterBasedAudit        bool
	RequireNoRequiredFail           bool
	RequireNoOptionalWarn           bool
	RequireTenantID                 bool
	RequireDeveloperAccount         bool
	RequireRoleGuard                bool
	RequirePermissionScope          bool
	RequireKeyName                  bool
	RequireMaskedSecretDisplay      bool
	RequireCreateDisabledGuard      bool
	RequireRevealDisabledGuard      bool
	RequireRotateDisabledGuard      bool
	RequireRevokePreview            bool
	RequireAuditTrail               bool
	RequireRateLimitPolicy          bool
	RequireExpiryPolicy             bool
	RequireSecurityNotice           bool
	RequireLegalReview              bool
	RequireFounderApproval          bool
	RequireChangeLog                bool
	RequireProductionPublishBlock   bool
	RequireRealDeveloperAccessBlock bool
	RequireAPIKeyCreationBlock      bool
	RequireAPIKeyRevealBlock        bool
	RequireAPIKeyRotationBlock      bool
	RequireSandboxLiveBlock         bool
	AllowSandboxSurfaceDeferred     bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type ScreenResult struct {
	Status                     string
	InternalAPIKeyScreenReady  bool
	StaticHTMLReady            bool
	ProductionScreenPublished  bool
	RealDeveloperAccessEnabled bool
	APIKeyCreationEnabled      bool
	APIKeyRevealEnabled        bool
	APIKeyRotationEnabled      bool
	SandboxLiveEnabled         bool
	RequiredFailCount          int
	OptionalWarnCount          int
	PassCount                  int
	Findings                   []Finding
}

func Evaluate(input ScreenInput) (ScreenResult, error) {
	result := ScreenResult{
		Status:                     "PASS",
		InternalAPIKeyScreenReady:  false,
		StaticHTMLReady:            false,
		ProductionScreenPublished:  false,
		RealDeveloperAccessEnabled: false,
		APIKeyCreationEnabled:      false,
		APIKeyRevealEnabled:        false,
		APIKeyRotationEnabled:      false,
		SandboxLiveEnabled:         false,
		Findings:                   []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&result, "PHASE_MISSING", "phase boş olamaz")
	}
	if strings.TrimSpace(input.Target) == "" {
		addFail(&result, "TARGET_MISSING", "target boş olamaz")
	}
	if input.ProductionScreenPublished {
		addFail(&result, "PRODUCTION_SCREEN_PUBLISH_BLOCKED", "bu fazda API key ekranı production yayını açılamaz")
	}
	if input.RealDeveloperAccessEnabled {
		addFail(&result, "REAL_DEVELOPER_ACCESS_BLOCKED", "bu fazda gerçek developer erişimi açılamaz")
	}
	if input.APIKeyCreationEnabled {
		addFail(&result, "API_KEY_CREATION_BLOCKED", "bu fazda gerçek API key oluşturma açılamaz")
	}
	if input.APIKeyRevealEnabled {
		addFail(&result, "API_KEY_REVEAL_BLOCKED", "bu fazda API key secret reveal açılamaz")
	}
	if input.APIKeyRotationEnabled {
		addFail(&result, "API_KEY_ROTATION_BLOCKED", "bu fazda API key rotation açılamaz")
	}
	if input.SandboxLiveEnabled {
		addFail(&result, "SANDBOX_LIVE_BLOCKED", "bu fazda canlı sandbox erişimi açılamaz")
	}

	sectionByKey := map[string]ScreenSection{}
	domainCoverage := map[ScreenDomain]bool{}

	for _, section := range input.Sections {
		key := strings.TrimSpace(section.Key)
		if key == "" {
			addFail(&result, "SCREEN_SECTION_KEY_MISSING", "screen section key boş olamaz")
			continue
		}
		if _, exists := sectionByKey[key]; exists {
			addFail(&result, "SCREEN_SECTION_DUPLICATE", fmt.Sprintf("screen section duplicate: %s", key))
			continue
		}

		sectionByKey[key] = section
		domainCoverage[section.Domain] = true

		if section.Required && section.Status != StatusReady {
			if section.DeferredToSandboxSurface && input.AllowSandboxSurfaceDeferred {
				result.PassCount++
			} else {
				addFail(&result, "REQUIRED_SECTION_NOT_READY", fmt.Sprintf("required screen section READY değil: %s", key))
			}
		} else if section.Required {
			result.PassCount++
		}

		checkBool(&result, input.RequireEvidence, section.Required, section.HasEvidence, "EVIDENCE_REQUIRED", key)
		checkBool(&result, input.RequireCounterBasedAudit, section.Required, section.HasCounterBasedAudit, "COUNTER_BASED_AUDIT_REQUIRED", key)
		checkZero(&result, input.RequireNoRequiredFail, section.Required, section.RequiredFailCount, "REQUIRED_FAIL_MUST_BE_ZERO", key)
		checkZero(&result, input.RequireNoOptionalWarn, section.Required, section.OptionalWarnCount, "OPTIONAL_WARN_MUST_BE_ZERO", key)
		checkBool(&result, input.RequireTenantID, section.Required, section.RequiresTenantID, "TENANT_ID_REQUIRED", key)
		checkBool(&result, input.RequireDeveloperAccount, section.Required, section.RequiresDeveloperAccount, "DEVELOPER_ACCOUNT_REQUIRED", key)
		checkBool(&result, input.RequireRoleGuard, section.Required, section.RequiresRoleGuard, "ROLE_GUARD_REQUIRED", key)
		checkBool(&result, input.RequirePermissionScope, section.Required, section.RequiresPermissionScope, "PERMISSION_SCOPE_REQUIRED", key)
		checkBool(&result, input.RequireKeyName, section.Required, section.RequiresKeyName, "KEY_NAME_REQUIRED", key)
		checkBool(&result, input.RequireMaskedSecretDisplay, section.Required, section.RequiresMaskedSecretDisplay, "MASKED_SECRET_DISPLAY_REQUIRED", key)
		checkBool(&result, input.RequireCreateDisabledGuard, section.Required, section.RequiresCreateDisabledGuard, "CREATE_DISABLED_GUARD_REQUIRED", key)
		checkBool(&result, input.RequireRevealDisabledGuard, section.Required, section.RequiresRevealDisabledGuard, "REVEAL_DISABLED_GUARD_REQUIRED", key)
		checkBool(&result, input.RequireRotateDisabledGuard, section.Required, section.RequiresRotateDisabledGuard, "ROTATE_DISABLED_GUARD_REQUIRED", key)
		checkBool(&result, input.RequireRevokePreview, section.Required, section.RequiresRevokePreview, "REVOKE_PREVIEW_REQUIRED", key)
		checkBool(&result, input.RequireAuditTrail, section.Required, section.RequiresAuditTrail, "AUDIT_TRAIL_REQUIRED", key)
		checkBool(&result, input.RequireRateLimitPolicy, section.Required, section.RequiresRateLimitPolicy, "RATE_LIMIT_POLICY_REQUIRED", key)
		checkBool(&result, input.RequireExpiryPolicy, section.Required, section.RequiresExpiryPolicy, "EXPIRY_POLICY_REQUIRED", key)
		checkBool(&result, input.RequireSecurityNotice, section.Required, section.RequiresSecurityNotice, "SECURITY_NOTICE_REQUIRED", key)
		checkBool(&result, input.RequireLegalReview, section.Required, section.RequiresLegalReview, "LEGAL_REVIEW_REQUIRED", key)
		checkBool(&result, input.RequireFounderApproval, section.Required, section.RequiresFounderApproval, "FOUNDER_APPROVAL_REQUIRED", key)
		checkBool(&result, input.RequireChangeLog, section.Required, section.RequiresChangeLog, "CHANGE_LOG_REQUIRED", key)
		checkBool(&result, input.RequireProductionPublishBlock, section.Required, section.BlocksProductionPublish, "PRODUCTION_PUBLISH_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireRealDeveloperAccessBlock, section.Required, section.BlocksRealDeveloperAccess, "REAL_DEVELOPER_ACCESS_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireAPIKeyCreationBlock, section.Required, section.BlocksAPIKeyCreation, "API_KEY_CREATION_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireAPIKeyRevealBlock, section.Required, section.BlocksAPIKeyReveal, "API_KEY_REVEAL_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireAPIKeyRotationBlock, section.Required, section.BlocksAPIKeyRotation, "API_KEY_ROTATION_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireSandboxLiveBlock, section.Required, section.BlocksSandboxLive, "SANDBOX_LIVE_BLOCK_REQUIRED", key)

		if section.ProductionScreenPublished {
			addFail(&result, "SECTION_PRODUCTION_SCREEN_PUBLISHED_BLOCKED", fmt.Sprintf("production screen published açık olamaz: %s", key))
		}
		if section.RealDeveloperAccessEnabled {
			addFail(&result, "SECTION_REAL_DEVELOPER_ACCESS_BLOCKED", fmt.Sprintf("real developer access açık olamaz: %s", key))
		}
		if section.APIKeyCreationEnabled {
			addFail(&result, "SECTION_API_KEY_CREATION_BLOCKED", fmt.Sprintf("api key creation açık olamaz: %s", key))
		}
		if section.APIKeyRevealEnabled {
			addFail(&result, "SECTION_API_KEY_REVEAL_BLOCKED", fmt.Sprintf("api key reveal açık olamaz: %s", key))
		}
		if section.APIKeyRotationEnabled {
			addFail(&result, "SECTION_API_KEY_ROTATION_BLOCKED", fmt.Sprintf("api key rotation açık olamaz: %s", key))
		}
		if section.SandboxLiveEnabled {
			addFail(&result, "SECTION_SANDBOX_LIVE_BLOCKED", fmt.Sprintf("sandbox live açık olamaz: %s", key))
		}
		if section.DeferredToSandboxSurface && strings.TrimSpace(section.DeferredReason) == "" {
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
			addFail(&result, "REQUIRED_SECTION_NOT_REGISTERED", fmt.Sprintf("required listesinde olup screen içinde yok: %s", requiredKey))
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
			addFail(&result, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("API key management screen domain eksik: %s", domain))
			continue
		}
		result.PassCount++
	}

	if result.RequiredFailCount > 0 {
		result.Status = "FAIL"
		return result, nil
	}

	result.Status = "PASS"
	result.InternalAPIKeyScreenReady = input.InternalAPIKeyScreenReady
	result.StaticHTMLReady = input.StaticHTMLReady
	result.ProductionScreenPublished = false
	result.RealDeveloperAccessEnabled = false
	result.APIKeyCreationEnabled = false
	result.APIKeyRevealEnabled = false
	result.APIKeyRotationEnabled = false
	result.SandboxLiveEnabled = false
	return result, nil
}

func RequiredSectionKeys(input ScreenInput) []string {
	keys := make([]string, 0, len(input.RequiredSectionKeys))
	keys = append(keys, input.RequiredSectionKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(result ScreenResult) error {
	if result.RequiredFailCount > 0 || result.Status != "PASS" {
		return errors.New("api key management screen failed")
	}
	return nil
}

func checkBool(result *ScreenResult, required bool, sectionRequired bool, actual bool, code string, key string) {
	if required && sectionRequired && !actual {
		addFail(result, code, fmt.Sprintf("%s eksik: %s", code, key))
	} else if sectionRequired {
		result.PassCount++
	}
}

func checkZero(result *ScreenResult, required bool, sectionRequired bool, actual int, code string, key string) {
	if required && sectionRequired && actual != 0 {
		addFail(result, code, fmt.Sprintf("%s sıfır değil: %s", code, key))
	} else if sectionRequired {
		result.PassCount++
	}
}

func addFail(result *ScreenResult, code, message string) {
	result.RequiredFailCount++
	result.Findings = append(result.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
