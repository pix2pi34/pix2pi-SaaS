package taxcalc

import "errors"

var (
	ErrTenantRequired              = errors.New("tenant_id zorunlu")
	ErrRequestIDRequired           = errors.New("request_id zorunlu")
	ErrActorRequired               = errors.New("actor zorunlu")
	ErrSourceModuleRequired        = errors.New("source_module zorunlu")
	ErrSourceDocumentRequired      = errors.New("source document zorunlu")
	ErrFiscalYearInvalid           = errors.New("fiscal_year gecersiz")
	ErrFiscalPeriodRequired        = errors.New("fiscal_period zorunlu")
	ErrCalculationDateRequired     = errors.New("calculation_date zorunlu")
	ErrTransactionTypeInvalid      = errors.New("transaction_type gecersiz")
	ErrTaxCodeRequired             = errors.New("tax_code zorunlu")
	ErrTaxRateInvalid              = errors.New("tax_rate gecersiz")
	ErrTaxCodeInactive             = errors.New("tax_code pasif")
	ErrBaseAmountInvalid           = errors.New("base_amount gecersiz")
	ErrCurrencyRequired            = errors.New("currency_code zorunlu")
	ErrExchangeRateInvalid         = errors.New("exchange_rate gecersiz")
	ErrWithholdingRatioInvalid     = errors.New("withholding ratio gecersiz")
	ErrTaxCalculationStatusInvalid = errors.New("tax calculation status gecersiz")
	ErrTaxLineCountInvalid         = errors.New("tax line sayisi gecersiz")
	ErrTaxStoreRequired            = errors.New("tax store zorunlu")
	ErrTaxNotFound                 = errors.New("tax calculation bulunamadi")
	ErrTaxPersistFailed            = errors.New("tax calculation persist basarisiz")
)
