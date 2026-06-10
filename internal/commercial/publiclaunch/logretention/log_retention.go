package logretention

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type PolicyStatus string

const (
	StatusReady    PolicyStatus = "READY"
	StatusDraft    PolicyStatus = "DRAFT"
	StatusDisabled PolicyStatus = "DISABLED"
)

type DataScope string

const (
	ScopeAuditLog      DataScope = "AUDIT_LOG"
	ScopeConsentLog    DataScope = "CONSENT_LOG"
	ScopeContractDoc   DataScope = "CONTRACT_DOCUMENT"
	ScopeSecurityLog   DataScope = "SECURITY_LOG"
	ScopeCommercialLog DataScope = "COMMERCIAL_OPERATION_LOG"
	ScopeSupportLog    DataScope = "SUPPORT_LOG"
)

type DisposalAction string

const (
	ActionArchive   DisposalAction = "ARCHIVE"
	ActionAnonymize DisposalAction = "ANONYMIZE"
	ActionDelete    DisposalAction = "DELETE"
	ActionLegalHold DisposalAction = "LEGAL_HOLD"
)

type RetentionPolicy struct {
	Key                     string
	Scope                   DataScope
	Title                   string
	Owner                   string
	Status                  PolicyStatus
	Required                bool
	RetentionDays           int
	DisposalAction          DisposalAction
	TenantScoped            bool
	HasLegalHold            bool
	HasAuditEvidence        bool
	HasKVKKBasis            bool
	HasRestoreGuard         bool
	ProductionDeleteEnabled bool
}

type PolicyInput struct {
	Phase                     string
	Target                    string
	RequiredPolicyKeys        []string
	Policies                  []RetentionPolicy
	RequireTenantScope        bool
	RequireLegalHold          bool
	RequireAuditEvidence      bool
	RequireKVKKBasis          bool
	RequireRestoreGuard       bool
	ProductionDeletionAllowed bool
	InternalPolicyReady       bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type PolicyReport struct {
	Status                    string
	InternalPolicyReady       bool
	ProductionDeletionAllowed bool
	RequiredFailCount         int
	OptionalWarnCount         int
	PassCount                 int
	Findings                  []Finding
}

func Evaluate(input PolicyInput) (PolicyReport, error) {
	report := PolicyReport{
		Status:                    "PASS",
		InternalPolicyReady:       false,
		ProductionDeletionAllowed: false,
		Findings:                  []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionDeletionAllowed {
		addFail(&report, "PRODUCTION_DELETION_BLOCKED", "bu fazda production deletion açık olamaz")
	}

	policyByKey := map[string]RetentionPolicy{}
	scopeCovered := map[DataScope]bool{}

	for _, policy := range input.Policies {
		key := strings.TrimSpace(policy.Key)
		if key == "" {
			addFail(&report, "POLICY_KEY_MISSING", "retention policy key boş olamaz")
			continue
		}
		if _, exists := policyByKey[key]; exists {
			addFail(&report, "POLICY_DUPLICATE", fmt.Sprintf("retention policy duplicate: %s", key))
			continue
		}

		policyByKey[key] = policy
		scopeCovered[policy.Scope] = true

		if policy.Required && policy.Status != StatusReady {
			addFail(&report, "REQUIRED_POLICY_NOT_READY", fmt.Sprintf("zorunlu policy READY değil: %s", key))
		} else if policy.Required {
			report.PassCount++
		}

		if policy.Required && policy.RetentionDays <= 0 {
			addFail(&report, "RETENTION_DAYS_MISSING", fmt.Sprintf("retention days eksik: %s", key))
		} else if policy.Required {
			report.PassCount++
		}

		if policy.Required && policy.DisposalAction == "" {
			addFail(&report, "DISPOSAL_ACTION_MISSING", fmt.Sprintf("imha/aksiyon tipi eksik: %s", key))
		} else if policy.Required {
			report.PassCount++
		}

		if input.RequireTenantScope && policy.Required && !policy.TenantScoped {
			addFail(&report, "TENANT_SCOPE_REQUIRED", fmt.Sprintf("tenant scoped değil: %s", key))
		} else if policy.Required {
			report.PassCount++
		}

		if input.RequireLegalHold && policy.Required && !policy.HasLegalHold {
			addFail(&report, "LEGAL_HOLD_REQUIRED", fmt.Sprintf("legal hold guard eksik: %s", key))
		} else if policy.Required {
			report.PassCount++
		}

		if input.RequireAuditEvidence && policy.Required && !policy.HasAuditEvidence {
			addFail(&report, "AUDIT_EVIDENCE_REQUIRED", fmt.Sprintf("audit evidence guard eksik: %s", key))
		} else if policy.Required {
			report.PassCount++
		}

		if input.RequireKVKKBasis && policy.Required && !policy.HasKVKKBasis {
			addFail(&report, "KVKK_BASIS_REQUIRED", fmt.Sprintf("KVKK dayanak alanı eksik: %s", key))
		} else if policy.Required {
			report.PassCount++
		}

		if input.RequireRestoreGuard && policy.Required && !policy.HasRestoreGuard {
			addFail(&report, "RESTORE_GUARD_REQUIRED", fmt.Sprintf("restore guard eksik: %s", key))
		} else if policy.Required {
			report.PassCount++
		}

		if policy.ProductionDeleteEnabled {
			addFail(&report, "POLICY_PRODUCTION_DELETE_ENABLED", fmt.Sprintf("policy production delete açık olamaz: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredPolicyKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}
		policy, exists := policyByKey[requiredKey]
		if !exists {
			addFail(&report, "REQUIRED_POLICY_NOT_REGISTERED", fmt.Sprintf("required listesinde olup inventory'de yok: %s", requiredKey))
			continue
		}
		if !policy.Required {
			addFail(&report, "REQUIRED_POLICY_FLAG_FALSE", fmt.Sprintf("required listesinde ama policy required=false: %s", requiredKey))
			continue
		}
		report.PassCount++
	}

	for _, scope := range []DataScope{ScopeAuditLog, ScopeConsentLog, ScopeContractDoc, ScopeSecurityLog, ScopeCommercialLog} {
		if !scopeCovered[scope] {
			addFail(&report, "REQUIRED_SCOPE_MISSING", fmt.Sprintf("zorunlu retention scope eksik: %s", scope))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalPolicyReady = false
		report.ProductionDeletionAllowed = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalPolicyReady = input.InternalPolicyReady
	report.ProductionDeletionAllowed = false
	return report, nil
}

func RequiredPolicyKeys(input PolicyInput) []string {
	keys := make([]string, 0, len(input.RequiredPolicyKeys))
	keys = append(keys, input.RequiredPolicyKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(report PolicyReport) error {
	if report.RequiredFailCount > 0 || report.Status != "PASS" {
		return errors.New("log retention destruction policy failed")
	}
	return nil
}

func addFail(report *PolicyReport, code, message string) {
	report.RequiredFailCount++
	report.Findings = append(report.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
