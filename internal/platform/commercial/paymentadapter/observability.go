package paymentadapter

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

var ErrPaymentObservabilityInvalidDependency = errors.New("payment observability invalid dependency")
var ErrPaymentObservabilityInvalidRequest = errors.New("payment observability invalid request")

type PaymentMetricName string

const (
	PaymentMetricOperationTotal    PaymentMetricName = "payment_operation_total"
	PaymentMetricAuthorizeTotal    PaymentMetricName = "payment_operation_authorize_total"
	PaymentMetricCaptureTotal      PaymentMetricName = "payment_operation_capture_total"
	PaymentMetricRefundTotal       PaymentMetricName = "payment_operation_refund_total"
	PaymentMetricVoidTotal         PaymentMetricName = "payment_operation_void_total"
	PaymentMetricWebhookVerified   PaymentMetricName = "payment_webhook_verified_total"
	PaymentMetricFailedTotal       PaymentMetricName = "payment_failed_total"
	PaymentMetricRetryAllowed      PaymentMetricName = "payment_retry_allowed_total"
	PaymentMetricRetryDenied       PaymentMetricName = "payment_retry_denied_total"
	PaymentMetricRetryNonRetryable PaymentMetricName = "payment_retry_non_retryable_total"
	PaymentMetricDuplicateWebhook  PaymentMetricName = "payment_duplicate_webhook_total"
	PaymentMetricAuditTrailTotal   PaymentMetricName = "payment_audit_trail_total"
)

type PaymentAuditTrailRecord struct {
	TenantID       string
	AttemptID      string
	ProviderCode   string
	Operation      PaymentOperation
	Status         PaymentAttemptStatus
	EventType      string
	ErrorCode      ContractErrorCode
	CorrelationID  string
	IdempotencyKey string
	Message        string
	OccurredAt     time.Time
}

type PaymentObservabilitySnapshot struct {
	Metrics map[PaymentMetricName]int
	Records []PaymentAuditTrailRecord
}

type PaymentObservabilityRuntime struct {
	metrics map[PaymentMetricName]int
	records []PaymentAuditTrailRecord
	now     func() time.Time
}

func NewPaymentObservabilityRuntime() *PaymentObservabilityRuntime {
	return &PaymentObservabilityRuntime{
		metrics: map[PaymentMetricName]int{},
		records: []PaymentAuditTrailRecord{},
		now:     func() time.Time { return time.Now().UTC() },
	}
}

func (r *PaymentObservabilityRuntime) RecordOperation(operation PaymentOperation, result PaymentOperationResult) error {
	if strings.TrimSpace(result.Attempt.TenantID) == "" {
		return fmt.Errorf("%w: tenant id is required", ErrPaymentObservabilityInvalidRequest)
	}
	if strings.TrimSpace(result.Attempt.AttemptID) == "" {
		return fmt.Errorf("%w: attempt id is required", ErrPaymentObservabilityInvalidRequest)
	}

	r.increment(PaymentMetricOperationTotal)
	r.increment(operationMetricName(operation))

	if result.Attempt.Status == AttemptStatusFailed || result.Attempt.FailureCode != ErrorNone {
		r.increment(PaymentMetricFailedTotal)
	}

	r.appendRecord(PaymentAuditTrailRecord{
		TenantID:       result.Attempt.TenantID,
		AttemptID:      result.Attempt.AttemptID,
		ProviderCode:   result.Attempt.ProviderCode,
		Operation:      operation,
		Status:         result.Attempt.Status,
		EventType:      "payment.operation",
		ErrorCode:      result.Attempt.FailureCode,
		CorrelationID:  result.Attempt.CorrelationID,
		IdempotencyKey: result.Attempt.IdempotencyKey,
		Message:        operationAuditMessage(operation, result.Attempt.Status),
		OccurredAt:     r.now().UTC(),
	})

	return nil
}

func (r *PaymentObservabilityRuntime) RecordWebhookOnce(result PaymentWebhookOnceResult) error {
	if strings.TrimSpace(result.Attempt.TenantID) == "" {
		return fmt.Errorf("%w: tenant id is required", ErrPaymentObservabilityInvalidRequest)
	}
	if strings.TrimSpace(result.Attempt.AttemptID) == "" {
		return fmt.Errorf("%w: attempt id is required", ErrPaymentObservabilityInvalidRequest)
	}

	if result.Duplicate {
		r.increment(PaymentMetricDuplicateWebhook)
	} else {
		r.increment(PaymentMetricWebhookVerified)
	}

	r.appendRecord(PaymentAuditTrailRecord{
		TenantID:       result.Attempt.TenantID,
		AttemptID:      result.Attempt.AttemptID,
		ProviderCode:   result.Attempt.ProviderCode,
		Operation:      OperationWebhookVerify,
		Status:         result.Attempt.Status,
		EventType:      "payment.webhook",
		ErrorCode:      result.Attempt.FailureCode,
		CorrelationID:  result.Attempt.CorrelationID,
		IdempotencyKey: result.Attempt.IdempotencyKey,
		Message:        result.Message,
		OccurredAt:     r.now().UTC(),
	})

	return nil
}

func (r *PaymentObservabilityRuntime) RecordRetryDecision(tenantID string, attemptID string, decision PaymentRetryDecision) error {
	if strings.TrimSpace(tenantID) == "" {
		return fmt.Errorf("%w: tenant id is required", ErrPaymentObservabilityInvalidRequest)
	}
	if strings.TrimSpace(attemptID) == "" {
		return fmt.Errorf("%w: attempt id is required", ErrPaymentObservabilityInvalidRequest)
	}

	switch decision.Status {
	case RetryDecisionAllowed:
		r.increment(PaymentMetricRetryAllowed)
	case RetryDecisionDenied:
		r.increment(PaymentMetricRetryDenied)
	case RetryDecisionNonRetryable:
		r.increment(PaymentMetricRetryNonRetryable)
	default:
		r.increment(PaymentMetricRetryDenied)
	}

	r.appendRecord(PaymentAuditTrailRecord{
		TenantID:   tenantID,
		AttemptID:  attemptID,
		Operation:  "",
		Status:     "",
		EventType:  "payment.retry_decision",
		ErrorCode:  decision.ErrorCode,
		Message:    decision.Message,
		OccurredAt: r.now().UTC(),
	})

	return nil
}

func (r *PaymentObservabilityRuntime) Snapshot() PaymentObservabilitySnapshot {
	metrics := map[PaymentMetricName]int{}
	for key, value := range r.metrics {
		metrics[key] = value
	}

	records := make([]PaymentAuditTrailRecord, len(r.records))
	copy(records, r.records)

	return PaymentObservabilitySnapshot{
		Metrics: metrics,
		Records: records,
	}
}

func (r *PaymentObservabilityRuntime) ExportTenantAuditTrail(tenantID string) ([]PaymentAuditTrailRecord, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, fmt.Errorf("%w: tenant id is required", ErrPaymentObservabilityInvalidRequest)
	}

	var records []PaymentAuditTrailRecord
	for _, record := range r.records {
		if record.TenantID == tenantID {
			records = append(records, record)
		}
	}

	sort.SliceStable(records, func(i, j int) bool {
		return records[i].OccurredAt.Before(records[j].OccurredAt)
	})

	return records, nil
}

func (r *PaymentObservabilityRuntime) increment(metric PaymentMetricName) {
	r.metrics[metric]++
}

func (r *PaymentObservabilityRuntime) appendRecord(record PaymentAuditTrailRecord) {
	if record.OccurredAt.IsZero() {
		record.OccurredAt = r.now().UTC()
	}
	r.records = append(r.records, record)
	r.increment(PaymentMetricAuditTrailTotal)
}

func operationMetricName(operation PaymentOperation) PaymentMetricName {
	switch operation {
	case OperationAuthorize:
		return PaymentMetricAuthorizeTotal
	case OperationCapture:
		return PaymentMetricCaptureTotal
	case OperationRefund:
		return PaymentMetricRefundTotal
	case OperationVoid:
		return PaymentMetricVoidTotal
	case OperationWebhookVerify:
		return PaymentMetricWebhookVerified
	default:
		return PaymentMetricOperationTotal
	}
}

func operationAuditMessage(operation PaymentOperation, status PaymentAttemptStatus) string {
	return fmt.Sprintf("payment operation %s recorded with status %s", operation, status)
}

func PaymentObservabilityMetricNames() []PaymentMetricName {
	return []PaymentMetricName{
		PaymentMetricOperationTotal,
		PaymentMetricAuthorizeTotal,
		PaymentMetricCaptureTotal,
		PaymentMetricRefundTotal,
		PaymentMetricVoidTotal,
		PaymentMetricWebhookVerified,
		PaymentMetricFailedTotal,
		PaymentMetricRetryAllowed,
		PaymentMetricRetryDenied,
		PaymentMetricRetryNonRetryable,
		PaymentMetricDuplicateWebhook,
		PaymentMetricAuditTrailTotal,
	}
}
