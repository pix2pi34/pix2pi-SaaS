package collectionflow

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

type CollectionEvent string

const (
	EventInvoiceDue          CollectionEvent = "INVOICE_DUE"
	EventCollectionAttempt   CollectionEvent = "COLLECTION_ATTEMPT"
	EventPaymentFailed       CollectionEvent = "PAYMENT_FAILED"
	EventRetryScheduled      CollectionEvent = "RETRY_SCHEDULED"
	EventGracePeriodStarted  CollectionEvent = "GRACE_PERIOD_STARTED"
	EventManualReviewQueued  CollectionEvent = "MANUAL_REVIEW_QUEUED"
	EventTenantActionBlocked CollectionEvent = "TENANT_ACTION_BLOCKED"
)

type CollectionStep struct {
	Key                         string
	Event                       CollectionEvent
	Title                       string
	Owner                       string
	Status                      StepStatus
	Required                    bool
	InternalReady               bool
	HasEvidence                 bool
	HasCounterBasedAudit        bool
	RequiredFailCount           int
	OptionalWarnCount           int
	ProductionPaymentEnabled    bool
	RealCustomerChargingEnabled bool
	AutoTenantSuspensionEnabled bool
	RequiresTenantID            bool
	RequiresInvoiceID           bool
	RequiresAttemptID           bool
	RequiresIdempotencyKey      bool
	RequiresAuditTrail          bool
	RequiresRetryPolicy         bool
	RequiresDunningTemplate     bool
	RequiresManualReview        bool
	RequiresBillingOwner        bool
	BlocksProductionCharging    bool
	BlocksAutoTenantSuspension  bool
	MaxRetryCount               int
	GracePeriodDays             int
	DeferredToProviderLive      bool
	DeferredReason              string
}

type FlowInput struct {
	Phase                            string
	Target                           string
	InternalCollectionFlowReady      bool
	ProductionPaymentEnabled         bool
	RealCustomerChargingEnabled      bool
	AutoTenantSuspensionEnabled      bool
	RequiredStepKeys                 []string
	RequiredEvents                   []CollectionEvent
	Steps                            []CollectionStep
	RequireInternalReady             bool
	RequireEvidence                  bool
	RequireCounterBasedAudit         bool
	RequireNoRequiredFail            bool
	RequireNoOptionalWarn            bool
	RequireTenantID                  bool
	RequireInvoiceID                 bool
	RequireAttemptID                 bool
	RequireIdempotencyKey            bool
	RequireAuditTrail                bool
	RequireRetryPolicy               bool
	RequireDunningTemplate           bool
	RequireManualReview              bool
	RequireBillingOwner              bool
	RequireProductionChargingBlock   bool
	RequireAutoTenantSuspensionBlock bool
	AllowProviderLiveDeferred        bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type FlowReport struct {
	Status                      string
	InternalCollectionFlowReady bool
	ProductionPaymentEnabled    bool
	RealCustomerChargingEnabled bool
	AutoTenantSuspensionEnabled bool
	RequiredFailCount           int
	OptionalWarnCount           int
	PassCount                   int
	Findings                    []Finding
}

func Evaluate(input FlowInput) (FlowReport, error) {
	report := FlowReport{
		Status:                      "PASS",
		InternalCollectionFlowReady: false,
		ProductionPaymentEnabled:    false,
		RealCustomerChargingEnabled: false,
		AutoTenantSuspensionEnabled: false,
		Findings:                    []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionPaymentEnabled {
		addFail(&report, "PRODUCTION_PAYMENT_BLOCKED", "bu fazda production payment enabled açılamaz")
	}

	if input.RealCustomerChargingEnabled {
		addFail(&report, "REAL_CUSTOMER_CHARGING_BLOCKED", "bu fazda gerçek müşteri tahsilatı açılamaz")
	}

	if input.AutoTenantSuspensionEnabled {
		addFail(&report, "AUTO_TENANT_SUSPENSION_BLOCKED", "bu fazda otomatik tenant askıya alma açılamaz")
	}

	stepByKey := map[string]CollectionStep{}
	eventCoverage := map[CollectionEvent]bool{}

	for _, step := range input.Steps {
		key := strings.TrimSpace(step.Key)
		if key == "" {
			addFail(&report, "COLLECTION_STEP_KEY_MISSING", "collection step key boş olamaz")
			continue
		}

		if _, exists := stepByKey[key]; exists {
			addFail(&report, "COLLECTION_STEP_DUPLICATE", fmt.Sprintf("collection step duplicate: %s", key))
			continue
		}

		stepByKey[key] = step
		eventCoverage[step.Event] = true

		if step.Required && step.Status != StatusReady {
			if step.DeferredToProviderLive && input.AllowProviderLiveDeferred {
				report.PassCount++
			} else {
				addFail(&report, "REQUIRED_STEP_NOT_READY", fmt.Sprintf("required collection step READY değil: %s", key))
			}
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireInternalReady && step.Required && !step.InternalReady {
			if step.DeferredToProviderLive && input.AllowProviderLiveDeferred {
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

		if input.RequireAttemptID && step.Required && !step.RequiresAttemptID {
			addFail(&report, "ATTEMPT_ID_REQUIRED", fmt.Sprintf("attempt_id requirement eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireIdempotencyKey && step.Required && !step.RequiresIdempotencyKey {
			addFail(&report, "IDEMPOTENCY_KEY_REQUIRED", fmt.Sprintf("idempotency key requirement eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAuditTrail && step.Required && !step.RequiresAuditTrail {
			addFail(&report, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail requirement eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireRetryPolicy && step.Required && !step.RequiresRetryPolicy {
			addFail(&report, "RETRY_POLICY_REQUIRED", fmt.Sprintf("retry policy eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireDunningTemplate && step.Required && !step.RequiresDunningTemplate {
			addFail(&report, "DUNNING_TEMPLATE_REQUIRED", fmt.Sprintf("dunning template eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireManualReview && step.Required && !step.RequiresManualReview {
			addFail(&report, "MANUAL_REVIEW_REQUIRED", fmt.Sprintf("manual review eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireBillingOwner && step.Required && !step.RequiresBillingOwner {
			addFail(&report, "BILLING_OWNER_REQUIRED", fmt.Sprintf("billing owner eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireProductionChargingBlock && step.Required && !step.BlocksProductionCharging {
			addFail(&report, "PRODUCTION_CHARGING_BLOCK_REQUIRED", fmt.Sprintf("production charging block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAutoTenantSuspensionBlock && step.Required && !step.BlocksAutoTenantSuspension {
			addFail(&report, "AUTO_TENANT_SUSPENSION_BLOCK_REQUIRED", fmt.Sprintf("auto tenant suspension block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if step.MaxRetryCount < 0 {
			addFail(&report, "MAX_RETRY_COUNT_INVALID", fmt.Sprintf("max retry count negatif olamaz: %s", key))
		}

		if step.GracePeriodDays < 0 {
			addFail(&report, "GRACE_PERIOD_DAYS_INVALID", fmt.Sprintf("grace period days negatif olamaz: %s", key))
		}

		if step.ProductionPaymentEnabled {
			addFail(&report, "STEP_PRODUCTION_PAYMENT_ENABLED_BLOCKED", fmt.Sprintf("production payment enabled açık olamaz: %s", key))
		}

		if step.RealCustomerChargingEnabled {
			addFail(&report, "STEP_REAL_CUSTOMER_CHARGING_BLOCKED", fmt.Sprintf("real customer charging açık olamaz: %s", key))
		}

		if step.AutoTenantSuspensionEnabled {
			addFail(&report, "STEP_AUTO_TENANT_SUSPENSION_BLOCKED", fmt.Sprintf("auto tenant suspension açık olamaz: %s", key))
		}

		if step.DeferredToProviderLive && strings.TrimSpace(step.DeferredReason) == "" {
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
			addFail(&report, "REQUIRED_EVENT_MISSING", fmt.Sprintf("collection event eksik: %s", event))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalCollectionFlowReady = false
		report.ProductionPaymentEnabled = false
		report.RealCustomerChargingEnabled = false
		report.AutoTenantSuspensionEnabled = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalCollectionFlowReady = input.InternalCollectionFlowReady
	report.ProductionPaymentEnabled = false
	report.RealCustomerChargingEnabled = false
	report.AutoTenantSuspensionEnabled = false
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
		return errors.New("collection failed payment flow failed")
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
