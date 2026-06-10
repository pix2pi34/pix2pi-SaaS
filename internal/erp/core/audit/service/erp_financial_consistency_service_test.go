package service

import (
	"testing"
	"time"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/events/domain"
	journaldomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/journal/domain"
	ledgerdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/domain"
)

func sampleConsistencyEvent() eventdomain.FinancialEventRecord {
	return eventdomain.FinancialEventRecord{
		EventID:       "sale_1001",
		EventType:     "sale.completed",
		SourceModule:  "POS",
		DocumentNo:    "DOC-1001",
		ReferenceID:   "REF-1001",
		PaymentMethod: "cash",
		TaxRate:       20,
		GrossAmount:   120,
		NetAmount:     100,
		TaxAmount:     20,
		Currency:      "TRY",
	}
}

func sampleConsistencyJournal() journaldomain.JournalEntry {
	return journaldomain.JournalEntry{
		JournalID:    "JRNL-sale_1001",
		EventID:      "sale_1001",
		DocumentNo:   "DOC-1001",
		ReferenceID:  "REF-1001",
		SourceModule: "POS",
		CreatedAt:    time.Now(),
		Lines: []journaldomain.JournalLine{
			{AccountCode: "100.01", Debit: 120, Credit: 0},
			{AccountCode: "600.01.001", Debit: 0, Credit: 100},
			{AccountCode: "391.01.20", Debit: 0, Credit: 20},
		},
	}
}

func sampleConsistencyPostings() []ledgerdomain.LedgerPosting {
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

func TestFinancialConsistencyService_Check_Success(t *testing.T) {
	svc := NewFinancialConsistencyService()

	result, err := svc.Check(
		sampleConsistencyEvent(),
		sampleConsistencyJournal(),
		sampleConsistencyPostings(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !result.IsConsistent {
		t.Fatal("expected consistent result")
	}
	if result.EventGrossAmount != 120 {
		t.Fatalf("expected 120, got %.2f", result.EventGrossAmount)
	}
}

func TestFinancialConsistencyService_Check_EventJournalMismatch(t *testing.T) {
	svc := NewFinancialConsistencyService()

	event := sampleConsistencyEvent()
	event.GrossAmount = 130

	_, err := svc.Check(
		event,
		sampleConsistencyJournal(),
		sampleConsistencyPostings(),
	)
	if err == nil {
		t.Fatal("expected mismatch error")
	}
}

func TestFinancialConsistencyService_Check_JournalLedgerMismatch(t *testing.T) {
	svc := NewFinancialConsistencyService()

	postings := sampleConsistencyPostings()
	postings[2].Credit = 10

	_, err := svc.Check(
		sampleConsistencyEvent(),
		sampleConsistencyJournal(),
		postings,
	)
	if err == nil {
		t.Fatal("expected journal ledger mismatch error")
	}
}

func TestFinancialConsistencyService_Check_PostingEventMismatch(t *testing.T) {
	svc := NewFinancialConsistencyService()

	postings := sampleConsistencyPostings()
	postings[0].EventID = "sale_9999"

	_, err := svc.Check(
		sampleConsistencyEvent(),
		sampleConsistencyJournal(),
		postings,
	)
	if err == nil {
		t.Fatal("expected posting event mismatch error")
	}
}
