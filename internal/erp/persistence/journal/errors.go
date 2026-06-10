package journal

import "errors"

var (
	ErrTenantRequired           = errors.New("tenant_id zorunlu")
	ErrJournalNoRequired        = errors.New("journal_no zorunlu")
	ErrJournalEntryIDRequired   = errors.New("journal_entry_id zorunlu")
	ErrLineNoInvalid            = errors.New("line_no gecersiz")
	ErrAccountCodeRequired      = errors.New("account_code zorunlu")
	ErrAmountInvalid            = errors.New("amount gecersiz")
	ErrJournalNotBalanced       = errors.New("journal borc/alacak dengede degil")
	ErrJournalLineSideInvalid   = errors.New("journal line borc/alacak tarafi gecersiz")
	ErrJournalSourceInvalid     = errors.New("source_module gecersiz")
	ErrJournalStatusInvalid     = errors.New("journal status gecersiz")
	ErrJournalLineStatusInvalid = errors.New("journal line status gecersiz")
	ErrJournalEntryNotFound     = errors.New("journal entry bulunamadi")
	ErrJournalLineNotFound      = errors.New("journal line bulunamadi")
)
