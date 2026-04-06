package service

import (
	"fmt"
	"time"

	bankadomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/banka/domain"
	bankaservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/banka/service"
	caridomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain"
	cariservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/service"
	kasadomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/kasa/domain"
	kasaservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/kasa/service"
	tahsilatdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/tahsilat/domain"
)

type TahsilatService struct {
	cariHesapService *cariservice.CariHesapService
	kasaService      *kasaservice.KasaService
	bankaService     *bankaservice.BankaService
	tahsilatlar      []tahsilatdomain.Tahsilat
	odemeler         []tahsilatdomain.Odeme
}

func NewTahsilatService(
	cariHesapService *cariservice.CariHesapService,
	kasaService *kasaservice.KasaService,
	bankaService *bankaservice.BankaService,
) *TahsilatService {
	return &TahsilatService{
		cariHesapService: cariHesapService,
		kasaService:      kasaService,
		bankaService:     bankaService,
		tahsilatlar:      make([]tahsilatdomain.Tahsilat, 0),
		odemeler:         make([]tahsilatdomain.Odeme, 0),
	}
}

func (s *TahsilatService) TahsilatEkle(
	tahsilat tahsilatdomain.Tahsilat,
) error {
	if tahsilat.TahsilatID == "" {
		return fmt.Errorf("tahsilat id bos olamaz")
	}
	if tahsilat.CariID == "" {
		return fmt.Errorf("cari id bos olamaz")
	}
	if tahsilat.Tutar <= 0 {
		return fmt.Errorf("tutar sifirdan buyuk olmali")
	}
	if tahsilat.ParaBirimi == "" {
		return fmt.Errorf("para birimi bos olamaz")
	}
	if tahsilat.KasaID == "" && tahsilat.BankaID == "" {
		return fmt.Errorf("kasa veya banka zorunludur")
	}
	if tahsilat.KasaID != "" && tahsilat.BankaID != "" {
		return fmt.Errorf("aynı anda hem kasa hem banka kullanilamaz")
	}
	if tahsilat.Tarih.IsZero() {
		tahsilat.Tarih = time.Now()
	}

	hesap, err := s.cariHesapService.CariHesapGetir(tahsilat.CariID)
	if err != nil {
		return err
	}
	if hesap.ParaBirimi != tahsilat.ParaBirimi {
		return fmt.Errorf("cari para birimi uyusmuyor")
	}

	err = s.cariHesapService.CariHareketEkle(
		caridomain.CariHareket{
			HareketID:       "cari-" + tahsilat.TahsilatID,
			HesapID:         tahsilat.CariID,
			HareketTip:      caridomain.CariHareketTipAlacak,
			Tutar:           tahsilat.Tutar,
			ParaBirimi:      tahsilat.ParaBirimi,
			BelgeNo:         "TAHSILAT-" + tahsilat.TahsilatID,
			ReferansID:      tahsilat.TahsilatID,
			Aciklama:        tahsilat.Aciklama,
			VadeTarihi:      tahsilat.Tarih,
			OlusturmaTarihi: tahsilat.Tarih,
		},
	)
	if err != nil {
		return err
	}

	if tahsilat.KasaID != "" {
		err = s.kasaService.KasaHareketEkle(
			kasadomain.KasaHareket{
				HareketID:       "kasa-" + tahsilat.TahsilatID,
				KasaID:          tahsilat.KasaID,
				HareketTip:      kasadomain.KasaHareketTipGiris,
				Tutar:           tahsilat.Tutar,
				BelgeNo:         "TAHSILAT-" + tahsilat.TahsilatID,
				ReferansID:      tahsilat.TahsilatID,
				Aciklama:        tahsilat.Aciklama,
				OlusturmaTarihi: tahsilat.Tarih,
			},
		)
		if err != nil {
			return err
		}
	}

	if tahsilat.BankaID != "" {
		err = s.bankaService.BankaHareketEkle(
			bankadomain.BankaHareket{
				HareketID:       "banka-" + tahsilat.TahsilatID,
				HesapID:         tahsilat.BankaID,
				HareketTip:      bankadomain.BankaHareketTipGiris,
				Tutar:           tahsilat.Tutar,
				BelgeNo:         "TAHSILAT-" + tahsilat.TahsilatID,
				ReferansID:      tahsilat.TahsilatID,
				Aciklama:        tahsilat.Aciklama,
				OlusturmaTarihi: tahsilat.Tarih,
			},
		)
		if err != nil {
			return err
		}
	}

	s.tahsilatlar = append(s.tahsilatlar, tahsilat)
	return nil
}

func (s *TahsilatService) OdemeEkle(
	odeme tahsilatdomain.Odeme,
) error {
	if odeme.OdemeID == "" {
		return fmt.Errorf("odeme id bos olamaz")
	}
	if odeme.CariID == "" {
		return fmt.Errorf("cari id bos olamaz")
	}
	if odeme.Tutar <= 0 {
		return fmt.Errorf("tutar sifirdan buyuk olmali")
	}
	if odeme.ParaBirimi == "" {
		return fmt.Errorf("para birimi bos olamaz")
	}
	if odeme.KasaID == "" && odeme.BankaID == "" {
		return fmt.Errorf("kasa veya banka zorunludur")
	}
	if odeme.KasaID != "" && odeme.BankaID != "" {
		return fmt.Errorf("aynı anda hem kasa hem banka kullanilamaz")
	}
	if odeme.Tarih.IsZero() {
		odeme.Tarih = time.Now()
	}

	hesap, err := s.cariHesapService.CariHesapGetir(odeme.CariID)
	if err != nil {
		return err
	}
	if hesap.ParaBirimi != odeme.ParaBirimi {
		return fmt.Errorf("cari para birimi uyusmuyor")
	}

	err = s.cariHesapService.CariHareketEkle(
		caridomain.CariHareket{
			HareketID:       "cari-" + odeme.OdemeID,
			HesapID:         odeme.CariID,
			HareketTip:      caridomain.CariHareketTipAlacak,
			Tutar:           odeme.Tutar,
			ParaBirimi:      odeme.ParaBirimi,
			BelgeNo:         "ODEME-" + odeme.OdemeID,
			ReferansID:      odeme.OdemeID,
			Aciklama:        odeme.Aciklama,
			VadeTarihi:      odeme.Tarih,
			OlusturmaTarihi: odeme.Tarih,
		},
	)
	if err != nil {
		return err
	}

	if odeme.KasaID != "" {
		err = s.kasaService.KasaHareketEkle(
			kasadomain.KasaHareket{
				HareketID:       "kasa-" + odeme.OdemeID,
				KasaID:          odeme.KasaID,
				HareketTip:      kasadomain.KasaHareketTipCikis,
				Tutar:           odeme.Tutar,
				BelgeNo:         "ODEME-" + odeme.OdemeID,
				ReferansID:      odeme.OdemeID,
				Aciklama:        odeme.Aciklama,
				OlusturmaTarihi: odeme.Tarih,
			},
		)
		if err != nil {
			return err
		}
	}

	if odeme.BankaID != "" {
		err = s.bankaService.BankaHareketEkle(
			bankadomain.BankaHareket{
				HareketID:       "banka-" + odeme.OdemeID,
				HesapID:         odeme.BankaID,
				HareketTip:      bankadomain.BankaHareketTipCikis,
				Tutar:           odeme.Tutar,
				BelgeNo:         "ODEME-" + odeme.OdemeID,
				ReferansID:      odeme.OdemeID,
				Aciklama:        odeme.Aciklama,
				OlusturmaTarihi: odeme.Tarih,
			},
		)
		if err != nil {
			return err
		}
	}

	s.odemeler = append(s.odemeler, odeme)
	return nil
}

func (s *TahsilatService) TahsilatlariListele() []tahsilatdomain.Tahsilat {
	return s.tahsilatlar
}

func (s *TahsilatService) OdemeleriListele() []tahsilatdomain.Odeme {
	return s.odemeler
}
