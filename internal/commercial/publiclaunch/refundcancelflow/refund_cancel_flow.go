package refundcancelflow

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

type RefundCancelEvent string

const (
	EventRefundRequestReceived      RefundCancelEvent = "REFUND_REQUEST_RECEIVED"
	EventRefundEligibilityValidated RefundCancelEvent = "REFUND_ELIGIBILITY_VALIDATED"
	EventRefundAmountCalculated     RefundCancelEvent = "REFUND_AMOUNT_CALCULATED"
	EventCancelRequestValidated     RefundCancelEvent = "CANCEL_REQUEST_VALIDATED"
	EventCreditNoteDeferred         RefundCancelEvent = "CREDIT_NOTE_DEFERRED"
	EventPaymentRefundDeferred      RefundCancelEvent = "PAYMENT_REFUND_DEFERRED"
	EventTenantEntitlementAdjusted  RefundCancelEvent = "TENANT_ENTITLEMENT_ADJUSTED"
	EventManualApprovalQueued       RefundCancelEvent = "MANUAL_APPROVAL_QUEUED"
	EventAccountingReversalReady    RefundCancelEvent = "ACCOUNTING_REVERSAL_READY"
	EventCustomerNotifyBlocked      RefundCancelEvent = "CUSTOMER_NOTIFICATION_BLOCKED"
)

type RefundCancelStep struct {
	Key                             string
	Event                           RefundCancelEvent
	Title                           string
	Owner                           string
	Status                          StepStatus
	Required                        bool
	InternalReady                   bool
	HasEvidence                     bool
	HasCounterBasedAudit            bool
	RequiredFailCount               int
	OptionalWarnCount               int
	ProductionRefundEnabled         bool
	RealMoneyRefundEnabled          bool
	AutoCancelEnabled               bool
	AutoCustomerNotificationEnabled bool
	RequiresTenantID                bool
	RequiresInvoiceID               bool
	RequiresPaymentAttemptID        bool
	RequiresRefundRequestID         bool
	RequiresIdempotencyKey          bool
	RequiresAuditTrail              bool
	RequiresEligibilityPolicy       bool
	RequiresAmountCalculation       bool
	RequiresManualApproval          bool
	RequiresBillingOwner            bool
	RequiresAccountingReversal      bool
	RequiresCreditNoteHandoff       bool
	RequiresProviderRefundHandoff   bool
	RequiresCustomerTemplate        bool
	BlocksProductionRefund          bool
	BlocksRealMoneyMovement         bool
	BlocksAutoCancel                bool
	BlocksAutoCustomerNotification  bool
	DeferredToProviderLive          bool
	DeferredToEDocumentModule       bool
	DeferredReason                  string
}

type FlowInput struct {
	Phase                                string
	Target                               string
	InternalRefundCancelFlowReady        bool
	ProductionRefundEnabled              bool
	RealMoneyRefundEnabled               bool
	AutoCancelEnabled                    bool
	AutoCustomerNotificationEnabled      bool
	RequiredStepKeys                     []string
	RequiredEvents                       []RefundCancelEvent
	Steps                                []RefundCancelStep
	RequireInternalReady                 bool
	RequireEvidence                      bool
	RequireCounterBasedAudit             bool
	RequireNoRequiredFail                bool
	RequireNoOptionalWarn                bool
	RequireTenantID                      bool
	RequireInvoiceID                     bool
	RequirePaymentAttemptID              bool
	RequireRefundRequestID               bool
	RequireIdempotencyKey                bool
	RequireAuditTrail                    bool
	RequireEligibilityPolicy             bool
	RequireAmountCalculation             bool
	RequireManualApproval                bool
	RequireBillingOwner                  bool
	RequireAccountingReversal            bool
	RequireCreditNoteHandoff             bool
	RequireProviderRefundHandoff         bool
	RequireCustomerTemplate              bool
	RequireProductionRefundBlock         bool
	RequireRealMoneyMovementBlock        bool
	RequireAutoCancelBlock               bool
	RequireAutoCustomerNotificationBlock bool
	AllowProviderLiveDeferred            bool
	AllowEDocumentDeferred               bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type FlowReport struct {
	Status                          string
	InternalRefundCancelFlowReady   bool
	ProductionRefundEnabled         bool
	RealMoneyRefundEnabled          bool
	AutoCancelEnabled               bool
	AutoCustomerNotificationEnabled bool
	RequiredFailCount               int
	OptionalWarnCount               int
	PassCount                       int
	Findings                        []Finding
}

func Evaluate(input FlowInput) (FlowReport, error) {
	report := FlowReport{
		Status:                          "PASS",
		InternalRefundCancelFlowReady:   false,
		ProductionRefundEnabled:         false,
		RealMoneyRefundEnabled:          false,
		AutoCancelEnabled:               false,
		AutoCustomerNotificationEnabled: false,
		Findings:                        []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionRefundEnabled {
		addFail(&report, "PRODUCTION_REFUND_BLOCKED", "bu fazda production refund enabled açılamaz")
	}

	if input.RealMoneyRefundEnabled {
		addFail(&report, "REAL_MONEY_REFUND_BLOCKED", "bu fazda gerçek para iadesi açılamaz")
	}

	if input.AutoCancelEnabled {
		addFail(&report, "AUTO_CANCEL_BLOCKED", "bu fazda otomatik iptal açılamaz")
	}

	if input.AutoCustomerNotificationEnabled {
		addFail(&report, "AUTO_CUSTOMER_NOTIFICATION_BLOCKED", "bu fazda otomatik müşteri bildirimi açılamaz")
	}

	stepByKey := map[string]RefundCancelStep{}
	eventCoverage := map[RefundCancelEvent]bool{}

	for _, step := range input.Steps {
		key := strings.TrimSpace(step.Key)
		if key == "" {
			addFail(&report, "REFUND_CANCEL_STEP_KEY_MISSING", "refund/cancel step key boş olamaz")
			continue
		}

		if _, exists := stepByKey[key]; exists {
			addFail(&report, "REFUND_CANCEL_STEP_DUPLICATE", fmt.Sprintf("refund/cancel step duplicate: %s", key))
			continue
		}

		stepByKey[key] = step
		eventCoverage[step.Event] = true

		if step.Required && step.Status != StatusReady {
			if isAllowedDeferred(step, input) {
				report.PassCount++
			} else {
				addFail(&report, "REQUIRED_STEP_NOT_READY", fmt.Sprintf("required refund/cancel step READY değil: %s", key))
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

		if input.RequireInvoiceID && step.Required && !step.RequiresInvoiceID {
			addFail(&report, "INVOICE_ID_REQUIRED", fmt.Sprintf("invoice_id requirement eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequirePaymentAttemptID && step.Required && !step.RequiresPaymentAttemptID {
			addFail(&report, "PAYMENT_ATTEMPT_ID_REQUIRED", fmt.Sprintf("payment_attempt_id requirement eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireRefundRequestID && step.Required && !step.RequiresRefundRequestID {
			addFail(&report, "REFUND_REQUEST_ID_REQUIRED", fmt.Sprintf("refund_request_id requirement eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireIdempotencyKey && step.Required && !step.RequiresIdempotencyKey {
			addFail(&report, "IDEMPOTENCY_KEY_REQUIRED", fmt.Sprintf("idempotency key eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAuditTrail && step.Required && !step.RequiresAuditTrail {
			addFail(&report, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireEligibilityPolicy && step.Required && !step.RequiresEligibilityPolicy {
			addFail(&report, "ELIGIBILITY_POLICY_REQUIRED", fmt.Sprintf("eligibility policy eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAmountCalculation && step.Required && !step.RequiresAmountCalculation {
			addFail(&report, "AMOUNT_CALCULATION_REQUIRED", fmt.Sprintf("amount calculation eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireManualApproval && step.Required && !step.RequiresManualApproval {
			addFail(&report, "MANUAL_APPROVAL_REQUIRED", fmt.Sprintf("manual approval eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireBillingOwner && step.Required && !step.RequiresBillingOwner {
			addFail(&report, "BILLING_OWNER_REQUIRED", fmt.Sprintf("billing owner eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAccountingReversal && step.Required && !step.RequiresAccountingReversal {
			addFail(&report, "ACCOUNTING_REVERSAL_REQUIRED", fmt.Sprintf("accounting reversal eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireCreditNoteHandoff && step.Required && !step.RequiresCreditNoteHandoff {
			addFail(&report, "CREDIT_NOTE_HANDOFF_REQUIRED", fmt.Sprintf("credit note handoff eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireProviderRefundHandoff && step.Required && !step.RequiresProviderRefundHandoff {
			addFail(&report, "PROVIDER_REFUND_HANDOFF_REQUIRED", fmt.Sprintf("provider refund handoff eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireCustomerTemplate && step.Required && !step.RequiresCustomerTemplate {
			addFail(&report, "CUSTOMER_TEMPLATE_REQUIRED", fmt.Sprintf("customer template eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireProductionRefundBlock && step.Required && !step.BlocksProductionRefund {
			addFail(&report, "PRODUCTION_REFUND_BLOCK_REQUIRED", fmt.Sprintf("production refund block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireRealMoneyMovementBlock && step.Required && !step.BlocksRealMoneyMovement {
			addFail(&report, "REAL_MONEY_MOVEMENT_BLOCK_REQUIRED", fmt.Sprintf("real money movement block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAutoCancelBlock && step.Required && !step.BlocksAutoCancel {
			addFail(&report, "AUTO_CANCEL_BLOCK_REQUIRED", fmt.Sprintf("auto cancel block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAutoCustomerNotificationBlock && step.Required && !step.BlocksAutoCustomerNotification {
			addFail(&report, "AUTO_CUSTOMER_NOTIFICATION_BLOCK_REQUIRED", fmt.Sprintf("auto customer notification block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if step.ProductionRefundEnabled {
			addFail(&report, "STEP_PRODUCTION_REFUND_ENABLED_BLOCKED", fmt.Sprintf("production refund enabled açık olamaz: %s", key))
		}

		if step.RealMoneyRefundEnabled {
			addFail(&report, "STEP_REAL_MONEY_REFUND_ENABLED_BLOCKED", fmt.Sprintf("real money refund enabled açık olamaz: %s", key))
		}

		if step.AutoCancelEnabled {
			addFail(&report, "STEP_AUTO_CANCEL_ENABLED_BLOCKED", fmt.Sprintf("auto cancel enabled açık olamaz: %s", key))
		}

		if step.AutoCustomerNotificationEnabled {
			addFail(&report, "STEP_AUTO_CUSTOMER_NOTIFICATION_ENABLED_BLOCKED", fmt.Sprintf("auto customer notification enabled açık olamaz: %s", key))
		}

		if (step.DeferredToProviderLive || step.DeferredToEDocumentModule) && strings.TrimSpace(step.DeferredReason) == "" {
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
			addFail(&report, "REQUIRED_EVENT_MISSING", fmt.Sprintf("refund/cancel event eksik: %s", event))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalRefundCancelFlowReady = false
		report.ProductionRefundEnabled = false
		report.RealMoneyRefundEnabled = false
		report.AutoCancelEnabled = false
		report.AutoCustomerNotificationEnabled = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalRefundCancelFlowReady = input.InternalRefundCancelFlowReady
	report.ProductionRefundEnabled = false
	report.RealMoneyRefundEnabled = false
	report.AutoCancelEnabled = false
	report.AutoCustomerNotificationEnabled = false
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
		return errors.New("refund cancel commercial flow failed")
	}
	return nil
}

func isAllowedDeferred(step RefundCancelStep, input FlowInput) bool {
	if step.DeferredToProviderLive && input.AllowProviderLiveDeferred {
		return true
	}
	if step.DeferredToEDocumentModule && input.AllowEDocumentDeferred {
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
