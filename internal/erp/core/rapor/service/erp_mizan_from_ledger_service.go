package service

import (
	"fmt"

	ufkservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ufk/service"
)

type MizanFromLedgerService struct {
	ledger *ufkservice.LedgerPostingService
}

func NewMizanFromLedgerService(
	ledger *ufkservice.LedgerPostingService,
) *MizanFromLedgerService {

	return &MizanFromLedgerService{
		ledger: ledger,
	}
}

func (s *MizanFromLedgerService) Yazdir() {

	fmt.Println("Mizan")
	fmt.Println("-----")

	for kod, hesap := range s.ledger.Hesaplar() {

		borc := 0.0
		alacak := 0.0

		if hesap.Bakiye > 0 {
			borc = hesap.Bakiye
		} else {
			alacak = -hesap.Bakiye
		}

		fmt.Printf(
			"Hesap:%s Borc:%.2f Alacak:%.2f\n",
			kod,
			borc,
			alacak,
		)

	}
}
