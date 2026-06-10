package paymentadapter

import (
	"errors"
	"testing"
)

func TestPaymentAttemptRepositorySaveAndFindByAttemptID(t *testing.T) {
	repo := NewInMemoryPaymentAttemptRepository()
	attempt := repositoryTestAttempt(t, "tenant_7", "attempt_repo_001", "idem_repo_001")

	if err := repo.Save(attempt); err != nil {
		t.Fatalf("expected save success, got error: %v", err)
	}

	found, exists, err := repo.FindByAttemptID("tenant_7", "attempt_repo_001")
	if err != nil {
		t.Fatalf("expected find success, got error: %v", err)
	}
	if !exists {
		t.Fatal("expected attempt to exist")
	}
	if found.AttemptID != "attempt_repo_001" {
		t.Fatalf("unexpected attempt id: %s", found.AttemptID)
	}
}

func TestPaymentAttemptRepositoryTenantSafeLookup(t *testing.T) {
	repo := NewInMemoryPaymentAttemptRepository()
	attempt := repositoryTestAttempt(t, "tenant_7", "shared_attempt_id", "idem_tenant_7")

	if err := repo.Save(attempt); err != nil {
		t.Fatalf("expected save success, got error: %v", err)
	}

	_, exists, err := repo.FindByAttemptID("tenant_99", "shared_attempt_id")
	if err != nil {
		t.Fatalf("expected tenant-safe miss without error, got %v", err)
	}
	if exists {
		t.Fatal("tenant_99 must not see tenant_7 attempt")
	}

	tenant99Attempt := repositoryTestAttempt(t, "tenant_99", "shared_attempt_id", "idem_tenant_99")
	if err := repo.Save(tenant99Attempt); err != nil {
		t.Fatalf("same attempt id in another tenant should be allowed: %v", err)
	}
}

func TestPaymentAttemptRepositoryDuplicateAttemptDenied(t *testing.T) {
	repo := NewInMemoryPaymentAttemptRepository()
	attempt := repositoryTestAttempt(t, "tenant_7", "attempt_repo_002", "idem_repo_002")

	if err := repo.Save(attempt); err != nil {
		t.Fatalf("expected first save success, got error: %v", err)
	}

	err := repo.Save(attempt)
	if err == nil {
		t.Fatal("duplicate attempt save must fail")
	}
	if !errors.Is(err, ErrPaymentAttemptAlreadyExists) {
		t.Fatalf("expected already exists error, got %v", err)
	}
}

func TestPaymentAttemptRepositoryIdempotencyConflictDenied(t *testing.T) {
	repo := NewInMemoryPaymentAttemptRepository()
	first := repositoryTestAttempt(t, "tenant_7", "attempt_repo_003_a", "idem_repo_003")
	second := repositoryTestAttempt(t, "tenant_7", "attempt_repo_003_b", "idem_repo_003")

	if err := repo.Save(first); err != nil {
		t.Fatalf("expected first save success, got error: %v", err)
	}

	err := repo.Save(second)
	if err == nil {
		t.Fatal("same idempotency key for different attempt must fail")
	}
	if !errors.Is(err, ErrPaymentAttemptIdempotencyConflict) {
		t.Fatalf("expected idempotency conflict, got %v", err)
	}
}

func TestPaymentAttemptRepositoryFindByIdempotencyKey(t *testing.T) {
	repo := NewInMemoryPaymentAttemptRepository()
	attempt := repositoryTestAttempt(t, "tenant_7", "attempt_repo_004", "idem_repo_004")

	if err := repo.Save(attempt); err != nil {
		t.Fatalf("expected save success, got error: %v", err)
	}

	found, exists, err := repo.FindByIdempotencyKey("tenant_7", "idem_repo_004")
	if err != nil {
		t.Fatalf("expected find by idempotency success, got error: %v", err)
	}
	if !exists {
		t.Fatal("expected idempotency lookup to find attempt")
	}
	if found.AttemptID != "attempt_repo_004" {
		t.Fatalf("unexpected attempt id: %s", found.AttemptID)
	}

	_, otherTenantExists, err := repo.FindByIdempotencyKey("tenant_99", "idem_repo_004")
	if err != nil {
		t.Fatalf("expected other tenant miss without error, got %v", err)
	}
	if otherTenantExists {
		t.Fatal("idempotency lookup must be tenant isolated")
	}
}

func TestPaymentAttemptRepositoryUpdatePersistsStatusAndEvents(t *testing.T) {
	repo := NewInMemoryPaymentAttemptRepository()
	attempt := repositoryTestAttempt(t, "tenant_7", "attempt_repo_005", "idem_repo_005")

	if err := repo.Save(attempt); err != nil {
		t.Fatalf("expected save success, got error: %v", err)
	}

	authorized, err := attempt.ApplyContractDecision(allowedDecision(OperationAuthorize), "prov_txn_repo_005")
	if err != nil {
		t.Fatalf("expected authorize transition, got error: %v", err)
	}

	if err := repo.Update(authorized); err != nil {
		t.Fatalf("expected update success, got error: %v", err)
	}

	found, exists, err := repo.FindByAttemptID("tenant_7", "attempt_repo_005")
	if err != nil {
		t.Fatalf("expected find success, got error: %v", err)
	}
	if !exists {
		t.Fatal("expected attempt to exist")
	}
	if found.Status != AttemptStatusAuthorized {
		t.Fatalf("expected AUTHORIZED status, got %s", found.Status)
	}
	if found.ProviderTransactionID != "prov_txn_repo_005" {
		t.Fatalf("expected provider transaction id persisted, got %s", found.ProviderTransactionID)
	}
	if len(found.Events) != 2 {
		t.Fatalf("expected 2 events after authorize, got %d", len(found.Events))
	}
}

func TestPaymentAttemptRepositoryUpdateMissingAttemptDenied(t *testing.T) {
	repo := NewInMemoryPaymentAttemptRepository()
	attempt := repositoryTestAttempt(t, "tenant_7", "attempt_repo_006", "idem_repo_006")

	err := repo.Update(attempt)
	if err == nil {
		t.Fatal("update missing attempt must fail")
	}
	if !errors.Is(err, ErrPaymentAttemptNotFound) {
		t.Fatalf("expected not found error, got %v", err)
	}
}

func TestPaymentAttemptRepositoryAppendAndListEvents(t *testing.T) {
	repo := NewInMemoryPaymentAttemptRepository()
	attempt := repositoryTestAttempt(t, "tenant_7", "attempt_repo_007", "idem_repo_007")

	if err := repo.Save(attempt); err != nil {
		t.Fatalf("expected save success, got error: %v", err)
	}

	event := PaymentAttemptEvent{
		FromStatus:            AttemptStatusCreated,
		ToStatus:              AttemptStatusAuthorized,
		Operation:             OperationAuthorize,
		ProviderCode:          "pix2pi_simulation",
		ProviderTransactionID: "prov_txn_repo_007",
		Message:               "manual audit event append test",
		CorrelationID:         "corr_attempt_repo_007",
		IdempotencyKey:        "idem_repo_007",
		AuditRequired:         true,
		RealPayment:           false,
	}

	if err := repo.AppendEvent("tenant_7", "attempt_repo_007", event); err != nil {
		t.Fatalf("expected append event success, got error: %v", err)
	}

	events, err := repo.ListEvents("tenant_7", "attempt_repo_007")
	if err != nil {
		t.Fatalf("expected list events success, got error: %v", err)
	}
	if len(events) != 2 {
		t.Fatalf("expected creation + appended event, got %d events", len(events))
	}
	if events[1].Message != "manual audit event append test" {
		t.Fatalf("unexpected appended event message: %s", events[1].Message)
	}

	found, exists, err := repo.FindByAttemptID("tenant_7", "attempt_repo_007")
	if err != nil {
		t.Fatalf("expected find success, got error: %v", err)
	}
	if !exists {
		t.Fatal("expected attempt to exist")
	}
	if len(found.Events) != 2 {
		t.Fatalf("expected stored attempt event history to be updated, got %d", len(found.Events))
	}
}

func TestPaymentAttemptRepositoryListEventsMissingAttemptDenied(t *testing.T) {
	repo := NewInMemoryPaymentAttemptRepository()

	_, err := repo.ListEvents("tenant_7", "missing_attempt")
	if err == nil {
		t.Fatal("list events for missing attempt must fail")
	}
	if !errors.Is(err, ErrPaymentAttemptNotFound) {
		t.Fatalf("expected not found error, got %v", err)
	}
}

func TestPaymentAttemptRepositorySaveInvalidAttemptDenied(t *testing.T) {
	repo := NewInMemoryPaymentAttemptRepository()
	attempt := repositoryTestAttempt(t, "tenant_7", "attempt_repo_008", "idem_repo_008")
	attempt.TenantID = ""

	err := repo.Save(attempt)
	if err == nil {
		t.Fatal("invalid attempt must fail")
	}
	if !errors.Is(err, ErrInvalidPaymentAttempt) {
		t.Fatalf("expected invalid payment attempt error, got %v", err)
	}
}

func repositoryTestAttempt(t *testing.T, tenantID string, attemptID string, idempotencyKey string) PaymentAttempt {
	t.Helper()

	attempt, err := NewPaymentAttempt(PaymentAttemptCreateRequest{
		AttemptID:      attemptID,
		TenantID:       tenantID,
		InvoiceID:      "invoice_" + attemptID,
		SubscriptionID: "sub_" + attemptID,
		ProviderCode:   "pix2pi_simulation",
		CorrelationID:  "corr_" + attemptID,
		RequestID:      "req_" + attemptID,
		IdempotencyKey: idempotencyKey,
		Money:          Money{AmountMinor: 45000, Currency: "TRY"},
	})
	if err != nil {
		t.Fatalf("expected repository test payment attempt, got error: %v", err)
	}

	return attempt
}
