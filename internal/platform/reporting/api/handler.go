package api

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"

	reportingservice "github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/service"
)

type tenantClaimContextKey struct{}

// WithTenantClaim stores a JWT tenant claim resolved by upstream auth middleware.
// The skeleton uses it only to enforce X-Tenant-ID equality when present.
func WithTenantClaim(ctx context.Context, tenantID string) context.Context {
	return context.WithValue(ctx, tenantClaimContextKey{}, tenantID)
}

func tenantClaimFromContext(ctx context.Context) string {
	value, ok := ctx.Value(tenantClaimContextKey{}).(string)
	if !ok {
		return ""
	}

	return strings.TrimSpace(value)
}

// ReportingService is the service boundary consumed by the API skeleton.
type ReportingService interface {
	OperationalSummary(ctx context.Context, req reportingservice.OperationalSummaryRequest) (reportingservice.QueryResponse, error)
	DailyMetrics(ctx context.Context, req reportingservice.DailyMetricsRequest) (reportingservice.QueryResponse, error)
	InventoryStatus(ctx context.Context, req reportingservice.InventoryStatusRequest) (reportingservice.QueryResponse, error)
	DocumentWorkQueue(ctx context.Context, req reportingservice.DocumentWorkQueueRequest) (reportingservice.QueryResponse, error)
	ReconciliationStatus(ctx context.Context, req reportingservice.ReconciliationStatusRequest) (reportingservice.QueryResponse, error)
	ProjectionState(ctx context.Context, req reportingservice.ProjectionStateRequest) (reportingservice.QueryResponse, error)
}

// Handler is a net/http compatible endpoint skeleton.
// It does not start a runtime server by itself.
type Handler struct {
	service ReportingService
}

// NewHandler creates a reporting API skeleton handler.
func NewHandler(service ReportingService) Handler {
	if service == nil {
		defaultService := reportingservice.New(nil)
		service = defaultService
	}

	return Handler{service: service}
}

// Register attaches all reporting endpoint skeleton routes to a mux.
// This function does not start a server.
func (h Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc(PathOperationalSummary, h.ServeHTTP)
	mux.HandleFunc(PathDailyMetrics, h.ServeHTTP)
	mux.HandleFunc(PathInventoryStatus, h.ServeHTTP)
	mux.HandleFunc(PathDocumentWorkQueue, h.ServeHTTP)
	mux.HandleFunc(PathReconciliationStatus, h.ServeHTTP)
	mux.HandleFunc(PathProjectionState, h.ServeHTTP)
}

// ServeHTTP routes reporting endpoints to the service layer.
func (h Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		h.writeError(w, r, http.StatusMethodNotAllowed, "", ErrorCodeMethodNotAllowed, "method not allowed")
		return
	}

	tenantID, ok := h.resolveTenant(w, r)
	if !ok {
		return
	}

	switch r.URL.Path {
	case PathOperationalSummary:
		resp, err := h.service.OperationalSummary(r.Context(), reportingservice.OperationalSummaryRequest{
			TenantID: tenantID,
		})
		h.writeServiceResult(w, r, tenantID, resp, err)

	case PathDailyMetrics:
		page, ok := h.parsePage(w, r, tenantID)
		if !ok {
			return
		}

		resp, err := h.service.DailyMetrics(r.Context(), reportingservice.DailyMetricsRequest{
			TenantID: tenantID,
			FromDate: r.URL.Query().Get("from_date"),
			ToDate:   r.URL.Query().Get("to_date"),
			Page:     page,
		})
		h.writeServiceResult(w, r, tenantID, resp, err)

	case PathInventoryStatus:
		page, ok := h.parsePage(w, r, tenantID)
		if !ok {
			return
		}

		alertOnly, ok := h.parseOptionalBool(w, r, tenantID, "alert_only")
		if !ok {
			return
		}

		resp, err := h.service.InventoryStatus(r.Context(), reportingservice.InventoryStatusRequest{
			TenantID:    tenantID,
			WarehouseID: r.URL.Query().Get("warehouse_id"),
			SKU:         r.URL.Query().Get("sku"),
			AlertOnly:   alertOnly,
			Page:        page,
		})
		h.writeServiceResult(w, r, tenantID, resp, err)

	case PathDocumentWorkQueue:
		page, ok := h.parsePage(w, r, tenantID)
		if !ok {
			return
		}

		priority, ok := h.parseOptionalInt(w, r, tenantID, "priority_lte")
		if !ok {
			return
		}

		resp, err := h.service.DocumentWorkQueue(r.Context(), reportingservice.DocumentWorkQueueRequest{
			TenantID:     tenantID,
			DocumentType: r.URL.Query().Get("document_type"),
			SourceModule: r.URL.Query().Get("source_module"),
			Status:       r.URL.Query().Get("status"),
			PriorityLTE:  priority,
			Page:         page,
		})
		h.writeServiceResult(w, r, tenantID, resp, err)

	case PathReconciliationStatus:
		page, ok := h.parsePage(w, r, tenantID)
		if !ok {
			return
		}

		resp, err := h.service.ReconciliationStatus(r.Context(), reportingservice.ReconciliationStatusRequest{
			TenantID:     tenantID,
			ScopeType:    r.URL.Query().Get("scope_type"),
			Status:       r.URL.Query().Get("status"),
			CurrencyCode: r.URL.Query().Get("currency_code"),
			Page:         page,
		})
		h.writeServiceResult(w, r, tenantID, resp, err)

	case PathProjectionState:
		page, ok := h.parsePage(w, r, tenantID)
		if !ok {
			return
		}

		resp, err := h.service.ProjectionState(r.Context(), reportingservice.ProjectionStateRequest{
			TenantID:       tenantID,
			ProjectionName: r.URL.Query().Get("projection_name"),
			Status:         r.URL.Query().Get("status"),
			Page:           page,
		})
		h.writeServiceResult(w, r, tenantID, resp, err)

	default:
		h.writeError(w, r, http.StatusNotFound, tenantID, ErrorCodeRouteNotFound, "route not found")
	}
}

func (h Handler) resolveTenant(w http.ResponseWriter, r *http.Request) (string, bool) {
	authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
	if !strings.HasPrefix(authHeader, "Bearer ") || strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer ")) == "" {
		h.writeError(w, r, http.StatusUnauthorized, "", ErrorCodeAuthRequired, "bearer token is required")
		return "", false
	}

	tenantID := strings.TrimSpace(r.Header.Get("X-Tenant-ID"))
	if tenantID == "" {
		h.writeError(w, r, http.StatusBadRequest, "", ErrorCodeTenantHeaderRequired, "X-Tenant-ID header is required")
		return "", false
	}

	if claimTenantID := tenantClaimFromContext(r.Context()); claimTenantID != "" && claimTenantID != tenantID {
		h.writeError(w, r, http.StatusForbidden, tenantID, ErrorCodeTenantMismatch, "tenant claim and header mismatch")
		return "", false
	}

	return tenantID, true
}

func (h Handler) parsePage(w http.ResponseWriter, r *http.Request, tenantID string) (reportingservice.PageRequest, bool) {
	limit := 0
	rawLimit := strings.TrimSpace(r.URL.Query().Get("limit"))

	if rawLimit != "" {
		parsed, err := strconv.Atoi(rawLimit)
		if err != nil {
			h.writeError(w, r, http.StatusBadRequest, tenantID, ErrorCodeReportingInvalidFilter, "limit must be numeric")
			return reportingservice.PageRequest{}, false
		}

		limit = parsed
	}

	return reportingservice.PageRequest{
		Limit:  limit,
		Cursor: r.URL.Query().Get("cursor"),
	}, true
}

func (h Handler) parseOptionalBool(w http.ResponseWriter, r *http.Request, tenantID string, key string) (*bool, bool) {
	raw := strings.TrimSpace(r.URL.Query().Get(key))
	if raw == "" {
		return nil, true
	}

	parsed, err := strconv.ParseBool(raw)
	if err != nil {
		h.writeError(w, r, http.StatusBadRequest, tenantID, ErrorCodeReportingInvalidFilter, key+" must be boolean")
		return nil, false
	}

	return &parsed, true
}

func (h Handler) parseOptionalInt(w http.ResponseWriter, r *http.Request, tenantID string, key string) (*int, bool) {
	raw := strings.TrimSpace(r.URL.Query().Get(key))
	if raw == "" {
		return nil, true
	}

	parsed, err := strconv.Atoi(raw)
	if err != nil {
		h.writeError(w, r, http.StatusBadRequest, tenantID, ErrorCodeReportingInvalidFilter, key+" must be numeric")
		return nil, false
	}

	return &parsed, true
}

func (h Handler) writeServiceResult(w http.ResponseWriter, r *http.Request, tenantID string, resp reportingservice.QueryResponse, err error) {
	if err != nil {
		status, code, message := mapServiceError(err)
		h.writeError(w, r, status, tenantID, code, message)
		return
	}

	h.writeSuccess(w, r, resp)
}

func (h Handler) writeSuccess(w http.ResponseWriter, r *http.Request, resp reportingservice.QueryResponse) {
	envelope := SuccessEnvelope{
		Status:    "ok",
		RequestID: requestID(r),
		TenantID:  resp.TenantID,
		Data: QueryData{
			QueryName:   resp.Query.Name,
			SourceTable: resp.Query.SourceTable,
			ReadOnly:    resp.Query.ReadOnly,
			ArgCount:    len(resp.Query.Args),
		},
		Meta: ResponseMeta{
			Limit:      resp.Meta.Limit,
			NextCursor: resp.Meta.NextCursor,
			HasMore:    resp.Meta.HasMore,
		},
	}

	writeJSON(w, http.StatusOK, envelope)
}

func (h Handler) writeError(w http.ResponseWriter, r *http.Request, status int, tenantID string, code string, message string) {
	envelope := ErrorEnvelope{
		Status:    "error",
		RequestID: requestID(r),
		TenantID:  tenantID,
		Error: ErrorDetail{
			Code:    code,
			Message: message,
			Details: map[string]any{},
		},
	}

	writeJSON(w, status, envelope)
}

func mapServiceError(err error) (int, string, string) {
	var serviceError reportingservice.ServiceError
	if errors.As(err, &serviceError) {
		switch serviceError.Code {
		case reportingservice.ErrorCodeTenantRequired:
			return http.StatusBadRequest, ErrorCodeTenantHeaderRequired, "tenant_id is required"
		case reportingservice.ErrorCodeTenantInvalid:
			return http.StatusForbidden, ErrorCodeTenantMismatch, "tenant_id is invalid"
		case reportingservice.ErrorCodeInvalidLimit:
			return http.StatusBadRequest, ErrorCodeReportingLimitExceeded, "reporting limit exceeded"
		case reportingservice.ErrorCodeInvalidFilter:
			return http.StatusBadRequest, ErrorCodeReportingInvalidFilter, "reporting filter is invalid"
		default:
			return http.StatusInternalServerError, ErrorCodeReportingQueryError, "reporting query failed"
		}
	}

	return http.StatusInternalServerError, ErrorCodeReportingQueryError, "reporting query failed"
}

func requestID(r *http.Request) string {
	requestID := strings.TrimSpace(r.Header.Get("X-Request-ID"))
	if requestID == "" {
		return "req_unknown"
	}

	return requestID
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}
