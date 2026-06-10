package main

import (
	"fmt"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/domain"
	eventbusservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/service"
	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
	eventstoreservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/service"
)

func zorunlu(kosul bool, mesaj string) {
	if !kosul {
		panic(mesaj)
	}
}

func main() {
	fmt.Println("STEP 1.3.6 — bus-store lifecycle sync testi basliyor")

	store := eventstoreservice.NewEventStoreService()
	bus := eventbusservice.NewEventBusServiceWithStore(store)

	event := eventdomain.EventMessage{
		EventID:    "evt-001",
		TenantID:   "tenant-001",
		TenantUUID: "tenant-uuid-001",
		Topic:      "sale.created",
		Payload:    `{"sale_id":1}`,
	}

	err := bus.Publish(event)
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ publish basarili")

	kayit, err := store.EventIDIleGetir("evt-001")
	if err != nil {
		panic(err)
	}

	zorunlu(kayit.Durum == eventstoredomain.EventStoreDurumBekliyor, "publish sonrasi durum bekliyor olmali")
	zorunlu(kayit.MaxRetry == 3, "default max retry 3 olmali")
	fmt.Println("OK ✅ publish sonrasi store durumu dogrulandi")

	err = bus.Retry("evt-001")
	if err != nil {
		panic(err)
	}

	kayit, err = store.EventIDIleGetir("evt-001")
	if err != nil {
		panic(err)
	}

	fmt.Printf("DEBUG retry-1 | durum=%s retry=%d max=%d\n", kayit.Durum, kayit.RetryCount, kayit.MaxRetry)

	zorunlu(kayit.RetryCount == 1, "retry count 1 olmali")
	zorunlu(kayit.Durum == eventstoredomain.EventStoreDurumTekrar, "retry sonrasi store durumu tekrar olmali")
	fmt.Println("OK ✅ retry store sync dogrulandi")

	err = bus.Retry("evt-001")
	if err != nil {
		panic(err)
	}

	err = bus.Retry("evt-001")
	if err != nil {
		panic(err)
	}

	kayit, err = store.EventIDIleGetir("evt-001")
	if err != nil {
		panic(err)
	}

	fmt.Printf("DEBUG dlq | durum=%s retry=%d max=%d dlq_nedeni=%s\n", kayit.Durum, kayit.RetryCount, kayit.MaxRetry, kayit.DlqNedeni)

	zorunlu(kayit.Durum == eventstoredomain.EventStoreDurumDlq, "max retry sonrasi store durumu dlq olmali")
	zorunlu(len(bus.DlqEventleri()) == 1, "dlq icinde 1 event olmali")
	fmt.Println("OK ✅ dlq store sync dogrulandi")

	err = bus.DlqYenidenKuyrugaAl("evt-001")
	if err != nil {
		panic(err)
	}

	kayit, err = store.EventIDIleGetir("evt-001")
	if err != nil {
		panic(err)
	}

	fmt.Printf("DEBUG requeue | durum=%s retry=%d\n", kayit.Durum, kayit.RetryCount)

	zorunlu(kayit.Durum == eventstoredomain.EventStoreDurumBekliyor, "requeue sonrasi store durumu bekliyor olmali")
	zorunlu(kayit.RetryCount == 0, "requeue sonrasi retry count sifir olmali")
	zorunlu(len(bus.TopicBekleyenEventleriListele("sale.created")) == 1, "kuyrukta tekrar 1 event olmali")
	fmt.Println("OK ✅ requeue store sync dogrulandi")

	err = bus.Ack("evt-001")
	if err != nil {
		panic(err)
	}

	kayit, err = store.EventIDIleGetir("evt-001")
	if err != nil {
		panic(err)
	}

	fmt.Printf("DEBUG ack | durum=%s retry=%d\n", kayit.Durum, kayit.RetryCount)

	zorunlu(kayit.Durum == eventstoredomain.EventStoreDurumIslendi, "ack sonrasi store durumu islendi olmali")
	zorunlu(len(bus.TopicBekleyenEventleriListele("sale.created")) == 0, "ack sonrasi bekleyen event kalmamali")
	fmt.Println("OK ✅ ack store sync dogrulandi")

	err = bus.Publish(event)
	if err != nil {
		fmt.Printf("OK ✅ duplicate publish engellendi: %s\n", err.Error())
	} else {
		panic("duplicate publish engellenmeliydi")
	}

	fmt.Println("OK ✅ STEP 1.3.6 bus-store lifecycle sync testi bitti")
}
