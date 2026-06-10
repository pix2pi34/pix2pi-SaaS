package fiscalguard

import "context"

type FiscalPeriodResolver interface {
	ResolvePeriod(ctx context.Context, req ResolvePeriodRequest) (ResolvePeriodResult, error)
}

type FiscalPeriodGuard interface {
	EnsurePostable(ctx context.Context, req PeriodGuardRequest) (PeriodGuardResult, error)
}

type FiscalPeriodProvider interface {
	FindPeriodByPostingDate(ctx context.Context, tenantID string, postingDate string) (FiscalPeriodSnapshot, error)
}
