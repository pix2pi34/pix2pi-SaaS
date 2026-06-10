package chartofaccounts

import "errors"

var (
	ErrTenantRequired         = errors.New("tenant_id zorunlu")
	ErrAccountCodeRequired    = errors.New("account_code zorunlu")
	ErrAccountNameRequired    = errors.New("account_name zorunlu")
	ErrAccountLevelInvalid    = errors.New("account_level gecersiz")
	ErrAccountTypeInvalid     = errors.New("account_type gecersiz")
	ErrNormalBalanceInvalid   = errors.New("normal_balance gecersiz")
	ErrVATRateInvalid         = errors.New("vat_rate gecersiz")
	ErrMappingKeyRequired     = errors.New("mapping_key zorunlu")
	ErrSourceModuleInvalid    = errors.New("source_module gecersiz")
	ErrPriorityInvalid        = errors.New("priority gecersiz")
	ErrChartAccountNotFound   = errors.New("chart account bulunamadi")
	ErrAccountMappingNotFound = errors.New("account mapping rule bulunamadi")
)
