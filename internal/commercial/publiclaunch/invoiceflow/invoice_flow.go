package invoiceflow

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

type InvoiceEvent string

const (
	EventInvoiceDraftCreated   InvoiceEvent = "INVOICE_DRAFT_CREATED"
	EventInvoiceCalculated     InvoiceEvent = "INVOICE_CALCULATED"
	EventInvoiceFinalized      InvoiceEvent = "INVOICE_FINALIZED"
	EventInvoiceDueScheduled   InvoiceEvent = "INVOICE_DUE_SCHEDULED"
	EventInvoiceDeliveryReady  InvoiceEvent = "INVOICE_DELIVERY_READY"
	EventAccountingExportReady InvoiceEvent = "ACCOUNTING_EXPORT_READY"
	EventEDocumentDeferred     InvoiceEvent = "E_DOCUMENT_DEFERRED"
)

type InvoiceStep struct {
	Key                        string
	Event                      InvoiceEvent
	Title                      string
	Owner                      string
	Status                     StepStatus
	Required                   bool
	InternalReady              bool
	HasEvidence                bool
	HasCounterBasedAudit       bool
	RequiredFailCount          int
	OptionalWarnCount          int
	ProductionInvoiceEnabled   bool
	RealCustomerInvoiceEnabled bool
	AutoInvoiceDeliveryEnabled bool
	RequiresTenantID           bool
	RequiresInvoiceID          bool
	RequiresBillingProfile     bool
	RequiresPlanSnapshot       bool
	RequiresLineItems          bool
	RequiresTaxCalculation     bool
	RequiresDueDate            bool
	RequiresCurrency           bool
	RequiresAuditTrail         bool
	RequiresIdempotencyKey     bool
	RequiresAccountingExport   bool
	RequiresEDocumentHandoff   bool
	BlocksProductionInvoice    bool
	BlocksRealCustomerDelivery bool
	DeferredToEDocumentModule  bool
	DeferredReason             string
}

type FlowInput struct {
	Phase                            string
	Target                           string
	InternalInvoiceFlowReady         bool
	ProductionInvoiceEnabled         bool
	RealCustomerInvoiceEnabled       bool
	AutoInvoiceDeliveryEnabled       bool
	RequiredStepKeys                 []string
	RequiredEvents                   []InvoiceEvent
	Steps                            []InvoiceStep
	RequireInternalReady             bool
	RequireEvidence                  bool
	RequireCounterBasedAudit         bool
	RequireNoRequiredFail            bool
	RequireNoOptionalWarn            bool
	RequireTenantID                  bool
	RequireInvoiceID                 bool
	RequireBillingProfile            bool
	RequirePlanSnapshot              bool
	RequireLineItems                 bool
	RequireTaxCalculation            bool
	RequireDueDate                   bool
	RequireCurrency                  bool
	RequireAuditTrail                bool
	RequireIdempotencyKey            bool
	RequireAccountingExport          bool
	RequireEDocumentHandoff          bool
	RequireProductionInvoiceBlock    bool
	RequireRealCustomerDeliveryBlock bool
	AllowEDocumentDeferred           bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type FlowReport struct {
	Status                     string
	InternalInvoiceFlowReady   bool
	ProductionInvoiceEnabled   bool
	RealCustomerInvoiceEnabled bool
	AutoInvoiceDeliveryEnabled bool
	RequiredFailCount          int
	OptionalWarnCount          int
	PassCount                  int
	Findings                   []Finding
}

func Evaluate(input FlowInput) (FlowReport, error) {
	report := FlowReport{
		Status:                     "PASS",
		InternalInvoiceFlowReady:   false,
		ProductionInvoiceEnabled:   false,
		RealCustomerInvoiceEnabled: false,
		AutoInvoiceDeliveryEnabled: false,
		Findings:                   []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionInvoiceEnabled {
		addFail(&report, "PRODUCTION_INVOICE_BLOCKED", "bu fazda production invoice enabled açılamaz")
	}

	if input.RealCustomerInvoiceEnabled {
		addFail(&report, "REAL_CUSTOMER_INVOICE_BLOCKED", "bu fazda gerçek müşteri faturası açılamaz")
	}

	if input.AutoInvoiceDeliveryEnabled {
		addFail(&report, "AUTO_INVOICE_DELIVERY_BLOCKED", "bu fazda otomatik fatura gönderimi açılamaz")
	}

	stepByKey := map[string]InvoiceStep{}
	eventCoverage := map[InvoiceEvent]bool{}

	for _, step := range input.Steps {
		key := strings.TrimSpace(step.Key)
		if key == "" {
			addFail(&report, "INVOICE_STEP_KEY_MISSING", "invoice step key boş olamaz")
			continue
		}

		if _, exists := stepByKey[key]; exists {
			addFail(&report, "INVOICE_STEP_DUPLICATE", fmt.Sprintf("invoice step duplicate: %s", key))
			continue
		}

		stepByKey[key] = step
		eventCoverage[step.Event] = true

		if step.Required && step.Status != StatusReady {
			if step.DeferredToEDocumentModule && input.AllowEDocumentDeferred {
				report.PassCount++
			} else {
				addFail(&report, "REQUIRED_STEP_NOT_READY", fmt.Sprintf("required invoice step READY değil: %s", key))
			}
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireInternalReady && step.Required && !step.InternalReady {
			if step.DeferredToEDocumentModule && input.AllowEDocumentDeferred {
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

		if input.RequireBillingProfile && step.Required && !step.RequiresBillingProfile {
			addFail(&report, "BILLING_PROFILE_REQUIRED", fmt.Sprintf("billing profile eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequirePlanSnapshot && step.Required && !step.RequiresPlanSnapshot {
			addFail(&report, "PLAN_SNAPSHOT_REQUIRED", fmt.Sprintf("plan snapshot eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireLineItems && step.Required && !step.RequiresLineItems {
			addFail(&report, "LINE_ITEMS_REQUIRED", fmt.Sprintf("line items eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireTaxCalculation && step.Required && !step.RequiresTaxCalculation {
			addFail(&report, "TAX_CALCULATION_REQUIRED", fmt.Sprintf("tax calculation eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireDueDate && step.Required && !step.RequiresDueDate {
			addFail(&report, "DUE_DATE_REQUIRED", fmt.Sprintf("due date eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireCurrency && step.Required && !step.RequiresCurrency {
			addFail(&report, "CURRENCY_REQUIRED", fmt.Sprintf("currency eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAuditTrail && step.Required && !step.RequiresAuditTrail {
			addFail(&report, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireIdempotencyKey && step.Required && !step.RequiresIdempotencyKey {
			addFail(&report, "IDEMPOTENCY_KEY_REQUIRED", fmt.Sprintf("idempotency key eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAccountingExport && step.Required && !step.RequiresAccountingExport {
			addFail(&report, "ACCOUNTING_EXPORT_REQUIRED", fmt.Sprintf("accounting export eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireEDocumentHandoff && step.Required && !step.RequiresEDocumentHandoff {
			addFail(&report, "E_DOCUMENT_HANDOFF_REQUIRED", fmt.Sprintf("e-document handoff eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireProductionInvoiceBlock && step.Required && !step.BlocksProductionInvoice {
			addFail(&report, "PRODUCTION_INVOICE_BLOCK_REQUIRED", fmt.Sprintf("production invoice block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireRealCustomerDeliveryBlock && step.Required && !step.BlocksRealCustomerDelivery {
			addFail(&report, "REAL_CUSTOMER_DELIVERY_BLOCK_REQUIRED", fmt.Sprintf("real customer delivery block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if step.ProductionInvoiceEnabled {
			addFail(&report, "STEP_PRODUCTION_INVOICE_ENABLED_BLOCKED", fmt.Sprintf("production invoice enabled açık olamaz: %s", key))
		}

		if step.RealCustomerInvoiceEnabled {
			addFail(&report, "STEP_REAL_CUSTOMER_INVOICE_BLOCKED", fmt.Sprintf("real customer invoice enabled açık olamaz: %s", key))
		}

		if step.AutoInvoiceDeliveryEnabled {
			addFail(&report, "STEP_AUTO_INVOICE_DELIVERY_BLOCKED", fmt.Sprintf("auto invoice delivery enabled açık olamaz: %s", key))
		}

		if step.DeferredToEDocumentModule && strings.TrimSpace(step.DeferredReason) == "" {
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
			addFail(&report, "REQUIRED_EVENT_MISSING", fmt.Sprintf("invoice event eksik: %s", event))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalInvoiceFlowReady = false
		report.ProductionInvoiceEnabled = false
		report.RealCustomerInvoiceEnabled = false
		report.AutoInvoiceDeliveryEnabled = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalInvoiceFlowReady = input.InternalInvoiceFlowReady
	report.ProductionInvoiceEnabled = false
	report.RealCustomerInvoiceEnabled = false
	report.AutoInvoiceDeliveryEnabled = false
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
		return errors.New("invoice flow failed")
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
