package readmodel

import (
	"context"
	"errors"
	"fmt"
	"strings"
)

var (
	ErrNilDashboardRepository = errors.New("readmodel: nil dashboard repository")
	ErrNilDashboardService    = errors.New("readmodel: nil dashboard service")
	ErrEmptyDashboardQuery    = errors.New("readmodel: empty dashboard query name")
	ErrInvalidDashboardLimit  = errors.New("readmodel: invalid dashboard limit")
	ErrEmptyMetricKey         = errors.New("readmodel: empty metric key")
)

type DashboardQueryRequest struct {
	TenantID   string
	Projection string
	QueryName  string
	BranchID   string
	PeriodKey  string
	Limit      int
}

func (r DashboardQueryRequest) Validate() error {
	if strings.TrimSpace(r.TenantID) == "" {
		return ErrEmptyTenantID
	}
	if strings.TrimSpace(r.Projection) == "" {
		return ErrEmptyProjectionName
	}
	if strings.TrimSpace(r.QueryName) == "" {
		return ErrEmptyDashboardQuery
	}
	if r.Limit <= 0 {
		return ErrInvalidDashboardLimit
	}
	if err := validateKeyPart(r.TenantID); err != nil {
		return fmt.Errorf("tenant id: %w", err)
	}
	if err := validateKeyPart(r.Projection); err != nil {
		return fmt.Errorf("projection: %w", err)
	}
	if err := validateKeyPart(r.QueryName); err != nil {
		return fmt.Errorf("query name: %w", err)
	}
	if r.BranchID != "" {
		if err := validateKeyPart(r.BranchID); err != nil {
			return fmt.Errorf("branch id: %w", err)
		}
	}
	if r.PeriodKey != "" {
		if err := validateKeyPart(r.PeriodKey); err != nil {
			return fmt.Errorf("period key: %w", err)
		}
	}
	return nil
}

type DashboardCard struct {
	MetricKey string
	Label     string
	Value     float64
	SortOrder int
}

func (c DashboardCard) Validate() error {
	if strings.TrimSpace(c.MetricKey) == "" {
		return ErrEmptyMetricKey
	}
	if err := validateKeyPart(c.MetricKey); err != nil {
		return fmt.Errorf("metric key: %w", err)
	}
	return nil
}

type DashboardQueryData struct {
	Cards []DashboardCard
}

func (d DashboardQueryData) Validate() error {
	for _, card := range d.Cards {
		if err := card.Validate(); err != nil {
			return err
		}
	}
	return nil
}

type DashboardQueryResult struct {
	TenantID     string
	Projection   string
	QueryName    string
	SourceTable  string
	Records      []DashboardCard
	RecordsCount int
}

type DashboardRepository interface {
	QueryDashboard(
		ctx context.Context,
		descriptor ProjectionRepositoryDescriptor,
		accessPlan TenantQueryAccessPlan,
		req DashboardQueryRequest,
	) (DashboardQueryData, error)
}

type DashboardQueryService struct {
	store       *ReportingStore
	repo        DashboardRepository
	tenantGuard *ReportingTenantGuard
	qualityGate *ReportingQualityGate
}

func NewDashboardQueryService(store *ReportingStore, repo DashboardRepository) (*DashboardQueryService, error) {
	if store == nil {
		return nil, ErrNilProjectionContractRegistry
	}
	if repo == nil {
		return nil, ErrNilDashboardRepository
	}

	guard, err := NewReportingTenantGuard(store)
	if err != nil {
		return nil, err
	}

	return &DashboardQueryService{
		store:       store,
		repo:        repo,
		tenantGuard: guard,
		qualityGate: NewReportingQualityGate(),
	}, nil
}

func (s *DashboardQueryService) ensureTenantGuard() (*ReportingTenantGuard, error) {
	if s == nil {
		return nil, ErrNilDashboardService
	}
	if s.tenantGuard != nil {
		return s.tenantGuard, nil
	}

	guard, err := NewReportingTenantGuard(s.store)
	if err != nil {
		return nil, err
	}

	s.tenantGuard = guard
	return s.tenantGuard, nil
}

func (s *DashboardQueryService) ensureQualityGate() *ReportingQualityGate {
	if s == nil {
		return nil
	}
	if s.qualityGate == nil {
		s.qualityGate = NewReportingQualityGate()
	}
	return s.qualityGate
}

func (s *DashboardQueryService) Query(ctx context.Context, req DashboardQueryRequest) (DashboardQueryResult, error) {
	var zero DashboardQueryResult

	if s == nil {
		return zero, ErrNilDashboardService
	}
	if err := req.Validate(); err != nil {
		return zero, err
	}

	guard, err := s.ensureTenantGuard()
	if err != nil {
		return zero, err
	}

	tenantPlan, err := guard.GuardDashboardRequest(req)
	if err != nil {
		return zero, err
	}

	desc, err := s.store.ResolveProjectionDescriptor(req.Projection)
	if err != nil {
		return zero, err
	}

	data, err := s.repo.QueryDashboard(ctx, desc, tenantPlan.AccessPlan, req)
	if err != nil {
		return zero, err
	}
	if err := data.Validate(); err != nil {
		return zero, err
	}

	result := DashboardQueryResult{
		TenantID:     req.TenantID,
		Projection:   req.Projection,
		QueryName:    req.QueryName,
		SourceTable:  desc.FullTableName,
		Records:      append([]DashboardCard(nil), data.Cards...),
		RecordsCount: len(data.Cards),
	}

	gate := s.ensureQualityGate()
	if gate == nil {
		return zero, ErrNilDashboardService
	}

	if err := gate.ValidateDashboardResult(req, result, tenantPlan); err != nil {
		return zero, err
	}

	return result, nil
}
