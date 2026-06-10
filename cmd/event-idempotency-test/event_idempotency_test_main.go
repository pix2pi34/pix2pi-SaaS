package main

import (
	"fmt"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/domain"
	eventbusservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/service"
	eventstoreservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/service"
)

func zorunlu(kosul bool, mesaj string) {
	if !kosul {
		panic(mesaj)
	}
}

func main() {
	fmt.Println("STEP 1.3.2 — event idempotency testi basliyor")

	store := eventstoreservice.NewEventStoreService()
	bus := eventbusservice.NewEventBusServiceWithStore(store)

	event1 := eventdomain.EventMessage{
		EventID:        "evt-idem-001",
		TenantID:       "tenant-001",
		TenantUUID:     "tenant-uuid-001",
		Topic:          "sale.created",
		Payload:        `{"sale_id":1}`,
		IdempotencyKey: "idem-sale-001",
		SourceService:  "sales-api",
	}

	err := bus.Publish(event1)
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ ilk publish basarili")

	event2 := eventdomain.EventMessage{
		EventID:        "evt-idem-002",
		TenantID:       "tenant-001",
		TenantUUID:     "tenant-uuid-001",
		Topic:          "sale.created",
		Payload:        `{"sale_id":1}`,
		IdempotencyKey: "idem-sale-001",
		SourceService:  "sales-api",
	}

	err = bus.Publish(event2)
	if err != nil {
		fmt.Printf("OK ✅ ayni tenant+topic+idempotency engellendi: %s\n", err.Error())
	} else {
		panic("ayni tenant+topic+idempotency engellenmeliydi")
	}

	event3 := eventdomain.EventMessage{
		EventID:        "evt-idem-003",
		TenantID:       "tenant-001",
		TenantUUID:     "tenant-uuid-001",
		Topic:          "invoice.created",
		Payload:        `{"invoice_id":10}`,
		IdempotencyKey: "idem-sale-001",
		SourceService:  "invoice-api",
	}

	err = bus.Publish(event3)
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ ayni idempotency key farkli topicte kabul edildi")

	event4 := eventdomain.EventMessage{
		EventID:        "evt-idem-004",
		TenantID:       "tenant-002",
		TenantUUID:     "tenant-uuid-002",
		Topic:          "sale.created",
		Payload:        `{"sale_id":2}`,
		IdempotencyKey: "idem-sale-001",
		SourceService:  "sales-api",
	}

	err = bus.Publish(event4)
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ ayni idempotency key farkli tenantta kabul edildi")

	event5 := eventdomain.EventMessage{
		EventID:    "evt-idem-005",
		TenantID:   "tenant-001",
		TenantUUID: "tenant-uuid-001",
		Topic:      "payment.created",
		Payload:    `{"payment_id":77}`,
	}

	err = bus.Publish(event5)
	if err != nil {
		panic(err)
	}

	kayit5, err := store.EventIDIleGetir("evt-idem-005")
	if err != nil {
		panic(err)
	}

	zorunlu(kayit5.IdempotencyKey == "evt-idem-005", "default idempotency key event id olmali")
	fmt.Println("OK ✅ default idempotency key dogrulandi")

	fmt.Println("OK ✅ STEP 1.3.2 event idempotency testi bitti")
}
