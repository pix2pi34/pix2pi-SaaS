package journalpost

import (
	"errors"
	"testing"
	"time"
)

func validJournalPostingRequest() JournalPostingRequest {
	return JournalPostingRequest{
		Tenant: TenantContext{
			TenantID:  "tenant_7",
			RequestID: "req-123",
			ActorID:   "user-1",
			ActorType: "user",
		},
		Source: SourceDocumentRef{
			SourceModule:       "sales",
			SourceDocumentType: "invoice",
			SourceDocumentID:   "invoice-id-1",
			SourceDocumentNo:   "INV-000001",
		},
		Fiscal: FiscalContext{
			FiscalYear:   2026,
			FiscalPeriod: "2026-04",
			PostingDate:  time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC),
		},
		JournalNo:   "JRNL-2026-000001",
		Description: "Sales invoice posting",
		Lines: []JournalLineDraft{
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
			"source": "faz3_10_4a_test",
		},
	}
}

func TestValidateJournalPostingRequestSuccess(t *testing.T) {
	req := validJournalPostingRequest()

	if err := ValidateJournalPostingRequest(req); err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateJournalPostingRequestTenantRequired(t *testing.T) {
	req := validJournalPostingRequest()
	req.Tenant.TenantID = ""

	err := ValidateJournalPostingRequest(req)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateJournalPostingRequestSourceRequired(t *testing.T) {
	req := validJournalPostingRequest()
	req.Source.SourceDocumentID = ""
	req.Source.SourceDocumentNo = ""

	err := ValidateJournalPostingRequest(req)
	if !errors.Is(err, ErrSourceDocumentRequired) {
		t.Fatalf("expected ErrSourceDocumentRequired, got %v", err)
	}
}

func TestValidateJournalPostingRequestJournalNoRequired(t *testing.T) {
	req := validJournalPostingRequest()
	req.JournalNo = ""

	err := ValidateJournalPostingRequest(req)
	if !errors.Is(err, ErrJournalNoRequired) {
		t.Fatalf("expected ErrJournalNoRequired, got %v", err)
	}
}

func TestValidateJournalPostingRequestFiscalYearInvalid(t *testing.T) {
	req := validJournalPostingRequest()
	req.Fiscal.FiscalYear = 1999

	err := ValidateJournalPostingRequest(req)
	if !errors.Is(err, ErrFiscalYearInvalid) {
		t.Fatalf("expected ErrFiscalYearInvalid, got %v", err)
	}
}

func TestValidateJournalPostingRequestLineCountInvalid(t *testing.T) {
	req := validJournalPostingRequest()
	req.Lines = req.Lines[:1]

	err := ValidateJournalPostingRequest(req)
	if !errors.Is(err, ErrJournalLineCountInvalid) {
		t.Fatalf("expected ErrJournalLineCountInvalid, got %v", err)
	}
}

func TestValidateJournalPostingRequestAccountCodeRequired(t *testing.T) {
	req := validJournalPostingRequest()
	req.Lines[0].AccountCode = ""

	err := ValidateJournalPostingRequest(req)
	if !errors.Is(err, ErrAccountCodeRequired) {
		t.Fatalf("expected ErrAccountCodeRequired, got %v", err)
	}
}

func TestValidateJournalPostingRequestAmountInvalid(t *testing.T) {
	req := validJournalPostingRequest()
	req.Lines[0].DebitAmount = -1

	err := ValidateJournalPostingRequest(req)
	if !errors.Is(err, ErrAmountInvalid) {
		t.Fatalf("expected ErrAmountInvalid, got %v", err)
	}
}

func TestValidateJournalPostingRequestUnbalanced(t *testing.T) {
	req := validJournalPostingRequest()
	req.Lines[1].CreditAmount = 99

	err := ValidateJournalPostingRequest(req)
	if !errors.Is(err, ErrJournalUnbalanced) {
		t.Fatalf("expected ErrJournalUnbalanced, got %v", err)
	}
}

func TestSumJournalLines(t *testing.T) {
	req := validJournalPostingRequest()

	totalDebit, totalCredit := SumJournalLines(req.Lines)

	if totalDebit != 120 {
		t.Fatalf("expected total debit 120, got %v", totalDebit)
	}

	if totalCredit != 120 {
		t.Fatalf("expected total credit 120, got %v", totalCredit)
	}
}

func TestBuildJournalDraftSuccess(t *testing.T) {
	req := validJournalPostingRequest()

	draft, err := BuildJournalDraft(req)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if draft.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", draft.TenantID)
	}

	if draft.JournalNo != req.JournalNo {
		t.Fatalf("expected journal no %s, got %s", req.JournalNo, draft.JournalNo)
	}

	if draft.Status != JournalStatusDraft {
		t.Fatalf("expected draft status, got %s", draft.Status)
	}

	if len(draft.Lines) != 3 {
		t.Fatalf("expected 3 lines, got %d", len(draft.Lines))
	}
}

func TestBuildJournalPostingResultSuccess(t *testing.T) {
	req := validJournalPostingRequest()

	result, err := BuildJournalPostingResult(req, JournalStatusPosted, "journal posted")
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

	if result.Status != JournalStatusPosted {
		t.Fatalf("expected posted status, got %s", result.Status)
	}

	if result.TotalDebit != 120 || result.TotalCredit != 120 {
		t.Fatalf("expected totals 120/120, got %v/%v", result.TotalDebit, result.TotalCredit)
	}

	if result.PostedAt.IsZero() {
		t.Fatal("expected posted_at")
	}
}

func TestBuildJournalPostingResultStatusInvalid(t *testing.T) {
	req := validJournalPostingRequest()

	_, err := BuildJournalPostingResult(req, JournalStatus("wrong"), "bad")
	if !errors.Is(err, ErrJournalStatusInvalid) {
		t.Fatalf("expected ErrJournalStatusInvalid, got %v", err)
	}
}
