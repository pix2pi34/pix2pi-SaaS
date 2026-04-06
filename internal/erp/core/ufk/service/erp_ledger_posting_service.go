package service

import (
	"fmt"

	ufkdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ufk/domain"
)

type LedgerPostingService struct {
	hesaplar map[string]*ufkdomain.LedgerAccount
}

func NewLedgerPostingService() *LedgerPostingService {

	return &LedgerPostingService{
		hesaplar: make(map[string]*ufkdomain.LedgerAccount),
	}
}

func (s *LedgerPostingService) Post(
	hesapKodu string,
	borc float64,
	alacak float64,
) {

	h, ok := s.hesaplar[hesapKodu]

	if !ok {

		h = &ufkdomain.LedgerAccount{
			HesapKodu: hesapKodu,
			Bakiye:    0,
		}

		s.hesaplar[hesapKodu] = h
	}

	h.Bakiye += borc
	h.Bakiye -= alacak
}

func (s *LedgerPostingService) Yazdir() {

	fmt.Println("Ledger Hesaplari")
	fmt.Println("----------------")

	for _, h := range s.hesaplar {

		fmt.Printf(
			"Hesap:%s Bakiye:%.2f\n",
			h.HesapKodu,
			h.Bakiye,
		)

	}
}

func (s *LedgerPostingService) Hesaplar() map[string]*ufkdomain.LedgerAccount {
	return s.hesaplar
}
