package supportchannel

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type ChannelType string

const (
	ChannelEmail         ChannelType = "EMAIL"
	ChannelInApp         ChannelType = "IN_APP"
	ChannelHelpCenter    ChannelType = "HELP_CENTER"
	ChannelKVKK          ChannelType = "KVKK_REQUEST"
	ChannelSecurity      ChannelType = "SECURITY_REPORT"
	ChannelOpsEscalation ChannelType = "OPS_ESCALATION"
)

type ChannelStatus string

const (
	StatusReady    ChannelStatus = "READY"
	StatusDraft    ChannelStatus = "DRAFT"
	StatusDisabled ChannelStatus = "DISABLED"
)

type IssueFamily string

const (
	IssuePilot      IssueFamily = "PILOT"
	IssueBilling    IssueFamily = "BILLING"
	IssueKVKK       IssueFamily = "KVKK"
	IssueSecurity   IssueFamily = "SECURITY"
	IssueTechnical  IssueFamily = "TECHNICAL"
	IssueCommercial IssueFamily = "COMMERCIAL"
)

type SupportChannel struct {
	Key                    string
	Type                   ChannelType
	Title                  string
	Status                 ChannelStatus
	Owner                  string
	Required               bool
	PublicVisible          bool
	InternalOnly           bool
	AllowedFamilies        []IssueFamily
	RequiresTenantID       bool
	RequiresRequesterEmail bool
	RequiresCorrelationID  bool
	RequiresConsentContext bool
	RequiresAuditTrail     bool
	RequiresSLAKey         bool
	HasIntakeTemplate      bool
	HasRoutingRule         bool
	HasOpsOwner            bool
	HasPrivacyNoticeLink   bool
}

type ChannelInput struct {
	Phase                         string
	Target                        string
	InternalChannelStructureReady bool
	PublicSupportEnabled          bool
	RealCustomerSupportOpen       bool
	RequiredChannelKeys           []string
	RequiredFamilies              []IssueFamily
	Channels                      []SupportChannel
	RequireTenantSafeIntake       bool
	RequireRequesterEmail         bool
	RequireCorrelationID          bool
	RequireSLAKey                 bool
	RequireAuditTrail             bool
	RequireIntakeTemplate         bool
	RequireRoutingRule            bool
	RequireOpsOwner               bool
	RequirePrivacyNoticeForKVKK   bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type ChannelReport struct {
	Status                        string
	InternalChannelStructureReady bool
	PublicSupportEnabled          bool
	RealCustomerSupportOpen       bool
	RequiredFailCount             int
	OptionalWarnCount             int
	PassCount                     int
	Findings                      []Finding
}

func Evaluate(input ChannelInput) (ChannelReport, error) {
	report := ChannelReport{
		Status:                        "PASS",
		InternalChannelStructureReady: false,
		PublicSupportEnabled:          false,
		RealCustomerSupportOpen:       false,
		Findings:                      []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.PublicSupportEnabled {
		addFail(&report, "PUBLIC_SUPPORT_BLOCKED", "bu fazda public support enabled açılamaz")
	}

	if input.RealCustomerSupportOpen {
		addFail(&report, "REAL_CUSTOMER_SUPPORT_BLOCKED", "bu fazda gerçek müşteri support intake açılamaz")
	}

	channelByKey := map[string]SupportChannel{}
	familyCoverage := map[IssueFamily]bool{}

	for _, channel := range input.Channels {
		key := strings.TrimSpace(channel.Key)
		if key == "" {
			addFail(&report, "CHANNEL_KEY_MISSING", "support channel key boş olamaz")
			continue
		}

		if _, exists := channelByKey[key]; exists {
			addFail(&report, "CHANNEL_DUPLICATE", fmt.Sprintf("support channel duplicate: %s", key))
			continue
		}

		channelByKey[key] = channel

		for _, family := range channel.AllowedFamilies {
			familyCoverage[family] = true
		}

		if channel.Required && channel.Status != StatusReady {
			addFail(&report, "REQUIRED_CHANNEL_NOT_READY", fmt.Sprintf("zorunlu channel READY değil: %s", key))
		} else if channel.Required {
			report.PassCount++
		}

		if input.RequireTenantSafeIntake && channel.Required && !channel.RequiresTenantID {
			addFail(&report, "TENANT_ID_REQUIRED", fmt.Sprintf("tenant_id zorunlu değil: %s", key))
		} else if channel.Required {
			report.PassCount++
		}

		if input.RequireRequesterEmail && channel.Required && !channel.RequiresRequesterEmail {
			addFail(&report, "REQUESTER_EMAIL_REQUIRED", fmt.Sprintf("requester_email zorunlu değil: %s", key))
		} else if channel.Required {
			report.PassCount++
		}

		if input.RequireCorrelationID && channel.Required && !channel.RequiresCorrelationID {
			addFail(&report, "CORRELATION_ID_REQUIRED", fmt.Sprintf("correlation_id zorunlu değil: %s", key))
		} else if channel.Required {
			report.PassCount++
		}

		if input.RequireSLAKey && channel.Required && !channel.RequiresSLAKey {
			addFail(&report, "SLA_KEY_REQUIRED", fmt.Sprintf("sla_key zorunlu değil: %s", key))
		} else if channel.Required {
			report.PassCount++
		}

		if input.RequireAuditTrail && channel.Required && !channel.RequiresAuditTrail {
			addFail(&report, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail zorunlu değil: %s", key))
		} else if channel.Required {
			report.PassCount++
		}

		if input.RequireIntakeTemplate && channel.Required && !channel.HasIntakeTemplate {
			addFail(&report, "INTAKE_TEMPLATE_REQUIRED", fmt.Sprintf("intake template eksik: %s", key))
		} else if channel.Required {
			report.PassCount++
		}

		if input.RequireRoutingRule && channel.Required && !channel.HasRoutingRule {
			addFail(&report, "ROUTING_RULE_REQUIRED", fmt.Sprintf("routing rule eksik: %s", key))
		} else if channel.Required {
			report.PassCount++
		}

		if input.RequireOpsOwner && channel.Required && !channel.HasOpsOwner {
			addFail(&report, "OPS_OWNER_REQUIRED", fmt.Sprintf("ops owner eksik: %s", key))
		} else if channel.Required {
			report.PassCount++
		}

		if input.RequirePrivacyNoticeForKVKK && channel.Type == ChannelKVKK && !channel.HasPrivacyNoticeLink {
			addFail(&report, "KVKK_PRIVACY_NOTICE_LINK_REQUIRED", fmt.Sprintf("KVKK channel privacy notice link içermeli: %s", key))
		}

		if channel.PublicVisible {
			addFail(&report, "PUBLIC_VISIBLE_CHANNEL_BLOCKED", fmt.Sprintf("bu fazda public visible channel kapalı kalmalı: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredChannelKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}

		channel, exists := channelByKey[requiredKey]
		if !exists {
			addFail(&report, "REQUIRED_CHANNEL_NOT_REGISTERED", fmt.Sprintf("required listesinde olup inventory'de yok: %s", requiredKey))
			continue
		}

		if !channel.Required {
			addFail(&report, "REQUIRED_CHANNEL_FLAG_FALSE", fmt.Sprintf("required listesinde ama channel required=false: %s", requiredKey))
			continue
		}

		report.PassCount++
	}

	for _, family := range input.RequiredFamilies {
		if !familyCoverage[family] {
			addFail(&report, "ISSUE_FAMILY_ROUTE_MISSING", fmt.Sprintf("issue family için channel yok: %s", family))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalChannelStructureReady = false
		report.PublicSupportEnabled = false
		report.RealCustomerSupportOpen = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalChannelStructureReady = input.InternalChannelStructureReady
	report.PublicSupportEnabled = false
	report.RealCustomerSupportOpen = false
	return report, nil
}

func RequiredChannelKeys(input ChannelInput) []string {
	keys := make([]string, 0, len(input.RequiredChannelKeys))
	keys = append(keys, input.RequiredChannelKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(report ChannelReport) error {
	if report.RequiredFailCount > 0 || report.Status != "PASS" {
		return errors.New("support channel structure failed")
	}
	return nil
}

func addFail(report *ChannelReport, code, message string) {
	report.RequiredFailCount++
	report.Findings = append(report.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
