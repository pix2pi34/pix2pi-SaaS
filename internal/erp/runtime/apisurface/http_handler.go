package apisurface

import (
	"encoding/json"
	"errors"
	"net/http"
)

const RuntimeFlowAPIPath = "/api/v1/erp/runtime/flows"

type RuntimeFlowHTTPHandler struct {
	service RuntimeFlowAPIService
}

func NewRuntimeFlowHTTPHandler(service RuntimeFlowAPIService) *RuntimeFlowHTTPHandler {
	return &RuntimeFlowHTTPHandler{service: service}
}

func (h *RuntimeFlowHTTPHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if h.service == nil {
		writeRuntimeFlowAPIError(w, r, http.StatusInternalServerError, "RUNTIME_FLOW_API_SERVICE_REQUIRED", ErrRuntimeFlowAPIServiceRequired)
		return
	}

	if r.Method != http.MethodPost {
		writeRuntimeFlowAPIError(w, r, http.StatusMethodNotAllowed, "INVALID_HTTP_METHOD", ErrInvalidHTTPMethod)
		return
	}

	defer r.Body.Close()

	var req RuntimeFlowAPIRequest

	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()

	if err := decoder.Decode(&req); err != nil {
		writeRuntimeFlowAPIError(w, r, http.StatusBadRequest, "INVALID_JSON_REQUEST", ErrInvalidJSONRequest)
		return
	}

	resp, err := h.service.PostRuntimeFlow(r.Context(), req)
	if err != nil {
		statusCode, errorCode := runtimeFlowAPIHTTPErrorStatus(err)
		writeRuntimeFlowAPIErrorResponse(w, statusCode, BuildRuntimeFlowAPIErrorResponse(req, errorCode, err))
		return
	}

	writeRuntimeFlowAPIJSON(w, http.StatusOK, resp)
}

func runtimeFlowAPIHTTPErrorStatus(err error) (int, string) {
	switch {
	case errors.Is(err, ErrTenantIDRequired):
		return http.StatusBadRequest, "TENANT_ID_REQUIRED"
	case errors.Is(err, ErrRequestIDRequired):
		return http.StatusBadRequest, "REQUEST_ID_REQUIRED"
	case errors.Is(err, ErrActorIDRequired):
		return http.StatusBadRequest, "ACTOR_ID_REQUIRED"
	case errors.Is(err, ErrTransactionKindRequired):
		return http.StatusBadRequest, "TRANSACTION_KIND_REQUIRED"
	case errors.Is(err, ErrTransactionKindInvalid):
		return http.StatusBadRequest, "TRANSACTION_KIND_INVALID"
	case errors.Is(err, ErrSourceModuleRequired):
		return http.StatusBadRequest, "SOURCE_MODULE_REQUIRED"
	case errors.Is(err, ErrSourceDocumentTypeRequired):
		return http.StatusBadRequest, "SOURCE_DOCUMENT_TYPE_REQUIRED"
	case errors.Is(err, ErrSourceDocumentRequired):
		return http.StatusBadRequest, "SOURCE_DOCUMENT_REQUIRED"
	case errors.Is(err, ErrTotalAmountInvalid):
		return http.StatusBadRequest, "TOTAL_AMOUNT_INVALID"
	case errors.Is(err, ErrCurrencyCodeRequired):
		return http.StatusBadRequest, "CURRENCY_CODE_REQUIRED"
	case errors.Is(err, ErrExchangeRateInvalid):
		return http.StatusBadRequest, "EXCHANGE_RATE_INVALID"
	case errors.Is(err, ErrIdempotencyKeyRequired):
		return http.StatusBadRequest, "IDEMPOTENCY_KEY_REQUIRED"
	case errors.Is(err, ErrRuntimeFlowExecutorRequired):
		return http.StatusInternalServerError, "RUNTIME_FLOW_EXECUTOR_REQUIRED"
	case errors.Is(err, ErrRuntimeFlowAPIServiceRequired):
		return http.StatusInternalServerError, "RUNTIME_FLOW_API_SERVICE_REQUIRED"
	default:
		return http.StatusInternalServerError, "RUNTIME_FLOW_INTERNAL_ERROR"
	}
}

func writeRuntimeFlowAPIError(w http.ResponseWriter, r *http.Request, statusCode int, code string, err error) {
	req := RuntimeFlowAPIRequest{}
	if r != nil {
		req.RequestID = r.Header.Get("X-Request-ID")
		req.TenantID = r.Header.Get("X-Tenant-ID")
	}

	writeRuntimeFlowAPIErrorResponse(w, statusCode, BuildRuntimeFlowAPIErrorResponse(req, code, err))
}

func writeRuntimeFlowAPIErrorResponse(w http.ResponseWriter, statusCode int, resp RuntimeFlowAPIErrorResponse) {
	writeRuntimeFlowAPIJSON(w, statusCode, resp)
}

func writeRuntimeFlowAPIJSON(w http.ResponseWriter, statusCode int, payload any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(statusCode)

	_ = json.NewEncoder(w).Encode(payload)
}
