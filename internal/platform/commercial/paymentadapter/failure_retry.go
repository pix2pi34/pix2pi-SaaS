package paymentadapter

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

var ErrPaymentFailureRetryInvalidDependency = errors.New("payment failure retry invalid dependency")
var ErrPaymentFailureRetryInvalidRequest = errors.New("payment failure retry invalid request")

type PaymentRetryDecisionStatus string

const (
	RetryDecisionAllowed      PaymentRetryDecisionStatus = "RETRY_ALLOWED"
	RetryDecisionDenied       PaymentRetryDecisionStatus = "RETRY_DENIED"
	RetryDecisionNonRetryable PaymentRetryDecisionStatus = "NON_RETRYABLE"
	RetryDecisionDuplicate    PaymentRetryDecisionStatus = "DUPLICATE_IGNORED"
)

type PaymentRetryPolicy struct {
	MaxAttempts         int
	RetryableErrorCodes map[ContractErrorCode]bool
}

type PaymentRetryDecision struct {
	Status        PaymentRetryDecisionStatus
	ErrorCode     ContractErrorCode
	AttemptNumber int
	MaxAttempts   int
	Retryable     bool
	Message       string
}

type PaymentFailureRetryRuntime struct {
	service      *PaymentService
	repo         PaymentAttemptRepository
	webhook      *PaymentWebhookIntakeRuntime
	policy       PaymentRetryPolicy
	seenWebhooks map[string]bool
	now          func() time.Time
}

type PaymentWebhookOnceResult struct {
	Result     PaymentWebhookIntakeResult
	Attempt    PaymentAttempt
	Duplicate  bool
	EventCount int
	Message    string
}

func DefaultPaymentRetryPolicy() PaymentRetryPolicy {
	return PaymentRetryPolicy{
		MaxAttempts: 3,
		RetryableErrorCodes: map[ContractErrorCode]bool{
			ErrorProviderTransactionRequired: true,
			ErrorAmountRequired:              true,
			ErrorCurrencyRequired:            true,
		},
	}
}

func NewPaymentFailureRetryRuntime(service *PaymentService, repo PaymentAttemptRepository, webhook *PaymentWebhookIntakeRuntime, policy PaymentRetryPolicy) (*PaymentFailureRetryRuntime, error) {
	if service == nil {
		return nil, fmt.Errorf("%w: payment service is required", ErrPaymentFailureRetryInvalidDependency)
	}
	if repo == nil {
		return nil, fmt.Errorf("%w: payment attempt repository is required", ErrPaymentFailureRetryInvalidDependency)
	}
	if webhook == nil {
		return nil, fmt.Errorf("%w: webhook runtime is required", ErrPaymentFailureRetryInvalidDependency)
	}
	if policy.MaxAttempts <= 0 {
		policy = DefaultPaymentRetryPolicy()
	}
	if policy.RetryableErrorCodes == nil {
		defaultPolicy := DefaultPaymentRetryPolicy()
		policy.RetryableErrorCodes = defaultPolicy.RetryableErrorCodes
	}

	return &PaymentFailureRetryRuntime{
		service:      service,
		repo:         repo,
		webhook:      webhook,
		policy:       policy,
		seenWebhooks: map[string]bool{},
		now:          func() time.Time { return time.Now().UTC() },
	}, nil
}

func (r *PaymentFailureRetryRuntime) AuthorizeWithReplay(req PaymentOperationRequest) (PaymentOperationResult, error) {
	if strings.TrimSpace(req.TenantID) == "" {
		return PaymentOperationResult{}, fmt.Errorf("%w: tenant id is required", ErrPaymentFailureRetryInvalidRequest)
	}
	if strings.TrimSpace(req.IdempotencyKey) == "" {
		return PaymentOperationResult{}, fmt.Errorf("%w: idempotency key is required", ErrPaymentFailureRetryInvalidRequest)
	}

	return r.service.Authorize(req)
}

func (r *PaymentFailureRetryRuntime) EvaluateRetry(errorCode ContractErrorCode, attemptNumber int) PaymentRetryDecision {
	decision := PaymentRetryDecision{
		Status:        RetryDecisionDenied,
		ErrorCode:     errorCode,
		AttemptNumber: attemptNumber,
		MaxAttempts:   r.policy.MaxAttempts,
		Retryable:     false,
		Message:       "retry denied",
	}

	if attemptNumber >= r.policy.MaxAttempts {
		decision.Status = RetryDecisionDenied
		decision.Message = "retry limit reached"
		return decision
	}

	if r.policy.RetryableErrorCodes[errorCode] {
		decision.Status = RetryDecisionAllowed
		decision.Retryable = true
		decision.Message = "retry allowed"
		return decision
	}

	decision.Status = RetryDecisionNonRetryable
	decision.Message = "payment error is non-retryable"
	return decision
}

func (r *PaymentFailureRetryRuntime) VerifyWebhookOnce(dedupeKey string, req PaymentWebhookIntakeRequest) (PaymentWebhookOnceResult, error) {
	if strings.TrimSpace(dedupeKey) == "" {
		return PaymentWebhookOnceResult{}, fmt.Errorf("%w: webhook dedupe key is required", ErrPaymentFailureRetryInvalidRequest)
	}
	if strings.TrimSpace(req.TenantID) == "" {
		return PaymentWebhookOnceResult{}, fmt.Errorf("%w: tenant id is required", ErrPaymentFailureRetryInvalidRequest)
	}
	if strings.TrimSpace(req.AttemptID) == "" {
		return PaymentWebhookOnceResult{}, fmt.Errorf("%w: attempt id is required", ErrPaymentFailureRetryInvalidRequest)
	}

	if r.seenWebhooks[dedupeKey] {
		attempt, exists, err := r.repo.FindByAttemptID(req.TenantID, req.AttemptID)
		if err != nil {
			return PaymentWebhookOnceResult{}, err
		}
		if !exists {
			return PaymentWebhookOnceResult{}, ErrPaymentAttemptNotFound
		}

		return PaymentWebhookOnceResult{
			Attempt:    attempt,
			Duplicate:  true,
			EventCount: len(attempt.Events),
			Message:    "duplicate webhook ignored",
		}, nil
	}

	result, err := r.webhook.VerifyAndRecord(req)
	if err != nil {
		return PaymentWebhookOnceResult{}, err
	}

	r.seenWebhooks[dedupeKey] = true

	attempt, exists, err := r.repo.FindByAttemptID(req.TenantID, req.AttemptID)
	if err != nil {
		return PaymentWebhookOnceResult{}, err
	}
	if !exists {
		return PaymentWebhookOnceResult{}, ErrPaymentAttemptNotFound
	}

	return PaymentWebhookOnceResult{
		Result:     result,
		Attempt:    attempt,
		Duplicate:  false,
		EventCount: len(attempt.Events),
		Message:    "webhook verified and recorded",
	}, nil
}
