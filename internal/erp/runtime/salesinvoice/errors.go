package salesinvoice

import "errors"

var (
	ErrTenantRequired            = errors.New("tenant_id zorunlu")
	ErrRequestIDRequired         = errors.New("request_id zorunlu")
	ErrActorRequired             = errors.New("actor zorunlu")
	ErrInvoiceNoRequired         = errors.New("invoice_no zorunlu")
	ErrCustomerRequired          = errors.New("customer zorunlu")
	ErrFiscalYearInvalid         = errors.New("fiscal_year gecersiz")
	ErrFiscalPeriodRequired      = errors.New("fiscal_period zorunlu")
	ErrInvoiceDateRequired       = errors.New("invoice_date zorunlu")
	ErrPostingDateRequired       = errors.New("posting_date zorunlu")
	ErrCurrencyRequired          = errors.New("currency_code zorunlu")
	ErrExchangeRateInvalid       = errors.New("exchange_rate gecersiz")
	ErrInvoiceLineCountInvalid   = errors.New("invoice line sayisi gecersiz")
	ErrProductRequired           = errors.New("product zorunlu")
	ErrQuantityInvalid           = errors.New("quantity gecersiz")
	ErrUnitPriceInvalid          = errors.New("unit_price gecersiz")
	ErrDiscountInvalid           = errors.New("discount gecersiz")
	ErrTaxCodeRequired           = errors.New("tax_code zorunlu")
	ErrTaxRateInvalid            = errors.New("tax_rate gecersiz")
	ErrInvoiceStatusInvalid      = errors.New("invoice status gecersiz")
	ErrInvoiceTotalInvalid       = errors.New("invoice total gecersiz")
	ErrSalesInvoiceStoreRequired = errors.New("sales invoice store zorunlu")
	ErrSalesInvoiceNotFound      = errors.New("sales invoice bulunamadi")
	ErrSalesInvoicePersistFailed = errors.New("sales invoice persist basarisiz")
)
