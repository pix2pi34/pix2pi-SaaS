package paymentadapter

import (
	"testing"
	"time"
)

func TestPaymentObservabilityRecordsOperationMetricsAndAuditTrail(t *testing.T) {
	obs := NewPaymentObservabilityRuntime()
	obs.now = func() time.Time { return time.Unix(1893456000, 0).UTC() }

	attempt := observabilityAttempt(t)
	authorized, err := attempt.ApplyContractDecision(observabilityDecision(OperationAuthorize), "prov_obs_001")
	if err != nil {
		t.Fatalf("expected authorize transition, got %v", err)
	}

	err = obs.RecordOperation(OperationAuthorize, PaymentOperationResult{
		Attempt:  authorized,
		Decision: observabilityDecision(OperationAuthorize),
	})
	if err != nil {
		t.Fatalf("expected record operation success, got %v", err)
	}

	snapshot := obs.Snapshot()
	if snapshot.Metrics[PaymentMetricOperationTotal] != 1 {
		t.Fatalf("expected operation total 1, got %d", snapshot.Metrics[PaymentMetricOperationTotal])
	}
	if snapshot.Metrics[PaymentMetricAuthorizeTotal] != 1 {
		t.Fatalf("expected authorize total 1, got %d", snapshot.Metrics[PaymentMetricAuthorizeTotal])
	}
	if snapshot.Metrics[PaymentMetricAuditTrailTotal] != 1 {
		t.Fatalf("expected audit trail total 1, got %d", snapshot.Metrics[PaymentMetricAuditTrailTotal])
	}
	if len(snapshot.Records) != 1 {
		t.Fatalf("expected one audit record, got %d", len(snapshot.Records))
	}
	if snapshot.Records[0].TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7 audit record, got %s", snapshot.Records[0].TenantID)
	}
}

func TestPaymentObservabilityRecordsFailedPaymentMetric(t *testing.T) {
	obs := NewPaymentObservabilityRuntime()
	attempt := observabilityAttempt(t)

	denied := OperationContractDecision{
		Allowed:       false,
		Status:        ContractStatusDenied,
		ProviderCode:  "pix2pi_simulation",
		Mode:          ModeSandbox,
		Operation:     OperationAuthorize,
		ErrorCode:     ErrorProductionGateClosed,
		Message:       "production real payment gate is closed",
		Retryable:     false,
		AuditRequired: true,
		RealPayment:   false,
	}

	failed, err := attempt.ApplyContractDecision(denied, "")
	if err != nil {
		t.Fatalf("expected failed transition from denied decision, got %v", err)
	}

	if err := obs.RecordOperation(OperationAuthorize, PaymentOperationResult{Attempt: failed, Decision: denied}); err != nil {
		t.Fatalf("expected failed operation record, got %v", err)
	}

	snapshot := obs.Snapshot()
	if snapshot.Metrics[PaymentMetricFailedTotal] != 1 {
		t.Fatalf("expected failed total 1, got %d", snapshot.Metrics[PaymentMetricFailedTotal])
	}
}

func TestPaymentObservabilityRecordsRetryDecisionMetrics(t *testing.T) {
	obs := NewPaymentObservabilityRuntime()

	err := obs.RecordRetryDecision("tenant_7", "attempt_obs_001", PaymentRetryDecision{
		Status:        RetryDecisionAllowed,
		ErrorCode:     ErrorProviderTransactionRequired,
		AttemptNumber: 1,
		MaxAttempts:   3,
		Retryable:     true,
		Message:       "retry allowed",
	})
	if err != nil {
		t.Fatalf("expected retry allowed record, got %v", err)
	}

	err = obs.RecordRetryDecision("tenant_7", "attempt_obs_001", PaymentRetryDecision{
		Status:        RetryDecisionNonRetryable,
		ErrorCode:     ErrorProductionGateClosed,
		AttemptNumber: 1,
		MaxAttempts:   3,
		Retryable:     false,
		Message:       "payment error is non-retryable",
	})
	if err != nil {
		t.Fatalf("expected retry non-retryable record, got %v", err)
	}

	snapshot := obs.Snapshot()
	if snapshot.Metrics[PaymentMetricRetryAllowed] != 1 {
		t.Fatalf("expected retry allowed total 1, got %d", snapshot.Metrics[PaymentMetricRetryAllowed])
	}
	if snapshot.Metrics[PaymentMetricRetryNonRetryable] != 1 {
		t.Fatalf("expected retry non-retryable total 1, got %d", snapshot.Metrics[PaymentMetricRetryNonRetryable])
	}
	if snapshot.Metrics[PaymentMetricAuditTrailTotal] != 2 {
		t.Fatalf("expected audit trail total 2, got %d", snapshot.Metrics[PaymentMetricAuditTrailTotal])
	}
}

func TestPaymentObservabilityRecordsWebhookAndDuplicateMetrics(t *testing.T) {
	obs := NewPaymentObservabilityRuntime()
	attempt := observabilityAttempt(t)

	if err := obs.RecordWebhookOnce(PaymentWebhookOnceResult{
		Attempt:    attempt,
		Duplicate:  false,
		EventCount: 3,
		Message:    "webhook verified and recorded",
	}); err != nil {
		t.Fatalf("expected webhook record success, got %v", err)
	}

	if err := obs.RecordWebhookOnce(PaymentWebhookOnceResult{
		Attempt:    attempt,
		Duplicate:  true,
		EventCount: 3,
		Message:    "duplicate webhook ignored",
	}); err != nil {
		t.Fatalf("expected duplicate webhook record success, got %v", err)
	}

	snapshot := obs.Snapshot()
	if snapshot.Metrics[PaymentMetricWebhookVerified] != 1 {
		t.Fatalf("expected webhook verified total 1, got %d", snapshot.Metrics[PaymentMetricWebhookVerified])
	}
	if snapshot.Metrics[PaymentMetricDuplicateWebhook] != 1 {
		t.Fatalf("expected duplicate webhook total 1, got %d", snapshot.Metrics[PaymentMetricDuplicateWebhook])
	}
}

func TestPaymentObservabilityTenantAuditTrailExport(t *testing.T) {
	obs := NewPaymentObservabilityRuntime()

	tenant7Attempt := observabilityAttempt(t)
	tenant99Attempt := observabilityAttempt(t)
	tenant99Attempt.TenantID = "tenant_99"
	tenant99Attempt.AttemptID = "attempt_obs_099"

	if err := obs.RecordOperation(OperationAuthorize, PaymentOperationResult{Attempt: tenant7Attempt, Decision: observabilityDecision(OperationAuthorize)}); err != nil {
		t.Fatalf("expected tenant_7 record, got %v", err)
	}
	if err := obs.RecordOperation(OperationAuthorize, PaymentOperationResult{Attempt: tenant99Attempt, Decision: observabilityDecision(OperationAuthorize)}); err != nil {
		t.Fatalf("expected tenant_99 record, got %v", err)
	}

	tenant7Records, err := obs.ExportTenantAuditTrail("tenant_7")
	if err != nil {
		t.Fatalf("expected tenant audit export success, got %v", err)
	}
	if len(tenant7Records) != 1 {
		t.Fatalf("expected one tenant_7 record, got %d", len(tenant7Records))
	}
	if tenant7Records[0].TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7 record, got %s", tenant7Records[0].TenantID)
	}
}

func TestPaymentObservabilityMetricNames(t *testing.T) {
	names := PaymentObservabilityMetricNames()
	if len(names) != 12 {
		t.Fatalf("expected 12 metric names, got %d", len(names))
	}

	assertPaymentMetricNameExists(t, names, PaymentMetricOperationTotal)
	assertPaymentMetricNameExists(t, names, PaymentMetricAuthorizeTotal)
	assertPaymentMetricNameExists(t, names, PaymentMetricFailedTotal)
	assertPaymentMetricNameExists(t, names, PaymentMetricRetryAllowed)
	assertPaymentMetricNameExists(t, names, PaymentMetricDuplicateWebhook)
	assertPaymentMetricNameExists(t, names, PaymentMetricAuditTrailTotal)
}

func observabilityAttempt(t *testing.T) PaymentAttempt {
	t.Helper()

	attempt, err := NewPaymentAttempt(PaymentAttemptCreateRequest{
		AttemptID:      "attempt_obs_001",
		TenantID:       "tenant_7",
		InvoiceID:      "invoice_obs_001",
		SubscriptionID: "sub_obs_001",
		ProviderCode:   "pix2pi_simulation",
		CorrelationID:  "corr_obs_001",
		RequestID:      "req_obs_001",
		IdempotencyKey: "idem_obs_001",
		Money:          Money{AmountMinor: 150000, Currency: "TRY"},
	})
	if err != nil {
		t.Fatalf("expected observability attempt, got %v", err)
	}

	return attempt
}

func observabilityDecision(operation PaymentOperation) OperationContractDecision {
	return OperationContractDecision{
		Allowed:       true,
		Status:        ContractStatusAccepted,
		ProviderCode:  "pix2pi_simulation",
		Mode:          ModeSandbox,
		Operation:     operation,
		ErrorCode:     ErrorNone,
		Message:       "payment operation contract accepted",
		Retryable:     true,
		AuditRequired: true,
		RealPayment:   false,
	}
}

func assertPaymentMetricNameExists(t *testing.T, names []PaymentMetricName, expected PaymentMetricName) {
	t.Helper()

	for _, name := range names {
		if name == expected {
			return
		}
	}

	t.Fatalf("expected metric name %s in list", expected)
}
