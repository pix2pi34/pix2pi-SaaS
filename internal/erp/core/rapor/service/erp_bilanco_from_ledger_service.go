package service

import (
	"fmt"
	"strings"

	ufkservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ufk/service"
)

type BilancoFromLedgerService struct {
	ledger *ufkservice.LedgerPostingService
}

func NewBilancoFromLedgerService(
	ledger *ufkservice.LedgerPostingService,
) *BilancoFromLedgerService {

	return &BilancoFromLedgerService{
		ledger: ledger,
	}
}

func (s *BilancoFromLedgerService) Yazdir() {

	aktifToplam := 0.0
	pasifToplam := 0.0

	fmt.Println("Bilanco")
	fmt.Println("-------")

	for kod, hesap := range s.ledger.Hesaplar() {

		if strings.HasPrefix(kod, "1") {

			tutar := hesap.Bakiye
			if tutar < 0 {
				tutar = -tutar
			}

			aktifToplam += tutar

			fmt.Printf("Aktif Hesap:%s Tutar:%.2f\n", kod, tutar)
		}

		if strings.HasPrefix(kod, "3") || strings.HasPrefix(kod, "5") {

			tutar := -hesap.Bakiye
			if tutar < 0 {
				tutar = -tutar
			}

			pasifToplam += tutar

			fmt.Printf("Pasif Hesap:%s Tutar:%.2f\n", kod, tutar)
		}

	}

	fmt.Println("-------------")

	fmt.Printf("Toplam Aktif: %.2f\n", aktifToplam)
	fmt.Printf("Toplam Pasif: %.2f\n", pasifToplam)
}
