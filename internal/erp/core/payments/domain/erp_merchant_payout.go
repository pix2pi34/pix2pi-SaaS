package domain

import "time"

const (
	PayoutStatusPending  = "pending"
	PayoutStatusApproved = "approved"
	PayoutStatusRejected = "rejected"
)

type MerchantPayout struct {
	PayoutID          string
	MerchantAccountID string
	PayoutAccountID   string
	Amount            float64
	Currency          string
	Status            string
	Description       string
	RequestedAt       time.Time
	ApprovedAt        time.Time
}
