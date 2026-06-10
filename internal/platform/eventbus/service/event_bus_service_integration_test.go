package service

import (
	"testing"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/domain"
	eventstoreservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/service"
)

func TestEventBusService_Publish_KaydetTenantSafeIleStoreaYazar(t *testing.T) {
	store := eventstoreservice.NewEventStoreService()
	bus := NewEventBusServiceWithStore(store)

	err := bus.Publish(eventdomain.EventMessage{
		EventID:    "evt-live-1",
		TenantID:   "tenant_42",
		TenantUUID: "uuid-42",
		Topic:      "sale.created",
		Payload:    `{"ok":true}`,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	kayit, err := store.EventIDIleGetir("evt-live-1")
	if err != nil {
		t.Fatalf("unexpected store read error: %v", err)
	}

	if kayit.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", kayit.TenantID)
	}
	if kayit.TenantUUID != "uuid-42" {
		t.Fatalf("expected uuid-42, got %s", kayit.TenantUUID)
	}
}

func TestEventBusService_Publish_TenantUUIDYoksaReddedilir(t *testing.T) {
	store := eventstoreservice.NewEventStoreService()
	bus := NewEventBusServiceWithStore(store)

	err := bus.Publish(eventdomain.EventMessage{
		EventID:    "evt-live-2",
		TenantID:   "tenant_42",
		TenantUUID: "",
		Topic:      "sale.created",
		Payload:    `{"ok":true}`,
	})
	if err == nil {
		t.Fatal("expected tenant validation error")
	}

	if store.EventVarMi("evt-live-2") {
		t.Fatal("event should not be stored")
	}
}
