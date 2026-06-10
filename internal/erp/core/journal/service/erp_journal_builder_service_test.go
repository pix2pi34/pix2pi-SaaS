package service

import (
	"testing"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/events/domain"
	ruledomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/rules/domain"
)

func sampleFinancialEvent() eventdomain.FinancialEventRecord {
	return eventdomain.FinancialEventRecord{
		EventID:       "sale_1001",
		EventType:     "sale.completed",
		SourceModule:  "POS",
		DocumentNo:    "DOC-1001",
		ReferenceID:   "REF-1001",
		PaymentMethod: "cash",
		TaxRate:       20,
		GrossAmount:   120.00,
		NetAmount:     100.00,
		TaxAmount:     20.00,
		Currency:      "TRY",
	}
}

func sampleAccountingRule() ruledomain.AccountingRule {
	return ruledomain.AccountingRule{
		RuleID:         "SALE_CASH_V1",
		EventType:      "sale.completed",
		PaymentMethod:  "cash",
		TaxRate:        20,
		Version:        1,
		Active:         true,
		SourceModule:   "POS",
		DebitAccount:   "100.01",
		RevenueAccount: "600.01.001",
		TaxAccount:     "391.01.20",
	}
}

func TestJournalBuilderService_Build_Success(t *testing.T) {
	svc := NewJournalBuilderService()

	entry, err := svc.Build(sampleFinancialEvent(), sampleAccountingRule())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if entry.JournalID != "JRNL-sale_1001" {
		t.Fatalf("expected JRNL-sale_1001, got %s", entry.JournalID)
	}
	if entry.EventID != "sale_1001" {
		t.Fatalf("expected sale_1001, got %s", entry.EventID)
	}
	if len(entry.Lines) != 3 {
		t.Fatalf("expected 3 lines, got %d", len(entry.Lines))
	}
}

func TestJournalBuilderService_Build_Balanced(t *testing.T) {
	svc := NewJournalBuilderService()

	entry, err := svc.Build(sampleFinancialEvent(), sampleAccountingRule())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	totalDebit := 0.0
	totalCredit := 0.0

	for _, line := range entry.Lines {
		totalDebit += line.Debit
		totalCredit += line.Credit
	}

	if round2(totalDebit) != round2(totalCredit) {
		t.Fatalf("expected balanced entry, debit=%.2f credit=%.2f", totalDebit, totalCredit)
	}
}

func TestJournalBuilderService_Build_InvalidEvent(t *testing.T) {
	svc := NewJournalBuilderService()

	event := sampleFinancialEvent()
	event.EventID = ""

	_, err := svc.Build(event, sampleAccountingRule())
	if err == nil {
		t.Fatal("expected invalid event error")
	}
}

func TestJournalBuilderService_Build_InvalidRule(t *testing.T) {
	svc := NewJournalBuilderService()

	rule := sampleAccountingRule()
	rule.DebitAccount = ""

	_, err := svc.Build(sampleFinancialEvent(), rule)
	if err == nil {
		t.Fatal("expected invalid rule error")
	}
}

func TestJournalBuilderService_Build_UnbalancedFinancialEvent(t *testing.T) {
	svc := NewJournalBuilderService()

	event := sampleFinancialEvent()
	event.NetAmount = 90
	event.TaxAmount = 5

	_, err := svc.Build(event, sampleAccountingRule())
	if err == nil {
		t.Fatal("expected unbalanced financial event error")
	}
}
