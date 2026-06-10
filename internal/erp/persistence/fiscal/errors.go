package fiscal

import "errors"

var (
	ErrTenantRequired             = errors.New("tenant_id zorunlu")
	ErrFiscalYearInvalid          = errors.New("fiscal_year gecersiz")
	ErrFiscalPeriodRequired       = errors.New("fiscal_period zorunlu")
	ErrPeriodNoInvalid            = errors.New("period_no gecersiz")
	ErrDateRangeInvalid           = errors.New("tarih araligi gecersiz")
	ErrDocumentModuleInvalid      = errors.New("document_module gecersiz")
	ErrDocumentTypeRequired       = errors.New("document_type zorunlu")
	ErrDocumentSequenceIDRequired = errors.New("document_sequence_id zorunlu")
	ErrDocumentNoRequired         = errors.New("document_no zorunlu")
	ErrAllocatedNoInvalid         = errors.New("allocated_no gecersiz")
	ErrNumberRangeInvalid         = errors.New("numara araligi gecersiz")
	ErrResetPolicyInvalid         = errors.New("reset_policy gecersiz")
	ErrFiscalYearNotFound         = errors.New("fiscal year bulunamadi")
	ErrFiscalPeriodNotFound       = errors.New("fiscal period bulunamadi")
	ErrDocumentSequenceNotFound   = errors.New("document sequence bulunamadi")
	ErrDocumentAllocationNotFound = errors.New("document allocation bulunamadi")
)
