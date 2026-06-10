package domain

import "testing"

func TestEventMessage_ValidateTenantIdentity_Success(t *testing.T) {
	msg := EventMessage{
		EventID:    "evt-1",
		TenantID:   "tenant_42",
		TenantUUID: "uuid-42",
		Topic:      "sale.created",
	}

	if err := msg.ValidateTenantIdentity(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestEventMessage_ValidateTenantIdentity_MissingTenantUUID(t *testing.T) {
	msg := EventMessage{
		EventID:    "evt-1",
		TenantID:   "tenant_42",
		TenantUUID: "",
		Topic:      "sale.created",
	}

	if err := msg.ValidateTenantIdentity(); err == nil {
		t.Fatal("expected tenant identity error")
	}
}
