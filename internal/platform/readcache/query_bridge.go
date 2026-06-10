package readcache

import (
	"context"
	"errors"
	"fmt"
)

var (
	ErrNilQueryBridge     = errors.New("readcache: nil query bridge")
	ErrNilScopeRegistry   = errors.New("readcache: nil scope registry")
	ErrNilProjectionCache = errors.New("readcache: nil projection cache")
	ErrNilQueryLoader     = errors.New("readcache: nil query loader")
)

type QueryExecutionResult[T any] struct {
	Data         T
	CacheUsed    bool
	CacheHit     bool
	Decision     CacheDecision
	Projection   string
	QueryName    string
	TTLClass     TTLClass
	Invalidation InvalidationMode
	GuardMode    GuardMode
	GuardActive  bool
}

type QueryBridge struct {
	registry *QueryScopeRegistry
	cache    *ProjectionCache
}

func NewQueryBridge(registry *QueryScopeRegistry, cache *ProjectionCache) (*QueryBridge, error) {
	if registry == nil {
		return nil, ErrNilScopeRegistry
	}
	if cache == nil {
		return nil, ErrNilProjectionCache
	}

	return &QueryBridge{
		registry: registry,
		cache:    cache,
	}, nil
}

func ExecuteQuery[T any](
	ctx context.Context,
	bridge *QueryBridge,
	tenantID string,
	projection string,
	queryName string,
	page int,
	pageSize int,
	sort string,
	filterData map[string]any,
	loader func(context.Context) (T, error),
) (QueryExecutionResult[T], error) {
	var zero QueryExecutionResult[T]

	if bridge == nil {
		return zero, ErrNilQueryBridge
	}
	if loader == nil {
		return zero, ErrNilQueryLoader
	}

	scope, ok := bridge.registry.Get(projection, queryName)
	if !ok {
		return zero, fmt.Errorf("%w: %s/%s", ErrUnknownQueryScope, projection, queryName)
	}

	result := QueryExecutionResult[T]{
		Decision:     scope.Decision,
		Projection:   scope.Projection,
		QueryName:    scope.QueryName,
		TTLClass:     scope.TTLClass,
		Invalidation: scope.InvalidationMode,
		GuardMode:    "",
		GuardActive:  false,
	}

	switch scope.Decision {
	case CacheDecisionDeny:
		data, err := loader(ctx)
		if err != nil {
			return zero, err
		}
		result.Data = data
		result.CacheUsed = false
		result.CacheHit = false
		return result, nil

	case CacheDecisionAllow, CacheDecisionCaution:
		spec, err := BuildQuerySpecFromScope(
			scope,
			tenantID,
			page,
			pageSize,
			sort,
			filterData,
		)
		if err != nil {
			return zero, err
		}

		data, hit, err := GetOrLoad(ctx, bridge.cache, spec, loader)
		if err != nil {
			return zero, err
		}

		result.Data = data
		result.CacheUsed = true
		result.CacheHit = hit
		return result, nil

	default:
		return zero, fmt.Errorf("readcache: unsupported decision %q", scope.Decision)
	}
}

func (b *QueryBridge) InvalidateProjection(ctx context.Context, tenantID, projection string) error {
	if b == nil {
		return ErrNilQueryBridge
	}
	return b.cache.DeleteProjection(ctx, tenantID, projection)
}

func (b *QueryBridge) Scope(projection, queryName string) (QueryScope, bool) {
	if b == nil {
		return QueryScope{}, false
	}
	return b.registry.Get(projection, queryName)
}
