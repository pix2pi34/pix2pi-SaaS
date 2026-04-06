package service

import (
	"fmt"
	"sort"
	"time"

	stokdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/stok/domain"
)

type StokService struct {
	urunler    map[string]stokdomain.UrunKart
	hareketler map[string][]stokdomain.StokHareket
}

func NewStokService() *StokService {
	return &StokService{
		urunler:    make(map[string]stokdomain.UrunKart),
		hareketler: make(map[string][]stokdomain.StokHareket),
	}
}

func (s *StokService) UrunKartOlustur(
	urunID string,
	urunKod string,
	urunAdi string,
	birim string,
	paraBirimi string,
	kdvOrani float64,
	alisFiyati float64,
	satisFiyati float64,
) error {
	if urunID == "" {
		return fmt.Errorf("urun id bos olamaz")
	}
	if urunKod == "" {
		return fmt.Errorf("urun kod bos olamaz")
	}
	if urunAdi == "" {
		return fmt.Errorf("urun adi bos olamaz")
	}
	if birim == "" {
		return fmt.Errorf("birim bos olamaz")
	}
	if paraBirimi == "" {
		return fmt.Errorf("para birimi bos olamaz")
	}
	if _, varMi := s.urunler[urunID]; varMi {
		return fmt.Errorf("urun zaten var: %s", urunID)
	}

	s.urunler[urunID] = stokdomain.UrunKart{
		UrunID:      urunID,
		UrunKod:     urunKod,
		UrunAdi:     urunAdi,
		Birim:       birim,
		ParaBirimi:  paraBirimi,
		KdvOrani:    kdvOrani,
		AlisFiyati:  alisFiyati,
		SatisFiyati: satisFiyati,
		Aktif:       true,
	}

	return nil
}

func (s *StokService) UrunKartGetir(urunID string) (stokdomain.UrunKart, error) {
	urun, varMi := s.urunler[urunID]
	if !varMi {
		return stokdomain.UrunKart{}, fmt.Errorf("urun bulunamadi: %s", urunID)
	}
	return urun, nil
}

func (s *StokService) StokHareketEkle(hareket stokdomain.StokHareket) error {
	if hareket.HareketID == "" {
		return fmt.Errorf("hareket id bos olamaz")
	}
	if hareket.UrunID == "" {
		return fmt.Errorf("urun id bos olamaz")
	}
	if hareket.HareketTip == "" {
		return fmt.Errorf("hareket tip bos olamaz")
	}
	if hareket.Miktar <= 0 {
		return fmt.Errorf("miktar sifirdan buyuk olmali")
	}

	_, varMi := s.urunler[hareket.UrunID]
	if !varMi {
		return fmt.Errorf("urun bulunamadi: %s", hareket.UrunID)
	}

	if hareket.OlusturmaTarihi.IsZero() {
		hareket.OlusturmaTarihi = time.Now()
	}

	if hareket.HareketTip == stokdomain.StokHareketTipCikis {
		mevcutStok, err := s.StokMiktariHesapla(hareket.UrunID)
		if err != nil {
			return err
		}
		if mevcutStok < hareket.Miktar {
			return fmt.Errorf("yetersiz stok: mevcut=%.2f cikis=%.2f", mevcutStok, hareket.Miktar)
		}
	}

	s.hareketler[hareket.UrunID] = append(s.hareketler[hareket.UrunID], hareket)
	return nil
}

func (s *StokService) StokMiktariHesapla(urunID string) (float64, error) {
	_, varMi := s.urunler[urunID]
	if !varMi {
		return 0, fmt.Errorf("urun bulunamadi: %s", urunID)
	}

	var miktar float64

	for _, hareket := range s.hareketler[urunID] {
		switch hareket.HareketTip {
		case stokdomain.StokHareketTipGiris:
			miktar += hareket.Miktar
		case stokdomain.StokHareketTipCikis:
			miktar -= hareket.Miktar
		}
	}

	return miktar, nil
}

func (s *StokService) UrunleriListele() []stokdomain.UrunKart {
	sonuc := make([]stokdomain.UrunKart, 0, len(s.urunler))

	for _, urun := range s.urunler {
		sonuc = append(sonuc, urun)
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].UrunKod < sonuc[j].UrunKod
	})

	return sonuc
}

func (s *StokService) HareketleriListele(urunID string) []stokdomain.StokHareket {
	sonuc := make([]stokdomain.StokHareket, 0)

	for _, hareket := range s.hareketler[urunID] {
		sonuc = append(sonuc, hareket)
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}
