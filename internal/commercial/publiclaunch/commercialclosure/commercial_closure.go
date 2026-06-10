package commercialclosure

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type ClosureStatus string

const (
	StatusReady       ClosureStatus = "READY"
	StatusPendingNext ClosureStatus = "PENDING_NEXT"
	StatusBlocked     ClosureStatus = "BLOCKED"
)

type ClosureDomain string

const (
	DomainCompliance   ClosureDomain = "COMPLIANCE"
	DomainSupportOps   ClosureDomain = "SUPPORT_OPS"
	DomainCommercial   ClosureDomain = "COMMERCIAL"
	DomainLegal        ClosureDomain = "LEGAL"
	DomainClosure      ClosureDomain = "CLOSURE"
	DomainNextPriority ClosureDomain = "NEXT_PRIORITY"
)

type ClosureItem struct {
	Key                    string
	Domain                 ClosureDomain
	Title                  string
	Owner                  string
	Status                 ClosureStatus
	Required               bool
	InternalReady          bool
	HasEvidence            bool
	HasCounterBasedAudit   bool
	RequiredFailCount      int
	OptionalWarnCount      int
	ProductionEnabled      bool
	RealCustomerOpsOpen    bool
	BlocksProductionLaunch bool
	DeferredToNextPriority bool
	DeferredReason         string
}

type ClosureInput struct {
	Phase                            string
	Target                           string
	InternalCommercialClosureReady   bool
	Priority1CommercialBlockComplete bool
	ProductionPublicLaunchAllowed    bool
	RealCustomerCommercialOpsOpen    bool
	RequiredItemKeys                 []string
	RequiredDomains                  []ClosureDomain
	Items                            []ClosureItem
	RequireInternalReady             bool
	RequireEvidence                  bool
	RequireCounterBasedAudit         bool
	RequireNoRequiredFail            bool
	RequireNoOptionalWarn            bool
	RequireProductionLaunchBlock     bool
	AllowDeferredNextPriorityItems   bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type ClosureReport struct {
	Status                           string
	InternalCommercialClosureReady   bool
	Priority1CommercialBlockComplete bool
	ProductionPublicLaunchAllowed    bool
	RealCustomerCommercialOpsOpen    bool
	RequiredFailCount                int
	OptionalWarnCount                int
	PassCount                        int
	Findings                         []Finding
}

func Evaluate(input ClosureInput) (ClosureReport, error) {
	report := ClosureReport{
		Status:                           "PASS",
		InternalCommercialClosureReady:   false,
		Priority1CommercialBlockComplete: false,
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

	itemByKey := map[string]ClosureItem{}
	domainCoverage := map[ClosureDomain]bool{}

	for _, item := range input.Items {
		key := strings.TrimSpace(item.Key)
		if key == "" {
			addFail(&report, "CLOSURE_ITEM_KEY_MISSING", "closure item key boş olamaz")
			continue
		}

		if _, exists := itemByKey[key]; exists {
			addFail(&report, "CLOSURE_ITEM_DUPLICATE", fmt.Sprintf("closure item duplicate: %s", key))
			continue
		}

		itemByKey[key] = item
		domainCoverage[item.Domain] = true

		if item.Required && item.Status != StatusReady {
			if item.DeferredToNextPriority && input.AllowDeferredNextPriorityItems {
				report.PassCount++
			} else {
				addFail(&report, "REQUIRED_ITEM_NOT_READY", fmt.Sprintf("required closure item READY değil: %s", key))
			}
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireInternalReady && item.Required && !item.InternalReady {
			if item.DeferredToNextPriority && input.AllowDeferredNextPriorityItems {
				report.PassCount++
			} else {
				addFail(&report, "INTERNAL_READY_REQUIRED", fmt.Sprintf("internal ready eksik: %s", key))
			}
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireEvidence && item.Required && !item.HasEvidence {
			addFail(&report, "EVIDENCE_REQUIRED", fmt.Sprintf("evidence eksik: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireCounterBasedAudit && item.Required && !item.HasCounterBasedAudit {
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

		if input.RequireProductionLaunchBlock && item.Required && !item.BlocksProductionLaunch {
			addFail(&report, "PRODUCTION_LAUNCH_BLOCK_REQUIRED", fmt.Sprintf("production launch block eksik: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if item.ProductionEnabled {
			addFail(&report, "ITEM_PRODUCTION_ENABLED_BLOCKED", fmt.Sprintf("production enabled açık olamaz: %s", key))
		}

		if item.RealCustomerOpsOpen {
			addFail(&report, "ITEM_REAL_CUSTOMER_OPS_BLOCKED", fmt.Sprintf("real customer ops açık olamaz: %s", key))
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
			addFail(&report, "REQUIRED_ITEM_NOT_REGISTERED", fmt.Sprintf("required listesinde olup closure içinde yok: %s", requiredKey))
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
			addFail(&report, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("closure domain eksik: %s", domain))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalCommercialClosureReady = false
		report.Priority1CommercialBlockComplete = false
		report.ProductionPublicLaunchAllowed = false
		report.RealCustomerCommercialOpsOpen = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalCommercialClosureReady = input.InternalCommercialClosureReady
	report.Priority1CommercialBlockComplete = input.Priority1CommercialBlockComplete
	report.ProductionPublicLaunchAllowed = false
	report.RealCustomerCommercialOpsOpen = false
	return report, nil
}

func RequiredItemKeys(input ClosureInput) []string {
	keys := make([]string, 0, len(input.RequiredItemKeys))
	keys = append(keys, input.RequiredItemKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(report ClosureReport) error {
	if report.RequiredFailCount > 0 || report.Status != "PASS" {
		return errors.New("commercial closure report failed")
	}
	return nil
}

func addFail(report *ClosureReport, code, message string) {
	report.RequiredFailCount++
	report.Findings = append(report.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
