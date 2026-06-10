package tenantplanchange

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

type PlanChangeEvent string

const (
	EventPlanChangeRequested       PlanChangeEvent = "PLAN_CHANGE_REQUESTED"
	EventCurrentPlanSnapshotted    PlanChangeEvent = "CURRENT_PLAN_SNAPSHOTTED"
	EventTargetPlanValidated       PlanChangeEvent = "TARGET_PLAN_VALIDATED"
	EventEntitlementDiffCalculated PlanChangeEvent = "ENTITLEMENT_DIFF_CALCULATED"
	EventBillingImpactCalculated   PlanChangeEvent = "BILLING_IMPACT_CALCULATED"
	EventProrationPolicyPrepared   PlanChangeEvent = "PRORATION_POLICY_PREPARED"
	EventDowngradeSafetyChecked    PlanChangeEvent = "DOWNGRADE_SAFETY_CHECKED"
	EventOwnerApprovalQueued       PlanChangeEvent = "OWNER_APPROVAL_QUEUED"
	EventEffectiveDateScheduled    PlanChangeEvent = "EFFECTIVE_DATE_SCHEDULED"
	EventPlanChangeDeferred        PlanChangeEvent = "PLAN_CHANGE_DEFERRED"
)

type PlanChangeStep struct {
	Key                           string
	Event                         PlanChangeEvent
	Title                         string
	Owner                         string
	Status                        StepStatus
	Required                      bool
	InternalReady                 bool
	HasEvidence                   bool
	HasCounterBasedAudit          bool
	RequiredFailCount             int
	OptionalWarnCount             int
	ProductionPlanChangeEnabled   bool
	RealCustomerPlanChangeEnabled bool
	AutoEntitlementSwitchEnabled  bool
	AutoProrationBillingEnabled   bool
	RequiresTenantID              bool
	RequiresPlanChangeRequestID   bool
	RequiresCurrentPlanID         bool
	RequiresTargetPlanID          bool
	RequiresPlanSnapshot          bool
	RequiresEntitlementDiff       bool
	RequiresBillingImpact         bool
	RequiresProrationPolicy       bool
	RequiresDowngradeSafetyCheck  bool
	RequiresOwnerApproval         bool
	RequiresEffectiveDate         bool
	RequiresAuditTrail            bool
	RequiresRollbackPlan          bool
	RequiresSupportHandoff        bool
	RequiresCustomerTemplate      bool
	BlocksProductionPlanChange    bool
	BlocksRealCustomerPlanChange  bool
	BlocksAutoEntitlementSwitch   bool
	BlocksAutoProrationBilling    bool
	DeferredToProductionApproval  bool
	DeferredReason                string
}

type FlowInput struct {
	Phase                              string
	Target                             string
	InternalTenantPlanChangeReady      bool
	ProductionPlanChangeEnabled        bool
	RealCustomerPlanChangeEnabled      bool
	AutoEntitlementSwitchEnabled       bool
	AutoProrationBillingEnabled        bool
	RequiredStepKeys                   []string
	RequiredEvents                     []PlanChangeEvent
	Steps                              []PlanChangeStep
	RequireInternalReady               bool
	RequireEvidence                    bool
	RequireCounterBasedAudit           bool
	RequireNoRequiredFail              bool
	RequireNoOptionalWarn              bool
	RequireTenantID                    bool
	RequirePlanChangeRequestID         bool
	RequireCurrentPlanID               bool
	RequireTargetPlanID                bool
	RequirePlanSnapshot                bool
	RequireEntitlementDiff             bool
	RequireBillingImpact               bool
	RequireProrationPolicy             bool
	RequireDowngradeSafetyCheck        bool
	RequireOwnerApproval               bool
	RequireEffectiveDate               bool
	RequireAuditTrail                  bool
	RequireRollbackPlan                bool
	RequireSupportHandoff              bool
	RequireCustomerTemplate            bool
	RequireProductionPlanChangeBlock   bool
	RequireRealCustomerPlanChangeBlock bool
	RequireAutoEntitlementSwitchBlock  bool
	RequireAutoProrationBillingBlock   bool
	AllowProductionApprovalDeferred    bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type FlowReport struct {
	Status                        string
	InternalTenantPlanChangeReady bool
	ProductionPlanChangeEnabled   bool
	RealCustomerPlanChangeEnabled bool
	AutoEntitlementSwitchEnabled  bool
	AutoProrationBillingEnabled   bool
	RequiredFailCount             int
	OptionalWarnCount             int
	PassCount                     int
	Findings                      []Finding
}

func Evaluate(input FlowInput) (FlowReport, error) {
	report := FlowReport{
		Status:                        "PASS",
		InternalTenantPlanChangeReady: false,
		ProductionPlanChangeEnabled:   false,
		RealCustomerPlanChangeEnabled: false,
		AutoEntitlementSwitchEnabled:  false,
		AutoProrationBillingEnabled:   false,
		Findings:                      []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionPlanChangeEnabled {
		addFail(&report, "PRODUCTION_PLAN_CHANGE_BLOCKED", "bu fazda production plan change açılamaz")
	}

	if input.RealCustomerPlanChangeEnabled {
		addFail(&report, "REAL_CUSTOMER_PLAN_CHANGE_BLOCKED", "bu fazda gerçek müşteri plan değişikliği açılamaz")
	}

	if input.AutoEntitlementSwitchEnabled {
		addFail(&report, "AUTO_ENTITLEMENT_SWITCH_BLOCKED", "bu fazda otomatik entitlement switch açılamaz")
	}

	if input.AutoProrationBillingEnabled {
		addFail(&report, "AUTO_PRORATION_BILLING_BLOCKED", "bu fazda otomatik proration billing açılamaz")
	}

	stepByKey := map[string]PlanChangeStep{}
	eventCoverage := map[PlanChangeEvent]bool{}

	for _, step := range input.Steps {
		key := strings.TrimSpace(step.Key)
		if key == "" {
			addFail(&report, "PLAN_CHANGE_STEP_KEY_MISSING", "plan change step key boş olamaz")
			continue
		}

		if _, exists := stepByKey[key]; exists {
			addFail(&report, "PLAN_CHANGE_STEP_DUPLICATE", fmt.Sprintf("plan change step duplicate: %s", key))
			continue
		}

		stepByKey[key] = step
		eventCoverage[step.Event] = true

		if step.Required && step.Status != StatusReady {
			if step.DeferredToProductionApproval && input.AllowProductionApprovalDeferred {
				report.PassCount++
			} else {
				addFail(&report, "REQUIRED_STEP_NOT_READY", fmt.Sprintf("required plan change step READY değil: %s", key))
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

		if input.RequirePlanChangeRequestID && step.Required && !step.RequiresPlanChangeRequestID {
			addFail(&report, "PLAN_CHANGE_REQUEST_ID_REQUIRED", fmt.Sprintf("plan_change_request_id eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireCurrentPlanID && step.Required && !step.RequiresCurrentPlanID {
			addFail(&report, "CURRENT_PLAN_ID_REQUIRED", fmt.Sprintf("current_plan_id eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireTargetPlanID && step.Required && !step.RequiresTargetPlanID {
			addFail(&report, "TARGET_PLAN_ID_REQUIRED", fmt.Sprintf("target_plan_id eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequirePlanSnapshot && step.Required && !step.RequiresPlanSnapshot {
			addFail(&report, "PLAN_SNAPSHOT_REQUIRED", fmt.Sprintf("plan snapshot eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireEntitlementDiff && step.Required && !step.RequiresEntitlementDiff {
			addFail(&report, "ENTITLEMENT_DIFF_REQUIRED", fmt.Sprintf("entitlement diff eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireBillingImpact && step.Required && !step.RequiresBillingImpact {
			addFail(&report, "BILLING_IMPACT_REQUIRED", fmt.Sprintf("billing impact eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireProrationPolicy && step.Required && !step.RequiresProrationPolicy {
			addFail(&report, "PRORATION_POLICY_REQUIRED", fmt.Sprintf("proration policy eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireDowngradeSafetyCheck && step.Required && !step.RequiresDowngradeSafetyCheck {
			addFail(&report, "DOWNGRADE_SAFETY_CHECK_REQUIRED", fmt.Sprintf("downgrade safety check eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireOwnerApproval && step.Required && !step.RequiresOwnerApproval {
			addFail(&report, "OWNER_APPROVAL_REQUIRED", fmt.Sprintf("owner approval eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireEffectiveDate && step.Required && !step.RequiresEffectiveDate {
			addFail(&report, "EFFECTIVE_DATE_REQUIRED", fmt.Sprintf("effective date eksik: %s", key))
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

		if input.RequireCustomerTemplate && step.Required && !step.RequiresCustomerTemplate {
			addFail(&report, "CUSTOMER_TEMPLATE_REQUIRED", fmt.Sprintf("customer template eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireProductionPlanChangeBlock && step.Required && !step.BlocksProductionPlanChange {
			addFail(&report, "PRODUCTION_PLAN_CHANGE_BLOCK_REQUIRED", fmt.Sprintf("production plan change block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireRealCustomerPlanChangeBlock && step.Required && !step.BlocksRealCustomerPlanChange {
			addFail(&report, "REAL_CUSTOMER_PLAN_CHANGE_BLOCK_REQUIRED", fmt.Sprintf("real customer plan change block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAutoEntitlementSwitchBlock && step.Required && !step.BlocksAutoEntitlementSwitch {
			addFail(&report, "AUTO_ENTITLEMENT_SWITCH_BLOCK_REQUIRED", fmt.Sprintf("auto entitlement switch block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAutoProrationBillingBlock && step.Required && !step.BlocksAutoProrationBilling {
			addFail(&report, "AUTO_PRORATION_BILLING_BLOCK_REQUIRED", fmt.Sprintf("auto proration billing block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if step.ProductionPlanChangeEnabled {
			addFail(&report, "STEP_PRODUCTION_PLAN_CHANGE_ENABLED_BLOCKED", fmt.Sprintf("production plan change enabled açık olamaz: %s", key))
		}

		if step.RealCustomerPlanChangeEnabled {
			addFail(&report, "STEP_REAL_CUSTOMER_PLAN_CHANGE_ENABLED_BLOCKED", fmt.Sprintf("real customer plan change enabled açık olamaz: %s", key))
		}

		if step.AutoEntitlementSwitchEnabled {
			addFail(&report, "STEP_AUTO_ENTITLEMENT_SWITCH_ENABLED_BLOCKED", fmt.Sprintf("auto entitlement switch enabled açık olamaz: %s", key))
		}

		if step.AutoProrationBillingEnabled {
			addFail(&report, "STEP_AUTO_PRORATION_BILLING_ENABLED_BLOCKED", fmt.Sprintf("auto proration billing enabled açık olamaz: %s", key))
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
			addFail(&report, "REQUIRED_EVENT_MISSING", fmt.Sprintf("plan change event eksik: %s", event))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		return report, nil
	}

	report.Status = "PASS"
	report.InternalTenantPlanChangeReady = input.InternalTenantPlanChangeReady
	report.ProductionPlanChangeEnabled = false
	report.RealCustomerPlanChangeEnabled = false
	report.AutoEntitlementSwitchEnabled = false
	report.AutoProrationBillingEnabled = false
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
		return errors.New("tenant plan change flow failed")
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
