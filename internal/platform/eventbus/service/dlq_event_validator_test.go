package service

import (
	"testing"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/domain"
)

func TestValidateDlqEvent_Success(t *testing.T) {
	err := ValidateDlqEvent(eventdomain.EventMessage{
		EventID:    "evt-dlq-1",
		TenantID:   "tenant_42",
		TenantUUID: "uuid-42",
		Topic:      "pix2pi.dlq",
		Payload:    `{"reason":"x"}`,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestValidateDlqEvent_MissingTenantUUID(t *testing.T) {
	err := ValidateDlqEvent(eventdomain.EventMessage{
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

func TestValidateDlqEvent_MissingPayload(t *testing.T) {
	err := ValidateDlqEvent(eventdomain.EventMessage{
		EventID:    "evt-dlq-3",
		TenantID:   "tenant_42",
		TenantUUID: "uuid-42",
		Topic:      "pix2pi.dlq",
		Payload:    "",
	})
	if err == nil {
		t.Fatal("expected payload error")
	}
}
