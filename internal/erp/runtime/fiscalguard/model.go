package fiscalguard

import (
	"strings"
	"time"
)

type FiscalPeriodStatus string

const (
	FiscalPeriodStatusOpen   FiscalPeriodStatus = "open"
	FiscalPeriodStatusLocked FiscalPeriodStatus = "locked"
	FiscalPeriodStatusClosed FiscalPeriodStatus = "closed"
)

type ResolvePeriodRequest struct {
	TenantID    string
	PostingDate time.Time
}

type FiscalPeriodSnapshot struct {
	TenantID string

	FiscalYear   int
	FiscalPeriod string
	PeriodNo     int

	PeriodStartDate time.Time
	PeriodEndDate   time.Time

	Status FiscalPeriodStatus
}

type ResolvePeriodResult struct {
	OK bool

	TenantID string

	FiscalYear   int
	FiscalPeriod string
	PeriodNo     int

	PostingDate time.Time

	Status FiscalPeriodStatus
}

type PeriodGuardRequest struct {
	TenantID string

	FiscalYear   int
	FiscalPeriod string
	PostingDate  time.Time

	Status FiscalPeriodStatus
}

type PeriodGuardResult struct {
	OK bool

	TenantID string

	FiscalYear   int
	FiscalPeriod string
	PostingDate  time.Time

	Status FiscalPeriodStatus

	Message string
}

func ValidateResolvePeriodRequest(req ResolvePeriodRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return ErrTenantRequired
	}

	if req.PostingDate.IsZero() {
		return ErrPostingDateRequired
	}

	return nil
}

func ValidateFiscalPeriodSnapshot(period FiscalPeriodSnapshot) error {
	if strings.TrimSpace(period.TenantID) == "" {
		return ErrTenantRequired
	}

	if period.FiscalYear < 2000 || period.FiscalYear > 2100 {
		return ErrFiscalYearInvalid
	}

	if strings.TrimSpace(period.FiscalPeriod) == "" {
		return ErrFiscalPeriodRequired
	}

	if period.PeriodStartDate.IsZero() {
		return ErrPeriodStartRequired
	}

	if period.PeriodEndDate.IsZero() {
		return ErrPeriodEndRequired
	}

	if period.PeriodEndDate.Before(period.PeriodStartDate) {
		return ErrPeriodDateRangeInvalid
	}

	if !isValidPeriodStatus(period.Status) {
		return ErrPeriodStatusInvalid
	}

	return nil
}

func ValidatePeriodGuardRequest(req PeriodGuardRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return ErrTenantRequired
	}

	if req.FiscalYear < 2000 || req.FiscalYear > 2100 {
		return ErrFiscalYearInvalid
	}

	if strings.TrimSpace(req.FiscalPeriod) == "" {
		return ErrFiscalPeriodRequired
	}

	if req.PostingDate.IsZero() {
		return ErrPostingDateRequired
	}

	if !isValidPeriodStatus(req.Status) {
		return ErrPeriodStatusInvalid
	}

	return nil
}

func EnsurePeriodOpen(req PeriodGuardRequest) (PeriodGuardResult, error) {
	if err := ValidatePeriodGuardRequest(req); err != nil {
		return PeriodGuardResult{}, err
	}

	switch req.Status {
	case FiscalPeriodStatusOpen:
		return PeriodGuardResult{
			OK:           true,
			TenantID:     req.TenantID,
			FiscalYear:   req.FiscalYear,
			FiscalPeriod: req.FiscalPeriod,
			PostingDate:  req.PostingDate,
			Status:       req.Status,
			Message:      "fiscal period acik",
		}, nil
	case FiscalPeriodStatusLocked:
		return PeriodGuardResult{}, ErrPeriodLocked
	case FiscalPeriodStatusClosed:
		return PeriodGuardResult{}, ErrPeriodClosed
	default:
		return PeriodGuardResult{}, ErrPeriodStatusInvalid
	}
}

func BuildResolvePeriodResult(req ResolvePeriodRequest, period FiscalPeriodSnapshot) (ResolvePeriodResult, error) {
	if err := ValidateResolvePeriodRequest(req); err != nil {
		return ResolvePeriodResult{}, err
	}

	if err := ValidateFiscalPeriodSnapshot(period); err != nil {
		return ResolvePeriodResult{}, err
	}

	if req.TenantID != period.TenantID {
		return ResolvePeriodResult{}, ErrPeriodNotFound
	}

	postingDate := dateOnly(req.PostingDate)
	startDate := dateOnly(period.PeriodStartDate)
	endDate := dateOnly(period.PeriodEndDate)

	if postingDate.Before(startDate) || postingDate.After(endDate) {
		return ResolvePeriodResult{}, ErrPostingDateOutOfRange
	}

	return ResolvePeriodResult{
		OK:           true,
		TenantID:     req.TenantID,
		FiscalYear:   period.FiscalYear,
		FiscalPeriod: period.FiscalPeriod,
		PeriodNo:     period.PeriodNo,
		PostingDate:  postingDate,
		Status:       period.Status,
	}, nil
}

func isValidPeriodStatus(status FiscalPeriodStatus) bool {
	switch status {
	case FiscalPeriodStatusOpen, FiscalPeriodStatusLocked, FiscalPeriodStatusClosed:
		return true
	default:
		return false
	}
}

func dateOnly(value time.Time) time.Time {
	y, m, d := value.Date()
	return time.Date(y, m, d, 0, 0, 0, 0, time.UTC)
}
