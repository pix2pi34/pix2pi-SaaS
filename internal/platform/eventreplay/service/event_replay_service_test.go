package service

import (
	"testing"
	"time"

	eventbusservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/service"
	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
	eventstoreservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/service"
)

type fakeReplayStore struct {
	kayitlar      []eventstoredomain.EventStoreRecord
	replayUpdated int
}

func (f *fakeReplayStore) Kaydet(kayit eventstoredomain.EventStoreRecord) error {
	f.kayitlar = append(f.kayitlar, kayit)
	return nil
}

func (f *fakeReplayStore) EventIDIleGetir(eventID string) (eventstoredomain.EventStoreRecord, error) {
	for _, k := range f.kayitlar {
		if k.EventID == eventID {
			return k, nil
		}
	}
	return eventstoredomain.EventStoreRecord{}, nil
}

func (f *fakeReplayStore) EventVarMi(eventID string) bool {
	for _, k := range f.kayitlar {
		if k.EventID == eventID {
			return true
		}
	}
	return false
}

func (f *fakeReplayStore) IdempotencyKaydiVarMi(tenantID string, topic string, idempotencyKey string) bool {
	return false
}

func (f *fakeReplayStore) DurumGuncelle(eventID string, durum string) error {
	return nil
}

func (f *fakeReplayStore) RetryGuncelle(eventID string, retryCount int, sonHata string, zaman time.Time) error {
	return nil
}

func (f *fakeReplayStore) IslendiOlarakIsaretle(eventID string, zaman time.Time) error {
	return nil
}

func (f *fakeReplayStore) DlqOlarakIsaretle(eventID string, retryCount int, neden string, zaman time.Time) error {
	return nil
}

func (f *fakeReplayStore) YenidenKuyrugaAlOlarakIsaretle(eventID string, zaman time.Time) error {
	return nil
}

func (f *fakeReplayStore) ReplayGuncelle(eventID string, zaman time.Time) error {
	f.replayUpdated++
	return nil
}

func (f *fakeReplayStore) TumKayitlariListele() []eventstoredomain.EventStoreRecord {
	return f.kayitlar
}

func (f *fakeReplayStore) TenantKayitlariniListele(tenantID string) []eventstoredomain.EventStoreRecord {
	sonuc := make([]eventstoredomain.EventStoreRecord, 0)
	for _, k := range f.kayitlar {
		if k.TenantID == tenantID {
			sonuc = append(sonuc, k)
		}
	}
	return sonuc
}

func (f *fakeReplayStore) TopicKayitlariniListele(topic string) []eventstoredomain.EventStoreRecord {
	sonuc := make([]eventstoredomain.EventStoreRecord, 0)
	for _, k := range f.kayitlar {
		if k.Topic == topic {
			sonuc = append(sonuc, k)
		}
	}
	return sonuc
}

func (f *fakeReplayStore) TenantTopicKayitlariniListele(tenantID string, topic string) []eventstoredomain.EventStoreRecord {
	sonuc := make([]eventstoredomain.EventStoreRecord, 0)
	for _, k := range f.kayitlar {
		if k.TenantID == tenantID && k.Topic == topic {
			sonuc = append(sonuc, k)
		}
	}
	return sonuc
}

func TestEventReplayService_ReplayTenantEventleriniBusaBas_Success(t *testing.T) {
	store := eventstoreservice.NewEventStoreService()

	err := store.Kaydet(eventstoredomain.EventStoreRecord{
		StoreID:        "store-1",
		EventID:        "evt-1",
		TenantID:       "tenant_42",
		TenantUUID:     "uuid-42",
		Topic:          "sale.created",
		Payload:        `{"ok":true}`,
		IdempotencyKey: "idem-1",
		SourceService:  "sales",
		MaxRetry:       3,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	bus := eventbusservice.NewEventBusService()
	replay := NewEventReplayService(store, bus)

	sonuc, err := replay.ReplayTenantEventleriniBusaBas("tenant_42")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if sonuc.ReplayEdilen != 1 {
		t.Fatalf("expected 1 replay, got %d", sonuc.ReplayEdilen)
	}

	kayit, err := store.EventIDIleGetir("evt-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if kayit.ReplayCount != 1 {
		t.Fatalf("expected replay count 1, got %d", kayit.ReplayCount)
	}
}

func TestEventReplayService_ReplayTenantEventleriniBusaBas_InvalidTenantIdentity(t *testing.T) {
	store := &fakeReplayStore{
		kayitlar: []eventstoredomain.EventStoreRecord{
			{
				StoreID:        "store-2",
				EventID:        "evt-2",
				TenantID:       "tenant_42",
				TenantUUID:     "",
				Topic:          "sale.created",
				Payload:        `{"ok":true}`,
				IdempotencyKey: "idem-2",
			},
		},
	}

	bus := eventbusservice.NewEventBusService()
	replay := NewEventReplayService(store, bus)

	sonuc, err := replay.ReplayTenantEventleriniBusaBas("tenant_42")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if sonuc.ReplayEdilen != 0 {
		t.Fatalf("expected 0 replay, got %d", sonuc.ReplayEdilen)
	}
	if sonuc.HataSayisi != 1 {
		t.Fatalf("expected 1 error, got %d", sonuc.HataSayisi)
	}
}
