package service

import (
	"fmt"
	"sort"
	"strings"

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
	_ = s.RegisterRule(ruledomain.AccountingRule{
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
	})

	_ = s.RegisterRule(ruledomain.AccountingRule{
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
	})

	_ = s.RegisterRule(ruledomain.AccountingRule{
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
	})
}

func (s *AccountingRuleService) RegisterRule(
	rule ruledomain.AccountingRule,
) error {
	if strings.TrimSpace(rule.RuleID) == "" {
		return fmt.Errorf("rule id cannot be empty")
	}
	if strings.TrimSpace(rule.EventType) == "" {
		return fmt.Errorf("event type cannot be empty")
	}
	if strings.TrimSpace(rule.PaymentMethod) == "" {
		return fmt.Errorf("payment method cannot be empty")
	}
	if rule.TaxRate < 0 {
		return fmt.Errorf("tax rate cannot be negative")
	}
	if rule.Version <= 0 {
		return fmt.Errorf("version must be greater than zero")
	}
	if strings.TrimSpace(rule.DebitAccount) == "" {
		return fmt.Errorf("debit account cannot be empty")
	}
	if strings.TrimSpace(rule.RevenueAccount) == "" {
		return fmt.Errorf("revenue account cannot be empty")
	}
	if strings.TrimSpace(rule.TaxAccount) == "" {
		return fmt.Errorf("tax account cannot be empty")
	}

	for _, existing := range s.rules {
		if existing.RuleID == rule.RuleID {
			return fmt.Errorf("duplicate rule id: %s", rule.RuleID)
		}

		if sameRuleKey(existing, rule) && existing.Version == rule.Version {
			return fmt.Errorf(
				"duplicate rule version: event=%s payment=%s tax=%d version=%d",
				rule.EventType,
				rule.PaymentMethod,
				rule.TaxRate,
				rule.Version,
			)
		}
	}

	s.rules = append(s.rules, normalizeRule(rule))
	s.sortRules()

	return nil
}

func (s *AccountingRuleService) FindRule(
	query ruledomain.AccountingRuleQuery,
) (ruledomain.AccountingRule, error) {
	candidates := make([]ruledomain.AccountingRule, 0)

	for _, rule := range s.rules {
		if !rule.Active {
			continue
		}

		if rule.EventType == normalizeEventType(query.EventType) &&
			rule.PaymentMethod == normalizePaymentMethod(query.PaymentMethod) &&
			rule.TaxRate == query.TaxRate {
			candidates = append(candidates, rule)
		}
	}

	if len(candidates) == 0 {
		return ruledomain.AccountingRule{}, fmt.Errorf(
			"accounting rule not found: event=%s payment=%s tax=%d",
			query.EventType,
			query.PaymentMethod,
			query.TaxRate,
		)
	}

	sort.Slice(candidates, func(i, j int) bool {
		if candidates[i].Version == candidates[j].Version {
			return candidates[i].RuleID < candidates[j].RuleID
		}
		return candidates[i].Version > candidates[j].Version
	})

	return candidates[0], nil
}

func (s *AccountingRuleService) ListRules() []ruledomain.AccountingRule {
	result := make([]ruledomain.AccountingRule, 0, len(s.rules))
	result = append(result, s.rules...)
	return result
}

func (s *AccountingRuleService) FindRuleByID(ruleID string) (ruledomain.AccountingRule, bool) {
	for _, rule := range s.rules {
		if rule.RuleID == ruleID {
			return rule, true
		}
	}
	return ruledomain.AccountingRule{}, false
}

func (s *AccountingRuleService) sortRules() {
	sort.Slice(s.rules, func(i, j int) bool {
		if s.rules[i].EventType != s.rules[j].EventType {
			return s.rules[i].EventType < s.rules[j].EventType
		}
		if s.rules[i].PaymentMethod != s.rules[j].PaymentMethod {
			return s.rules[i].PaymentMethod < s.rules[j].PaymentMethod
		}
		if s.rules[i].TaxRate != s.rules[j].TaxRate {
			return s.rules[i].TaxRate < s.rules[j].TaxRate
		}
		if s.rules[i].Version != s.rules[j].Version {
			return s.rules[i].Version > s.rules[j].Version
		}
		return s.rules[i].RuleID < s.rules[j].RuleID
	})
}

func sameRuleKey(a, b ruledomain.AccountingRule) bool {
	return normalizeEventType(a.EventType) == normalizeEventType(b.EventType) &&
		normalizePaymentMethod(a.PaymentMethod) == normalizePaymentMethod(b.PaymentMethod) &&
		a.TaxRate == b.TaxRate
}

func normalizeRule(rule ruledomain.AccountingRule) ruledomain.AccountingRule {
	rule.EventType = normalizeEventType(rule.EventType)
	rule.PaymentMethod = normalizePaymentMethod(rule.PaymentMethod)
	rule.SourceModule = strings.TrimSpace(strings.ToUpper(rule.SourceModule))
	return rule
}

func normalizeEventType(v string) string {
	return strings.TrimSpace(strings.ToLower(v))
}

func normalizePaymentMethod(v string) string {
	return strings.TrimSpace(strings.ToLower(v))
}
