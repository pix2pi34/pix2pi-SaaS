package service

import (
	"fmt"
	"strings"
	"time"
)

type EventIntake struct {
	TenantID      string
	EventID       string
	EventType     string
	SourceModule  string
	DocumentNo    string
	ReferenceID   string
	PaymentMethod string
	TaxRate       int
	GrossAmount   float64
	Currency      string
	OccurredAt    time.Time
}

type EventIntakeService struct {
}

func NewEventIntakeService() *EventIntakeService {
	return &EventIntakeService{}
}

func (s *EventIntakeService) Normalize(
	input EventIntake,
) (EventIntake, error) {
	tenantID := strings.TrimSpace(input.TenantID)
	if tenantID == "" {
		return EventIntake{}, fmt.Errorf("tenant id cannot be empty")
	}

	eventID := strings.TrimSpace(input.EventID)
	if eventID == "" {
		return EventIntake{}, fmt.Errorf("event id cannot be empty")
	}

	if input.GrossAmount <= 0 {
		return EventIntake{}, fmt.Errorf("gross amount must be greater than zero")
	}

	eventType := normalizeEventType(input.EventType)
	if eventType == "" {
		return EventIntake{}, fmt.Errorf("event type cannot be empty")
	}

	sourceModule := strings.TrimSpace(input.SourceModule)
	if sourceModule == "" {
		sourceModule = "pos"
	}

	paymentMethod := strings.TrimSpace(strings.ToLower(input.PaymentMethod))
	if paymentMethod == "" {
		paymentMethod = "cash"
	}

	currency := strings.TrimSpace(strings.ToUpper(input.Currency))
	if currency == "" {
		currency = "TRY"
	}

	documentNo := strings.TrimSpace(input.DocumentNo)
	if documentNo == "" {
		documentNo = eventID
	}

	referenceID := strings.TrimSpace(input.ReferenceID)
	if referenceID == "" {
		referenceID = eventID
	}

	taxRate := input.TaxRate
	if taxRate == 0 {
		taxRate = 20
	}
	if taxRate < 0 {
		return EventIntake{}, fmt.Errorf("tax rate cannot be negative")
	}

	occurredAt := input.OccurredAt
	if occurredAt.IsZero() {
		occurredAt = time.Now()
	}

	return EventIntake{
		TenantID:      tenantID,
		EventID:       eventID,
		EventType:     eventType,
		SourceModule:  sourceModule,
		DocumentNo:    documentNo,
		ReferenceID:   referenceID,
		PaymentMethod: paymentMethod,
		TaxRate:       taxRate,
		GrossAmount:   input.GrossAmount,
		Currency:      currency,
		OccurredAt:    occurredAt,
	}, nil
}

func (i EventIntake) ToFinancialEventInput() FinancialEventInput {
	return FinancialEventInput{
		EventID:       i.EventID,
		EventType:     i.EventType,
		SourceModule:  i.SourceModule,
		DocumentNo:    i.DocumentNo,
		ReferenceID:   i.ReferenceID,
		PaymentMethod: i.PaymentMethod,
		TaxRate:       i.TaxRate,
		GrossAmount:   i.GrossAmount,
		Currency:      i.Currency,
		OccurredAt:    i.OccurredAt,
	}
}

func normalizeEventType(v string) string {
	v = strings.TrimSpace(strings.ToLower(v))

	switch v {
	case "":
		return "sale.completed"
	case "sale.created":
		return "sale.completed"
	default:
		return v
	}
}
