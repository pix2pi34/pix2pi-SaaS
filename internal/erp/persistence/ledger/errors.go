package ledger

import "errors"

var (
	ErrTenantRequired         = errors.New("tenant_id zorunlu")
	ErrJournalEntryIDRequired = errors.New("journal_entry_id zorunlu")
	ErrJournalLineIDRequired  = errors.New("journal_line_id zorunlu")
	ErrAccountCodeRequired    = errors.New("account_code zorunlu")
	ErrFiscalYearInvalid      = errors.New("fiscal_year gecersiz")
	ErrFiscalPeriodRequired   = errors.New("fiscal_period zorunlu")
	ErrAmountInvalid          = errors.New("amount gecersiz")
	ErrDirectionInvalid       = errors.New("direction gecersiz")
	ErrBalanceSideInvalid     = errors.New("balance_side gecersiz")
	ErrLedgerStatusInvalid    = errors.New("ledger status gecersiz")
	ErrLedgerMovementNotFound = errors.New("account movement bulunamadi")
	ErrLedgerBalanceNotFound  = errors.New("ledger balance bulunamadi")
)
