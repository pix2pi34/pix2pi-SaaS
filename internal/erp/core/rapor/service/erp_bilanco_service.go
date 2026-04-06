package service

import (
	"strings"

	rapordomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/rapor/domain"
)

type BilancoService struct {
	mizanService *MizanService
}

func NewBilancoService(mizanService *MizanService) *BilancoService {
	return &BilancoService{
		mizanService: mizanService,
	}
}

func (s *BilancoService) BilancoOlustur() rapordomain.Bilanco {

	mizan := s.mizanService.MizanOlustur()

	sonuc := rapordomain.Bilanco{
		Satirlar: make([]rapordomain.BilancoSatir, 0),
	}

	for _, satir := range mizan {

		tutar := satir.ToplamBorc - satir.ToplamAlacak
		if tutar < 0 {
			tutar = -tutar
		}

		if aktifHesabiMi(satir.HesapKodu) {

			sonuc.Satirlar = append(sonuc.Satirlar, rapordomain.BilancoSatir{
				HesapKodu: satir.HesapKodu,
				HesapAdi:  satir.HesapAdi,
				Tutar:     tutar,
				Tip:       "aktif",
			})

			sonuc.AktifToplam += tutar
			continue
		}

		if pasifHesabiMi(satir.HesapKodu) {

			sonuc.Satirlar = append(sonuc.Satirlar, rapordomain.BilancoSatir{
				HesapKodu: satir.HesapKodu,
				HesapAdi:  satir.HesapAdi,
				Tutar:     tutar,
				Tip:       "pasif",
			})

			sonuc.PasifToplam += tutar
		}
	}

	return sonuc
}

func aktifHesabiMi(kod string) bool {
	return strings.HasPrefix(kod, "1") || strings.HasPrefix(kod, "2")
}

func pasifHesabiMi(kod string) bool {
	return strings.HasPrefix(kod, "3") ||
		strings.HasPrefix(kod, "4") ||
		strings.HasPrefix(kod, "5")
}
