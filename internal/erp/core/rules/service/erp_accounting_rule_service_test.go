package service

import (
	"testing"

	ruledomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/rules/domain"
)

func TestNewAccountingRuleService_SeededRules(t *testing.T) {
	svc := NewAccountingRuleService()

	rules := svc.ListRules()
	if len(rules) != 3 {
		t.Fatalf("expected 3 seeded rules, got %d", len(rules))
	}
}

func TestAccountingRuleService_FindRule_DefaultSeed(t *testing.T) {
	svc := NewAccountingRuleService()

	rule, err := svc.FindRule(ruledomain.AccountingRuleQuery{
		EventType:     "sale.completed",
		PaymentMethod: "cash",
		TaxRate:       20,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if rule.RuleID != "SALE_CASH_V1" {
		t.Fatalf("expected SALE_CASH_V1, got %s", rule.RuleID)
	}
	if rule.DebitAccount != "100.01" {
		t.Fatalf("expected 100.01, got %s", rule.DebitAccount)
	}
}

func TestAccountingRuleService_RegisterRule_DuplicateRuleID(t *testing.T) {
	svc := NewAccountingRuleService()

	err := svc.RegisterRule(ruledomain.AccountingRule{
		RuleID:         "SALE_CASH_V1",
		EventType:      "sale.completed",
		PaymentMethod:  "cash",
		TaxRate:        20,
		Version:        2,
		Active:         true,
		SourceModule:   "POS",
		DebitAccount:   "100.02",
		RevenueAccount: "600.01.001",
		TaxAccount:     "391.01.20",
	})
	if err == nil {
		t.Fatal("expected duplicate rule id error")
	}
}

func TestAccountingRuleService_RegisterRule_DuplicateVersionKey(t *testing.T) {
	svc := NewAccountingRuleService()

	err := svc.RegisterRule(ruledomain.AccountingRule{
		RuleID:         "SALE_CASH_V1_B",
		EventType:      "sale.completed",
		PaymentMethod:  "cash",
		TaxRate:        20,
		Version:        1,
		Active:         true,
		SourceModule:   "POS",
		DebitAccount:   "100.02",
		RevenueAccount: "600.01.001",
		TaxAccount:     "391.01.20",
	})
	if err == nil {
		t.Fatal("expected duplicate version key error")
	}
}

func TestAccountingRuleService_FindRule_HighestActiveVersionWins(t *testing.T) {
	svc := NewAccountingRuleService()

	err := svc.RegisterRule(ruledomain.AccountingRule{
		RuleID:         "SALE_CASH_V2",
		EventType:      "sale.completed",
		PaymentMethod:  "cash",
		TaxRate:        20,
		Version:        2,
		Active:         true,
		SourceModule:   "POS",
		DebitAccount:   "100.09",
		RevenueAccount: "600.01.002",
		TaxAccount:     "391.01.20",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	rule, err := svc.FindRule(ruledomain.AccountingRuleQuery{
		EventType:     "sale.completed",
		PaymentMethod: "cash",
		TaxRate:       20,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if rule.RuleID != "SALE_CASH_V2" {
		t.Fatalf("expected SALE_CASH_V2, got %s", rule.RuleID)
	}
	if rule.Version != 2 {
		t.Fatalf("expected version 2, got %d", rule.Version)
	}
}

func TestAccountingRuleService_FindRule_IgnoresInactiveHigherVersion(t *testing.T) {
	svc := NewAccountingRuleService()

	err := svc.RegisterRule(ruledomain.AccountingRule{
		RuleID:         "SALE_POS_V2",
		EventType:      "sale.completed",
		PaymentMethod:  "pos",
		TaxRate:        20,
		Version:        2,
		Active:         false,
		SourceModule:   "POS",
		DebitAccount:   "108.99",
		RevenueAccount: "600.01.010",
		TaxAccount:     "391.01.20",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	rule, err := svc.FindRule(ruledomain.AccountingRuleQuery{
		EventType:     "sale.completed",
		PaymentMethod: "pos",
		TaxRate:       20,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if rule.RuleID != "SALE_POS_V1" {
		t.Fatalf("expected SALE_POS_V1, got %s", rule.RuleID)
	}
}

func TestAccountingRuleService_FindRule_NotFound(t *testing.T) {
	svc := NewAccountingRuleService()

	_, err := svc.FindRule(ruledomain.AccountingRuleQuery{
		EventType:     "refund.completed",
		PaymentMethod: "cash",
		TaxRate:       20,
	})
	if err == nil {
		t.Fatal("expected not found error")
	}
}

func TestAccountingRuleService_FindRule_NormalizesInput(t *testing.T) {
	svc := NewAccountingRuleService()

	rule, err := svc.FindRule(ruledomain.AccountingRuleQuery{
		EventType:     "SALE.COMPLETED",
		PaymentMethod: "CASH",
		TaxRate:       20,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if rule.RuleID != "SALE_CASH_V1" {
		t.Fatalf("expected SALE_CASH_V1, got %s", rule.RuleID)
	}
}
