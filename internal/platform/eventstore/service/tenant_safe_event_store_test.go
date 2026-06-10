package service

import (
	"testing"

	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
)

type fakeEventStoreRecorder struct {
	callCount int
	lastKayit eventstoredomain.EventStoreRecord
	err       error
}

func (f *fakeEventStoreRecorder) Kaydet(kayit eventstoredomain.EventStoreRecord) error {
	f.callCount++
	f.lastKayit = kayit
	return f.err
}

func TestKaydetTenantSafe_Success(t *testing.T) {
	store := &fakeEventStoreRecorder{}

	err := KaydetTenantSafe(store, eventstoredomain.EventStoreRecord{
		StoreID:     "store-1",
		EventID:     "evt-1",
		TenantID:    "tenant_42",
		TenantUUID:  "uuid-42",
		Topic:       "sale.created",
		Payload:     "{}",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if store.callCount != 1 {
		t.Fatalf("expected 1 kaydet call, got %d", store.callCount)
	}
	if store.lastKayit.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", store.lastKayit.TenantID)
	}
}

func TestKaydetTenantSafe_MissingTenantID(t *testing.T) {
	store := &fakeEventStoreRecorder{}

	err := KaydetTenantSafe(store, eventstoredomain.EventStoreRecord{
		StoreID:     "store-1",
		EventID:     "evt-1",
		TenantID:    "",
		TenantUUID:  "uuid-42",
		Topic:       "sale.created",
		Payload:     "{}",
	})
	if err == nil {
		t.Fatal("expected tenant validation error")
	}

	if store.callCount != 0 {
		t.Fatalf("expected 0 kaydet call, got %d", store.callCount)
	}
}

func TestKaydetTenantSafe_NilStore(t *testing.T) {
	err := KaydetTenantSafe(nil, eventstoredomain.EventStoreRecord{
		StoreID:     "store-1",
		EventID:     "evt-1",
		TenantID:    "tenant_42",
		TenantUUID:  "uuid-42",
		Topic:       "sale.created",
		Payload:     "{}",
	})
	if err == nil {
		t.Fatal("expected store error")
	}
}
