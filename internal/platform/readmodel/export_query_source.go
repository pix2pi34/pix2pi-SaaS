package readmodel

import (
	"context"
	"errors"
	"fmt"
	"strings"
)

var (
	ErrNilExportRepository    = errors.New("readmodel: nil export repository")
	ErrNilExportService       = errors.New("readmodel: nil export service")
	ErrEmptyExportQuery       = errors.New("readmodel: empty export query name")
	ErrInvalidExportBatchSize = errors.New("readmodel: invalid export batch size")
	ErrInvalidExportFormat    = errors.New("readmodel: invalid export format")
	ErrEmptyExportRecordKey   = errors.New("readmodel: empty export record key")
)

type ExportFormat string

const (
	ExportFormatExcel ExportFormat = "excel"
	ExportFormatPDF   ExportFormat = "pdf"
	ExportFormatCSV   ExportFormat = "csv"
)

type ExportQueryRequest struct {
	TenantID   string
	Projection string
	QueryName  string
	Format     ExportFormat
	BranchID   string
	PeriodKey  string
	BatchSize  int
	Cursor     string
}

func (r ExportQueryRequest) Validate() error {
	if strings.TrimSpace(r.TenantID) == "" {
		return ErrEmptyTenantID
	}
	if strings.TrimSpace(r.Projection) == "" {
		return ErrEmptyProjectionName
	}
	if strings.TrimSpace(r.QueryName) == "" {
		return ErrEmptyExportQuery
	}
	if r.BatchSize <= 0 {
		return ErrInvalidExportBatchSize
	}

	switch r.Format {
	case ExportFormatExcel, ExportFormatPDF, ExportFormatCSV:
	default:
		return ErrInvalidExportFormat
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
	if r.Cursor != "" {
		if err := validateKeyPart(r.Cursor); err != nil {
			return fmt.Errorf("cursor: %w", err)
		}
	}

	return nil
}

type ExportRecord struct {
	RecordKey string
	Columns   map[string]string
}

func (r ExportRecord) Validate() error {
	if strings.TrimSpace(r.RecordKey) == "" {
		return ErrEmptyExportRecordKey
	}
	if err := validateKeyPart(r.RecordKey); err != nil {
		return fmt.Errorf("record key: %w", err)
	}
	return nil
}

type ExportQueryData struct {
	Rows       []ExportRecord
	NextCursor string
}

func (d ExportQueryData) Validate() error {
	for _, row := range d.Rows {
		if err := row.Validate(); err != nil {
			return err
		}
	}
	if d.NextCursor != "" {
		if err := validateKeyPart(d.NextCursor); err != nil {
			return fmt.Errorf("next cursor: %w", err)
		}
	}
	return nil
}

type ExportQueryResult struct {
	TenantID    string
	Projection  string
	QueryName   string
	Format      ExportFormat
	SourceTable string
	Rows        []ExportRecord
	RowCount    int
	NextCursor  string
}

type ExportRepository interface {
	QueryExport(
		ctx context.Context,
		descriptor ProjectionRepositoryDescriptor,
		accessPlan TenantQueryAccessPlan,
		req ExportQueryRequest,
	) (ExportQueryData, error)
}

type ExportQueryService struct {
	store       *ReportingStore
	repo        ExportRepository
	tenantGuard *ReportingTenantGuard
	qualityGate *ReportingQualityGate
}

func NewExportQueryService(store *ReportingStore, repo ExportRepository) (*ExportQueryService, error) {
	if store == nil {
		return nil, ErrNilProjectionContractRegistry
	}
	if repo == nil {
		return nil, ErrNilExportRepository
	}

	guard, err := NewReportingTenantGuard(store)
	if err != nil {
		return nil, err
	}

	return &ExportQueryService{
		store:       store,
		repo:        repo,
		tenantGuard: guard,
		qualityGate: NewReportingQualityGate(),
	}, nil
}

func (s *ExportQueryService) ensureTenantGuard() (*ReportingTenantGuard, error) {
	if s == nil {
		return nil, ErrNilExportService
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

func (s *ExportQueryService) ensureQualityGate() *ReportingQualityGate {
	if s == nil {
		return nil
	}
	if s.qualityGate == nil {
		s.qualityGate = NewReportingQualityGate()
	}
	return s.qualityGate
}

func (s *ExportQueryService) Query(ctx context.Context, req ExportQueryRequest) (ExportQueryResult, error) {
	var zero ExportQueryResult

	if s == nil {
		return zero, ErrNilExportService
	}
	if err := req.Validate(); err != nil {
		return zero, err
	}

	guard, err := s.ensureTenantGuard()
	if err != nil {
		return zero, err
	}

	tenantPlan, err := guard.GuardExportRequest(req)
	if err != nil {
		return zero, err
	}

	desc, err := s.store.ResolveProjectionDescriptor(req.Projection)
	if err != nil {
		return zero, err
	}

	data, err := s.repo.QueryExport(ctx, desc, tenantPlan.AccessPlan, req)
	if err != nil {
		return zero, err
	}
	if err := data.Validate(); err != nil {
		return zero, err
	}

	result := ExportQueryResult{
		TenantID:    req.TenantID,
		Projection:  req.Projection,
		QueryName:   req.QueryName,
		Format:      req.Format,
		SourceTable: desc.FullTableName,
		Rows:        append([]ExportRecord(nil), data.Rows...),
		RowCount:    len(data.Rows),
		NextCursor:  data.NextCursor,
	}

	gate := s.ensureQualityGate()
	if gate == nil {
		return zero, ErrNilExportService
	}

	if err := gate.ValidateExportResult(req, result, tenantPlan); err != nil {
		return zero, err
	}

	return result, nil
}
