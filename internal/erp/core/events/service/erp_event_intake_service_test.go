package service

import (
	"testing"
	"time"
)

func TestEventIntakeService_Normalize_Defaults(t *testing.T) {
	svc := NewEventIntakeService()

	got, err := svc.Normalize(EventIntake{
		TenantID:    "tenant_42",
		EventID:     "sale_1001",
		GrossAmount: 1200.50,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if got.EventType != "sale.completed" {
		t.Fatalf("expected sale.completed, got %s", got.EventType)
	}
	if got.SourceModule != "pos" {
		t.Fatalf("expected pos, got %s", got.SourceModule)
	}
	if got.PaymentMethod != "cash" {
		t.Fatalf("expected cash, got %s", got.PaymentMethod)
	}
	if got.Currency != "TRY" {
		t.Fatalf("expected TRY, got %s", got.Currency)
	}
	if got.DocumentNo != "sale_1001" {
		t.Fatalf("expected sale_1001, got %s", got.DocumentNo)
	}
	if got.ReferenceID != "sale_1001" {
		t.Fatalf("expected sale_1001, got %s", got.ReferenceID)
	}
	if got.TaxRate != 20 {
		t.Fatalf("expected 20, got %d", got.TaxRate)
	}
	if got.OccurredAt.IsZero() {
		t.Fatal("expected occurred_at to be set")
	}
}

func TestEventIntakeService_Normalize_SaleCreatedBecomesCompleted(t *testing.T) {
	svc := NewEventIntakeService()

	got, err := svc.Normalize(EventIntake{
		TenantID:    "tenant_42",
		EventID:     "sale_1002",
		EventType:   "sale.created",
		GrossAmount: 500,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if got.EventType != "sale.completed" {
		t.Fatalf("expected sale.completed, got %s", got.EventType)
	}
}

func TestEventIntakeService_Normalize_RequiresTenant(t *testing.T) {
	svc := NewEventIntakeService()

	_, err := svc.Normalize(EventIntake{
		TenantID:    "",
		EventID:     "sale_1003",
		EventType:   "sale.completed",
		GrossAmount: 100,
	})
	if err == nil {
		t.Fatal("expected tenant error")
	}
}

func TestEventIntakeService_Normalize_RequiresPositiveAmount(t *testing.T) {
	svc := NewEventIntakeService()

	_, err := svc.Normalize(EventIntake{
		TenantID:    "tenant_42",
		EventID:     "sale_1004",
		EventType:   "sale.completed",
		GrossAmount: 0,
	})
	if err == nil {
		t.Fatal("expected amount error")
	}
}

func TestEventIntake_ToFinancialEventInput(t *testing.T) {
	now := time.Now()

	input := EventIntake{
		TenantID:      "tenant_42",
		EventID:       "sale_1005",
		EventType:     "sale.completed",
		SourceModule:  "pos",
		DocumentNo:    "DOC-1005",
		ReferenceID:   "REF-1005",
		PaymentMethod: "pos",
		TaxRate:       20,
		GrossAmount:   240,
		Currency:      "TRY",
		OccurredAt:    now,
	}

	got := input.ToFinancialEventInput()

	if got.EventID != "sale_1005" {
		t.Fatalf("expected sale_1005, got %s", got.EventID)
	}
	if got.EventType != "sale.completed" {
		t.Fatalf("expected sale.completed, got %s", got.EventType)
	}
	if got.PaymentMethod != "pos" {
		t.Fatalf("expected pos, got %s", got.PaymentMethod)
	}
	if got.OccurredAt != now {
		t.Fatal("expected occurred_at preserved")
	}
}
