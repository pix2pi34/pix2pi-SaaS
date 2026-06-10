package cashbankpay

import (
	"math"
	"strings"
	"time"
)

type PaymentDirection string

const (
	PaymentDirectionInflow  PaymentDirection = "inflow"
	PaymentDirectionOutflow PaymentDirection = "outflow"
)

type PaymentMethod string

const (
	PaymentMethodCash         PaymentMethod = "cash"
	PaymentMethodBankTransfer PaymentMethod = "bank_transfer"
	PaymentMethodCard         PaymentMethod = "card"
	PaymentMethodCheque       PaymentMethod = "cheque"
	PaymentMethodOther        PaymentMethod = "other"
)

type PaymentStatus string

const (
	PaymentStatusDraft     PaymentStatus = "draft"
	PaymentStatusPosted    PaymentStatus = "posted"
	PaymentStatusCancelled PaymentStatus = "cancelled"
	PaymentStatusReversed  PaymentStatus = "reversed"
)

type AccountType string

const (
	AccountTypeCash AccountType = "cash"
	AccountTypeBank AccountType = "bank"
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
	FiscalYear   int
	FiscalPeriod string
	PaymentDate  time.Time
}

type AccountRef struct {
	AccountID   string
	AccountCode string
	AccountName string
	AccountType AccountType
}

type Money struct {
	Amount       float64
	CurrencyCode string
	ExchangeRate float64
	LocalAmount  float64
}

type CounterpartyRef struct {
	PartyID    string
	CustomerID string
	VendorID   string
	Name       string
}

type PaymentRequest struct {
	Tenant TenantContext
	Source SourceDocumentRef
	Fiscal FiscalContext

	PaymentNo string

	Direction PaymentDirection
	Method    PaymentMethod

	Account      AccountRef
	Counterparty CounterpartyRef

	Money Money

	Description string
	Metadata    map[string]string
}

type CashBankMovementDraft struct {
	TenantID string

	PaymentNo string

	Direction PaymentDirection
	Method    PaymentMethod

	Account AccountRef

	Amount       float64
	LocalAmount  float64
	SignedAmount float64

	CurrencyCode string
	ExchangeRate float64

	Fiscal FiscalContext
	Source SourceDocumentRef

	Counterparty CounterpartyRef

	Description string
	Status      PaymentStatus
}

type PaymentDraft struct {
	TenantID string

	PaymentNo string

	Direction PaymentDirection
	Method    PaymentMethod

	Account      AccountRef
	Counterparty CounterpartyRef

	Money Money

	Fiscal FiscalContext
	Source SourceDocumentRef

	Description string
	Status      PaymentStatus

	Movements []CashBankMovementDraft
}

type PaymentResult struct {
	OK bool

	TenantID  string
	RequestID string

	PaymentNo string
	Status    PaymentStatus

	Direction PaymentDirection
	Method    PaymentMethod

	Account AccountRef

	Amount       float64
	LocalAmount  float64
	SignedAmount float64

	CurrencyCode string
	ExchangeRate float64

	Fiscal FiscalContext
	Source SourceDocumentRef

	PostedAt time.Time
	Message  string
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

	if ctx.PaymentDate.IsZero() {
		return ErrPaymentDateRequired
	}

	return nil
}

func ValidateAccountRef(ref AccountRef) error {
	if strings.TrimSpace(ref.AccountID) == "" && strings.TrimSpace(ref.AccountCode) == "" {
		return ErrAccountRefRequired
	}

	if !isValidAccountType(ref.AccountType) {
		return ErrAccountTypeInvalid
	}

	return nil
}

func ValidateMoney(money Money) error {
	if money.Amount <= 0 {
		return ErrAmountInvalid
	}

	if strings.TrimSpace(money.CurrencyCode) == "" {
		return ErrCurrencyRequired
	}

	if money.ExchangeRate <= 0 {
		return ErrAmountInvalid
	}

	if money.LocalAmount <= 0 {
		return ErrAmountInvalid
	}

	return nil
}

func ValidatePaymentRequest(req PaymentRequest) error {
	if err := ValidateTenantContext(req.Tenant); err != nil {
		return err
	}

	if err := ValidateSourceDocumentRef(req.Source); err != nil {
		return err
	}

	if err := ValidateFiscalContext(req.Fiscal); err != nil {
		return err
	}

	if strings.TrimSpace(req.PaymentNo) == "" {
		return ErrPaymentNoRequired
	}

	if !isValidPaymentDirection(req.Direction) {
		return ErrPaymentDirectionInvalid
	}

	if !isValidPaymentMethod(req.Method) {
		return ErrPaymentMethodInvalid
	}

	if err := ValidateAccountRef(req.Account); err != nil {
		return err
	}

	if err := ValidateMoney(req.Money); err != nil {
		return err
	}

	return nil
}

func ValidateCashBankMovementDraft(movement CashBankMovementDraft) error {
	if strings.TrimSpace(movement.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(movement.PaymentNo) == "" {
		return ErrPaymentNoRequired
	}

	if !isValidPaymentDirection(movement.Direction) {
		return ErrPaymentDirectionInvalid
	}

	if !isValidPaymentMethod(movement.Method) {
		return ErrPaymentMethodInvalid
	}

	if !isValidPaymentStatus(movement.Status) {
		return ErrPaymentStatusInvalid
	}

	if err := ValidateAccountRef(movement.Account); err != nil {
		return err
	}

	if movement.Amount <= 0 || movement.LocalAmount <= 0 {
		return ErrAmountInvalid
	}

	if strings.TrimSpace(movement.CurrencyCode) == "" {
		return ErrCurrencyRequired
	}

	if movement.ExchangeRate <= 0 {
		return ErrAmountInvalid
	}

	if movement.Direction == PaymentDirectionInflow && movement.SignedAmount <= 0 {
		return ErrAmountInvalid
	}

	if movement.Direction == PaymentDirectionOutflow && movement.SignedAmount >= 0 {
		return ErrAmountInvalid
	}

	if err := ValidateFiscalContext(movement.Fiscal); err != nil {
		return err
	}

	if err := ValidateSourceDocumentRef(movement.Source); err != nil {
		return err
	}

	return nil
}

func ValidatePaymentDraft(draft PaymentDraft) error {
	if strings.TrimSpace(draft.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(draft.PaymentNo) == "" {
		return ErrPaymentNoRequired
	}

	if !isValidPaymentDirection(draft.Direction) {
		return ErrPaymentDirectionInvalid
	}

	if !isValidPaymentMethod(draft.Method) {
		return ErrPaymentMethodInvalid
	}

	if !isValidPaymentStatus(draft.Status) {
		return ErrPaymentStatusInvalid
	}

	if err := ValidateAccountRef(draft.Account); err != nil {
		return err
	}

	if err := ValidateMoney(draft.Money); err != nil {
		return err
	}

	if err := ValidateFiscalContext(draft.Fiscal); err != nil {
		return err
	}

	if err := ValidateSourceDocumentRef(draft.Source); err != nil {
		return err
	}

	if len(draft.Movements) < 1 {
		return ErrMovementCountInvalid
	}

	for _, movement := range draft.Movements {
		if err := ValidateCashBankMovementDraft(movement); err != nil {
			return err
		}
	}

	return nil
}

func BuildCashBankMovement(req PaymentRequest) (CashBankMovementDraft, error) {
	if err := ValidatePaymentRequest(req); err != nil {
		return CashBankMovementDraft{}, err
	}

	signedAmount := roundAmount(req.Money.LocalAmount)
	if req.Direction == PaymentDirectionOutflow {
		signedAmount = roundAmount(-req.Money.LocalAmount)
	}

	return CashBankMovementDraft{
		TenantID:     req.Tenant.TenantID,
		PaymentNo:    req.PaymentNo,
		Direction:    req.Direction,
		Method:       req.Method,
		Account:      req.Account,
		Amount:       roundAmount(req.Money.Amount),
		LocalAmount:  roundAmount(req.Money.LocalAmount),
		SignedAmount: signedAmount,
		CurrencyCode: strings.ToUpper(strings.TrimSpace(req.Money.CurrencyCode)),
		ExchangeRate: req.Money.ExchangeRate,
		Fiscal:       req.Fiscal,
		Source:       req.Source,
		Counterparty: req.Counterparty,
		Description:  req.Description,
		Status:       PaymentStatusDraft,
	}, nil
}

func BuildPaymentDraft(req PaymentRequest) (PaymentDraft, error) {
	if err := ValidatePaymentRequest(req); err != nil {
		return PaymentDraft{}, err
	}

	movement, err := BuildCashBankMovement(req)
	if err != nil {
		return PaymentDraft{}, err
	}

	return PaymentDraft{
		TenantID:     req.Tenant.TenantID,
		PaymentNo:    req.PaymentNo,
		Direction:    req.Direction,
		Method:       req.Method,
		Account:      req.Account,
		Counterparty: req.Counterparty,
		Money: Money{
			Amount:       roundAmount(req.Money.Amount),
			CurrencyCode: strings.ToUpper(strings.TrimSpace(req.Money.CurrencyCode)),
			ExchangeRate: req.Money.ExchangeRate,
			LocalAmount:  roundAmount(req.Money.LocalAmount),
		},
		Fiscal:      req.Fiscal,
		Source:      req.Source,
		Description: req.Description,
		Status:      PaymentStatusDraft,
		Movements:   []CashBankMovementDraft{movement},
	}, nil
}

func BuildPaymentResult(req PaymentRequest, draft PaymentDraft, message string) (PaymentResult, error) {
	if err := ValidatePaymentRequest(req); err != nil {
		return PaymentResult{}, err
	}

	if err := ValidatePaymentDraft(draft); err != nil {
		return PaymentResult{}, err
	}

	if draft.Status != PaymentStatusPosted {
		return PaymentResult{}, ErrPaymentStatusInvalid
	}

	signedAmount := roundAmount(draft.Money.LocalAmount)
	if draft.Direction == PaymentDirectionOutflow {
		signedAmount = roundAmount(-draft.Money.LocalAmount)
	}

	return PaymentResult{
		OK:           true,
		TenantID:     req.Tenant.TenantID,
		RequestID:    req.Tenant.RequestID,
		PaymentNo:    draft.PaymentNo,
		Status:       PaymentStatusPosted,
		Direction:    draft.Direction,
		Method:       draft.Method,
		Account:      draft.Account,
		Amount:       roundAmount(draft.Money.Amount),
		LocalAmount:  roundAmount(draft.Money.LocalAmount),
		SignedAmount: signedAmount,
		CurrencyCode: strings.ToUpper(strings.TrimSpace(draft.Money.CurrencyCode)),
		ExchangeRate: draft.Money.ExchangeRate,
		Fiscal:       draft.Fiscal,
		Source:       draft.Source,
		PostedAt:     time.Now().UTC(),
		Message:      message,
	}, nil
}

func isValidPaymentDirection(value PaymentDirection) bool {
	switch value {
	case PaymentDirectionInflow, PaymentDirectionOutflow:
		return true
	default:
		return false
	}
}

func isValidPaymentMethod(value PaymentMethod) bool {
	switch value {
	case PaymentMethodCash, PaymentMethodBankTransfer, PaymentMethodCard, PaymentMethodCheque, PaymentMethodOther:
		return true
	default:
		return false
	}
}

func isValidPaymentStatus(value PaymentStatus) bool {
	switch value {
	case PaymentStatusDraft, PaymentStatusPosted, PaymentStatusCancelled, PaymentStatusReversed:
		return true
	default:
		return false
	}
}

func isValidAccountType(value AccountType) bool {
	switch value {
	case AccountTypeCash, AccountTypeBank:
		return true
	default:
		return false
	}
}

func roundAmount(value float64) float64 {
	return math.Round(value*100) / 100
}
