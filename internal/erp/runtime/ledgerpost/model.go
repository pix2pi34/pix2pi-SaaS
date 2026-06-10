package ledgerpost

import (
	"math"
	"strings"
	"time"
)

type JournalStatus string

const (
	JournalStatusDraft  JournalStatus = "draft"
	JournalStatusPosted JournalStatus = "posted"
)

type LedgerPostingStatus string

const (
	LedgerPostingStatusDraft  LedgerPostingStatus = "draft"
	LedgerPostingStatusPosted LedgerPostingStatus = "posted"
)

type MovementDirection string

const (
	MovementDirectionDebit  MovementDirection = "debit"
	MovementDirectionCredit MovementDirection = "credit"
)

type TenantContext struct {
	TenantID  string
	RequestID string
	ActorID   string
	ActorType string
}

type JournalRef struct {
	JournalEntryID string
	JournalNo      string
	JournalStatus  JournalStatus
}

type FiscalContext struct {
	FiscalYear   int
	FiscalPeriod string
	PostingDate  time.Time
}

type LedgerLineDraft struct {
	LineNo int

	AccountCode string
	AccountName string

	DebitAmount  float64
	CreditAmount float64

	CurrencyCode string
	ExchangeRate float64

	Description string

	PartyID    string
	CustomerID string
	VendorID   string
}

type AccountMovementDraft struct {
	LineNo int

	AccountCode string
	AccountName string

	MovementDirection MovementDirection

	DebitAmount  float64
	CreditAmount float64
	SignedAmount float64

	CurrencyCode string
	ExchangeRate float64

	Description string

	PartyID    string
	CustomerID string
	VendorID   string
}

type LedgerPostingRequest struct {
	Tenant  TenantContext
	Journal JournalRef
	Fiscal  FiscalContext

	Description string
	Lines       []LedgerLineDraft

	Metadata map[string]string
}

type LedgerPostingDraft struct {
	TenantID string

	Journal JournalRef
	Fiscal  FiscalContext

	Description string
	Status      LedgerPostingStatus

	Movements []AccountMovementDraft
}

type LedgerPostingResult struct {
	OK bool

	TenantID  string
	RequestID string

	JournalEntryID string
	JournalNo      string

	Status LedgerPostingStatus

	Fiscal FiscalContext

	MovementCount int

	TotalDebit  float64
	TotalCredit float64

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

func ValidateJournalRef(ref JournalRef) error {
	if strings.TrimSpace(ref.JournalEntryID) == "" && strings.TrimSpace(ref.JournalNo) == "" {
		return ErrJournalRefRequired
	}

	if ref.JournalStatus != JournalStatusPosted {
		return ErrJournalStatusInvalid
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

	if ctx.PostingDate.IsZero() {
		return ErrPostingDateRequired
	}

	return nil
}

func ValidateLedgerLineDraft(line LedgerLineDraft) error {
	if strings.TrimSpace(line.AccountCode) == "" {
		return ErrAccountCodeRequired
	}

	if line.DebitAmount < 0 || line.CreditAmount < 0 {
		return ErrAmountInvalid
	}

	if line.DebitAmount == 0 && line.CreditAmount == 0 {
		return ErrAmountInvalid
	}

	if line.DebitAmount > 0 && line.CreditAmount > 0 {
		return ErrAmountInvalid
	}

	if strings.TrimSpace(line.CurrencyCode) != "" && line.ExchangeRate <= 0 {
		return ErrAmountInvalid
	}

	return nil
}

func ValidateAccountMovementDraft(movement AccountMovementDraft) error {
	if strings.TrimSpace(movement.AccountCode) == "" {
		return ErrAccountCodeRequired
	}

	if movement.MovementDirection != MovementDirectionDebit && movement.MovementDirection != MovementDirectionCredit {
		return ErrMovementDirectionInvalid
	}

	if movement.DebitAmount < 0 || movement.CreditAmount < 0 {
		return ErrAmountInvalid
	}

	if movement.MovementDirection == MovementDirectionDebit && movement.DebitAmount <= 0 {
		return ErrAmountInvalid
	}

	if movement.MovementDirection == MovementDirectionCredit && movement.CreditAmount <= 0 {
		return ErrAmountInvalid
	}

	if strings.TrimSpace(movement.CurrencyCode) != "" && movement.ExchangeRate <= 0 {
		return ErrAmountInvalid
	}

	return nil
}

func ValidateLedgerPostingRequest(req LedgerPostingRequest) error {
	if err := ValidateTenantContext(req.Tenant); err != nil {
		return err
	}

	if err := ValidateJournalRef(req.Journal); err != nil {
		return err
	}

	if err := ValidateFiscalContext(req.Fiscal); err != nil {
		return err
	}

	if len(req.Lines) < 2 {
		return ErrLedgerLineCountInvalid
	}

	for _, line := range req.Lines {
		if err := ValidateLedgerLineDraft(line); err != nil {
			return err
		}
	}

	if !IsBalanced(req.Lines) {
		return ErrLedgerUnbalanced
	}

	return nil
}

func ValidateLedgerPostingDraft(draft LedgerPostingDraft) error {
	if strings.TrimSpace(draft.TenantID) == "" {
		return ErrTenantRequired
	}

	if err := ValidateJournalRef(draft.Journal); err != nil {
		return err
	}

	if err := ValidateFiscalContext(draft.Fiscal); err != nil {
		return err
	}

	if draft.Status != LedgerPostingStatusDraft && draft.Status != LedgerPostingStatusPosted {
		return ErrLedgerStatusInvalid
	}

	if len(draft.Movements) < 2 {
		return ErrLedgerLineCountInvalid
	}

	for _, movement := range draft.Movements {
		if err := ValidateAccountMovementDraft(movement); err != nil {
			return err
		}
	}

	totalDebit, totalCredit := SumMovements(draft.Movements)
	if math.Abs(totalDebit-totalCredit) >= 0.000001 {
		return ErrLedgerUnbalanced
	}

	return nil
}

func BuildAccountMovements(lines []LedgerLineDraft) ([]AccountMovementDraft, error) {
	if len(lines) < 2 {
		return nil, ErrLedgerLineCountInvalid
	}

	movements := make([]AccountMovementDraft, 0, len(lines))

	for _, line := range lines {
		if err := ValidateLedgerLineDraft(line); err != nil {
			return nil, err
		}

		movement := AccountMovementDraft{
			LineNo:       line.LineNo,
			AccountCode:  line.AccountCode,
			AccountName:  line.AccountName,
			DebitAmount:  line.DebitAmount,
			CreditAmount: line.CreditAmount,
			CurrencyCode: line.CurrencyCode,
			ExchangeRate: line.ExchangeRate,
			Description:  line.Description,
			PartyID:      line.PartyID,
			CustomerID:   line.CustomerID,
			VendorID:     line.VendorID,
		}

		if line.DebitAmount > 0 {
			movement.MovementDirection = MovementDirectionDebit
			movement.SignedAmount = roundAmount(line.DebitAmount)
		} else {
			movement.MovementDirection = MovementDirectionCredit
			movement.SignedAmount = roundAmount(-line.CreditAmount)
		}

		movements = append(movements, movement)
	}

	return movements, nil
}

func BuildLedgerPostingDraft(req LedgerPostingRequest) (LedgerPostingDraft, error) {
	if err := ValidateLedgerPostingRequest(req); err != nil {
		return LedgerPostingDraft{}, err
	}

	movements, err := BuildAccountMovements(req.Lines)
	if err != nil {
		return LedgerPostingDraft{}, err
	}

	return LedgerPostingDraft{
		TenantID:    req.Tenant.TenantID,
		Journal:     req.Journal,
		Fiscal:      req.Fiscal,
		Description: req.Description,
		Status:      LedgerPostingStatusDraft,
		Movements:   movements,
	}, nil
}

func BuildLedgerPostingResult(req LedgerPostingRequest, draft LedgerPostingDraft, message string) (LedgerPostingResult, error) {
	if err := ValidateLedgerPostingRequest(req); err != nil {
		return LedgerPostingResult{}, err
	}

	if err := ValidateLedgerPostingDraft(draft); err != nil {
		return LedgerPostingResult{}, err
	}

	totalDebit, totalCredit := SumMovements(draft.Movements)

	return LedgerPostingResult{
		OK:             true,
		TenantID:       req.Tenant.TenantID,
		RequestID:      req.Tenant.RequestID,
		JournalEntryID: req.Journal.JournalEntryID,
		JournalNo:      req.Journal.JournalNo,
		Status:         LedgerPostingStatusPosted,
		Fiscal:         req.Fiscal,
		MovementCount:  len(draft.Movements),
		TotalDebit:     totalDebit,
		TotalCredit:    totalCredit,
		PostedAt:       time.Now().UTC(),
		Message:        message,
	}, nil
}

func SumLedgerLines(lines []LedgerLineDraft) (float64, float64) {
	var totalDebit float64
	var totalCredit float64

	for _, line := range lines {
		totalDebit += line.DebitAmount
		totalCredit += line.CreditAmount
	}

	return roundAmount(totalDebit), roundAmount(totalCredit)
}

func SumMovements(movements []AccountMovementDraft) (float64, float64) {
	var totalDebit float64
	var totalCredit float64

	for _, movement := range movements {
		totalDebit += movement.DebitAmount
		totalCredit += movement.CreditAmount
	}

	return roundAmount(totalDebit), roundAmount(totalCredit)
}

func IsBalanced(lines []LedgerLineDraft) bool {
	totalDebit, totalCredit := SumLedgerLines(lines)
	return math.Abs(totalDebit-totalCredit) < 0.000001
}

func roundAmount(value float64) float64 {
	return math.Round(value*100) / 100
}
