package service

import (
	"time"

	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
)

type EventStorePort interface {
	EventVarMi(eventID string) bool
	IdempotencyKaydiVarMi(
		tenantID string,
		topic string,
		idempotencyKey string,
	) bool

	Kaydet(kayit eventstoredomain.EventStoreRecord) error
	EventIDIleGetir(eventID string) (eventstoredomain.EventStoreRecord, error)

	DurumGuncelle(eventID string, durum string) error
	RetryGuncelle(
		eventID string,
		retryCount int,
		sonHata string,
		zaman time.Time,
	) error
	IslendiOlarakIsaretle(eventID string, zaman time.Time) error
	DlqOlarakIsaretle(
		eventID string,
		retryCount int,
		neden string,
		zaman time.Time,
	) error
	YenidenKuyrugaAlOlarakIsaretle(eventID string, zaman time.Time) error
	ReplayGuncelle(eventID string, zaman time.Time) error

	TumKayitlariListele() []eventstoredomain.EventStoreRecord
	TenantKayitlariniListele(tenantID string) []eventstoredomain.EventStoreRecord
	TopicKayitlariniListele(topic string) []eventstoredomain.EventStoreRecord
	TenantTopicKayitlariniListele(
		tenantID string,
		topic string,
	) []eventstoredomain.EventStoreRecord
}
