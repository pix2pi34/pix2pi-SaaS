package tenantshutdown

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

type ShutdownEvent string

const (
	EventShutdownRequestReceived   ShutdownEvent = "SHUTDOWN_REQUEST_RECEIVED"
	EventBillingStatusValidated    ShutdownEvent = "BILLING_STATUS_VALIDATED"
	EventUnpaidInvoiceChecked      ShutdownEvent = "UNPAID_INVOICE_CHECKED"
	EventDataExportOffered         ShutdownEvent = "DATA_EXPORT_OFFERED"
	EventLegalHoldChecked          ShutdownEvent = "LEGAL_HOLD_CHECKED"
	EventOwnerApprovalQueued       ShutdownEvent = "OWNER_APPROVAL_QUEUED"
	EventTenantAccessFreezePlanned ShutdownEvent = "TENANT_ACCESS_FREEZE_PLANNED"
	EventBillingStopPlanned        ShutdownEvent = "BILLING_STOP_PLANNED"
	EventFinalShutdownDeferred     ShutdownEvent = "FINAL_SHUTDOWN_DEFERRED"
)

type ShutdownStep struct {
	Key                          string
	Event                        ShutdownEvent
	Title                        string
	Owner                        string
	Status                       StepStatus
	Required                     bool
	InternalReady                bool
	HasEvidence                  bool
	HasCounterBasedAudit         bool
	RequiredFailCount            int
	OptionalWarnCount            int
	ProductionShutdownEnabled    bool
	RealTenantClosureEnabled     bool
	DataDeletionEnabled          bool
	AutoAccessCutoffEnabled      bool
	RequiresTenantID             bool
	RequiresShutdownRequestID    bool
	RequiresBillingStatusCheck   bool
	RequiresUnpaidInvoiceCheck   bool
	RequiresDataExportOffer      bool
	RequiresLegalHoldCheck       bool
	RequiresOwnerApproval        bool
	RequiresSupportHandoff       bool
	RequiresCustomerTemplate     bool
	RequiresAuditTrail           bool
	RequiresRollbackWindow       bool
	RequiresBackupSnapshot       bool
	RequiresEntitlementFreeze    bool
	RequiresBillingStopPlan      bool
	BlocksProductionShutdown     bool
	BlocksRealTenantClosure      bool
	BlocksDataDeletion           bool
	BlocksAutoAccessCutoff       bool
	DeferredToDataExportFlow     bool
	DeferredToProductionApproval bool
	DeferredReason               string
}

type FlowInput struct {
	Phase                           string
	Target                          string
	InternalTenantShutdownReady     bool
	ProductionShutdownEnabled       bool
	RealTenantClosureEnabled        bool
	DataDeletionEnabled             bool
	AutoAccessCutoffEnabled         bool
	RequiredStepKeys                []string
	RequiredEvents                  []ShutdownEvent
	Steps                           []ShutdownStep
	RequireInternalReady            bool
	RequireEvidence                 bool
	RequireCounterBasedAudit        bool
	RequireNoRequiredFail           bool
	RequireNoOptionalWarn           bool
	RequireTenantID                 bool
	RequireShutdownRequestID        bool
	RequireBillingStatusCheck       bool
	RequireUnpaidInvoiceCheck       bool
	RequireDataExportOffer          bool
	RequireLegalHoldCheck           bool
	RequireOwnerApproval            bool
	RequireSupportHandoff           bool
	RequireCustomerTemplate         bool
	RequireAuditTrail               bool
	RequireRollbackWindow           bool
	RequireBackupSnapshot           bool
	RequireEntitlementFreeze        bool
	RequireBillingStopPlan          bool
	RequireProductionShutdownBlock  bool
	RequireRealTenantClosureBlock   bool
	RequireDataDeletionBlock        bool
	RequireAutoAccessCutoffBlock    bool
	AllowDataExportFlowDeferred     bool
	AllowProductionApprovalDeferred bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type FlowReport struct {
	Status                      string
	InternalTenantShutdownReady bool
	ProductionShutdownEnabled   bool
	RealTenantClosureEnabled    bool
	DataDeletionEnabled         bool
	AutoAccessCutoffEnabled     bool
	RequiredFailCount           int
	OptionalWarnCount           int
	PassCount                   int
	Findings                    []Finding
}

func Evaluate(input FlowInput) (FlowReport, error) {
	report := FlowReport{
		Status:                      "PASS",
		InternalTenantShutdownReady: false,
		ProductionShutdownEnabled:   false,
		RealTenantClosureEnabled:    false,
		DataDeletionEnabled:         false,
		AutoAccessCutoffEnabled:     false,
		Findings:                    []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionShutdownEnabled {
		addFail(&report, "PRODUCTION_SHUTDOWN_BLOCKED", "bu fazda production tenant shutdown açılamaz")
	}

	if input.RealTenantClosureEnabled {
		addFail(&report, "REAL_TENANT_CLOSURE_BLOCKED", "bu fazda gerçek tenant kapatma açılamaz")
	}

	if input.DataDeletionEnabled {
		addFail(&report, "DATA_DELETION_BLOCKED", "bu fazda veri silme açılamaz")
	}

	if input.AutoAccessCutoffEnabled {
		addFail(&report, "AUTO_ACCESS_CUTOFF_BLOCKED", "bu fazda otomatik erişim kesme açılamaz")
	}

	stepByKey := map[string]ShutdownStep{}
	eventCoverage := map[ShutdownEvent]bool{}

	for _, step := range input.Steps {
		key := strings.TrimSpace(step.Key)
		if key == "" {
			addFail(&report, "SHUTDOWN_STEP_KEY_MISSING", "tenant shutdown step key boş olamaz")
			continue
		}

		if _, exists := stepByKey[key]; exists {
			addFail(&report, "SHUTDOWN_STEP_DUPLICATE", fmt.Sprintf("tenant shutdown step duplicate: %s", key))
			continue
		}

		stepByKey[key] = step
		eventCoverage[step.Event] = true

		if step.Required && step.Status != StatusReady {
			if isAllowedDeferred(step, input) {
				report.PassCount++
			} else {
				addFail(&report, "REQUIRED_STEP_NOT_READY", fmt.Sprintf("required tenant shutdown step READY değil: %s", key))
			}
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireInternalReady && step.Required && !step.InternalReady {
			if isAllowedDeferred(step, input) {
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

		if input.RequireShutdownRequestID && step.Required && !step.RequiresShutdownRequestID {
			addFail(&report, "SHUTDOWN_REQUEST_ID_REQUIRED", fmt.Sprintf("shutdown_request_id requirement eksik: %s", key))
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

		if input.RequireDataExportOffer && step.Required && !step.RequiresDataExportOffer {
			addFail(&report, "DATA_EXPORT_OFFER_REQUIRED", fmt.Sprintf("data export offer eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireLegalHoldCheck && step.Required && !step.RequiresLegalHoldCheck {
			addFail(&report, "LEGAL_HOLD_CHECK_REQUIRED", fmt.Sprintf("legal hold check eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireOwnerApproval && step.Required && !step.RequiresOwnerApproval {
			addFail(&report, "OWNER_APPROVAL_REQUIRED", fmt.Sprintf("owner approval eksik: %s", key))
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

		if input.RequireAuditTrail && step.Required && !step.RequiresAuditTrail {
			addFail(&report, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireRollbackWindow && step.Required && !step.RequiresRollbackWindow {
			addFail(&report, "ROLLBACK_WINDOW_REQUIRED", fmt.Sprintf("rollback window eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireBackupSnapshot && step.Required && !step.RequiresBackupSnapshot {
			addFail(&report, "BACKUP_SNAPSHOT_REQUIRED", fmt.Sprintf("backup snapshot eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireEntitlementFreeze && step.Required && !step.RequiresEntitlementFreeze {
			addFail(&report, "ENTITLEMENT_FREEZE_REQUIRED", fmt.Sprintf("entitlement freeze eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireBillingStopPlan && step.Required && !step.RequiresBillingStopPlan {
			addFail(&report, "BILLING_STOP_PLAN_REQUIRED", fmt.Sprintf("billing stop plan eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireProductionShutdownBlock && step.Required && !step.BlocksProductionShutdown {
			addFail(&report, "PRODUCTION_SHUTDOWN_BLOCK_REQUIRED", fmt.Sprintf("production shutdown block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireRealTenantClosureBlock && step.Required && !step.BlocksRealTenantClosure {
			addFail(&report, "REAL_TENANT_CLOSURE_BLOCK_REQUIRED", fmt.Sprintf("real tenant closure block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireDataDeletionBlock && step.Required && !step.BlocksDataDeletion {
			addFail(&report, "DATA_DELETION_BLOCK_REQUIRED", fmt.Sprintf("data deletion block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAutoAccessCutoffBlock && step.Required && !step.BlocksAutoAccessCutoff {
			addFail(&report, "AUTO_ACCESS_CUTOFF_BLOCK_REQUIRED", fmt.Sprintf("auto access cutoff block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if step.ProductionShutdownEnabled {
			addFail(&report, "STEP_PRODUCTION_SHUTDOWN_ENABLED_BLOCKED", fmt.Sprintf("production shutdown enabled açık olamaz: %s", key))
		}

		if step.RealTenantClosureEnabled {
			addFail(&report, "STEP_REAL_TENANT_CLOSURE_ENABLED_BLOCKED", fmt.Sprintf("real tenant closure enabled açık olamaz: %s", key))
		}

		if step.DataDeletionEnabled {
			addFail(&report, "STEP_DATA_DELETION_ENABLED_BLOCKED", fmt.Sprintf("data deletion enabled açık olamaz: %s", key))
		}

		if step.AutoAccessCutoffEnabled {
			addFail(&report, "STEP_AUTO_ACCESS_CUTOFF_ENABLED_BLOCKED", fmt.Sprintf("auto access cutoff enabled açık olamaz: %s", key))
		}

		if (step.DeferredToDataExportFlow || step.DeferredToProductionApproval) && strings.TrimSpace(step.DeferredReason) == "" {
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
			addFail(&report, "REQUIRED_EVENT_MISSING", fmt.Sprintf("tenant shutdown event eksik: %s", event))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalTenantShutdownReady = false
		report.ProductionShutdownEnabled = false
		report.RealTenantClosureEnabled = false
		report.DataDeletionEnabled = false
		report.AutoAccessCutoffEnabled = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalTenantShutdownReady = input.InternalTenantShutdownReady
	report.ProductionShutdownEnabled = false
	report.RealTenantClosureEnabled = false
	report.DataDeletionEnabled = false
	report.AutoAccessCutoffEnabled = false
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
		return errors.New("tenant shutdown flow failed")
	}
	return nil
}

func isAllowedDeferred(step ShutdownStep, input FlowInput) bool {
	if step.DeferredToDataExportFlow && input.AllowDataExportFlowDeferred {
		return true
	}
	if step.DeferredToProductionApproval && input.AllowProductionApprovalDeferred {
		return true
	}
	return false
}

func addFail(report *FlowReport, code, message string) {
	report.RequiredFailCount++
	report.Findings = append(report.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
