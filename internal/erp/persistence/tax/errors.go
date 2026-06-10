package tax

import "errors"

var (
	ErrTenantRequired          = errors.New("tenant_id zorunlu")
	ErrTaxCodeRequired         = errors.New("tax_code zorunlu")
	ErrTaxNameRequired         = errors.New("tax_name zorunlu")
	ErrTaxTypeInvalid          = errors.New("tax_type gecersiz")
	ErrTaxCodeIDRequired       = errors.New("tax_code_id zorunlu")
	ErrTaxRateIDRequired       = errors.New("tax_rate_id zorunlu")
	ErrRateInvalid             = errors.New("rate_percent gecersiz")
	ErrWithholdingRatioInvalid = errors.New("withholding ratio gecersiz")
	ErrValidRangeInvalid       = errors.New("valid_from / valid_to araligi gecersiz")
	ErrSourceModuleInvalid     = errors.New("source_module gecersiz")
	ErrFiscalYearInvalid       = errors.New("fiscal_year gecersiz")
	ErrFiscalPeriodRequired    = errors.New("fiscal_period zorunlu")
	ErrAmountInvalid           = errors.New("amount gecersiz")
	ErrDirectionInvalid        = errors.New("direction gecersiz")
	ErrTaxStatusInvalid        = errors.New("tax status gecersiz")
	ErrTaxCodeNotFound         = errors.New("tax code bulunamadi")
	ErrTaxRateNotFound         = errors.New("tax rate bulunamadi")
	ErrTaxTransactionNotFound  = errors.New("tax transaction bulunamadi")
)
