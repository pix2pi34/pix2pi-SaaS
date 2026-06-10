package publicapi

import (
	"strings"
	"time"
)

var allowedPublicAPIQuotaWindows = map[string]struct{}{
	"minute": {},
	"hour":   {},
	"day":    {},
	"month":  {},
}

var allowedPublicAPIQuotaStatuses = map[string]struct{}{
	"allowed": {},
	"limited": {},
}

type EvaluatePublicAPIQuotaRequest struct {
	TenantID    string `json:"tenant_id,omitempty"`
	RequestID   string `json:"request_id"`
	AppID       string `json:"app_id"`
	APIKeyID    string `json:"api_key_id"`
	Environment string `json:"environment"`
	QuotaWindow string `json:"quota_window"`
	Cost        int    `json:"cost"`
	RequestedBy string `json:"requested_by"`
}

type EvaluatePublicAPIQuotaResponse struct {
	RequestID         string    `json:"request_id"`
	AppID             string    `json:"app_id"`
	APIKeyID          string    `json:"api_key_id"`
	Environment       string    `json:"environment"`
	QuotaWindow       string    `json:"quota_window"`
	Limit             int       `json:"limit"`
	UsedBefore        int       `json:"used_before"`
	Cost              int       `json:"cost"`
	UsedAfter         int       `json:"used_after"`
	Remaining         int       `json:"remaining"`
	RateLimitStatus   string    `json:"rate_limit_status"`
	Allowed           bool      `json:"allowed"`
	RetryAfterSeconds int       `json:"retry_after_seconds,omitempty"`
	DenialReason      string    `json:"denial_reason,omitempty"`
	EvaluatedAt        time.Time `json:"evaluated_at"`
}

func (r EvaluatePublicAPIQuotaRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.RequestID)) {
		errs = append(errs, ValidationError{Field: "request_id", Message: "gecersiz format"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.AppID)) {
		errs = append(errs, ValidationError{Field: "app_id", Message: "gecersiz format"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.APIKeyID)) {
		errs = append(errs, ValidationError{Field: "api_key_id", Message: "gecersiz format"})
	}

	if !containsValue(allowedPublicAPIKeyEnvironments, strings.TrimSpace(r.Environment)) {
		errs = append(errs, ValidationError{Field: "environment", Message: "desteklenmeyen deger"})
	}

	if !containsValue(allowedPublicAPIQuotaWindows, strings.TrimSpace(r.QuotaWindow)) {
		errs = append(errs, ValidationError{Field: "quota_window", Message: "desteklenmeyen deger"})
	}

	if r.Cost < 1 || r.Cost > 1000 {
		errs = append(errs, ValidationError{Field: "cost", Message: "1-1000 araliginda olmali"})
	}

	if !publicAPIActorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{Field: "requested_by", Message: "gecersiz format"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r EvaluatePublicAPIQuotaResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.RequestID)) {
		errs = append(errs, ValidationError{Field: "request_id", Message: "gecersiz format"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.AppID)) {
		errs = append(errs, ValidationError{Field: "app_id", Message: "gecersiz format"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.APIKeyID)) {
		errs = append(errs, ValidationError{Field: "api_key_id", Message: "gecersiz format"})
	}

	if !containsValue(allowedPublicAPIKeyEnvironments, strings.TrimSpace(r.Environment)) {
		errs = append(errs, ValidationError{Field: "environment", Message: "desteklenmeyen deger"})
	}

	if !containsValue(allowedPublicAPIQuotaWindows, strings.TrimSpace(r.QuotaWindow)) {
		errs = append(errs, ValidationError{Field: "quota_window", Message: "desteklenmeyen deger"})
	}

	if r.Limit < 1 {
		errs = append(errs, ValidationError{Field: "limit", Message: "1 veya uzeri olmali"})
	}

	if r.UsedBefore < 0 {
		errs = append(errs, ValidationError{Field: "used_before", Message: "0 veya uzeri olmali"})
	}

	if r.Cost < 1 || r.Cost > 1000 {
		errs = append(errs, ValidationError{Field: "cost", Message: "1-1000 araliginda olmali"})
	}

	if r.UsedAfter < 0 {
		errs = append(errs, ValidationError{Field: "used_after", Message: "0 veya uzeri olmali"})
	}

	if r.Remaining < 0 {
		errs = append(errs, ValidationError{Field: "remaining", Message: "0 veya uzeri olmali"})
	}

	if !containsValue(allowedPublicAPIQuotaStatuses, strings.TrimSpace(r.RateLimitStatus)) {
		errs = append(errs, ValidationError{Field: "rate_limit_status", Message: "desteklenmeyen deger"})
	}

	if r.Allowed && strings.TrimSpace(r.RateLimitStatus) != "allowed" {
		errs = append(errs, ValidationError{Field: "rate_limit_status", Message: "allowed true ise allowed olmali"})
	}

	if !r.Allowed {
		if strings.TrimSpace(r.RateLimitStatus) != "limited" {
			errs = append(errs, ValidationError{Field: "rate_limit_status", Message: "allowed false ise limited olmali"})
		}

		if strings.TrimSpace(r.DenialReason) == "" {
			errs = append(errs, ValidationError{Field: "denial_reason", Message: "limited durumda zorunlu alan"})
		}

		if r.RetryAfterSeconds < 1 {
			errs = append(errs, ValidationError{Field: "retry_after_seconds", Message: "limited durumda 1 veya uzeri olmali"})
		}
	}

	if r.EvaluatedAt.IsZero() {
		errs = append(errs, ValidationError{Field: "evaluated_at", Message: "zorunlu alan"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
