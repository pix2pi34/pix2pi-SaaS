package sales

import (
	"errors"
	"testing"
)

func TestValidateCreateSalesQuotationInputSuccess(t *testing.T) {
	err := ValidateCreateSalesQuotationInput(CreateSalesQuotationInput{
		TenantID:       "tenant_7",
		QuotationNo:    "QT-001",
		CustomerID:     "customer-1",
		PartyID:        "party-1",
		CurrencyCode:   "TRY",
		ExchangeRate:   1,
		SubtotalAmount: 100,
		VATAmount:      20,
		TotalAmount:    120,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateSalesQuotationInputNoRequired(t *testing.T) {
	err := ValidateCreateSalesQuotationInput(CreateSalesQuotationInput{
		TenantID:     "tenant_7",
		CustomerID:   "customer-1",
		PartyID:      "party-1",
		ExchangeRate: 1,
	})

	if !errors.Is(err, ErrQuotationNoRequired) {
		t.Fatalf("expected ErrQuotationNoRequired, got %v", err)
	}
}

func TestValidateCreateSalesQuotationLineInputSuccess(t *testing.T) {
	err := ValidateCreateSalesQuotationLineInput(CreateSalesQuotationLineInput{
		TenantID:    "tenant_7",
		QuotationID: "quotation-1",
		LineNo:      1,
		ItemID:      "item-1",
		UnitID:      "unit-1",
		Quantity:    1,
		UnitPrice:   100,
		VATRate:     20,
		VATAmount:   20,
		LineTotal:   120,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateSalesQuotationLineInputQuantityPositive(t *testing.T) {
	err := ValidateCreateSalesQuotationLineInput(CreateSalesQuotationLineInput{
		TenantID:    "tenant_7",
		QuotationID: "quotation-1",
		LineNo:      1,
		ItemID:      "item-1",
		UnitID:      "unit-1",
		Quantity:    0,
	})

	if !errors.Is(err, ErrQuantityMustBePositive) {
		t.Fatalf("expected ErrQuantityMustBePositive, got %v", err)
	}
}

func TestValidateCreateSalesOrderInputSuccess(t *testing.T) {
	err := ValidateCreateSalesOrderInput(CreateSalesOrderInput{
		TenantID:       "tenant_7",
		SalesOrderNo:   "SO-001",
		CustomerID:     "customer-1",
		PartyID:        "party-1",
		CurrencyCode:   "TRY",
		ExchangeRate:   1,
		SubtotalAmount: 100,
		VATAmount:      20,
		TotalAmount:    120,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateSalesOrderInputCustomerRequired(t *testing.T) {
	err := ValidateCreateSalesOrderInput(CreateSalesOrderInput{
		TenantID:     "tenant_7",
		SalesOrderNo: "SO-001",
		PartyID:      "party-1",
		ExchangeRate: 1,
	})

	if !errors.Is(err, ErrCustomerIDRequired) {
		t.Fatalf("expected ErrCustomerIDRequired, got %v", err)
	}
}

func TestValidateCreateSalesOrderLineInputDeliveredRangeInvalid(t *testing.T) {
	err := ValidateCreateSalesOrderLineInput(CreateSalesOrderLineInput{
		TenantID:          "tenant_7",
		SalesOrderID:      "sales-order-1",
		LineNo:            1,
		ItemID:            "item-1",
		UnitID:            "unit-1",
		Quantity:          2,
		DeliveredQuantity: 3,
		UnitPrice:         100,
		VATRate:           20,
		LineTotal:         240,
	})

	if !errors.Is(err, ErrQuantityRangeInvalid) {
		t.Fatalf("expected ErrQuantityRangeInvalid, got %v", err)
	}
}

func TestValidateCreateSalesDeliveryInputSuccess(t *testing.T) {
	err := ValidateCreateSalesDeliveryInput(CreateSalesDeliveryInput{
		TenantID:    "tenant_7",
		DeliveryNo:  "DEL-001",
		CustomerID:  "customer-1",
		PartyID:     "party-1",
		WarehouseID: "warehouse-1",
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateSalesDeliveryInputWarehouseRequired(t *testing.T) {
	err := ValidateCreateSalesDeliveryInput(CreateSalesDeliveryInput{
		TenantID:   "tenant_7",
		DeliveryNo: "DEL-001",
		CustomerID: "customer-1",
		PartyID:    "party-1",
	})

	if !errors.Is(err, ErrWarehouseIDRequired) {
		t.Fatalf("expected ErrWarehouseIDRequired, got %v", err)
	}
}

func TestValidateCreateSalesDeliveryLineInputDeliveryRequired(t *testing.T) {
	err := ValidateCreateSalesDeliveryLineInput(CreateSalesDeliveryLineInput{
		TenantID: "tenant_7",
		LineNo:   1,
		ItemID:   "item-1",
		UnitID:   "unit-1",
		Quantity: 1,
	})

	if !errors.Is(err, ErrDeliveryIDRequired) {
		t.Fatalf("expected ErrDeliveryIDRequired, got %v", err)
	}
}

func TestValidateCreateSalesInvoiceInputSuccess(t *testing.T) {
	err := ValidateCreateSalesInvoiceInput(CreateSalesInvoiceInput{
		TenantID:        "tenant_7",
		SalesInvoiceNo:  "INV-001",
		CustomerID:      "customer-1",
		PartyID:         "party-1",
		InvoiceType:     SalesInvoiceTypeSales,
		CurrencyCode:    "TRY",
		ExchangeRate:    1,
		SubtotalAmount:  100,
		VATAmount:       20,
		TotalAmount:     120,
		PaidAmount:      0,
		RemainingAmount: 120,
		EDocumentStatus: EDocumentStatusNone,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateSalesInvoiceInputInvoiceTypeInvalid(t *testing.T) {
	err := ValidateCreateSalesInvoiceInput(CreateSalesInvoiceInput{
		TenantID:        "tenant_7",
		SalesInvoiceNo:  "INV-001",
		CustomerID:      "customer-1",
		PartyID:         "party-1",
		InvoiceType:     SalesInvoiceType("wrong"),
		ExchangeRate:    1,
		TotalAmount:     120,
		RemainingAmount: 120,
	})

	if !errors.Is(err, ErrInvoiceTypeInvalid) {
		t.Fatalf("expected ErrInvoiceTypeInvalid, got %v", err)
	}
}

func TestValidateCreateSalesInvoiceInputPaidCannotExceedTotal(t *testing.T) {
	err := ValidateCreateSalesInvoiceInput(CreateSalesInvoiceInput{
		TenantID:        "tenant_7",
		SalesInvoiceNo:  "INV-001",
		CustomerID:      "customer-1",
		PartyID:         "party-1",
		InvoiceType:     SalesInvoiceTypeSales,
		ExchangeRate:    1,
		TotalAmount:     120,
		PaidAmount:      130,
		RemainingAmount: 0,
	})

	if !errors.Is(err, ErrAmountInvalid) {
		t.Fatalf("expected ErrAmountInvalid, got %v", err)
	}
}

func TestValidateCreateSalesInvoiceLineInputVATRateInvalid(t *testing.T) {
	err := ValidateCreateSalesInvoiceLineInput(CreateSalesInvoiceLineInput{
		TenantID:       "tenant_7",
		SalesInvoiceID: "invoice-1",
		LineNo:         1,
		ItemID:         "item-1",
		UnitID:         "unit-1",
		Quantity:       1,
		UnitPrice:      100,
		VATRate:        150,
		LineTotal:      120,
	})

	if !errors.Is(err, ErrVATRateInvalid) {
		t.Fatalf("expected ErrVATRateInvalid, got %v", err)
	}
}
