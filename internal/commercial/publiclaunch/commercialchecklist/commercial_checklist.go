package commercialchecklist

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type ItemStatus string

const (
	StatusReady       ItemStatus = "READY"
	StatusPendingNext ItemStatus = "PENDING_NEXT"
	StatusBlocked     ItemStatus = "BLOCKED"
	StatusDisabled    ItemStatus = "DISABLED"
)

type ChecklistDomain string

const (
	DomainCompliance ChecklistDomain = "COMPLIANCE"
	DomainSupport    ChecklistDomain = "SUPPORT_OPS"
	DomainCommercial ChecklistDomain = "COMMERCIAL_OPS"
	DomainLaunchGate ChecklistDomain = "LAUNCH_GATE"
	DomainDeferred   ChecklistDomain = "DEFERRED_NEXT_PRIORITY"
)

type ChecklistItem struct {
	Key                       string
	Domain                    ChecklistDomain
	Title                     string
	Owner                     string
	Status                    ItemStatus
	Required                  bool
	BlocksLaunch              bool
	RequiresEvidence          bool
	HasEvidence               bool
	RequiresCounterBasedAudit bool
	HasCounterBasedAudit      bool
	RequiresNoRequiredFail    bool
	RequiredFailCount         int
	OptionalWarnCount         int
	ProductionEnabled         bool
	InternalReady             bool
	DeferredToNextPriority    bool
	DeferredReason            string
}

type ChecklistInput struct {
	Phase                            string
	Target                           string
	InternalCommercialChecklistReady bool
	ProductionPublicLaunchAllowed    bool
	RealCustomerCommercialOpsOpen    bool
	RequiredItemKeys                 []string
	RequiredDomains                  []ChecklistDomain
	Items                            []ChecklistItem
	RequireEvidence                  bool
	RequireCounterBasedAudit         bool
	RequireNoRequiredFail            bool
	RequireInternalReady             bool
	AllowDeferredNextPriorityItems   bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type ChecklistReport struct {
	Status                           string
	InternalCommercialChecklistReady bool
	ProductionPublicLaunchAllowed    bool
	RealCustomerCommercialOpsOpen    bool
	RequiredFailCount                int
	OptionalWarnCount                int
	PassCount                        int
	Findings                         []Finding
}

func Evaluate(input ChecklistInput) (ChecklistReport, error) {
	report := ChecklistReport{
		Status:                           "PASS",
		InternalCommercialChecklistReady: false,
		ProductionPublicLaunchAllowed:    false,
		RealCustomerCommercialOpsOpen:    false,
		Findings:                         []Finding{},
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

	if input.RealCustomerCommercialOpsOpen {
		addFail(&report, "REAL_CUSTOMER_COMMERCIAL_OPS_BLOCKED", "bu fazda gerçek müşteri ticari operasyon açılamaz")
	}

	itemByKey := map[string]ChecklistItem{}
	domainCoverage := map[ChecklistDomain]bool{}

	for _, item := range input.Items {
		key := strings.TrimSpace(item.Key)
		if key == "" {
			addFail(&report, "CHECKLIST_ITEM_KEY_MISSING", "checklist item key boş olamaz")
			continue
		}

		if _, exists := itemByKey[key]; exists {
			addFail(&report, "CHECKLIST_ITEM_DUPLICATE", fmt.Sprintf("checklist item duplicate: %s", key))
			continue
		}

		itemByKey[key] = item
		domainCoverage[item.Domain] = true

		if item.Required && item.Status != StatusReady {
			if item.DeferredToNextPriority && input.AllowDeferredNextPriorityItems {
				report.PassCount++
			} else {
				addFail(&report, "REQUIRED_ITEM_NOT_READY", fmt.Sprintf("zorunlu checklist item READY değil: %s", key))
			}
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

		if input.RequireNoRequiredFail && item.Required && item.RequiresNoRequiredFail && item.RequiredFailCount != 0 {
			addFail(&report, "REQUIRED_FAIL_MUST_BE_ZERO", fmt.Sprintf("required fail sıfır değil: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if item.Required && item.OptionalWarnCount != 0 {
			addFail(&report, "OPTIONAL_WARN_MUST_BE_ZERO", fmt.Sprintf("optional warn sıfır değil: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireInternalReady && item.Required && !item.InternalReady {
			if item.DeferredToNextPriority && input.AllowDeferredNextPriorityItems {
				report.PassCount++
			} else {
				addFail(&report, "INTERNAL_READY_REQUIRED", fmt.Sprintf("internal ready değil: %s", key))
			}
		} else if item.Required {
			report.PassCount++
		}

		if item.ProductionEnabled {
			addFail(&report, "PRODUCTION_ENABLED_BLOCKED", fmt.Sprintf("production enabled açık olamaz: %s", key))
		}

		if item.DeferredToNextPriority && strings.TrimSpace(item.DeferredReason) == "" {
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
			addFail(&report, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("checklist domain eksik: %s", domain))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalCommercialChecklistReady = false
		report.ProductionPublicLaunchAllowed = false
		report.RealCustomerCommercialOpsOpen = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalCommercialChecklistReady = input.InternalCommercialChecklistReady
	report.ProductionPublicLaunchAllowed = false
	report.RealCustomerCommercialOpsOpen = false
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
		return errors.New("commercial checklist failed")
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
