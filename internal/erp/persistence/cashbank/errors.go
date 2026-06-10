package cashbank

import "errors"

var (
	ErrTenantRequired             = errors.New("tenant_id zorunlu")
	ErrCashCodeRequired           = errors.New("cash_code zorunlu")
	ErrCashNameRequired           = errors.New("cash_name zorunlu")
	ErrBankCodeRequired           = errors.New("bank_code zorunlu")
	ErrBankNameRequired           = errors.New("bank_name zorunlu")
	ErrPaymentNoRequired          = errors.New("payment_no zorunlu")
	ErrPaymentTypeInvalid         = errors.New("payment_type gecersiz")
	ErrPaymentDirectionInvalid    = errors.New("payment_direction gecersiz")
	ErrPaymentMethodInvalid       = errors.New("payment_method gecersiz")
	ErrPaymentAccountRequired     = errors.New("cash_account_id veya bank_account_id zorunlu")
	ErrSourceModuleInvalid        = errors.New("source_module gecersiz")
	ErrAmountInvalid              = errors.New("amount gecersiz")
	ErrPaymentStatusInvalid       = errors.New("payment status gecersiz")
	ErrCashAccountNotFound        = errors.New("cash account bulunamadi")
	ErrBankAccountNotFound        = errors.New("bank account bulunamadi")
	ErrPaymentTransactionNotFound = errors.New("payment transaction bulunamadi")
)
