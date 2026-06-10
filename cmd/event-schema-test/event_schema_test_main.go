package main

import (
	"fmt"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/domain"
	eventbusservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/service"
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
	fmt.Println("STEP 1.1.3 — event schema contract testi basliyor")

	store := eventstoreservice.NewEventStoreService()
	schema := schemaservice.NewEventSchemaService()

	err := schema.SozlesmeKaydet(
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

	gecerliEvent := eventdomain.EventMessage{
		EventID:    "evt-schema-001",
		TenantID:   "tenant-001",
		TenantUUID: "tenant-uuid-001",
		Topic:      "sale.created",
		Payload:    `{"sale_id":1,"amount":100}`,
	}

	err = bus.Publish(gecerliEvent)
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ gecerli event publish basarili")

	kayit, err := store.EventIDIleGetir("evt-schema-001")
	if err != nil {
		panic(err)
	}

	zorunlu(kayit.SozlesmeAdi == "sale_created_contract", "sozlesme adi store'a yazilmali")
	zorunlu(kayit.SozlesmeVersiyonu == 1, "sozlesme versiyonu store'a yazilmali")
	fmt.Println("OK ✅ schema store propagation dogrulandi")

	invalidAlanEvent := eventdomain.EventMessage{
		EventID:    "evt-schema-002",
		TenantID:   "tenant-001",
		TenantUUID: "tenant-uuid-001",
		Topic:      "sale.created",
		Payload:    `{"sale_id":1}`,
	}

	err = bus.Publish(invalidAlanEvent)
	if err != nil {
		fmt.Printf("OK ✅ zorunlu alan eksik event engellendi: %s\n", err.Error())
	} else {
		panic("zorunlu alan eksik event engellenmeliydi")
	}

	invalidJsonEvent := eventdomain.EventMessage{
		EventID:    "evt-schema-003",
		TenantID:   "tenant-001",
		TenantUUID: "tenant-uuid-001",
		Topic:      "sale.created",
		Payload:    `sale_id=1`,
	}

	err = bus.Publish(invalidJsonEvent)
	if err != nil {
		fmt.Printf("OK ✅ json olmayan payload engellendi: %s\n", err.Error())
	} else {
		panic("json olmayan payload engellenmeliydi")
	}

	topicYokEvent := eventdomain.EventMessage{
		EventID:    "evt-schema-004",
		TenantID:   "tenant-001",
		TenantUUID: "tenant-uuid-001",
		Topic:      "payment.created",
		Payload:    `{"payment_id":77}`,
	}

	err = bus.Publish(topicYokEvent)
	if err != nil {
		fmt.Printf("OK ✅ sozlesmesiz topic engellendi: %s\n", err.Error())
	} else {
		panic("sozlesmesiz topic engellenmeliydi")
	}

	yanlisVersiyonEvent := eventdomain.EventMessage{
		EventID:           "evt-schema-005",
		TenantID:          "tenant-001",
		TenantUUID:        "tenant-uuid-001",
		Topic:             "sale.created",
		Payload:           `{"sale_id":2,"amount":200}`,
		SozlesmeAdi:       "sale_created_contract",
		SozlesmeVersiyonu: 2,
	}

	err = bus.Publish(yanlisVersiyonEvent)
	if err != nil {
		fmt.Printf("OK ✅ yanlis sozlesme versiyonu engellendi: %s\n", err.Error())
	} else {
		panic("yanlis sozlesme versiyonu engellenmeliydi")
	}

	fmt.Println("OK ✅ STEP 1.1.3 event schema contract testi bitti")
}
