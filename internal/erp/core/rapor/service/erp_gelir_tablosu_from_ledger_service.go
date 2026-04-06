package service

import (
	"fmt"
	"strings"

	ufkservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ufk/service"
)

type GelirTablosuFromLedgerService struct {
	ledger *ufkservice.LedgerPostingService
}

func NewGelirTablosuFromLedgerService(
	ledger *ufkservice.LedgerPostingService,
) *GelirTablosuFromLedgerService {

	return &GelirTablosuFromLedgerService{
		ledger: ledger,
	}
}

func (s *GelirTablosuFromLedgerService) Yazdir() {

	gelirToplam := 0.0
	giderToplam := 0.0

	fmt.Println("Gelir Tablosu")
	fmt.Println("--------------")

	for kod, hesap := range s.ledger.Hesaplar() {

		if strings.HasPrefix(kod, "6") {

			tutar := -hesap.Bakiye
			gelirToplam += tutar

			fmt.Printf("Gelir Hesap:%s Tutar:%.2f\n", kod, tutar)
		}

		if strings.HasPrefix(kod, "7") {

			tutar := hesap.Bakiye
			giderToplam += tutar

			fmt.Printf("Gider Hesap:%s Tutar:%.2f\n", kod, tutar)
		}

	}

	fmt.Println("----------------")

	fmt.Printf("Toplam Gelir: %.2f\n", gelirToplam)
	fmt.Printf("Toplam Gider: %.2f\n", giderToplam)

	net := gelirToplam - giderToplam

	fmt.Printf("Net Kar/Zarar: %.2f\n", net)
}
