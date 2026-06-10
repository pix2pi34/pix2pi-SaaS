package platform

import (
	"testing"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/domain"
)

func TestBuildTenantSafeDlqPayload_Success(t *testing.T) {
	data, err := buildTenantSafeDlqPayload(eventdomain.EventMessage{
		EventID:    "evt-dlq-1",
		TenantID:   "tenant_42",
		TenantUUID: "uuid-42",
		Topic:      "pix2pi.dlq",
		Payload:    `{"reason":"x"}`,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(data) == 0 {
		t.Fatal("expected non-empty payload")
	}
}

func TestBuildTenantSafeDlqPayload_MissingTenantUUID(t *testing.T) {
	_, err := buildTenantSafeDlqPayload(eventdomain.EventMessage{
		EventID:    "evt-dlq-2",
		TenantID:   "tenant_42",
		TenantUUID: "",
		Topic:      "pix2pi.dlq",
		Payload:    `{"reason":"x"}`,
	})
	if err == nil {
		t.Fatal("expected tenant validation error")
	}
}

func TestDLQ_SendTenantSafe_NilConnection(t *testing.T) {
	d := NewDLQ(nil)

	err := d.SendTenantSafe(eventdomain.EventMessage{
		EventID:    "evt-dlq-3",
		TenantID:   "tenant_42",
		TenantUUID: "uuid-42",
		Topic:      "pix2pi.dlq",
		Payload:    `{"reason":"x"}`,
	})
	if err == nil {
		t.Fatal("expected nil connection error")
	}
}
