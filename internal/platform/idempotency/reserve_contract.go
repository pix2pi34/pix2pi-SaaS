package idempotency

import (
	"regexp"
	"strings"
	"time"
)

var (
	scopeKeyPattern       = regexp.MustCompile(`^[a-z0-9][a-z0-9._:-]*$`)
	idempotencyKeyPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
	requestHashPattern    = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
	actorRefPattern       = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
)

var allowedReservationStatuses = map[string]struct{}{
	"reserved": {},
	"existing": {},
	"conflict": {},
}

type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

type ValidationErrors []ValidationError

func (v ValidationErrors) Error() string {
	if len(v) == 0 {
		return "validation failed"
	}

	parts := make([]string, 0, len(v))
	for _, item := range v {
		parts = append(parts, item.Field+": "+item.Message)
	}

	return strings.Join(parts, ", ")
}

func containsValue(values map[string]struct{}, value string) bool {
	_, ok := values[value]
	return ok
}

type ReserveIdempotencyKeyRequest struct {
	TenantID       string `json:"tenant_id,omitempty"`
	ScopeKey       string `json:"scope_key"`
	IdempotencyKey string `json:"idempotency_key"`
	RequestHash    string `json:"request_hash"`
	TTLSeconds     int    `json:"ttl_seconds"`
	RequestedBy    string `json:"requested_by"`
}

type ReserveIdempotencyKeyResponse struct {
	ReservationID    string    `json:"reservation_id"`
	ScopeKey         string    `json:"scope_key"`
	IdempotencyKey   string    `json:"idempotency_key"`
	RequestHash      string    `json:"request_hash"`
	Status           string    `json:"status"`
	ExistingResultRef string   `json:"existing_result_ref,omitempty"`
	ExpiresAt        time.Time `json:"expires_at"`
	ReservedAt       time.Time `json:"reserved_at"`
}

func (r ReserveIdempotencyKeyRequest) Validate() error {
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

	if r.TTLSeconds < 60 || r.TTLSeconds > 604800 {
		errs = append(errs, ValidationError{
			Field:   "ttl_seconds",
			Message: "60-604800 araliginda olmali",
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

func (r ReserveIdempotencyKeyResponse) Validate() error {
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

	if !containsValue(allowedReservationStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.ExpiresAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "expires_at",
			Message: "zorunlu alan",
		})
	}

	if r.ReservedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "reserved_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
