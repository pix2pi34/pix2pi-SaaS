package supportreadiness

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
)

type ReadinessDomain string

const (
	DomainSLA             ReadinessDomain = "SLA"
	DomainChannel         ReadinessDomain = "CHANNEL"
	DomainTemplate        ReadinessDomain = "TEMPLATE"
	DomainEscalation      ReadinessDomain = "ESCALATION"
	DomainIncident        ReadinessDomain = "INCIDENT"
	DomainOpsTest         ReadinessDomain = "OPS_TEST"
	DomainCommercialLegal ReadinessDomain = "COMMERCIAL_LEGAL"
	DomainLaunchGate      ReadinessDomain = "LAUNCH_GATE"
)

type SupportReadinessItem struct {
	Key                            string
	Domain                         ReadinessDomain
	Title                          string
	Owner                          string
	Status                         ItemStatus
	Required                       bool
	InternalReady                  bool
	HasEvidence                    bool
	HasCounterBasedAudit           bool
	RequiredFailCount              int
	OptionalWarnCount              int
	ProductionEnabled              bool
	RealCustomerSupportOpen        bool
	PublicSupportEnabled           bool
	CustomerNotificationEnabled    bool
	RequiresTenantID               bool
	RequiresCorrelationID          bool
	RequiresAuditTrail             bool
	RequiresSLAContract            bool
	RequiresEscalationBinding      bool
	RequiresIncidentClassification bool
	RequiresCommunicationTemplate  bool
	BlocksProductionSupport        bool
	BlocksRealCustomerNotification bool
}

type ReadinessInput struct {
	Phase                                string
	Target                               string
	InternalSupportReadinessReady        bool
	ProductionSupportEnabled             bool
	RealCustomerSupportOpen              bool
	PublicSupportEnabled                 bool
	CustomerNotificationEnabled          bool
	RequiredItemKeys                     []string
	RequiredDomains                      []ReadinessDomain
	Items                                []SupportReadinessItem
	RequireInternalReady                 bool
	RequireEvidence                      bool
	RequireCounterBasedAudit             bool
	RequireNoRequiredFail                bool
	RequireNoOptionalWarn                bool
	RequireTenantID                      bool
	RequireCorrelationID                 bool
	RequireAuditTrail                    bool
	RequireSLAContract                   bool
	RequireEscalationBinding             bool
	RequireIncidentClassification        bool
	RequireCommunicationTemplate         bool
	RequireProductionSupportBlock        bool
	RequireRealCustomerNotificationBlock bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type ReadinessReport struct {
	Status                        string
	InternalSupportReadinessReady bool
	ProductionSupportEnabled      bool
	RealCustomerSupportOpen       bool
	PublicSupportEnabled          bool
	CustomerNotificationEnabled   bool
	RequiredFailCount             int
	OptionalWarnCount             int
	PassCount                     int
	Findings                      []Finding
}

func Evaluate(input ReadinessInput) (ReadinessReport, error) {
	report := ReadinessReport{
		Status:                        "PASS",
		InternalSupportReadinessReady: false,
		ProductionSupportEnabled:      false,
		RealCustomerSupportOpen:       false,
		PublicSupportEnabled:          false,
		CustomerNotificationEnabled:   false,
		Findings:                      []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionSupportEnabled {
		addFail(&report, "PRODUCTION_SUPPORT_ENABLED_BLOCKED", "bu fazda production support enabled açılamaz")
	}

	if input.RealCustomerSupportOpen {
		addFail(&report, "REAL_CUSTOMER_SUPPORT_OPEN_BLOCKED", "bu fazda gerçek müşteri support açık olamaz")
	}

	if input.PublicSupportEnabled {
		addFail(&report, "PUBLIC_SUPPORT_ENABLED_BLOCKED", "bu fazda public support açık olamaz")
	}

	if input.CustomerNotificationEnabled {
		addFail(&report, "CUSTOMER_NOTIFICATION_ENABLED_BLOCKED", "bu fazda gerçek müşteri notification açık olamaz")
	}

	itemByKey := map[string]SupportReadinessItem{}
	domainCoverage := map[ReadinessDomain]bool{}

	for _, item := range input.Items {
		key := strings.TrimSpace(item.Key)
		if key == "" {
			addFail(&report, "READINESS_ITEM_KEY_MISSING", "readiness item key boş olamaz")
			continue
		}

		if _, exists := itemByKey[key]; exists {
			addFail(&report, "READINESS_ITEM_DUPLICATE", fmt.Sprintf("readiness item duplicate: %s", key))
			continue
		}

		itemByKey[key] = item
		domainCoverage[item.Domain] = true

		if item.Required && item.Status != StatusReady {
			addFail(&report, "REQUIRED_ITEM_NOT_READY", fmt.Sprintf("zorunlu readiness item READY değil: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireInternalReady && item.Required && !item.InternalReady {
			addFail(&report, "INTERNAL_READY_REQUIRED", fmt.Sprintf("internal ready eksik: %s", key))
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

		if input.RequireTenantID && item.Required && !item.RequiresTenantID {
			addFail(&report, "TENANT_ID_REQUIRED", fmt.Sprintf("tenant_id requirement eksik: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireCorrelationID && item.Required && !item.RequiresCorrelationID {
			addFail(&report, "CORRELATION_ID_REQUIRED", fmt.Sprintf("correlation_id requirement eksik: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireAuditTrail && item.Required && !item.RequiresAuditTrail {
			addFail(&report, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail requirement eksik: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireSLAContract && item.Required && !item.RequiresSLAContract {
			addFail(&report, "SLA_CONTRACT_REQUIRED", fmt.Sprintf("SLA contract eksik: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireEscalationBinding && item.Required && !item.RequiresEscalationBinding {
			addFail(&report, "ESCALATION_BINDING_REQUIRED", fmt.Sprintf("escalation binding eksik: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireIncidentClassification && item.Required && !item.RequiresIncidentClassification {
			addFail(&report, "INCIDENT_CLASSIFICATION_REQUIRED", fmt.Sprintf("incident classification eksik: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireCommunicationTemplate && item.Required && !item.RequiresCommunicationTemplate {
			addFail(&report, "COMMUNICATION_TEMPLATE_REQUIRED", fmt.Sprintf("communication template eksik: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireProductionSupportBlock && item.Required && !item.BlocksProductionSupport {
			addFail(&report, "PRODUCTION_SUPPORT_BLOCK_REQUIRED", fmt.Sprintf("production support block eksik: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if input.RequireRealCustomerNotificationBlock && item.Required && !item.BlocksRealCustomerNotification {
			addFail(&report, "REAL_CUSTOMER_NOTIFICATION_BLOCK_REQUIRED", fmt.Sprintf("real customer notification block eksik: %s", key))
		} else if item.Required {
			report.PassCount++
		}

		if item.ProductionEnabled {
			addFail(&report, "ITEM_PRODUCTION_ENABLED_BLOCKED", fmt.Sprintf("production enabled açık olamaz: %s", key))
		}

		if item.RealCustomerSupportOpen {
			addFail(&report, "ITEM_REAL_CUSTOMER_SUPPORT_OPEN_BLOCKED", fmt.Sprintf("real customer support open açık olamaz: %s", key))
		}

		if item.PublicSupportEnabled {
			addFail(&report, "ITEM_PUBLIC_SUPPORT_ENABLED_BLOCKED", fmt.Sprintf("public support enabled açık olamaz: %s", key))
		}

		if item.CustomerNotificationEnabled {
			addFail(&report, "ITEM_CUSTOMER_NOTIFICATION_ENABLED_BLOCKED", fmt.Sprintf("customer notification enabled açık olamaz: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredItemKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}

		item, exists := itemByKey[requiredKey]
		if !exists {
			addFail(&report, "REQUIRED_ITEM_NOT_REGISTERED", fmt.Sprintf("required listesinde olup readiness içinde yok: %s", requiredKey))
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
			addFail(&report, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("readiness domain eksik: %s", domain))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalSupportReadinessReady = false
		report.ProductionSupportEnabled = false
		report.RealCustomerSupportOpen = false
		report.PublicSupportEnabled = false
		report.CustomerNotificationEnabled = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalSupportReadinessReady = input.InternalSupportReadinessReady
	report.ProductionSupportEnabled = false
	report.RealCustomerSupportOpen = false
	report.PublicSupportEnabled = false
	report.CustomerNotificationEnabled = false
	return report, nil
}

func RequiredItemKeys(input ReadinessInput) []string {
	keys := make([]string, 0, len(input.RequiredItemKeys))
	keys = append(keys, input.RequiredItemKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(report ReadinessReport) error {
	if report.RequiredFailCount > 0 || report.Status != "PASS" {
		return errors.New("support readiness failed")
	}
	return nil
}

func addFail(report *ReadinessReport, code, message string) {
	report.RequiredFailCount++
	report.Findings = append(report.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
