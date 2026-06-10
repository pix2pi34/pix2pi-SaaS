package domain

import "testing"

func TestEventStoreRecord_ValidateTenantIdentity_Success(t *testing.T) {
	rec := EventStoreRecord{
		StoreID:     "store-1",
		EventID:     "evt-1",
		TenantID:    "tenant_42",
		TenantUUID:  "uuid-42",
		Topic:       "sale.created",
	}

	if err := rec.ValidateTenantIdentity(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestEventStoreRecord_ValidateTenantIdentity_MissingTenantID(t *testing.T) {
	rec := EventStoreRecord{
		StoreID:     "store-1",
		EventID:     "evt-1",
		TenantID:    "",
		TenantUUID:  "uuid-42",
		Topic:       "sale.created",
	}

	if err := rec.ValidateTenantIdentity(); err == nil {
		t.Fatal("expected tenant identity error")
	}
}
