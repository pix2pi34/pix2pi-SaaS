package service

import (
	"fmt"
	"sort"

	journaldomain "github.com/divrigili/pix2pi-SaaS/internal/ufk/domain"
)

type LedgerPostingService struct {
	hesaplar map[string]journaldomain.LedgerAccount
}

func NewLedgerPostingService() *LedgerPostingService {
	return &LedgerPostingService{
		hesaplar: make(map[string]journaldomain.LedgerAccount),
	}
}

func (s *LedgerPostingService) JournalSatirlariniIsle(
	satirlar []journaldomain.JournalLine,
) error {
	if len(satirlar) == 0 {
		return fmt.Errorf("journal satirlari bos olamaz")
	}

	for _, satir := range satirlar {
		if satir.HesapKodu == "" {
			return fmt.Errorf("hesap kodu zorunlu")
		}

		mevcut := s.hesaplar[satir.HesapKodu]
		mevcut.HesapKodu = satir.HesapKodu
		mevcut.Bakiye = mevcut.Bakiye + satir.Borc - satir.Alacak

		s.hesaplar[satir.HesapKodu] = mevcut
	}

	return nil
}

func (s *LedgerPostingService) HesapGetir(
	hesapKodu string,
) (journaldomain.LedgerAccount, error) {
	if hesapKodu == "" {
		return journaldomain.LedgerAccount{}, fmt.Errorf("hesap kodu zorunlu")
	}

	hesap, varMi := s.hesaplar[hesapKodu]
	if !varMi {
		return journaldomain.LedgerAccount{}, fmt.Errorf("hesap bulunamadi")
	}

	return hesap, nil
}

func (s *LedgerPostingService) TumHesaplariListele() []journaldomain.LedgerAccount {
	sonuc := make([]journaldomain.LedgerAccount, 0, len(s.hesaplar))

	for _, hesap := range s.hesaplar {
		sonuc = append(sonuc, hesap)
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].HesapKodu < sonuc[j].HesapKodu
	})

	return sonuc
}
