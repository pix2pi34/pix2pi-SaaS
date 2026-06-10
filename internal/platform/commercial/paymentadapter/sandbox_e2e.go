package paymentadapter

import (
	"errors"
	"fmt"
	"strings"
)

var ErrPaymentSandboxE2EInvalidDependency = errors.New("payment sandbox e2e invalid dependency")
var ErrPaymentSandboxE2EInvalidRequest = errors.New("payment sandbox e2e invalid request")

type PaymentSandboxE2ERuntime struct {
	service  *PaymentService
	provider *SimulationPaymentProviderAdapter
	webhook  *PaymentWebhookIntakeRuntime
	repo     PaymentAttemptRepository
}

type PaymentSandboxE2ERoundtripRequest struct {
	PaymentRequest PaymentOperationRequest
	EventType      string
}

type PaymentSandboxE2ERoundtripResult struct {
	AuthorizeResult  PaymentOperationResult
	WebhookDelivery  SimulationWebhookDelivery
	WebhookResult    PaymentWebhookIntakeResult
	FinalAttempt     PaymentAttempt
	EventCountBefore int
	EventCountAfter  int
}

func NewPaymentSandboxE2ERuntime(
	service *PaymentService,
	provider *SimulationPaymentProviderAdapter,
	webhook *PaymentWebhookIntakeRuntime,
	repo PaymentAttemptRepository,
) (*PaymentSandboxE2ERuntime, error) {
	if service == nil {
		return nil, fmt.Errorf("%w: payment service is required", ErrPaymentSandboxE2EInvalidDependency)
	}
	if provider == nil {
		return nil, fmt.Errorf("%w: simulation provider is required", ErrPaymentSandboxE2EInvalidDependency)
	}
	if webhook == nil {
		return nil, fmt.Errorf("%w: webhook runtime is required", ErrPaymentSandboxE2EInvalidDependency)
	}
	if repo == nil {
		return nil, fmt.Errorf("%w: payment attempt repository is required", ErrPaymentSandboxE2EInvalidDependency)
	}
	if provider.Mode() == ModeProduction {
		return nil, fmt.Errorf("%w: production mode is forbidden for sandbox e2e", ErrPaymentSandboxE2EInvalidDependency)
	}

	return &PaymentSandboxE2ERuntime{
		service:  service,
		provider: provider,
		webhook:  webhook,
		repo:     repo,
	}, nil
}

func (r *PaymentSandboxE2ERuntime) AuthorizeWebhookRoundtrip(req PaymentSandboxE2ERoundtripRequest) (PaymentSandboxE2ERoundtripResult, error) {
	if strings.TrimSpace(req.EventType) == "" {
		return PaymentSandboxE2ERoundtripResult{}, fmt.Errorf("%w: event type is required", ErrPaymentSandboxE2EInvalidRequest)
	}
	if strings.TrimSpace(req.PaymentRequest.TenantID) == "" {
		return PaymentSandboxE2ERoundtripResult{}, fmt.Errorf("%w: tenant id is required", ErrPaymentSandboxE2EInvalidRequest)
	}
	if strings.TrimSpace(req.PaymentRequest.AttemptID) == "" {
		return PaymentSandboxE2ERoundtripResult{}, fmt.Errorf("%w: attempt id is required", ErrPaymentSandboxE2EInvalidRequest)
	}
	if strings.TrimSpace(req.PaymentRequest.CorrelationID) == "" {
		return PaymentSandboxE2ERoundtripResult{}, fmt.Errorf("%w: correlation id is required", ErrPaymentSandboxE2EInvalidRequest)
	}

	authorizeResult, err := r.service.Authorize(req.PaymentRequest)
	if err != nil {
		return PaymentSandboxE2ERoundtripResult{}, err
	}
	if authorizeResult.Attempt.Status != AttemptStatusAuthorized {
		return PaymentSandboxE2ERoundtripResult{}, fmt.Errorf("%w: authorize did not produce AUTHORIZED attempt", ErrPaymentSandboxE2EInvalidRequest)
	}
	if strings.TrimSpace(authorizeResult.Attempt.ProviderTransactionID) == "" {
		return PaymentSandboxE2ERoundtripResult{}, fmt.Errorf("%w: provider transaction id is required after authorize", ErrPaymentSandboxE2EInvalidRequest)
	}

	eventCountBefore := len(authorizeResult.Attempt.Events)

	delivery, err := r.provider.BuildWebhookDelivery(RequestContext{
		TenantID:       req.PaymentRequest.TenantID,
		SubscriptionID: req.PaymentRequest.SubscriptionID,
		CorrelationID:  req.PaymentRequest.CorrelationID,
		RequestID:      req.PaymentRequest.RequestID,
		IdempotencyKey: req.PaymentRequest.IdempotencyKey,
	}, req.PaymentRequest.AttemptID, authorizeResult.Attempt.ProviderTransactionID, req.EventType)
	if err != nil {
		return PaymentSandboxE2ERoundtripResult{}, err
	}

	webhookResult, err := r.webhook.VerifyAndRecord(PaymentWebhookIntakeRequest{
		TenantID:        req.PaymentRequest.TenantID,
		AttemptID:       req.PaymentRequest.AttemptID,
		ProviderCode:    delivery.ProviderCode,
		CorrelationID:   req.PaymentRequest.CorrelationID,
		RequestID:       req.PaymentRequest.RequestID,
		SignatureHeader: delivery.SignatureHeader,
		RawPayload:      delivery.RawPayload,
		ReceivedAt:      delivery.OccurredAt,
	})
	if err != nil {
		return PaymentSandboxE2ERoundtripResult{}, err
	}

	finalAttempt, exists, err := r.repo.FindByAttemptID(req.PaymentRequest.TenantID, req.PaymentRequest.AttemptID)
	if err != nil {
		return PaymentSandboxE2ERoundtripResult{}, err
	}
	if !exists {
		return PaymentSandboxE2ERoundtripResult{}, ErrPaymentAttemptNotFound
	}
	if finalAttempt.Status != AttemptStatusAuthorized {
		return PaymentSandboxE2ERoundtripResult{}, fmt.Errorf("%w: webhook roundtrip must not change authorized status", ErrPaymentSandboxE2EInvalidRequest)
	}
	if finalAttempt.ProviderTransactionID != authorizeResult.Attempt.ProviderTransactionID {
		return PaymentSandboxE2ERoundtripResult{}, fmt.Errorf("%w: provider transaction continuity failed", ErrPaymentSandboxE2EInvalidRequest)
	}

	eventCountAfter := len(finalAttempt.Events)
	if eventCountAfter <= eventCountBefore {
		return PaymentSandboxE2ERoundtripResult{}, fmt.Errorf("%w: webhook audit event was not appended", ErrPaymentSandboxE2EInvalidRequest)
	}

	return PaymentSandboxE2ERoundtripResult{
		AuthorizeResult:  authorizeResult,
		WebhookDelivery:  delivery,
		WebhookResult:    webhookResult,
		FinalAttempt:     finalAttempt,
		EventCountBefore: eventCountBefore,
		EventCountAfter:  eventCountAfter,
	}, nil
}
