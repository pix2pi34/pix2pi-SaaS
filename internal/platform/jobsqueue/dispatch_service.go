package jobsqueue

import (
	"context"
	"errors"
	"sort"
	"strings"
	"time"
)

type ResolveDispatchCommand struct {
	TenantID  string
	QueueKey  string
	JobID     string
	Priority  string
}

type ResolveDispatchResult struct {
	EffectiveQueueKey string
	PreferredPool     string
	DispatchMode      string
	TenantAware       bool
}

type DispatchPolicyStore interface {
	ResolveDispatchPolicy(ctx context.Context, cmd ResolveDispatchCommand) (ResolveDispatchResult, error)
}

type ResolveDispatchUsecase struct {
	store DispatchPolicyStore
	nowFn func() time.Time
}

func NewResolveDispatchUsecase(store DispatchPolicyStore) *ResolveDispatchUsecase {
	return &ResolveDispatchUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *ResolveDispatchUsecase) Resolve(ctx context.Context, req ResolveDispatchRequest) (ResolveDispatchResponse, error) {
	if u == nil || u.store == nil {
		return ResolveDispatchResponse{}, errors.New("resolve dispatch usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.QueueKey = strings.TrimSpace(req.QueueKey)
	req.JobID = strings.TrimSpace(req.JobID)
	req.Priority = strings.TrimSpace(req.Priority)
	req.RequestedPool = strings.TrimSpace(req.RequestedPool)
	req.FallbackPool = strings.TrimSpace(req.FallbackPool)
	req.AvailablePools = trimmedNonEmptyPools(req.AvailablePools)

	if err := req.Validate(); err != nil {
		return ResolveDispatchResponse{}, err
	}

	result, err := u.store.ResolveDispatchPolicy(ctx, ResolveDispatchCommand{
		TenantID: req.TenantID,
		QueueKey: req.QueueKey,
		JobID:    req.JobID,
		Priority: req.Priority,
	})
	if err != nil {
		return ResolveDispatchResponse{}, err
	}

	effectiveQueueKey := firstNonEmpty(strings.TrimSpace(result.EffectiveQueueKey), req.QueueKey)
	selectedPool, dispatchMode := resolveDispatchTarget(req, result)
	if selectedPool == "" {
		return ResolveDispatchResponse{}, errors.New("uygun dispatch pool bulunamadi")
	}

	resp := ResolveDispatchResponse{
		DispatchKey:     buildDispatchKey(req.TenantID, effectiveQueueKey, selectedPool),
		JobID:           req.JobID,
		QueueKey:        effectiveQueueKey,
		Priority:        req.Priority,
		SelectedPool:    selectedPool,
		DispatchMode:    dispatchMode,
		TenantAware:     result.TenantAware || req.TenantID != "",
		AppliedTenantID: req.TenantID,
		DispatchedAt:    u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return ResolveDispatchResponse{}, err
	}

	return resp, nil
}

func resolveDispatchTarget(req ResolveDispatchRequest, result ResolveDispatchResult) (string, string) {
	available := append([]string(nil), req.AvailablePools...)
	sort.Strings(available)

	preferredPool := strings.TrimSpace(result.PreferredPool)
	requestedPool := strings.TrimSpace(req.RequestedPool)
	fallbackPool := strings.TrimSpace(req.FallbackPool)
	dispatchMode := strings.TrimSpace(result.DispatchMode)

	if preferredPool != "" && poolExists(available, preferredPool) {
		return preferredPool, firstNonEmpty(dispatchMode, "tenant_pinned")
	}

	if requestedPool != "" && poolExists(available, requestedPool) {
		return requestedPool, firstNonEmpty(dispatchMode, "shared_pool")
	}

	if priorityPool := findPriorityPool(available, req.Priority); priorityPool != "" {
		return priorityPool, firstNonEmpty(dispatchMode, "priority_lane")
	}

	if len(available) > 0 {
		return available[0], firstNonEmpty(dispatchMode, "shared_pool")
	}

	if fallbackPool != "" {
		return fallbackPool, "fallback"
	}

	return "", ""
}

func poolExists(pools []string, target string) bool {
	for _, pool := range pools {
		if strings.TrimSpace(pool) == strings.TrimSpace(target) {
			return true
		}
	}
	return false
}

func findPriorityPool(pools []string, priority string) string {
	if strings.TrimSpace(priority) != "high" && strings.TrimSpace(priority) != "critical" {
		return ""
	}

	for _, pool := range pools {
		lower := strings.ToLower(strings.TrimSpace(pool))
		if strings.Contains(lower, "priority") || strings.Contains(lower, "critical") {
			return pool
		}
	}

	return ""
}

func buildDispatchKey(tenantID, queueKey, selectedPool string) string {
	parts := []string{}
	if strings.TrimSpace(tenantID) != "" {
		parts = append(parts, strings.TrimSpace(tenantID))
	}
	parts = append(parts, strings.TrimSpace(queueKey), strings.TrimSpace(selectedPool))
	return strings.Join(parts, "|")
}
