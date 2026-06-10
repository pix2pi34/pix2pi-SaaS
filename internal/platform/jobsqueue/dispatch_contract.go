package jobsqueue

import (
	"strings"
	"time"
)

var allowedDispatchModes = map[string]struct{}{
	"tenant_pinned": {},
	"shared_pool":   {},
	"priority_lane": {},
	"fallback":      {},
}

type ResolveDispatchRequest struct {
	TenantID       string   `json:"tenant_id,omitempty"`
	QueueKey       string   `json:"queue_key"`
	JobID          string   `json:"job_id"`
	Priority       string   `json:"priority"`
	RequestedPool  string   `json:"requested_pool,omitempty"`
	AvailablePools []string `json:"available_pools,omitempty"`
	FallbackPool   string   `json:"fallback_pool,omitempty"`
}

type ResolveDispatchResponse struct {
	DispatchKey      string    `json:"dispatch_key"`
	JobID            string    `json:"job_id"`
	QueueKey         string    `json:"queue_key"`
	Priority         string    `json:"priority"`
	SelectedPool     string    `json:"selected_pool"`
	DispatchMode     string    `json:"dispatch_mode"`
	TenantAware      bool      `json:"tenant_aware"`
	AppliedTenantID  string    `json:"applied_tenant_id,omitempty"`
	DispatchedAt     time.Time `json:"dispatched_at"`
}

func (r ResolveDispatchRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !jobQueueKeyPattern.MatchString(strings.TrimSpace(r.QueueKey)) {
		errs = append(errs, ValidationError{
			Field:   "queue_key",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.JobID) == "" {
		errs = append(errs, ValidationError{
			Field:   "job_id",
			Message: "zorunlu alan",
		})
	}

	if !containsValue(allowedJobPriorities, strings.TrimSpace(r.Priority)) {
		errs = append(errs, ValidationError{
			Field:   "priority",
			Message: "desteklenmeyen deger",
		})
	}

	if pool := strings.TrimSpace(r.RequestedPool); pool != "" && !workerKeyPattern.MatchString(pool) {
		errs = append(errs, ValidationError{
			Field:   "requested_pool",
			Message: "gecersiz format",
		})
	}

	if pool := strings.TrimSpace(r.FallbackPool); pool != "" && !workerKeyPattern.MatchString(pool) {
		errs = append(errs, ValidationError{
			Field:   "fallback_pool",
			Message: "gecersiz format",
		})
	}

	for idx, pool := range r.AvailablePools {
		if !workerKeyPattern.MatchString(strings.TrimSpace(pool)) {
			errs = append(errs, ValidationError{
				Field:   "available_pools[" + string(rune(idx+'0')) + "]",
				Message: "gecersiz format",
			})
		}
	}

	if len(trimmedNonEmptyPools(r.AvailablePools)) == 0 && strings.TrimSpace(r.FallbackPool) == "" {
		errs = append(errs, ValidationError{
			Field:   "dispatch_target",
			Message: "en az bir available pool veya fallback pool olmali",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r ResolveDispatchResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if strings.TrimSpace(r.DispatchKey) == "" {
		errs = append(errs, ValidationError{
			Field:   "dispatch_key",
			Message: "zorunlu alan",
		})
	}

	if strings.TrimSpace(r.JobID) == "" {
		errs = append(errs, ValidationError{
			Field:   "job_id",
			Message: "zorunlu alan",
		})
	}

	if !jobQueueKeyPattern.MatchString(strings.TrimSpace(r.QueueKey)) {
		errs = append(errs, ValidationError{
			Field:   "queue_key",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedJobPriorities, strings.TrimSpace(r.Priority)) {
		errs = append(errs, ValidationError{
			Field:   "priority",
			Message: "desteklenmeyen deger",
		})
	}

	if !workerKeyPattern.MatchString(strings.TrimSpace(r.SelectedPool)) {
		errs = append(errs, ValidationError{
			Field:   "selected_pool",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedDispatchModes, strings.TrimSpace(r.DispatchMode)) {
		errs = append(errs, ValidationError{
			Field:   "dispatch_mode",
			Message: "desteklenmeyen deger",
		})
	}

	if r.DispatchedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "dispatched_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func trimmedNonEmptyPools(in []string) []string {
	out := make([]string, 0, len(in))
	seen := make(map[string]struct{})

	for _, pool := range in {
		pool = strings.TrimSpace(pool)
		if pool == "" {
			continue
		}
		if _, ok := seen[pool]; ok {
			continue
		}
		seen[pool] = struct{}{}
		out = append(out, pool)
	}

	return out
}
