package withholding

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:      true,
		ActiveRuleVersion:   "TR_STOPAJ_2026_V1",
		DefaultCurrencyCode: "TRY",
		MaxRateBps:          4000,
		MinRateBps:          0,
		AuditRequired:       true,
		IdempotencyRequired: true,
		AllowedDocumentTypes: []DocumentType{
			DocumentTypePurchaseInvoice,
			DocumentTypeExpenseVoucher,
			DocumentTypeSelfEmployment,
			DocumentTypeRentAccrual,
			DocumentTypeCustom,
		},
		AllowedSubjects: []WithholdingSubject{
			SubjectRent,
			SubjectProfessionalService,
			SubjectSelfEmployment,
			SubjectFreelance,
			SubjectConstruction,
			SubjectDividend,
			SubjectCustom,
		},
	}
}

func validRules() []WithholdingRule {
	effectiveFrom := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)

	return []WithholdingRule{
		{
			RuleID:             "STOPAJ-RENT-2026",
			RuleVersion:        "TR_STOPAJ_2026_V1",
			Subject:            SubjectRent,
			RateBps:            2000,
			EffectiveFrom:      effectiveFrom,
			MinBaseAmountKurus: 1,
			AccountCode:        "360.01",
			DeclarationCode:    "STOPAJ_RENT",
			Active:             true,
			ExemptionAllowed:   true,
		},
		{
			RuleID:             "STOPAJ-PROF-2026",
			RuleVersion:        "TR_STOPAJ_2026_V1",
			Subject:            SubjectProfessionalService,
			RateBps:            2000,
			EffectiveFrom:      effectiveFrom,
			MinBaseAmountKurus: 50000,
			AccountCode:        "360.02",
			DeclarationCode:    "STOPAJ_PROFESSIONAL_SERVICE",
			Active:             true,
			ExemptionAllowed:   false,
		},
	}
}

func validRequest() WithholdingRequest {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return WithholdingRequest{
		TenantID:           "tenant-001",
		CorrelationID:      "corr-001",
		RequestID:          "req-001",
		IdempotencyKey:     "idem-001",
		DocumentType:       DocumentTypeRentAccrual,
		DocumentID:         "doc-001",
		DocumentNo:         "RENT-001",
		PartyID:            "party-001",
		PartyTitle:         "Test Mal Sahibi",
		PartyTaxNo:         "1234567890",
		Subject:            SubjectRent,
		GrossAmountKurus:   1000000,
		TaxBaseAmountKurus: 1000000,
		CurrencyCode:       "TRY",
		DocumentDate:       now,
		RequestedAt:        now,
	}
}

func TestExecuteAppliesRentWithholding(t *testing.T) {
	runtime, err := NewStopajRuntime(validConfig(), validRules())
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
		t.Fatalf("expected calculation ok, got %s", result.CalculationStatus)
	}
	if result.WithholdingAmountKurus != 200000 {
		t.Fatalf("expected withholding 200000, got %d", result.WithholdingAmountKurus)
	}
	if result.NetPayableAmountKurus != 800000 {
		t.Fatalf("expected net payable 800000, got %d", result.NetPayableAmountKurus)
	}
	if result.RuleVersion != "TR_STOPAJ_2026_V1" {
		t.Fatalf("expected active rule version, got %s", result.RuleVersion)
	}
}

func TestExecuteNotAppliedBelowMinimumBase(t *testing.T) {
	runtime, err := NewStopajRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.DocumentType = DocumentTypePurchaseInvoice
	req.Subject = SubjectProfessionalService
	req.GrossAmountKurus = 40000
	req.TaxBaseAmountKurus = 40000

	result, err := runtime.Execute(req)
	if err != nil {
		t.Fatalf("execute failed: %v", err)
	}

	if result.DecisionStatus != DecisionNotApplied {
		t.Fatalf("expected not applied, got %s", result.DecisionStatus)
	}
	if result.CalculationStatus != CalculationExempt {
		t.Fatalf("expected exempt, got %s", result.CalculationStatus)
	}
	if result.WithholdingAmountKurus != 0 {
		t.Fatalf("expected zero withholding, got %d", result.WithholdingAmountKurus)
	}
}

func TestExecuteAppliesExemptionWhenAllowed(t *testing.T) {
	runtime, err := NewStopajRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.ExemptionCode = "STOPAJ_EXEMPTION_TEST"
	req.ExemptionReason = "Test istisna"

	result, err := runtime.Execute(req)
	if err != nil {
		t.Fatalf("execute failed: %v", err)
	}

	if result.DecisionStatus != DecisionNotApplied {
		t.Fatalf("expected not applied due exemption, got %s", result.DecisionStatus)
	}
	if result.CalculationStatus != CalculationExempt {
		t.Fatalf("expected exempt, got %s", result.CalculationStatus)
	}
}

func TestExecuteRejectsExemptionWhenNotAllowed(t *testing.T) {
	runtime, err := NewStopajRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.DocumentType = DocumentTypePurchaseInvoice
	req.Subject = SubjectProfessionalService
	req.ExemptionCode = "NOT_ALLOWED"
	req.ExemptionReason = "Test"

	result, err := runtime.Execute(req)
	if err == nil {
		t.Fatal("expected exemption not allowed error")
	}
	if result.ErrorCode != "EXEMPTION_NOT_ALLOWED" {
		t.Fatalf("expected EXEMPTION_NOT_ALLOWED, got %s", result.ErrorCode)
	}
}

func TestExecuteRejectsRuleNotEffective(t *testing.T) {
	runtime, err := NewStopajRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.DocumentDate = time.Date(2025, 12, 31, 0, 0, 0, 0, time.UTC)

	result, err := runtime.Execute(req)
	if err == nil {
		t.Fatal("expected rule not effective error")
	}
	if result.ErrorCode != "WITHHOLDING_RULE_NOT_EFFECTIVE" {
		t.Fatalf("expected WITHHOLDING_RULE_NOT_EFFECTIVE, got %s", result.ErrorCode)
	}
}

func TestExecuteRejectsInvalidRequest(t *testing.T) {
	runtime, err := NewStopajRuntime(validConfig(), validRules())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.TenantID = ""

	result, err := runtime.Execute(req)
	if err == nil {
		t.Fatal("expected tenant validation error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	if _, err := NewStopajRuntime(cfg, validRules()); err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsOutOfRangeRate(t *testing.T) {
	rules := validRules()
	rules[0].RateBps = 5000

	if _, err := NewStopajRuntime(validConfig(), rules); err == nil {
		t.Fatal("expected rate out of range error")
	}
}
