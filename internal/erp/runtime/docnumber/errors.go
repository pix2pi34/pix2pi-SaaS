package docnumber

import "errors"

var (
	ErrTenantRequired          = errors.New("tenant_id zorunlu")
	ErrRequestIDRequired       = errors.New("request_id zorunlu")
	ErrActorRequired           = errors.New("actor zorunlu")
	ErrDocumentModuleInvalid   = errors.New("document_module gecersiz")
	ErrDocumentTypeRequired    = errors.New("document_type zorunlu")
	ErrSequenceIDRequired      = errors.New("document_sequence_id zorunlu")
	ErrSequenceNotFound        = errors.New("document sequence bulunamadi")
	ErrSequenceInactive        = errors.New("document sequence pasif")
	ErrSequenceLocked          = errors.New("document sequence kilitli")
	ErrSequenceExhausted       = errors.New("document sequence numara limiti doldu")
	ErrCurrentNoInvalid        = errors.New("current_no gecersiz")
	ErrMinNoInvalid            = errors.New("min_no gecersiz")
	ErrMaxNoInvalid            = errors.New("max_no gecersiz")
	ErrPaddingInvalid          = errors.New("padding gecersiz")
	ErrAllocatedNoInvalid      = errors.New("allocated_no gecersiz")
	ErrFiscalYearInvalid       = errors.New("fiscal_year gecersiz")
	ErrAllocationStatusInvalid = errors.New("allocation_status gecersiz")
	ErrAllocationStoreRequired = errors.New("document number allocation store zorunlu")
)
