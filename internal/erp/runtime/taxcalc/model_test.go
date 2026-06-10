package taxcalc

import (
	"errors"
	"testing"
	"time"
)

func validTaxCalculationRequest() TaxCalculationRequest {
	return TaxCalculationRequest{
		Tenant: TenantContext{
			TenantID:  "tenant_7",
			RequestID: "req-123",
			ActorID:   "user-1",
			ActorType: "user",
		},
		Source: SourceDocumentRef{
			SourceModule:       "sales",
			SourceDocumentType: "invoice",
			SourceDocumentID:   "invoice-id-1",
			SourceDocumentNo:   "INV-000001",
		},
		Fiscal: FiscalContext{
			FiscalYear:      2026,
			FiscalPeriod:    "2026-04",
			CalculationDate: time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC),
		},
		TransactionType: TransactionTypeSale,
		TaxCode: TaxCodeSnapshot{
			TaxCodeID: "tax-code-1",
			Code:      "KDV20",
			Name:      "KDV %20",
			Rate:      20,
			IsActive:  true,
		},
		Money: MoneyInput{
			BaseAmount:   100,
			CurrencyCode: "TRY",
			ExchangeRate: 1,
		},
		Description: "KDV calculation test",
		Metadata: map[string]string{
			"source": "faz3_10_7a_test",
		},
	}
}

func TestValidateTaxCalculationRequestSuccess(t *testing.T) {
	req := validTaxCalculationRequest()

	if err := ValidateTaxCalculationRequest(req); err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateTaxCalculationRequestTenantRequired(t *testing.T) {
	req := validTaxCalculationRequest()
	req.Tenant.TenantID = ""

	err := ValidateTaxCalculationRequest(req)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateTaxCalculationRequestSourceRequired(t *testing.T) {
	req := validTaxCalculationRequest()
	req.Source.SourceDocumentID = ""
	req.Source.SourceDocumentNo = ""

	err := ValidateTaxCalculationRequest(req)
	if !errors.Is(err, ErrSourceDocumentRequired) {
		t.Fatalf("expected ErrSourceDocumentRequired, got %v", err)
	}
}

func TestValidateTaxCalculationRequestFiscalYearInvalid(t *testing.T) {
	req := validTaxCalculationRequest()
	req.Fiscal.FiscalYear = 1999

	err := ValidateTaxCalculationRequest(req)
	if !errors.Is(err, ErrFiscalYearInvalid) {
		t.Fatalf("expected ErrFiscalYearInvalid, got %v", err)
	}
}

func TestValidateTaxCalculationRequestTransactionTypeInvalid(t *testing.T) {
	req := validTaxCalculationRequest()
	req.TransactionType = TransactionType("wrong")

	err := ValidateTaxCalculationRequest(req)
	if !errors.Is(err, ErrTransactionTypeInvalid) {
		t.Fatalf("expected ErrTransactionTypeInvalid, got %v", err)
	}
}

func TestValidateTaxCalculationRequestTaxCodeRequired(t *testing.T) {
	req := validTaxCalculationRequest()
	req.TaxCode.Code = ""

	err := ValidateTaxCalculationRequest(req)
	if !errors.Is(err, ErrTaxCodeRequired) {
		t.Fatalf("expected ErrTaxCodeRequired, got %v", err)
	}
}

func TestValidateTaxCalculationRequestTaxCodeInactive(t *testing.T) {
	req := validTaxCalculationRequest()
	req.TaxCode.IsActive = false

	err := ValidateTaxCalculationRequest(req)
	if !errors.Is(err, ErrTaxCodeInactive) {
		t.Fatalf("expected ErrTaxCodeInactive, got %v", err)
	}
}

func TestValidateTaxCalculationRequestTaxRateInvalid(t *testing.T) {
	req := validTaxCalculationRequest()
	req.TaxCode.Rate = 101

	err := ValidateTaxCalculationRequest(req)
	if !errors.Is(err, ErrTaxRateInvalid) {
		t.Fatalf("expected ErrTaxRateInvalid, got %v", err)
	}
}

func TestValidateTaxCalculationRequestBaseAmountInvalid(t *testing.T) {
	req := validTaxCalculationRequest()
	req.Money.BaseAmount = 0

	err := ValidateTaxCalculationRequest(req)
	if !errors.Is(err, ErrBaseAmountInvalid) {
		t.Fatalf("expected ErrBaseAmountInvalid, got %v", err)
	}
}

func TestValidateTaxCalculationRequestCurrencyRequired(t *testing.T) {
	req := validTaxCalculationRequest()
	req.Money.CurrencyCode = ""

	err := ValidateTaxCalculationRequest(req)
	if !errors.Is(err, ErrCurrencyRequired) {
		t.Fatalf("expected ErrCurrencyRequired, got %v", err)
	}
}

func TestValidateTaxCalculationRequestWithholdingRatioInvalid(t *testing.T) {
	req := validTaxCalculationRequest()
	req.TaxCode.IsWithholding = true
	req.TaxCode.WithholdingNumerator = 9
	req.TaxCode.WithholdingDenominator = 5

	err := ValidateTaxCalculationRequest(req)
	if !errors.Is(err, ErrWithholdingRatioInvalid) {
		t.Fatalf("expected ErrWithholdingRatioInvalid, got %v", err)
	}
}

func TestBuildTaxLineNormalKDV(t *testing.T) {
	req := validTaxCalculationRequest()

	line, err := BuildTaxLine(req)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if line.BaseAmount != 100 {
		t.Fatalf("expected base amount 100, got %v", line.BaseAmount)
	}

	if line.TaxAmount != 20 {
		t.Fatalf("expected tax amount 20, got %v", line.TaxAmount)
	}

	if line.WithholdingAmount != 0 {
		t.Fatalf("expected withholding 0, got %v", line.WithholdingAmount)
	}

	if line.NetTaxAmount != 20 {
		t.Fatalf("expected net tax 20, got %v", line.NetTaxAmount)
	}

	if line.GrossAmount != 120 {
		t.Fatalf("expected gross 120, got %v", line.GrossAmount)
	}

	if line.PayableAmount != 120 {
		t.Fatalf("expected payable 120, got %v", line.PayableAmount)
	}
}

func TestBuildTaxLineWithholdingKDV(t *testing.T) {
	req := validTaxCalculationRequest()
	req.TaxCode.IsWithholding = true
	req.TaxCode.WithholdingNumerator = 5
	req.TaxCode.WithholdingDenominator = 10

	line, err := BuildTaxLine(req)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if line.TaxAmount != 20 {
		t.Fatalf("expected tax 20, got %v", line.TaxAmount)
	}

	if line.WithholdingAmount != 10 {
		t.Fatalf("expected withholding 10, got %v", line.WithholdingAmount)
	}

	if line.NetTaxAmount != 10 {
		t.Fatalf("expected net tax 10, got %v", line.NetTaxAmount)
	}

	if line.GrossAmount != 120 {
		t.Fatalf("expected gross 120, got %v", line.GrossAmount)
	}

	if line.PayableAmount != 110 {
		t.Fatalf("expected payable 110, got %v", line.PayableAmount)
	}
}

func TestBuildTaxLineExempt(t *testing.T) {
	req := validTaxCalculationRequest()
	req.TaxCode.IsExempt = true
	req.TaxCode.Rate = 20

	line, err := BuildTaxLine(req)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if line.TaxAmount != 0 {
		t.Fatalf("expected tax 0, got %v", line.TaxAmount)
	}

	if line.GrossAmount != 100 {
		t.Fatalf("expected gross 100, got %v", line.GrossAmount)
	}

	if line.PayableAmount != 100 {
		t.Fatalf("expected payable 100, got %v", line.PayableAmount)
	}
}

func TestBuildTaxCalculationDraftSuccess(t *testing.T) {
	req := validTaxCalculationRequest()

	draft, err := BuildTaxCalculationDraft(req)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if draft.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", draft.TenantID)
	}

	if draft.Status != TaxCalculationStatusDraft {
		t.Fatalf("expected draft status, got %s", draft.Status)
	}

	if len(draft.Lines) != 1 {
		t.Fatalf("expected 1 line, got %d", len(draft.Lines))
	}

	if draft.TotalTaxAmount != 20 {
		t.Fatalf("expected total tax 20, got %v", draft.TotalTaxAmount)
	}
}

func TestValidateTaxCalculationDraftSuccess(t *testing.T) {
	req := validTaxCalculationRequest()

	draft, err := BuildTaxCalculationDraft(req)
	if err != nil {
		t.Fatalf("expected draft success, got %v", err)
	}

	if err := ValidateTaxCalculationDraft(draft); err != nil {
		t.Fatalf("expected validate success, got %v", err)
	}
}

func TestBuildTaxCalculationResultSuccess(t *testing.T) {
	req := validTaxCalculationRequest()

	draft, err := BuildTaxCalculationDraft(req)
	if err != nil {
		t.Fatalf("expected draft success, got %v", err)
	}

	draft.Status = TaxCalculationStatusPosted
	draft.Lines[0].Status = TaxCalculationStatusPosted

	result, err := BuildTaxCalculationResult(req, draft, "tax calculated")
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}

	if result.TenantID != req.Tenant.TenantID {
		t.Fatalf("expected tenant %s, got %s", req.Tenant.TenantID, result.TenantID)
	}

	if result.RequestID != req.Tenant.RequestID {
		t.Fatalf("expected request_id %s, got %s", req.Tenant.RequestID, result.RequestID)
	}

	if result.Status != TaxCalculationStatusPosted {
		t.Fatalf("expected posted status, got %s", result.Status)
	}

	if result.TotalTaxAmount != 20 {
		t.Fatalf("expected total tax 20, got %v", result.TotalTaxAmount)
	}

	if result.CalculatedAt.IsZero() {
		t.Fatal("expected calculated_at")
	}
}

func TestBuildTaxCalculationResultStatusInvalid(t *testing.T) {
	req := validTaxCalculationRequest()

	draft, err := BuildTaxCalculationDraft(req)
	if err != nil {
		t.Fatalf("expected draft success, got %v", err)
	}

	_, err = BuildTaxCalculationResult(req, draft, "tax calculated")
	if !errors.Is(err, ErrTaxCalculationStatusInvalid) {
		t.Fatalf("expected ErrTaxCalculationStatusInvalid, got %v", err)
	}
}
