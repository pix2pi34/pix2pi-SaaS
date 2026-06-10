package serviceregistry

import (
	"context"
	"errors"
	"strings"
	"time"
)

type CleanupStaleInstancesRequest struct {
	TenantID           string `json:"tenant_id,omitempty"`
	GracePeriodSeconds int    `json:"grace_period_seconds"`
	Limit              int    `json:"limit"`
	TargetStatus       string `json:"target_status"`
	DryRun             bool   `json:"dry_run"`
}

type CleanupStaleInstancesResponse struct {
	TenantID        string    `json:"tenant_id,omitempty"`
	CleanedCount    int       `json:"cleaned_count"`
	ThresholdTime   time.Time `json:"threshold_time"`
	TargetStatus    string    `json:"target_status"`
	DryRun          bool      `json:"dry_run"`
	ExecutedAt      time.Time `json:"executed_at"`
}

func (r CleanupStaleInstancesRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if r.GracePeriodSeconds < 30 || r.GracePeriodSeconds > 86400 {
		errs = append(errs, ValidationError{
			Field:   "grace_period_seconds",
			Message: "30-86400 araliginda olmali",
		})
	}

	if r.Limit < 1 || r.Limit > 10000 {
		errs = append(errs, ValidationError{
			Field:   "limit",
			Message: "1-10000 araliginda olmali",
		})
	}

	if !containsValue(allowedInstanceStatuses, strings.TrimSpace(r.TargetStatus)) {
		errs = append(errs, ValidationError{
			Field:   "target_status",
			Message: "desteklenmeyen deger",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r CleanupStaleInstancesResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if r.CleanedCount < 0 {
		errs = append(errs, ValidationError{
			Field:   "cleaned_count",
			Message: "negatif olamaz",
		})
	}

	if r.ThresholdTime.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "threshold_time",
			Message: "zorunlu alan",
		})
	}

	if !containsValue(allowedInstanceStatuses, strings.TrimSpace(r.TargetStatus)) {
		errs = append(errs, ValidationError{
			Field:   "target_status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.ExecutedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "executed_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

type CleanupStaleInstancesCommand struct {
	TenantID      string
	ThresholdTime time.Time
	Limit         int
	TargetStatus  string
	DryRun        bool
}

type CleanupStaleInstancesResult struct {
	CleanedCount int
}

type StaleInstanceCleanupStore interface {
	CleanupStaleInstances(ctx context.Context, cmd CleanupStaleInstancesCommand) (CleanupStaleInstancesResult, error)
}

type StaleInstanceCleanupUsecase struct {
	store StaleInstanceCleanupStore
	nowFn func() time.Time
}

func NewStaleInstanceCleanupUsecase(store StaleInstanceCleanupStore) *StaleInstanceCleanupUsecase {
	return &StaleInstanceCleanupUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *StaleInstanceCleanupUsecase) Run(ctx context.Context, req CleanupStaleInstancesRequest) (CleanupStaleInstancesResponse, error) {
	if u == nil || u.store == nil {
		return CleanupStaleInstancesResponse{}, errors.New("stale cleanup usecase hazir degil")
	}

	if err := req.Validate(); err != nil {
		return CleanupStaleInstancesResponse{}, err
	}

	executedAt := u.nowFn().UTC()
	thresholdTime := executedAt.Add(-time.Duration(req.GracePeriodSeconds) * time.Second)

	cmd := CleanupStaleInstancesCommand{
		TenantID:      strings.TrimSpace(req.TenantID),
		ThresholdTime: thresholdTime,
		Limit:         req.Limit,
		TargetStatus:  strings.TrimSpace(req.TargetStatus),
		DryRun:        req.DryRun,
	}

	result, err := u.store.CleanupStaleInstances(ctx, cmd)
	if err != nil {
		return CleanupStaleInstancesResponse{}, err
	}

	resp := CleanupStaleInstancesResponse{
		TenantID:      cmd.TenantID,
		CleanedCount:  result.CleanedCount,
		ThresholdTime: thresholdTime,
		TargetStatus:  cmd.TargetStatus,
		DryRun:        cmd.DryRun,
		ExecutedAt:    executedAt,
	}

	if err := resp.Validate(); err != nil {
		return CleanupStaleInstancesResponse{}, err
	}

	return resp, nil
}
