package service

import (
	"testing"
	"time"

	journaldomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/journal/domain"
)

func sampleJournalEntry() journaldomain.JournalEntry {
	return journaldomain.JournalEntry{
		JournalID:    "JRNL-sale_1001",
		EventID:      "sale_1001",
		DocumentNo:   "DOC-1001",
		ReferenceID:  "REF-1001",
		SourceModule: "POS",
		CreatedAt:    time.Now(),
		Lines: []journaldomain.JournalLine{
			{
				AccountCode: "100.01",
				Debit:       120,
				Credit:      0,
			},
			{
				AccountCode: "600.01.001",
				Debit:       0,
				Credit:      100,
			},
			{
				AccountCode: "391.01.20",
				Debit:       0,
				Credit:      20,
			},
		},
	}
}

func TestLedgerPostingService_BuildFromJournal_Success(t *testing.T) {
	svc := NewLedgerPostingService()

	postings, err := svc.BuildFromJournal(sampleJournalEntry())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(postings) != 3 {
		t.Fatalf("expected 3 postings, got %d", len(postings))
	}
	if postings[0].PostingID != "JRNL-sale_1001-1" {
		t.Fatalf("expected JRNL-sale_1001-1, got %s", postings[0].PostingID)
	}
	if postings[0].JournalID != "JRNL-sale_1001" {
		t.Fatalf("expected JRNL-sale_1001, got %s", postings[0].JournalID)
	}
	if postings[0].EventID != "sale_1001" {
		t.Fatalf("expected sale_1001, got %s", postings[0].EventID)
	}
}

func TestLedgerPostingService_BuildFromJournal_Balanced(t *testing.T) {
	svc := NewLedgerPostingService()

	postings, err := svc.BuildFromJournal(sampleJournalEntry())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	totalDebit := 0.0
	totalCredit := 0.0

	for _, posting := range postings {
		totalDebit += posting.Debit
		totalCredit += posting.Credit
	}

	if round2(totalDebit) != round2(totalCredit) {
		t.Fatalf("expected balanced postings, debit=%.2f credit=%.2f", totalDebit, totalCredit)
	}
}

func TestLedgerPostingService_BuildFromJournal_InvalidJournalID(t *testing.T) {
	svc := NewLedgerPostingService()

	journal := sampleJournalEntry()
	journal.JournalID = ""

	_, err := svc.BuildFromJournal(journal)
	if err == nil {
		t.Fatal("expected invalid journal id error")
	}
}

func TestLedgerPostingService_BuildFromJournal_InvalidEventID(t *testing.T) {
	svc := NewLedgerPostingService()

	journal := sampleJournalEntry()
	journal.EventID = ""

	_, err := svc.BuildFromJournal(journal)
	if err == nil {
		t.Fatal("expected invalid event id error")
	}
}

func TestLedgerPostingService_BuildFromJournal_InvalidLine(t *testing.T) {
	svc := NewLedgerPostingService()

	journal := sampleJournalEntry()
	journal.Lines[0].AccountCode = ""

	_, err := svc.BuildFromJournal(journal)
	if err == nil {
		t.Fatal("expected invalid line error")
	}
}

func TestLedgerPostingService_BuildFromJournal_Unbalanced(t *testing.T) {
	svc := NewLedgerPostingService()

	journal := sampleJournalEntry()
	journal.Lines[2].Credit = 10

	_, err := svc.BuildFromJournal(journal)
	if err == nil {
		t.Fatal("expected unbalanced posting error")
	}
}
