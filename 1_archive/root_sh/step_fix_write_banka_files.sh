#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

cat <<'GOEOF' > internal/erp/core/banka/domain/erp_banka_hesap.go
package domain

type BankaHesap struct {
	HesapID    string
	Kod        string
	BankaAdi   string
	SubeAdi    string
	Iban       string
	ParaBirimi string
	Aktif      bool
}
GOEOF

cat <<'GOEOF' > internal/erp/core/banka/domain/erp_banka_hareket.go
package domain

import "time"

const (
	BankaHareketTipGiris = "giris"
	BankaHareketTipCikis = "cikis"
)

type BankaHareket struct {
	HareketID       string
	HesapID         string
	HareketTip      string
	Tutar           float64
	BelgeNo         string
	ReferansID      string
	Aciklama        string
	OlusturmaTarihi time.Time
}
GOEOF

cat <<'GOEOF' > internal/erp/core/banka/service/erp_banka_service.go
package service

import (
	"fmt"
	"sort"
	"time"

	bankadomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/banka/domain"
)

type BankaService struct {
	hesaplar   map[string]bankadomain.BankaHesap
	hareketler map[string][]bankadomain.BankaHareket
}

func NewBankaService() *BankaService {
	return &BankaService{
		hesaplar:   make(map[string]bankadomain.BankaHesap),
		hareketler: make(map[string][]bankadomain.BankaHareket),
	}
}

func (s *BankaService) BankaHesapOlustur(
	hesapID string,
	kod string,
	bankaAdi string,
	subeAdi string,
	iban string,
	paraBirimi string,
) error {
	if hesapID == "" {
		return fmt.Errorf("hesap id bos olamaz")
	}
	if kod == "" {
		return fmt.Errorf("kod bos olamaz")
	}
	if bankaAdi == "" {
		return fmt.Errorf("banka adi bos olamaz")
	}
	if subeAdi == "" {
		return fmt.Errorf("sube adi bos olamaz")
	}
	if iban == "" {
		return fmt.Errorf("iban bos olamaz")
	}
	if paraBirimi == "" {
		return fmt.Errorf("para birimi bos olamaz")
	}
	if _, varMi := s.hesaplar[hesapID]; varMi {
		return fmt.Errorf("banka hesabi zaten var: %s", hesapID)
	}

	s.hesaplar[hesapID] = bankadomain.BankaHesap{
		HesapID:    hesapID,
		Kod:        kod,
		BankaAdi:   bankaAdi,
		SubeAdi:    subeAdi,
		Iban:       iban,
		ParaBirimi: paraBirimi,
		Aktif:      true,
	}

	return nil
}

func (s *BankaService) BankaHesapGetir(
	hesapID string,
) (bankadomain.BankaHesap, error) {
	hesap, varMi := s.hesaplar[hesapID]
	if !varMi {
		return bankadomain.BankaHesap{}, fmt.Errorf("banka hesabi bulunamadi: %s", hesapID)
	}
	return hesap, nil
}

func (s *BankaService) BankaHareketEkle(
	hareket bankadomain.BankaHareket,
) error {
	if hareket.HareketID == "" {
		return fmt.Errorf("hareket id bos olamaz")
	}
	if hareket.HesapID == "" {
		return fmt.Errorf("hesap id bos olamaz")
	}
	if hareket.HareketTip == "" {
		return fmt.Errorf("hareket tip bos olamaz")
	}
	if hareket.Tutar <= 0 {
		return fmt.Errorf("tutar sifirdan buyuk olmali")
	}

	_, varMi := s.hesaplar[hareket.HesapID]
	if !varMi {
		return fmt.Errorf("banka hesabi bulunamadi: %s", hareket.HesapID)
	}

	if hareket.OlusturmaTarihi.IsZero() {
		hareket.OlusturmaTarihi = time.Now()
	}

	if hareket.HareketTip == bankadomain.BankaHareketTipCikis {
		bakiye, err := s.BakiyeHesapla(hareket.HesapID)
		if err != nil {
			return err
		}
		if bakiye < hareket.Tutar {
			return fmt.Errorf("yetersiz banka bakiyesi: mevcut=%.2f cikis=%.2f", bakiye, hareket.Tutar)
		}
	}

	s.hareketler[hareket.HesapID] = append(s.hareketler[hareket.HesapID], hareket)
	return nil
}

func (s *BankaService) HesaplariListele() []bankadomain.BankaHesap {
	sonuc := make([]bankadomain.BankaHesap, 0, len(s.hesaplar))

	for _, hesap := range s.hesaplar {
		sonuc = append(sonuc, hesap)
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].Kod < sonuc[j].Kod
	})

	return sonuc
}

func (s *BankaService) HareketleriListele(
	hesapID string,
) []bankadomain.BankaHareket {
	sonuc := make([]bankadomain.BankaHareket, 0)

	for _, hareket := range s.hareketler[hesapID] {
		sonuc = append(sonuc, hareket)
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *BankaService) BakiyeHesapla(
	hesapID string,
) (float64, error) {
	_, varMi := s.hesaplar[hesapID]
	if !varMi {
		return 0, fmt.Errorf("banka hesabi bulunamadi: %s", hesapID)
	}

	var bakiye float64

	for _, hareket := range s.hareketler[hesapID] {
		switch hareket.HareketTip {
		case bankadomain.BankaHareketTipGiris:
			bakiye += hareket.Tutar
		case bankadomain.BankaHareketTipCikis:
			bakiye -= hareket.Tutar
		}
	}

	return bakiye, nil
}
GOEOF

echo "OK ✅ banka dosyalari yazildi"
