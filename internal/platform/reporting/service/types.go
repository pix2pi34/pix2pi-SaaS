package service

import "github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/repository"

// ErrorCode is the service-level reporting error contract.
type ErrorCode string

const (
	ErrorCodeTenantRequired       ErrorCode = "TENANT_REQUIRED"
	ErrorCodeTenantInvalid        ErrorCode = "TENANT_INVALID"
	ErrorCodeInvalidLimit         ErrorCode = "REPORTING_LIMIT_EXCEEDED"
	ErrorCodeInvalidFilter        ErrorCode = "REPORTING_INVALID_FILTER"
	ErrorCodeRepositoryFailure    ErrorCode = "REPORTING_REPOSITORY_ERROR"
	ErrorCodeUnknown              ErrorCode = "REPORTING_UNKNOWN_ERROR"
)

// ServiceError maps repository/domain errors to service-level error codes.
type ServiceError struct {
	Code    ErrorCode
	Message string
	Err     error
}

func (e ServiceError) Error() string {
	if e.Message != "" {
		return e.Message
	}

	return string(e.Code)
}

func (e ServiceError) Unwrap() error {
	return e.Err
}

// PageRequest is the service-facing pagination DTO.
type PageRequest struct {
	Limit  int
	Cursor string
}

// PageMeta is returned with query responses for endpoint/service layers.
type PageMeta struct {
	Limit      int
	NextCursor string
	HasMore    bool
}

// QueryResponse is the service output contract for later handler layers.
type QueryResponse struct {
	TenantID string
	Query    repository.QuerySpec
	Meta     PageMeta
}

// OperationalSummaryRequest asks for the tenant operational summary.
type OperationalSummaryRequest struct {
	TenantID string
}

// DailyMetricsRequest asks for tenant daily operational metrics.
type DailyMetricsRequest struct {
	TenantID string
	FromDate string
	ToDate   string
	Page     PageRequest
}

// InventoryStatusRequest asks for tenant inventory status snapshots.
type InventoryStatusRequest struct {
	TenantID    string
	WarehouseID string
	SKU         string
	AlertOnly   *bool
	Page        PageRequest
}

// DocumentWorkQueueRequest asks for tenant document work queue rows.
type DocumentWorkQueueRequest struct {
	TenantID     string
	DocumentType string
	SourceModule string
	Status       string
	PriorityLTE  *int
	Page         PageRequest
}

// ReconciliationStatusRequest asks for tenant reconciliation snapshots.
type ReconciliationStatusRequest struct {
	TenantID     string
	ScopeType    string
	Status       string
	CurrencyCode string
	Page         PageRequest
}

// ProjectionStateRequest asks for tenant projection state rows.
type ProjectionStateRequest struct {
	TenantID       string
	ProjectionName string
	Status         string
	Page           PageRequest
}
