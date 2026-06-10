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
	fmt.Println("STEP 1.3.5 — gercek replay testi basliyor")

	store := eventstoreservice.NewEventStoreService()
	bus := eventbusservice.NewEventBusServiceWithStore(store)
	replay := eventreplayservice.NewEventReplayService(store, bus)

	event := eventdomain.EventMessage{
		EventID:    "evt-replay-001",
		TenantID:   "tenant-001",
		TenantUUID: "tenant-uuid-001",
		Topic:      "sale.created",
		Payload:    `{"sale_id":99}`,
	}

	err := bus.Publish(event)
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ publish basarili")

	err = bus.Ack("evt-replay-001")
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ event ack ile islenmis duruma geldi")

	kayit, err := store.EventIDIleGetir("evt-replay-001")
	if err != nil {
		panic(err)
	}

	zorunlu(kayit.Durum == "islendi", "ack sonrasi store durumu islendi olmali")
	fmt.Println("OK ✅ ack sonrasi store durumu dogrulandi")

	sonuc, err := replay.ReplayTenantEventleriniBusaBas("tenant-001")
	if err != nil {
		panic(err)
	}

	fmt.Printf("DEBUG replay-1 | toplam=%d replay=%d skip=%d hata=%d\n", sonuc.Toplam, sonuc.ReplayEdilen, sonuc.Atlanan, sonuc.HataSayisi)

	zorunlu(sonuc.Toplam == 1, "ilk replay toplam 1 olmali")
	zorunlu(sonuc.ReplayEdilen == 1, "ilk replayde 1 event kuyruğa alinmali")
	zorunlu(sonuc.Atlanan == 0, "ilk replayde skip olmamali")
	zorunlu(sonuc.HataSayisi == 0, "ilk replayde hata olmamali")

	kayit, err = store.EventIDIleGetir("evt-replay-001")
	if err != nil {
		panic(err)
	}

	zorunlu(kayit.ReplayCount == 1, "ilk replay sonrasi replay count 1 olmali")
	zorunlu(kayit.Durum == "bekliyor", "ilk replay sonrasi store durumu bekliyor olmali")
	zorunlu(len(bus.TopicBekleyenEventleriListele("sale.created")) == 1, "ilk replay sonrasi bus kuyrugunda 1 event olmali")
	fmt.Println("OK ✅ ilk replay dogrulandi")

	sonuc, err = replay.ReplayTenantEventleriniBusaBas("tenant-001")
	if err != nil {
		panic(err)
	}

	fmt.Printf("DEBUG replay-2 | toplam=%d replay=%d skip=%d hata=%d\n", sonuc.Toplam, sonuc.ReplayEdilen, sonuc.Atlanan, sonuc.HataSayisi)

	zorunlu(sonuc.Toplam == 1, "ikinci replay toplam 1 olmali")
	zorunlu(sonuc.ReplayEdilen == 0, "ikinci replayde yeni replay olmamali")
	zorunlu(sonuc.Atlanan == 1, "ikinci replayde event skip olmali")
	zorunlu(sonuc.HataSayisi == 0, "ikinci replayde hata olmamali")
	fmt.Println("OK ✅ skip replay dogrulandi")

	fmt.Println("OK ✅ STEP 1.3.5 gercek replay testi bitti")
}
