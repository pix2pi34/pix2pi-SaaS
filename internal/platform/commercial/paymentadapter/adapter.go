package paymentadapter

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
)

type ProviderMode string

const (
	ModeSimulation ProviderMode = "SIMULATION"
	ModeSandbox    ProviderMode = "SANDBOX"
	ModeProduction ProviderMode = "PRODUCTION"
)

type PaymentOperation string

const (
	OperationAuthorize     PaymentOperation = "AUTHORIZE"
	OperationCapture       PaymentOperation = "CAPTURE"
	OperationRefund        PaymentOperation = "REFUND"
	OperationVoid          PaymentOperation = "VOID"
	OperationWebhookVerify PaymentOperation = "WEBHOOK_VERIFY"
)

type Money struct {
	AmountMinor int64  `json:"amount_minor"`
	Currency    string `json:"currency"`
}

type RequestContext struct {
	TenantID       string `json:"tenant_id"`
	SubscriptionID string `json:"subscription_id"`
	PlanCode       string `json:"plan_code"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`
}

type ProviderConfig struct {
	ProviderName       string   `json:"provider_name"`
	ProviderCode       string   `json:"provider_code"`
	Mode               string   `json:"mode"`
	RealPaymentEnabled bool     `json:"real_payment_enabled"`
	AllowedOperations  []string `json:"allowed_operations"`
	SettlementCurrency string   `json:"settlement_currency"`
	WebhookRequired    bool     `json:"webhook_required"`
	AuditEnabled       bool     `json:"audit_enabled"`
}

type Decision struct {
	Allowed       bool             `json:"allowed"`
	ProviderCode  string           `json:"provider_code"`
	Mode          ProviderMode     `json:"mode"`
	Operation     PaymentOperation `json:"operation"`
	Reason        string           `json:"reason"`
	AuditRequired bool             `json:"audit_required"`
	RealPayment   bool             `json:"real_payment"`
}

type PaymentProviderAdapter interface {
	Code() string
	Mode() ProviderMode
	Evaluate(ctx RequestContext, op PaymentOperation, money Money) Decision
}

type ProviderAdapter struct {
	config     ProviderConfig
	mode       ProviderMode
	operations map[PaymentOperation]bool
}

func LoadProviderConfig(raw []byte) (ProviderConfig, error) {
	var cfg ProviderConfig
	if err := json.Unmarshal(raw, &cfg); err != nil {
		return ProviderConfig{}, fmt.Errorf("payment provider config parse failed: %w", err)
	}
	return cfg, nil
}

func NewProviderAdapter(cfg ProviderConfig) (*ProviderAdapter, error) {
	mode, err := normalizeMode(cfg.Mode)
	if err != nil {
		return nil, err
	}
	if strings.TrimSpace(cfg.ProviderName) == "" {
		return nil, errors.New("provider name is required")
	}
	if strings.TrimSpace(cfg.ProviderCode) == "" {
		return nil, errors.New("provider code is required")
	}
	if strings.TrimSpace(cfg.SettlementCurrency) == "" {
		return nil, errors.New("settlement currency is required")
	}
	if len(cfg.AllowedOperations) == 0 {
		return nil, errors.New("at least one allowed operation is required")
	}

	operations := make(map[PaymentOperation]bool, len(cfg.AllowedOperations))
	for _, op := range cfg.AllowedOperations {
		normalized, err := normalizeOperation(op)
		if err != nil {
			return nil, err
		}
		operations[normalized] = true
	}

	return &ProviderAdapter{config: cfg, mode: mode, operations: operations}, nil
}

func (a *ProviderAdapter) Code() string {
	return a.config.ProviderCode
}

func (a *ProviderAdapter) Mode() ProviderMode {
	return a.mode
}

func (a *ProviderAdapter) Evaluate(ctx RequestContext, op PaymentOperation, money Money) Decision {
	decision := Decision{
		Allowed:       false,
		ProviderCode:  a.config.ProviderCode,
		Mode:          a.mode,
		Operation:     op,
		AuditRequired: a.config.AuditEnabled,
		RealPayment:   false,
	}

	if strings.TrimSpace(ctx.TenantID) == "" {
		decision.Reason = "tenant context is required"
		return decision
	}
	if strings.TrimSpace(ctx.CorrelationID) == "" {
		decision.Reason = "correlation id is required"
		return decision
	}
	if op != OperationWebhookVerify && strings.TrimSpace(ctx.IdempotencyKey) == "" {
		decision.Reason = "idempotency key is required"
		return decision
	}
	if op != OperationWebhookVerify && money.AmountMinor <= 0 {
		decision.Reason = "positive amount is required"
		return decision
	}
	if op != OperationWebhookVerify && strings.TrimSpace(money.Currency) == "" {
		decision.Reason = "currency is required"
		return decision
	}
	if !a.operations[op] {
		decision.Reason = "operation is not allowed for provider"
		return decision
	}
	if a.mode == ModeProduction && !a.config.RealPaymentEnabled {
		decision.Reason = "production real payment gate is closed"
		return decision
	}

	decision.Allowed = true
	decision.RealPayment = a.mode == ModeProduction && a.config.RealPaymentEnabled
	decision.Reason = "payment provider adapter decision allowed"
	return decision
}

func normalizeMode(value string) (ProviderMode, error) {
	switch ProviderMode(strings.ToUpper(strings.TrimSpace(value))) {
	case ModeSimulation:
		return ModeSimulation, nil
	case ModeSandbox:
		return ModeSandbox, nil
	case ModeProduction:
		return ModeProduction, nil
	default:
		return "", fmt.Errorf("unsupported provider mode: %s", value)
	}
}

func normalizeOperation(value string) (PaymentOperation, error) {
	switch PaymentOperation(strings.ToUpper(strings.TrimSpace(value))) {
	case OperationAuthorize:
		return OperationAuthorize, nil
	case OperationCapture:
		return OperationCapture, nil
	case OperationRefund:
		return OperationRefund, nil
	case OperationVoid:
		return OperationVoid, nil
	case OperationWebhookVerify:
		return OperationWebhookVerify, nil
	default:
		return "", fmt.Errorf("unsupported payment operation: %s", value)
	}
}
