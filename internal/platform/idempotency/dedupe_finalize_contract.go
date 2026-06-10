package idempotency

import (
	"strings"
	"time"
)

type FinalizeDedupeRecordRequest struct {
	TenantID    string `json:"tenant_id,omitempty"`
	ScopeKey    string `json:"scope_key"`
	RecordKey   string `json:"record_key"`
	PayloadHash string `json:"payload_hash"`
	ValueRef    string `json:"value_ref"`
	FinalStatus string `json:"final_status"`
	RequestedBy string `json:"requested_by"`
}

type FinalizeDedupeRecordResponse struct {
	RecordID    string    `json:"record_id"`
	ScopeKey    string    `json:"scope_key"`
	RecordKey   string    `json:"record_key"`
	PayloadHash string    `json:"payload_hash"`
	ValueRef    string    `json:"value_ref"`
	FinalStatus string    `json:"final_status"`
	BoundAt     time.Time `json:"bound_at"`
}

func (r FinalizeDedupeRecordRequest) Validate() error {
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

	if !dedupeRecordKeyPattern.MatchString(strings.TrimSpace(r.ValueRef)) {
		errs = append(errs, ValidationError{
			Field:   "value_ref",
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

func (r FinalizeDedupeRecordResponse) Validate() error {
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

	if !dedupeRecordKeyPattern.MatchString(strings.TrimSpace(r.ValueRef)) {
		errs = append(errs, ValidationError{
			Field:   "value_ref",
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
