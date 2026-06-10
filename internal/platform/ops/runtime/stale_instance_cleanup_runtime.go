package opsruntime

import (
	"errors"
	"strings"
	"time"
)

const (
	StaleInstanceCleanupDecisionAllow = "ALLOW"
	StaleInstanceCleanupDecisionDeny  = "DENY"

	StaleInstanceCleanupReasonAllowed          = "STALE_INSTANCE_CLEANUP_ALLOWED"
	StaleInstanceCleanupReasonMissingTenant    = "STALE_INSTANCE_CLEANUP_MISSING_TENANT"
	StaleInstanceCleanupReasonMissingRegistry  = "STALE_INSTANCE_CLEANUP_MISSING_REGISTRY"
	StaleInstanceCleanupReasonInvalidThreshold = "STALE_INSTANCE_CLEANUP_INVALID_THRESHOLD"
	StaleInstanceCleanupReasonInvalidTimestamp = "STALE_INSTANCE_CLEANUP_INVALID_TIMESTAMP"
	StaleInstanceCleanupReasonCrossTenant      = "STALE_INSTANCE_CLEANUP_CROSS_TENANT_DENIED"
)

var (
	ErrStaleInstanceCleanupMissingTenant    = errors.New("missing stale instance cleanup tenant id")
	ErrStaleInstanceCleanupMissingRegistry  = errors.New("missing instance metadata registry")
	ErrStaleInstanceCleanupInvalidThreshold = errors.New("invalid stale instance cleanup threshold")
	ErrStaleInstanceCleanupInvalidTimestamp = errors.New("invalid stale instance timestamp")
	ErrStaleInstanceCleanupCrossTenant      = errors.New("cross-tenant stale instance cleanup denied")
)

type StaleInstanceCleanupRuntimeConfig struct {
	RequireTenant               bool     `json:"require_tenant"`
	StaleAfterSeconds           int64    `json:"stale_after_seconds"`
	AutoCleanupEnabled          bool     `json:"auto_cleanup_enabled"`
	CleanupMetadataEnabled      bool     `json:"cleanup_metadata_enabled"`
	CleanupMetadataVisibilities []string `json:"cleanup_metadata_visibilities"`
}

func DefaultStaleInstanceCleanupRuntimeConfig() StaleInstanceCleanupRuntimeConfig {
	return StaleInstanceCleanupRuntimeConfig{
		RequireTenant:               true,
		StaleAfterSeconds:           90,
		AutoCleanupEnabled:          true,
		CleanupMetadataEnabled:      true,
		CleanupMetadataVisibilities: []string{InstanceMetadataVisibilityInternal},
	}
}

type StaleInstanceCleanupRequest struct {
	TenantID      string    `json:"tenant_id"`
	Now           time.Time `json:"now,omitempty"`
	ActorRef      string    `json:"actor_ref,omitempty"`
	CorrelationID string    `json:"correlation_id,omitempty"`
}

type StaleInstanceCandidate struct {
	TenantID       string `json:"tenant_id"`
	ServiceID      string `json:"service_id"`
	InstanceID     string `json:"instance_id"`
	ServiceName    string `json:"service_name"`
	PreviousStatus string `json:"previous_status"`
	AgeSeconds     int64  `json:"age_seconds"`
	LastSeenAt     string `json:"last_seen_at"`
}

type StaleInstanceCleanupResult struct {
	TenantID             string                   `json:"tenant_id"`
	CheckedCount         int                      `json:"checked_count"`
	StaleCandidateCount  int                      `json:"stale_candidate_count"`
	MarkedStaleCount     int                      `json:"marked_stale_count"`
	DeletedMetadataCount int                      `json:"deleted_metadata_count"`
	StaleCandidates      []StaleInstanceCandidate `json:"stale_candidates"`
	CorrelationID        string                   `json:"correlation_id,omitempty"`
	CompletedAt          string                   `json:"completed_at"`
}

type StaleInstanceCleanupDecision struct {
	Decision             string `json:"decision"`
	Allowed              bool   `json:"allowed"`
	TenantID             string `json:"tenant_id"`
	CheckedCount         int    `json:"checked_count"`
	StaleCandidateCount  int    `json:"stale_candidate_count"`
	MarkedStaleCount     int    `json:"marked_stale_count"`
	DeletedMetadataCount int    `json:"deleted_metadata_count"`
	ActorRef             string `json:"actor_ref,omitempty"`
	CorrelationID        string `json:"correlation_id,omitempty"`
	Reason               string `json:"reason"`
	CheckedAt            string `json:"checked_at"`
}

type StaleInstanceCleanupRuntime struct {
	config   StaleInstanceCleanupRuntimeConfig
	registry *InstanceMetadataRuntime
}

func NewStaleInstanceCleanupRuntime(config StaleInstanceCleanupRuntimeConfig, registry *InstanceMetadataRuntime) *StaleInstanceCleanupRuntime {
	defaults := DefaultStaleInstanceCleanupRuntimeConfig()

	if config.StaleAfterSeconds == 0 {
		config.StaleAfterSeconds = defaults.StaleAfterSeconds
	}
	if len(config.CleanupMetadataVisibilities) == 0 {
		config.CleanupMetadataVisibilities = defaults.CleanupMetadataVisibilities
	}

	return &StaleInstanceCleanupRuntime{
		config:   config,
		registry: registry,
	}
}

func (r *StaleInstanceCleanupRuntime) DetectStaleInstances(req StaleInstanceCleanupRequest) (StaleInstanceCleanupResult, StaleInstanceCleanupDecision, error) {
	return r.evaluate(req, false)
}

func (r *StaleInstanceCleanupRuntime) RunCleanup(req StaleInstanceCleanupRequest) (StaleInstanceCleanupResult, StaleInstanceCleanupDecision, error) {
	return r.evaluate(req, true)
}

func (r *StaleInstanceCleanupRuntime) evaluate(req StaleInstanceCleanupRequest, mutate bool) (StaleInstanceCleanupResult, StaleInstanceCleanupDecision, error) {
	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	} else {
		now = now.UTC()
	}

	tenantID := strings.TrimSpace(req.TenantID)

	decision := StaleInstanceCleanupDecision{
		Decision:      StaleInstanceCleanupDecisionDeny,
		Allowed:       false,
		TenantID:      tenantID,
		ActorRef:      strings.TrimSpace(req.ActorRef),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		Reason:        StaleInstanceCleanupReasonAllowed,
		CheckedAt:     now.Format(time.RFC3339Nano),
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = StaleInstanceCleanupReasonMissingTenant
		return StaleInstanceCleanupResult{}, decision, ErrStaleInstanceCleanupMissingTenant
	}

	if r.registry == nil {
		decision.Reason = StaleInstanceCleanupReasonMissingRegistry
		return StaleInstanceCleanupResult{}, decision, ErrStaleInstanceCleanupMissingRegistry
	}

	if r.config.StaleAfterSeconds <= 0 {
		decision.Reason = StaleInstanceCleanupReasonInvalidThreshold
		return StaleInstanceCleanupResult{}, decision, ErrStaleInstanceCleanupInvalidThreshold
	}

	r.registry.mu.Lock()
	defer r.registry.mu.Unlock()

	result := StaleInstanceCleanupResult{
		TenantID:      tenantID,
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		CompletedAt:   now.Format(time.RFC3339Nano),
	}

	for mapKey, instance := range r.registry.instances {
		if instance.TenantID != tenantID {
			continue
		}

		result.CheckedCount++

		lastSeen, err := instanceLastSeenAt(instance)
		if err != nil {
			decision.Reason = StaleInstanceCleanupReasonInvalidTimestamp
			return StaleInstanceCleanupResult{}, decision, ErrStaleInstanceCleanupInvalidTimestamp
		}

		ageSeconds := int64(now.Sub(lastSeen).Seconds())
		if ageSeconds < 0 {
			ageSeconds = 0
		}

		if ageSeconds < r.config.StaleAfterSeconds {
			continue
		}

		candidate := StaleInstanceCandidate{
			TenantID:       instance.TenantID,
			ServiceID:      instance.ServiceID,
			InstanceID:     instance.InstanceID,
			ServiceName:    instance.ServiceName,
			PreviousStatus: instance.Status,
			AgeSeconds:     ageSeconds,
			LastSeenAt:     lastSeen.Format(time.RFC3339Nano),
		}
		result.StaleCandidates = append(result.StaleCandidates, candidate)
		result.StaleCandidateCount++

		if mutate && r.config.AutoCleanupEnabled && instance.Status != ServiceInstanceStatusStale {
			instance.Status = ServiceInstanceStatusStale
			instance.UpdatedAt = now.Format(time.RFC3339Nano)
			if strings.TrimSpace(req.CorrelationID) != "" {
				instance.CorrelationID = strings.TrimSpace(req.CorrelationID)
			}
			r.registry.instances[mapKey] = instance
			result.MarkedStaleCount++
		}

		if mutate && r.config.AutoCleanupEnabled && r.config.CleanupMetadataEnabled {
			result.DeletedMetadataCount += r.deleteCleanupMetadataLocked(tenantID, instance.InstanceID)
		}
	}

	decision.Decision = StaleInstanceCleanupDecisionAllow
	decision.Allowed = true
	decision.CheckedCount = result.CheckedCount
	decision.StaleCandidateCount = result.StaleCandidateCount
	decision.MarkedStaleCount = result.MarkedStaleCount
	decision.DeletedMetadataCount = result.DeletedMetadataCount
	decision.Reason = StaleInstanceCleanupReasonAllowed

	return result, decision, nil
}

func (r *StaleInstanceCleanupRuntime) deleteCleanupMetadataLocked(tenantID string, instanceID string) int {
	deleted := 0
	for key, metadata := range r.registry.metadata {
		if metadata.TenantID != tenantID || metadata.InstanceID != instanceID {
			continue
		}
		if !cleanupVisibilityAllowed(metadata.Visibility, r.config.CleanupMetadataVisibilities) {
			continue
		}
		delete(r.registry.metadata, key)
		deleted++
	}
	return deleted
}

func instanceLastSeenAt(instance ServiceInstanceRecord) (time.Time, error) {
	candidates := []string{
		strings.TrimSpace(instance.UpdatedAt),
		strings.TrimSpace(instance.RegisteredAt),
	}
	for _, value := range candidates {
		if value == "" {
			continue
		}
		parsed, err := time.Parse(time.RFC3339Nano, value)
		if err == nil {
			return parsed.UTC(), nil
		}
		parsed, err = time.Parse(time.RFC3339, value)
		if err == nil {
			return parsed.UTC(), nil
		}
	}
	return time.Time{}, ErrStaleInstanceCleanupInvalidTimestamp
}

func cleanupVisibilityAllowed(visibility string, allowed []string) bool {
	for _, item := range allowed {
		if strings.EqualFold(strings.TrimSpace(item), strings.TrimSpace(visibility)) {
			return true
		}
	}
	return false
}
