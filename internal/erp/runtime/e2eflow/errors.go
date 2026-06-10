package e2eflow

import "errors"

var (
	ErrTenantRequired         = errors.New("tenant_id zorunlu")
	ErrRequestIDRequired      = errors.New("request_id zorunlu")
	ErrActorRequired          = errors.New("actor zorunlu")
	ErrTransactionKindInvalid = errors.New("transaction_kind gecersiz")
	ErrSourceModuleRequired   = errors.New("source_module zorunlu")
	ErrSourceDocumentRequired = errors.New("source document zorunlu")
	ErrTotalAmountInvalid     = errors.New("total_amount gecersiz")
	ErrCurrencyRequired       = errors.New("currency_code zorunlu")
	ErrExchangeRateInvalid    = errors.New("exchange_rate gecersiz")
	ErrIdempotencyKeyRequired = errors.New("idempotency_key zorunlu")
	ErrFlowStatusInvalid      = errors.New("flow_status gecersiz")
	ErrFlowStepCountInvalid   = errors.New("flow step sayisi gecersiz")
	ErrFlowStepKindInvalid    = errors.New("flow step kind gecersiz")
	ErrFlowStepStatusInvalid  = errors.New("flow step status gecersiz")
	ErrFlowPlanRequired       = errors.New("flow plan zorunlu")
	ErrFlowStoreRequired      = errors.New("flow store zorunlu")
	ErrFlowNotFound           = errors.New("flow bulunamadi")
	ErrFlowPersistFailed      = errors.New("flow persist basarisiz")
	ErrFlowAdapterRequired    = errors.New("flow adapter zorunlu")
	ErrFlowAdapterNotFound    = errors.New("flow adapter bulunamadi")

	ErrDocumentAdapterRequired  = errors.New("document adapter zorunlu")
	ErrTaxAdapterRequired       = errors.New("tax adapter zorunlu")
	ErrCashBankAdapterRequired  = errors.New("cashbank adapter zorunlu")
	ErrJournalAdapterRequired   = errors.New("journal adapter zorunlu")
	ErrLedgerAdapterRequired    = errors.New("ledger adapter zorunlu")
	ErrPublisherAdapterRequired = errors.New("publisher adapter zorunlu")
)
