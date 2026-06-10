package paymentadapter

import (
	"errors"
	"testing"
	"time"
)

func TestPaymentAdminOpsRuntimeRequiresDependencies(t *testing.T) {
	repo := NewInMemoryPaymentAttemptRepository()
	obs := NewPaymentObservabilityRuntime()

	if _, err := NewPaymentAdminOpsRuntime(nil, obs); err == nil {
		t.Fatal("missing repository must fail")
	}
	if _, err := NewPaymentAdminOpsRuntime(repo, nil); err == nil {
		t.Fatal("missing observability runtime must fail")
	}
}

func TestPaymentAdminOpsQueuesFailedPaymentReview(t *testing.T) {
	ops, repo, obs := adminOpsRuntime(t)
	failed := adminOpsFailedAttempt(t)

	if err := repo.Save(failed.Attempt); err != nil {
		t.Fatalf("expected failed attempt save, got %v", err)
	}
	if err := obs.RecordOperation(OperationAuthorize, failed); err != nil {
		t.Fatalf("expected failed operation observability record, got %v", err)
	}

	item, err := ops.QueueFailedPayment(failed)
	if err != nil {
		t.Fatalf("expected failed payment review queue, got %v", err)
	}
	if item.ReviewType != PaymentReviewFailedPayment {
		t.Fatalf("expected FAILED_PAYMENT review, got %s", item.ReviewType)
	}
	if item.Status != PaymentReviewOpen {
		t.Fatalf("expected OPEN review, got %s", item.Status)
	}
	if item.Priority != 10 {
		t.Fatalf("expected priority 10, got %d", item.Priority)
	}

	items, err := ops.ListTenantReviews("tenant_7")
	if err != nil {
		t.Fatalf("expected tenant review list, got %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("expected one tenant review, got %d", len(items))
	}
}

func TestPaymentAdminOpsRejectsNonFailedPaymentReview(t *testing.T) {
	ops, _, _ := adminOpsRuntime(t)
	attempt := adminOpsAuthorizedAttempt(t)

	_, err := ops.QueueFailedPayment(PaymentOperationResult{
		Attempt:  attempt,
		Decision: adminOpsDecision(OperationAuthorize),
	})
	if err == nil {
		t.Fatal("non-failed payment must not be queued as failed review")
	}
	if !errors.Is(err, ErrPaymentAdminOpsInvalidRequest) {
		t.Fatalf("expected invalid request, got %v", err)
	}
}

func TestPaymentAdminOpsQueuesRetryReview(t *testing.T) {
	ops, repo, _ := adminOpsRuntime(t)
	attempt := adminOpsAuthorizedAttempt(t)

	if err := repo.Save(attempt); err != nil {
		t.Fatalf("expected attempt save, got %v", err)
	}

	item, err := ops.QueueRetryReview("tenant_7", "attempt_admin_ops_001", PaymentRetryDecision{
		Status:        RetryDecisionAllowed,
		ErrorCode:     ErrorProviderTransactionRequired,
		AttemptNumber: 1,
		MaxAttempts:   3,
		Retryable:     true,
		Message:       "retry allowed",
	})
	if err != nil {
		t.Fatalf("expected retry review queue, got %v", err)
	}
	if item.ReviewType != PaymentReviewRetryReview {
		t.Fatalf("expected RETRY_REVIEW, got %s", item.ReviewType)
	}
	if item.ErrorCode != ErrorProviderTransactionRequired {
		t.Fatalf("expected provider transaction error, got %s", item.ErrorCode)
	}
}

func TestPaymentAdminOpsQueuesWebhookDispute(t *testing.T) {
	ops, repo, _ := adminOpsRuntime(t)
	attempt := adminOpsAuthorizedAttempt(t)

	if err := repo.Save(attempt); err != nil {
		t.Fatalf("expected attempt save, got %v", err)
	}

	item, err := ops.QueueWebhookDispute("tenant_7", "attempt_admin_ops_001", "provider webhook payload mismatch")
	if err != nil {
		t.Fatalf("expected webhook dispute queue, got %v", err)
	}
	if item.ReviewType != PaymentReviewWebhookDispute {
		t.Fatalf("expected WEBHOOK_DISPUTE, got %s", item.ReviewType)
	}
	if item.Priority != 7 {
		t.Fatalf("expected priority 7, got %d", item.Priority)
	}
}

func TestPaymentAdminOpsActionGuardAssignResolveReject(t *testing.T) {
	ops, repo, _ := adminOpsRuntime(t)
	failed := adminOpsFailedAttempt(t)

	if err := repo.Save(failed.Attempt); err != nil {
		t.Fatalf("expected failed attempt save, got %v", err)
	}

	item, err := ops.QueueFailedPayment(failed)
	if err != nil {
		t.Fatalf("expected failed review, got %v", err)
	}

	_, err = ops.ApplyAction(PaymentOpsActionRequest{
		TenantID: "tenant_7",
		ReviewID: item.ReviewID,
		Action:   PaymentOpsActionResolve,
		Actor:    "ops_user_1",
		Message:  "cannot resolve before assignment",
	})
	if err == nil {
		t.Fatal("resolve before assignment must fail")
	}
	if !errors.Is(err, ErrPaymentAdminOpsActionDenied) {
		t.Fatalf("expected action denied, got %v", err)
	}

	assigned, err := ops.ApplyAction(PaymentOpsActionRequest{
		TenantID: "tenant_7",
		ReviewID: item.ReviewID,
		Action:   PaymentOpsActionAssign,
		Actor:    "ops_user_1",
		Message:  "assigned to ops",
	})
	if err != nil {
		t.Fatalf("expected assign success, got %v", err)
	}
	if assigned.Status != PaymentReviewInReview {
		t.Fatalf("expected IN_REVIEW, got %s", assigned.Status)
	}
	if assigned.AssignedTo != "ops_user_1" {
		t.Fatalf("expected assigned ops_user_1, got %s", assigned.AssignedTo)
	}

	resolved, err := ops.ApplyAction(PaymentOpsActionRequest{
		TenantID: "tenant_7",
		ReviewID: item.ReviewID,
		Action:   PaymentOpsActionResolve,
		Actor:    "ops_user_1",
		Message:  "resolved after manual check",
	})
	if err != nil {
		t.Fatalf("expected resolve success, got %v", err)
	}
	if resolved.Status != PaymentReviewResolved {
		t.Fatalf("expected RESOLVED, got %s", resolved.Status)
	}
}

func TestPaymentAdminOpsCrossTenantReviewAccessDenied(t *testing.T) {
	ops, repo, _ := adminOpsRuntime(t)
	failed := adminOpsFailedAttempt(t)

	if err := repo.Save(failed.Attempt); err != nil {
		t.Fatalf("expected failed attempt save, got %v", err)
	}

	item, err := ops.QueueFailedPayment(failed)
	if err != nil {
		t.Fatalf("expected failed review, got %v", err)
	}

	_, exists, err := ops.GetReview("tenant_99", item.ReviewID)
	if err != nil {
		t.Fatalf("expected cross tenant lookup without error, got %v", err)
	}
	if exists {
		t.Fatal("tenant_99 must not access tenant_7 review")
	}
}

func TestPaymentAdminOpsTenantAuditTrailReadContract(t *testing.T) {
	ops, _, obs := adminOpsRuntime(t)

	tenant7Attempt := adminOpsAuthorizedAttempt(t)
	tenant99Attempt := adminOpsAuthorizedAttempt(t)
	tenant99Attempt.TenantID = "tenant_99"
	tenant99Attempt.AttemptID = "attempt_admin_ops_099"

	if err := obs.RecordOperation(OperationAuthorize, PaymentOperationResult{Attempt: tenant7Attempt, Decision: adminOpsDecision(OperationAuthorize)}); err != nil {
		t.Fatalf("expected tenant_7 audit record, got %v", err)
	}
	if err := obs.RecordOperation(OperationAuthorize, PaymentOperationResult{Attempt: tenant99Attempt, Decision: adminOpsDecision(OperationAuthorize)}); err != nil {
		t.Fatalf("expected tenant_99 audit record, got %v", err)
	}

	records, err := ops.ReadTenantAuditTrail(PaymentOpsAuditTrailQuery{
		TenantID:  "tenant_7",
		AttemptID: "attempt_admin_ops_001",
		EventType: "payment.operation",
	})
	if err != nil {
		t.Fatalf("expected tenant audit read success, got %v", err)
	}
	if len(records) != 1 {
		t.Fatalf("expected one filtered audit record, got %d", len(records))
	}
	if records[0].TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7 record, got %s", records[0].TenantID)
	}
}

func TestPaymentAdminOpsStaticCatalogs(t *testing.T) {
	if len(PaymentAdminOpsReviewTypes()) != 3 {
		t.Fatalf("expected 3 review types")
	}
	if len(PaymentAdminOpsReviewStatuses()) != 4 {
		t.Fatalf("expected 4 review statuses")
	}
	if len(PaymentAdminOpsActions()) != 3 {
		t.Fatalf("expected 3 ops actions")
	}
}

func adminOpsRuntime(t *testing.T) (*PaymentAdminOpsRuntime, *InMemoryPaymentAttemptRepository, *PaymentObservabilityRuntime) {
	t.Helper()

	repo := NewInMemoryPaymentAttemptRepository()
	obs := NewPaymentObservabilityRuntime()
	ops, err := NewPaymentAdminOpsRuntime(repo, obs)
	if err != nil {
		t.Fatalf("expected admin ops runtime, got %v", err)
	}

	fixedNow := time.Unix(1893456000, 0).UTC()
	ops.now = func() time.Time { return fixedNow }
	obs.now = func() time.Time { return fixedNow }

	return ops, repo, obs
}

func adminOpsAuthorizedAttempt(t *testing.T) PaymentAttempt {
	t.Helper()

	attempt, err := NewPaymentAttempt(PaymentAttemptCreateRequest{
		AttemptID:      "attempt_admin_ops_001",
		TenantID:       "tenant_7",
		InvoiceID:      "invoice_admin_ops_001",
		SubscriptionID: "sub_admin_ops_001",
		ProviderCode:   "pix2pi_simulation",
		CorrelationID:  "corr_admin_ops_001",
		RequestID:      "req_admin_ops_001",
		IdempotencyKey: "idem_admin_ops_001",
		Money:          Money{AmountMinor: 175000, Currency: "TRY"},
	})
	if err != nil {
		t.Fatalf("expected admin ops attempt, got %v", err)
	}

	authorized, err := attempt.ApplyContractDecision(adminOpsDecision(OperationAuthorize), "prov_admin_ops_001")
	if err != nil {
		t.Fatalf("expected authorized attempt, got %v", err)
	}

	return authorized
}

func adminOpsFailedAttempt(t *testing.T) PaymentOperationResult {
	t.Helper()

	attempt, err := NewPaymentAttempt(PaymentAttemptCreateRequest{
		AttemptID:      "attempt_admin_ops_failed_001",
		TenantID:       "tenant_7",
		InvoiceID:      "invoice_admin_ops_failed_001",
		SubscriptionID: "sub_admin_ops_failed_001",
		ProviderCode:   "pix2pi_simulation",
		CorrelationID:  "corr_admin_ops_failed_001",
		RequestID:      "req_admin_ops_failed_001",
		IdempotencyKey: "idem_admin_ops_failed_001",
		Money:          Money{AmountMinor: 175000, Currency: "TRY"},
	})
	if err != nil {
		t.Fatalf("expected failed attempt base, got %v", err)
	}

	decision := OperationContractDecision{
		Allowed:       false,
		Status:        ContractStatusDenied,
		ProviderCode:  "pix2pi_simulation",
		Mode:          ModeProduction,
		Operation:     OperationAuthorize,
		ErrorCode:     ErrorProductionGateClosed,
		Message:       "production real payment gate is closed",
		Retryable:     false,
		AuditRequired: true,
		RealPayment:   false,
	}

	failed, err := attempt.ApplyContractDecision(decision, "")
	if err != nil {
		t.Fatalf("expected failed attempt from denied decision, got %v", err)
	}

	return PaymentOperationResult{
		Attempt:  failed,
		Decision: decision,
		Replay:   false,
	}
}

func adminOpsDecision(operation PaymentOperation) OperationContractDecision {
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
