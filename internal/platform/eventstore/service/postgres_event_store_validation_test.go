package service

import (
	"testing"

	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
)

func TestValidatePostgresEventStoreKaydetInput_Success(t *testing.T) {
	err := validatePostgresEventStoreKaydetInput(eventstoredomain.EventStoreRecord{
		StoreID:     "store-pg-1",
		EventID:     "evt-pg-1",
		TenantID:    "tenant_42",
		TenantUUID:  "uuid-42",
		Topic:       "sale.created",
		Payload:     `{"ok":true}`,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestValidatePostgresEventStoreKaydetInput_MissingTenantUUID(t *testing.T) {
	err := validatePostgresEventStoreKaydetInput(eventstoredomain.EventStoreRecord{
		StoreID:     "store-pg-2",
		EventID:     "evt-pg-2",
		TenantID:    "tenant_42",
		TenantUUID:  "",
		Topic:       "sale.created",
		Payload:     `{"ok":true}`,
	})
	if err == nil {
		t.Fatal("expected tenant validation error")
	}
}

func TestValidatePostgresEventStoreKaydetInput_MissingTopic(t *testing.T) {
	err := validatePostgresEventStoreKaydetInput(eventstoredomain.EventStoreRecord{
		StoreID:     "store-pg-3",
		EventID:     "evt-pg-3",
		TenantID:    "tenant_42",
		TenantUUID:  "uuid-42",
		Topic:       "",
		Payload:     `{"ok":true}`,
	})
	if err == nil {
		t.Fatal("expected topic error")
	}
}
