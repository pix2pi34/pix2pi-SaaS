package fiscalguard

import (
	"context"
)

var _ FiscalPeriodResolver = (*DefaultFiscalGuard)(nil)
var _ FiscalPeriodGuard = (*DefaultFiscalGuard)(nil)

type DefaultFiscalGuard struct {
	provider FiscalPeriodProvider
}

func NewDefaultFiscalGuard(provider FiscalPeriodProvider) *DefaultFiscalGuard {
	return &DefaultFiscalGuard{
		provider: provider,
	}
}

func (g *DefaultFiscalGuard) ResolvePeriod(ctx context.Context, req ResolvePeriodRequest) (ResolvePeriodResult, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return ResolvePeriodResult{}, ctx.Err()
	default:
	}

	if err := ValidateResolvePeriodRequest(req); err != nil {
		return ResolvePeriodResult{}, err
	}

	if g.provider == nil {
		return ResolvePeriodResult{}, ErrPeriodNotFound
	}

	period, err := g.provider.FindPeriodByPostingDate(ctx, req.TenantID, dateOnly(req.PostingDate).Format("2006-01-02"))
	if err != nil {
		return ResolvePeriodResult{}, err
	}

	return BuildResolvePeriodResult(req, period)
}

func (g *DefaultFiscalGuard) EnsurePostable(ctx context.Context, req PeriodGuardRequest) (PeriodGuardResult, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return PeriodGuardResult{}, ctx.Err()
	default:
	}

	return EnsurePeriodOpen(req)
}
