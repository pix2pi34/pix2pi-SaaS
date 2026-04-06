package domain

import "time"

type FinancialEvent struct {
	ID          string
	Type        string
	ReferenceID string
	Amount      float64
	Currency    string
	OccurredAt  time.Time
}
