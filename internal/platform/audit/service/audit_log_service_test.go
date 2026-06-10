package service

import (
	"testing"

	auditdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/audit/domain"
)

func TestAuditLogService_LogEkle_Success(t *testing.T) {
	svc := NewAuditLogService()

	err := svc.LogEkle(auditdomain.AuditLog{
		LogID:      "log-1",
		TenantID:   "tenant_42",
		TenantUUID: "uuid-42",
		UserID:     "user-1",
		Entity:     "sale",
		EntityID:   "sale-1",
		Action:     "create",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(svc.TumLoglariListele()) != 1 {
		t.Fatalf("expected 1 log, got %d", len(svc.TumLoglariListele()))
	}
}

func TestAuditLogService_LogEkle_MissingTenantUUID(t *testing.T) {
	svc := NewAuditLogService()

	err := svc.LogEkle(auditdomain.AuditLog{
		LogID:      "log-1",
		TenantID:   "tenant_42",
		TenantUUID: "",
		UserID:     "user-1",
		Entity:     "sale",
		EntityID:   "sale-1",
		Action:     "create",
	})
	if err == nil {
		t.Fatal("expected tenant identity error")
	}
}
