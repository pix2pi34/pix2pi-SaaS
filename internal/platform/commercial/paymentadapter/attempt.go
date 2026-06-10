package paymentadapter

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type PaymentAttemptStatus string

const (
	AttemptStatusCreated    PaymentAttemptStatus = "CREATED"
	AttemptStatusAuthorized PaymentAttemptStatus = "AUTHORIZED"
	AttemptStatusCaptured   PaymentAttemptStatus = "CAPTURED"
	AttemptStatusRefunded   PaymentAttemptStatus = "REFUNDED"
	AttemptStatusVoided     PaymentAttemptStatus = "VOIDED"
	AttemptStatusFailed     PaymentAttemptStatus = "FAILED"
)

var (
	ErrInvalidPaymentAttempt       = errors.New("invalid payment attempt")
	ErrInvalidAttemptTransition    = errors.New("invalid payment attempt transition")
	ErrIdempotencyKeyMismatch      = errors.New("payment attempt idempotency key mismatch")
	ErrProviderTransactionMismatch = errors.New("payment provider transaction id mismatch")
)

type PaymentAttemptCreateRequest struct {
	AttemptID      string
	TenantID       string
	InvoiceID      string
	SubscriptionID string
	ProviderCode   string
	CorrelationID  string
	RequestID      string
	IdempotencyKey string
	Money          Money
}

type PaymentAttempt struct {
	AttemptID             string
	TenantID              string
	InvoiceID             string
	SubscriptionID        string
	ProviderCode          string
	CorrelationID         string
	RequestID             string
	IdempotencyKey        string
	Money                 Money
	Status                PaymentAttemptStatus
	ProviderTransactionID string
	FailureCode           ContractErrorCode
	FailureMessage        string
	Events                []PaymentAttemptEvent
}

type PaymentAttemptEvent struct {
	FromStatus            PaymentAttemptStatus
	ToStatus              PaymentAttemptStatus
	Operation             PaymentOperation
	ProviderCode          string
	ProviderTransactionID string
	ErrorCode             ContractErrorCode
	Message               string
	CorrelationID         string
	IdempotencyKey        string
	AuditRequired         bool
	RealPayment           bool
	OccurredAt            time.Time
}

func NewPaymentAttempt(req PaymentAttemptCreateRequest) (PaymentAttempt, error) {
	if strings.TrimSpace(req.AttemptID) == "" {
		return PaymentAttempt{}, fmt.Errorf("%w: attempt id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(req.TenantID) == "" {
		return PaymentAttempt{}, fmt.Errorf("%w: tenant id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(req.InvoiceID) == "" {
		return PaymentAttempt{}, fmt.Errorf("%w: invoice id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(req.ProviderCode) == "" {
		return PaymentAttempt{}, fmt.Errorf("%w: provider code is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return PaymentAttempt{}, fmt.Errorf("%w: correlation id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(req.IdempotencyKey) == "" {
		return PaymentAttempt{}, fmt.Errorf("%w: idempotency key is required", ErrInvalidPaymentAttempt)
	}
	if req.Money.AmountMinor <= 0 {
		return PaymentAttempt{}, fmt.Errorf("%w: positive amount is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(req.Money.Currency) == "" {
		return PaymentAttempt{}, fmt.Errorf("%w: currency is required", ErrInvalidPaymentAttempt)
	}

	attempt := PaymentAttempt{
		AttemptID:      req.AttemptID,
		TenantID:       req.TenantID,
		InvoiceID:      req.InvoiceID,
		SubscriptionID: req.SubscriptionID,
		ProviderCode:   req.ProviderCode,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey,
		Money:          req.Money,
		Status:         AttemptStatusCreated,
	}

	attempt.Events = append(attempt.Events, PaymentAttemptEvent{
		FromStatus:     "",
		ToStatus:       AttemptStatusCreated,
		Operation:      "",
		ProviderCode:   req.ProviderCode,
		Message:        "payment attempt created",
		CorrelationID:  req.CorrelationID,
		IdempotencyKey: req.IdempotencyKey,
		AuditRequired:  true,
		RealPayment:    false,
		OccurredAt:     time.Now().UTC(),
	})

	return attempt, nil
}

func (a PaymentAttempt) ValidateIdempotencyReplay(idempotencyKey string) error {
	if strings.TrimSpace(idempotencyKey) == "" {
		return ErrIdempotencyKeyMismatch
	}
	if idempotencyKey != a.IdempotencyKey {
		return ErrIdempotencyKeyMismatch
	}
	return nil
}

func (a PaymentAttempt) ApplyContractDecision(decision OperationContractDecision, providerTransactionID string) (PaymentAttempt, error) {
	if err := EnsureContractDecisionIsAuditable(decision); err != nil {
		return a, err
	}
	if strings.TrimSpace(decision.ProviderCode) != "" && decision.ProviderCode != a.ProviderCode {
		return a, ErrProviderTransactionMismatch
	}

	if !decision.Allowed {
		return a.failFromDecision(decision, providerTransactionID), nil
	}

	switch decision.Operation {
	case OperationAuthorize:
		return a.authorize(decision, providerTransactionID)
	case OperationCapture:
		return a.capture(decision, providerTransactionID)
	case OperationRefund:
		return a.refund(decision, providerTransactionID)
	case OperationVoid:
		return a.void(decision, providerTransactionID)
	case OperationWebhookVerify:
		return a.recordWebhookVerified(decision), nil
	default:
		return a, fmt.Errorf("%w: unsupported operation %s", ErrInvalidAttemptTransition, decision.Operation)
	}
}

func (a PaymentAttempt) authorize(decision OperationContractDecision, providerTransactionID string) (PaymentAttempt, error) {
	if a.Status != AttemptStatusCreated {
		return a, fmt.Errorf("%w: authorize requires CREATED status", ErrInvalidAttemptTransition)
	}
	if strings.TrimSpace(providerTransactionID) == "" {
		return a, fmt.Errorf("%w: provider transaction id is required for authorization", ErrInvalidPaymentAttempt)
	}

	a.ProviderTransactionID = providerTransactionID
	return a.transition(AttemptStatusAuthorized, decision, providerTransactionID, ErrorNone, "payment authorized"), nil
}

func (a PaymentAttempt) capture(decision OperationContractDecision, providerTransactionID string) (PaymentAttempt, error) {
	if a.Status != AttemptStatusAuthorized {
		return a, fmt.Errorf("%w: capture requires AUTHORIZED status", ErrInvalidAttemptTransition)
	}
	if err := a.ensureProviderTransaction(providerTransactionID); err != nil {
		return a, err
	}

	return a.transition(AttemptStatusCaptured, decision, a.ProviderTransactionID, ErrorNone, "payment captured"), nil
}

func (a PaymentAttempt) refund(decision OperationContractDecision, providerTransactionID string) (PaymentAttempt, error) {
	if a.Status != AttemptStatusCaptured {
		return a, fmt.Errorf("%w: refund requires CAPTURED status", ErrInvalidAttemptTransition)
	}
	if err := a.ensureProviderTransaction(providerTransactionID); err != nil {
		return a, err
	}

	return a.transition(AttemptStatusRefunded, decision, a.ProviderTransactionID, ErrorNone, "payment refunded"), nil
}

func (a PaymentAttempt) void(decision OperationContractDecision, providerTransactionID string) (PaymentAttempt, error) {
	if a.Status != AttemptStatusAuthorized {
		return a, fmt.Errorf("%w: void requires AUTHORIZED status", ErrInvalidAttemptTransition)
	}
	if err := a.ensureProviderTransaction(providerTransactionID); err != nil {
		return a, err
	}

	return a.transition(AttemptStatusVoided, decision, a.ProviderTransactionID, ErrorNone, "payment voided"), nil
}

func (a PaymentAttempt) recordWebhookVerified(decision OperationContractDecision) PaymentAttempt {
	return a.transition(a.Status, decision, a.ProviderTransactionID, ErrorNone, "payment webhook verified")
}

func (a PaymentAttempt) failFromDecision(decision OperationContractDecision, providerTransactionID string) PaymentAttempt {
	message := decision.Message
	if strings.TrimSpace(message) == "" {
		message = "payment operation failed"
	}

	a.FailureCode = decision.ErrorCode
	a.FailureMessage = message
	return a.transition(AttemptStatusFailed, decision, providerTransactionID, decision.ErrorCode, message)
}

func (a PaymentAttempt) ensureProviderTransaction(providerTransactionID string) error {
	if strings.TrimSpace(a.ProviderTransactionID) == "" {
		return fmt.Errorf("%w: existing provider transaction id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(providerTransactionID) == "" {
		return fmt.Errorf("%w: provider transaction id is required", ErrInvalidPaymentAttempt)
	}
	if providerTransactionID != a.ProviderTransactionID {
		return ErrProviderTransactionMismatch
	}
	return nil
}

func (a PaymentAttempt) transition(to PaymentAttemptStatus, decision OperationContractDecision, providerTransactionID string, errorCode ContractErrorCode, message string) PaymentAttempt {
	from := a.Status
	a.Status = to

	if strings.TrimSpace(providerTransactionID) != "" {
		a.ProviderTransactionID = providerTransactionID
	}

	if errorCode != ErrorNone {
		a.FailureCode = errorCode
		a.FailureMessage = message
	}

	a.Events = append(a.Events, PaymentAttemptEvent{
		FromStatus:            from,
		ToStatus:              to,
		Operation:             decision.Operation,
		ProviderCode:          a.ProviderCode,
		ProviderTransactionID: providerTransactionID,
		ErrorCode:             errorCode,
		Message:               message,
		CorrelationID:         a.CorrelationID,
		IdempotencyKey:        a.IdempotencyKey,
		AuditRequired:         decision.AuditRequired,
		RealPayment:           decision.RealPayment,
		OccurredAt:            time.Now().UTC(),
	})

	return a
}

func PaymentAttemptStatuses() []PaymentAttemptStatus {
	return []PaymentAttemptStatus{
		AttemptStatusCreated,
		AttemptStatusAuthorized,
		AttemptStatusCaptured,
		AttemptStatusRefunded,
		AttemptStatusVoided,
		AttemptStatusFailed,
	}
}
