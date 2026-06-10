package supportescalation

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

type Priority string

const (
	PriorityP0 Priority = "P0_CRITICAL"
	PriorityP1 Priority = "P1_HIGH"
	PriorityP2 Priority = "P2_NORMAL"
	PriorityP3 Priority = "P3_LOW"
)

type EscalationLevel string

const (
	LevelL1Support     EscalationLevel = "L1_SUPPORT"
	LevelL2Ops         EscalationLevel = "L2_OPS"
	LevelL3Engineering EscalationLevel = "L3_ENGINEERING"
	LevelL4Compliance  EscalationLevel = "L4_LEGAL_KVKK_SECURITY"
	LevelL5Executive   EscalationLevel = "L5_EXECUTIVE"
)

type TriggerType string

const (
	TriggerSLABreach        TriggerType = "SLA_BREACH"
	TriggerP0Incident       TriggerType = "P0_INCIDENT"
	TriggerKVKKRequest      TriggerType = "KVKK_REQUEST"
	TriggerSecurityReport   TriggerType = "SECURITY_REPORT"
	TriggerBillingDispute   TriggerType = "BILLING_DISPUTE"
	TriggerUnresolvedTicket TriggerType = "UNRESOLVED_TICKET"
)

type EscalationRule struct {
	Key                            string
	Trigger                        TriggerType
	Priority                       Priority
	FromLevel                      EscalationLevel
	ToLevel                        EscalationLevel
	Owner                          string
	Status                         RuleStatus
	Required                       bool
	MaxAgeHours                    int
	NotifyCustomer                 bool
	AutoEscalate                   bool
	ManualReviewAllowed            bool
	RequiresTenantID               bool
	RequiresTicketID               bool
	RequiresCorrelationID          bool
	RequiresSLAKey                 bool
	RequiresAuditTrail             bool
	RequiresCustomerTemplate       bool
	RequiresOpsOwner               bool
	RequiresBusinessOwner          bool
	RequiresEngineeringOwner       bool
	RequiresLegalKVKKSecurityOwner bool
	BlocksSilentFailure            bool
}

type MatrixInput struct {
	Phase                            string
	Target                           string
	InternalMatrixReady              bool
	ProductionAutoEscalationEnabled  bool
	CustomerNotificationEnabled      bool
	RequiredRuleKeys                 []string
	RequiredTriggers                 []TriggerType
	Rules                            []EscalationRule
	RequireTenantID                  bool
	RequireTicketID                  bool
	RequireCorrelationID             bool
	RequireSLAKey                    bool
	RequireAuditTrail                bool
	RequireCustomerTemplateForNotify bool
	RequireOwnerMapping              bool
	RequireSilentFailureBlock        bool
	RequireManualReview              bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type MatrixReport struct {
	Status                          string
	InternalMatrixReady             bool
	ProductionAutoEscalationEnabled bool
	CustomerNotificationEnabled     bool
	RequiredFailCount               int
	OptionalWarnCount               int
	PassCount                       int
	Findings                        []Finding
}

func Evaluate(input MatrixInput) (MatrixReport, error) {
	report := MatrixReport{
		Status:                          "PASS",
		InternalMatrixReady:             false,
		ProductionAutoEscalationEnabled: false,
		CustomerNotificationEnabled:     false,
		Findings:                        []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionAutoEscalationEnabled {
		addFail(&report, "PRODUCTION_AUTO_ESCALATION_BLOCKED", "bu fazda production auto escalation açılamaz")
	}

	if input.CustomerNotificationEnabled {
		addFail(&report, "CUSTOMER_NOTIFICATION_BLOCKED", "bu fazda gerçek müşteri escalation notification açılamaz")
	}

	ruleByKey := map[string]EscalationRule{}
	triggerCoverage := map[TriggerType]bool{}

	for _, rule := range input.Rules {
		key := strings.TrimSpace(rule.Key)
		if key == "" {
			addFail(&report, "RULE_KEY_MISSING", "escalation rule key boş olamaz")
			continue
		}

		if _, exists := ruleByKey[key]; exists {
			addFail(&report, "RULE_DUPLICATE", fmt.Sprintf("escalation rule duplicate: %s", key))
			continue
		}

		ruleByKey[key] = rule
		triggerCoverage[rule.Trigger] = true

		if rule.Required && rule.Status != StatusReady {
			addFail(&report, "REQUIRED_RULE_NOT_READY", fmt.Sprintf("zorunlu escalation rule READY değil: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if rule.Required && rule.MaxAgeHours <= 0 {
			addFail(&report, "MAX_AGE_HOURS_REQUIRED", fmt.Sprintf("max age hours eksik: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if rule.Required && strings.TrimSpace(rule.Owner) == "" {
			addFail(&report, "OWNER_REQUIRED", fmt.Sprintf("owner eksik: %s", key))
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

		if input.RequireSLAKey && rule.Required && !rule.RequiresSLAKey {
			addFail(&report, "SLA_KEY_REQUIRED", fmt.Sprintf("sla_key zorunlu değil: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireAuditTrail && rule.Required && !rule.RequiresAuditTrail {
			addFail(&report, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail zorunlu değil: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireCustomerTemplateForNotify && rule.NotifyCustomer && !rule.RequiresCustomerTemplate {
			addFail(&report, "CUSTOMER_TEMPLATE_REQUIRED_FOR_NOTIFY", fmt.Sprintf("customer notification için template zorunlu: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireOwnerMapping && rule.Required && !hasRequiredOwnerMapping(rule) {
			addFail(&report, "OWNER_MAPPING_REQUIRED", fmt.Sprintf("rule için owner mapping eksik: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireSilentFailureBlock && rule.Required && !rule.BlocksSilentFailure {
			addFail(&report, "SILENT_FAILURE_BLOCK_REQUIRED", fmt.Sprintf("silent failure block eksik: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if input.RequireManualReview && rule.Required && !rule.ManualReviewAllowed {
			addFail(&report, "MANUAL_REVIEW_REQUIRED", fmt.Sprintf("manual review izni eksik: %s", key))
		} else if rule.Required {
			report.PassCount++
		}

		if !isValidLevelTransition(rule.FromLevel, rule.ToLevel) {
			addFail(&report, "INVALID_ESCALATION_TRANSITION", fmt.Sprintf("geçersiz escalation transition: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredRuleKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}

		rule, exists := ruleByKey[requiredKey]
		if !exists {
			addFail(&report, "REQUIRED_RULE_NOT_REGISTERED", fmt.Sprintf("required listesinde olup matrix'te yok: %s", requiredKey))
			continue
		}

		if !rule.Required {
			addFail(&report, "REQUIRED_RULE_FLAG_FALSE", fmt.Sprintf("required listesinde ama rule required=false: %s", requiredKey))
			continue
		}

		report.PassCount++
	}

	for _, trigger := range input.RequiredTriggers {
		if !triggerCoverage[trigger] {
			addFail(&report, "REQUIRED_TRIGGER_MISSING", fmt.Sprintf("trigger için escalation rule yok: %s", trigger))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalMatrixReady = false
		report.ProductionAutoEscalationEnabled = false
		report.CustomerNotificationEnabled = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalMatrixReady = input.InternalMatrixReady
	report.ProductionAutoEscalationEnabled = false
	report.CustomerNotificationEnabled = false
	return report, nil
}

func RequiredRuleKeys(input MatrixInput) []string {
	keys := make([]string, 0, len(input.RequiredRuleKeys))
	keys = append(keys, input.RequiredRuleKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(report MatrixReport) error {
	if report.RequiredFailCount > 0 || report.Status != "PASS" {
		return errors.New("support escalation matrix failed")
	}
	return nil
}

func addFail(report *MatrixReport, code, message string) {
	report.RequiredFailCount++
	report.Findings = append(report.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}

func hasRequiredOwnerMapping(rule EscalationRule) bool {
	if !rule.RequiresOpsOwner && !rule.RequiresBusinessOwner && !rule.RequiresEngineeringOwner && !rule.RequiresLegalKVKKSecurityOwner {
		return false
	}

	switch rule.ToLevel {
	case LevelL2Ops:
		return rule.RequiresOpsOwner
	case LevelL3Engineering:
		return rule.RequiresEngineeringOwner || rule.RequiresOpsOwner
	case LevelL4Compliance:
		return rule.RequiresLegalKVKKSecurityOwner
	case LevelL5Executive:
		return rule.RequiresBusinessOwner || rule.RequiresOpsOwner
	default:
		return rule.RequiresOpsOwner || rule.RequiresBusinessOwner || rule.RequiresEngineeringOwner || rule.RequiresLegalKVKKSecurityOwner
	}
}

func isValidLevelTransition(from, to EscalationLevel) bool {
	return levelRank(to) > levelRank(from)
}

func levelRank(level EscalationLevel) int {
	switch level {
	case LevelL1Support:
		return 1
	case LevelL2Ops:
		return 2
	case LevelL3Engineering:
		return 3
	case LevelL4Compliance:
		return 4
	case LevelL5Executive:
		return 5
	default:
		return 0
	}
}
