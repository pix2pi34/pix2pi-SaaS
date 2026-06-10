package readcache

import (
	"context"
	"errors"
	"fmt"
)

var (
	ErrNilFallbackExecutor = errors.New("readcache: nil fallback executor")
	ErrNilCacheAttempt     = errors.New("readcache: nil cache attempt")
	ErrNilSourceLoader     = errors.New("readcache: nil source loader")
)

type FallbackExecutionResult[T any] struct {
	Data         T
	CacheUsed    bool
	CacheHit     bool
	FallbackUsed bool
	ServedStale  bool
	Lifecycle    string
	FallbackMode FallbackMode
}

type FallbackExecutor struct {
	lifecycles *CacheLifecycleRegistry
}

func NewFallbackExecutor(lifecycles *CacheLifecycleRegistry) (*FallbackExecutor, error) {
	if lifecycles == nil {
		return nil, ErrUnknownLifecycleProfile
	}

	return &FallbackExecutor{
		lifecycles: lifecycles,
	}, nil
}

func ExecuteWithFallback[T any](
	ctx context.Context,
	executor *FallbackExecutor,
	lifecycleName string,
	cacheAttempt func(context.Context) (T, bool, error),
	sourceLoader func(context.Context) (T, error),
	staleLoader func(context.Context) (T, bool, error),
) (FallbackExecutionResult[T], error) {
	var zero FallbackExecutionResult[T]

	if executor == nil {
		return zero, ErrNilFallbackExecutor
	}
	if cacheAttempt == nil {
		return zero, ErrNilCacheAttempt
	}
	if sourceLoader == nil {
		return zero, ErrNilSourceLoader
	}

	lifecycle, ok := executor.lifecycles.Get(lifecycleName)
	if !ok {
		return zero, fmt.Errorf("%w: %s", ErrUnknownLifecycleProfile, lifecycleName)
	}

	result := FallbackExecutionResult[T]{
		Lifecycle:    lifecycle.Name,
		FallbackMode: lifecycle.Fallback,
	}

	cached, hit, err := cacheAttempt(ctx)
	if err == nil {
		result.CacheUsed = true
		result.CacheHit = hit

		if hit {
			result.Data = cached
			return result, nil
		}

		data, loadErr := sourceLoader(ctx)
		if loadErr != nil {
			return zero, loadErr
		}

		result.Data = data
		return result, nil
	}

	switch lifecycle.Fallback {
	case FallbackModeFailClosed:
		return zero, fmt.Errorf("readcache: fail_closed fallback triggered: %w", err)

	case FallbackModeBypass:
		data, loadErr := sourceLoader(ctx)
		if loadErr != nil {
			return zero, loadErr
		}

		result.Data = data
		result.CacheUsed = false
		result.CacheHit = false
		result.FallbackUsed = true
		result.ServedStale = false
		return result, nil

	case FallbackModeServeStale:
		if staleLoader != nil {
			staleData, staleFound, staleErr := staleLoader(ctx)
			if staleErr == nil && staleFound {
				result.Data = staleData
				result.CacheUsed = false
				result.CacheHit = false
				result.FallbackUsed = true
				result.ServedStale = true
				return result, nil
			}
		}

		data, loadErr := sourceLoader(ctx)
		if loadErr != nil {
			return zero, loadErr
		}

		result.Data = data
		result.CacheUsed = false
		result.CacheHit = false
		result.FallbackUsed = true
		result.ServedStale = false
		return result, nil

	default:
		return zero, ErrInvalidFallbackMode
	}
}
