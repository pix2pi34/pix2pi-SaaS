package service

import (
	"fmt"
	"math"
	"time"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/events/domain"
)

type FinancialEventInput struct {
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

type FinancialEventService struct {
}

func NewFinancialEventService() *FinancialEventService {
	return &FinancialEventService{}
}

func (s *FinancialEventService) Build(
	input FinancialEventInput,
) (eventdomain.FinancialEventRecord, error) {
	if input.EventID == "" {
		return eventdomain.FinancialEventRecord{}, fmt.Errorf("event id cannot be empty")
	}

	if input.EventType == "" {
		return eventdomain.FinancialEventRecord{}, fmt.Errorf("event type cannot be empty")
	}

	if input.GrossAmount <= 0 {
		return eventdomain.FinancialEventRecord{}, fmt.Errorf("gross amount must be greater than zero")
	}

	if input.Currency == "" {
		return eventdomain.FinancialEventRecord{}, fmt.Errorf("currency cannot be empty")
	}

	netAmount, taxAmount, err := s.calculateNetAndTax(input.GrossAmount, input.TaxRate)
	if err != nil {
		return eventdomain.FinancialEventRecord{}, err
	}

	return eventdomain.FinancialEventRecord{
		EventID:       input.EventID,
		EventType:     input.EventType,
		SourceModule:  input.SourceModule,
		DocumentNo:    input.DocumentNo,
		ReferenceID:   input.ReferenceID,
		PaymentMethod: input.PaymentMethod,
		TaxRate:       input.TaxRate,
		GrossAmount:   round2(input.GrossAmount),
		NetAmount:     netAmount,
		TaxAmount:     taxAmount,
		Currency:      input.Currency,
		OccurredAt:    input.OccurredAt,
	}, nil
}

func (s *FinancialEventService) calculateNetAndTax(
	grossAmount float64,
	taxRate int,
) (float64, float64, error) {
	if taxRate < 0 {
		return 0, 0, fmt.Errorf("tax rate cannot be negative")
	}

	if taxRate == 0 {
		return round2(grossAmount), 0, nil
	}

	divisor := 1 + (float64(taxRate) / 100)
	netAmount := round2(grossAmount / divisor)
	taxAmount := round2(grossAmount - netAmount)

	return netAmount, taxAmount, nil
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
