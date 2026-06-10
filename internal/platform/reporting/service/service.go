package service

import (
	"context"
	"errors"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/repository"
)

// ReadmodelRepository is the dependency inversion boundary between service and repository layers.
type ReadmodelRepository interface {
	OperationalSummary(tenantID string) (repository.QuerySpec, error)
	DailyMetrics(filter repository.DailyMetricsFilter) (repository.QuerySpec, error)
	InventoryStatus(filter repository.InventoryStatusFilter) (repository.QuerySpec, error)
	DocumentWorkQueue(filter repository.DocumentWorkQueueFilter) (repository.QuerySpec, error)
	ReconciliationStatus(filter repository.ReconciliationStatusFilter) (repository.QuerySpec, error)
	ProjectionState(filter repository.ProjectionStateFilter) (repository.QuerySpec, error)
}

// Service coordinates validation and repository query-spec creation.
type Service struct {
	repo ReadmodelRepository
}

// New creates a reporting service. If repo is nil, it uses the default repository builder.
func New(repo ReadmodelRepository) Service {
	if repo == nil {
		repo = repository.New()
	}

	return Service{repo: repo}
}

// OperationalSummary builds the operational summary query response.
func (s Service) OperationalSummary(ctx context.Context, req OperationalSummaryRequest) (QueryResponse, error) {
	_ = ctx

	if err := validateTenant(req.TenantID); err != nil {
		return QueryResponse{}, err
	}

	spec, err := s.repo.OperationalSummary(req.TenantID)
	if err != nil {
		return QueryResponse{}, mapRepositoryError(err)
	}

	return response(req.TenantID, spec), nil
}

// DailyMetrics builds the daily metrics query response.
func (s Service) DailyMetrics(ctx context.Context, req DailyMetricsRequest) (QueryResponse, error) {
	_ = ctx

	if err := validateTenant(req.TenantID); err != nil {
		return QueryResponse{}, err
	}

	page, err := normalizePage(req.Page)
	if err != nil {
		return QueryResponse{}, err
	}

	spec, err := s.repo.DailyMetrics(repository.DailyMetricsFilter{
		TenantID: req.TenantID,
		FromDate: req.FromDate,
		ToDate:   req.ToDate,
		Page:     page,
	})
	if err != nil {
		return QueryResponse{}, mapRepositoryError(err)
	}

	return response(req.TenantID, spec), nil
}

// InventoryStatus builds the inventory status query response.
func (s Service) InventoryStatus(ctx context.Context, req InventoryStatusRequest) (QueryResponse, error) {
	_ = ctx

	if err := validateTenant(req.TenantID); err != nil {
		return QueryResponse{}, err
	}

	page, err := normalizePage(req.Page)
	if err != nil {
		return QueryResponse{}, err
	}

	spec, err := s.repo.InventoryStatus(repository.InventoryStatusFilter{
		TenantID:    req.TenantID,
		WarehouseID: req.WarehouseID,
		SKU:         req.SKU,
		AlertOnly:   req.AlertOnly,
		Page:        page,
	})
	if err != nil {
		return QueryResponse{}, mapRepositoryError(err)
	}

	return response(req.TenantID, spec), nil
}

// DocumentWorkQueue builds the document work queue query response.
func (s Service) DocumentWorkQueue(ctx context.Context, req DocumentWorkQueueRequest) (QueryResponse, error) {
	_ = ctx

	if err := validateTenant(req.TenantID); err != nil {
		return QueryResponse{}, err
	}

	page, err := normalizePage(req.Page)
	if err != nil {
		return QueryResponse{}, err
	}

	spec, err := s.repo.DocumentWorkQueue(repository.DocumentWorkQueueFilter{
		TenantID:     req.TenantID,
		DocumentType: req.DocumentType,
		SourceModule: req.SourceModule,
		Status:       req.Status,
		PriorityLTE:  req.PriorityLTE,
		Page:         page,
	})
	if err != nil {
		return QueryResponse{}, mapRepositoryError(err)
	}

	return response(req.TenantID, spec), nil
}

// ReconciliationStatus builds the reconciliation status query response.
func (s Service) ReconciliationStatus(ctx context.Context, req ReconciliationStatusRequest) (QueryResponse, error) {
	_ = ctx

	if err := validateTenant(req.TenantID); err != nil {
		return QueryResponse{}, err
	}

	page, err := normalizePage(req.Page)
	if err != nil {
		return QueryResponse{}, err
	}

	spec, err := s.repo.ReconciliationStatus(repository.ReconciliationStatusFilter{
		TenantID:     req.TenantID,
		ScopeType:    req.ScopeType,
		Status:       req.Status,
		CurrencyCode: req.CurrencyCode,
		Page:         page,
	})
	if err != nil {
		return QueryResponse{}, mapRepositoryError(err)
	}

	return response(req.TenantID, spec), nil
}

// ProjectionState builds the projection state query response.
func (s Service) ProjectionState(ctx context.Context, req ProjectionStateRequest) (QueryResponse, error) {
	_ = ctx

	if err := validateTenant(req.TenantID); err != nil {
		return QueryResponse{}, err
	}

	page, err := normalizePage(req.Page)
	if err != nil {
		return QueryResponse{}, err
	}

	spec, err := s.repo.ProjectionState(repository.ProjectionStateFilter{
		TenantID:       req.TenantID,
		ProjectionName: req.ProjectionName,
		Status:         req.Status,
		Page:           page,
	})
	if err != nil {
		return QueryResponse{}, mapRepositoryError(err)
	}

	return response(req.TenantID, spec), nil
}

func validateTenant(tenantID string) error {
	if err := repository.ValidateTenantID(tenantID); err != nil {
		return mapRepositoryError(err)
	}

	return nil
}

func normalizePage(page PageRequest) (repository.PageRequest, error) {
	normalized, err := repository.NormalizePage(repository.PageRequest{
		Limit:  page.Limit,
		Cursor: page.Cursor,
	})
	if err != nil {
		return repository.PageRequest{}, mapRepositoryError(err)
	}

	return normalized, nil
}

func response(tenantID string, spec repository.QuerySpec) QueryResponse {
	return QueryResponse{
		TenantID: tenantID,
		Query:    spec,
		Meta: PageMeta{
			Limit:      spec.Limit,
			NextCursor: "",
			HasMore:    false,
		},
	}
}

func mapRepositoryError(err error) error {
	if err == nil {
		return nil
	}

	switch {
	case errors.Is(err, repository.ErrTenantRequired):
		return ServiceError{
			Code:    ErrorCodeTenantRequired,
			Message: "tenant_id is required",
			Err:     err,
		}
	case errors.Is(err, repository.ErrInvalidTenant):
		return ServiceError{
			Code:    ErrorCodeTenantInvalid,
			Message: "tenant_id is invalid",
			Err:     err,
		}
	case errors.Is(err, repository.ErrInvalidLimit):
		return ServiceError{
			Code:    ErrorCodeInvalidLimit,
			Message: "reporting limit exceeded",
			Err:     err,
		}
	case errors.Is(err, repository.ErrInvalidDate):
		return ServiceError{
			Code:    ErrorCodeInvalidFilter,
			Message: "reporting filter is invalid",
			Err:     err,
		}
	default:
		return ServiceError{
			Code:    ErrorCodeRepositoryFailure,
			Message: "reporting repository failed",
			Err:     err,
		}
	}
}
