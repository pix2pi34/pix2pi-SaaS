package supportincident

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type RuleStatus string

const (
	StatusReady    RuleStatus = "READY"
	StatusDraft    RuleStatus = "DRAFT"
	StatusDisabled RuleStatus = "DISABLED"
)

type Severity string

const (
	SeverityP0 Severity = "P0_CRITICAL"
	SeverityP1 Severity = "P1_HIGH"
	SeverityP2 Severity = "P2_NORMAL"
	SeverityP3 Severity = "P3_LOW"
)

type IncidentCategory string

const (
	CategoryAvailability  IncidentCategory = "AVAILABILITY"
	CategoryPerformance   IncidentCategory = "PERFORMANCE"
	CategorySecurity      IncidentCategory = "SECURITY"
	CategoryKVKK          IncidentCategory = "KVKK"
	CategoryBilling       IncidentCategory = "BILLING"
	CategoryDataIntegrity IncidentCategory = "DATA_INTEGRITY"
	CategorySupportOps    IncidentCategory = "SUPPORT_OPS"
)

type IncidentRule struct {
	Key                           string
	Category                      IncidentCategory
	Severity                      Severity
	Title                         string
	Owner                         string
	Status                        RuleStatus
	Required                      bool
	DefaultSLAKey                 string
	DefaultEscalationKey          string
	DefaultCustomerTemplateKey    string
	RequiresTenantID              bool
	RequiresTicketID              bool
	RequiresCorrelationID         bool
	RequiresAuditTrail            bool
	RequiresRootCause             bool
	RequiresCustomerImpact        bool
	RequiresSecurityReview        bool
	RequiresKVKKReview            bool
	RequiresBillingOwner          bool
	RequiresEngineeringOwner      bool
	RequiresSupportOwner          bool
	ManualReviewAllowed           bool
	BlocksAutoClose               bool
	InternalOnly                  bool
	ProductionAutoClassifyEnabled bool
}

type ClassificationInput struct {
	Phase                               string
	Target                              string
	InternalClassificationReady         bool
	ProductionAutoClassificationEnabled bool
	CustomerNotificationEnabled         bool
	RequiredRuleKeys                    []string
	RequiredCategories                  []IncidentCategory
	Rules                               []IncidentRule
	RequireTenantID                     bool
	RequireTicketID                     bool
	RequireCorrelationID                bool
	RequireAuditTrail                   bool
	RequireRootCause                    bool
	RequireCustomerImpact               bool
	RequireManualReview                 bool
	RequireAutoCloseBlock               bool
	RequireSLAKey                       bool
	RequireEscalationKey                bool
	RequireCustomerTemplate             bool
	RequireSpecialOwnerMapping          bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type ClassificationReport struct {
	Status                              string
	InternalClassificationReady         bool
	ProductionAutoClassificationEnabled bool
	CustomerNotificationEnabled         bool
	RequiredFailCount                   int
	OptionalWarnCount                   int
	PassCount                           int
	Findings                            []Finding
}

func Evaluate(input ClassificationInput) (ClassificationReport, error) {
	report := ClassificationReport{
		Status:                              "PASS",
		InternalClassificationReady:         false,
		ProductionAutoClassificationEnabled: false,
		CustomerNotificationEnabled:         false,
		Findings:                            []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionAutoClassificationEnabled {
		addFail(&report, "PRODUCTION_AUTO_CLASSIFICATION_BLOCKED", "bu fazda production auto classification açılamaz")
	}

	if input.CustomerNotificationEnabled {
		addFail(&report, "CUSTOMER_NOTIFICATION_BLOCKED", "bu fazda gerçek müşteri incident notification açılamaz")
	}

	ruleByKey := map[string]IncidentRule{}
	categoryCoverage := map[IncidentCategory]bool{}

	for _, rule := range input.Rules {
		key := strings.TrimSpace(rule.Key)
		if key == "" {
			addFail(&report, "INCIDENT_RULE_KEY_MISSING", "incident rule key boş olamaz")
			continue
		}

		if _, exists := ruleByKey[key]; exists {
			addFail(&report, "INCIDENT_RULE_DUPLICATE", fmt.Sprintf("incident rule duplicate: %s", key))
			continue
		}

		ruleByKey[key] = rule
		categoryCoverage[rule.Category] = true

		if rule.Required && rule.Status != StatusReady {
			addFail(&report, "REQUIRED_INCIDENT_RULE_NOT_READY", fmt.Sprintf("zorunlu incident rule READY değil: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if rule.Required && strings.TrimSpace(rule.Owner) == "" {
			addFail(&report, "OWNER_REQUIRED", fmt.Sprintf("owner eksik: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireSLAKey && rule.Required && strings.TrimSpace(rule.DefaultSLAKey) == "" {
			addFail(&report, "SLA_KEY_REQUIRED", fmt.Sprintf("default SLA key eksik: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireEscalationKey && rule.Required && strings.TrimSpace(rule.DefaultEscalationKey) == "" {
			addFail(&report, "ESCALATION_KEY_REQUIRED", fmt.Sprintf("default escalation key eksik: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireCustomerTemplate && rule.Required && strings.TrimSpace(rule.DefaultCustomerTemplateKey) == "" {
			addFail(&report, "CUSTOMER_TEMPLATE_KEY_REQUIRED", fmt.Sprintf("default customer template key eksik: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireTenantID && rule.Required && !rule.RequiresTenantID {
			addFail(&report, "TENANT_ID_REQUIRED", fmt.Sprintf("tenant_id zorunlu değil: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireTicketID && rule.Required && !rule.RequiresTicketID {
			addFail(&report, "TICKET_ID_REQUIRED", fmt.Sprintf("ticket_id zorunlu değil: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireCorrelationID && rule.Required && !rule.RequiresCorrelationID {
			addFail(&report, "CORRELATION_ID_REQUIRED", fmt.Sprintf("correlation_id zorunlu değil: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireAuditTrail && rule.Required && !rule.RequiresAuditTrail {
			addFail(&report, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail zorunlu değil: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireRootCause && rule.Required && !rule.RequiresRootCause {
			addFail(&report, "ROOT_CAUSE_REQUIRED", fmt.Sprintf("root cause zorunlu değil: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireCustomerImpact && rule.Required && !rule.RequiresCustomerImpact {
			addFail(&report, "CUSTOMER_IMPACT_REQUIRED", fmt.Sprintf("customer impact zorunlu değil: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireManualReview && rule.Required && !rule.ManualReviewAllowed {
			addFail(&report, "MANUAL_REVIEW_REQUIRED", fmt.Sprintf("manual review izni eksik: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireAutoCloseBlock && rule.Required && !rule.BlocksAutoClose {
			addFail(&report, "AUTO_CLOSE_BLOCK_REQUIRED", fmt.Sprintf("auto close block eksik: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if rule.ProductionAutoClassifyEnabled {
			addFail(&report, "RULE_PRODUCTION_AUTO_CLASSIFY_ENABLED", fmt.Sprintf("rule production auto classify açık olamaz: %s", key))
		}

		if input.RequireSpecialOwnerMapping && !hasSpecialOwnerMapping(rule) {
			addFail(&report, "SPECIAL_OWNER_MAPPING_REQUIRED", fmt.Sprintf("incident rule owner mapping eksik: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredRuleKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}

		rule, exists := ruleByKey[requiredKey]
		if !exists {
			addFail(&report, "REQUIRED_RULE_NOT_REGISTERED", fmt.Sprintf("required listesinde olup classification içinde yok: %s", requiredKey))
			continue
		}

		if !rule.Required {
			addFail(&report, "REQUIRED_RULE_FLAG_FALSE", fmt.Sprintf("required listesinde ama rule required=false: %s", requiredKey))
			continue
		}

		report.PassCount++
	}

	for _, category := range input.RequiredCategories {
		if !categoryCoverage[category] {
			addFail(&report, "REQUIRED_CATEGORY_MISSING", fmt.Sprintf("incident category eksik: %s", category))
			continue
		}
		report.PassCount++
	}

	if !isSeverityCoverageValid(input.Rules) {
		addFail(&report, "SEVERITY_COVERAGE_MISSING", "P0/P1/P2/P3 severity kapsamı eksik")
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalClassificationReady = false
		report.ProductionAutoClassificationEnabled = false
		report.CustomerNotificationEnabled = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalClassificationReady = input.InternalClassificationReady
	report.ProductionAutoClassificationEnabled = false
	report.CustomerNotificationEnabled = false
	return report, nil
}

func RequiredRuleKeys(input ClassificationInput) []string {
	keys := make([]string, 0, len(input.RequiredRuleKeys))
	keys = append(keys, input.RequiredRuleKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(report ClassificationReport) error {
	if report.RequiredFailCount > 0 || report.Status != "PASS" {
		return errors.New("support incident classification failed")
	}
	return nil
}

func addFail(report *ClassificationReport, code, message string) {
	report.RequiredFailCount++
	report.Findings = append(report.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}

func hasSpecialOwnerMapping(rule IncidentRule) bool {
	switch rule.Category {
	case CategorySecurity:
		return rule.RequiresSecurityReview && rule.RequiresEngineeringOwner
	case CategoryKVKK:
		return rule.RequiresKVKKReview
	case CategoryBilling:
		return rule.RequiresBillingOwner
	case CategoryAvailability, CategoryPerformance, CategoryDataIntegrity:
		return rule.RequiresEngineeringOwner || rule.RequiresSupportOwner
	case CategorySupportOps:
		return rule.RequiresSupportOwner
	default:
		return false
	}
}

func isSeverityCoverageValid(rules []IncidentRule) bool {
	seen := map[Severity]bool{}
	for _, rule := range rules {
		if rule.Required {
			seen[rule.Severity] = true
		}
	}

	return seen[SeverityP0] && seen[SeverityP1] && seen[SeverityP2] && seen[SeverityP3]
}
