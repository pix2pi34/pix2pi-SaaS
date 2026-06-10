package salesinvoice

import (
	"errors"
	"testing"
	"time"
)

func validSalesInvoiceRequest() SalesInvoiceRequest {
	return SalesInvoiceRequest{
		Tenant: TenantContext{
			TenantID:  "tenant_7",
			RequestID: "req-123",
			ActorID:   "user-1",
			ActorType: "user",
		},
		Fiscal: FiscalContext{
			FiscalYear:   2026,
			FiscalPeriod: "2026-04",
			InvoiceDate:  time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC),
			PostingDate:  time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC),
		},
		InvoiceNo: "INV-2026-000001",
		Customer: CustomerRef{
			CustomerID:   "customer-1",
			CustomerCode: "CARI-001",
			CustomerName: "Test Musteri",
			TaxNo:        "1234567890",
			TaxOffice:    "Istanbul",
		},
		Money: MoneyContext{
			CurrencyCode: "TRY",
			ExchangeRate: 1,
		},
		Lines: []SalesInvoiceLineRequest{
			{
				LineNo: 1,
				Product: ProductRef{
					ProductID:   "product-1",
					ProductCode: "URUN-001",
					ProductName: "Test Urun",
					UnitCode:    "ADET",
				},
				Quantity:       2,
				UnitPrice:      50,
				DiscountAmount: 0,
				TaxCode:        "KDV20",
				TaxRate:        20,
				Description:    "Test urun satiri",
			},
		},
		Description: "Sales invoice test",
		Metadata: map[string]string{
			"source": "faz3_10_8a_test",
		},
	}
}

func TestValidateSalesInvoiceRequestSuccess(t *testing.T) {
	req := validSalesInvoiceRequest()

	if err := ValidateSalesInvoiceRequest(req); err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateSalesInvoiceRequestTenantRequired(t *testing.T) {
	req := validSalesInvoiceRequest()
	req.Tenant.TenantID = ""

	err := ValidateSalesInvoiceRequest(req)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateSalesInvoiceRequestInvoiceNoRequired(t *testing.T) {
	req := validSalesInvoiceRequest()
	req.InvoiceNo = ""

	err := ValidateSalesInvoiceRequest(req)
	if !errors.Is(err, ErrInvoiceNoRequired) {
		t.Fatalf("expected ErrInvoiceNoRequired, got %v", err)
	}
}

func TestValidateSalesInvoiceRequestCustomerRequired(t *testing.T) {
	req := validSalesInvoiceRequest()
	req.Customer = CustomerRef{}

	err := ValidateSalesInvoiceRequest(req)
	if !errors.Is(err, ErrCustomerRequired) {
		t.Fatalf("expected ErrCustomerRequired, got %v", err)
	}
}

func TestValidateSalesInvoiceRequestFiscalYearInvalid(t *testing.T) {
	req := validSalesInvoiceRequest()
	req.Fiscal.FiscalYear = 1999

	err := ValidateSalesInvoiceRequest(req)
	if !errors.Is(err, ErrFiscalYearInvalid) {
		t.Fatalf("expected ErrFiscalYearInvalid, got %v", err)
	}
}

func TestValidateSalesInvoiceRequestCurrencyRequired(t *testing.T) {
	req := validSalesInvoiceRequest()
	req.Money.CurrencyCode = ""

	err := ValidateSalesInvoiceRequest(req)
	if !errors.Is(err, ErrCurrencyRequired) {
		t.Fatalf("expected ErrCurrencyRequired, got %v", err)
	}
}

func TestValidateSalesInvoiceRequestLineCountInvalid(t *testing.T) {
	req := validSalesInvoiceRequest()
	req.Lines = nil

	err := ValidateSalesInvoiceRequest(req)
	if !errors.Is(err, ErrInvoiceLineCountInvalid) {
		t.Fatalf("expected ErrInvoiceLineCountInvalid, got %v", err)
	}
}

func TestValidateSalesInvoiceRequestProductRequired(t *testing.T) {
	req := validSalesInvoiceRequest()
	req.Lines[0].Product = ProductRef{}

	err := ValidateSalesInvoiceRequest(req)
	if !errors.Is(err, ErrProductRequired) {
		t.Fatalf("expected ErrProductRequired, got %v", err)
	}
}

func TestValidateSalesInvoiceRequestQuantityInvalid(t *testing.T) {
	req := validSalesInvoiceRequest()
	req.Lines[0].Quantity = 0

	err := ValidateSalesInvoiceRequest(req)
	if !errors.Is(err, ErrQuantityInvalid) {
		t.Fatalf("expected ErrQuantityInvalid, got %v", err)
	}
}

func TestValidateSalesInvoiceRequestDiscountInvalid(t *testing.T) {
	req := validSalesInvoiceRequest()
	req.Lines[0].DiscountAmount = 999

	err := ValidateSalesInvoiceRequest(req)
	if !errors.Is(err, ErrDiscountInvalid) {
		t.Fatalf("expected ErrDiscountInvalid, got %v", err)
	}
}

func TestValidateSalesInvoiceRequestTaxCodeRequired(t *testing.T) {
	req := validSalesInvoiceRequest()
	req.Lines[0].TaxCode = ""

	err := ValidateSalesInvoiceRequest(req)
	if !errors.Is(err, ErrTaxCodeRequired) {
		t.Fatalf("expected ErrTaxCodeRequired, got %v", err)
	}
}

func TestBuildSalesInvoiceLineDraftSuccess(t *testing.T) {
	req := validSalesInvoiceRequest()

	line, err := BuildSalesInvoiceLineDraft(req.Lines[0], req.Money)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if line.GrossLineAmount != 100 {
		t.Fatalf("expected gross 100, got %v", line.GrossLineAmount)
	}

	if line.TaxableAmount != 100 {
		t.Fatalf("expected taxable 100, got %v", line.TaxableAmount)
	}

	if line.TaxAmount != 20 {
		t.Fatalf("expected tax 20, got %v", line.TaxAmount)
	}

	if line.LineTotalAmount != 120 {
		t.Fatalf("expected line total 120, got %v", line.LineTotalAmount)
	}
}

func TestBuildSalesInvoiceLineDraftWithDiscount(t *testing.T) {
	req := validSalesInvoiceRequest()
	req.Lines[0].DiscountAmount = 10

	line, err := BuildSalesInvoiceLineDraft(req.Lines[0], req.Money)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if line.GrossLineAmount != 100 {
		t.Fatalf("expected gross 100, got %v", line.GrossLineAmount)
	}

	if line.DiscountAmount != 10 {
		t.Fatalf("expected discount 10, got %v", line.DiscountAmount)
	}

	if line.TaxableAmount != 90 {
		t.Fatalf("expected taxable 90, got %v", line.TaxableAmount)
	}

	if line.TaxAmount != 18 {
		t.Fatalf("expected tax 18, got %v", line.TaxAmount)
	}

	if line.LineTotalAmount != 108 {
		t.Fatalf("expected line total 108, got %v", line.LineTotalAmount)
	}
}

func TestBuildSalesInvoiceDraftSuccess(t *testing.T) {
	req := validSalesInvoiceRequest()

	draft, err := BuildSalesInvoiceDraft(req)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if draft.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", draft.TenantID)
	}

	if draft.InvoiceNo != req.InvoiceNo {
		t.Fatalf("expected invoice no %s, got %s", req.InvoiceNo, draft.InvoiceNo)
	}

	if draft.Status != InvoiceStatusDraft {
		t.Fatalf("expected draft status, got %s", draft.Status)
	}

	if len(draft.Lines) != 1 {
		t.Fatalf("expected 1 line, got %d", len(draft.Lines))
	}

	if draft.TotalGrossAmount != 100 {
		t.Fatalf("expected total gross 100, got %v", draft.TotalGrossAmount)
	}

	if draft.TotalTaxAmount != 20 {
		t.Fatalf("expected total tax 20, got %v", draft.TotalTaxAmount)
	}

	if draft.TotalInvoiceAmount != 120 {
		t.Fatalf("expected invoice total 120, got %v", draft.TotalInvoiceAmount)
	}
}

func TestValidateSalesInvoiceDraftSuccess(t *testing.T) {
	req := validSalesInvoiceRequest()

	draft, err := BuildSalesInvoiceDraft(req)
	if err != nil {
		t.Fatalf("expected draft success, got %v", err)
	}

	if err := ValidateSalesInvoiceDraft(draft); err != nil {
		t.Fatalf("expected validate success, got %v", err)
	}
}

func TestBuildSalesInvoiceResultSuccess(t *testing.T) {
	req := validSalesInvoiceRequest()

	draft, err := BuildSalesInvoiceDraft(req)
	if err != nil {
		t.Fatalf("expected draft success, got %v", err)
	}

	draft.Status = InvoiceStatusPosted

	result, err := BuildSalesInvoiceResult(req, draft, "sales invoice posted")
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

	if result.Status != InvoiceStatusPosted {
		t.Fatalf("expected posted status, got %s", result.Status)
	}

	if result.TotalInvoiceAmount != 120 {
		t.Fatalf("expected invoice total 120, got %v", result.TotalInvoiceAmount)
	}

	if result.LineCount != 1 {
		t.Fatalf("expected line count 1, got %d", result.LineCount)
	}

	if result.PostedAt.IsZero() {
		t.Fatal("expected posted_at")
	}
}

func TestBuildSalesInvoiceResultStatusInvalid(t *testing.T) {
	req := validSalesInvoiceRequest()

	draft, err := BuildSalesInvoiceDraft(req)
	if err != nil {
		t.Fatalf("expected draft success, got %v", err)
	}

	_, err = BuildSalesInvoiceResult(req, draft, "sales invoice posted")
	if !errors.Is(err, ErrInvoiceStatusInvalid) {
		t.Fatalf("expected ErrInvoiceStatusInvalid, got %v", err)
	}
}
