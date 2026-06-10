package fiscalguard

import (
	"errors"
	"testing"
	"time"
)

func validResolveRequest() ResolvePeriodRequest {
	return ResolvePeriodRequest{
		TenantID:    "tenant_7",
		PostingDate: time.Date(2026, 4, 26, 13, 30, 0, 0, time.UTC),
	}
}

func validPeriodSnapshot() FiscalPeriodSnapshot {
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

func TestValidateResolvePeriodRequestSuccess(t *testing.T) {
	err := ValidateResolvePeriodRequest(validResolveRequest())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateResolvePeriodRequestTenantRequired(t *testing.T) {
	req := validResolveRequest()
	req.TenantID = ""

	err := ValidateResolvePeriodRequest(req)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateResolvePeriodRequestPostingDateRequired(t *testing.T) {
	req := validResolveRequest()
	req.PostingDate = time.Time{}

	err := ValidateResolvePeriodRequest(req)
	if !errors.Is(err, ErrPostingDateRequired) {
		t.Fatalf("expected ErrPostingDateRequired, got %v", err)
	}
}

func TestValidateFiscalPeriodSnapshotSuccess(t *testing.T) {
	err := ValidateFiscalPeriodSnapshot(validPeriodSnapshot())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateFiscalPeriodSnapshotFiscalYearInvalid(t *testing.T) {
	period := validPeriodSnapshot()
	period.FiscalYear = 1999

	err := ValidateFiscalPeriodSnapshot(period)
	if !errors.Is(err, ErrFiscalYearInvalid) {
		t.Fatalf("expected ErrFiscalYearInvalid, got %v", err)
	}
}

func TestValidateFiscalPeriodSnapshotDateRangeInvalid(t *testing.T) {
	period := validPeriodSnapshot()
	period.PeriodStartDate = time.Date(2026, 5, 1, 0, 0, 0, 0, time.UTC)
	period.PeriodEndDate = time.Date(2026, 4, 30, 0, 0, 0, 0, time.UTC)

	err := ValidateFiscalPeriodSnapshot(period)
	if !errors.Is(err, ErrPeriodDateRangeInvalid) {
		t.Fatalf("expected ErrPeriodDateRangeInvalid, got %v", err)
	}
}

func TestBuildResolvePeriodResultSuccess(t *testing.T) {
	result, err := BuildResolvePeriodResult(validResolveRequest(), validPeriodSnapshot())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}

	if result.FiscalYear != 2026 {
		t.Fatalf("expected fiscal_year 2026, got %d", result.FiscalYear)
	}

	if result.FiscalPeriod != "2026-04" {
		t.Fatalf("expected fiscal_period 2026-04, got %s", result.FiscalPeriod)
	}

	if result.PeriodNo != 4 {
		t.Fatalf("expected period_no 4, got %d", result.PeriodNo)
	}
}

func TestBuildResolvePeriodResultTenantMismatch(t *testing.T) {
	period := validPeriodSnapshot()
	period.TenantID = "tenant_99"

	_, err := BuildResolvePeriodResult(validResolveRequest(), period)
	if !errors.Is(err, ErrPeriodNotFound) {
		t.Fatalf("expected ErrPeriodNotFound, got %v", err)
	}
}

func TestBuildResolvePeriodResultPostingDateOutOfRange(t *testing.T) {
	req := validResolveRequest()
	req.PostingDate = time.Date(2026, 5, 1, 0, 0, 0, 0, time.UTC)

	_, err := BuildResolvePeriodResult(req, validPeriodSnapshot())
	if !errors.Is(err, ErrPostingDateOutOfRange) {
		t.Fatalf("expected ErrPostingDateOutOfRange, got %v", err)
	}
}

func TestEnsurePeriodOpenSuccess(t *testing.T) {
	req := PeriodGuardRequest{
		TenantID:     "tenant_7",
		FiscalYear:   2026,
		FiscalPeriod: "2026-04",
		PostingDate:  time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC),
		Status:       FiscalPeriodStatusOpen,
	}

	result, err := EnsurePeriodOpen(req)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}
}

func TestEnsurePeriodOpenLocked(t *testing.T) {
	req := PeriodGuardRequest{
		TenantID:     "tenant_7",
		FiscalYear:   2026,
		FiscalPeriod: "2026-04",
		PostingDate:  time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC),
		Status:       FiscalPeriodStatusLocked,
	}

	_, err := EnsurePeriodOpen(req)
	if !errors.Is(err, ErrPeriodLocked) {
		t.Fatalf("expected ErrPeriodLocked, got %v", err)
	}
}

func TestEnsurePeriodOpenClosed(t *testing.T) {
	req := PeriodGuardRequest{
		TenantID:     "tenant_7",
		FiscalYear:   2026,
		FiscalPeriod: "2026-04",
		PostingDate:  time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC),
		Status:       FiscalPeriodStatusClosed,
	}

	_, err := EnsurePeriodOpen(req)
	if !errors.Is(err, ErrPeriodClosed) {
		t.Fatalf("expected ErrPeriodClosed, got %v", err)
	}
}
