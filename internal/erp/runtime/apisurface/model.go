package apisurface

import (
	"strings"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/e2eflow"
)

type RuntimeFlowAPIRequest struct {
	TenantID string `json:"tenant_id"`

	RequestID string `json:"request_id"`
	ActorID   string `json:"actor_id"`
	ActorType string `json:"actor_type"`

	TransactionKind string `json:"transaction_kind"`

	Source RuntimeFlowAPISource `json:"source"`
	Money  RuntimeFlowAPIMoney  `json:"money"`

	IdempotencyKey string `json:"idempotency_key"`
	CorrelationID  string `json:"correlation_id"`

	Description string            `json:"description"`
	Metadata    map[string]string `json:"metadata"`
}

type RuntimeFlowAPISource struct {
	SourceModule       string `json:"source_module"`
	SourceDocumentType string `json:"source_document_type"`
	SourceDocumentID   string `json:"source_document_id"`
	SourceDocumentNo   string `json:"source_document_no"`
}

type RuntimeFlowAPIMoney struct {
	TotalAmount  float64 `json:"total_amount"`
	CurrencyCode string  `json:"currency_code"`
	ExchangeRate float64 `json:"exchange_rate"`
}

type RuntimeFlowAPIResponse struct {
	OK bool `json:"ok"`

	TenantID  string `json:"tenant_id"`
	RequestID string `json:"request_id"`

	TransactionKind string `json:"transaction_kind"`

	SourceModule       string `json:"source_module"`
	SourceDocumentType string `json:"source_document_type"`
	SourceDocumentID   string `json:"source_document_id"`
	SourceDocumentNo   string `json:"source_document_no"`

	Status    string `json:"status"`
	StepCount int    `json:"step_count"`

	CompletedAt time.Time `json:"completed_at"`
	Message     string    `json:"message"`
}

type RuntimeFlowAPIErrorResponse struct {
	OK bool `json:"ok"`

	ErrorCode string `json:"error_code"`
	Message   string `json:"message"`

	TenantID  string `json:"tenant_id,omitempty"`
	RequestID string `json:"request_id,omitempty"`
}

func ValidateRuntimeFlowAPIRequest(req RuntimeFlowAPIRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return ErrTenantIDRequired
	}

	if strings.TrimSpace(req.RequestID) == "" {
		return ErrRequestIDRequired
	}

	if strings.TrimSpace(req.ActorID) == "" {
		return ErrActorIDRequired
	}

	if strings.TrimSpace(req.TransactionKind) == "" {
		return ErrTransactionKindRequired
	}

	if !isValidAPITransactionKind(req.TransactionKind) {
		return ErrTransactionKindInvalid
	}

	if strings.TrimSpace(req.Source.SourceModule) == "" {
		return ErrSourceModuleRequired
	}

	if strings.TrimSpace(req.Source.SourceDocumentType) == "" {
		return ErrSourceDocumentTypeRequired
	}

	if strings.TrimSpace(req.Source.SourceDocumentID) == "" && strings.TrimSpace(req.Source.SourceDocumentNo) == "" {
		return ErrSourceDocumentRequired
	}

	if req.Money.TotalAmount <= 0 {
		return ErrTotalAmountInvalid
	}

	if strings.TrimSpace(req.Money.CurrencyCode) == "" {
		return ErrCurrencyCodeRequired
	}

	if req.Money.ExchangeRate <= 0 {
		return ErrExchangeRateInvalid
	}

	if strings.TrimSpace(req.IdempotencyKey) == "" {
		return ErrIdempotencyKeyRequired
	}

	return nil
}

func ToRuntimeFlowRequest(req RuntimeFlowAPIRequest) (e2eflow.RuntimeFlowRequest, error) {
	if err := ValidateRuntimeFlowAPIRequest(req); err != nil {
		return e2eflow.RuntimeFlowRequest{}, err
	}

	return e2eflow.RuntimeFlowRequest{
		Tenant: e2eflow.TenantContext{
			TenantID:  strings.TrimSpace(req.TenantID),
			RequestID: strings.TrimSpace(req.RequestID),
			ActorID:   strings.TrimSpace(req.ActorID),
			ActorType: defaultActorType(req.ActorType),
		},
		TransactionKind: e2eflow.TransactionKind(strings.TrimSpace(req.TransactionKind)),
		Source: e2eflow.SourceDocumentRef{
			SourceModule:       strings.TrimSpace(req.Source.SourceModule),
			SourceDocumentType: strings.TrimSpace(req.Source.SourceDocumentType),
			SourceDocumentID:   strings.TrimSpace(req.Source.SourceDocumentID),
			SourceDocumentNo:   strings.TrimSpace(req.Source.SourceDocumentNo),
		},
		Money: e2eflow.MoneySummary{
			TotalAmount:  req.Money.TotalAmount,
			CurrencyCode: strings.ToUpper(strings.TrimSpace(req.Money.CurrencyCode)),
			ExchangeRate: req.Money.ExchangeRate,
		},
		IdempotencyKey: strings.TrimSpace(req.IdempotencyKey),
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		Description:    req.Description,
		Metadata:       req.Metadata,
	}, nil
}

func BuildRuntimeFlowAPIResponse(result e2eflow.RuntimeFlowResult) RuntimeFlowAPIResponse {
	return RuntimeFlowAPIResponse{
		OK: result.OK,

		TenantID:  result.TenantID,
		RequestID: result.RequestID,

		TransactionKind: string(result.TransactionKind),

		SourceModule:       result.Source.SourceModule,
		SourceDocumentType: result.Source.SourceDocumentType,
		SourceDocumentID:   result.Source.SourceDocumentID,
		SourceDocumentNo:   result.Source.SourceDocumentNo,

		Status:      string(result.Status),
		StepCount:   result.StepCount,
		CompletedAt: result.CompletedAt,
		Message:     result.Message,
	}
}

func BuildRuntimeFlowAPIErrorResponse(req RuntimeFlowAPIRequest, code string, err error) RuntimeFlowAPIErrorResponse {
	message := ""
	if err != nil {
		message = err.Error()
	}

	return RuntimeFlowAPIErrorResponse{
		OK: false,

		ErrorCode: strings.TrimSpace(code),
		Message:   message,

		TenantID:  strings.TrimSpace(req.TenantID),
		RequestID: strings.TrimSpace(req.RequestID),
	}
}

func defaultActorType(value string) string {
	if strings.TrimSpace(value) == "" {
		return "user"
	}

	return strings.TrimSpace(value)
}

func isValidAPITransactionKind(kind string) bool {
	switch e2eflow.TransactionKind(strings.TrimSpace(kind)) {
	case e2eflow.TransactionKindSalesInvoice,
		e2eflow.TransactionKindPurchaseInvoice,
		e2eflow.TransactionKindCashReceipt,
		e2eflow.TransactionKindCashPayment:
		return true
	default:
		return false
	}
}
