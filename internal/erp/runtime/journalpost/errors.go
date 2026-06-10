package journalpost

import "errors"

var (
	ErrTenantRequired          = errors.New("tenant_id zorunlu")
	ErrRequestIDRequired       = errors.New("request_id zorunlu")
	ErrActorRequired           = errors.New("actor zorunlu")
	ErrSourceModuleRequired    = errors.New("source_module zorunlu")
	ErrSourceDocumentRequired  = errors.New("source document zorunlu")
	ErrJournalNoRequired       = errors.New("journal_no zorunlu")
	ErrPostingDateRequired     = errors.New("posting_date zorunlu")
	ErrFiscalYearInvalid       = errors.New("fiscal_year gecersiz")
	ErrFiscalPeriodRequired    = errors.New("fiscal_period zorunlu")
	ErrJournalLineCountInvalid = errors.New("journal line sayisi gecersiz")
	ErrAccountCodeRequired     = errors.New("account_code zorunlu")
	ErrAmountInvalid           = errors.New("amount gecersiz")
	ErrJournalUnbalanced       = errors.New("journal balanced degil")
	ErrJournalStatusInvalid    = errors.New("journal status gecersiz")
	ErrJournalStoreRequired    = errors.New("journal posting store zorunlu")
	ErrJournalNotFound         = errors.New("journal bulunamadi")
	ErrJournalPersistFailed    = errors.New("journal persist basarisiz")
)
