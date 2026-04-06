package engine

import (
	"fmt"
	"math"
	"time"

	vergiservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/vergi/service"
)

type MuhasebeSatiri struct {
	HesapKodu string
	Yon       string
	Tutar     float64
}

type JournalSatiri struct {
	HesapKodu string
	Borc      float64
	Alacak    float64
}

type JournalFis struct {
	FisID          string
	FisNo          string
	IslemTipi      string
	NetTutar       float64
	KdvOrani       float64
	KdvTutari      float64
	GenelToplam    float64
	OlusturmaTarihi time.Time
	Satirlar       []JournalSatiri
}

type VergiTaniEngine struct {
	vergiService *vergiservice.VergiMotoruService
}

func NewVergiTaniEngine(
	vergiService *vergiservice.VergiMotoruService,
) *VergiTaniEngine {
	return &VergiTaniEngine{
		vergiService: vergiService,
	}
}

func (e *VergiTaniEngine) SatisFaturasiIsle(
	tutar float64,
	kdvOrani float64,
) ([]MuhasebeSatiri, error) {
	kural, err := e.vergiService.KuralBul("satis", kdvOrani)
	if err != nil {
		return nil, err
	}

	kdvTutari := round2(tutar * kdvOrani / 100.0)
	genelToplam := round2(tutar + kdvTutari)

	satirlar := []MuhasebeSatiri{
		{
			HesapKodu: kural.BorcHesap,
			Yon:       "BORC",
			Tutar:     genelToplam,
		},
		{
			HesapKodu: kural.GelirHesap,
			Yon:       "ALACAK",
			Tutar:     round2(tutar),
		},
		{
			HesapKodu: kural.KdvHesap,
			Yon:       "ALACAK",
			Tutar:     kdvTutari,
		},
	}

	return satirlar, nil
}

func (e *VergiTaniEngine) SatisFaturasiJournalOlustur(
	fisID string,
	fisNo string,
	tutar float64,
	kdvOrani float64,
) (JournalFis, error) {
	muhasebeSatirlari, err := e.SatisFaturasiIsle(tutar, kdvOrani)
	if err != nil {
		return JournalFis{}, err
	}

	journalSatirlari := make([]JournalSatiri, 0, len(muhasebeSatirlari))

	for _, satir := range muhasebeSatirlari {
		journalSatiri := JournalSatiri{
			HesapKodu: satir.HesapKodu,
		}

		if satir.Yon == "BORC" {
			journalSatiri.Borc = satir.Tutar
		} else {
			journalSatiri.Alacak = satir.Tutar
		}

		journalSatirlari = append(journalSatirlari, journalSatiri)
	}

	kdvTutari := round2(tutar * kdvOrani / 100.0)
	genelToplam := round2(tutar + kdvTutari)

	fis := JournalFis{
		FisID:           fisID,
		FisNo:           fisNo,
		IslemTipi:       "satis",
		NetTutar:        round2(tutar),
		KdvOrani:        round2(kdvOrani),
		KdvTutari:       kdvTutari,
		GenelToplam:     genelToplam,
		OlusturmaTarihi: time.Now(),
		Satirlar:        journalSatirlari,
	}

	return fis, nil
}

func (e *VergiTaniEngine) SatisFaturasiJournalYazdir(
	fisID string,
	fisNo string,
	tutar float64,
	kdvOrani float64,
) error {
	fis, err := e.SatisFaturasiJournalOlustur(fisID, fisNo, tutar, kdvOrani)
	if err != nil {
		return err
	}

	fmt.Println("UFK Event Journal Engine")
	fmt.Println("------------------------")
	fmt.Printf("FisID: %s\n", fis.FisID)
	fmt.Printf("FisNo: %s\n", fis.FisNo)
	fmt.Printf("Islem Tipi: %s\n", fis.IslemTipi)
	fmt.Printf("Net Tutar: %.2f\n", fis.NetTutar)
	fmt.Printf("KDV Orani: %.2f\n", fis.KdvOrani)
	fmt.Printf("KDV Tutari: %.2f\n", fis.KdvTutari)
	fmt.Printf("Genel Toplam: %.2f\n", fis.GenelToplam)
	fmt.Println("Journal Satirlari:")

	for _, satir := range fis.Satirlar {
		fmt.Printf(
			"Hesap:%s Borc:%.2f Alacak:%.2f\n",
			satir.HesapKodu,
			satir.Borc,
			satir.Alacak,
		)
	}

	return nil
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
