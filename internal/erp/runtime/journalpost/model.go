package journalpost

import (
	"math"
	"strings"
	"time"
)

type JournalStatus string

const (
	JournalStatusDraft    JournalStatus = "draft"
	JournalStatusPosted   JournalStatus = "posted"
	JournalStatusReversed JournalStatus = "reversed"
	JournalStatusCanceled JournalStatus = "canceled"
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
	PostingDate  time.Time
}

type JournalLineDraft struct {
	LineNo      int
	AccountCode string
	AccountName string

	DebitAmount  float64
	CreditAmount float64

	CurrencyCode string
	ExchangeRate float64

	Description string
	PartyID     string
	CustomerID  string
	VendorID    string
}

type JournalDraft struct {
	TenantID string

	JournalNo string

	Source SourceDocumentRef
	Fiscal FiscalContext

	Description string
	Status      JournalStatus

	Lines []JournalLineDraft
}

type JournalPostingRequest struct {
	Tenant TenantContext
	Source SourceDocumentRef
	Fiscal FiscalContext

	JournalNo   string
	Description string

	Lines []JournalLineDraft

	Metadata map[string]string
}

type JournalPostingResult struct {
	OK bool

	TenantID  string
	RequestID string

	JournalNo string
	Status    JournalStatus

	Source SourceDocumentRef
	Fiscal FiscalContext

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

	if ctx.PostingDate.IsZero() {
		return ErrPostingDateRequired
	}

	return nil
}

func ValidateJournalLineDraft(line JournalLineDraft) error {
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

func ValidateJournalDraft(draft JournalDraft) error {
	if strings.TrimSpace(draft.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(draft.JournalNo) == "" {
		return ErrJournalNoRequired
	}

	if err := ValidateSourceDocumentRef(draft.Source); err != nil {
		return err
	}

	if err := ValidateFiscalContext(draft.Fiscal); err != nil {
		return err
	}

	status := draft.Status
	if strings.TrimSpace(string(status)) == "" {
		status = JournalStatusDraft
	}

	if !isValidJournalStatus(status) {
		return ErrJournalStatusInvalid
	}

	if len(draft.Lines) < 2 {
		return ErrJournalLineCountInvalid
	}

	for _, line := range draft.Lines {
		if err := ValidateJournalLineDraft(line); err != nil {
			return err
		}
	}

	if !IsBalanced(draft.Lines) {
		return ErrJournalUnbalanced
	}

	return nil
}

func ValidateJournalPostingRequest(req JournalPostingRequest) error {
	if err := ValidateTenantContext(req.Tenant); err != nil {
		return err
	}

	if err := ValidateSourceDocumentRef(req.Source); err != nil {
		return err
	}

	if err := ValidateFiscalContext(req.Fiscal); err != nil {
		return err
	}

	if strings.TrimSpace(req.JournalNo) == "" {
		return ErrJournalNoRequired
	}

	draft := JournalDraft{
		TenantID:    req.Tenant.TenantID,
		JournalNo:   req.JournalNo,
		Source:      req.Source,
		Fiscal:      req.Fiscal,
		Status:      JournalStatusDraft,
		Lines:       req.Lines,
		Description: req.Description,
	}

	return ValidateJournalDraft(draft)
}

func BuildJournalDraft(req JournalPostingRequest) (JournalDraft, error) {
	if err := ValidateJournalPostingRequest(req); err != nil {
		return JournalDraft{}, err
	}

	return JournalDraft{
		TenantID:    req.Tenant.TenantID,
		JournalNo:   req.JournalNo,
		Source:      req.Source,
		Fiscal:      req.Fiscal,
		Description: req.Description,
		Status:      JournalStatusDraft,
		Lines:       req.Lines,
	}, nil
}

func BuildJournalPostingResult(req JournalPostingRequest, status JournalStatus, message string) (JournalPostingResult, error) {
	if err := ValidateJournalPostingRequest(req); err != nil {
		return JournalPostingResult{}, err
	}

	if !isValidJournalStatus(status) {
		return JournalPostingResult{}, ErrJournalStatusInvalid
	}

	totalDebit, totalCredit := SumJournalLines(req.Lines)

	return JournalPostingResult{
		OK:          true,
		TenantID:    req.Tenant.TenantID,
		RequestID:   req.Tenant.RequestID,
		JournalNo:   req.JournalNo,
		Status:      status,
		Source:      req.Source,
		Fiscal:      req.Fiscal,
		TotalDebit:  totalDebit,
		TotalCredit: totalCredit,
		PostedAt:    time.Now().UTC(),
		Message:     message,
	}, nil
}

func SumJournalLines(lines []JournalLineDraft) (float64, float64) {
	var totalDebit float64
	var totalCredit float64

	for _, line := range lines {
		totalDebit += line.DebitAmount
		totalCredit += line.CreditAmount
	}

	return roundAmount(totalDebit), roundAmount(totalCredit)
}

func IsBalanced(lines []JournalLineDraft) bool {
	totalDebit, totalCredit := SumJournalLines(lines)
	return math.Abs(totalDebit-totalCredit) < 0.000001
}

func isValidJournalStatus(status JournalStatus) bool {
	switch status {
	case JournalStatusDraft, JournalStatusPosted, JournalStatusReversed, JournalStatusCanceled:
		return true
	default:
		return false
	}
}

func roundAmount(value float64) float64 {
	return math.Round(value*100) / 100
}
