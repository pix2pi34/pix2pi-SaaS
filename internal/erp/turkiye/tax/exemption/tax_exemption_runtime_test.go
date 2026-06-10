package exemption

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:      true,
		ActiveRuleVersion:   "TR_TAX_EXEMPTION_2026_V1",
		DefaultCurrencyCode: "TRY",
		AuditRequired:       true,
		IdempotencyRequired: true,
		MinOverrideRateBps:  0,
		MaxOverrideRateBps:  2000,
		AllowedDocumentTypes: []DocumentType{
			DocumentTypeSalesInvoice,
			DocumentTypePurchaseInvoice,
			DocumentTypeEBelgeDocument,
			DocumentTypeExpenseVoucher,
			DocumentTypeJournalDocument,
			DocumentTypeCustom,
		},
		AllowedTaxTypes: []TaxType{
			TaxTypeKDV,
			TaxTypeStopaj,
			TaxTypeOTV,
			TaxTypeDamga,
			TaxTypeCustom,
		},
	}
}

func validRules() []ExemptionRule {
	effectiveFrom := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)

	return []ExemptionRule{
		{
			RuleID:             "KDV-FULL-EXPORT-2026",
			RuleVersion:        "TR_TAX_EXEMPTION_2026_V1",
			TaxType:            TaxTypeKDV,
			ExemptionCode:      "KDV_EXPORT_FULL",
			ExemptionScope:     ScopeFullExemption,
			EffectiveFrom:      effectiveFrom,
			MinBaseAmountKurus: 1,
			AccountCode:        "391.00",
			DeclarationCode:    "KDV_EXPORT_EXEMPTION",
			LegalReference:     "KDV istisna test referansi",
			ReasonRequired:     true,
			Active:             true,
		},
		{
			RuleID:             "KDV-PARTIAL-2026",
			RuleVersion:        "TR_TAX_EXEMPTION_2026_V1",
			TaxType:            TaxTypeKDV,
			ExemptionCode:      "KDV_PARTIAL_50",
			ExemptionScope:     ScopePartialExemption,
			EffectiveFrom:      effectiveFrom,
			MinBaseAmountKurus: 1,
			ExemptRateBps:      5000,
			AccountCode:        "391.01",
			DeclarationCode:    "KDV_PARTIAL_EXEMPTION",
			LegalReference:     "KDV kismi istisna test referansi",
			ReasonRequired:     false,
			Active:             true,
		},
		{
			RuleID:             "KDV-RATE-OVERRIDE-2026",
			RuleVersion:        "TR_TAX_EXEMPTION_2026_V1",
			TaxType:            TaxTypeKDV,
			ExemptionCode:      "KDV_RATE_10",
			ExemptionScope:     ScopeRateOverride,
			EffectiveFrom:      effectiveFrom,
			MinBaseAmountKurus: 1,
			OverrideRateBps:    1000,
			AccountCode:        "391.10",
			DeclarationCode:    "KDV_RATE_OVERRIDE",
			LegalReference:     "KDV oran override test referansi",
			ReasonRequired:     false,
			Active:             true,
		},
	}
}

func validRequest() ExemptionRequest {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return ExemptionRequest{
		TenantID:               "tenant-001",
		CorrelationID:          "corr-001",
		RequestID:              "req-001",
		IdempotencyKey:         "idem-001",
		DocumentType:           DocumentTypeSalesInvoice,
		DocumentID:             "doc-001",
		DocumentNo:             "INV-001",
		PartyID:                "party-001",
		PartyTitle:             "Test Musteri A.S.",
		PartyTaxNo:             "1234567890",
		TaxType:                TaxTypeKDV,
		ExemptionCode:          "KDV_EXPORT_FULL",
		ExemptionReason:        "Ihracat istisnasi",
		GrossAmountKurus:       1000000,
		TaxBaseAmountKurus:     1000000,
		OriginalTaxRateBps:     2000,
		OriginalTaxAmountKurus: 200000,
		CurrencyCode:           "TRY",
		DocumentDate:           now,
		RequestedAt:            now,
	}
}

func TestExecuteAppliesFullExemption(t *testing.T) {
	runtime, err := NewTaxExemptionRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.Execute(validRequest())
	if err != nil {
		t.Fatalf("execute failed: %v", err)
	}

	if result.DecisionStatus != DecisionApplied {
		t.Fatalf("expected applied, got %s", result.DecisionStatus)
	}
	if result.CalculationStatus != CalculationOK {
		t.Fatalf("expected OK, got %s", result.CalculationStatus)
	}
	if result.EffectiveTaxRateBps != 0 {
		t.Fatalf("expected effective rate 0, got %d", result.EffectiveTaxRateBps)
	}
	if result.EffectiveTaxAmountKurus != 0 {
		t.Fatalf("expected effective tax 0, got %d", result.EffectiveTaxAmountKurus)
	}
	if result.ExemptedTaxAmountKurus != 200000 {
		t.Fatalf("expected exempted 200000, got %d", result.ExemptedTaxAmountKurus)
	}
}

func TestExecuteAppliesPartialExemption(t *testing.T) {
	runtime, err := NewTaxExemptionRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.ExemptionCode = "KDV_PARTIAL_50"
	req.ExemptionReason = ""

	result, err := runtime.Execute(req)
	if err != nil {
		t.Fatalf("execute failed: %v", err)
	}

	if result.DecisionStatus != DecisionApplied {
		t.Fatalf("expected applied, got %s", result.DecisionStatus)
	}
	if result.EffectiveTaxAmountKurus != 100000 {
		t.Fatalf("expected effective tax 100000, got %d", result.EffectiveTaxAmountKurus)
	}
	if result.ExemptedTaxAmountKurus != 100000 {
		t.Fatalf("expected exempted tax 100000, got %d", result.ExemptedTaxAmountKurus)
	}
}

func TestExecuteAppliesRateOverride(t *testing.T) {
	runtime, err := NewTaxExemptionRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.ExemptionCode = "KDV_RATE_10"
	req.ExemptionReason = ""

	result, err := runtime.Execute(req)
	if err != nil {
		t.Fatalf("execute failed: %v", err)
	}

	if result.EffectiveTaxRateBps != 1000 {
		t.Fatalf("expected override rate 1000, got %d", result.EffectiveTaxRateBps)
	}
	if result.EffectiveTaxAmountKurus != 100000 {
		t.Fatalf("expected effective tax 100000, got %d", result.EffectiveTaxAmountKurus)
	}
}

func TestExecuteRejectsMissingReasonWhenRequired(t *testing.T) {
	runtime, err := NewTaxExemptionRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.ExemptionReason = ""

	result, err := runtime.Execute(req)
	if err == nil {
		t.Fatal("expected exemption reason error")
	}
	if result.ErrorCode != "EXEMPTION_REASON_REQUIRED" {
		t.Fatalf("expected EXEMPTION_REASON_REQUIRED, got %s", result.ErrorCode)
	}
}

func TestExecuteRejectsRuleMissing(t *testing.T) {
	runtime, err := NewTaxExemptionRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.ExemptionCode = "UNKNOWN"

	result, err := runtime.Execute(req)
	if err == nil {
		t.Fatal("expected rule missing error")
	}
	if result.ErrorCode != "EXEMPTION_RULE_MISSING" {
		t.Fatalf("expected EXEMPTION_RULE_MISSING, got %s", result.ErrorCode)
	}
	if result.CalculationStatus != CalculationRuleMissing {
		t.Fatalf("expected rule missing calculation, got %s", result.CalculationStatus)
	}
}

func TestExecuteRejectsRuleNotEffective(t *testing.T) {
	runtime, err := NewTaxExemptionRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.DocumentDate = time.Date(2025, 12, 31, 0, 0, 0, 0, time.UTC)

	result, err := runtime.Execute(req)
	if err == nil {
		t.Fatal("expected rule not effective error")
	}
	if result.ErrorCode != "EXEMPTION_RULE_NOT_EFFECTIVE" {
		t.Fatalf("expected EXEMPTION_RULE_NOT_EFFECTIVE, got %s", result.ErrorCode)
	}
}

func TestExecuteRejectsInvalidRequest(t *testing.T) {
	runtime, err := NewTaxExemptionRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.TaxBaseAmountKurus = 2000000

	result, err := runtime.Execute(req)
	if err == nil {
		t.Fatal("expected invalid tax base error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	if _, err := NewTaxExemptionRuntime(cfg, validRules()); err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsOutOfRangeOverrideRate(t *testing.T) {
	rules := validRules()
	rules[2].OverrideRateBps = 3000

	if _, err := NewTaxExemptionRuntime(validConfig(), rules); err == nil {
		t.Fatal("expected override rate range error")
	}
}
