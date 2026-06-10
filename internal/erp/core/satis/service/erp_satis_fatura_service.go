package service

import (
	"fmt"
	"math"
	"time"

	caridomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain"
	cariservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/service"
	satisdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/satis/domain"
)

type SatisFaturaService struct {
	cariHesapService *cariservice.CariHesapService
}

func NewSatisFaturaService(
	cariHesapService *cariservice.CariHesapService,
) *SatisFaturaService {
	return &SatisFaturaService{
		cariHesapService: cariHesapService,
	}
}

func (s *SatisFaturaService) SatisFaturaOlustur(
	faturaID string,
	faturaNo string,
	cariHesapID string,
	paraBirimi string,
	satirlar []satisdomain.SatisFaturaSatir,
	olusturmaTarihi time.Time,
) (satisdomain.SatisFatura, []satisdomain.SatisFaturaSatir, error) {
	if faturaID == "" {
		return satisdomain.SatisFatura{}, nil, fmt.Errorf("fatura id bos olamaz")
	}
	if faturaNo == "" {
		return satisdomain.SatisFatura{}, nil, fmt.Errorf("fatura no bos olamaz")
	}
	if cariHesapID == "" {
		return satisdomain.SatisFatura{}, nil, fmt.Errorf("cari hesap id bos olamaz")
	}
	if paraBirimi == "" {
		return satisdomain.SatisFatura{}, nil, fmt.Errorf("para birimi bos olamaz")
	}
	if len(satirlar) == 0 {
		return satisdomain.SatisFatura{}, nil, fmt.Errorf("fatura satiri zorunludur")
	}

	_, err := s.cariHesapService.CariHesapGetir("", cariHesapID)
	if err != nil {
		return satisdomain.SatisFatura{}, nil, err
	}

	hesaplanmisSatirlar := make([]satisdomain.SatisFaturaSatir, 0, len(satirlar))

	var araToplam float64
	var kdvToplam float64
	var genelToplam float64

	for _, satir := range satirlar {
		if satir.SatirID == "" {
			return satisdomain.SatisFatura{}, nil, fmt.Errorf("satir id bos olamaz")
		}
		if satir.UrunKod == "" {
			return satisdomain.SatisFatura{}, nil, fmt.Errorf("urun kod bos olamaz")
		}
		if satir.UrunAdi == "" {
			return satisdomain.SatisFatura{}, nil, fmt.Errorf("urun adi bos olamaz")
		}
		if satir.Miktar <= 0 {
			return satisdomain.SatisFatura{}, nil, fmt.Errorf("miktar sifirdan buyuk olmali")
		}
		if satir.BirimFiyat <= 0 {
			return satisdomain.SatisFatura{}, nil, fmt.Errorf("birim fiyat sifirdan buyuk olmali")
		}
		if satir.IskontoOrani < 0 || satir.IskontoOrani > 100 {
			return satisdomain.SatisFatura{}, nil, fmt.Errorf("iskonto orani 0-100 araliginda olmali")
		}

		brutToplam := round2(satir.Miktar * satir.BirimFiyat)
		iskontoTutari := round2(brutToplam * satir.IskontoOrani / 100.0)
		netToplam := round2(brutToplam - iskontoTutari)
		kdvTutari := round2(netToplam * satir.KdvOrani / 100.0)
		satirGenelToplam := round2(netToplam + kdvTutari)

		satir.BrutToplam = brutToplam
		satir.IskontoTutari = iskontoTutari
		satir.NetToplam = netToplam
		satir.KdvTutari = kdvTutari
		satir.GenelToplam = satirGenelToplam

		araToplam += netToplam
		kdvToplam += kdvTutari
		genelToplam += satirGenelToplam

		hesaplanmisSatirlar = append(hesaplanmisSatirlar, satir)
	}

	fatura := satisdomain.SatisFatura{
		FaturaID:        faturaID,
		FaturaNo:        faturaNo,
		CariHesapID:     cariHesapID,
		ParaBirimi:      paraBirimi,
		AraToplam:       round2(araToplam),
		KdvToplam:       round2(kdvToplam),
		GenelToplam:     round2(genelToplam),
		OlusturmaTarihi: olusturmaTarihi,
	}

	err = s.cariHesapService.CariHareketEkle("",
		caridomain.CariHareket{
			HareketID:       "cari-" + faturaID,
			HesapID:         cariHesapID,
			HareketTip:      caridomain.CariHareketTipBorc,
			Tutar:           fatura.GenelToplam,
			ParaBirimi:      paraBirimi,
			BelgeNo:         faturaNo,
			ReferansID:      faturaID,
			Aciklama:        "satis faturasi",
			VadeTarihi:      olusturmaTarihi.AddDate(0, 0, 30),
			OlusturmaTarihi: olusturmaTarihi,
		},
	)
	if err != nil {
		return satisdomain.SatisFatura{}, nil, err
	}

	return fatura, hesaplanmisSatirlar, nil
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
