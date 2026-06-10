package procurement

import (
	"errors"
	"testing"
)

func TestValidateCreatePurchaseOrderInputSuccess(t *testing.T) {
	err := ValidateCreatePurchaseOrderInput(CreatePurchaseOrderInput{
		TenantID:        "tenant_7",
		PurchaseOrderNo: "PO-001",
		VendorID:        "vendor-1",
		PartyID:         "party-1",
		CurrencyCode:    "TRY",
		ExchangeRate:    1,
		SubtotalAmount:  100,
		VATAmount:       20,
		TotalAmount:     120,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreatePurchaseOrderInputNoRequired(t *testing.T) {
	err := ValidateCreatePurchaseOrderInput(CreatePurchaseOrderInput{
		TenantID:     "tenant_7",
		VendorID:     "vendor-1",
		PartyID:      "party-1",
		ExchangeRate: 1,
	})

	if !errors.Is(err, ErrPurchaseOrderNoRequired) {
		t.Fatalf("expected ErrPurchaseOrderNoRequired, got %v", err)
	}
}

func TestValidateCreatePurchaseOrderLineInputSuccess(t *testing.T) {
	err := ValidateCreatePurchaseOrderLineInput(CreatePurchaseOrderLineInput{
		TenantID:        "tenant_7",
		PurchaseOrderID: "purchase-order-1",
		LineNo:          1,
		ItemID:          "item-1",
		UnitID:          "unit-1",
		Quantity:        1,
		UnitCost:        100,
		VATRate:         20,
		VATAmount:       20,
		LineTotal:       120,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreatePurchaseOrderLineInputQuantityPositive(t *testing.T) {
	err := ValidateCreatePurchaseOrderLineInput(CreatePurchaseOrderLineInput{
		TenantID:        "tenant_7",
		PurchaseOrderID: "purchase-order-1",
		LineNo:          1,
		ItemID:          "item-1",
		UnitID:          "unit-1",
		Quantity:        0,
	})

	if !errors.Is(err, ErrQuantityMustBePositive) {
		t.Fatalf("expected ErrQuantityMustBePositive, got %v", err)
	}
}

func TestValidateCreatePurchaseOrderLineInputReceivedRangeInvalid(t *testing.T) {
	err := ValidateCreatePurchaseOrderLineInput(CreatePurchaseOrderLineInput{
		TenantID:         "tenant_7",
		PurchaseOrderID:  "purchase-order-1",
		LineNo:           1,
		ItemID:           "item-1",
		UnitID:           "unit-1",
		Quantity:         2,
		ReceivedQuantity: 3,
		UnitCost:         100,
		VATRate:          20,
		LineTotal:        240,
	})

	if !errors.Is(err, ErrQuantityRangeInvalid) {
		t.Fatalf("expected ErrQuantityRangeInvalid, got %v", err)
	}
}

func TestValidateCreatePurchaseReceiptInputSuccess(t *testing.T) {
	err := ValidateCreatePurchaseReceiptInput(CreatePurchaseReceiptInput{
		TenantID:          "tenant_7",
		PurchaseReceiptNo: "RCPT-001",
		VendorID:          "vendor-1",
		PartyID:           "party-1",
		WarehouseID:       "warehouse-1",
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreatePurchaseReceiptInputWarehouseRequired(t *testing.T) {
	err := ValidateCreatePurchaseReceiptInput(CreatePurchaseReceiptInput{
		TenantID:          "tenant_7",
		PurchaseReceiptNo: "RCPT-001",
		VendorID:          "vendor-1",
		PartyID:           "party-1",
	})

	if !errors.Is(err, ErrWarehouseIDRequired) {
		t.Fatalf("expected ErrWarehouseIDRequired, got %v", err)
	}
}

func TestValidateCreatePurchaseReceiptLineInputReceiptRequired(t *testing.T) {
	err := ValidateCreatePurchaseReceiptLineInput(CreatePurchaseReceiptLineInput{
		TenantID: "tenant_7",
		LineNo:   1,
		ItemID:   "item-1",
		UnitID:   "unit-1",
		Quantity: 1,
	})

	if !errors.Is(err, ErrPurchaseReceiptIDRequired) {
		t.Fatalf("expected ErrPurchaseReceiptIDRequired, got %v", err)
	}
}

func TestValidateCreatePurchaseInvoiceInputSuccess(t *testing.T) {
	err := ValidateCreatePurchaseInvoiceInput(CreatePurchaseInvoiceInput{
		TenantID:          "tenant_7",
		PurchaseInvoiceNo: "PINV-001",
		VendorID:          "vendor-1",
		PartyID:           "party-1",
		InvoiceType:       PurchaseInvoiceTypePurchase,
		CurrencyCode:      "TRY",
		ExchangeRate:      1,
		SubtotalAmount:    100,
		VATAmount:         20,
		TotalAmount:       120,
		PaidAmount:        0,
		RemainingAmount:   120,
		EDocumentStatus:   PurchaseEDocumentStatusNone,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreatePurchaseInvoiceInputInvoiceTypeInvalid(t *testing.T) {
	err := ValidateCreatePurchaseInvoiceInput(CreatePurchaseInvoiceInput{
		TenantID:          "tenant_7",
		PurchaseInvoiceNo: "PINV-001",
		VendorID:          "vendor-1",
		PartyID:           "party-1",
		InvoiceType:       PurchaseInvoiceType("wrong"),
		ExchangeRate:      1,
		TotalAmount:       120,
		RemainingAmount:   120,
	})

	if !errors.Is(err, ErrPurchaseInvoiceTypeInvalid) {
		t.Fatalf("expected ErrPurchaseInvoiceTypeInvalid, got %v", err)
	}
}

func TestValidateCreatePurchaseInvoiceInputPaidCannotExceedTotal(t *testing.T) {
	err := ValidateCreatePurchaseInvoiceInput(CreatePurchaseInvoiceInput{
		TenantID:          "tenant_7",
		PurchaseInvoiceNo: "PINV-001",
		VendorID:          "vendor-1",
		PartyID:           "party-1",
		InvoiceType:       PurchaseInvoiceTypePurchase,
		ExchangeRate:      1,
		TotalAmount:       120,
		PaidAmount:        130,
		RemainingAmount:   0,
	})

	if !errors.Is(err, ErrAmountInvalid) {
		t.Fatalf("expected ErrAmountInvalid, got %v", err)
	}
}

func TestValidateCreatePurchaseInvoiceLineInputVATRateInvalid(t *testing.T) {
	err := ValidateCreatePurchaseInvoiceLineInput(CreatePurchaseInvoiceLineInput{
		TenantID:          "tenant_7",
		PurchaseInvoiceID: "purchase-invoice-1",
		LineNo:            1,
		ItemID:            "item-1",
		UnitID:            "unit-1",
		Quantity:          1,
		UnitCost:          100,
		VATRate:           150,
		LineTotal:         120,
	})

	if !errors.Is(err, ErrVATRateInvalid) {
		t.Fatalf("expected ErrVATRateInvalid, got %v", err)
	}
}
