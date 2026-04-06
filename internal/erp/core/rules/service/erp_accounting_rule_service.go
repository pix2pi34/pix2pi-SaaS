package service

import (
	"fmt"

	ruledomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/rules/domain"
)

type AccountingRuleService struct {
	rules []ruledomain.AccountingRule
}

func NewAccountingRuleService() *AccountingRuleService {
	s := &AccountingRuleService{
		rules: make([]ruledomain.AccountingRule, 0),
	}

	s.seedRules()

	return s
}

func (s *AccountingRuleService) seedRules() {
	s.rules = append(s.rules,
		ruledomain.AccountingRule{
			RuleID:         "SALE_POS_V1",
			EventType:      "sale.completed",
			PaymentMethod:  "pos",
			TaxRate:        20,
			Version:        1,
			Active:         true,
			SourceModule:   "POS",
			DebitAccount:   "108.01",
			RevenueAccount: "600.01.001",
			TaxAccount:     "391.01.20",
		},
		ruledomain.AccountingRule{
			RuleID:         "SALE_CASH_V1",
			EventType:      "sale.completed",
			PaymentMethod:  "cash",
			TaxRate:        20,
			Version:        1,
			Active:         true,
			SourceModule:   "POS",
			DebitAccount:   "100.01",
			RevenueAccount: "600.01.001",
			TaxAccount:     "391.01.20",
		},
		ruledomain.AccountingRule{
			RuleID:         "SALE_BANK_V1",
			EventType:      "sale.completed",
			PaymentMethod:  "bank",
			TaxRate:        20,
			Version:        1,
			Active:         true,
			SourceModule:   "POS",
			DebitAccount:   "102.01",
			RevenueAccount: "600.01.001",
			TaxAccount:     "391.01.20",
		},
	)
}

func (s *AccountingRuleService) FindRule(
	query ruledomain.AccountingRuleQuery,
) (ruledomain.AccountingRule, error) {
	for _, rule := range s.rules {
		if !rule.Active {
			continue
		}

		if rule.EventType == query.EventType &&
			rule.PaymentMethod == query.PaymentMethod &&
			rule.TaxRate == query.TaxRate {
			return rule, nil
		}
	}

	return ruledomain.AccountingRule{}, fmt.Errorf(
		"accounting rule not found: event=%s payment=%s tax=%d",
		query.EventType,
		query.PaymentMethod,
		query.TaxRate,
	)
}
