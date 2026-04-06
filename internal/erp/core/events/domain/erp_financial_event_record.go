package domain

import "time"

type FinancialEventRecord struct {
	EventID        string
	EventType      string
	SourceModule   string
	DocumentNo     string
	ReferenceID    string
	PaymentMethod  string
	TaxRate        int
	GrossAmount    float64
	NetAmount      float64
	TaxAmount      float64
	Currency       string
	OccurredAt     time.Time
}
