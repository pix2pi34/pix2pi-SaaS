package service

import (
	"fmt"
	"sort"
	"time"

	kasadomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/kasa/domain"
)

type KasaService struct {
	kasalar    map[string]kasadomain.KasaHesap
	hareketler map[string][]kasadomain.KasaHareket
}

func NewKasaService() *KasaService {
	return &KasaService{
		kasalar:    make(map[string]kasadomain.KasaHesap),
		hareketler: make(map[string][]kasadomain.KasaHareket),
	}
}

func (s *KasaService) KasaOlustur(
	kasaID string,
	kod string,
	ad string,
	paraBirimi string,
) error {
	if kasaID == "" {
		return fmt.Errorf("kasa id bos olamaz")
	}
	if kod == "" {
		return fmt.Errorf("kod bos olamaz")
	}
	if ad == "" {
		return fmt.Errorf("ad bos olamaz")
	}
	if paraBirimi == "" {
		return fmt.Errorf("para birimi bos olamaz")
	}
	if _, varMi := s.kasalar[kasaID]; varMi {
		return fmt.Errorf("kasa zaten var: %s", kasaID)
	}

	s.kasalar[kasaID] = kasadomain.KasaHesap{
		KasaID:     kasaID,
		Kod:        kod,
		Ad:         ad,
		ParaBirimi: paraBirimi,
		Aktif:      true,
	}

	return nil
}

func (s *KasaService) KasaGetir(
	kasaID string,
) (kasadomain.KasaHesap, error) {
	kasa, varMi := s.kasalar[kasaID]
	if !varMi {
		return kasadomain.KasaHesap{}, fmt.Errorf("kasa bulunamadi: %s", kasaID)
	}
	return kasa, nil
}

func (s *KasaService) KasaHareketEkle(
	hareket kasadomain.KasaHareket,
) error {
	if hareket.HareketID == "" {
		return fmt.Errorf("hareket id bos olamaz")
	}
	if hareket.KasaID == "" {
		return fmt.Errorf("kasa id bos olamaz")
	}
	if hareket.HareketTip == "" {
		return fmt.Errorf("hareket tip bos olamaz")
	}
	if hareket.Tutar <= 0 {
		return fmt.Errorf("tutar sifirdan buyuk olmali")
	}
	if hareket.ParaBirimi == "" {
		return fmt.Errorf("para birimi bos olamaz")
	}

	kasa, varMi := s.kasalar[hareket.KasaID]
	if !varMi {
		return fmt.Errorf("kasa bulunamadi: %s", hareket.KasaID)
	}

	if kasa.ParaBirimi != hareket.ParaBirimi {
		return fmt.Errorf("kasa para birimi uyusmuyor: kasa=%s hareket=%s", kasa.ParaBirimi, hareket.ParaBirimi)
	}

	if hareket.OlusturmaTarihi.IsZero() {
		hareket.OlusturmaTarihi = time.Now()
	}

	if hareket.HareketTip == kasadomain.KasaHareketTipCikis {
		bakiye, err := s.KasaBakiyeHesapla(hareket.KasaID)
		if err != nil {
			return err
		}
		if bakiye < hareket.Tutar {
			return fmt.Errorf("yetersiz kasa bakiyesi: mevcut=%.2f cikis=%.2f", bakiye, hareket.Tutar)
		}
	}

	s.hareketler[hareket.KasaID] = append(s.hareketler[hareket.KasaID], hareket)
	return nil
}

func (s *KasaService) KasalariListele() []kasadomain.KasaHesap {
	sonuc := make([]kasadomain.KasaHesap, 0, len(s.kasalar))

	for _, kasa := range s.kasalar {
		sonuc = append(sonuc, kasa)
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].Kod < sonuc[j].Kod
	})

	return sonuc
}

func (s *KasaService) HareketleriListele(
	kasaID string,
) []kasadomain.KasaHareket {
	sonuc := make([]kasadomain.KasaHareket, 0)

	for _, hareket := range s.hareketler[kasaID] {
		sonuc = append(sonuc, hareket)
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *KasaService) KasaBakiyeHesapla(
	kasaID string,
) (float64, error) {
	_, varMi := s.kasalar[kasaID]
	if !varMi {
		return 0, fmt.Errorf("kasa bulunamadi: %s", kasaID)
	}

	var bakiye float64

	for _, hareket := range s.hareketler[kasaID] {
		switch hareket.HareketTip {
		case kasadomain.KasaHareketTipGiris:
			bakiye += hareket.Tutar
		case kasadomain.KasaHareketTipCikis:
			bakiye -= hareket.Tutar
		}
	}

	return bakiye, nil
}

func (s *KasaService) KasaEkstreGetir(
	kasaID string,
) ([]kasadomain.KasaEkstreSatir, error) {
	_, varMi := s.kasalar[kasaID]
	if !varMi {
		return nil, fmt.Errorf("kasa bulunamadi: %s", kasaID)
	}

	hareketler := make([]kasadomain.KasaHareket, 0, len(s.hareketler[kasaID]))
	hareketler = append(hareketler, s.hareketler[kasaID]...)

	sort.Slice(hareketler, func(i, j int) bool {
		return hareketler[i].OlusturmaTarihi.Before(hareketler[j].OlusturmaTarihi)
	})

	var bakiye float64
	ekstre := make([]kasadomain.KasaEkstreSatir, 0, len(hareketler))

	for _, h := range hareketler {
		var giris float64
		var cikis float64

		if h.HareketTip == kasadomain.KasaHareketTipGiris {
			giris = h.Tutar
			bakiye += h.Tutar
		} else {
			cikis = h.Tutar
			bakiye -= h.Tutar
		}

		ekstre = append(ekstre, kasadomain.KasaEkstreSatir{
			Tarih:    h.OlusturmaTarihi,
			BelgeNo:  h.BelgeNo,
			Aciklama: h.Aciklama,
			Giris:    giris,
			Cikis:    cikis,
			Bakiye:   bakiye,
		})
	}

	return ekstre, nil
}
