package readmodel

import (
	"errors"
	"fmt"
	"strings"
)

var (
	ErrNilReportingTenantGuard = errors.New("readmodel: nil reporting tenant guard")
	ErrTenantFilterNotEnforced = errors.New("readmodel: tenant filter not enforced")
	ErrTenantMismatch          = errors.New("readmodel: tenant mismatch")
	ErrProjectionMismatch      = errors.New("readmodel: projection mismatch")
	ErrQueryNameMismatch       = errors.New("readmodel: query name mismatch")
	ErrSourceTableMismatch     = errors.New("readmodel: source table mismatch")
	ErrRecordCountMismatch     = errors.New("readmodel: record count mismatch")
	ErrRowCountMismatch        = errors.New("readmodel: row count mismatch")
	ErrRebuildPlanInvalid      = errors.New("readmodel: rebuild plan invalid")
)

type TenantSafeQueryPlan struct {
	TenantID            string
	Projection          string
	QueryName           string
	SourceTable         string
	TenantColumn        string
	EnforceTenantFilter bool

	QueryTarget TenantQueryTarget
	AccessPlan  TenantQueryAccessPlan
}

func (p TenantSafeQueryPlan) normalize() (TenantSafeQueryPlan, error) {
	normalized := p

	if strings.TrimSpace(normalized.QueryTarget.ProjectionName) == "" &&
		strings.TrimSpace(normalized.Projection) != "" &&
		strings.TrimSpace(normalized.SourceTable) != "" &&
		strings.TrimSpace(normalized.TenantColumn) != "" {
		normalized.QueryTarget = TenantQueryTarget{
			ProjectionName: normalized.Projection,
			TableName:      extractTableNameFromFullTableName(normalized.SourceTable),
			FullTableName:  normalized.SourceTable,
			TenantColumn:   normalized.TenantColumn,
		}
	}

	if strings.TrimSpace(normalized.AccessPlan.TenantID) == "" &&
		strings.TrimSpace(normalized.TenantID) != "" &&
		strings.TrimSpace(normalized.QueryTarget.ProjectionName) != "" {
		accessPlan, err := BuildTenantQueryAccessPlan(
			normalized.TenantID,
			normalized.QueryTarget,
		)
		if err != nil {
			return TenantSafeQueryPlan{}, err
		}
		normalized.AccessPlan = accessPlan
	}

	return normalized, nil
}

func extractTableNameFromFullTableName(fullTableName string) string {
	fullTableName = strings.TrimSpace(fullTableName)
	if fullTableName == "" {
		return ""
	}

	parts := strings.Split(fullTableName, ".")
	if len(parts) == 0 {
		return ""
	}

	return strings.TrimSpace(parts[len(parts)-1])
}

type ReportingTenantGuard struct {
	store *ReportingStore
}

func NewReportingTenantGuard(store *ReportingStore) (*ReportingTenantGuard, error) {
	if store == nil {
		return nil, ErrNilReportingTenantGuard
	}

	return &ReportingTenantGuard{
		store: store,
	}, nil
}

func (g *ReportingTenantGuard) GuardDashboardRequest(req DashboardQueryRequest) (TenantSafeQueryPlan, error) {
	if g == nil {
		return TenantSafeQueryPlan{}, ErrNilReportingTenantGuard
	}
	if err := req.Validate(); err != nil {
		return TenantSafeQueryPlan{}, err
	}

	desc, err := g.store.ResolveProjectionDescriptor(req.Projection)
	if err != nil {
		return TenantSafeQueryPlan{}, err
	}
	if desc.TenantColumn == "" {
		return TenantSafeQueryPlan{}, ErrTenantFilterNotEnforced
	}

	target, err := desc.TenantQueryTarget()
	if err != nil {
		return TenantSafeQueryPlan{}, err
	}

	accessPlan, err := desc.TenantAccessPlan(req.TenantID)
	if err != nil {
		return TenantSafeQueryPlan{}, err
	}

	return TenantSafeQueryPlan{
		TenantID:            req.TenantID,
		Projection:          req.Projection,
		QueryName:           req.QueryName,
		SourceTable:         desc.FullTableName,
		TenantColumn:        desc.TenantColumn,
		EnforceTenantFilter: true,
		QueryTarget:         target,
		AccessPlan:          accessPlan,
	}, nil
}

func (g *ReportingTenantGuard) GuardExportRequest(req ExportQueryRequest) (TenantSafeQueryPlan, error) {
	if g == nil {
		return TenantSafeQueryPlan{}, ErrNilReportingTenantGuard
	}
	if err := req.Validate(); err != nil {
		return TenantSafeQueryPlan{}, err
	}

	desc, err := g.store.ResolveProjectionDescriptor(req.Projection)
	if err != nil {
		return TenantSafeQueryPlan{}, err
	}
	if desc.TenantColumn == "" {
		return TenantSafeQueryPlan{}, ErrTenantFilterNotEnforced
	}

	target, err := desc.TenantQueryTarget()
	if err != nil {
		return TenantSafeQueryPlan{}, err
	}

	accessPlan, err := desc.TenantAccessPlan(req.TenantID)
	if err != nil {
		return TenantSafeQueryPlan{}, err
	}

	return TenantSafeQueryPlan{
		TenantID:            req.TenantID,
		Projection:          req.Projection,
		QueryName:           req.QueryName,
		SourceTable:         desc.FullTableName,
		TenantColumn:        desc.TenantColumn,
		EnforceTenantFilter: true,
		QueryTarget:         target,
		AccessPlan:          accessPlan,
	}, nil
}

type ReportingQualityGate struct{}

func NewReportingQualityGate() *ReportingQualityGate {
	return &ReportingQualityGate{}
}

func (g *ReportingQualityGate) ValidateDashboardResult(
	req DashboardQueryRequest,
	result DashboardQueryResult,
	plan TenantSafeQueryPlan,
) error {
	if g == nil {
		return ErrNilReportingTenantGuard
	}
	if !plan.EnforceTenantFilter {
		return ErrTenantFilterNotEnforced
	}

	normalizedPlan, err := plan.normalize()
	if err != nil {
		return err
	}

	if err := normalizedPlan.QueryTarget.Validate(); err != nil {
		return err
	}
	if err := normalizedPlan.AccessPlan.Validate(); err != nil {
		return err
	}

	if req.TenantID != result.TenantID || req.TenantID != normalizedPlan.TenantID || req.TenantID != normalizedPlan.AccessPlan.TenantID {
		return ErrTenantMismatch
	}
	if req.Projection != result.Projection || req.Projection != normalizedPlan.Projection || req.Projection != normalizedPlan.QueryTarget.ProjectionName {
		return ErrProjectionMismatch
	}
	if req.QueryName != result.QueryName || req.QueryName != normalizedPlan.QueryName {
		return ErrQueryNameMismatch
	}
	if result.SourceTable != normalizedPlan.SourceTable || result.SourceTable != normalizedPlan.QueryTarget.FullTableName {
		return ErrSourceTableMismatch
	}
	if result.RecordsCount != len(result.Records) {
		return ErrRecordCountMismatch
	}

	return nil
}

func (g *ReportingQualityGate) ValidateExportResult(
	req ExportQueryRequest,
	result ExportQueryResult,
	plan TenantSafeQueryPlan,
) error {
	if g == nil {
		return ErrNilReportingTenantGuard
	}
	if !plan.EnforceTenantFilter {
		return ErrTenantFilterNotEnforced
	}

	normalizedPlan, err := plan.normalize()
	if err != nil {
		return err
	}

	if err := normalizedPlan.QueryTarget.Validate(); err != nil {
		return err
	}
	if err := normalizedPlan.AccessPlan.Validate(); err != nil {
		return err
	}

	if req.TenantID != result.TenantID || req.TenantID != normalizedPlan.TenantID || req.TenantID != normalizedPlan.AccessPlan.TenantID {
		return ErrTenantMismatch
	}
	if req.Projection != result.Projection || req.Projection != normalizedPlan.Projection || req.Projection != normalizedPlan.QueryTarget.ProjectionName {
		return ErrProjectionMismatch
	}
	if req.QueryName != result.QueryName || req.QueryName != normalizedPlan.QueryName {
		return ErrQueryNameMismatch
	}
	if result.SourceTable != normalizedPlan.SourceTable || result.SourceTable != normalizedPlan.QueryTarget.FullTableName {
		return ErrSourceTableMismatch
	}
	if result.RowCount != len(result.Rows) {
		return ErrRowCountMismatch
	}

	return nil
}

func (g *ReportingQualityGate) ValidateRebuildPlan(plan ProjectionRebuildPlan) error {
	if g == nil {
		return ErrNilReportingTenantGuard
	}
	if plan.Projection == "" || plan.TableName == "" || plan.FullTableName == "" {
		return ErrRebuildPlanInvalid
	}
	if !plan.SupportsRebuild {
		return fmt.Errorf("%w: rebuild disabled", ErrRebuildPlanInvalid)
	}
	if !plan.RequiresReplay {
		return fmt.Errorf("%w: replay not required", ErrRebuildPlanInvalid)
	}

	switch plan.Mode {
	case RebuildModeTruncateReplay, RebuildModeReplayFromEvent:
		return nil
	default:
		return ErrRebuildPlanInvalid
	}
}
