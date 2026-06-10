package service

import (
	"fmt"
	"sort"
	"time"

	caridomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain"
)

type CariHesapService struct {
	hesaplar   map[string]caridomain.CariHesap
	hareketler map[string][]caridomain.CariHareket
}

func NewCariHesapService() *CariHesapService {
	return &CariHesapService{
		hesaplar:   make(map[string]caridomain.CariHesap),
		hareketler: make(map[string][]caridomain.CariHareket),
	}
}

func (s *CariHesapService) CariHesapOlustur(
	hesapID string,
	tenantID string,
	tenantUUID string,
	cariTip string,
	kod string,
	unvan string,
	paraBirimi string,
	vergiNo string,
	vergiDairesi string,
	mersisNo string,
	adres string,
	telefon string,
	email string,
) error {
	if hesapID == "" {
		return fmt.Errorf("hesap id bos olamaz")
	}
	if tenantID == "" {
		return fmt.Errorf("tenant id zorunlu")
	}
	if tenantUUID == "" {
		return fmt.Errorf("tenant uuid zorunlu")
	}
	if cariTip == "" {
		return fmt.Errorf("cari tip bos olamaz")
	}
	if kod == "" {
		return fmt.Errorf("kod bos olamaz")
	}
	if unvan == "" {
		return fmt.Errorf("unvan bos olamaz")
	}
	if paraBirimi == "" {
		return fmt.Errorf("para birimi bos olamaz")
	}
	if vergiNo == "" {
		return fmt.Errorf("vergi no zorunludur")
	}
	if vergiDairesi == "" {
		return fmt.Errorf("vergi dairesi zorunludur")
	}
	if adres == "" {
		return fmt.Errorf("adres zorunludur")
	}

	if _, varMi := s.hesaplar[hesapID]; varMi {
		return fmt.Errorf("cari hesap zaten var: %s", hesapID)
	}

	s.hesaplar[hesapID] = caridomain.CariHesap{
		HesapID:      hesapID,
		TenantID:     tenantID,
		TenantUUID:   tenantUUID,
		CariTip:      cariTip,
		Kod:          kod,
		Unvan:        unvan,
		ParaBirimi:   paraBirimi,
		VergiNo:      vergiNo,
		VergiDairesi: vergiDairesi,
		MersisNo:     mersisNo,
		Adres:        adres,
		Telefon:      telefon,
		Email:        email,
		AcikBakiye:   0,
	}

	return nil
}

func (s *CariHesapService) CariHesapGetir(
	tenantID string,
	hesapID string,
) (caridomain.CariHesap, error) {
	hesap, varMi := s.hesaplar[hesapID]
	if !varMi {
		return caridomain.CariHesap{}, fmt.Errorf("cari hesap bulunamadi: %s", hesapID)
	}
	if hesap.TenantID != tenantID {
		return caridomain.CariHesap{}, fmt.Errorf("tenant uyusmuyor")
	}

	return hesap, nil
}

func (s *CariHesapService) CariHareketEkle(
	tenantID string,
	hareket caridomain.CariHareket,
) error {
	if tenantID == "" {
		return fmt.Errorf("tenant id zorunlu")
	}
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
		return fmt.Errorf("tutar sifirdan buyuk olmalidir")
	}
	if hareket.ParaBirimi == "" {
		return fmt.Errorf("para birimi bos olamaz")
	}

	hesap, varMi := s.hesaplar[hareket.HesapID]
	if !varMi {
		return fmt.Errorf("cari hesap bulunamadi: %s", hareket.HesapID)
	}
	if hesap.TenantID != tenantID {
		return fmt.Errorf("tenant uyusmuyor")
	}
	if hesap.ParaBirimi != hareket.ParaBirimi {
		return fmt.Errorf("para birimi uyusmuyor")
	}

	if hareket.OlusturmaTarihi.IsZero() {
		hareket.OlusturmaTarihi = time.Now()
	}

	s.hareketler[hareket.HesapID] = append(s.hareketler[hareket.HesapID], hareket)
	return nil
}

func (s *CariHesapService) TenantHesaplariListele(
	tenantID string,
) []caridomain.CariHesap {
	sonuc := make([]caridomain.CariHesap, 0)

	for _, hesap := range s.hesaplar {
		if hesap.TenantID == tenantID {
			sonuc = append(sonuc, hesap)
		}
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].Kod < sonuc[j].Kod
	})

	return sonuc
}

func (s *CariHesapService) TenantHareketleriListele(
	tenantID string,
	hesapID string,
) []caridomain.CariHareket {
	hesap, varMi := s.hesaplar[hesapID]
	if !varMi {
		return []caridomain.CariHareket{}
	}
	if hesap.TenantID != tenantID {
		return []caridomain.CariHareket{}
	}

	sonuc := make([]caridomain.CariHareket, 0)
	for _, hareket := range s.hareketler[hesapID] {
		sonuc = append(sonuc, hareket)
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *CariHesapService) BakiyeHesapla(
	tenantID string,
	hesapID string,
) (float64, error) {
	hesap, varMi := s.hesaplar[hesapID]
	if !varMi {
		return 0, fmt.Errorf("cari hesap bulunamadi: %s", hesapID)
	}
	if hesap.TenantID != tenantID {
		return 0, fmt.Errorf("tenant uyusmuyor")
	}

	bakiye := hesap.AcikBakiye

	for _, hareket := range s.hareketler[hesapID] {
		switch hareket.HareketTip {
		case caridomain.CariHareketTipBorc:
			bakiye += hareket.Tutar
		case caridomain.CariHareketTipAlacak:
			bakiye -= hareket.Tutar
		}
	}

	return bakiye, nil
}

// HesaplariListele eski rapor katmanı için compatibility wrapper'dır.
// Yeni tenant-aware rapor katmanı geldiğinde tenant_id parametreli gerçek listeleme ile değiştirilecektir.
func (s *CariHesapService) HesaplariListele() []caridomain.CariHesap {
	return []caridomain.CariHesap{}
}

// HareketleriListele eski rapor katmanı için compatibility wrapper'dır.
// Yeni tenant-aware rapor katmanı geldiğinde gerçek tenant filtreli listeleme ile değiştirilecektir.
func (s *CariHesapService) HareketleriListele(tenantID string) []caridomain.CariHareket {
	_ = tenantID
	return []caridomain.CariHareket{}
}
