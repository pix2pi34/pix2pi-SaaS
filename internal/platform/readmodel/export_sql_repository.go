package readmodel

import (
	"context"
	"errors"
	"fmt"
	"strings"
)

var (
	ErrNilExportRowExecutor   = errors.New("readmodel: nil export row executor")
	ErrNilExportSQLRepository = errors.New("readmodel: nil export sql repository")
)

const DefaultExportSelectClause = "*"

type ExportRowExecutor interface {
	QueryExportRows(ctx context.Context, sql string, args []any) (ExportQueryData, error)
}

type ExportSQLRepository struct {
	executor     ExportRowExecutor
	selectClause string
}

func NewExportSQLRepository(
	executor ExportRowExecutor,
) (*ExportSQLRepository, error) {
	if executor == nil {
		return nil, ErrNilExportRowExecutor
	}

	return &ExportSQLRepository{
		executor:     executor,
		selectClause: DefaultExportSelectClause,
	}, nil
}

func (r *ExportSQLRepository) WithSelectClause(
	selectClause string,
) *ExportSQLRepository {
	if r == nil {
		return nil
	}

	clone := *r
	clone.selectClause = strings.TrimSpace(selectClause)
	return &clone
}

func (r *ExportSQLRepository) QueryExport(
	ctx context.Context,
	descriptor ProjectionRepositoryDescriptor,
	accessPlan TenantQueryAccessPlan,
	req ExportQueryRequest,
) (ExportQueryData, error) {
	var zero ExportQueryData

	if r == nil {
		return zero, ErrNilExportSQLRepository
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
		selectClause = DefaultExportSelectClause
	}

	sql, args, err := BuildTenantFilteredSelectSQL(
		selectClause,
		target,
		accessPlan,
	)
	if err != nil {
		return zero, err
	}

	sql = fmt.Sprintf("%s LIMIT %d", sql, req.BatchSize)

	data, err := r.executor.QueryExportRows(ctx, sql, args)
	if err != nil {
		return zero, err
	}
	if err := data.Validate(); err != nil {
		return zero, err
	}

	return data, nil
}
