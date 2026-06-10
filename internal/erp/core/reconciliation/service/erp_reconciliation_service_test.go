package service

import (
	"testing"

	ledgerdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/domain"
)

func sampleLedgerPostings() []ledgerdomain.LedgerPosting {
	return []ledgerdomain.LedgerPosting{
		{
			PostingID:    "JRNL-sale_1001-1",
			JournalID:    "JRNL-sale_1001",
			EventID:      "sale_1001",
			DocumentNo:   "DOC-1001",
			ReferenceID:  "REF-1001",
			SourceModule: "POS",
			AccountCode:  "100.01",
			Debit:        120,
			Credit:       0,
		},
		{
			PostingID:    "JRNL-sale_1001-2",
			JournalID:    "JRNL-sale_1001",
			EventID:      "sale_1001",
			DocumentNo:   "DOC-1001",
			ReferenceID:  "REF-1001",
			SourceModule: "POS",
			AccountCode:  "600.01.001",
			Debit:        0,
			Credit:       100,
		},
		{
			PostingID:    "JRNL-sale_1001-3",
			JournalID:    "JRNL-sale_1001",
			EventID:      "sale_1001",
			DocumentNo:   "DOC-1001",
			ReferenceID:  "REF-1001",
			SourceModule: "POS",
			AccountCode:  "391.01.20",
			Debit:        0,
			Credit:       20,
		},
	}
}

func TestReconciliationService_Reconcile_Success(t *testing.T) {
	svc := NewReconciliationService()

	result, err := svc.Reconcile(sampleLedgerPostings(), []ExternalMovement{
		{
			Source:      "bank",
			AccountCode: "100.01",
			Amount:      120,
			ReferenceID: "REF-1001",
		},
		{
			Source:      "sales",
			AccountCode: "600.01.001",
			Amount:      100,
			ReferenceID: "REF-1001",
		},
		{
			Source:      "tax",
			AccountCode: "391.01.20",
			Amount:      20,
			ReferenceID: "REF-1001",
		},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if result.MatchedCount != 3 {
		t.Fatalf("expected 3 matches, got %d", result.MatchedCount)
	}
	if result.UnmatchedCount != 0 {
		t.Fatalf("expected 0 unmatched, got %d", result.UnmatchedCount)
	}
}

func TestReconciliationService_Reconcile_Unmatched(t *testing.T) {
	svc := NewReconciliationService()

	result, err := svc.Reconcile(sampleLedgerPostings(), []ExternalMovement{
		{
			Source:      "bank",
			AccountCode: "100.01",
			Amount:      120,
			ReferenceID: "REF-1001",
		},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if result.MatchedCount != 1 {
		t.Fatalf("expected 1 match, got %d", result.MatchedCount)
	}
	if result.UnmatchedCount != 2 {
		t.Fatalf("expected 2 unmatched, got %d", result.UnmatchedCount)
	}
}

func TestReconciliationService_Reconcile_InvalidPosting(t *testing.T) {
	svc := NewReconciliationService()

	postings := sampleLedgerPostings()
	postings[0].AccountCode = ""

	_, err := svc.Reconcile(postings, []ExternalMovement{
		{
			Source:      "bank",
			AccountCode: "100.01",
			Amount:      120,
			ReferenceID: "REF-1001",
		},
	})
	if err == nil {
		t.Fatal("expected invalid posting error")
	}
}

func TestReconciliationService_Reconcile_EmptyPostings(t *testing.T) {
	svc := NewReconciliationService()

	_, err := svc.Reconcile(nil, nil)
	if err == nil {
		t.Fatal("expected empty postings error")
	}
}
