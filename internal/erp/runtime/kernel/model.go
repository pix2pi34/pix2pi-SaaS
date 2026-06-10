package kernel

import (
	"strings"
	"time"
)

type TenantContext struct {
	TenantID  string
	RequestID string
	ActorID   string
	ActorType string
}

type DocumentRef struct {
	Module       string
	DocumentType string
	DocumentID   string
	DocumentNo   string
}

type Money struct {
	Amount       float64
	CurrencyCode string
	ExchangeRate float64
	LocalAmount  float64
}

type FiscalContext struct {
	FiscalYear   int
	FiscalPeriod string
	PostingDate  time.Time
}

type RuntimeOperation string

const (
	RuntimeOperationCreate   RuntimeOperation = "create"
	RuntimeOperationPost     RuntimeOperation = "post"
	RuntimeOperationReverse  RuntimeOperation = "reverse"
	RuntimeOperationCancel   RuntimeOperation = "cancel"
	RuntimeOperationAllocate RuntimeOperation = "allocate"
)

type RuntimeRequest struct {
	Tenant    TenantContext
	Operation RuntimeOperation
	Document  DocumentRef
	Money     Money
	Fiscal    FiscalContext
	Metadata  map[string]string
}

type RuntimeResult struct {
	OK         bool
	TenantID   string
	RequestID  string
	Operation  RuntimeOperation
	Document   DocumentRef
	Message    string
	OccurredAt time.Time
}

func ValidateTenantContext(ctx TenantContext) error {
	if strings.TrimSpace(ctx.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(ctx.RequestID) == "" {
		return ErrRequestIDRequired
	}

	if strings.TrimSpace(ctx.ActorID) == "" {
		return ErrActorRequired
	}

	return nil
}

func ValidateDocumentRef(ref DocumentRef) error {
	if strings.TrimSpace(ref.Module) == "" {
		return ErrDocumentRefInvalid
	}

	if strings.TrimSpace(ref.DocumentType) == "" {
		return ErrDocumentRefInvalid
	}

	if strings.TrimSpace(ref.DocumentID) == "" && strings.TrimSpace(ref.DocumentNo) == "" {
		return ErrDocumentRefInvalid
	}

	return nil
}

func ValidateMoney(money Money) error {
	if money.Amount < 0 || money.LocalAmount < 0 || money.ExchangeRate <= 0 {
		return ErrAmountInvalid
	}

	if strings.TrimSpace(money.CurrencyCode) == "" {
		return ErrCurrencyRequired
	}

	return nil
}

func ValidateFiscalContext(fiscal FiscalContext) error {
	if fiscal.FiscalYear < 2000 || fiscal.FiscalYear > 2100 {
		return ErrFiscalYearInvalid
	}

	if strings.TrimSpace(fiscal.FiscalPeriod) == "" {
		return ErrFiscalPeriodInvalid
	}

	if fiscal.PostingDate.IsZero() {
		return ErrFiscalPeriodInvalid
	}

	return nil
}

func ValidateRuntimeRequest(req RuntimeRequest) error {
	if err := ValidateTenantContext(req.Tenant); err != nil {
		return err
	}

	if strings.TrimSpace(string(req.Operation)) == "" {
		return ErrOperationRequired
	}

	if err := ValidateDocumentRef(req.Document); err != nil {
		return err
	}

	if err := ValidateMoney(req.Money); err != nil {
		return err
	}

	if err := ValidateFiscalContext(req.Fiscal); err != nil {
		return err
	}

	return nil
}

func NewSuccessResult(req RuntimeRequest, message string) RuntimeResult {
	return RuntimeResult{
		OK:         true,
		TenantID:   req.Tenant.TenantID,
		RequestID:  req.Tenant.RequestID,
		Operation:  req.Operation,
		Document:   req.Document,
		Message:    message,
		OccurredAt: time.Now().UTC(),
	}
}
