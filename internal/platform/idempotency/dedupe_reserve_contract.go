package idempotency

import (
	"regexp"
	"strings"
	"time"
)

var dedupeRecordKeyPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)

var allowedDedupeReservationStatuses = map[string]struct{}{
	"reserved": {},
	"existing": {},
	"conflict": {},
}

type ReserveDedupeRecordRequest struct {
	TenantID    string `json:"tenant_id,omitempty"`
	ScopeKey    string `json:"scope_key"`
	RecordKey   string `json:"record_key"`
	PayloadHash string `json:"payload_hash"`
	TTLSeconds  int    `json:"ttl_seconds"`
	RequestedBy string `json:"requested_by"`
}

type ReserveDedupeRecordResponse struct {
	RecordID          string    `json:"record_id"`
	ScopeKey          string    `json:"scope_key"`
	RecordKey         string    `json:"record_key"`
	PayloadHash       string    `json:"payload_hash"`
	Status            string    `json:"status"`
	ExistingValueRef  string    `json:"existing_value_ref,omitempty"`
	ExpiresAt         time.Time `json:"expires_at"`
	ReservedAt        time.Time `json:"reserved_at"`
}

func (r ReserveDedupeRecordRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !scopeKeyPattern.MatchString(strings.TrimSpace(r.ScopeKey)) {
		errs = append(errs, ValidationError{
			Field:   "scope_key",
			Message: "gecersiz format",
		})
	}

	if !dedupeRecordKeyPattern.MatchString(strings.TrimSpace(r.RecordKey)) {
		errs = append(errs, ValidationError{
			Field:   "record_key",
			Message: "gecersiz format",
		})
	}

	if !requestHashPattern.MatchString(strings.TrimSpace(r.PayloadHash)) {
		errs = append(errs, ValidationError{
			Field:   "payload_hash",
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

func (r ReserveDedupeRecordResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if strings.TrimSpace(r.RecordID) == "" {
		errs = append(errs, ValidationError{
			Field:   "record_id",
			Message: "zorunlu alan",
		})
	}

	if !scopeKeyPattern.MatchString(strings.TrimSpace(r.ScopeKey)) {
		errs = append(errs, ValidationError{
			Field:   "scope_key",
			Message: "gecersiz format",
		})
	}

	if !dedupeRecordKeyPattern.MatchString(strings.TrimSpace(r.RecordKey)) {
		errs = append(errs, ValidationError{
			Field:   "record_key",
			Message: "gecersiz format",
		})
	}

	if !requestHashPattern.MatchString(strings.TrimSpace(r.PayloadHash)) {
		errs = append(errs, ValidationError{
			Field:   "payload_hash",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedDedupeReservationStatuses, strings.TrimSpace(r.Status)) {
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
