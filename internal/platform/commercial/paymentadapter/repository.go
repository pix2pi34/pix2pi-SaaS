package paymentadapter

import (
	"errors"
	"fmt"
	"strings"
	"sync"
)

var (
	ErrPaymentAttemptAlreadyExists       = errors.New("payment attempt already exists")
	ErrPaymentAttemptNotFound            = errors.New("payment attempt not found")
	ErrPaymentAttemptIdempotencyConflict = errors.New("payment attempt idempotency conflict")
)

type PaymentAttemptRepository interface {
	Save(attempt PaymentAttempt) error
	Update(attempt PaymentAttempt) error
	FindByAttemptID(tenantID string, attemptID string) (PaymentAttempt, bool, error)
	FindByIdempotencyKey(tenantID string, idempotencyKey string) (PaymentAttempt, bool, error)
	AppendEvent(tenantID string, attemptID string, event PaymentAttemptEvent) error
	ListEvents(tenantID string, attemptID string) ([]PaymentAttemptEvent, error)
}

type InMemoryPaymentAttemptRepository struct {
	mu        sync.RWMutex
	attempts  map[string]PaymentAttempt
	idemIndex map[string]string
	events    map[string][]PaymentAttemptEvent
}

func NewInMemoryPaymentAttemptRepository() *InMemoryPaymentAttemptRepository {
	return &InMemoryPaymentAttemptRepository{
		attempts:  make(map[string]PaymentAttempt),
		idemIndex: make(map[string]string),
		events:    make(map[string][]PaymentAttemptEvent),
	}
}

func (r *InMemoryPaymentAttemptRepository) Save(attempt PaymentAttempt) error {
	if err := validatePaymentAttemptForRepository(attempt); err != nil {
		return err
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	attemptKey := paymentAttemptRepositoryKey(attempt.TenantID, attempt.AttemptID)
	if _, exists := r.attempts[attemptKey]; exists {
		return ErrPaymentAttemptAlreadyExists
	}

	idemKey := paymentAttemptIdempotencyKey(attempt.TenantID, attempt.IdempotencyKey)
	if existingAttemptID, exists := r.idemIndex[idemKey]; exists && existingAttemptID != attempt.AttemptID {
		return ErrPaymentAttemptIdempotencyConflict
	}

	r.attempts[attemptKey] = clonePaymentAttempt(attempt)
	r.idemIndex[idemKey] = attempt.AttemptID
	r.events[attemptKey] = clonePaymentAttemptEvents(attempt.Events)
	return nil
}

func (r *InMemoryPaymentAttemptRepository) Update(attempt PaymentAttempt) error {
	if err := validatePaymentAttemptForRepository(attempt); err != nil {
		return err
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	attemptKey := paymentAttemptRepositoryKey(attempt.TenantID, attempt.AttemptID)
	if _, exists := r.attempts[attemptKey]; !exists {
		return ErrPaymentAttemptNotFound
	}

	idemKey := paymentAttemptIdempotencyKey(attempt.TenantID, attempt.IdempotencyKey)
	if existingAttemptID, exists := r.idemIndex[idemKey]; exists && existingAttemptID != attempt.AttemptID {
		return ErrPaymentAttemptIdempotencyConflict
	}

	r.attempts[attemptKey] = clonePaymentAttempt(attempt)
	r.idemIndex[idemKey] = attempt.AttemptID
	r.events[attemptKey] = clonePaymentAttemptEvents(attempt.Events)
	return nil
}

func (r *InMemoryPaymentAttemptRepository) FindByAttemptID(tenantID string, attemptID string) (PaymentAttempt, bool, error) {
	if strings.TrimSpace(tenantID) == "" {
		return PaymentAttempt{}, false, fmt.Errorf("%w: tenant id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(attemptID) == "" {
		return PaymentAttempt{}, false, fmt.Errorf("%w: attempt id is required", ErrInvalidPaymentAttempt)
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	attempt, exists := r.attempts[paymentAttemptRepositoryKey(tenantID, attemptID)]
	if !exists {
		return PaymentAttempt{}, false, nil
	}

	return clonePaymentAttempt(attempt), true, nil
}

func (r *InMemoryPaymentAttemptRepository) FindByIdempotencyKey(tenantID string, idempotencyKey string) (PaymentAttempt, bool, error) {
	if strings.TrimSpace(tenantID) == "" {
		return PaymentAttempt{}, false, fmt.Errorf("%w: tenant id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(idempotencyKey) == "" {
		return PaymentAttempt{}, false, fmt.Errorf("%w: idempotency key is required", ErrInvalidPaymentAttempt)
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	attemptID, exists := r.idemIndex[paymentAttemptIdempotencyKey(tenantID, idempotencyKey)]
	if !exists {
		return PaymentAttempt{}, false, nil
	}

	attempt, exists := r.attempts[paymentAttemptRepositoryKey(tenantID, attemptID)]
	if !exists {
		return PaymentAttempt{}, false, ErrPaymentAttemptNotFound
	}

	return clonePaymentAttempt(attempt), true, nil
}

func (r *InMemoryPaymentAttemptRepository) AppendEvent(tenantID string, attemptID string, event PaymentAttemptEvent) error {
	if strings.TrimSpace(tenantID) == "" {
		return fmt.Errorf("%w: tenant id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(attemptID) == "" {
		return fmt.Errorf("%w: attempt id is required", ErrInvalidPaymentAttempt)
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	attemptKey := paymentAttemptRepositoryKey(tenantID, attemptID)
	attempt, exists := r.attempts[attemptKey]
	if !exists {
		return ErrPaymentAttemptNotFound
	}

	attempt.Events = append(attempt.Events, event)
	r.attempts[attemptKey] = clonePaymentAttempt(attempt)
	r.events[attemptKey] = append(r.events[attemptKey], event)
	return nil
}

func (r *InMemoryPaymentAttemptRepository) ListEvents(tenantID string, attemptID string) ([]PaymentAttemptEvent, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, fmt.Errorf("%w: tenant id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(attemptID) == "" {
		return nil, fmt.Errorf("%w: attempt id is required", ErrInvalidPaymentAttempt)
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	attemptKey := paymentAttemptRepositoryKey(tenantID, attemptID)
	if _, exists := r.attempts[attemptKey]; !exists {
		return nil, ErrPaymentAttemptNotFound
	}

	return clonePaymentAttemptEvents(r.events[attemptKey]), nil
}

func validatePaymentAttemptForRepository(attempt PaymentAttempt) error {
	if strings.TrimSpace(attempt.AttemptID) == "" {
		return fmt.Errorf("%w: attempt id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(attempt.TenantID) == "" {
		return fmt.Errorf("%w: tenant id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(attempt.InvoiceID) == "" {
		return fmt.Errorf("%w: invoice id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(attempt.ProviderCode) == "" {
		return fmt.Errorf("%w: provider code is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(attempt.CorrelationID) == "" {
		return fmt.Errorf("%w: correlation id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(attempt.IdempotencyKey) == "" {
		return fmt.Errorf("%w: idempotency key is required", ErrInvalidPaymentAttempt)
	}
	if attempt.Money.AmountMinor <= 0 {
		return fmt.Errorf("%w: positive amount is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(attempt.Money.Currency) == "" {
		return fmt.Errorf("%w: currency is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(string(attempt.Status)) == "" {
		return fmt.Errorf("%w: status is required", ErrInvalidPaymentAttempt)
	}

	return nil
}

func paymentAttemptRepositoryKey(tenantID string, attemptID string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(attemptID)
}

func paymentAttemptIdempotencyKey(tenantID string, idempotencyKey string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(idempotencyKey)
}

func clonePaymentAttempt(attempt PaymentAttempt) PaymentAttempt {
	attempt.Events = clonePaymentAttemptEvents(attempt.Events)
	return attempt
}

func clonePaymentAttemptEvents(events []PaymentAttemptEvent) []PaymentAttemptEvent {
	if len(events) == 0 {
		return nil
	}

	cloned := make([]PaymentAttemptEvent, len(events))
	copy(cloned, events)
	return cloned
}
