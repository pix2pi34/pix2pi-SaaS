package service

import (
	"testing"

	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
)

func TestBuildReplayEventFromStoreRecord_Success(t *testing.T) {
	event, err := BuildReplayEventFromStoreRecord(eventstoredomain.EventStoreRecord{
		StoreID:        "store-1",
		EventID:        "evt-1",
		TenantID:       "tenant_42",
		TenantUUID:     "uuid-42",
		Topic:          "sale.created",
		Payload:        `{"ok":true}`,
		IdempotencyKey: "idem-1",
		SourceService:  "sales",
		Version:        1,
		MaxRetry:       3,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if event.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", event.TenantID)
	}
	if event.TenantUUID != "uuid-42" {
		t.Fatalf("expected uuid-42, got %s", event.TenantUUID)
	}
	if event.Durum != "bekliyor" {
		t.Fatalf("expected bekliyor, got %s", event.Durum)
	}
}

func TestBuildReplayEventFromStoreRecord_MissingTenantUUID(t *testing.T) {
	_, err := BuildReplayEventFromStoreRecord(eventstoredomain.EventStoreRecord{
		StoreID:        "store-1",
		EventID:        "evt-1",
		TenantID:       "tenant_42",
		TenantUUID:     "",
		Topic:          "sale.created",
		Payload:        `{"ok":true}`,
		IdempotencyKey: "idem-1",
	})
	if err == nil {
		t.Fatal("expected tenant validation error")
	}
}

func TestBuildReplayEventFromStoreRecord_MissingTopic(t *testing.T) {
	_, err := BuildReplayEventFromStoreRecord(eventstoredomain.EventStoreRecord{
		StoreID:        "store-1",
		EventID:        "evt-1",
		TenantID:       "tenant_42",
		TenantUUID:     "uuid-42",
		Topic:          "",
		Payload:        `{"ok":true}`,
		IdempotencyKey: "idem-1",
	})
	if err == nil {
		t.Fatal("expected topic error")
	}
}
