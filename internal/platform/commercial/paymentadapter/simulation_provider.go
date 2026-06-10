package paymentadapter

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

var (
	ErrSimulationProviderInvalidConfig = errors.New("simulation provider invalid config")
	ErrSimulationProviderDenied        = errors.New("simulation provider denied")
)

type SimulationPaymentProviderAdapter struct {
	base          *ProviderAdapter
	matrix        ProviderCapabilityMatrix
	webhookSecret string
	now           func() time.Time
}

type SimulationProviderOperationResult struct {
	Decision              OperationContractDecision
	Operation             PaymentOperation
	ProviderCode          string
	ProviderTransactionID string
	Status                PaymentAttemptStatus
	Approved              bool
	Message               string
	OccurredAt            time.Time
}

type SimulationWebhookDelivery struct {
	ProviderCode          string
	TenantID              string
	AttemptID             string
	ProviderTransactionID string
	EventType             string
	RawPayload            []byte
	SignatureHeader       string
	OccurredAt            time.Time
}

func NewSimulationPaymentProviderAdapter(cfg ProviderConfig, webhookSecret string) (*SimulationPaymentProviderAdapter, error) {
	if cfg.Mode == string(ModeProduction) {
		return nil, fmt.Errorf("%w: production mode is not allowed for simulation provider", ErrSimulationProviderInvalidConfig)
	}
	if cfg.RealPaymentEnabled {
		return nil, fmt.Errorf("%w: real payment must be disabled for simulation provider", ErrSimulationProviderInvalidConfig)
	}
	if strings.TrimSpace(webhookSecret) == "" {
		return nil, fmt.Errorf("%w: webhook secret is required", ErrSimulationProviderInvalidConfig)
	}

	base, err := NewProviderAdapter(cfg)
	if err != nil {
		return nil, err
	}

	matrix, err := NewProviderCapabilityMatrix(cfg)
	if err != nil {
		return nil, err
	}

	return &SimulationPaymentProviderAdapter{
		base:          base,
		matrix:        matrix,
		webhookSecret: webhookSecret,
		now:           func() time.Time { return time.Now().UTC() },
	}, nil
}

func (a *SimulationPaymentProviderAdapter) Code() string {
	return a.base.Code()
}

func (a *SimulationPaymentProviderAdapter) Mode() ProviderMode {
	return a.base.Mode()
}

func (a *SimulationPaymentProviderAdapter) Evaluate(ctx RequestContext, op PaymentOperation, money Money) Decision {
	return a.base.Evaluate(ctx, op, money)
}

func (a *SimulationPaymentProviderAdapter) Authorize(ctx RequestContext, attemptID string, money Money) (SimulationProviderOperationResult, error) {
	decision := a.validate(ctx, OperationAuthorize, money, "")
	if !decision.Allowed {
		return a.deniedResult(decision, OperationAuthorize), nil
	}

	providerTransactionID := a.providerTransactionID(ctx.TenantID, attemptID, OperationAuthorize)
	return a.allowedResult(decision, OperationAuthorize, providerTransactionID, AttemptStatusAuthorized, "simulation payment authorized"), nil
}

func (a *SimulationPaymentProviderAdapter) Capture(ctx RequestContext, providerTransactionID string, money Money) (SimulationProviderOperationResult, error) {
	decision := a.validate(ctx, OperationCapture, money, providerTransactionID)
	if !decision.Allowed {
		return a.deniedResult(decision, OperationCapture), nil
	}

	return a.allowedResult(decision, OperationCapture, providerTransactionID, AttemptStatusCaptured, "simulation payment captured"), nil
}

func (a *SimulationPaymentProviderAdapter) Refund(ctx RequestContext, providerTransactionID string, money Money) (SimulationProviderOperationResult, error) {
	decision := a.validate(ctx, OperationRefund, money, providerTransactionID)
	if !decision.Allowed {
		return a.deniedResult(decision, OperationRefund), nil
	}

	return a.allowedResult(decision, OperationRefund, providerTransactionID, AttemptStatusRefunded, "simulation payment refunded"), nil
}

func (a *SimulationPaymentProviderAdapter) Void(ctx RequestContext, providerTransactionID string) (SimulationProviderOperationResult, error) {
	decision := a.validate(ctx, OperationVoid, Money{}, providerTransactionID)
	if !decision.Allowed {
		return a.deniedResult(decision, OperationVoid), nil
	}

	return a.allowedResult(decision, OperationVoid, providerTransactionID, AttemptStatusVoided, "simulation payment voided"), nil
}

func (a *SimulationPaymentProviderAdapter) BuildWebhookDelivery(ctx RequestContext, attemptID string, providerTransactionID string, eventType string) (SimulationWebhookDelivery, error) {
	if strings.TrimSpace(ctx.TenantID) == "" {
		return SimulationWebhookDelivery{}, fmt.Errorf("%w: tenant id is required", ErrSimulationProviderDenied)
	}
	if strings.TrimSpace(attemptID) == "" {
		return SimulationWebhookDelivery{}, fmt.Errorf("%w: attempt id is required", ErrSimulationProviderDenied)
	}
	if strings.TrimSpace(providerTransactionID) == "" {
		return SimulationWebhookDelivery{}, fmt.Errorf("%w: provider transaction id is required", ErrSimulationProviderDenied)
	}
	if strings.TrimSpace(eventType) == "" {
		return SimulationWebhookDelivery{}, fmt.Errorf("%w: event type is required", ErrSimulationProviderDenied)
	}

	occurredAt := a.now().UTC()
	payload := []byte(fmt.Sprintf(
		`{"provider_code":"%s","tenant_id":"%s","attempt_id":"%s","provider_transaction_id":"%s","event_type":"%s","occurred_at":"%s"}`,
		a.Code(),
		ctx.TenantID,
		attemptID,
		providerTransactionID,
		eventType,
		occurredAt.Format(time.RFC3339),
	))

	return SimulationWebhookDelivery{
		ProviderCode:          a.Code(),
		TenantID:              ctx.TenantID,
		AttemptID:             attemptID,
		ProviderTransactionID: providerTransactionID,
		EventType:             eventType,
		RawPayload:            payload,
		SignatureHeader:       BuildPaymentWebhookSignatureHeader(a.webhookSecret, occurredAt, payload),
		OccurredAt:            occurredAt,
	}, nil
}

func (a *SimulationPaymentProviderAdapter) validate(ctx RequestContext, operation PaymentOperation, money Money, providerTransactionID string) OperationContractDecision {
	return a.matrix.ValidateRequest(OperationContractRequest{
		ProviderCode:          a.Code(),
		TenantID:              ctx.TenantID,
		CorrelationID:         ctx.CorrelationID,
		RequestID:             ctx.RequestID,
		IdempotencyKey:        ctx.IdempotencyKey,
		Operation:             operation,
		Money:                 money,
		ProviderTransactionID: providerTransactionID,
	})
}

func (a *SimulationPaymentProviderAdapter) allowedResult(decision OperationContractDecision, operation PaymentOperation, providerTransactionID string, status PaymentAttemptStatus, message string) SimulationProviderOperationResult {
	return SimulationProviderOperationResult{
		Decision:              decision,
		Operation:             operation,
		ProviderCode:          a.Code(),
		ProviderTransactionID: providerTransactionID,
		Status:                status,
		Approved:              true,
		Message:               message,
		OccurredAt:            a.now().UTC(),
	}
}

func (a *SimulationPaymentProviderAdapter) deniedResult(decision OperationContractDecision, operation PaymentOperation) SimulationProviderOperationResult {
	return SimulationProviderOperationResult{
		Decision:     decision,
		Operation:    operation,
		ProviderCode: a.Code(),
		Status:       AttemptStatusFailed,
		Approved:     false,
		Message:      decision.Message,
		OccurredAt:   a.now().UTC(),
	}
}

func (a *SimulationPaymentProviderAdapter) providerTransactionID(tenantID string, attemptID string, operation PaymentOperation) string {
	return "sim_" + sanitizeSimulationToken(tenantID) + "_" + sanitizeSimulationToken(attemptID) + "_" + strings.ToLower(string(operation))
}

func sanitizeSimulationToken(value string) string {
	trimmed := strings.TrimSpace(value)
	replacer := strings.NewReplacer(" ", "_", "/", "_", "\\", "_", ":", "_")
	return replacer.Replace(trimmed)
}
