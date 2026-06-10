package quotesalesflow

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type StepStatus string

const (
	StatusReady       StepStatus = "READY"
	StatusPendingNext StepStatus = "PENDING_NEXT"
	StatusBlocked     StepStatus = "BLOCKED"
)

type SalesEvent string

const (
	EventQuoteRequestReceived     SalesEvent = "QUOTE_REQUEST_RECEIVED"
	EventCRMStageVerified         SalesEvent = "CRM_STAGE_VERIFIED"
	EventCustomerProfileValidated SalesEvent = "CUSTOMER_PROFILE_VALIDATED"
	EventPricingSnapshotAttached  SalesEvent = "PRICING_SNAPSHOT_ATTACHED"
	EventDiscountApprovalQueued   SalesEvent = "DISCOUNT_APPROVAL_QUEUED"
	EventProposalDraftCreated     SalesEvent = "PROPOSAL_DRAFT_CREATED"
	EventCommercialTermsReviewed  SalesEvent = "COMMERCIAL_TERMS_REVIEWED"
	EventQuoteApprovalRecorded    SalesEvent = "QUOTE_APPROVAL_RECORDED"
	EventSalesWonHandoffReady     SalesEvent = "SALES_WON_HANDOFF_READY"
	EventSalesOpsReportDeferred   SalesEvent = "SALES_OPS_REPORT_DEFERRED"
)

type SalesStep struct {
	Key                           string
	Event                         SalesEvent
	Title                         string
	Owner                         string
	Status                        StepStatus
	Required                      bool
	HasEvidence                   bool
	HasCounterBasedAudit          bool
	RequiredFailCount             int
	OptionalWarnCount             int
	ProductionSalesEnabled        bool
	RealCustomerSalesOpen         bool
	AutoQuoteSendEnabled          bool
	AutoContractActivationEnabled bool
	RequiresTenantID              bool
	RequiresLeadID                bool
	RequiresQuoteID               bool
	RequiresCRMStage              bool
	RequiresCustomerProfile       bool
	RequiresPricingSnapshot       bool
	RequiresPlanSnapshot          bool
	RequiresDiscountApproval      bool
	RequiresCommercialTerms       bool
	RequiresOwnerApproval         bool
	RequiresAuditTrail            bool
	RequiresConsentCheck          bool
	RequiresKVKKNotice            bool
	RequiresValidityWindow        bool
	RequiresRollbackPath          bool
	RequiresOnboardingHandoff     bool
	BlocksProductionSales         bool
	BlocksRealCustomerSales       bool
	BlocksAutoQuoteSend           bool
	BlocksAutoContractActivation  bool
	DeferredToSalesOpsReport      bool
	DeferredReason                string
}

type FlowInput struct {
	Phase                              string
	Target                             string
	InternalQuoteSalesFlowReady        bool
	ProductionSalesEnabled             bool
	RealCustomerSalesOpen              bool
	AutoQuoteSendEnabled               bool
	AutoContractActivationEnabled      bool
	RequiredStepKeys                   []string
	RequiredEvents                     []SalesEvent
	Steps                              []SalesStep
	RequireEvidence                    bool
	RequireCounterBasedAudit           bool
	RequireNoRequiredFail              bool
	RequireNoOptionalWarn              bool
	RequireTenantID                    bool
	RequireLeadID                      bool
	RequireQuoteID                     bool
	RequireCRMStage                    bool
	RequireCustomerProfile             bool
	RequirePricingSnapshot             bool
	RequirePlanSnapshot                bool
	RequireDiscountApproval            bool
	RequireCommercialTerms             bool
	RequireOwnerApproval               bool
	RequireAuditTrail                  bool
	RequireConsentCheck                bool
	RequireKVKKNotice                  bool
	RequireValidityWindow              bool
	RequireRollbackPath                bool
	RequireOnboardingHandoff           bool
	RequireProductionSalesBlock        bool
	RequireRealCustomerSalesBlock      bool
	RequireAutoQuoteSendBlock          bool
	RequireAutoContractActivationBlock bool
	AllowSalesOpsReportDeferred        bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type FlowReport struct {
	Status                        string
	InternalQuoteSalesFlowReady   bool
	ProductionSalesEnabled        bool
	RealCustomerSalesOpen         bool
	AutoQuoteSendEnabled          bool
	AutoContractActivationEnabled bool
	RequiredFailCount             int
	OptionalWarnCount             int
	PassCount                     int
	Findings                      []Finding
}

func Evaluate(input FlowInput) (FlowReport, error) {
	report := FlowReport{
		Status:                        "PASS",
		InternalQuoteSalesFlowReady:   false,
		ProductionSalesEnabled:        false,
		RealCustomerSalesOpen:         false,
		AutoQuoteSendEnabled:          false,
		AutoContractActivationEnabled: false,
		Findings:                      []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionSalesEnabled {
		addFail(&report, "PRODUCTION_SALES_BLOCKED", "bu fazda production satış açılamaz")
	}

	if input.RealCustomerSalesOpen {
		addFail(&report, "REAL_CUSTOMER_SALES_BLOCKED", "bu fazda gerçek müşteri satış operasyonu açılamaz")
	}

	if input.AutoQuoteSendEnabled {
		addFail(&report, "AUTO_QUOTE_SEND_BLOCKED", "bu fazda otomatik teklif gönderimi açılamaz")
	}

	if input.AutoContractActivationEnabled {
		addFail(&report, "AUTO_CONTRACT_ACTIVATION_BLOCKED", "bu fazda otomatik sözleşme/tenant aktivasyonu açılamaz")
	}

	stepByKey := map[string]SalesStep{}
	eventCoverage := map[SalesEvent]bool{}

	for _, step := range input.Steps {
		key := strings.TrimSpace(step.Key)
		if key == "" {
			addFail(&report, "SALES_STEP_KEY_MISSING", "sales step key boş olamaz")
			continue
		}

		if _, exists := stepByKey[key]; exists {
			addFail(&report, "SALES_STEP_DUPLICATE", fmt.Sprintf("sales step duplicate: %s", key))
			continue
		}

		stepByKey[key] = step
		eventCoverage[step.Event] = true

		if step.Required && step.Status != StatusReady {
			if step.DeferredToSalesOpsReport && input.AllowSalesOpsReportDeferred {
				report.PassCount++
			} else {
				addFail(&report, "REQUIRED_STEP_NOT_READY", fmt.Sprintf("required sales step READY değil: %s", key))
			}
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireEvidence && step.Required && !step.HasEvidence {
			addFail(&report, "EVIDENCE_REQUIRED", fmt.Sprintf("evidence eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireCounterBasedAudit && step.Required && !step.HasCounterBasedAudit {
			addFail(&report, "COUNTER_BASED_AUDIT_REQUIRED", fmt.Sprintf("counter based audit eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireNoRequiredFail && step.Required && step.RequiredFailCount != 0 {
			addFail(&report, "REQUIRED_FAIL_MUST_BE_ZERO", fmt.Sprintf("required fail sıfır değil: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireNoOptionalWarn && step.Required && step.OptionalWarnCount != 0 {
			addFail(&report, "OPTIONAL_WARN_MUST_BE_ZERO", fmt.Sprintf("optional warn sıfır değil: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireTenantID && step.Required && !step.RequiresTenantID {
			addFail(&report, "TENANT_ID_REQUIRED", fmt.Sprintf("tenant_id eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireLeadID && step.Required && !step.RequiresLeadID {
			addFail(&report, "LEAD_ID_REQUIRED", fmt.Sprintf("lead_id eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireQuoteID && step.Required && !step.RequiresQuoteID {
			addFail(&report, "QUOTE_ID_REQUIRED", fmt.Sprintf("quote_id eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireCRMStage && step.Required && !step.RequiresCRMStage {
			addFail(&report, "CRM_STAGE_REQUIRED", fmt.Sprintf("CRM stage eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireCustomerProfile && step.Required && !step.RequiresCustomerProfile {
			addFail(&report, "CUSTOMER_PROFILE_REQUIRED", fmt.Sprintf("customer profile eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequirePricingSnapshot && step.Required && !step.RequiresPricingSnapshot {
			addFail(&report, "PRICING_SNAPSHOT_REQUIRED", fmt.Sprintf("pricing snapshot eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequirePlanSnapshot && step.Required && !step.RequiresPlanSnapshot {
			addFail(&report, "PLAN_SNAPSHOT_REQUIRED", fmt.Sprintf("plan snapshot eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireDiscountApproval && step.Required && !step.RequiresDiscountApproval {
			addFail(&report, "DISCOUNT_APPROVAL_REQUIRED", fmt.Sprintf("discount approval eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireCommercialTerms && step.Required && !step.RequiresCommercialTerms {
			addFail(&report, "COMMERCIAL_TERMS_REQUIRED", fmt.Sprintf("commercial terms eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireOwnerApproval && step.Required && !step.RequiresOwnerApproval {
			addFail(&report, "OWNER_APPROVAL_REQUIRED", fmt.Sprintf("owner approval eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAuditTrail && step.Required && !step.RequiresAuditTrail {
			addFail(&report, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireConsentCheck && step.Required && !step.RequiresConsentCheck {
			addFail(&report, "CONSENT_CHECK_REQUIRED", fmt.Sprintf("consent check eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireKVKKNotice && step.Required && !step.RequiresKVKKNotice {
			addFail(&report, "KVKK_NOTICE_REQUIRED", fmt.Sprintf("KVKK notice eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireValidityWindow && step.Required && !step.RequiresValidityWindow {
			addFail(&report, "VALIDITY_WINDOW_REQUIRED", fmt.Sprintf("validity window eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireRollbackPath && step.Required && !step.RequiresRollbackPath {
			addFail(&report, "ROLLBACK_PATH_REQUIRED", fmt.Sprintf("rollback path eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireOnboardingHandoff && step.Required && !step.RequiresOnboardingHandoff {
			addFail(&report, "ONBOARDING_HANDOFF_REQUIRED", fmt.Sprintf("onboarding handoff eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireProductionSalesBlock && step.Required && !step.BlocksProductionSales {
			addFail(&report, "PRODUCTION_SALES_BLOCK_REQUIRED", fmt.Sprintf("production sales block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireRealCustomerSalesBlock && step.Required && !step.BlocksRealCustomerSales {
			addFail(&report, "REAL_CUSTOMER_SALES_BLOCK_REQUIRED", fmt.Sprintf("real customer sales block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAutoQuoteSendBlock && step.Required && !step.BlocksAutoQuoteSend {
			addFail(&report, "AUTO_QUOTE_SEND_BLOCK_REQUIRED", fmt.Sprintf("auto quote send block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAutoContractActivationBlock && step.Required && !step.BlocksAutoContractActivation {
			addFail(&report, "AUTO_CONTRACT_ACTIVATION_BLOCK_REQUIRED", fmt.Sprintf("auto contract activation block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if step.ProductionSalesEnabled {
			addFail(&report, "STEP_PRODUCTION_SALES_ENABLED_BLOCKED", fmt.Sprintf("production sales enabled açık olamaz: %s", key))
		}

		if step.RealCustomerSalesOpen {
			addFail(&report, "STEP_REAL_CUSTOMER_SALES_OPEN_BLOCKED", fmt.Sprintf("real customer sales open açık olamaz: %s", key))
		}

		if step.AutoQuoteSendEnabled {
			addFail(&report, "STEP_AUTO_QUOTE_SEND_ENABLED_BLOCKED", fmt.Sprintf("auto quote send açık olamaz: %s", key))
		}

		if step.AutoContractActivationEnabled {
			addFail(&report, "STEP_AUTO_CONTRACT_ACTIVATION_ENABLED_BLOCKED", fmt.Sprintf("auto contract activation açık olamaz: %s", key))
		}

		if step.DeferredToSalesOpsReport && strings.TrimSpace(step.DeferredReason) == "" {
			addFail(&report, "DEFERRED_REASON_REQUIRED", fmt.Sprintf("deferred reason eksik: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredStepKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}

		step, exists := stepByKey[requiredKey]
		if !exists {
			addFail(&report, "REQUIRED_STEP_NOT_REGISTERED", fmt.Sprintf("required listesinde olup flow içinde yok: %s", requiredKey))
			continue
		}

		if !step.Required {
			addFail(&report, "REQUIRED_STEP_FLAG_FALSE", fmt.Sprintf("required listesinde ama step required=false: %s", requiredKey))
			continue
		}

		report.PassCount++
	}

	for _, event := range input.RequiredEvents {
		if !eventCoverage[event] {
			addFail(&report, "REQUIRED_EVENT_MISSING", fmt.Sprintf("sales event eksik: %s", event))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		return report, nil
	}

	report.Status = "PASS"
	report.InternalQuoteSalesFlowReady = input.InternalQuoteSalesFlowReady
	report.ProductionSalesEnabled = false
	report.RealCustomerSalesOpen = false
	report.AutoQuoteSendEnabled = false
	report.AutoContractActivationEnabled = false
	return report, nil
}

func RequiredStepKeys(input FlowInput) []string {
	keys := make([]string, 0, len(input.RequiredStepKeys))
	keys = append(keys, input.RequiredStepKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(report FlowReport) error {
	if report.RequiredFailCount > 0 || report.Status != "PASS" {
		return errors.New("quote sales flow failed")
	}
	return nil
}

func addFail(report *FlowReport, code, message string) {
	report.RequiredFailCount++
	report.Findings = append(report.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
