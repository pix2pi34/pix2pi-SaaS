package readcache

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
)

var (
	ErrNilProjectionRebuildGuard = errors.New("readcache: nil projection rebuild guard")
	ErrInvalidGuardMode          = errors.New("readcache: invalid guard mode")
)

type GuardMode string

const (
	GuardModeFreeze GuardMode = "freeze"
	GuardModeFlush  GuardMode = "flush"
)

type ProjectionGuardState struct {
	Mode          GuardMode `json:"mode"`
	Reason        string    `json:"reason"`
	StartedAtUnix int64     `json:"started_at_unix"`
}

func (s ProjectionGuardState) Validate() error {
	switch s.Mode {
	case GuardModeFreeze, GuardModeFlush:
		return nil
	default:
		return ErrInvalidGuardMode
	}
}

type ProjectionRebuildGuard struct {
	store      Store
	env        string
	service    string
	defaultTTL time.Duration
}

func NewProjectionRebuildGuard(store Store, env, service string, defaultTTL time.Duration) (*ProjectionRebuildGuard, error) {
	if store == nil {
		return nil, ErrNilStore
	}
	if strings.TrimSpace(env) == "" {
		return nil, ErrEmptyEnv
	}
	if strings.TrimSpace(service) == "" {
		return nil, ErrEmptyService
	}
	if err := validateKeyPart(env); err != nil {
		return nil, fmt.Errorf("env: %w", err)
	}
	if err := validateKeyPart(service); err != nil {
		return nil, fmt.Errorf("service: %w", err)
	}
	if defaultTTL <= 0 {
		defaultTTL = 15 * time.Minute
	}

	return &ProjectionRebuildGuard{
		store:      store,
		env:        env,
		service:    service,
		defaultTTL: defaultTTL,
	}, nil
}

func (g *ProjectionRebuildGuard) BuildKey(tenantID, projection string) (string, error) {
	if strings.TrimSpace(tenantID) == "" {
		return "", ErrEmptyTenantID
	}
	if strings.TrimSpace(projection) == "" {
		return "", ErrEmptyProjection
	}
	if err := validateKeyPart(tenantID); err != nil {
		return "", fmt.Errorf("tenant id: %w", err)
	}
	if err := validateKeyPart(projection); err != nil {
		return "", fmt.Errorf("projection: %w", err)
	}

	key := strings.Join([]string{
		"pix2pi",
		g.env,
		g.service,
		"tenant",
		tenantID,
		"projection",
		projection,
		"rebuild_guard",
	}, ":")

	return key, nil
}

func (g *ProjectionRebuildGuard) Activate(
	ctx context.Context,
	tenantID string,
	projection string,
	mode GuardMode,
	ttl time.Duration,
	reason string,
) error {
	if g == nil {
		return ErrNilProjectionRebuildGuard
	}
	state := ProjectionGuardState{
		Mode:          mode,
		Reason:        reason,
		StartedAtUnix: time.Now().Unix(),
	}
	if err := state.Validate(); err != nil {
		return err
	}

	key, err := g.BuildKey(tenantID, projection)
	if err != nil {
		return err
	}
	if ttl <= 0 {
		ttl = g.defaultTTL
	}

	return g.store.Set(ctx, key, state, ttl)
}

func (g *ProjectionRebuildGuard) IsActive(
	ctx context.Context,
	tenantID string,
	projection string,
) (ProjectionGuardState, bool, error) {
	if g == nil {
		return ProjectionGuardState{}, false, ErrNilProjectionRebuildGuard
	}

	key, err := g.BuildKey(tenantID, projection)
	if err != nil {
		return ProjectionGuardState{}, false, err
	}

	var state ProjectionGuardState
	found, err := g.store.Get(ctx, key, &state)
	if err != nil {
		return ProjectionGuardState{}, false, err
	}
	if !found {
		return ProjectionGuardState{}, false, nil
	}
	if err := state.Validate(); err != nil {
		return ProjectionGuardState{}, false, err
	}

	return state, true, nil
}

func (g *ProjectionRebuildGuard) Clear(ctx context.Context, tenantID string, projection string) error {
	if g == nil {
		return ErrNilProjectionRebuildGuard
	}

	key, err := g.BuildKey(tenantID, projection)
	if err != nil {
		return err
	}

	return g.store.Delete(ctx, key)
}

func BeginProjectionRebuild(
	ctx context.Context,
	guard *ProjectionRebuildGuard,
	cache *ProjectionCache,
	tenantID string,
	projection string,
	mode GuardMode,
	ttl time.Duration,
	reason string,
) error {
	if guard == nil {
		return ErrNilProjectionRebuildGuard
	}
	if cache == nil {
		return ErrNilProjectionCache
	}

	if err := cache.DeleteProjection(ctx, tenantID, projection); err != nil {
		return err
	}

	return guard.Activate(ctx, tenantID, projection, mode, ttl, reason)
}

func EndProjectionRebuild(
	ctx context.Context,
	guard *ProjectionRebuildGuard,
	cache *ProjectionCache,
	tenantID string,
	projection string,
) error {
	if guard == nil {
		return ErrNilProjectionRebuildGuard
	}
	if cache == nil {
		return ErrNilProjectionCache
	}

	if err := guard.Clear(ctx, tenantID, projection); err != nil {
		return err
	}

	return cache.DeleteProjection(ctx, tenantID, projection)
}

func ExecuteQueryWithGuard[T any](
	ctx context.Context,
	bridge *QueryBridge,
	guard *ProjectionRebuildGuard,
	tenantID string,
	projection string,
	queryName string,
	page int,
	pageSize int,
	sort string,
	filterData map[string]any,
	loader func(context.Context) (T, error),
) (QueryExecutionResult[T], error) {
	if guard == nil {
		return ExecuteQuery(
			ctx,
			bridge,
			tenantID,
			projection,
			queryName,
			page,
			pageSize,
			sort,
			filterData,
			loader,
		)
	}

	state, active, err := guard.IsActive(ctx, tenantID, projection)
	if err != nil {
		var zero QueryExecutionResult[T]
		return zero, err
	}

	if !active {
		return ExecuteQuery(
			ctx,
			bridge,
			tenantID,
			projection,
			queryName,
			page,
			pageSize,
			sort,
			filterData,
			loader,
		)
	}

	scope, ok := bridge.Scope(projection, queryName)
	if !ok {
		var zero QueryExecutionResult[T]
		return zero, fmt.Errorf("%w: %s/%s", ErrUnknownQueryScope, projection, queryName)
	}

	data, err := loader(ctx)
	if err != nil {
		var zero QueryExecutionResult[T]
		return zero, err
	}

	return QueryExecutionResult[T]{
		Data:         data,
		CacheUsed:    false,
		CacheHit:     false,
		Decision:     scope.Decision,
		Projection:   scope.Projection,
		QueryName:    scope.QueryName,
		TTLClass:     scope.TTLClass,
		Invalidation: scope.InvalidationMode,
		GuardMode:    state.Mode,
		GuardActive:  true,
	}, nil
}
