package idempotency

import (
	"strings"
	"time"
)

var allowedFinalizeStatuses = map[string]struct{}{
	"completed": {},
	"failed":    {},
}

type FinalizeIdempotencyKeyRequest struct {
	TenantID       string `json:"tenant_id,omitempty"`
	ScopeKey       string `json:"scope_key"`
	IdempotencyKey string `json:"idempotency_key"`
	RequestHash    string `json:"request_hash"`
	ResultRef      string `json:"result_ref"`
	FinalStatus    string `json:"final_status"`
	RequestedBy    string `json:"requested_by"`
}

type FinalizeIdempotencyKeyResponse struct {
	ReservationID   string    `json:"reservation_id"`
	ScopeKey        string    `json:"scope_key"`
	IdempotencyKey  string    `json:"idempotency_key"`
	RequestHash     string    `json:"request_hash"`
	ResultRef       string    `json:"result_ref"`
	FinalStatus     string    `json:"final_status"`
	BoundAt         time.Time `json:"bound_at"`
}

func (r FinalizeIdempotencyKeyRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !scopeKeyPattern.MatchString(strings.TrimSpace(r.ScopeKey)) {
		errs = append(errs, ValidationError{
			Field:   "scope_key",
			Message: "gecersiz format",
		})
	}

	if !idempotencyKeyPattern.MatchString(strings.TrimSpace(r.IdempotencyKey)) {
		errs = append(errs, ValidationError{
			Field:   "idempotency_key",
			Message: "gecersiz format",
		})
	}

	if !requestHashPattern.MatchString(strings.TrimSpace(r.RequestHash)) {
		errs = append(errs, ValidationError{
			Field:   "request_hash",
			Message: "gecersiz format",
		})
	}

	if !idempotencyKeyPattern.MatchString(strings.TrimSpace(r.ResultRef)) {
		errs = append(errs, ValidationError{
			Field:   "result_ref",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedFinalizeStatuses, strings.TrimSpace(r.FinalStatus)) {
		errs = append(errs, ValidationError{
			Field:   "final_status",
			Message: "desteklenmeyen deger",
		})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{
			Field:   "requested_by",
			Message: "gecersiz format",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r FinalizeIdempotencyKeyResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if strings.TrimSpace(r.ReservationID) == "" {
		errs = append(errs, ValidationError{
			Field:   "reservation_id",
			Message: "zorunlu alan",
		})
	}

	if !scopeKeyPattern.MatchString(strings.TrimSpace(r.ScopeKey)) {
		errs = append(errs, ValidationError{
			Field:   "scope_key",
			Message: "gecersiz format",
		})
	}

	if !idempotencyKeyPattern.MatchString(strings.TrimSpace(r.IdempotencyKey)) {
		errs = append(errs, ValidationError{
			Field:   "idempotency_key",
			Message: "gecersiz format",
		})
	}

	if !requestHashPattern.MatchString(strings.TrimSpace(r.RequestHash)) {
		errs = append(errs, ValidationError{
			Field:   "request_hash",
			Message: "gecersiz format",
		})
	}

	if !idempotencyKeyPattern.MatchString(strings.TrimSpace(r.ResultRef)) {
		errs = append(errs, ValidationError{
			Field:   "result_ref",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedFinalizeStatuses, strings.TrimSpace(r.FinalStatus)) {
		errs = append(errs, ValidationError{
			Field:   "final_status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.BoundAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "bound_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
