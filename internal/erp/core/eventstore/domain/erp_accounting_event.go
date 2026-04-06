package domain

import "time"

type AccountingEvent struct {
	EventID         string
	TenantID        string
	TenantUUID      string
	EventType       string
	ReferenceID     string
	Tutar           float64
	KdvOrani        float64
	OlusturmaTarihi time.Time
}
