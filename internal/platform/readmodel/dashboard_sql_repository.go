package readmodel

import (
	"context"
	"errors"
	"fmt"
	"strings"
)

var (
	ErrNilDashboardRowExecutor   = errors.New("readmodel: nil dashboard row executor")
	ErrNilDashboardSQLRepository = errors.New("readmodel: nil dashboard sql repository")
)

const DefaultDashboardSelectClause = "metric_key, label, value, sort_order"

type DashboardRowExecutor interface {
	QueryDashboardRows(ctx context.Context, sql string, args []any) ([]DashboardCard, error)
}

type DashboardSQLRepository struct {
	executor     DashboardRowExecutor
	selectClause string
}

func NewDashboardSQLRepository(
	executor DashboardRowExecutor,
) (*DashboardSQLRepository, error) {
	if executor == nil {
		return nil, ErrNilDashboardRowExecutor
	}

	return &DashboardSQLRepository{
		executor:     executor,
		selectClause: DefaultDashboardSelectClause,
	}, nil
}

func (r *DashboardSQLRepository) WithSelectClause(
	selectClause string,
) *DashboardSQLRepository {
	if r == nil {
		return nil
	}

	clone := *r
	clone.selectClause = strings.TrimSpace(selectClause)
	return &clone
}

func (r *DashboardSQLRepository) QueryDashboard(
	ctx context.Context,
	descriptor ProjectionRepositoryDescriptor,
	accessPlan TenantQueryAccessPlan,
	req DashboardQueryRequest,
) (DashboardQueryData, error) {
	var zero DashboardQueryData

	if r == nil {
		return zero, ErrNilDashboardSQLRepository
	}
	if err := req.Validate(); err != nil {
		return zero, err
	}

	target, err := descriptor.TenantQueryTarget()
	if err != nil {
		return zero, err
	}

	selectClause := strings.TrimSpace(r.selectClause)
	if selectClause == "" {
		selectClause = DefaultDashboardSelectClause
	}

	sql, args, err := BuildTenantFilteredSelectSQL(
		selectClause,
		target,
		accessPlan,
	)
	if err != nil {
		return zero, err
	}

	sql = fmt.Sprintf("%s LIMIT %d", sql, req.Limit)

	rows, err := r.executor.QueryDashboardRows(ctx, sql, args)
	if err != nil {
		return zero, err
	}

	data := DashboardQueryData{
		Cards: append([]DashboardCard(nil), rows...),
	}
	if err := data.Validate(); err != nil {
		return zero, err
	}

	return data, nil
}
