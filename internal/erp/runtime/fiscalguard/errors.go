package fiscalguard

import "errors"

var (
	ErrTenantRequired         = errors.New("tenant_id zorunlu")
	ErrPostingDateRequired    = errors.New("posting_date zorunlu")
	ErrFiscalYearInvalid      = errors.New("fiscal_year gecersiz")
	ErrFiscalPeriodRequired   = errors.New("fiscal_period zorunlu")
	ErrPeriodStartRequired    = errors.New("period_start_date zorunlu")
	ErrPeriodEndRequired      = errors.New("period_end_date zorunlu")
	ErrPeriodDateRangeInvalid = errors.New("period tarih araligi gecersiz")
	ErrPeriodStatusInvalid    = errors.New("period status gecersiz")
	ErrPeriodNotFound         = errors.New("fiscal period bulunamadi")
	ErrPeriodLocked           = errors.New("fiscal period kilitli")
	ErrPeriodClosed           = errors.New("fiscal period kapali")
	ErrPostingDateOutOfRange  = errors.New("posting_date fiscal period disinda")
)
