package domain

import (
	"time"

	tenancy "github.com/divrigili/pix2pi-SaaS/internal/platform/tenancy"
)

const (
	EventDurumBekliyor = "bekliyor"
	EventDurumIslendi  = "islendi"
	EventDurumHata     = "hata"
	EventDurumDlq      = "dlq"
)

type EventMessage struct {
	EventID    string
	TenantID   string
	TenantUUID string
	Topic      string
	Payload    string

	SozlesmeAdi       string
	SozlesmeVersiyonu int

	CorrelationID  string
	CausationID    string
	IdempotencyKey string
	SourceService  string
	Version        int

	Durum      string
	RetryCount int
	MaxRetry   int

	OlusturmaTarihi time.Time
	IslenmeTarihi   time.Time
}

func (e EventMessage) TenantIdentity() (tenancy.TenantIdentity, error) {
	return tenancy.NewTenantIdentity(e.TenantID, e.TenantUUID)
}

func (e EventMessage) ValidateTenantIdentity() error {
	_, err := e.TenantIdentity()
	return err
}
