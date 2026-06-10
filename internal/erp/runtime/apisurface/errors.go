package apisurface

import "errors"

var (
	ErrTenantIDRequired              = errors.New("tenant_id zorunlu")
	ErrRequestIDRequired             = errors.New("request_id zorunlu")
	ErrActorIDRequired               = errors.New("actor_id zorunlu")
	ErrTransactionKindRequired       = errors.New("transaction_kind zorunlu")
	ErrTransactionKindInvalid        = errors.New("transaction_kind gecersiz")
	ErrSourceModuleRequired          = errors.New("source_module zorunlu")
	ErrSourceDocumentTypeRequired    = errors.New("source_document_type zorunlu")
	ErrSourceDocumentRequired        = errors.New("source_document zorunlu")
	ErrTotalAmountInvalid            = errors.New("total_amount gecersiz")
	ErrCurrencyCodeRequired          = errors.New("currency_code zorunlu")
	ErrExchangeRateInvalid           = errors.New("exchange_rate gecersiz")
	ErrIdempotencyKeyRequired        = errors.New("idempotency_key zorunlu")
	ErrRuntimeFlowExecutorRequired   = errors.New("runtime flow executor zorunlu")
	ErrRuntimeFlowAPIServiceRequired = errors.New("runtime flow api service zorunlu")
	ErrInvalidHTTPMethod             = errors.New("http method gecersiz")
	ErrInvalidJSONRequest            = errors.New("json request gecersiz")

	ErrRouteNameRequired        = errors.New("route name zorunlu")
	ErrRoutePathRequired        = errors.New("route path zorunlu")
	ErrRouteMethodInvalid       = errors.New("route method gecersiz")
	ErrRouteHandlerRequired     = errors.New("route handler zorunlu")
	ErrRouteAuthRequired        = errors.New("route auth zorunlu")
	ErrRouteTenantHeaderMissing = errors.New("route tenant header zorunlu")
	ErrRouteRegistrarRequired   = errors.New("route registrar zorunlu")
	ErrRouteRegistrationFailed  = errors.New("route registration basarisiz")

	ErrGatewayMountNameRequired      = errors.New("gateway mount name zorunlu")
	ErrGatewayMountServiceRequired   = errors.New("gateway mount service zorunlu")
	ErrGatewayMountPathRequired      = errors.New("gateway mount path zorunlu")
	ErrGatewayMountRouteCountInvalid = errors.New("gateway mount route sayisi gecersiz")
	ErrGatewayMountRoutePathInvalid  = errors.New("gateway mount route path gecersiz")
	ErrGatewayMountSecurityInvalid   = errors.New("gateway mount security gecersiz")
)
