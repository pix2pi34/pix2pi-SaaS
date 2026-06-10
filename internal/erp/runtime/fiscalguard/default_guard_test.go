package fiscalguard

import (
	"context"
	"errors"
	"testing"
	"time"
)

type fakeFiscalPeriodProvider struct {
	period FiscalPeriodSnapshot
	err    error

	called    bool
	gotTenant string
	gotDate   string
}

func (p *fakeFiscalPeriodProvider) FindPeriodByPostingDate(ctx context.Context, tenantID string, postingDate string) (FiscalPeriodSnapshot, error) {
	p.called = true
	p.gotTenant = tenantID
	p.gotDate = postingDate

	if p.err != nil {
		return FiscalPeriodSnapshot{}, p.err
	}

	return p.period, nil
}

func validDefaultGuardResolveRequest() ResolvePeriodRequest {
	return ResolvePeriodRequest{
		TenantID:    "tenant_7",
		PostingDate: time.Date(2026, 4, 26, 13, 45, 0, 0, time.UTC),
	}
}

func validDefaultGuardPeriodSnapshot() FiscalPeriodSnapshot {
	return FiscalPeriodSnapshot{
		TenantID:        "tenant_7",
		FiscalYear:      2026,
		FiscalPeriod:    "2026-04",
		PeriodNo:        4,
		PeriodStartDate: time.Date(2026, 4, 1, 0, 0, 0, 0, time.UTC),
		PeriodEndDate:   time.Date(2026, 4, 30, 0, 0, 0, 0, time.UTC),
		Status:          FiscalPeriodStatusOpen,
	}
}

func TestDefaultFiscalGuardResolvePeriodSuccess(t *testing.T) {
	provider := &fakeFiscalPeriodProvider{
		period: validDefaultGuardPeriodSnapshot(),
	}

	guard := NewDefaultFiscalGuard(provider)

	result, err := guard.ResolvePeriod(context.Background(), validDefaultGuardResolveRequest())
	if err != nil {
		t.Fatalf("expected resolve success, got %v", err)
	}

	if !provider.called {
		t.Fatal("expected provider to be called")
	}

	if provider.gotTenant != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", provider.gotTenant)
	}

	if provider.gotDate != "2026-04-26" {
		t.Fatalf("expected posting date 2026-04-26, got %s", provider.gotDate)
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}

	if result.FiscalYear != 2026 {
		t.Fatalf("expected fiscal year 2026, got %d", result.FiscalYear)
	}

	if result.FiscalPeriod != "2026-04" {
		t.Fatalf("expected fiscal period 2026-04, got %s", result.FiscalPeriod)
	}

	if result.Status != FiscalPeriodStatusOpen {
		t.Fatalf("expected open status, got %s", result.Status)
	}
}

func TestDefaultFiscalGuardResolvePeriodValidationFailure(t *testing.T) {
	provider := &fakeFiscalPeriodProvider{
		period: validDefaultGuardPeriodSnapshot(),
	}

	guard := NewDefaultFiscalGuard(provider)
	req := validDefaultGuardResolveRequest()
	req.TenantID = ""

	_, err := guard.ResolvePeriod(context.Background(), req)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}

	if provider.called {
		t.Fatal("provider should not be called on validation failure")
	}
}

func TestDefaultFiscalGuardResolvePeriodProviderMissing(t *testing.T) {
	guard := NewDefaultFiscalGuard(nil)

	_, err := guard.ResolvePeriod(context.Background(), validDefaultGuardResolveRequest())
	if !errors.Is(err, ErrPeriodNotFound) {
		t.Fatalf("expected ErrPeriodNotFound, got %v", err)
	}
}

func TestDefaultFiscalGuardResolvePeriodProviderError(t *testing.T) {
	provider := &fakeFiscalPeriodProvider{
		err: ErrPeriodNotFound,
	}

	guard := NewDefaultFiscalGuard(provider)

	_, err := guard.ResolvePeriod(context.Background(), validDefaultGuardResolveRequest())
	if !errors.Is(err, ErrPeriodNotFound) {
		t.Fatalf("expected ErrPeriodNotFound, got %v", err)
	}
}

func TestDefaultFiscalGuardResolvePeriodContextCancelled(t *testing.T) {
	provider := &fakeFiscalPeriodProvider{
		period: validDefaultGuardPeriodSnapshot(),
	}

	guard := NewDefaultFiscalGuard(provider)

	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := guard.ResolvePeriod(ctx, validDefaultGuardResolveRequest())
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("expected context.Canceled, got %v", err)
	}
}

func TestDefaultFiscalGuardEnsurePostableSuccess(t *testing.T) {
	guard := NewDefaultFiscalGuard(nil)

	result, err := guard.EnsurePostable(context.Background(), PeriodGuardRequest{
		TenantID:     "tenant_7",
		FiscalYear:   2026,
		FiscalPeriod: "2026-04",
		PostingDate:  time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC),
		Status:       FiscalPeriodStatusOpen,
	})
	if err != nil {
		t.Fatalf("expected postable success, got %v", err)
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}
}

func TestDefaultFiscalGuardEnsurePostableLocked(t *testing.T) {
	guard := NewDefaultFiscalGuard(nil)

	_, err := guard.EnsurePostable(context.Background(), PeriodGuardRequest{
		TenantID:     "tenant_7",
		FiscalYear:   2026,
		FiscalPeriod: "2026-04",
		PostingDate:  time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC),
		Status:       FiscalPeriodStatusLocked,
	})
	if !errors.Is(err, ErrPeriodLocked) {
		t.Fatalf("expected ErrPeriodLocked, got %v", err)
	}
}

func TestDefaultFiscalGuardEnsurePostableClosed(t *testing.T) {
	guard := NewDefaultFiscalGuard(nil)

	_, err := guard.EnsurePostable(context.Background(), PeriodGuardRequest{
		TenantID:     "tenant_7",
		FiscalYear:   2026,
		FiscalPeriod: "2026-04",
		PostingDate:  time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC),
		Status:       FiscalPeriodStatusClosed,
	})
	if !errors.Is(err, ErrPeriodClosed) {
		t.Fatalf("expected ErrPeriodClosed, got %v", err)
	}
}

func TestDefaultFiscalGuardEnsurePostableContextCancelled(t *testing.T) {
	guard := NewDefaultFiscalGuard(nil)

	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := guard.EnsurePostable(ctx, PeriodGuardRequest{
		TenantID:     "tenant_7",
		FiscalYear:   2026,
		FiscalPeriod: "2026-04",
		PostingDate:  time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC),
		Status:       FiscalPeriodStatusOpen,
	})
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("expected context.Canceled, got %v", err)
	}
}
