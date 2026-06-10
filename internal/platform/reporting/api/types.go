package api

const (
	PathOperationalSummary   = "/api/v1/reporting/operational/summary"
	PathDailyMetrics         = "/api/v1/reporting/operational/daily-metrics"
	PathInventoryStatus      = "/api/v1/reporting/inventory/status"
	PathDocumentWorkQueue    = "/api/v1/reporting/documents/work-queue"
	PathReconciliationStatus = "/api/v1/reporting/reconciliation/status"
	PathProjectionState      = "/api/v1/reporting/projections/state"
)

const (
	ErrorCodeAuthRequired          = "AUTH_REQUIRED"
	ErrorCodeTenantHeaderRequired  = "TENANT_HEADER_REQUIRED"
	ErrorCodeTenantMismatch        = "TENANT_MISMATCH"
	ErrorCodeReportingInvalidFilter = "REPORTING_INVALID_FILTER"
	ErrorCodeReportingLimitExceeded = "REPORTING_LIMIT_EXCEEDED"
	ErrorCodeReportingQueryError    = "REPORTING_QUERY_ERROR"
	ErrorCodeMethodNotAllowed       = "METHOD_NOT_ALLOWED"
	ErrorCodeRouteNotFound          = "ROUTE_NOT_FOUND"
)

// QueryData is intentionally safe: it does not expose raw SQL/query text.
type QueryData struct {
	QueryName   string `json:"query_name"`
	SourceTable string `json:"source_table"`
	ReadOnly    bool   `json:"read_only"`
	ArgCount    int    `json:"arg_count"`
}

type SuccessEnvelope struct {
	Status    string      `json:"status"`
	RequestID string      `json:"request_id"`
	TenantID  string      `json:"tenant_id"`
	Data      QueryData   `json:"data"`
	Meta      ResponseMeta `json:"meta"`
}

type ResponseMeta struct {
	Limit      int    `json:"limit"`
	NextCursor string `json:"next_cursor"`
	HasMore    bool   `json:"has_more"`
}

type ErrorEnvelope struct {
	Status    string      `json:"status"`
	RequestID string      `json:"request_id"`
	TenantID  string      `json:"tenant_id,omitempty"`
	Error     ErrorDetail `json:"error"`
}

type ErrorDetail struct {
	Code    string         `json:"code"`
	Message string         `json:"message"`
	Details map[string]any `json:"details"`
}
