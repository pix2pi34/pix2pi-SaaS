package service

import (
	"fmt"
	"sort"
	"time"

	financedomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/finance/domain"
)

type CommissionRuleService struct {
	rules []financedomain.CommissionRule
}

func NewCommissionRuleService() *CommissionRuleService {
	s := &CommissionRuleService{
		rules: make([]financedomain.CommissionRule, 0),
	}

	s.seedRules()

	return s
}

func (s *CommissionRuleService) seedRules() {
	validFrom2025 := time.Date(2025, 1, 1, 0, 0, 0, 0, time.UTC)
	validTo2025 := time.Date(2025, 12, 31, 23, 59, 59, 0, time.UTC)

	validFrom2026 := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	validTo2026 := time.Date(2099, 12, 31, 23, 59, 59, 0, time.UTC)

	s.rules = append(s.rules,
		financedomain.CommissionRule{
			RuleID:         "STANDARD_POS",
			Version:        1,
			MerchantType:   "standard",
			Channel:        "pos",
			CommissionRate: 10,
			ValidFrom:      validFrom2025,
			ValidTo:        validTo2025,
			Active:         true,
		},
		financedomain.CommissionRule{
			RuleID:         "STANDARD_POS",
			Version:        2,
			MerchantType:   "standard",
			Channel:        "pos",
			CommissionRate: 8,
			ValidFrom:      validFrom2026,
			ValidTo:        validTo2026,
			Active:         true,
		},
		financedomain.CommissionRule{
			RuleID:         "PREMIUM_POS",
			Version:        1,
			MerchantType:   "premium",
			Channel:        "pos",
			CommissionRate: 5,
			ValidFrom:      validFrom2025,
			ValidTo:        validTo2026,
			Active:         true,
		},
	)
}

func (s *CommissionRuleService) FindRule(
	query financedomain.CommissionRuleQuery,
) (financedomain.CommissionRule, error) {
	candidates := make([]financedomain.CommissionRule, 0)

	for _, rule := range s.rules {
		if !rule.Active {
			continue
		}

		if rule.MerchantType != query.MerchantType {
			continue
		}

		if rule.Channel != query.Channel {
			continue
		}

		if query.At.Before(rule.ValidFrom) || query.At.After(rule.ValidTo) {
			continue
		}

		candidates = append(candidates, rule)
	}

	if len(candidates) == 0 {
		return financedomain.CommissionRule{}, fmt.Errorf(
			"commission rule not found: merchant_type=%s channel=%s at=%s",
			query.MerchantType,
			query.Channel,
			query.At.Format("2006-01-02"),
		)
	}

	sort.Slice(candidates, func(i, j int) bool {
		return candidates[i].Version > candidates[j].Version
	})

	return candidates[0], nil
}
