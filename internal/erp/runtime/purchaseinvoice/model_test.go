package purchaseinvoice

import (
	"errors"
	"testing"
	"time"
)

func validPurchaseInvoiceRequest() PurchaseInvoiceRequest {
	return PurchaseInvoiceRequest{
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
		InvoiceNo: "PINV-2026-000001",
		Vendor: VendorRef{
			VendorID:   "vendor-1",
			VendorCode: "SATICI-001",
			VendorName: "Test Tedarikci",
			TaxNo:      "1234567890",
			TaxOffice:  "Istanbul",
		},
		Money: MoneyContext{
			CurrencyCode: "TRY",
			ExchangeRate: 1,
		},
		Lines: []PurchaseInvoiceLineRequest{
			{
				LineNo: 1,
				Item: ItemRef{
					ItemID:   "item-1",
					ItemCode: "URUN-001",
					ItemName: "Test Urun",
					UnitCode: "ADET",
				},
				Quantity:       2,
				UnitPrice:      50,
				DiscountAmount: 0,
				TaxCode:        "KDV20",
				TaxRate:        20,
				Description:    "Test alim satiri",
			},
		},
		Description: "Purchase invoice test",
		Metadata: map[string]string{
			"source": "faz3_10_9a_test",
		},
	}
}

func TestValidatePurchaseInvoiceRequestSuccess(t *testing.T) {
	req := validPurchaseInvoiceRequest()

	if err := ValidatePurchaseInvoiceRequest(req); err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidatePurchaseInvoiceRequestTenantRequired(t *testing.T) {
	req := validPurchaseInvoiceRequest()
	req.Tenant.TenantID = ""

	err := ValidatePurchaseInvoiceRequest(req)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidatePurchaseInvoiceRequestInvoiceNoRequired(t *testing.T) {
	req := validPurchaseInvoiceRequest()
	req.InvoiceNo = ""

	err := ValidatePurchaseInvoiceRequest(req)
	if !errors.Is(err, ErrInvoiceNoRequired) {
		t.Fatalf("expected ErrInvoiceNoRequired, got %v", err)
	}
}

func TestValidatePurchaseInvoiceRequestVendorRequired(t *testing.T) {
	req := validPurchaseInvoiceRequest()
	req.Vendor = VendorRef{}

	err := ValidatePurchaseInvoiceRequest(req)
	if !errors.Is(err, ErrVendorRequired) {
		t.Fatalf("expected ErrVendorRequired, got %v", err)
	}
}

func TestValidatePurchaseInvoiceRequestFiscalYearInvalid(t *testing.T) {
	req := validPurchaseInvoiceRequest()
	req.Fiscal.FiscalYear = 1999

	err := ValidatePurchaseInvoiceRequest(req)
	if !errors.Is(err, ErrFiscalYearInvalid) {
		t.Fatalf("expected ErrFiscalYearInvalid, got %v", err)
	}
}

func TestValidatePurchaseInvoiceRequestCurrencyRequired(t *testing.T) {
	req := validPurchaseInvoiceRequest()
	req.Money.CurrencyCode = ""

	err := ValidatePurchaseInvoiceRequest(req)
	if !errors.Is(err, ErrCurrencyRequired) {
		t.Fatalf("expected ErrCurrencyRequired, got %v", err)
	}
}

func TestValidatePurchaseInvoiceRequestLineCountInvalid(t *testing.T) {
	req := validPurchaseInvoiceRequest()
	req.Lines = nil

	err := ValidatePurchaseInvoiceRequest(req)
	if !errors.Is(err, ErrInvoiceLineCountInvalid) {
		t.Fatalf("expected ErrInvoiceLineCountInvalid, got %v", err)
	}
}

func TestValidatePurchaseInvoiceRequestItemRequired(t *testing.T) {
	req := validPurchaseInvoiceRequest()
	req.Lines[0].Item = ItemRef{}

	err := ValidatePurchaseInvoiceRequest(req)
	if !errors.Is(err, ErrItemRequired) {
		t.Fatalf("expected ErrItemRequired, got %v", err)
	}
}

func TestValidatePurchaseInvoiceRequestQuantityInvalid(t *testing.T) {
	req := validPurchaseInvoiceRequest()
	req.Lines[0].Quantity = 0

	err := ValidatePurchaseInvoiceRequest(req)
	if !errors.Is(err, ErrQuantityInvalid) {
		t.Fatalf("expected ErrQuantityInvalid, got %v", err)
	}
}

func TestValidatePurchaseInvoiceRequestDiscountInvalid(t *testing.T) {
	req := validPurchaseInvoiceRequest()
	req.Lines[0].DiscountAmount = 999

	err := ValidatePurchaseInvoiceRequest(req)
	if !errors.Is(err, ErrDiscountInvalid) {
		t.Fatalf("expected ErrDiscountInvalid, got %v", err)
	}
}

func TestValidatePurchaseInvoiceRequestTaxCodeRequired(t *testing.T) {
	req := validPurchaseInvoiceRequest()
	req.Lines[0].TaxCode = ""

	err := ValidatePurchaseInvoiceRequest(req)
	if !errors.Is(err, ErrTaxCodeRequired) {
		t.Fatalf("expected ErrTaxCodeRequired, got %v", err)
	}
}

func TestBuildPurchaseInvoiceLineDraftSuccess(t *testing.T) {
	req := validPurchaseInvoiceRequest()

	line, err := BuildPurchaseInvoiceLineDraft(req.Lines[0], req.Money)
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

func TestBuildPurchaseInvoiceLineDraftWithDiscount(t *testing.T) {
	req := validPurchaseInvoiceRequest()
	req.Lines[0].DiscountAmount = 10

	line, err := BuildPurchaseInvoiceLineDraft(req.Lines[0], req.Money)
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

func TestBuildPurchaseInvoiceDraftSuccess(t *testing.T) {
	req := validPurchaseInvoiceRequest()

	draft, err := BuildPurchaseInvoiceDraft(req)
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

func TestValidatePurchaseInvoiceDraftSuccess(t *testing.T) {
	req := validPurchaseInvoiceRequest()

	draft, err := BuildPurchaseInvoiceDraft(req)
	if err != nil {
		t.Fatalf("expected draft success, got %v", err)
	}

	if err := ValidatePurchaseInvoiceDraft(draft); err != nil {
		t.Fatalf("expected validate success, got %v", err)
	}
}

func TestBuildPurchaseInvoiceResultSuccess(t *testing.T) {
	req := validPurchaseInvoiceRequest()

	draft, err := BuildPurchaseInvoiceDraft(req)
	if err != nil {
		t.Fatalf("expected draft success, got %v", err)
	}

	draft.Status = InvoiceStatusPosted

	result, err := BuildPurchaseInvoiceResult(req, draft, "purchase invoice posted")
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

func TestBuildPurchaseInvoiceResultStatusInvalid(t *testing.T) {
	req := validPurchaseInvoiceRequest()

	draft, err := BuildPurchaseInvoiceDraft(req)
	if err != nil {
		t.Fatalf("expected draft success, got %v", err)
	}

	_, err = BuildPurchaseInvoiceResult(req, draft, "purchase invoice posted")
	if !errors.Is(err, ErrInvoiceStatusInvalid) {
		t.Fatalf("expected ErrInvoiceStatusInvalid, got %v", err)
	}
}
