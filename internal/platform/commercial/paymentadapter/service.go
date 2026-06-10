package paymentadapter

import (
	"errors"
	"fmt"
	"strings"
)

var ErrPaymentServiceInvalidDependency = errors.New("payment service invalid dependency")

type PaymentService struct {
	provider PaymentProviderAdapter
	matrix   ProviderCapabilityMatrix
	repo     PaymentAttemptRepository
}

type PaymentOperationRequest struct {
	AttemptID             string
	TenantID              string
	InvoiceID             string
	SubscriptionID        string
	CorrelationID         string
	RequestID             string
	IdempotencyKey        string
	Money                 Money
	ProviderTransactionID string
	WebhookSignature      string
	RawWebhookPayload     []byte
}

type PaymentOperationResult struct {
	Attempt  PaymentAttempt
	Decision OperationContractDecision
	Replay   bool
}

func NewPaymentService(provider PaymentProviderAdapter, matrix ProviderCapabilityMatrix, repo PaymentAttemptRepository) (*PaymentService, error) {
	if provider == nil {
		return nil, fmt.Errorf("%w: provider adapter is required", ErrPaymentServiceInvalidDependency)
	}
	if repo == nil {
		return nil, fmt.Errorf("%w: payment attempt repository is required", ErrPaymentServiceInvalidDependency)
	}
	if strings.TrimSpace(matrix.ProviderCode) == "" {
		return nil, fmt.Errorf("%w: provider capability matrix provider code is required", ErrPaymentServiceInvalidDependency)
	}
	if provider.Code() != matrix.ProviderCode {
		return nil, fmt.Errorf("%w: provider code mismatch", ErrPaymentServiceInvalidDependency)
	}
	if provider.Mode() != matrix.Mode {
		return nil, fmt.Errorf("%w: provider mode mismatch", ErrPaymentServiceInvalidDependency)
	}

	return &PaymentService{
		provider: provider,
		matrix:   matrix,
		repo:     repo,
	}, nil
}

func (s *PaymentService) Authorize(req PaymentOperationRequest) (PaymentOperationResult, error) {
	existing, found, err := s.repo.FindByIdempotencyKey(req.TenantID, req.IdempotencyKey)
	if err == nil && found {
		if replayErr := existing.ValidateIdempotencyReplay(req.IdempotencyKey); replayErr != nil {
			return PaymentOperationResult{}, replayErr
		}

		return PaymentOperationResult{
			Attempt: existing,
			Replay:  true,
		}, nil
	}
	if err != nil && !errors.Is(err, ErrInvalidPaymentAttempt) {
		return PaymentOperationResult{}, err
	}

	attempt, err := NewPaymentAttempt(PaymentAttemptCreateRequest{
		AttemptID:      req.AttemptID,
		TenantID:       req.TenantID,
		InvoiceID:      req.InvoiceID,
		SubscriptionID: req.SubscriptionID,
		ProviderCode:   s.provider.Code(),
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey,
		Money:          req.Money,
	})
	if err != nil {
		return PaymentOperationResult{}, err
	}

	decision := s.validateOperation(req, OperationAuthorize)
	providerTransactionID := req.ProviderTransactionID
	if decision.Allowed && strings.TrimSpace(providerTransactionID) == "" {
		providerTransactionID = simulationProviderTransactionID(req.AttemptID)
	}

	next, err := attempt.ApplyContractDecision(decision, providerTransactionID)
	if err != nil {
		return PaymentOperationResult{}, err
	}

	if err := s.repo.Save(next); err != nil {
		return PaymentOperationResult{}, err
	}

	return PaymentOperationResult{
		Attempt:  next,
		Decision: decision,
		Replay:   false,
	}, nil
}

func (s *PaymentService) Capture(req PaymentOperationRequest) (PaymentOperationResult, error) {
	return s.applyExistingAttemptOperation(req, OperationCapture)
}

func (s *PaymentService) Refund(req PaymentOperationRequest) (PaymentOperationResult, error) {
	return s.applyExistingAttemptOperation(req, OperationRefund)
}

func (s *PaymentService) Void(req PaymentOperationRequest) (PaymentOperationResult, error) {
	return s.applyExistingAttemptOperation(req, OperationVoid)
}

func (s *PaymentService) VerifyWebhook(req PaymentOperationRequest) (PaymentOperationResult, error) {
	return s.applyExistingAttemptOperation(req, OperationWebhookVerify)
}

func (s *PaymentService) applyExistingAttemptOperation(req PaymentOperationRequest, operation PaymentOperation) (PaymentOperationResult, error) {
	attempt, found, err := s.repo.FindByAttemptID(req.TenantID, req.AttemptID)
	if err != nil {
		return PaymentOperationResult{}, err
	}
	if !found {
		return PaymentOperationResult{}, ErrPaymentAttemptNotFound
	}

	decision := s.validateOperation(req, operation)
	next, err := attempt.ApplyContractDecision(decision, req.ProviderTransactionID)
	if err != nil {
		return PaymentOperationResult{}, err
	}

	if err := s.repo.Update(next); err != nil {
		return PaymentOperationResult{}, err
	}

	return PaymentOperationResult{
		Attempt:  next,
		Decision: decision,
		Replay:   false,
	}, nil
}

func (s *PaymentService) validateOperation(req PaymentOperationRequest, operation PaymentOperation) OperationContractDecision {
	return s.matrix.ValidateRequest(OperationContractRequest{
		ProviderCode:          s.provider.Code(),
		TenantID:              req.TenantID,
		CorrelationID:         req.CorrelationID,
		RequestID:             req.RequestID,
		IdempotencyKey:        req.IdempotencyKey,
		Operation:             operation,
		Money:                 req.Money,
		ProviderTransactionID: req.ProviderTransactionID,
		WebhookSignature:      req.WebhookSignature,
		RawWebhookPayload:     req.RawWebhookPayload,
	})
}

func simulationProviderTransactionID(attemptID string) string {
	trimmed := strings.TrimSpace(attemptID)
	if trimmed == "" {
		return ""
	}

	return "sim_provider_txn_" + trimmed
}
