package service

import (
	"testing"

	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
)

func TestEventStoreService_Kaydet_ValidateTenantIdentityIleCalisir(t *testing.T) {
	store := NewEventStoreService()

	err := store.Kaydet(eventstoredomain.EventStoreRecord{
		StoreID:     "store-live-1",
		EventID:     "evt-store-1",
		TenantID:    "tenant_42",
		TenantUUID:  "uuid-42",
		Topic:       "sale.created",
		Payload:     `{"ok":true}`,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	kayit, err := store.EventIDIleGetir("evt-store-1")
	if err != nil {
		t.Fatalf("unexpected read error: %v", err)
	}

	if kayit.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", kayit.TenantID)
	}
}

func TestEventStoreService_Kaydet_TenantUUIDYoksaReddedilir(t *testing.T) {
	store := NewEventStoreService()

	err := store.Kaydet(eventstoredomain.EventStoreRecord{
		StoreID:     "store-live-2",
		EventID:     "evt-store-2",
		TenantID:    "tenant_42",
		TenantUUID:  "",
		Topic:       "sale.created",
		Payload:     `{"ok":true}`,
	})
	if err == nil {
		t.Fatal("expected tenant validation error")
	}

	if store.EventVarMi("evt-store-2") {
		t.Fatal("record should not be stored")
	}
}
