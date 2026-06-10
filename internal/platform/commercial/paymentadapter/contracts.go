package paymentadapter

import (
	"errors"
	"fmt"
	"strings"
)

type ContractStatus string

const (
	ContractStatusAccepted ContractStatus = "ACCEPTED"
	ContractStatusDenied   ContractStatus = "DENIED"
)

type ContractErrorCode string

const (
	ErrorNone                        ContractErrorCode = ""
	ErrorTenantRequired              ContractErrorCode = "PAYMENT_TENANT_REQUIRED"
	ErrorCorrelationRequired         ContractErrorCode = "PAYMENT_CORRELATION_REQUIRED"
	ErrorIdempotencyRequired         ContractErrorCode = "PAYMENT_IDEMPOTENCY_REQUIRED"
	ErrorAmountRequired              ContractErrorCode = "PAYMENT_AMOUNT_REQUIRED"
	ErrorCurrencyRequired            ContractErrorCode = "PAYMENT_CURRENCY_REQUIRED"
	ErrorProviderTransactionRequired ContractErrorCode = "PAYMENT_PROVIDER_TRANSACTION_REQUIRED"
	ErrorWebhookSignatureRequired    ContractErrorCode = "PAYMENT_WEBHOOK_SIGNATURE_REQUIRED"
	ErrorWebhookPayloadRequired      ContractErrorCode = "PAYMENT_WEBHOOK_PAYLOAD_REQUIRED"
	ErrorOperationUnsupported        ContractErrorCode = "PAYMENT_OPERATION_UNSUPPORTED"
	ErrorProviderMismatch            ContractErrorCode = "PAYMENT_PROVIDER_MISMATCH"
	ErrorProductionGateClosed        ContractErrorCode = "PAYMENT_PRODUCTION_GATE_CLOSED"
)

type OperationContract struct {
	Operation                     PaymentOperation `json:"operation"`
	Supported                     bool             `json:"supported"`
	RequiresAmount                bool             `json:"requires_amount"`
	RequiresCurrency              bool             `json:"requires_currency"`
	RequiresIdempotencyKey        bool             `json:"requires_idempotency_key"`
	RequiresProviderTransactionID bool             `json:"requires_provider_transaction_id"`
	RequiresWebhookSignature      bool             `json:"requires_webhook_signature"`
	RequiresRawWebhookPayload     bool             `json:"requires_raw_webhook_payload"`
	Retryable                     bool             `json:"retryable"`
	Reversible                    bool             `json:"reversible"`
}

type ProviderCapabilityMatrix struct {
	ProviderCode       string
	Mode               ProviderMode
	RealPaymentEnabled bool
	AuditRequired      bool
	Contracts          map[PaymentOperation]OperationContract
}

type OperationContractRequest struct {
	ProviderCode          string
	TenantID              string
	CorrelationID         string
	RequestID             string
	IdempotencyKey        string
	Operation             PaymentOperation
	Money                 Money
	ProviderTransactionID string
	WebhookSignature      string
	RawWebhookPayload     []byte
}

type OperationContractDecision struct {
	Allowed       bool
	Status        ContractStatus
	ProviderCode  string
	Mode          ProviderMode
	Operation     PaymentOperation
	ErrorCode     ContractErrorCode
	Message       string
	Retryable     bool
	AuditRequired bool
	RealPayment   bool
}

func NewProviderCapabilityMatrix(cfg ProviderConfig) (ProviderCapabilityMatrix, error) {
	mode, err := normalizeMode(cfg.Mode)
	if err != nil {
		return ProviderCapabilityMatrix{}, err
	}
	if strings.TrimSpace(cfg.ProviderCode) == "" {
		return ProviderCapabilityMatrix{}, errors.New("provider code is required")
	}

	contracts := defaultOperationContracts()
	for _, rawOperation := range cfg.AllowedOperations {
		operation, err := normalizeOperation(rawOperation)
		if err != nil {
			return ProviderCapabilityMatrix{}, err
		}

		contract := contracts[operation]
		contract.Supported = true
		contracts[operation] = contract
	}

	return ProviderCapabilityMatrix{
		ProviderCode:       cfg.ProviderCode,
		Mode:               mode,
		RealPaymentEnabled: cfg.RealPaymentEnabled,
		AuditRequired:      cfg.AuditEnabled,
		Contracts:          contracts,
	}, nil
}

func (m ProviderCapabilityMatrix) ValidateRequest(req OperationContractRequest) OperationContractDecision {
	decision := OperationContractDecision{
		Allowed:       false,
		Status:        ContractStatusDenied,
		ProviderCode:  m.ProviderCode,
		Mode:          m.Mode,
		Operation:     req.Operation,
		ErrorCode:     ErrorNone,
		Message:       "",
		Retryable:     false,
		AuditRequired: m.AuditRequired,
		RealPayment:   false,
	}

	if strings.TrimSpace(req.ProviderCode) != "" && req.ProviderCode != m.ProviderCode {
		return decision.deny(ErrorProviderMismatch, "payment provider mismatch", false)
	}
	if strings.TrimSpace(req.TenantID) == "" {
		return decision.deny(ErrorTenantRequired, "tenant id is required", false)
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return decision.deny(ErrorCorrelationRequired, "correlation id is required", false)
	}

	contract, ok := m.Contracts[req.Operation]
	if !ok || !contract.Supported {
		return decision.deny(ErrorOperationUnsupported, "payment operation is unsupported", false)
	}

	if contract.RequiresIdempotencyKey && strings.TrimSpace(req.IdempotencyKey) == "" {
		return decision.deny(ErrorIdempotencyRequired, "idempotency key is required", contract.Retryable)
	}
	if contract.RequiresAmount && req.Money.AmountMinor <= 0 {
		return decision.deny(ErrorAmountRequired, "positive amount is required", contract.Retryable)
	}
	if contract.RequiresCurrency && strings.TrimSpace(req.Money.Currency) == "" {
		return decision.deny(ErrorCurrencyRequired, "currency is required", contract.Retryable)
	}
	if contract.RequiresProviderTransactionID && strings.TrimSpace(req.ProviderTransactionID) == "" {
		return decision.deny(ErrorProviderTransactionRequired, "provider transaction id is required", contract.Retryable)
	}
	if contract.RequiresWebhookSignature && strings.TrimSpace(req.WebhookSignature) == "" {
		return decision.deny(ErrorWebhookSignatureRequired, "webhook signature is required", contract.Retryable)
	}
	if contract.RequiresRawWebhookPayload && len(req.RawWebhookPayload) == 0 {
		return decision.deny(ErrorWebhookPayloadRequired, "raw webhook payload is required", contract.Retryable)
	}
	if m.Mode == ModeProduction && !m.RealPaymentEnabled {
		return decision.deny(ErrorProductionGateClosed, "production real payment gate is closed", false)
	}

	decision.Allowed = true
	decision.Status = ContractStatusAccepted
	decision.Message = "payment operation contract accepted"
	decision.Retryable = contract.Retryable
	decision.RealPayment = m.Mode == ModeProduction && m.RealPaymentEnabled
	return decision
}

func (d OperationContractDecision) deny(code ContractErrorCode, message string, retryable bool) OperationContractDecision {
	d.Allowed = false
	d.Status = ContractStatusDenied
	d.ErrorCode = code
	d.Message = message
	d.Retryable = retryable
	d.RealPayment = false
	return d
}

func defaultOperationContracts() map[PaymentOperation]OperationContract {
	return map[PaymentOperation]OperationContract{
		OperationAuthorize: {
			Operation:              OperationAuthorize,
			Supported:              false,
			RequiresAmount:         true,
			RequiresCurrency:       true,
			RequiresIdempotencyKey: true,
			Retryable:              true,
			Reversible:             true,
		},
		OperationCapture: {
			Operation:                     OperationCapture,
			Supported:                     false,
			RequiresAmount:                true,
			RequiresCurrency:              true,
			RequiresIdempotencyKey:        true,
			RequiresProviderTransactionID: true,
			Retryable:                     true,
			Reversible:                    false,
		},
		OperationRefund: {
			Operation:                     OperationRefund,
			Supported:                     false,
			RequiresAmount:                true,
			RequiresCurrency:              true,
			RequiresIdempotencyKey:        true,
			RequiresProviderTransactionID: true,
			Retryable:                     true,
			Reversible:                    false,
		},
		OperationVoid: {
			Operation:                     OperationVoid,
			Supported:                     false,
			RequiresAmount:                false,
			RequiresCurrency:              false,
			RequiresIdempotencyKey:        true,
			RequiresProviderTransactionID: true,
			Retryable:                     true,
			Reversible:                    false,
		},
		OperationWebhookVerify: {
			Operation:                 OperationWebhookVerify,
			Supported:                 false,
			RequiresAmount:            false,
			RequiresCurrency:          false,
			RequiresIdempotencyKey:    false,
			RequiresWebhookSignature:  true,
			RequiresRawWebhookPayload: true,
			Retryable:                 false,
			Reversible:                false,
		},
	}
}

func StandardContractErrorCodes() []ContractErrorCode {
	return []ContractErrorCode{
		ErrorTenantRequired,
		ErrorCorrelationRequired,
		ErrorIdempotencyRequired,
		ErrorAmountRequired,
		ErrorCurrencyRequired,
		ErrorProviderTransactionRequired,
		ErrorWebhookSignatureRequired,
		ErrorWebhookPayloadRequired,
		ErrorOperationUnsupported,
		ErrorProviderMismatch,
		ErrorProductionGateClosed,
	}
}

func EnsureContractDecisionIsAuditable(decision OperationContractDecision) error {
	if strings.TrimSpace(decision.ProviderCode) == "" {
		return fmt.Errorf("auditable payment decision requires provider code")
	}
	if strings.TrimSpace(string(decision.Mode)) == "" {
		return fmt.Errorf("auditable payment decision requires provider mode")
	}
	if strings.TrimSpace(string(decision.Operation)) == "" {
		return fmt.Errorf("auditable payment decision requires operation")
	}
	if decision.Status == "" {
		return fmt.Errorf("auditable payment decision requires status")
	}
	return nil
}
