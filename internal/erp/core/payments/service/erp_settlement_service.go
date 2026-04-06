package service

import (
	"fmt"
	"strings"
	"time"

	ledgerservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/service"
	paymentsdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/payments/domain"
)

type SettlementService struct {
	multiLedgerService *ledgerservice.MultiLedgerService
}

func NewSettlementService(
	multiLedgerService *ledgerservice.MultiLedgerService,
) *SettlementService {
	return &SettlementService{
		multiLedgerService: multiLedgerService,
	}
}

func (s *SettlementService) PrepareBatch(
	batchID string,
	currency string,
) (paymentsdomain.SettlementBatch, error) {
	if batchID == "" {
		return paymentsdomain.SettlementBatch{}, fmt.Errorf("batch id cannot be empty")
	}

	if currency == "" {
		return paymentsdomain.SettlementBatch{}, fmt.Errorf("currency cannot be empty")
	}

	accounts := s.multiLedgerService.ListAccounts()
	items := make([]paymentsdomain.SettlementItem, 0)
	var totalAmount float64

	itemCounter := 1

	for _, acc := range accounts {
		if acc.AccountType != "payout" {
			continue
		}

		if acc.Currency != currency {
			continue
		}

		if acc.Balance <= 0 {
			continue
		}

		merchantAccountID := s.resolveMerchantAccountID(acc.AccountID)

		item := paymentsdomain.SettlementItem{
			ItemID:            fmt.Sprintf("%s-item-%03d", batchID, itemCounter),
			MerchantAccountID: merchantAccountID,
			PayoutAccountID:   acc.AccountID,
			Amount:            acc.Balance,
			Currency:          acc.Currency,
		}

		items = append(items, item)
		totalAmount += acc.Balance
		itemCounter++
	}

	return paymentsdomain.SettlementBatch{
		BatchID:     batchID,
		Status:      paymentsdomain.SettlementStatusPrepared,
		Currency:    currency,
		Items:       items,
		TotalAmount: totalAmount,
		CreatedAt:   time.Now(),
		PreparedAt:  time.Now(),
	}, nil
}

func (s *SettlementService) resolveMerchantAccountID(payoutAccountID string) string {
	if strings.HasPrefix(payoutAccountID, "payout.") {
		return strings.TrimPrefix(payoutAccountID, "payout.")
	}
	return payoutAccountID
}
