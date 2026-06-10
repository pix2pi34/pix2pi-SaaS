package supporttemplates

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type TemplateStatus string

const (
	StatusReady    TemplateStatus = "READY"
	StatusDraft    TemplateStatus = "DRAFT"
	StatusDisabled TemplateStatus = "DISABLED"
)

type TemplateCategory string

const (
	CategoryTicketAck      TemplateCategory = "TICKET_ACK"
	CategoryIncidentUpdate TemplateCategory = "INCIDENT_UPDATE"
	CategorySLABreach      TemplateCategory = "SLA_BREACH"
	CategoryKVKKRequest    TemplateCategory = "KVKK_REQUEST"
	CategoryBillingIssue   TemplateCategory = "BILLING_ISSUE"
	CategorySecurityReport TemplateCategory = "SECURITY_REPORT"
)

type DeliveryChannel string

const (
	ChannelEmail DeliveryChannel = "EMAIL"
	ChannelInApp DeliveryChannel = "IN_APP"
	ChannelOps   DeliveryChannel = "OPS_INTERNAL"
)

type CustomerTemplate struct {
	Key                  string
	Category             TemplateCategory
	Channel              DeliveryChannel
	Title                string
	Owner                string
	Language             string
	Status               TemplateStatus
	Required             bool
	InternalOnly         bool
	PublicPublished      bool
	RealCustomerSending  bool
	Subject              string
	BodyPreview          string
	RequiredVariables    []string
	HasTenantContext     bool
	HasTicketContext     bool
	HasSLAContext        bool
	HasKVKKFooter        bool
	HasPrivacyNoticeLink bool
	HasAuditTrail        bool
	HasToneGuard         bool
	HasEscalationHint    bool
}

type TemplateInput struct {
	Phase                           string
	Target                          string
	InternalTemplatesReady          bool
	PublicTemplatesPublished        bool
	RealCustomerSendingEnabled      bool
	RequiredTemplateKeys            []string
	RequiredCategories              []TemplateCategory
	Templates                       []CustomerTemplate
	RequireTenantContext            bool
	RequireTicketContext            bool
	RequireAuditTrail               bool
	RequireToneGuard                bool
	RequireKVKKFooter               bool
	RequirePrivacyNoticeForKVKK     bool
	RequireSLAContextForBreach      bool
	RequireEscalationHintForBreach  bool
	RequireTurkishLanguageTemplates bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type TemplateReport struct {
	Status                     string
	InternalTemplatesReady     bool
	PublicTemplatesPublished   bool
	RealCustomerSendingEnabled bool
	RequiredFailCount          int
	OptionalWarnCount          int
	PassCount                  int
	Findings                   []Finding
}

func Evaluate(input TemplateInput) (TemplateReport, error) {
	report := TemplateReport{
		Status:                     "PASS",
		InternalTemplatesReady:     false,
		PublicTemplatesPublished:   false,
		RealCustomerSendingEnabled: false,
		Findings:                   []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.PublicTemplatesPublished {
		addFail(&report, "PUBLIC_TEMPLATE_PUBLICATION_BLOCKED", "bu fazda template public yayınlanamaz")
	}

	if input.RealCustomerSendingEnabled {
		addFail(&report, "REAL_CUSTOMER_SENDING_BLOCKED", "bu fazda gerçek müşteriye iletişim gönderimi açılamaz")
	}

	templateByKey := map[string]CustomerTemplate{}
	categoryCoverage := map[TemplateCategory]bool{}

	for _, template := range input.Templates {
		key := strings.TrimSpace(template.Key)
		if key == "" {
			addFail(&report, "TEMPLATE_KEY_MISSING", "template key boş olamaz")
			continue
		}

		if _, exists := templateByKey[key]; exists {
			addFail(&report, "TEMPLATE_DUPLICATE", fmt.Sprintf("template duplicate: %s", key))
			continue
		}

		templateByKey[key] = template
		categoryCoverage[template.Category] = true

		if template.Required && template.Status != StatusReady {
			addFail(&report, "REQUIRED_TEMPLATE_NOT_READY", fmt.Sprintf("zorunlu template READY değil: %s", key))
		} else if template.Required {
			report.PassCount++
		}

		if template.Required && strings.TrimSpace(template.Subject) == "" {
			addFail(&report, "TEMPLATE_SUBJECT_MISSING", fmt.Sprintf("subject eksik: %s", key))
		} else if template.Required {
			report.PassCount++
		}

		if template.Required && strings.TrimSpace(template.BodyPreview) == "" {
			addFail(&report, "TEMPLATE_BODY_MISSING", fmt.Sprintf("body preview eksik: %s", key))
		} else if template.Required {
			report.PassCount++
		}

		if input.RequireTurkishLanguageTemplates && template.Required && template.Language != "tr-TR" {
			addFail(&report, "TURKISH_LANGUAGE_REQUIRED", fmt.Sprintf("template dili tr-TR değil: %s", key))
		} else if template.Required {
			report.PassCount++
		}

		if input.RequireTenantContext && template.Required && !template.HasTenantContext {
			addFail(&report, "TENANT_CONTEXT_REQUIRED", fmt.Sprintf("tenant context eksik: %s", key))
		} else if template.Required {
			report.PassCount++
		}

		if input.RequireTicketContext && template.Required && !template.HasTicketContext {
			addFail(&report, "TICKET_CONTEXT_REQUIRED", fmt.Sprintf("ticket context eksik: %s", key))
		} else if template.Required {
			report.PassCount++
		}

		if input.RequireAuditTrail && template.Required && !template.HasAuditTrail {
			addFail(&report, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail eksik: %s", key))
		} else if template.Required {
			report.PassCount++
		}

		if input.RequireToneGuard && template.Required && !template.HasToneGuard {
			addFail(&report, "TONE_GUARD_REQUIRED", fmt.Sprintf("tone guard eksik: %s", key))
		} else if template.Required {
			report.PassCount++
		}

		if input.RequireKVKKFooter && template.Required && !template.HasKVKKFooter {
			addFail(&report, "KVKK_FOOTER_REQUIRED", fmt.Sprintf("KVKK footer eksik: %s", key))
		} else if template.Required {
			report.PassCount++
		}

		if input.RequirePrivacyNoticeForKVKK && template.Category == CategoryKVKKRequest && !template.HasPrivacyNoticeLink {
			addFail(&report, "KVKK_PRIVACY_NOTICE_LINK_REQUIRED", fmt.Sprintf("KVKK template privacy notice link içermeli: %s", key))
		}

		if input.RequireSLAContextForBreach && template.Category == CategorySLABreach && !template.HasSLAContext {
			addFail(&report, "SLA_CONTEXT_REQUIRED_FOR_BREACH", fmt.Sprintf("SLA breach template SLA context içermeli: %s", key))
		}

		if input.RequireEscalationHintForBreach && template.Category == CategorySLABreach && !template.HasEscalationHint {
			addFail(&report, "ESCALATION_HINT_REQUIRED_FOR_BREACH", fmt.Sprintf("SLA breach template escalation hint içermeli: %s", key))
		}

		if template.PublicPublished {
			addFail(&report, "PUBLIC_PUBLISHED_TEMPLATE_BLOCKED", fmt.Sprintf("bu fazda public published template kapalı kalmalı: %s", key))
		}

		if template.RealCustomerSending {
			addFail(&report, "REAL_CUSTOMER_TEMPLATE_SEND_BLOCKED", fmt.Sprintf("bu fazda real customer sending kapalı kalmalı: %s", key))
		}

		if template.Required && !hasVariable(template.RequiredVariables, "tenant_id") {
			addFail(&report, "TENANT_ID_VARIABLE_REQUIRED", fmt.Sprintf("tenant_id değişkeni eksik: %s", key))
		} else if template.Required {
			report.PassCount++
		}

		if template.Required && !hasVariable(template.RequiredVariables, "ticket_id") {
			addFail(&report, "TICKET_ID_VARIABLE_REQUIRED", fmt.Sprintf("ticket_id değişkeni eksik: %s", key))
		} else if template.Required {
			report.PassCount++
		}

		if template.Required && !hasVariable(template.RequiredVariables, "correlation_id") {
			addFail(&report, "CORRELATION_ID_VARIABLE_REQUIRED", fmt.Sprintf("correlation_id değişkeni eksik: %s", key))
		} else if template.Required {
			report.PassCount++
		}
	}

	for _, requiredKey := range input.RequiredTemplateKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}

		template, exists := templateByKey[requiredKey]
		if !exists {
			addFail(&report, "REQUIRED_TEMPLATE_NOT_REGISTERED", fmt.Sprintf("required listesinde olup inventory'de yok: %s", requiredKey))
			continue
		}

		if !template.Required {
			addFail(&report, "REQUIRED_TEMPLATE_FLAG_FALSE", fmt.Sprintf("required listesinde ama template required=false: %s", requiredKey))
			continue
		}

		report.PassCount++
	}

	for _, category := range input.RequiredCategories {
		if !categoryCoverage[category] {
			addFail(&report, "REQUIRED_CATEGORY_MISSING", fmt.Sprintf("template category eksik: %s", category))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalTemplatesReady = false
		report.PublicTemplatesPublished = false
		report.RealCustomerSendingEnabled = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalTemplatesReady = input.InternalTemplatesReady
	report.PublicTemplatesPublished = false
	report.RealCustomerSendingEnabled = false
	return report, nil
}

func RequiredTemplateKeys(input TemplateInput) []string {
	keys := make([]string, 0, len(input.RequiredTemplateKeys))
	keys = append(keys, input.RequiredTemplateKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(report TemplateReport) error {
	if report.RequiredFailCount > 0 || report.Status != "PASS" {
		return errors.New("customer communication templates failed")
	}
	return nil
}

func addFail(report *TemplateReport, code, message string) {
	report.RequiredFailCount++
	report.Findings = append(report.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}

func hasVariable(vars []string, target string) bool {
	for _, v := range vars {
		if v == target {
			return true
		}
	}
	return false
}
