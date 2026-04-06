package service

import (
	"sort"

	bankaservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/banka/service"
	cariservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/service"
	kasaservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/kasa/service"
	rapordomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/rapor/domain"
)

type MizanService struct {
	cariHesapService *cariservice.CariHesapService
	kasaService      *kasaservice.KasaService
	bankaService     *bankaservice.BankaService
}

func NewMizanService(
	cariHesapService *cariservice.CariHesapService,
	kasaService *kasaservice.KasaService,
	bankaService *bankaservice.BankaService,
) *MizanService {
	return &MizanService{
		cariHesapService: cariHesapService,
		kasaService:      kasaService,
		bankaService:     bankaService,
	}
}

func (s *MizanService) MizanOlustur() []rapordomain.MizanSatir {
	sonuc := make([]rapordomain.MizanSatir, 0)

	for _, hesap := range s.cariHesapService.HesaplariListele() {
		hareketler := s.cariHesapService.HareketleriListele(hesap.HesapID)

		var toplamBorc float64
		var toplamAlacak float64

		for _, h := range hareketler {
			if h.HareketTip == "borc" {
				toplamBorc += h.Tutar
			} else {
				toplamAlacak += h.Tutar
			}
		}

		sonuc = append(sonuc, rapordomain.MizanSatir{
			HesapKodu:    hesap.Kod,
			HesapAdi:     hesap.Unvan,
			ToplamBorc:   toplamBorc,
			ToplamAlacak: toplamAlacak,
			Bakiye:       toplamBorc - toplamAlacak,
		})
	}

	for _, kasa := range s.kasaService.KasalariListele() {
		hareketler := s.kasaService.HareketleriListele(kasa.KasaID)

		var toplamBorc float64
		var toplamAlacak float64

		for _, h := range hareketler {
			if h.HareketTip == "giris" {
				toplamBorc += h.Tutar
			} else {
				toplamAlacak += h.Tutar
			}
		}

		sonuc = append(sonuc, rapordomain.MizanSatir{
			HesapKodu:    kasa.Kod,
			HesapAdi:     kasa.Ad,
			ToplamBorc:   toplamBorc,
			ToplamAlacak: toplamAlacak,
			Bakiye:       toplamBorc - toplamAlacak,
		})
	}

	for _, hesap := range s.bankaService.HesaplariListele() {
		hareketler := s.bankaService.HareketleriListele(hesap.HesapID)

		var toplamBorc float64
		var toplamAlacak float64

		for _, h := range hareketler {
			if h.HareketTip == "giris" {
				toplamBorc += h.Tutar
			} else {
				toplamAlacak += h.Tutar
			}
		}

		sonuc = append(sonuc, rapordomain.MizanSatir{
			HesapKodu:    hesap.Kod,
			HesapAdi:     hesap.BankaAdi + " " + hesap.SubeAdi,
			ToplamBorc:   toplamBorc,
			ToplamAlacak: toplamAlacak,
			Bakiye:       toplamBorc - toplamAlacak,
		})
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].HesapKodu < sonuc[j].HesapKodu
	})

	return sonuc
}
