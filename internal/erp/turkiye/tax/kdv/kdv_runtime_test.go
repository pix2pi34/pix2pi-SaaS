package kdv

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:      true,
		ActiveRuleVersion:   "TR_KDV_2026_V1",
		DefaultCurrencyCode: "TRY",
		AuditRequired:       true,
		IdempotencyRequired: true,
		MinRateBps:          0,
		MaxRateBps:          2000,
		AllowedDocumentTypes: []DocumentType{
			DocumentTypeSalesInvoice,
			DocumentTypePurchaseInvoice,
			DocumentTypeSalesReturn,
			DocumentTypePurchaseReturn,
			DocumentTypeEBelgeDocument,
			DocumentTypeCustom,
		},
		AllowedDirections: []TaxDirection{
			DirectionOutput,
			DirectionInput,
			DirectionReturn,
		},
		AllowedRateCodes: []KDVRateCode{
			RateCodeKDV0,
			RateCodeKDV1,
			RateCodeKDV10,
			RateCodeKDV20,
			RateCodeCustom,
		},
	}
}

func validRules() []KDVRule {
	effectiveFrom := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)

	return []KDVRule{
		{
			RuleID:               "KDV-OUTPUT-20-2026",
			RuleVersion:          "TR_KDV_2026_V1",
			RateCode:             RateCodeKDV20,
			RateBps:              2000,
			Direction:            DirectionOutput,
			EffectiveFrom:        effectiveFrom,
			OutputAccountCode:    "391.01.20",
			DeclarationCode:      "KDV_OUTPUT_20",
			ExemptionAllowed:     true,
			ReverseChargeAllowed: false,
			Active:               true,
		},
		{
			RuleID:               "KDV-INPUT-20-2026",
			RuleVersion:          "TR_KDV_2026_V1",
			RateCode:             RateCodeKDV20,
			RateBps:              2000,
			Direction:            DirectionInput,
			EffectiveFrom:        effectiveFrom,
			InputAccountCode:     "191.01.20",
			DeclarationCode:      "KDV_INPUT_20",
			ExemptionAllowed:     false,
			ReverseChargeAllowed: true,
			Active:               true,
		},
		{
			RuleID:               "KDV-OUTPUT-10-2026",
			RuleVersion:          "TR_KDV_2026_V1",
			RateCode:             RateCodeKDV10,
			RateBps:              1000,
			Direction:            DirectionOutput,
			EffectiveFrom:        effectiveFrom,
			OutputAccountCode:    "391.01.10",
			DeclarationCode:      "KDV_OUTPUT_10",
			ExemptionAllowed:     true,
			ReverseChargeAllowed: false,
			Active:               true,
		},
		{
			RuleID:               "KDV-OUTPUT-0-2026",
			RuleVersion:          "TR_KDV_2026_V1",
			RateCode:             RateCodeKDV0,
			RateBps:              0,
			Direction:            DirectionOutput,
			EffectiveFrom:        effectiveFrom,
			OutputAccountCode:    "391.00",
			DeclarationCode:      "KDV_ZERO_RATE",
			ExemptionAllowed:     true,
			ReverseChargeAllowed: false,
			Active:               true,
		},
	}
}

func validRequest() KDVRequest {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return KDVRequest{
		TenantID:           "tenant-001",
		CorrelationID:      "corr-001",
		RequestID:          "req-001",
		IdempotencyKey:     "idem-001",
		DocumentType:       DocumentTypeSalesInvoice,
		DocumentID:         "invoice-001",
		DocumentNo:         "INV-001",
		PartyID:            "party-001",
		PartyTitle:         "Test Musteri A.S.",
		PartyTaxNo:         "1234567890",
		Direction:          DirectionOutput,
		RateCode:           RateCodeKDV20,
		GrossAmountKurus:   1200000,
		NetAmountKurus:     1000000,
		TaxBaseAmountKurus: 1000000,
		CurrencyCode:       "TRY",
		DocumentDate:       now,
		RequestedAt:        now,
	}
}

func TestExecuteAppliesOutputKDV20(t *testing.T) {
	runtime, err := NewKDVRuntime(validConfig(), validRules())
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
		t.Fatalf("expected calculation OK, got %s", result.CalculationStatus)
	}
	if result.KDVAmountKurus != 200000 {
		t.Fatalf("expected kdv 200000, got %d", result.KDVAmountKurus)
	}
	if result.TotalAmountKurus != 1200000 {
		t.Fatalf("expected total 1200000, got %d", result.TotalAmountKurus)
	}
	if result.AccountCode != "391.01.20" {
		t.Fatalf("expected output account 391.01.20, got %s", result.AccountCode)
	}
}

func TestExecuteAppliesInputKDV20ReverseCharge(t *testing.T) {
	runtime, err := NewKDVRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.DocumentType = DocumentTypePurchaseInvoice
	req.Direction = DirectionInput
	req.RateCode = RateCodeKDV20
	req.ReverseCharge = true

	result, err := runtime.Execute(req)
	if err != nil {
		t.Fatalf("execute failed: %v", err)
	}

	if !result.ReverseChargeApplied {
		t.Fatal("expected reverse charge applied")
	}
	if result.AccountCode != "191.01.20" {
		t.Fatalf("expected input account 191.01.20, got %s", result.AccountCode)
	}
}

func TestExecuteAppliesOutputKDV10(t *testing.T) {
	runtime, err := NewKDVRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.RateCode = RateCodeKDV10
	req.GrossAmountKurus = 1100000

	result, err := runtime.Execute(req)
	if err != nil {
		t.Fatalf("execute failed: %v", err)
	}

	if result.KDVAmountKurus != 100000 {
		t.Fatalf("expected kdv 100000, got %d", result.KDVAmountKurus)
	}
	if result.TotalAmountKurus != 1100000 {
		t.Fatalf("expected total 1100000, got %d", result.TotalAmountKurus)
	}
}

func TestExecuteZeroRatedKDV(t *testing.T) {
	runtime, err := NewKDVRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.RateCode = RateCodeKDV0
	req.GrossAmountKurus = 1000000

	result, err := runtime.Execute(req)
	if err != nil {
		t.Fatalf("execute failed: %v", err)
	}

	if result.CalculationStatus != CalculationZeroRated {
		t.Fatalf("expected zero rated, got %s", result.CalculationStatus)
	}
	if result.KDVAmountKurus != 0 {
		t.Fatalf("expected zero kdv, got %d", result.KDVAmountKurus)
	}
}

func TestExecuteExemptionAllowed(t *testing.T) {
	runtime, err := NewKDVRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.ExemptionCode = "KDV_EXPORT_EXEMPTION"
	req.ExemptionReason = "Ihracat istisnasi"

	result, err := runtime.Execute(req)
	if err != nil {
		t.Fatalf("execute failed: %v", err)
	}

	if result.DecisionStatus != DecisionNotApplied {
		t.Fatalf("expected not applied, got %s", result.DecisionStatus)
	}
	if !result.ExemptionApplied {
		t.Fatal("expected exemption applied")
	}
	if result.KDVAmountKurus != 0 {
		t.Fatalf("expected zero KDV with exemption, got %d", result.KDVAmountKurus)
	}
}

func TestExecuteRejectsExemptionWhenNotAllowed(t *testing.T) {
	runtime, err := NewKDVRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.DocumentType = DocumentTypePurchaseInvoice
	req.Direction = DirectionInput
	req.ExemptionCode = "NOT_ALLOWED"
	req.ExemptionReason = "Test"

	result, err := runtime.Execute(req)
	if err == nil {
		t.Fatal("expected exemption not allowed error")
	}
	if result.ErrorCode != "KDV_EXEMPTION_NOT_ALLOWED" {
		t.Fatalf("expected KDV_EXEMPTION_NOT_ALLOWED, got %s", result.ErrorCode)
	}
}

func TestExecuteRejectsReverseChargeWhenNotAllowed(t *testing.T) {
	runtime, err := NewKDVRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.ReverseCharge = true

	result, err := runtime.Execute(req)
	if err == nil {
		t.Fatal("expected reverse charge not allowed error")
	}
	if result.ErrorCode != "KDV_REVERSE_CHARGE_NOT_ALLOWED" {
		t.Fatalf("expected KDV_REVERSE_CHARGE_NOT_ALLOWED, got %s", result.ErrorCode)
	}
}

func TestExecuteRejectsRuleNotEffective(t *testing.T) {
	runtime, err := NewKDVRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.DocumentDate = time.Date(2025, 12, 31, 0, 0, 0, 0, time.UTC)

	result, err := runtime.Execute(req)
	if err == nil {
		t.Fatal("expected rule not effective error")
	}
	if result.ErrorCode != "KDV_RULE_NOT_EFFECTIVE" {
		t.Fatalf("expected KDV_RULE_NOT_EFFECTIVE, got %s", result.ErrorCode)
	}
}

func TestExecuteRejectsInvalidAmount(t *testing.T) {
	runtime, err := NewKDVRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.TaxBaseAmountKurus = 1300000

	result, err := runtime.Execute(req)
	if err == nil {
		t.Fatal("expected invalid amount error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	if _, err := NewKDVRuntime(cfg, validRules()); err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsOutOfRangeRate(t *testing.T) {
	rules := validRules()
	rules[0].RateBps = 2500

	if _, err := NewKDVRuntime(validConfig(), rules); err == nil {
		t.Fatal("expected out of range rate error")
	}
}
