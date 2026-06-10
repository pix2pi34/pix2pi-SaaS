package readmodel

import (
	"errors"
	"fmt"
	"strings"
)

var (
	ErrNilTenantRepositoryQuery           = errors.New("readmodel: nil tenant repository query")
	ErrEmptySelectClause                  = errors.New("readmodel: empty select clause")
	ErrTenantAccessPlanGuardRequired      = errors.New("readmodel: tenant access plan guard required")
	ErrTenantAccessPlanTargetMissing      = errors.New("readmodel: tenant access plan target missing")
	ErrTenantAccessPlanProjectionMismatch = errors.New("readmodel: tenant access plan projection mismatch")
	ErrTenantAccessPlanSourceMismatch     = errors.New("readmodel: tenant access plan source mismatch")
	ErrTenantAccessPlanColumnMismatch     = errors.New("readmodel: tenant access plan column mismatch")
)

type TenantRepositoryQuery struct {
	ProjectionName string
	SourceTable    string
	TenantColumn   string
	WhereClause    string
	Args           []any
}

func (q TenantRepositoryQuery) Validate() error {
	if strings.TrimSpace(q.ProjectionName) == "" {
		return ErrEmptyProjectionName
	}
	if strings.TrimSpace(q.SourceTable) == "" {
		return ErrSourceTableMismatch
	}
	if strings.TrimSpace(q.TenantColumn) == "" {
		return ErrEmptyTenantColumn
	}
	if strings.TrimSpace(q.WhereClause) == "" {
		return ErrTenantFilterNotEnforced
	}
	if len(q.Args) != 1 {
		return ErrTenantFilterNotEnforced
	}
	return nil
}

func BuildTenantRepositoryQuery(
	target TenantQueryTarget,
	accessPlan TenantQueryAccessPlan,
) (TenantRepositoryQuery, error) {
	if err := target.Validate(); err != nil {
		return TenantRepositoryQuery{}, err
	}

	if !accessPlan.GuardRequired {
		return TenantRepositoryQuery{}, ErrTenantAccessPlanGuardRequired
	}

	if err := accessPlan.Target.Validate(); err != nil {
		return TenantRepositoryQuery{}, ErrTenantAccessPlanTargetMissing
	}

	if err := accessPlan.Validate(); err != nil {
		return TenantRepositoryQuery{}, err
	}

	if target.ProjectionName != accessPlan.Target.ProjectionName {
		return TenantRepositoryQuery{}, ErrTenantAccessPlanProjectionMismatch
	}
	if target.FullTableName != accessPlan.Target.FullTableName {
		return TenantRepositoryQuery{}, ErrTenantAccessPlanSourceMismatch
	}
	if target.TenantColumn != accessPlan.Target.TenantColumn {
		return TenantRepositoryQuery{}, ErrTenantAccessPlanColumnMismatch
	}

	return TenantRepositoryQuery{
		ProjectionName: target.ProjectionName,
		SourceTable:    target.FullTableName,
		TenantColumn:   target.TenantColumn,
		WhereClause:    accessPlan.WhereClause,
		Args:           append([]any(nil), accessPlan.Args...),
	}, nil
}

func BuildTenantFilteredSelectSQL(
	selectClause string,
	target TenantQueryTarget,
	accessPlan TenantQueryAccessPlan,
) (string, []any, error) {
	selectClause = strings.TrimSpace(selectClause)
	if selectClause == "" {
		return "", nil, ErrEmptySelectClause
	}

	query, err := BuildTenantRepositoryQuery(target, accessPlan)
	if err != nil {
		return "", nil, err
	}
	if err := query.Validate(); err != nil {
		return "", nil, err
	}

	sql := fmt.Sprintf(
		"SELECT %s FROM %s WHERE %s",
		selectClause,
		query.SourceTable,
		query.WhereClause,
	)

	return sql, append([]any(nil), query.Args...), nil
}

func BuildDashboardRepositoryQuery(
	desc ProjectionRepositoryDescriptor,
	accessPlan TenantQueryAccessPlan,
) (TenantRepositoryQuery, error) {
	target, err := desc.TenantQueryTarget()
	if err != nil {
		return TenantRepositoryQuery{}, err
	}

	return BuildTenantRepositoryQuery(target, accessPlan)
}

func BuildExportRepositoryQuery(
	desc ProjectionRepositoryDescriptor,
	accessPlan TenantQueryAccessPlan,
) (TenantRepositoryQuery, error) {
	target, err := desc.TenantQueryTarget()
	if err != nil {
		return TenantRepositoryQuery{}, err
	}

	return BuildTenantRepositoryQuery(target, accessPlan)
}
