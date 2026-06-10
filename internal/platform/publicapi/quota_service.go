package publicapi

import (
	"context"
	"errors"
	"strings"
	"time"
)

type EvaluatePublicAPIQuotaCommand struct {
	TenantID    string
	RequestID   string
	AppID       string
	APIKeyID    string
	Environment string
	QuotaWindow string
	Cost        int
	RequestedBy string
}

type EvaluatePublicAPIQuotaResult struct {
	RequestID         string
	AppID             string
	APIKeyID          string
	Environment       string
	QuotaWindow       string
	Limit             int
	UsedBefore        int
	Cost              int
	UsedAfter         int
	Remaining         int
	RateLimitStatus   string
	Allowed           bool
	RetryAfterSeconds int
	DenialReason      string
}

type PublicAPIQuotaStore interface {
	EvaluateQuota(ctx context.Context, cmd EvaluatePublicAPIQuotaCommand) (EvaluatePublicAPIQuotaResult, error)
}

type EvaluatePublicAPIQuotaUsecase struct {
	store PublicAPIQuotaStore
	nowFn func() time.Time
}

func NewEvaluatePublicAPIQuotaUsecase(store PublicAPIQuotaStore) *EvaluatePublicAPIQuotaUsecase {
	return &EvaluatePublicAPIQuotaUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *EvaluatePublicAPIQuotaUsecase) Evaluate(ctx context.Context, req EvaluatePublicAPIQuotaRequest) (EvaluatePublicAPIQuotaResponse, error) {
	if u == nil || u.store == nil {
		return EvaluatePublicAPIQuotaResponse{}, errors.New("public api quota usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.RequestID = strings.TrimSpace(req.RequestID)
	req.AppID = strings.TrimSpace(req.AppID)
	req.APIKeyID = strings.TrimSpace(req.APIKeyID)
	req.Environment = strings.TrimSpace(req.Environment)
	req.QuotaWindow = strings.TrimSpace(req.QuotaWindow)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return EvaluatePublicAPIQuotaResponse{}, err
	}

	result, err := u.store.EvaluateQuota(ctx, EvaluatePublicAPIQuotaCommand{
		TenantID:    req.TenantID,
		RequestID:   req.RequestID,
		AppID:       req.AppID,
		APIKeyID:    req.APIKeyID,
		Environment: req.Environment,
		QuotaWindow: req.QuotaWindow,
		Cost:        req.Cost,
		RequestedBy: req.RequestedBy,
	})
	if err != nil {
		return EvaluatePublicAPIQuotaResponse{}, err
	}

	limit := firstPositivePublicAPIInt(result.Limit, fallbackPublicAPIQuotaLimit(req.Environment, req.QuotaWindow))
	usedBefore := result.UsedBefore
	cost := firstPositivePublicAPIInt(result.Cost, req.Cost)
	usedAfter := result.UsedAfter
	if usedAfter == 0 {
		usedAfter = usedBefore + cost
	}

	remaining := result.Remaining
	if remaining == 0 && usedAfter <= limit {
		remaining = limit - usedAfter
	}

	status := strings.TrimSpace(result.RateLimitStatus)
	allowed := result.Allowed
	retryAfterSeconds := result.RetryAfterSeconds
	denialReason := strings.TrimSpace(result.DenialReason)

	if status == "" {
		if usedAfter <= limit {
			status = "allowed"
			allowed = true
			denialReason = ""
		} else {
			status = "limited"
			allowed = false
			remaining = 0
			if retryAfterSeconds == 0 {
				retryAfterSeconds = fallbackPublicAPIRetryAfterSeconds(req.QuotaWindow)
			}
			if denialReason == "" {
				denialReason = "quota limit asildi"
			}
		}
	}

	if status == "allowed" {
		allowed = true
		denialReason = ""
		retryAfterSeconds = 0
	}

	if status == "limited" {
		allowed = false
		remaining = 0
		if retryAfterSeconds == 0 {
			retryAfterSeconds = fallbackPublicAPIRetryAfterSeconds(req.QuotaWindow)
		}
		if denialReason == "" {
			denialReason = "quota limit asildi"
		}
	}

	resp := EvaluatePublicAPIQuotaResponse{
		RequestID:         firstNonEmpty(strings.TrimSpace(result.RequestID), req.RequestID),
		AppID:             firstNonEmpty(strings.TrimSpace(result.AppID), req.AppID),
		APIKeyID:          firstNonEmpty(strings.TrimSpace(result.APIKeyID), req.APIKeyID),
		Environment:       firstNonEmpty(strings.TrimSpace(result.Environment), req.Environment),
		QuotaWindow:       firstNonEmpty(strings.TrimSpace(result.QuotaWindow), req.QuotaWindow),
		Limit:             limit,
		UsedBefore:        usedBefore,
		Cost:              cost,
		UsedAfter:         usedAfter,
		Remaining:         remaining,
		RateLimitStatus:   status,
		Allowed:           allowed,
		RetryAfterSeconds: retryAfterSeconds,
		DenialReason:      denialReason,
		EvaluatedAt:       u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return EvaluatePublicAPIQuotaResponse{}, err
	}

	return resp, nil
}

func fallbackPublicAPIQuotaLimit(environment, quotaWindow string) int {
	if strings.TrimSpace(environment) == "production" {
		switch strings.TrimSpace(quotaWindow) {
		case "minute":
			return 600
		case "hour":
			return 10000
		case "day":
			return 100000
		case "month":
			return 1000000
		}
	}

	switch strings.TrimSpace(quotaWindow) {
	case "minute":
		return 60
	case "hour":
		return 1000
	case "day":
		return 10000
	case "month":
		return 100000
	default:
		return 1000
	}
}

func fallbackPublicAPIRetryAfterSeconds(quotaWindow string) int {
	switch strings.TrimSpace(quotaWindow) {
	case "minute":
		return 60
	case "hour":
		return 3600
	case "day":
		return 86400
	case "month":
		return 2592000
	default:
		return 60
	}
}

func firstPositivePublicAPIInt(values ...int) int {
	for _, v := range values {
		if v > 0 {
			return v
		}
	}
	return 0
}
