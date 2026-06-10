package main

import (
	"fmt"
	"sync"

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

func kanalHataKontrol(ch <-chan error) {
	for err := range ch {
		if err != nil {
			panic(err)
		}
	}
}

func main() {
	fmt.Println("STEP concurrency — thread safety testi basliyor")

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

	const toplamPublish = 20
	var wg sync.WaitGroup
	publishErrCh := make(chan error, toplamPublish)

	for i := 1; i <= toplamPublish; i++ {
		i := i
		wg.Add(1)

		go func() {
			defer wg.Done()

			event := eventdomain.EventMessage{
				EventID:        fmt.Sprintf("evt-conc-%03d", i),
				TenantID:       "tenant-001",
				TenantUUID:     "tenant-uuid-001",
				Topic:          "sale.created",
				Payload:        fmt.Sprintf(`{"sale_id":%d,"amount":%d}`, i, i*10),
				IdempotencyKey: fmt.Sprintf("idem-conc-%03d", i),
				SourceService:  "sales-api",
			}

			if err := bus.Publish(event); err != nil {
				publishErrCh <- fmt.Errorf("publish hata %d: %w", i, err)
			}
		}()
	}

	wg.Wait()
	close(publishErrCh)
	kanalHataKontrol(publishErrCh)

	zorunlu(len(store.TumKayitlariListele()) == toplamPublish, "publish sonrasi store kayit sayisi 20 olmali")
	zorunlu(len(bus.TopicBekleyenEventleriListele("sale.created")) == toplamPublish, "publish sonrasi bekleyen event sayisi 20 olmali")
	fmt.Println("OK ✅ paralel publish dogrulandi")

	const toplamAck = 10
	ackErrCh := make(chan error, toplamAck)

	for i := 1; i <= toplamAck; i++ {
		i := i
		wg.Add(1)

		go func() {
			defer wg.Done()

			if err := bus.Ack(fmt.Sprintf("evt-conc-%03d", i)); err != nil {
				ackErrCh <- fmt.Errorf("ack hata %d: %w", i, err)
			}
		}()
	}

	wg.Wait()
	close(ackErrCh)
	kanalHataKontrol(ackErrCh)

	zorunlu(len(bus.TopicBekleyenEventleriListele("sale.created")) == 10, "ack sonrasi bekleyen event sayisi 10 olmali")

	for i := 1; i <= toplamAck; i++ {
		kayit, err := store.EventIDIleGetir(fmt.Sprintf("evt-conc-%03d", i))
		if err != nil {
			panic(err)
		}
		zorunlu(kayit.Durum == "islendi", "ack sonrasi store durumu islendi olmali")
	}
	fmt.Println("OK ✅ paralel ack dogrulandi")

	retryErrCh := make(chan error, 10)

	for i := 11; i <= 20; i++ {
		i := i
		wg.Add(1)

		go func() {
			defer wg.Done()

			if err := bus.Retry(fmt.Sprintf("evt-conc-%03d", i)); err != nil {
				retryErrCh <- fmt.Errorf("retry hata %d: %w", i, err)
			}
		}()
	}

	wg.Wait()
	close(retryErrCh)
	kanalHataKontrol(retryErrCh)

	for i := 11; i <= 20; i++ {
		kayit, err := store.EventIDIleGetir(fmt.Sprintf("evt-conc-%03d", i))
		if err != nil {
			panic(err)
		}
		zorunlu(kayit.RetryCount == 1, "retry sonrasi retry count 1 olmali")
		zorunlu(kayit.Durum == "tekrar", "retry sonrasi store durumu tekrar olmali")
	}
	fmt.Println("OK ✅ paralel retry dogrulandi")

	fmt.Println("OK ✅ STEP concurrency thread safety testi bitti")
}
