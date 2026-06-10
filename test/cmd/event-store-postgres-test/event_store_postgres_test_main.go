package main

import (
	"fmt"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/domain"
	eventbusservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/service"
	eventreplayservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventreplay/service"
	schemadomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventschema/domain"
	schemaservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventschema/service"
	eventstoreservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/service"
)

func zorunlu(kosul bool, mesaj string) {
	if !kosul {
		panic(mesaj)
	}
}

func main() {
	fmt.Println("STEP postgres persist — event store testi basliyor")

	store, err := eventstoreservice.NewPostgresEventStoreServiceFromEnv(
		"event_store_records_pg_test",
	)
	if err != nil {
		panic(err)
	}
	defer store.Close()

	err = store.EnsureSchema()
	if err != nil {
		panic(err)
	}

	err = store.TestIcinTemizle()
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ postgres baglanti + schema + temizleme tamam")

	schema := schemaservice.NewEventSchemaService()

	err = schema.SozlesmeKaydet(
		schemadomain.EventSozlesme{
			Topic:             "sale.created",
			SozlesmeAdi:       "sale_created_contract",
			SozlesmeVersiyonu: 1,
			ZorunluAlanlar:    []string{"sale_id", "amount"},
		},
	)
	if err != nil {
		panic(err)
	}

	bus := eventbusservice.NewEventBusServiceWithStoreAndSchema(store, schema)
	replay := eventreplayservice.NewEventReplayService(store, bus)

	event1 := eventdomain.EventMessage{
		EventID:        "evt-pg-001",
		TenantID:       "tenant-001",
		TenantUUID:     "tenant-uuid-001",
		Topic:          "sale.created",
		Payload:        `{"sale_id":1,"amount":100}`,
		CorrelationID:  "corr-pg-001",
		CausationID:    "cmd-pg-001",
		IdempotencyKey: "idem-pg-001",
		SourceService:  "sales-api",
		Version:        2,
	}

	err = bus.Publish(event1)
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ postgres publish basarili")

	kayit1, err := store.EventIDIleGetir("evt-pg-001")
	if err != nil {
		panic(err)
	}

	zorunlu(kayit1.Topic == "sale.created", "topic postgres'a yazilmali")
	zorunlu(kayit1.CorrelationID == "corr-pg-001", "correlation id postgres'a yazilmali")
	zorunlu(kayit1.CausationID == "cmd-pg-001", "causation id postgres'a yazilmali")
	zorunlu(kayit1.IdempotencyKey == "idem-pg-001", "idempotency key postgres'a yazilmali")
	zorunlu(kayit1.SozlesmeAdi == "sale_created_contract", "sozlesme adi postgres'a yazilmali")
	zorunlu(kayit1.SozlesmeVersiyonu == 1, "sozlesme versiyonu postgres'a yazilmali")
	fmt.Println("OK ✅ postgres insert persistence dogrulandi")

	err = bus.Ack("evt-pg-001")
	if err != nil {
		panic(err)
	}

	kayit1, err = store.EventIDIleGetir("evt-pg-001")
	if err != nil {
		panic(err)
	}

	zorunlu(kayit1.Durum == "islendi", "ack sonrasi durum postgres'te islendi olmali")
	fmt.Println("OK ✅ postgres ack persistence dogrulandi")

	sonuc, err := replay.ReplayTenantEventleriniBusaBas("tenant-001")
	if err != nil {
		panic(err)
	}

	zorunlu(sonuc.ReplayEdilen == 1, "postgres replay edilmeli")

	kayit1, err = store.EventIDIleGetir("evt-pg-001")
	if err != nil {
		panic(err)
	}

	zorunlu(kayit1.ReplayCount == 1, "postgres replay count 1 olmali")
	fmt.Println("OK ✅ postgres replay persistence dogrulandi")

	event2 := eventdomain.EventMessage{
		EventID:        "evt-pg-002",
		TenantID:       "tenant-001",
		TenantUUID:     "tenant-uuid-001",
		Topic:          "sale.created",
		Payload:        `{"sale_id":2,"amount":200}`,
		IdempotencyKey: "idem-pg-002",
		SourceService:  "sales-api",
		MaxRetry:       3,
	}

	err = bus.Publish(event2)
	if err != nil {
		panic(err)
	}

	err = bus.Retry("evt-pg-002")
	if err != nil {
		panic(err)
	}

	err = bus.Retry("evt-pg-002")
	if err != nil {
		panic(err)
	}

	err = bus.Retry("evt-pg-002")
	if err != nil {
		panic(err)
	}

	kayit2, err := store.EventIDIleGetir("evt-pg-002")
	if err != nil {
		panic(err)
	}

	zorunlu(kayit2.Durum == "dlq", "3 retry sonrasi postgres durum dlq olmali")
	zorunlu(kayit2.RetryCount == 3, "3 retry sonrasi retry count 3 olmali")
	fmt.Println("OK ✅ postgres retry dlq persistence dogrulandi")

	event3 := eventdomain.EventMessage{
		EventID:        "evt-pg-003",
		TenantID:       "tenant-001",
		TenantUUID:     "tenant-uuid-001",
		Topic:          "sale.created",
		Payload:        `{"sale_id":3,"amount":300}`,
		IdempotencyKey: "idem-pg-001",
		SourceService:  "sales-api",
	}

	err = bus.Publish(event3)
	if err != nil {
		fmt.Printf("OK ✅ postgres idempotency korumasi dogrulandi: %s\n", err.Error())
	} else {
		panic("postgres idempotency korumasi calismaliydi")
	}

	fmt.Println("OK ✅ STEP postgres persist event store testi bitti")
}
