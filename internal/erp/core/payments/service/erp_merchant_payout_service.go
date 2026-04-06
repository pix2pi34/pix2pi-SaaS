package service

import (
	"fmt"
	"time"

	ledgerdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/domain"
	ledgerservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/service"
	paymentsdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/payments/domain"
)

type MerchantPayoutService struct {
	multiLedgerService   *ledgerservice.MultiLedgerService
	walletTransferService *ledgerservice.WalletTransferService
}

func NewMerchantPayoutService(
	multiLedgerService *ledgerservice.MultiLedgerService,
	walletTransferService *ledgerservice.WalletTransferService,
) *MerchantPayoutService {
	return &MerchantPayoutService{
		multiLedgerService:    multiLedgerService,
		walletTransferService: walletTransferService,
	}
}

func (s *MerchantPayoutService) CreatePayoutRequest(
	payoutID string,
	merchantAccountID string,
	payoutAccountID string,
	amount float64,
	currency string,
	description string,
) (paymentsdomain.MerchantPayout, error) {
	if payoutID == "" {
		return paymentsdomain.MerchantPayout{}, fmt.Errorf("payout id cannot be empty")
	}

	if merchantAccountID == "" {
		return paymentsdomain.MerchantPayout{}, fmt.Errorf("merchant account id cannot be empty")
	}

	if payoutAccountID == "" {
		return paymentsdomain.MerchantPayout{}, fmt.Errorf("payout account id cannot be empty")
	}

	if amount <= 0 {
		return paymentsdomain.MerchantPayout{}, fmt.Errorf("amount must be greater than zero")
	}

	acc, err := s.multiLedgerService.GetAccount(merchantAccountID)
	if err != nil {
		return paymentsdomain.MerchantPayout{}, err
	}

	if acc.Currency != currency {
		return paymentsdomain.MerchantPayout{}, fmt.Errorf("currency mismatch")
	}

	if acc.Balance < amount {
		return paymentsdomain.MerchantPayout{}, fmt.Errorf(
			"insufficient merchant balance: balance=%.2f requested=%.2f",
			acc.Balance,
			amount,
		)
	}

	return paymentsdomain.MerchantPayout{
		PayoutID:          payoutID,
		MerchantAccountID: merchantAccountID,
		PayoutAccountID:   payoutAccountID,
		Amount:            amount,
		Currency:          currency,
		Status:            paymentsdomain.PayoutStatusPending,
		Description:       description,
		RequestedAt:       time.Now(),
	}, nil
}

func (s *MerchantPayoutService) ApprovePayout(
	payout paymentsdomain.MerchantPayout,
) (paymentsdomain.MerchantPayout, error) {
	if payout.Status != paymentsdomain.PayoutStatusPending {
		return paymentsdomain.MerchantPayout{}, fmt.Errorf("only pending payout can be approved")
	}

	err := s.walletTransferService.Transfer(
		ledgerdomain.WalletTransfer{
			TransferID:    "payout-transfer-" + payout.PayoutID,
			FromAccountID: payout.MerchantAccountID,
			ToAccountID:   payout.PayoutAccountID,
			Amount:        payout.Amount,
			Currency:      payout.Currency,
			Description:   payout.Description,
		},
	)
	if err != nil {
		return paymentsdomain.MerchantPayout{}, err
	}

	payout.Status = paymentsdomain.PayoutStatusApproved
	payout.ApprovedAt = time.Now()

	return payout, nil
}
