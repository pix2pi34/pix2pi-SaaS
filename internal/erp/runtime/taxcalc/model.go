package taxcalc

import (
	"math"
	"strings"
	"time"
)

type TransactionType string

const (
	TransactionTypeSale     TransactionType = "sale"
	TransactionTypePurchase TransactionType = "purchase"
	TransactionTypeReturn   TransactionType = "return"
	TransactionTypeExpense  TransactionType = "expense"
)

type TaxCalculationStatus string

const (
	TaxCalculationStatusDraft  TaxCalculationStatus = "draft"
	TaxCalculationStatusPosted TaxCalculationStatus = "posted"
)

type TenantContext struct {
	TenantID  string
	RequestID string
	ActorID   string
	ActorType string
}

type SourceDocumentRef struct {
	SourceModule       string
	SourceDocumentType string
	SourceDocumentID   string
	SourceDocumentNo   string
}

type FiscalContext struct {
	FiscalYear      int
	FiscalPeriod    string
	CalculationDate time.Time
}

type TaxCodeSnapshot struct {
	TaxCodeID string

	Code string
	Name string

	Rate float64

	IsActive bool
	IsExempt bool

	IsWithholding          bool
	WithholdingNumerator   int
	WithholdingDenominator int
}

type MoneyInput struct {
	BaseAmount   float64
	CurrencyCode string
	ExchangeRate float64
}

type TaxCalculationRequest struct {
	Tenant TenantContext
	Source SourceDocumentRef
	Fiscal FiscalContext

	TransactionType TransactionType
	TaxCode         TaxCodeSnapshot
	Money           MoneyInput

	Description string
	Metadata    map[string]string
}

type TaxLineDraft struct {
	TenantID string

	TransactionType TransactionType

	TaxCodeID string
	TaxCode   string
	TaxName   string

	TaxRate float64

	BaseAmount float64
	TaxAmount  float64

	WithholdingAmount float64
	NetTaxAmount      float64

	GrossAmount   float64
	PayableAmount float64

	LocalBaseAmount float64
	LocalTaxAmount  float64

	LocalWithholdingAmount float64
	LocalNetTaxAmount      float64

	LocalGrossAmount   float64
	LocalPayableAmount float64

	CurrencyCode string
	ExchangeRate float64

	Source SourceDocumentRef
	Fiscal FiscalContext

	Description string
	Status      TaxCalculationStatus
}

type TaxCalculationDraft struct {
	TenantID string

	TransactionType TransactionType

	Source SourceDocumentRef
	Fiscal FiscalContext

	CurrencyCode string
	ExchangeRate float64

	TotalBaseAmount float64
	TotalTaxAmount  float64

	TotalWithholdingAmount float64
	TotalNetTaxAmount      float64

	TotalGrossAmount   float64
	TotalPayableAmount float64

	LocalTotalBaseAmount float64
	LocalTotalTaxAmount  float64

	LocalTotalWithholdingAmount float64
	LocalTotalNetTaxAmount      float64

	LocalTotalGrossAmount   float64
	LocalTotalPayableAmount float64

	Description string
	Status      TaxCalculationStatus

	Lines []TaxLineDraft
}

type TaxCalculationResult struct {
	OK bool

	TenantID  string
	RequestID string

	TransactionType TransactionType

	Source SourceDocumentRef
	Fiscal FiscalContext

	TotalBaseAmount float64
	TotalTaxAmount  float64

	TotalWithholdingAmount float64
	TotalNetTaxAmount      float64

	TotalGrossAmount   float64
	TotalPayableAmount float64

	CurrencyCode string
	ExchangeRate float64

	Status TaxCalculationStatus

	CalculatedAt time.Time
	Message      string
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

func ValidateSourceDocumentRef(ref SourceDocumentRef) error {
	if strings.TrimSpace(ref.SourceModule) == "" {
		return ErrSourceModuleRequired
	}

	if strings.TrimSpace(ref.SourceDocumentType) == "" {
		return ErrSourceDocumentRequired
	}

	if strings.TrimSpace(ref.SourceDocumentID) == "" && strings.TrimSpace(ref.SourceDocumentNo) == "" {
		return ErrSourceDocumentRequired
	}

	return nil
}

func ValidateFiscalContext(ctx FiscalContext) error {
	if ctx.FiscalYear < 2000 || ctx.FiscalYear > 2100 {
		return ErrFiscalYearInvalid
	}

	if strings.TrimSpace(ctx.FiscalPeriod) == "" {
		return ErrFiscalPeriodRequired
	}

	if ctx.CalculationDate.IsZero() {
		return ErrCalculationDateRequired
	}

	return nil
}

func ValidateTaxCodeSnapshot(code TaxCodeSnapshot) error {
	if strings.TrimSpace(code.Code) == "" {
		return ErrTaxCodeRequired
	}

	if !code.IsActive {
		return ErrTaxCodeInactive
	}

	if code.Rate < 0 || code.Rate > 100 {
		return ErrTaxRateInvalid
	}

	if code.IsWithholding {
		if code.WithholdingNumerator <= 0 || code.WithholdingDenominator <= 0 {
			return ErrWithholdingRatioInvalid
		}

		if code.WithholdingNumerator > code.WithholdingDenominator {
			return ErrWithholdingRatioInvalid
		}
	}

	return nil
}

func ValidateMoneyInput(money MoneyInput) error {
	if money.BaseAmount <= 0 {
		return ErrBaseAmountInvalid
	}

	if strings.TrimSpace(money.CurrencyCode) == "" {
		return ErrCurrencyRequired
	}

	if money.ExchangeRate <= 0 {
		return ErrExchangeRateInvalid
	}

	return nil
}

func ValidateTaxCalculationRequest(req TaxCalculationRequest) error {
	if err := ValidateTenantContext(req.Tenant); err != nil {
		return err
	}

	if err := ValidateSourceDocumentRef(req.Source); err != nil {
		return err
	}

	if err := ValidateFiscalContext(req.Fiscal); err != nil {
		return err
	}

	if !isValidTransactionType(req.TransactionType) {
		return ErrTransactionTypeInvalid
	}

	if err := ValidateTaxCodeSnapshot(req.TaxCode); err != nil {
		return err
	}

	if err := ValidateMoneyInput(req.Money); err != nil {
		return err
	}

	return nil
}

func ValidateTaxLineDraft(line TaxLineDraft) error {
	if strings.TrimSpace(line.TenantID) == "" {
		return ErrTenantRequired
	}

	if !isValidTransactionType(line.TransactionType) {
		return ErrTransactionTypeInvalid
	}

	if strings.TrimSpace(line.TaxCode) == "" {
		return ErrTaxCodeRequired
	}

	if line.TaxRate < 0 || line.TaxRate > 100 {
		return ErrTaxRateInvalid
	}

	if line.BaseAmount <= 0 || line.LocalBaseAmount <= 0 {
		return ErrBaseAmountInvalid
	}

	if strings.TrimSpace(line.CurrencyCode) == "" {
		return ErrCurrencyRequired
	}

	if line.ExchangeRate <= 0 {
		return ErrExchangeRateInvalid
	}

	if !isValidTaxCalculationStatus(line.Status) {
		return ErrTaxCalculationStatusInvalid
	}

	if err := ValidateSourceDocumentRef(line.Source); err != nil {
		return err
	}

	if err := ValidateFiscalContext(line.Fiscal); err != nil {
		return err
	}

	return nil
}

func ValidateTaxCalculationDraft(draft TaxCalculationDraft) error {
	if strings.TrimSpace(draft.TenantID) == "" {
		return ErrTenantRequired
	}

	if !isValidTransactionType(draft.TransactionType) {
		return ErrTransactionTypeInvalid
	}

	if strings.TrimSpace(draft.CurrencyCode) == "" {
		return ErrCurrencyRequired
	}

	if draft.ExchangeRate <= 0 {
		return ErrExchangeRateInvalid
	}

	if !isValidTaxCalculationStatus(draft.Status) {
		return ErrTaxCalculationStatusInvalid
	}

	if err := ValidateSourceDocumentRef(draft.Source); err != nil {
		return err
	}

	if err := ValidateFiscalContext(draft.Fiscal); err != nil {
		return err
	}

	if len(draft.Lines) < 1 {
		return ErrTaxLineCountInvalid
	}

	for _, line := range draft.Lines {
		if err := ValidateTaxLineDraft(line); err != nil {
			return err
		}
	}

	return nil
}

func BuildTaxLine(req TaxCalculationRequest) (TaxLineDraft, error) {
	if err := ValidateTaxCalculationRequest(req); err != nil {
		return TaxLineDraft{}, err
	}

	baseAmount := roundAmount(req.Money.BaseAmount)
	taxAmount := 0.0

	if !req.TaxCode.IsExempt {
		taxAmount = roundAmount(baseAmount * req.TaxCode.Rate / 100)
	}

	withholdingAmount := 0.0
	if req.TaxCode.IsWithholding {
		withholdingAmount = roundAmount(taxAmount * float64(req.TaxCode.WithholdingNumerator) / float64(req.TaxCode.WithholdingDenominator))
	}

	netTaxAmount := roundAmount(taxAmount - withholdingAmount)
	grossAmount := roundAmount(baseAmount + taxAmount)
	payableAmount := roundAmount(baseAmount + netTaxAmount)

	exchangeRate := req.Money.ExchangeRate

	return TaxLineDraft{
		TenantID:        req.Tenant.TenantID,
		TransactionType: req.TransactionType,
		TaxCodeID:       req.TaxCode.TaxCodeID,
		TaxCode:         strings.TrimSpace(req.TaxCode.Code),
		TaxName:         strings.TrimSpace(req.TaxCode.Name),
		TaxRate:         req.TaxCode.Rate,

		BaseAmount: baseAmount,
		TaxAmount:  taxAmount,

		WithholdingAmount: withholdingAmount,
		NetTaxAmount:      netTaxAmount,

		GrossAmount:   grossAmount,
		PayableAmount: payableAmount,

		LocalBaseAmount: roundAmount(baseAmount * exchangeRate),
		LocalTaxAmount:  roundAmount(taxAmount * exchangeRate),

		LocalWithholdingAmount: roundAmount(withholdingAmount * exchangeRate),
		LocalNetTaxAmount:      roundAmount(netTaxAmount * exchangeRate),

		LocalGrossAmount:   roundAmount(grossAmount * exchangeRate),
		LocalPayableAmount: roundAmount(payableAmount * exchangeRate),

		CurrencyCode: strings.ToUpper(strings.TrimSpace(req.Money.CurrencyCode)),
		ExchangeRate: exchangeRate,

		Source: req.Source,
		Fiscal: req.Fiscal,

		Description: req.Description,
		Status:      TaxCalculationStatusDraft,
	}, nil
}

func BuildTaxCalculationDraft(req TaxCalculationRequest) (TaxCalculationDraft, error) {
	if err := ValidateTaxCalculationRequest(req); err != nil {
		return TaxCalculationDraft{}, err
	}

	line, err := BuildTaxLine(req)
	if err != nil {
		return TaxCalculationDraft{}, err
	}

	return TaxCalculationDraft{
		TenantID:        req.Tenant.TenantID,
		TransactionType: req.TransactionType,
		Source:          req.Source,
		Fiscal:          req.Fiscal,
		CurrencyCode:    strings.ToUpper(strings.TrimSpace(req.Money.CurrencyCode)),
		ExchangeRate:    req.Money.ExchangeRate,

		TotalBaseAmount: line.BaseAmount,
		TotalTaxAmount:  line.TaxAmount,

		TotalWithholdingAmount: line.WithholdingAmount,
		TotalNetTaxAmount:      line.NetTaxAmount,

		TotalGrossAmount:   line.GrossAmount,
		TotalPayableAmount: line.PayableAmount,

		LocalTotalBaseAmount: line.LocalBaseAmount,
		LocalTotalTaxAmount:  line.LocalTaxAmount,

		LocalTotalWithholdingAmount: line.LocalWithholdingAmount,
		LocalTotalNetTaxAmount:      line.LocalNetTaxAmount,

		LocalTotalGrossAmount:   line.LocalGrossAmount,
		LocalTotalPayableAmount: line.LocalPayableAmount,

		Description: req.Description,
		Status:      TaxCalculationStatusDraft,
		Lines:       []TaxLineDraft{line},
	}, nil
}

func BuildTaxCalculationResult(req TaxCalculationRequest, draft TaxCalculationDraft, message string) (TaxCalculationResult, error) {
	if err := ValidateTaxCalculationRequest(req); err != nil {
		return TaxCalculationResult{}, err
	}

	if err := ValidateTaxCalculationDraft(draft); err != nil {
		return TaxCalculationResult{}, err
	}

	if draft.Status != TaxCalculationStatusPosted {
		return TaxCalculationResult{}, ErrTaxCalculationStatusInvalid
	}

	return TaxCalculationResult{
		OK:              true,
		TenantID:        req.Tenant.TenantID,
		RequestID:       req.Tenant.RequestID,
		TransactionType: draft.TransactionType,
		Source:          draft.Source,
		Fiscal:          draft.Fiscal,

		TotalBaseAmount: draft.TotalBaseAmount,
		TotalTaxAmount:  draft.TotalTaxAmount,

		TotalWithholdingAmount: draft.TotalWithholdingAmount,
		TotalNetTaxAmount:      draft.TotalNetTaxAmount,

		TotalGrossAmount:   draft.TotalGrossAmount,
		TotalPayableAmount: draft.TotalPayableAmount,

		CurrencyCode: draft.CurrencyCode,
		ExchangeRate: draft.ExchangeRate,

		Status:       TaxCalculationStatusPosted,
		CalculatedAt: time.Now().UTC(),
		Message:      message,
	}, nil
}

func isValidTransactionType(value TransactionType) bool {
	switch value {
	case TransactionTypeSale, TransactionTypePurchase, TransactionTypeReturn, TransactionTypeExpense:
		return true
	default:
		return false
	}
}

func isValidTaxCalculationStatus(value TaxCalculationStatus) bool {
	switch value {
	case TaxCalculationStatusDraft, TaxCalculationStatusPosted:
		return true
	default:
		return false
	}
}

func roundAmount(value float64) float64 {
	return math.Round(value*100) / 100
}
