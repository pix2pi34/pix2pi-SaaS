package legalchecklist

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type ItemStatus string

const (
	StatusReady        ItemStatus = "READY"
	StatusPendingLegal ItemStatus = "PENDING_LEGAL_APPROVAL"
	StatusPendingKVKK  ItemStatus = "PENDING_KVKK_APPROVAL"
	StatusBlocked      ItemStatus = "BLOCKED"
)

type LegalDomain string

const (
	DomainContract       LegalDomain = "CONTRACT"
	DomainKVKK           LegalDomain = "KVKK"
	DomainConsent        LegalDomain = "CONSENT"
	DomainRetention      LegalDomain = "RETENTION"
	DomainSupportLegal   LegalDomain = "SUPPORT_LEGAL"
	DomainLaunchApproval LegalDomain = "LAUNCH_APPROVAL"
)

type LegalChecklistItem struct {
	Key                           string
	Domain                        LegalDomain
	Title                         string
	Owner                         string
	Status                        ItemStatus
	Required                      bool
	BlocksPublicLaunch            bool
	RequiresLegalApproval         bool
	LegalApprovalReady            bool
	RequiresKVKKApproval          bool
	KVKKApprovalReady             bool
	RequiresFounderApproval       bool
	FounderApprovalReady          bool
	RequiresVersion               bool
	HasVersion                    bool
	RequiresEvidence              bool
	HasEvidence                   bool
	RequiresCounterBasedAudit     bool
	HasCounterBasedAudit          bool
	RequiredFailCount             int
	OptionalWarnCount             int
	PublicPublishAllowed          bool
	RealCustomerCollectionAllowed bool
	DeferredToFinalApproval       bool
	DeferredReason                string
}

type ChecklistInput struct {
	Phase                         string
	Target                        string
	InternalLegalChecklistReady   bool
	ProductionPublicLaunchAllowed bool
	RealCustomerCollectionAllowed bool
	RequiredItemKeys              []string
	RequiredDomains               []LegalDomain
	Items                         []LegalChecklistItem
	RequireLegalApprovalGate      bool
	RequireKVKKApprovalGate       bool
	RequireFounderApprovalGate    bool
	RequireVersionedDocuments     bool
	RequireEvidence               bool
	RequireCounterBasedAudit      bool
	RequireNoRequiredFail         bool
	RequireNoOptionalWarn         bool
	AllowDeferredFinalApproval    bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type ChecklistReport struct {
	Status                        string
	InternalLegalChecklistReady   bool
	ProductionPublicLaunchAllowed bool
	RealCustomerCollectionAllowed bool
	RequiredFailCount             int
	OptionalWarnCount             int
	PassCount                     int
	Findings                      []Finding
}

func Evaluate(input ChecklistInput) (ChecklistReport, error) {
	report := ChecklistReport{
		Status:                        "PASS",
		InternalLegalChecklistReady:   false,
		ProductionPublicLaunchAllowed: false,
		RealCustomerCollectionAllowed: false,
		Findings:                      []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionPublicLaunchAllowed {
		addFail(&report, "PRODUCTION_PUBLIC_LAUNCH_BLOCKED", "bu fazda production public launch açılamaz")
	}

	if input.RealCustomerCollectionAllowed {
		addFail(&report, "REAL_CUSTOMER_COLLECTION_BLOCKED", "bu fazda gerçek müşteri veri toplama açılamaz")
	}

	itemByKey := map[string]LegalChecklistItem{}
	domainCoverage := map[LegalDomain]bool{}

	for _, item := range input.Items {
		key := strings.TrimSpace(item.Key)
		if key == "" {
			addFail(&report, "LEGAL_ITEM_KEY_MISSING", "legal checklist item key boş olamaz")
			continue
		}

		if _, exists := itemByKey[key]; exists {
			addFail(&report, "LEGAL_ITEM_DUPLICATE", fmt.Sprintf("legal checklist item duplicate: %s", key))
			continue
		}

		itemByKey[key] = item
		domainCoverage[item.Domain] = true

		if item.Required && item.Status != StatusReady {
			if item.DeferredToFinalApproval && input.AllowDeferredFinalApproval {
				report.PassCount++
			} else {
				addFail(&report, "REQUIRED_LEGAL_ITEM_NOT_READY", fmt.Sprintf("zorunlu legal item READY değil: %s", key))
			}
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireLegalApprovalGate && item.Required && item.RequiresLegalApproval && !item.LegalApprovalReady {
			if item.DeferredToFinalApproval && input.AllowDeferredFinalApproval {
				report.PassCount++
			} else {
				addFail(&report, "LEGAL_APPROVAL_REQUIRED", fmt.Sprintf("legal approval eksik: %s", key))
			}
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireKVKKApprovalGate && item.Required && item.RequiresKVKKApproval && !item.KVKKApprovalReady {
			if item.DeferredToFinalApproval && input.AllowDeferredFinalApproval {
				report.PassCount++
			} else {
				addFail(&report, "KVKK_APPROVAL_REQUIRED", fmt.Sprintf("KVKK approval eksik: %s", key))
			}
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireFounderApprovalGate && item.Required && item.RequiresFounderApproval && !item.FounderApprovalReady {
			if item.DeferredToFinalApproval && input.AllowDeferredFinalApproval {
				report.PassCount++
			} else {
				addFail(&report, "FOUNDER_APPROVAL_REQUIRED", fmt.Sprintf("founder approval eksik: %s", key))
			}
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireVersionedDocuments && item.Required && item.RequiresVersion && !item.HasVersion {
			addFail(&report, "VERSION_REQUIRED", fmt.Sprintf("versiyon eksik: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireEvidence && item.Required && item.RequiresEvidence && !item.HasEvidence {
			addFail(&report, "EVIDENCE_REQUIRED", fmt.Sprintf("evidence eksik: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireCounterBasedAudit && item.Required && item.RequiresCounterBasedAudit && !item.HasCounterBasedAudit {
			addFail(&report, "COUNTER_BASED_AUDIT_REQUIRED", fmt.Sprintf("counter based audit eksik: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireNoRequiredFail && item.Required && item.RequiredFailCount != 0 {
			addFail(&report, "REQUIRED_FAIL_MUST_BE_ZERO", fmt.Sprintf("required fail sıfır değil: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireNoOptionalWarn && item.Required && item.OptionalWarnCount != 0 {
			addFail(&report, "OPTIONAL_WARN_MUST_BE_ZERO", fmt.Sprintf("optional warn sıfır değil: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if item.PublicPublishAllowed {
			addFail(&report, "PUBLIC_PUBLISH_BLOCKED", fmt.Sprintf("public publish allowed açık olamaz: %s", key))
		}

		if item.RealCustomerCollectionAllowed {
			addFail(&report, "REAL_CUSTOMER_COLLECTION_ITEM_BLOCKED", fmt.Sprintf("real customer collection açık olamaz: %s", key))
		}

		if item.DeferredToFinalApproval && strings.TrimSpace(item.DeferredReason) == "" {
			addFail(&report, "DEFERRED_REASON_REQUIRED", fmt.Sprintf("deferred reason eksik: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredItemKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}

		item, exists := itemByKey[requiredKey]
		if !exists {
			addFail(&report, "REQUIRED_ITEM_NOT_REGISTERED", fmt.Sprintf("required listesinde olup checklist içinde yok: %s", requiredKey))
			continue
		}

		if !item.Required {
			addFail(&report, "REQUIRED_ITEM_FLAG_FALSE", fmt.Sprintf("required listesinde ama item required=false: %s", requiredKey))
			continue
		}

		report.PassCount++
	}

	for _, domain := range input.RequiredDomains {
		if !domainCoverage[domain] {
			addFail(&report, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("legal checklist domain eksik: %s", domain))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalLegalChecklistReady = false
		report.ProductionPublicLaunchAllowed = false
		report.RealCustomerCollectionAllowed = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalLegalChecklistReady = input.InternalLegalChecklistReady
	report.ProductionPublicLaunchAllowed = false
	report.RealCustomerCollectionAllowed = false
	return report, nil
}

func RequiredItemKeys(input ChecklistInput) []string {
	keys := make([]string, 0, len(input.RequiredItemKeys))
	keys = append(keys, input.RequiredItemKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(report ChecklistReport) error {
	if report.RequiredFailCount > 0 || report.Status != "PASS" {
		return errors.New("legal checklist failed")
	}
	return nil
}

func addFail(report *ChecklistReport, code, message string) {
	report.RequiredFailCount++
	report.Findings = append(report.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
