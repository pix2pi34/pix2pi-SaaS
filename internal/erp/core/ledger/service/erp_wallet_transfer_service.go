package service

import (
	"fmt"

	ledgerdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/domain"
)

type WalletTransferService struct {
	multiLedgerService *MultiLedgerService
}

func NewWalletTransferService(
	multiLedgerService *MultiLedgerService,
) *WalletTransferService {
	return &WalletTransferService{
		multiLedgerService: multiLedgerService,
	}
}

func (s *WalletTransferService) Transfer(
	transfer ledgerdomain.WalletTransfer,
) error {
	if transfer.TransferID == "" {
		return fmt.Errorf("transfer id cannot be empty")
	}

	if transfer.FromAccountID == "" {
		return fmt.Errorf("from account id cannot be empty")
	}

	if transfer.ToAccountID == "" {
		return fmt.Errorf("to account id cannot be empty")
	}

	if transfer.Amount <= 0 {
		return fmt.Errorf("amount must be greater than zero")
	}

	fromAcc, err := s.multiLedgerService.GetAccount(transfer.FromAccountID)
	if err != nil {
		return err
	}

	toAcc, err := s.multiLedgerService.GetAccount(transfer.ToAccountID)
	if err != nil {
		return err
	}

	if fromAcc.Currency != transfer.Currency {
		return fmt.Errorf("from account currency mismatch")
	}

	if toAcc.Currency != transfer.Currency {
		return fmt.Errorf("to account currency mismatch")
	}

	err = s.multiLedgerService.ApplyAmount(transfer.FromAccountID, -transfer.Amount)
	if err != nil {
		return err
	}

	err = s.multiLedgerService.ApplyAmount(transfer.ToAccountID, transfer.Amount)
	if err != nil {
		return err
	}

	return nil
}
