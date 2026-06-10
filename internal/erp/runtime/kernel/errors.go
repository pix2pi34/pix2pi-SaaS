package kernel

import "errors"

var (
	ErrTenantRequired      = errors.New("tenant_id zorunlu")
	ErrRequestIDRequired   = errors.New("request_id zorunlu")
	ErrActorRequired       = errors.New("actor zorunlu")
	ErrOperationRequired   = errors.New("operation zorunlu")
	ErrDocumentRefInvalid  = errors.New("document ref gecersiz")
	ErrAmountInvalid       = errors.New("amount gecersiz")
	ErrCurrencyRequired    = errors.New("currency_code zorunlu")
	ErrFiscalYearInvalid   = errors.New("fiscal_year gecersiz")
	ErrFiscalPeriodInvalid = errors.New("fiscal_period gecersiz")
)
