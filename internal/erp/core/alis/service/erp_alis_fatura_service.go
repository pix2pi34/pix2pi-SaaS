package service

import (
	"fmt"
	"math"
	"time"

	alisdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/alis/domain"
	caridomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain"
	cariservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/service"
	stokdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/stok/domain"
	stokservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/stok/service"
)

type AlisFaturaService struct {
	cariHesapService *cariservice.CariHesapService
	stokService      *stokservice.StokService
}

func NewAlisFaturaService(
	cariHesapService *cariservice.CariHesapService,
	stokService *stokservice.StokService,
) *AlisFaturaService {
	return &AlisFaturaService{
		cariHesapService: cariHesapService,
		stokService:      stokService,
	}
}

func (s *AlisFaturaService) AlisFaturasiOlustur(
	faturaID string,
	faturaNo string,
	cariHesapID string,
	paraBirimi string,
	satirlar []alisdomain.AlisFaturaSatir,
	olusturmaTarihi time.Time,
) (alisdomain.AlisFatura, []alisdomain.AlisFaturaSatir, error) {
	if faturaID == "" {
		return alisdomain.AlisFatura{}, nil, fmt.Errorf("fatura id bos olamaz")
	}
	if faturaNo == "" {
		return alisdomain.AlisFatura{}, nil, fmt.Errorf("fatura no bos olamaz")
	}
	if cariHesapID == "" {
		return alisdomain.AlisFatura{}, nil, fmt.Errorf("cari hesap id bos olamaz")
	}
	if paraBirimi == "" {
		return alisdomain.AlisFatura{}, nil, fmt.Errorf("para birimi bos olamaz")
	}
	if len(satirlar) == 0 {
		return alisdomain.AlisFatura{}, nil, fmt.Errorf("fatura satiri zorunludur")
	}

	_, err := s.cariHesapService.CariHesapGetir("", cariHesapID)
	if err != nil {
		return alisdomain.AlisFatura{}, nil, err
	}

	hesaplanmisSatirlar := make([]alisdomain.AlisFaturaSatir, 0, len(satirlar))

	var araToplam float64
	var kdvToplam float64
	var genelToplam float64

	for _, satir := range satirlar {
		if satir.SatirID == "" {
			return alisdomain.AlisFatura{}, nil, fmt.Errorf("satir id bos olamaz")
		}
		if satir.UrunID == "" {
			return alisdomain.AlisFatura{}, nil, fmt.Errorf("urun id bos olamaz")
		}
		if satir.UrunKod == "" {
			return alisdomain.AlisFatura{}, nil, fmt.Errorf("urun kod bos olamaz")
		}
		if satir.UrunAdi == "" {
			return alisdomain.AlisFatura{}, nil, fmt.Errorf("urun adi bos olamaz")
		}
		if satir.Miktar <= 0 {
			return alisdomain.AlisFatura{}, nil, fmt.Errorf("miktar sifirdan buyuk olmali")
		}
		if satir.BirimFiyat <= 0 {
			return alisdomain.AlisFatura{}, nil, fmt.Errorf("birim fiyat sifirdan buyuk olmali")
		}

		satirTutar := round2(satir.Miktar * satir.BirimFiyat)
		kdvTutari := round2(satirTutar * satir.KdvOrani / 100.0)
		satirGenelToplam := round2(satirTutar + kdvTutari)

		satir.SatirToplam = satirTutar
		satir.KdvTutari = kdvTutari
		satir.GenelToplam = satirGenelToplam

		araToplam += satirTutar
		kdvToplam += kdvTutari
		genelToplam += satirGenelToplam

		err := s.stokService.StokHareketEkle(
			stokdomain.StokHareket{
				HareketID:       "stok-" + faturaID + "-" + satir.SatirID,
				UrunID:          satir.UrunID,
				HareketTip:      stokdomain.StokHareketTipGiris,
				Miktar:          satir.Miktar,
				BirimMaliyet:    satir.BirimFiyat,
				BelgeNo:         faturaNo,
				ReferansID:      faturaID,
				Aciklama:        "alis faturasi stok girisi",
				OlusturmaTarihi: olusturmaTarihi,
			},
		)
		if err != nil {
			return alisdomain.AlisFatura{}, nil, err
		}

		hesaplanmisSatirlar = append(hesaplanmisSatirlar, satir)
	}

	fatura := alisdomain.AlisFatura{
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
			Aciklama:        "alis faturasi",
			VadeTarihi:      olusturmaTarihi.AddDate(0, 0, 30),
			OlusturmaTarihi: olusturmaTarihi,
		},
	)
	if err != nil {
		return alisdomain.AlisFatura{}, nil, err
	}

	return fatura, hesaplanmisSatirlar, nil
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
