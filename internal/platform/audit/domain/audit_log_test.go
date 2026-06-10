package domain

import "testing"

func TestAuditLog_ValidateTenantIdentity_Success(t *testing.T) {
	log := AuditLog{
		LogID:      "log-1",
		TenantID:   "tenant_42",
		TenantUUID: "uuid-42",
		UserID:     "user-1",
		Entity:     "sale",
		EntityID:   "sale-1",
		Action:     "create",
	}

	if err := log.ValidateTenantIdentity(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestAuditLog_ValidateTenantIdentity_MissingTenantUUID(t *testing.T) {
	log := AuditLog{
		LogID:      "log-1",
		TenantID:   "tenant_42",
		TenantUUID: "",
		UserID:     "user-1",
		Entity:     "sale",
		EntityID:   "sale-1",
		Action:     "create",
	}

	if err := log.ValidateTenantIdentity(); err == nil {
		t.Fatal("expected tenant identity error")
	}
}
