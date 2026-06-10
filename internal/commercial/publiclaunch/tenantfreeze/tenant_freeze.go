package tenantfreeze

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

type FreezeEvent string

const (
	EventFreezeRequestReceived    FreezeEvent = "FREEZE_REQUEST_RECEIVED"
	EventBillingStatusChecked     FreezeEvent = "BILLING_STATUS_CHECKED"
	EventUnpaidInvoiceChecked     FreezeEvent = "UNPAID_INVOICE_CHECKED"
	EventFreezeEligibilityChecked FreezeEvent = "FREEZE_ELIGIBILITY_CHECKED"
	EventOwnerApprovalQueued      FreezeEvent = "OWNER_APPROVAL_QUEUED"
	EventEntitlementFreezePlanned FreezeEvent = "ENTITLEMENT_FREEZE_PLANNED"
	EventAccessLimitPolicyReady   FreezeEvent = "ACCESS_LIMIT_POLICY_READY"
	EventNotificationBlocked      FreezeEvent = "NOTIFICATION_BLOCKED"
	EventUnfreezePathDefined      FreezeEvent = "UNFREEZE_PATH_DEFINED"
	EventProductionFreezeDeferred FreezeEvent = "PRODUCTION_FREEZE_DEFERRED"
)

type FreezeStep struct {
	Key                             string
	Event                           FreezeEvent
	Title                           string
	Owner                           string
	Status                          StepStatus
	Required                        bool
	InternalReady                   bool
	HasEvidence                     bool
	HasCounterBasedAudit            bool
	RequiredFailCount               int
	OptionalWarnCount               int
	ProductionFreezeEnabled         bool
	RealTenantFreezeEnabled         bool
	AutoAccessCutoffEnabled         bool
	AutoUnfreezeEnabled             bool
	RequiresTenantID                bool
	RequiresFreezeRequestID         bool
	RequiresBillingStatusCheck      bool
	RequiresUnpaidInvoiceCheck      bool
	RequiresFreezeEligibilityPolicy bool
	RequiresOwnerApproval           bool
	RequiresEntitlementFreeze       bool
	RequiresAccessLimitPolicy       bool
	RequiresNotificationTemplate    bool
	RequiresUnfreezePath            bool
	RequiresAuditTrail              bool
	RequiresRollbackPlan            bool
	RequiresSupportHandoff          bool
	BlocksProductionFreeze          bool
	BlocksRealTenantFreeze          bool
	BlocksAutoAccessCutoff          bool
	BlocksAutoUnfreeze              bool
	DeferredToProductionApproval    bool
	DeferredReason                  string
}

type FlowInput struct {
	Phase                           string
	Target                          string
	InternalTenantFreezeReady       bool
	ProductionFreezeEnabled         bool
	RealTenantFreezeEnabled         bool
	AutoAccessCutoffEnabled         bool
	AutoUnfreezeEnabled             bool
	RequiredStepKeys                []string
	RequiredEvents                  []FreezeEvent
	Steps                           []FreezeStep
	RequireInternalReady            bool
	RequireEvidence                 bool
	RequireCounterBasedAudit        bool
	RequireNoRequiredFail           bool
	RequireNoOptionalWarn           bool
	RequireTenantID                 bool
	RequireFreezeRequestID          bool
	RequireBillingStatusCheck       bool
	RequireUnpaidInvoiceCheck       bool
	RequireFreezeEligibilityPolicy  bool
	RequireOwnerApproval            bool
	RequireEntitlementFreeze        bool
	RequireAccessLimitPolicy        bool
	RequireNotificationTemplate     bool
	RequireUnfreezePath             bool
	RequireAuditTrail               bool
	RequireRollbackPlan             bool
	RequireSupportHandoff           bool
	RequireProductionFreezeBlock    bool
	RequireRealTenantFreezeBlock    bool
	RequireAutoAccessCutoffBlock    bool
	RequireAutoUnfreezeBlock        bool
	AllowProductionApprovalDeferred bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type FlowReport struct {
	Status                    string
	InternalTenantFreezeReady bool
	ProductionFreezeEnabled   bool
	RealTenantFreezeEnabled   bool
	AutoAccessCutoffEnabled   bool
	AutoUnfreezeEnabled       bool
	RequiredFailCount         int
	OptionalWarnCount         int
	PassCount                 int
	Findings                  []Finding
}

func Evaluate(input FlowInput) (FlowReport, error) {
	report := FlowReport{
		Status:                    "PASS",
		InternalTenantFreezeReady: false,
		ProductionFreezeEnabled:   false,
		RealTenantFreezeEnabled:   false,
		AutoAccessCutoffEnabled:   false,
		AutoUnfreezeEnabled:       false,
		Findings:                  []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionFreezeEnabled {
		addFail(&report, "PRODUCTION_FREEZE_BLOCKED", "bu fazda production tenant freeze açılamaz")
	}

	if input.RealTenantFreezeEnabled {
		addFail(&report, "REAL_TENANT_FREEZE_BLOCKED", "bu fazda gerçek tenant dondurma açılamaz")
	}

	if input.AutoAccessCutoffEnabled {
		addFail(&report, "AUTO_ACCESS_CUTOFF_BLOCKED", "bu fazda otomatik erişim kesme açılamaz")
	}

	if input.AutoUnfreezeEnabled {
		addFail(&report, "AUTO_UNFREEZE_BLOCKED", "bu fazda otomatik çözme açılamaz")
	}

	stepByKey := map[string]FreezeStep{}
	eventCoverage := map[FreezeEvent]bool{}

	for _, step := range input.Steps {
		key := strings.TrimSpace(step.Key)
		if key == "" {
			addFail(&report, "FREEZE_STEP_KEY_MISSING", "tenant freeze step key boş olamaz")
			continue
		}

		if _, exists := stepByKey[key]; exists {
			addFail(&report, "FREEZE_STEP_DUPLICATE", fmt.Sprintf("tenant freeze step duplicate: %s", key))
			continue
		}

		stepByKey[key] = step
		eventCoverage[step.Event] = true

		if step.Required && step.Status != StatusReady {
			if step.DeferredToProductionApproval && input.AllowProductionApprovalDeferred {
				report.PassCount++
			} else {
				addFail(&report, "REQUIRED_STEP_NOT_READY", fmt.Sprintf("required tenant freeze step READY değil: %s", key))
			}
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireInternalReady && step.Required && !step.InternalReady {
			if step.DeferredToProductionApproval && input.AllowProductionApprovalDeferred {
				report.PassCount++
			} else {
				addFail(&report, "INTERNAL_READY_REQUIRED", fmt.Sprintf("internal ready eksik: %s", key))
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
			addFail(&report, "TENANT_ID_REQUIRED", fmt.Sprintf("tenant_id requirement eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireFreezeRequestID && step.Required && !step.RequiresFreezeRequestID {
			addFail(&report, "FREEZE_REQUEST_ID_REQUIRED", fmt.Sprintf("freeze_request_id eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireBillingStatusCheck && step.Required && !step.RequiresBillingStatusCheck {
			addFail(&report, "BILLING_STATUS_CHECK_REQUIRED", fmt.Sprintf("billing status check eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireUnpaidInvoiceCheck && step.Required && !step.RequiresUnpaidInvoiceCheck {
			addFail(&report, "UNPAID_INVOICE_CHECK_REQUIRED", fmt.Sprintf("unpaid invoice check eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireFreezeEligibilityPolicy && step.Required && !step.RequiresFreezeEligibilityPolicy {
			addFail(&report, "FREEZE_ELIGIBILITY_POLICY_REQUIRED", fmt.Sprintf("freeze eligibility policy eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireOwnerApproval && step.Required && !step.RequiresOwnerApproval {
			addFail(&report, "OWNER_APPROVAL_REQUIRED", fmt.Sprintf("owner approval eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireEntitlementFreeze && step.Required && !step.RequiresEntitlementFreeze {
			addFail(&report, "ENTITLEMENT_FREEZE_REQUIRED", fmt.Sprintf("entitlement freeze eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAccessLimitPolicy && step.Required && !step.RequiresAccessLimitPolicy {
			addFail(&report, "ACCESS_LIMIT_POLICY_REQUIRED", fmt.Sprintf("access limit policy eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireNotificationTemplate && step.Required && !step.RequiresNotificationTemplate {
			addFail(&report, "NOTIFICATION_TEMPLATE_REQUIRED", fmt.Sprintf("notification template eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireUnfreezePath && step.Required && !step.RequiresUnfreezePath {
			addFail(&report, "UNFREEZE_PATH_REQUIRED", fmt.Sprintf("unfreeze path eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAuditTrail && step.Required && !step.RequiresAuditTrail {
			addFail(&report, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireRollbackPlan && step.Required && !step.RequiresRollbackPlan {
			addFail(&report, "ROLLBACK_PLAN_REQUIRED", fmt.Sprintf("rollback plan eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireSupportHandoff && step.Required && !step.RequiresSupportHandoff {
			addFail(&report, "SUPPORT_HANDOFF_REQUIRED", fmt.Sprintf("support handoff eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireProductionFreezeBlock && step.Required && !step.BlocksProductionFreeze {
			addFail(&report, "PRODUCTION_FREEZE_BLOCK_REQUIRED", fmt.Sprintf("production freeze block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireRealTenantFreezeBlock && step.Required && !step.BlocksRealTenantFreeze {
			addFail(&report, "REAL_TENANT_FREEZE_BLOCK_REQUIRED", fmt.Sprintf("real tenant freeze block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAutoAccessCutoffBlock && step.Required && !step.BlocksAutoAccessCutoff {
			addFail(&report, "AUTO_ACCESS_CUTOFF_BLOCK_REQUIRED", fmt.Sprintf("auto access cutoff block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAutoUnfreezeBlock && step.Required && !step.BlocksAutoUnfreeze {
			addFail(&report, "AUTO_UNFREEZE_BLOCK_REQUIRED", fmt.Sprintf("auto unfreeze block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if step.ProductionFreezeEnabled {
			addFail(&report, "STEP_PRODUCTION_FREEZE_ENABLED_BLOCKED", fmt.Sprintf("production freeze enabled açık olamaz: %s", key))
		}

		if step.RealTenantFreezeEnabled {
			addFail(&report, "STEP_REAL_TENANT_FREEZE_ENABLED_BLOCKED", fmt.Sprintf("real tenant freeze enabled açık olamaz: %s", key))
		}

		if step.AutoAccessCutoffEnabled {
			addFail(&report, "STEP_AUTO_ACCESS_CUTOFF_ENABLED_BLOCKED", fmt.Sprintf("auto access cutoff enabled açık olamaz: %s", key))
		}

		if step.AutoUnfreezeEnabled {
			addFail(&report, "STEP_AUTO_UNFREEZE_ENABLED_BLOCKED", fmt.Sprintf("auto unfreeze enabled açık olamaz: %s", key))
		}

		if step.DeferredToProductionApproval && strings.TrimSpace(step.DeferredReason) == "" {
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
			addFail(&report, "REQUIRED_EVENT_MISSING", fmt.Sprintf("tenant freeze event eksik: %s", event))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		return report, nil
	}

	report.Status = "PASS"
	report.InternalTenantFreezeReady = input.InternalTenantFreezeReady
	report.ProductionFreezeEnabled = false
	report.RealTenantFreezeEnabled = false
	report.AutoAccessCutoffEnabled = false
	report.AutoUnfreezeEnabled = false
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
		return errors.New("tenant freeze flow failed")
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
