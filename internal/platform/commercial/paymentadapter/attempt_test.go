package paymentadapter

import (
	"errors"
	"testing"
)

func TestNewPaymentAttemptCreated(t *testing.T) {
	attempt := mustPaymentAttempt(t)

	if attempt.Status != AttemptStatusCreated {
		t.Fatalf("expected CREATED status, got %s", attempt.Status)
	}
	if len(attempt.Events) != 1 {
		t.Fatalf("expected creation audit event, got %d events", len(attempt.Events))
	}
	if attempt.Events[0].ToStatus != AttemptStatusCreated {
		t.Fatalf("expected creation event to CREATED, got %s", attempt.Events[0].ToStatus)
	}
}

func TestPaymentAttemptAuthorizeTransitionSetsProviderTransaction(t *testing.T) {
	attempt := mustPaymentAttempt(t)

	next, err := attempt.ApplyContractDecision(allowedDecision(OperationAuthorize), "prov_txn_001")
	if err != nil {
		t.Fatalf("expected authorize transition, got error: %v", err)
	}
	if next.Status != AttemptStatusAuthorized {
		t.Fatalf("expected AUTHORIZED, got %s", next.Status)
	}
	if next.ProviderTransactionID != "prov_txn_001" {
		t.Fatalf("expected provider transaction mapping, got %s", next.ProviderTransactionID)
	}
	if len(next.Events) != 2 {
		t.Fatalf("expected 2 audit events, got %d", len(next.Events))
	}
}

func TestPaymentAttemptCaptureRequiresAuthorizedStatus(t *testing.T) {
	attempt := mustPaymentAttempt(t)

	_, err := attempt.ApplyContractDecision(allowedDecision(OperationCapture), "prov_txn_001")
	if err == nil {
		t.Fatal("capture from CREATED must fail")
	}
	if !errors.Is(err, ErrInvalidAttemptTransition) {
		t.Fatalf("expected invalid transition error, got %v", err)
	}

	authorized := mustAuthorizedAttempt(t)
	captured, err := authorized.ApplyContractDecision(allowedDecision(OperationCapture), "prov_txn_001")
	if err != nil {
		t.Fatalf("expected capture transition, got error: %v", err)
	}
	if captured.Status != AttemptStatusCaptured {
		t.Fatalf("expected CAPTURED, got %s", captured.Status)
	}
}

func TestPaymentAttemptRefundRequiresCapturedStatus(t *testing.T) {
	authorized := mustAuthorizedAttempt(t)

	_, err := authorized.ApplyContractDecision(allowedDecision(OperationRefund), "prov_txn_001")
	if err == nil {
		t.Fatal("refund from AUTHORIZED must fail")
	}
	if !errors.Is(err, ErrInvalidAttemptTransition) {
		t.Fatalf("expected invalid transition error, got %v", err)
	}

	captured := mustCapturedAttempt(t)
	refunded, err := captured.ApplyContractDecision(allowedDecision(OperationRefund), "prov_txn_001")
	if err != nil {
		t.Fatalf("expected refund transition, got error: %v", err)
	}
	if refunded.Status != AttemptStatusRefunded {
		t.Fatalf("expected REFUNDED, got %s", refunded.Status)
	}
}

func TestPaymentAttemptVoidRequiresAuthorizedStatus(t *testing.T) {
	authorized := mustAuthorizedAttempt(t)

	voided, err := authorized.ApplyContractDecision(allowedDecision(OperationVoid), "prov_txn_001")
	if err != nil {
		t.Fatalf("expected void transition, got error: %v", err)
	}
	if voided.Status != AttemptStatusVoided {
		t.Fatalf("expected VOIDED, got %s", voided.Status)
	}
}

func TestPaymentAttemptDeniedDecisionMarksFailedAndAuditEvent(t *testing.T) {
	attempt := mustPaymentAttempt(t)

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
		t.Fatalf("expected denied decision to mark failed without error, got %v", err)
	}
	if failed.Status != AttemptStatusFailed {
		t.Fatalf("expected FAILED, got %s", failed.Status)
	}
	if failed.FailureCode != ErrorProductionGateClosed {
		t.Fatalf("expected failure code, got %s", failed.FailureCode)
	}
	if len(failed.Events) != 2 {
		t.Fatalf("expected failure audit event, got %d events", len(failed.Events))
	}
}

func TestPaymentAttemptIdempotencyReplayGuard(t *testing.T) {
	attempt := mustPaymentAttempt(t)

	if err := attempt.ValidateIdempotencyReplay("idem_7_5p_2_001"); err != nil {
		t.Fatalf("same idempotency key should be accepted: %v", err)
	}

	err := attempt.ValidateIdempotencyReplay("different_idem_key")
	if err == nil {
		t.Fatal("different idempotency key must fail")
	}
	if !errors.Is(err, ErrIdempotencyKeyMismatch) {
		t.Fatalf("expected idempotency mismatch, got %v", err)
	}
}

func TestPaymentAttemptProviderTransactionMismatchDenied(t *testing.T) {
	authorized := mustAuthorizedAttempt(t)

	_, err := authorized.ApplyContractDecision(allowedDecision(OperationCapture), "different_provider_txn")
	if err == nil {
		t.Fatal("provider transaction mismatch must fail")
	}
	if !errors.Is(err, ErrProviderTransactionMismatch) {
		t.Fatalf("expected provider transaction mismatch, got %v", err)
	}
}

func TestPaymentAttemptWebhookVerifyDoesNotChangeStatus(t *testing.T) {
	authorized := mustAuthorizedAttempt(t)

	next, err := authorized.ApplyContractDecision(allowedDecision(OperationWebhookVerify), "")
	if err != nil {
		t.Fatalf("expected webhook verify record, got error: %v", err)
	}
	if next.Status != AttemptStatusAuthorized {
		t.Fatalf("webhook verify must not change status, got %s", next.Status)
	}
	if len(next.Events) != 3 {
		t.Fatalf("expected webhook audit event, got %d events", len(next.Events))
	}
}

func TestPaymentAttemptStatuses(t *testing.T) {
	statuses := PaymentAttemptStatuses()
	if len(statuses) != 6 {
		t.Fatalf("expected 6 statuses, got %d", len(statuses))
	}
	assertContainsAttemptStatus(t, statuses, AttemptStatusCreated)
	assertContainsAttemptStatus(t, statuses, AttemptStatusAuthorized)
	assertContainsAttemptStatus(t, statuses, AttemptStatusCaptured)
	assertContainsAttemptStatus(t, statuses, AttemptStatusRefunded)
	assertContainsAttemptStatus(t, statuses, AttemptStatusVoided)
	assertContainsAttemptStatus(t, statuses, AttemptStatusFailed)
}

func mustPaymentAttempt(t *testing.T) PaymentAttempt {
	t.Helper()

	attempt, err := NewPaymentAttempt(PaymentAttemptCreateRequest{
		AttemptID:      "pay_attempt_7_5p_2_001",
		TenantID:       "tenant_7",
		InvoiceID:      "invoice_7_5p_2_001",
		SubscriptionID: "sub_7_5p_2_001",
		ProviderCode:   "pix2pi_simulation",
		CorrelationID:  "corr_7_5p_2_001",
		RequestID:      "req_7_5p_2_001",
		IdempotencyKey: "idem_7_5p_2_001",
		Money:          Money{AmountMinor: 30000, Currency: "TRY"},
	})
	if err != nil {
		t.Fatalf("expected payment attempt, got error: %v", err)
	}

	return attempt
}

func mustAuthorizedAttempt(t *testing.T) PaymentAttempt {
	t.Helper()

	attempt := mustPaymentAttempt(t)
	authorized, err := attempt.ApplyContractDecision(allowedDecision(OperationAuthorize), "prov_txn_001")
	if err != nil {
		t.Fatalf("expected authorized attempt, got error: %v", err)
	}

	return authorized
}

func mustCapturedAttempt(t *testing.T) PaymentAttempt {
	t.Helper()

	authorized := mustAuthorizedAttempt(t)
	captured, err := authorized.ApplyContractDecision(allowedDecision(OperationCapture), "prov_txn_001")
	if err != nil {
		t.Fatalf("expected captured attempt, got error: %v", err)
	}

	return captured
}

func allowedDecision(operation PaymentOperation) OperationContractDecision {
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

func assertContainsAttemptStatus(t *testing.T, statuses []PaymentAttemptStatus, expected PaymentAttemptStatus) {
	t.Helper()

	for _, status := range statuses {
		if status == expected {
			return
		}
	}

	t.Fatalf("expected status %s in payment attempt statuses", expected)
}
