package domain

import (
	"time"

	tenancy "github.com/divrigili/pix2pi-SaaS/internal/platform/tenancy"
)

const (
	EventStoreDurumBekliyor = "bekliyor"
	EventStoreDurumTekrar   = "tekrar"
	EventStoreDurumIslendi  = "islendi"
	EventStoreDurumDlq      = "dlq"
)

type EventStoreRecord struct {
	StoreID    string
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

	Durum       string
	RetryCount  int
	MaxRetry    int
	ReplayCount int

	SonHata   string
	DlqNedeni string

	OlusturmaTarihi  time.Time
	GuncellemeTarihi time.Time
	IslenmeTarihi    time.Time
	SonRetryTarihi   time.Time
	SonReplayTarihi  time.Time
	DlqTarihi        time.Time
}

func (r EventStoreRecord) TenantIdentity() (tenancy.TenantIdentity, error) {
	return tenancy.NewTenantIdentity(r.TenantID, r.TenantUUID)
}

func (r EventStoreRecord) ValidateTenantIdentity() error {
	_, err := r.TenantIdentity()
	return err
}
