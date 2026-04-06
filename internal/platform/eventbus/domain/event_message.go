package domain

import "time"

const (
	EventDurumBekliyor = "bekliyor"
	EventDurumIslendi  = "islendi"
	EventDurumHata     = "hata"
	EventDurumDlq      = "dlq"
)

type EventMessage struct {
	EventID         string
	TenantID        string
	TenantUUID      string
	Topic           string
	Payload         string
	Durum           string
	RetryCount      int
	MaxRetry        int
	OlusturmaTarihi time.Time
	IslenmeTarihi   time.Time
}
