package domain

import "time"

const (
	SettlementStatusPending   = "pending"
	SettlementStatusPrepared  = "prepared"
	SettlementStatusCompleted = "completed"
)

type SettlementItem struct {
	ItemID           string
	MerchantAccountID string
	PayoutAccountID  string
	Amount           float64
	Currency         string
}

type SettlementBatch struct {
	BatchID       string
	Status        string
	Currency      string
	Items         []SettlementItem
	TotalAmount   float64
	CreatedAt     time.Time
	PreparedAt    time.Time
}
