package service

import (
	"testing"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/domain"
)

type fakeEventPublisher struct {
	callCount int
	lastEvent eventdomain.EventMessage
	err       error
}

func (f *fakeEventPublisher) Publish(event eventdomain.EventMessage) error {
	f.callCount++
	f.lastEvent = event
	return f.err
}

func TestPublishTenantSafe_Success(t *testing.T) {
	pub := &fakeEventPublisher{}

	err := PublishTenantSafe(pub, eventdomain.EventMessage{
		EventID:    "evt-1",
		TenantID:   "tenant_42",
		TenantUUID: "uuid-42",
		Topic:      "sale.created",
		Payload:    "{}",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if pub.callCount != 1 {
		t.Fatalf("expected 1 publish call, got %d", pub.callCount)
	}
	if pub.lastEvent.TenantID != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", pub.lastEvent.TenantID)
	}
}

func TestPublishTenantSafe_MissingTenantUUID(t *testing.T) {
	pub := &fakeEventPublisher{}

	err := PublishTenantSafe(pub, eventdomain.EventMessage{
		EventID:    "evt-1",
		TenantID:   "tenant_42",
		TenantUUID: "",
		Topic:      "sale.created",
		Payload:    "{}",
	})
	if err == nil {
		t.Fatal("expected tenant validation error")
	}

	if pub.callCount != 0 {
		t.Fatalf("expected 0 publish call, got %d", pub.callCount)
	}
}

func TestPublishTenantSafe_NilPublisher(t *testing.T) {
	err := PublishTenantSafe(nil, eventdomain.EventMessage{
		EventID:    "evt-1",
		TenantID:   "tenant_42",
		TenantUUID: "uuid-42",
		Topic:      "sale.created",
		Payload:    "{}",
	})
	if err == nil {
		t.Fatal("expected publisher error")
	}
}
