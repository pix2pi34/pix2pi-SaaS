package main

import (
	"fmt"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/domain"
	eventbusservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/service"
	eventreplayservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventreplay/service"
	eventstoreservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/service"
)

func zorunlu(kosul bool, mesaj string) {
	if !kosul {
		panic(mesaj)
	}
}

func main() {
	fmt.Println("STEP 1.1.4 — event metadata standard testi basliyor")

	store := eventstoreservice.NewEventStoreService()
	bus := eventbusservice.NewEventBusServiceWithStore(store)
	replay := eventreplayservice.NewEventReplayService(store, bus)

	event := eventdomain.EventMessage{
		EventID:        "evt-meta-001",
		TenantID:       "tenant-001",
		TenantUUID:     "tenant-uuid-001",
		Topic:          "sale.created",
		Payload:        `{"sale_id":10}`,
		CorrelationID:  "corr-001",
		CausationID:    "cmd-001",
		IdempotencyKey: "idem-001",
		SourceService:  "sales-api",
		Version:        2,
	}

	err := bus.Publish(event)
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ metadata'li publish basarili")

	kayit, err := store.EventIDIleGetir("evt-meta-001")
	if err != nil {
		panic(err)
	}

	zorunlu(kayit.CorrelationID == "corr-001", "correlation id store'a yazilmali")
	zorunlu(kayit.CausationID == "cmd-001", "causation id store'a yazilmali")
	zorunlu(kayit.IdempotencyKey == "idem-001", "idempotency key store'a yazilmali")
	zorunlu(kayit.SourceService == "sales-api", "source service store'a yazilmali")
	zorunlu(kayit.Version == 2, "version store'a yazilmali")
	fmt.Println("OK ✅ metadata store propagation dogrulandi")

	err = bus.Ack("evt-meta-001")
	if err != nil {
		panic(err)
	}

	sonuc, err := replay.ReplayTenantEventleriniBusaBas("tenant-001")
	if err != nil {
		panic(err)
	}

	zorunlu(sonuc.ReplayEdilen == 1, "metadata'li event replay edilmeli")

	bekleyen := bus.TenantTopicBekleyenEventleriListele("tenant-001", "sale.created")
	zorunlu(len(bekleyen) == 1, "replay sonrasi kuyrukta 1 event olmali")

	zorunlu(bekleyen[0].CorrelationID == "corr-001", "correlation id replay ile korunmali")
	zorunlu(bekleyen[0].CausationID == "cmd-001", "causation id replay ile korunmali")
	zorunlu(bekleyen[0].IdempotencyKey == "idem-001", "idempotency key replay ile korunmali")
	zorunlu(bekleyen[0].SourceService == "sales-api", "source service replay ile korunmali")
	zorunlu(bekleyen[0].Version == 2, "version replay ile korunmali")
	fmt.Println("OK ✅ metadata replay propagation dogrulandi")

	event2 := eventdomain.EventMessage{
		EventID:    "evt-meta-002",
		TenantID:   "tenant-001",
		TenantUUID: "tenant-uuid-001",
		Topic:      "invoice.created",
		Payload:    `{"invoice_id":20}`,
	}

	err = bus.Publish(event2)
	if err != nil {
		panic(err)
	}

	kayit2, err := store.EventIDIleGetir("evt-meta-002")
	if err != nil {
		panic(err)
	}

	zorunlu(kayit2.CorrelationID == "evt-meta-002", "default correlation id event id olmali")
	zorunlu(kayit2.IdempotencyKey == "evt-meta-002", "default idempotency key event id olmali")
	zorunlu(kayit2.SourceService == "unknown", "default source service unknown olmali")
	zorunlu(kayit2.Version == 1, "default version 1 olmali")
	fmt.Println("OK ✅ metadata default standardi dogrulandi")

	fmt.Println("OK ✅ STEP 1.1.4 event metadata standard testi bitti")
}
