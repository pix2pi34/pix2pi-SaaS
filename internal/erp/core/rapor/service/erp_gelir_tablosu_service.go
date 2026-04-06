package service

import (
	"strings"

	rapordomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/rapor/domain"
)

type GelirTablosuService struct {
	mizanService *MizanService
}

func NewGelirTablosuService(
	mizanService *MizanService,
) *GelirTablosuService {
	return &GelirTablosuService{
		mizanService: mizanService,
	}
}

func (s *GelirTablosuService) GelirTablosuOlustur() rapordomain.GelirTablosu {
	mizan := s.mizanService.MizanOlustur()

	sonuc := rapordomain.GelirTablosu{
		Satirlar: make([]rapordomain.GelirTablosuSatir, 0),
	}

	for _, satir := range mizan {
		if gelirHesabiMi(satir.HesapKodu) {
			tutar := satir.ToplamAlacak - satir.ToplamBorc
			if tutar < 0 {
				tutar = -tutar
			}

			sonuc.Satirlar = append(sonuc.Satirlar, rapordomain.GelirTablosuSatir{
				HesapKodu: satir.HesapKodu,
				HesapAdi:  satir.HesapAdi,
				Tutar:     tutar,
				Tip:       "gelir",
			})

			sonuc.GelirlerToplami += tutar
			continue
		}

		if giderHesabiMi(satir.HesapKodu) {
			tutar := satir.ToplamBorc - satir.ToplamAlacak
			if tutar < 0 {
				tutar = -tutar
			}

			sonuc.Satirlar = append(sonuc.Satirlar, rapordomain.GelirTablosuSatir{
				HesapKodu: satir.HesapKodu,
				HesapAdi:  satir.HesapAdi,
				Tutar:     tutar,
				Tip:       "gider",
			})

			sonuc.GiderlerToplami += tutar
		}
	}

	sonuc.NetSonuc = sonuc.GelirlerToplami - sonuc.GiderlerToplami

	return sonuc
}

func gelirHesabiMi(hesapKodu string) bool {
	return strings.HasPrefix(hesapKodu, "600")
}

func giderHesabiMi(hesapKodu string) bool {
	giderKodlari := []string{
		"620", "630", "631", "632", "633",
		"634", "635", "636", "637", "638", "639",
	}

	for _, kod := range giderKodlari {
		if strings.HasPrefix(hesapKodu, kod) {
			return true
		}
	}

	return false
}
