package main

import (
	"fmt"

	ufkservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ufk/service"
	vergidomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/vergi/domain"
	vergiengine "github.com/divrigili/pix2pi-SaaS/internal/erp/core/vergi/engine"
	vergiservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/vergi/service"
	raporservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/rapor/service"
)

func main() {

	vergiService := vergiservice.NewVergiMotoruService()

	vergiService.KuralEkle(
		vergidomain.VergiKural{
			KuralID:    "kural-satis-20",
			IslemTipi:  "satis",
			KdvOrani:   20,
			BorcHesap:  "120",
			GelirHesap: "600",
			KdvHesap:   "391",
			KuralAdi:   "Satis KDV 20",
		},
	)

	engine := vergiengine.NewVergiTaniEngine(vergiService)

	fis, err := engine.SatisFaturasiJournalOlustur(
		"journal-001",
		"JRNL-SATIS-20260312-0001",
		1000,
		20,
	)

	if err != nil {
		panic(err)
	}

	fmt.Println("UFK Event Journal Engine")
	fmt.Println("------------------------")

	for _, satir := range fis.Satirlar {

		fmt.Printf(
			"Hesap:%s Borc:%.2f Alacak:%.2f\n",
			satir.HesapKodu,
			satir.Borc,
			satir.Alacak,
		)
	}

	ledger := ufkservice.NewLedgerPostingService()

	for _, satir := range fis.Satirlar {

		ledger.Post(
			satir.HesapKodu,
			satir.Borc,
			satir.Alacak,
		)
	}

	fmt.Println()
	ledger.Yazdir()

	mizan := raporservice.NewMizanFromLedgerService(ledger)

	fmt.Println()
	mizan.Yazdir()

	gelir := raporservice.NewGelirTablosuFromLedgerService(ledger)

	fmt.Println()
	gelir.Yazdir()
  
        bilanco := raporservice.NewBilancoFromLedgerService(ledger)

        fmt.Println()

	bilanco.Yazdir()

	fmt.Println()
	fmt.Println("OK ✅ ufk journal → ledger → mizan → gelir tablosu calisti")

}
