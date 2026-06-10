package ledgerpost

import "errors"

var (
	ErrTenantRequired           = errors.New("tenant_id zorunlu")
	ErrRequestIDRequired        = errors.New("request_id zorunlu")
	ErrActorRequired            = errors.New("actor zorunlu")
	ErrJournalRefRequired       = errors.New("journal ref zorunlu")
	ErrJournalStatusInvalid     = errors.New("journal status gecersiz")
	ErrPostingDateRequired      = errors.New("posting_date zorunlu")
	ErrFiscalYearInvalid        = errors.New("fiscal_year gecersiz")
	ErrFiscalPeriodRequired     = errors.New("fiscal_period zorunlu")
	ErrLedgerLineCountInvalid   = errors.New("ledger line sayisi gecersiz")
	ErrAccountCodeRequired      = errors.New("account_code zorunlu")
	ErrAmountInvalid            = errors.New("amount gecersiz")
	ErrLedgerUnbalanced         = errors.New("ledger balanced degil")
	ErrMovementDirectionInvalid = errors.New("movement_direction gecersiz")
	ErrLedgerStatusInvalid      = errors.New("ledger status gecersiz")
	ErrLedgerStoreRequired      = errors.New("ledger posting store zorunlu")
	ErrLedgerNotFound           = errors.New("ledger kaydi bulunamadi")
	ErrLedgerPersistFailed      = errors.New("ledger persist basarisiz")
)
