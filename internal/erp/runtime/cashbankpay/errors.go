package cashbankpay

import "errors"

var (
	ErrTenantRequired          = errors.New("tenant_id zorunlu")
	ErrRequestIDRequired       = errors.New("request_id zorunlu")
	ErrActorRequired           = errors.New("actor zorunlu")
	ErrSourceModuleRequired    = errors.New("source_module zorunlu")
	ErrSourceDocumentRequired  = errors.New("source document zorunlu")
	ErrPaymentNoRequired       = errors.New("payment_no zorunlu")
	ErrPaymentDirectionInvalid = errors.New("payment_direction gecersiz")
	ErrPaymentMethodInvalid    = errors.New("payment_method gecersiz")
	ErrPaymentStatusInvalid    = errors.New("payment_status gecersiz")
	ErrAccountRefRequired      = errors.New("account ref zorunlu")
	ErrAccountTypeInvalid      = errors.New("account_type gecersiz")
	ErrAmountInvalid           = errors.New("amount gecersiz")
	ErrCurrencyRequired        = errors.New("currency_code zorunlu")
	ErrFiscalYearInvalid       = errors.New("fiscal_year gecersiz")
	ErrFiscalPeriodRequired    = errors.New("fiscal_period zorunlu")
	ErrPaymentDateRequired     = errors.New("payment_date zorunlu")
	ErrMovementCountInvalid    = errors.New("cashbank movement sayisi gecersiz")
	ErrPaymentStoreRequired    = errors.New("payment store zorunlu")
	ErrPaymentNotFound         = errors.New("payment bulunamadi")
	ErrPaymentPersistFailed    = errors.New("payment persist basarisiz")
)
