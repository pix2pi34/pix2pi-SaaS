package domain

import "time"

type EventStoreRecord struct {
	StoreID         string
	EventID         string
	TenantID        string
	TenantUUID      string
	Topic           string
	Payload         string
	Version         int
	OlusturmaTarihi time.Time
}
