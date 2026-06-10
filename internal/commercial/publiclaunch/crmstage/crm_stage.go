package crmstage

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type TransitionStatus string

const (
	StatusReady       TransitionStatus = "READY"
	StatusPendingNext TransitionStatus = "PENDING_NEXT"
	StatusBlocked     TransitionStatus = "BLOCKED"
)

type Stage string

const (
	StageLeadIntake        Stage = "LEAD_INTAKE"
	StageDiscovery         Stage = "DISCOVERY"
	StageQualified         Stage = "QUALIFIED"
	StageDemoScheduled     Stage = "DEMO_SCHEDULED"
	StageProposalRequested Stage = "PROPOSAL_REQUESTED"
	StageProposalSent      Stage = "PROPOSAL_SENT"
	StageWon               Stage = "WON"
	StageLost              Stage = "LOST"
	StageOnboardingHandoff Stage = "ONBOARDING_HANDOFF"
)

type StageTransition struct {
	Key                        string
	From                       Stage
	To                         Stage
	Trigger                    string
	Owner                      string
	Status                     TransitionStatus
	Required                   bool
	HasEvidence                bool
	HasCounterBasedAudit       bool
	RequiredFailCount          int
	OptionalWarnCount          int
	ProductionCRMEnabled       bool
	RealCustomerCRMOpen        bool
	AutoSalesActionEnabled     bool
	ExternalCRMProviderEnabled bool
	RequiresTenantID           bool
	RequiresLeadID             bool
	RequiresStageReason        bool
	RequiresOwnerAssignment    bool
	RequiresAuditTrail         bool
	RequiresConsentCheck       bool
	RequiresKVKKNotice         bool
	RequiresNextAction         bool
	RequiresSLA                bool
	RequiresRollbackPath       bool
	RequiresDuplicateGuard     bool
	RequiresManualReview       bool
	BlocksProductionCRM        bool
	BlocksRealCustomerCRM      bool
	BlocksAutoSalesAction      bool
	BlocksExternalCRMProvider  bool
	DeferredToSalesFlow        bool
	DeferredReason             string
}

type FlowInput struct {
	Phase                           string
	Target                          string
	InternalCRMStageReady           bool
	ProductionCRMEnabled            bool
	RealCustomerCRMOpen             bool
	AutoSalesActionEnabled          bool
	ExternalCRMProviderEnabled      bool
	RequiredTransitionKeys          []string
	RequiredStages                  []Stage
	Transitions                     []StageTransition
	RequireEvidence                 bool
	RequireCounterBasedAudit        bool
	RequireNoRequiredFail           bool
	RequireNoOptionalWarn           bool
	RequireTenantID                 bool
	RequireLeadID                   bool
	RequireStageReason              bool
	RequireOwnerAssignment          bool
	RequireAuditTrail               bool
	RequireConsentCheck             bool
	RequireKVKKNotice               bool
	RequireNextAction               bool
	RequireSLA                      bool
	RequireRollbackPath             bool
	RequireDuplicateGuard           bool
	RequireManualReview             bool
	RequireProductionCRMBlock       bool
	RequireRealCustomerCRMBlock     bool
	RequireAutoSalesActionBlock     bool
	RequireExternalCRMProviderBlock bool
	AllowSalesFlowDeferred          bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type FlowReport struct {
	Status                     string
	InternalCRMStageReady      bool
	ProductionCRMEnabled       bool
	RealCustomerCRMOpen        bool
	AutoSalesActionEnabled     bool
	ExternalCRMProviderEnabled bool
	RequiredFailCount          int
	OptionalWarnCount          int
	PassCount                  int
	Findings                   []Finding
}

func Evaluate(input FlowInput) (FlowReport, error) {
	report := FlowReport{
		Status:                     "PASS",
		InternalCRMStageReady:      false,
		ProductionCRMEnabled:       false,
		RealCustomerCRMOpen:        false,
		AutoSalesActionEnabled:     false,
		ExternalCRMProviderEnabled: false,
		Findings:                   []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionCRMEnabled {
		addFail(&report, "PRODUCTION_CRM_BLOCKED", "bu fazda production CRM açılamaz")
	}

	if input.RealCustomerCRMOpen {
		addFail(&report, "REAL_CUSTOMER_CRM_BLOCKED", "bu fazda gerçek müşteri CRM operasyonu açılamaz")
	}

	if input.AutoSalesActionEnabled {
		addFail(&report, "AUTO_SALES_ACTION_BLOCKED", "bu fazda otomatik satış aksiyonu açılamaz")
	}

	if input.ExternalCRMProviderEnabled {
		addFail(&report, "EXTERNAL_CRM_PROVIDER_BLOCKED", "bu fazda external CRM provider açılamaz")
	}

	transitionByKey := map[string]StageTransition{}
	stageCoverage := map[Stage]bool{}

	for _, transition := range input.Transitions {
		key := strings.TrimSpace(transition.Key)
		if key == "" {
			addFail(&report, "CRM_TRANSITION_KEY_MISSING", "crm transition key boş olamaz")
			continue
		}

		if _, exists := transitionByKey[key]; exists {
			addFail(&report, "CRM_TRANSITION_DUPLICATE", fmt.Sprintf("crm transition duplicate: %s", key))
			continue
		}

		transitionByKey[key] = transition
		stageCoverage[transition.From] = true
		stageCoverage[transition.To] = true

		if transition.Required && transition.Status != StatusReady {
			if transition.DeferredToSalesFlow && input.AllowSalesFlowDeferred {
				report.PassCount++
			} else {
				addFail(&report, "REQUIRED_TRANSITION_NOT_READY", fmt.Sprintf("required crm transition READY değil: %s", key))
			}
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireEvidence && transition.Required && !transition.HasEvidence {
			addFail(&report, "EVIDENCE_REQUIRED", fmt.Sprintf("evidence eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireCounterBasedAudit && transition.Required && !transition.HasCounterBasedAudit {
			addFail(&report, "COUNTER_BASED_AUDIT_REQUIRED", fmt.Sprintf("counter based audit eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireNoRequiredFail && transition.Required && transition.RequiredFailCount != 0 {
			addFail(&report, "REQUIRED_FAIL_MUST_BE_ZERO", fmt.Sprintf("required fail sıfır değil: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireNoOptionalWarn && transition.Required && transition.OptionalWarnCount != 0 {
			addFail(&report, "OPTIONAL_WARN_MUST_BE_ZERO", fmt.Sprintf("optional warn sıfır değil: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireTenantID && transition.Required && !transition.RequiresTenantID {
			addFail(&report, "TENANT_ID_REQUIRED", fmt.Sprintf("tenant_id eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireLeadID && transition.Required && !transition.RequiresLeadID {
			addFail(&report, "LEAD_ID_REQUIRED", fmt.Sprintf("lead_id eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireStageReason && transition.Required && !transition.RequiresStageReason {
			addFail(&report, "STAGE_REASON_REQUIRED", fmt.Sprintf("stage reason eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireOwnerAssignment && transition.Required && !transition.RequiresOwnerAssignment {
			addFail(&report, "OWNER_ASSIGNMENT_REQUIRED", fmt.Sprintf("owner assignment eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireAuditTrail && transition.Required && !transition.RequiresAuditTrail {
			addFail(&report, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireConsentCheck && transition.Required && !transition.RequiresConsentCheck {
			addFail(&report, "CONSENT_CHECK_REQUIRED", fmt.Sprintf("consent check eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireKVKKNotice && transition.Required && !transition.RequiresKVKKNotice {
			addFail(&report, "KVKK_NOTICE_REQUIRED", fmt.Sprintf("KVKK notice eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireNextAction && transition.Required && !transition.RequiresNextAction {
			addFail(&report, "NEXT_ACTION_REQUIRED", fmt.Sprintf("next action eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireSLA && transition.Required && !transition.RequiresSLA {
			addFail(&report, "SLA_REQUIRED", fmt.Sprintf("SLA eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireRollbackPath && transition.Required && !transition.RequiresRollbackPath {
			addFail(&report, "ROLLBACK_PATH_REQUIRED", fmt.Sprintf("rollback path eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireDuplicateGuard && transition.Required && !transition.RequiresDuplicateGuard {
			addFail(&report, "DUPLICATE_GUARD_REQUIRED", fmt.Sprintf("duplicate guard eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireManualReview && transition.Required && !transition.RequiresManualReview {
			addFail(&report, "MANUAL_REVIEW_REQUIRED", fmt.Sprintf("manual review eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireProductionCRMBlock && transition.Required && !transition.BlocksProductionCRM {
			addFail(&report, "PRODUCTION_CRM_BLOCK_REQUIRED", fmt.Sprintf("production CRM block eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireRealCustomerCRMBlock && transition.Required && !transition.BlocksRealCustomerCRM {
			addFail(&report, "REAL_CUSTOMER_CRM_BLOCK_REQUIRED", fmt.Sprintf("real customer CRM block eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireAutoSalesActionBlock && transition.Required && !transition.BlocksAutoSalesAction {
			addFail(&report, "AUTO_SALES_ACTION_BLOCK_REQUIRED", fmt.Sprintf("auto sales action block eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if input.RequireExternalCRMProviderBlock && transition.Required && !transition.BlocksExternalCRMProvider {
			addFail(&report, "EXTERNAL_CRM_PROVIDER_BLOCK_REQUIRED", fmt.Sprintf("external CRM provider block eksik: %s", key))
		} else if transition.Required {
			report.PassCount++
		}

		if transition.ProductionCRMEnabled {
			addFail(&report, "TRANSITION_PRODUCTION_CRM_ENABLED_BLOCKED", fmt.Sprintf("production CRM enabled açık olamaz: %s", key))
		}

		if transition.RealCustomerCRMOpen {
			addFail(&report, "TRANSITION_REAL_CUSTOMER_CRM_OPEN_BLOCKED", fmt.Sprintf("real customer CRM open açık olamaz: %s", key))
		}

		if transition.AutoSalesActionEnabled {
			addFail(&report, "TRANSITION_AUTO_SALES_ACTION_ENABLED_BLOCKED", fmt.Sprintf("auto sales action açık olamaz: %s", key))
		}

		if transition.ExternalCRMProviderEnabled {
			addFail(&report, "TRANSITION_EXTERNAL_CRM_PROVIDER_ENABLED_BLOCKED", fmt.Sprintf("external CRM provider açık olamaz: %s", key))
		}

		if transition.DeferredToSalesFlow && strings.TrimSpace(transition.DeferredReason) == "" {
			addFail(&report, "DEFERRED_REASON_REQUIRED", fmt.Sprintf("deferred reason eksik: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredTransitionKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}

		transition, exists := transitionByKey[requiredKey]
		if !exists {
			addFail(&report, "REQUIRED_TRANSITION_NOT_REGISTERED", fmt.Sprintf("required listesinde olup flow içinde yok: %s", requiredKey))
			continue
		}

		if !transition.Required {
			addFail(&report, "REQUIRED_TRANSITION_FLAG_FALSE", fmt.Sprintf("required listesinde ama transition required=false: %s", requiredKey))
			continue
		}

		report.PassCount++
	}

	for _, stage := range input.RequiredStages {
		if !stageCoverage[stage] {
			addFail(&report, "REQUIRED_STAGE_MISSING", fmt.Sprintf("CRM stage eksik: %s", stage))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		return report, nil
	}

	report.Status = "PASS"
	report.InternalCRMStageReady = input.InternalCRMStageReady
	report.ProductionCRMEnabled = false
	report.RealCustomerCRMOpen = false
	report.AutoSalesActionEnabled = false
	report.ExternalCRMProviderEnabled = false
	return report, nil
}

func RequiredTransitionKeys(input FlowInput) []string {
	keys := make([]string, 0, len(input.RequiredTransitionKeys))
	keys = append(keys, input.RequiredTransitionKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(report FlowReport) error {
	if report.RequiredFailCount > 0 || report.Status != "PASS" {
		return errors.New("crm stage management flow failed")
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
