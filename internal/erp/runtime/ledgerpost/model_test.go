package ledgerpost

import (
	"errors"
	"testing"
	"time"
)

func validLedgerPostingRequest() LedgerPostingRequest {
	return LedgerPostingRequest{
		Tenant: TenantContext{
			TenantID:  "tenant_7",
			RequestID: "req-123",
			ActorID:   "user-1",
			ActorType: "user",
		},
		Journal: JournalRef{
			JournalEntryID: "journal-entry-id-1",
			JournalNo:      "JRNL-2026-000001",
			JournalStatus:  JournalStatusPosted,
		},
		Fiscal: FiscalContext{
			FiscalYear:   2026,
			FiscalPeriod: "2026-04",
			PostingDate:  time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC),
		},
		Description: "Ledger posting test",
		Lines: []LedgerLineDraft{
			{
				LineNo:       1,
				AccountCode:  "120.01",
				AccountName:  "Alicilar",
				DebitAmount:  120,
				CurrencyCode: "TRY",
				ExchangeRate: 1,
				Description:  "Cari borc",
			},
			{
				LineNo:       2,
				AccountCode:  "600.01",
				AccountName:  "Yurt Ici Satislar",
				CreditAmount: 100,
				CurrencyCode: "TRY",
				ExchangeRate: 1,
				Description:  "Satis geliri",
			},
			{
				LineNo:       3,
				AccountCode:  "391.01",
				AccountName:  "Hesaplanan KDV",
				CreditAmount: 20,
				CurrencyCode: "TRY",
				ExchangeRate: 1,
				Description:  "KDV",
			},
		},
		Metadata: map[string]string{
			"source": "faz3_10_5a_test",
		},
	}
}

func TestValidateLedgerPostingRequestSuccess(t *testing.T) {
	req := validLedgerPostingRequest()

	if err := ValidateLedgerPostingRequest(req); err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateLedgerPostingRequestTenantRequired(t *testing.T) {
	req := validLedgerPostingRequest()
	req.Tenant.TenantID = ""

	err := ValidateLedgerPostingRequest(req)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateLedgerPostingRequestJournalRefRequired(t *testing.T) {
	req := validLedgerPostingRequest()
	req.Journal.JournalEntryID = ""
	req.Journal.JournalNo = ""

	err := ValidateLedgerPostingRequest(req)
	if !errors.Is(err, ErrJournalRefRequired) {
		t.Fatalf("expected ErrJournalRefRequired, got %v", err)
	}
}

func TestValidateLedgerPostingRequestJournalStatusInvalid(t *testing.T) {
	req := validLedgerPostingRequest()
	req.Journal.JournalStatus = JournalStatusDraft

	err := ValidateLedgerPostingRequest(req)
	if !errors.Is(err, ErrJournalStatusInvalid) {
		t.Fatalf("expected ErrJournalStatusInvalid, got %v", err)
	}
}

func TestValidateLedgerPostingRequestFiscalYearInvalid(t *testing.T) {
	req := validLedgerPostingRequest()
	req.Fiscal.FiscalYear = 1999

	err := ValidateLedgerPostingRequest(req)
	if !errors.Is(err, ErrFiscalYearInvalid) {
		t.Fatalf("expected ErrFiscalYearInvalid, got %v", err)
	}
}

func TestValidateLedgerPostingRequestLineCountInvalid(t *testing.T) {
	req := validLedgerPostingRequest()
	req.Lines = req.Lines[:1]

	err := ValidateLedgerPostingRequest(req)
	if !errors.Is(err, ErrLedgerLineCountInvalid) {
		t.Fatalf("expected ErrLedgerLineCountInvalid, got %v", err)
	}
}

func TestValidateLedgerPostingRequestAccountCodeRequired(t *testing.T) {
	req := validLedgerPostingRequest()
	req.Lines[0].AccountCode = ""

	err := ValidateLedgerPostingRequest(req)
	if !errors.Is(err, ErrAccountCodeRequired) {
		t.Fatalf("expected ErrAccountCodeRequired, got %v", err)
	}
}

func TestValidateLedgerPostingRequestAmountInvalid(t *testing.T) {
	req := validLedgerPostingRequest()
	req.Lines[0].DebitAmount = -1

	err := ValidateLedgerPostingRequest(req)
	if !errors.Is(err, ErrAmountInvalid) {
		t.Fatalf("expected ErrAmountInvalid, got %v", err)
	}
}

func TestValidateLedgerPostingRequestUnbalanced(t *testing.T) {
	req := validLedgerPostingRequest()
	req.Lines[1].CreditAmount = 99

	err := ValidateLedgerPostingRequest(req)
	if !errors.Is(err, ErrLedgerUnbalanced) {
		t.Fatalf("expected ErrLedgerUnbalanced, got %v", err)
	}
}

func TestBuildAccountMovementsSuccess(t *testing.T) {
	req := validLedgerPostingRequest()

	movements, err := BuildAccountMovements(req.Lines)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if len(movements) != 3 {
		t.Fatalf("expected 3 movements, got %d", len(movements))
	}

	if movements[0].MovementDirection != MovementDirectionDebit {
		t.Fatalf("expected debit movement, got %s", movements[0].MovementDirection)
	}

	if movements[0].SignedAmount != 120 {
		t.Fatalf("expected signed amount 120, got %v", movements[0].SignedAmount)
	}

	if movements[1].MovementDirection != MovementDirectionCredit {
		t.Fatalf("expected credit movement, got %s", movements[1].MovementDirection)
	}

	if movements[1].SignedAmount != -100 {
		t.Fatalf("expected signed amount -100, got %v", movements[1].SignedAmount)
	}
}

func TestSumLedgerLines(t *testing.T) {
	req := validLedgerPostingRequest()

	totalDebit, totalCredit := SumLedgerLines(req.Lines)

	if totalDebit != 120 {
		t.Fatalf("expected total debit 120, got %v", totalDebit)
	}

	if totalCredit != 120 {
		t.Fatalf("expected total credit 120, got %v", totalCredit)
	}
}

func TestBuildLedgerPostingDraftSuccess(t *testing.T) {
	req := validLedgerPostingRequest()

	draft, err := BuildLedgerPostingDraft(req)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if draft.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", draft.TenantID)
	}

	if draft.Status != LedgerPostingStatusDraft {
		t.Fatalf("expected draft status, got %s", draft.Status)
	}

	if len(draft.Movements) != 3 {
		t.Fatalf("expected 3 movements, got %d", len(draft.Movements))
	}
}

func TestValidateLedgerPostingDraftSuccess(t *testing.T) {
	req := validLedgerPostingRequest()

	draft, err := BuildLedgerPostingDraft(req)
	if err != nil {
		t.Fatalf("expected draft success, got %v", err)
	}

	if err := ValidateLedgerPostingDraft(draft); err != nil {
		t.Fatalf("expected validate success, got %v", err)
	}
}

func TestBuildLedgerPostingResultSuccess(t *testing.T) {
	req := validLedgerPostingRequest()

	draft, err := BuildLedgerPostingDraft(req)
	if err != nil {
		t.Fatalf("expected draft success, got %v", err)
	}

	draft.Status = LedgerPostingStatusPosted

	result, err := BuildLedgerPostingResult(req, draft, "ledger posted")
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}

	if result.TenantID != req.Tenant.TenantID {
		t.Fatalf("expected tenant %s, got %s", req.Tenant.TenantID, result.TenantID)
	}

	if result.RequestID != req.Tenant.RequestID {
		t.Fatalf("expected request_id %s, got %s", req.Tenant.RequestID, result.RequestID)
	}

	if result.Status != LedgerPostingStatusPosted {
		t.Fatalf("expected posted status, got %s", result.Status)
	}

	if result.MovementCount != 3 {
		t.Fatalf("expected movement count 3, got %d", result.MovementCount)
	}

	if result.TotalDebit != 120 || result.TotalCredit != 120 {
		t.Fatalf("expected totals 120/120, got %v/%v", result.TotalDebit, result.TotalCredit)
	}

	if result.PostedAt.IsZero() {
		t.Fatal("expected posted_at")
	}
}
