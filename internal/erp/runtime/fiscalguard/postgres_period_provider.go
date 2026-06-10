package fiscalguard

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ FiscalPeriodProvider = (*PostgresFiscalPeriodProvider)(nil)

type PostgresFiscalPeriodProvider struct {
	pool *pgxpool.Pool
}

func NewPostgresFiscalPeriodProvider(pool *pgxpool.Pool) *PostgresFiscalPeriodProvider {
	return &PostgresFiscalPeriodProvider{
		pool: pool,
	}
}

func (p *PostgresFiscalPeriodProvider) FindPeriodByPostingDate(ctx context.Context, tenantID string, postingDate string) (FiscalPeriodSnapshot, error) {
	if strings.TrimSpace(tenantID) == "" {
		return FiscalPeriodSnapshot{}, ErrTenantRequired
	}

	if strings.TrimSpace(postingDate) == "" {
		return FiscalPeriodSnapshot{}, ErrPostingDateRequired
	}

	parsedPostingDate, err := time.Parse("2006-01-02", strings.TrimSpace(postingDate))
	if err != nil {
		return FiscalPeriodSnapshot{}, ErrPostingDateRequired
	}

	tx, err := p.pool.Begin(ctx)
	if err != nil {
		return FiscalPeriodSnapshot{}, err
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		return FiscalPeriodSnapshot{}, err
	}

	row := tx.QueryRow(ctx, `
SELECT
    tenant_id,
    fiscal_year,
    fiscal_period,
    period_no,
    period_start_date,
    period_end_date,
    status
FROM erp_fiscal_periods
WHERE tenant_id = $1
  AND period_start_date <= $2
  AND period_end_date >= $2
  AND deleted_at IS NULL
ORDER BY period_start_date DESC
LIMIT 1;
`, tenantID, parsedPostingDate)

	period, err := scanRuntimeFiscalPeriodSnapshot(row)
	if err != nil {
		return FiscalPeriodSnapshot{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return FiscalPeriodSnapshot{}, err
	}

	return period, nil
}

type runtimeFiscalPeriodScanner interface {
	Scan(dest ...any) error
}

func scanRuntimeFiscalPeriodSnapshot(scanner runtimeFiscalPeriodScanner) (FiscalPeriodSnapshot, error) {
	var period FiscalPeriodSnapshot
	var startDate pgtype.Date
	var endDate pgtype.Date
	var status string

	err := scanner.Scan(
		&period.TenantID,
		&period.FiscalYear,
		&period.FiscalPeriod,
		&period.PeriodNo,
		&startDate,
		&endDate,
		&status,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return FiscalPeriodSnapshot{}, ErrPeriodNotFound
	}

	if err != nil {
		return FiscalPeriodSnapshot{}, err
	}

	if startDate.Valid {
		period.PeriodStartDate = startDate.Time
	}

	if endDate.Valid {
		period.PeriodEndDate = endDate.Time
	}

	period.Status = FiscalPeriodStatus(status)

	return period, nil
}
