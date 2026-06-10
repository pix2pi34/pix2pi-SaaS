package readcache

import (
	"context"
	"errors"
	"fmt"
	"time"
)

var (
	ErrNilReportingBridge         = errors.New("readcache: nil reporting bridge")
	ErrNilReportingProfileRegistry = errors.New("readcache: nil reporting profile registry")
	ErrNilReportingLoader         = errors.New("readcache: nil reporting loader")
)

type ReportingExecutionResult[T any] struct {
	Data               T
	CacheUsed          bool
	CacheHit           bool
	Surface            ReportingSurface
	Decision           CacheDecision
	Projection         string
	QueryName          string
	TTLClass           TTLClass
	Invalidation       InvalidationMode
	RefreshModel       RefreshModel
	SupportsWarmup     bool
	SupportsExportSeed bool
	StaleTolerance     time.Duration
}

type ReportingBridge struct {
	profiles *ReportingProfileRegistry
	cache    *ProjectionCache
}

func NewReportingBridge(profiles *ReportingProfileRegistry, cache *ProjectionCache) (*ReportingBridge, error) {
	if profiles == nil {
		return nil, ErrNilReportingProfileRegistry
	}
	if cache == nil {
		return nil, ErrNilProjectionCache
	}

	return &ReportingBridge{
		profiles: profiles,
		cache:    cache,
	}, nil
}

func ExecuteReportingQuery[T any](
	ctx context.Context,
	bridge *ReportingBridge,
	tenantID string,
	projection string,
	queryName string,
	page int,
	pageSize int,
	sort string,
	filterData map[string]any,
	loader func(context.Context) (T, error),
) (ReportingExecutionResult[T], error) {
	var zero ReportingExecutionResult[T]

	if bridge == nil {
		return zero, ErrNilReportingBridge
	}
	if loader == nil {
		return zero, ErrNilReportingLoader
	}

	profile, ok := bridge.profiles.Get(projection, queryName)
	if !ok {
		return zero, fmt.Errorf("%w: %s/%s", ErrUnknownReportingProfile, projection, queryName)
	}

	result := ReportingExecutionResult[T]{
		Surface:            profile.Surface,
		Decision:           profile.Decision,
		Projection:         profile.Projection,
		QueryName:          profile.QueryName,
		TTLClass:           profile.TTLClass,
		Invalidation:       profile.InvalidationMode,
		RefreshModel:       profile.RefreshModel,
		SupportsWarmup:     profile.SupportsWarmup,
		SupportsExportSeed: profile.SupportsExportSeed,
		StaleTolerance:     profile.StaleTolerance,
	}

	switch profile.Decision {
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
		spec, err := BuildReportingQuerySpec(
			profile,
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
		return zero, fmt.Errorf("readcache: unsupported reporting decision %q", profile.Decision)
	}
}

func (b *ReportingBridge) Profile(projection, queryName string) (ReportingProfile, bool) {
	if b == nil {
		return ReportingProfile{}, false
	}
	return b.profiles.Get(projection, queryName)
}

func (b *ReportingBridge) ProfilesBySurface(surface ReportingSurface) []ReportingProfile {
	if b == nil {
		return nil
	}
	return b.profiles.ListBySurface(surface)
}

func (b *ReportingBridge) InvalidateReportingProjection(ctx context.Context, tenantID, projection, queryName string) error {
	if b == nil {
		return ErrNilReportingBridge
	}

	_, ok := b.profiles.Get(projection, queryName)
	if !ok {
		return fmt.Errorf("%w: %s/%s", ErrUnknownReportingProfile, projection, queryName)
	}

	return b.cache.DeleteProjection(ctx, tenantID, projection)
}

func (b *ReportingBridge) InvalidateReportingSurface(ctx context.Context, tenantID string, surface ReportingSurface) error {
	if b == nil {
		return ErrNilReportingBridge
	}

	switch surface {
	case ReportingSurfaceDashboard, ReportingSurfaceReport, ReportingSurfaceExport:
	default:
		return ErrInvalidReportingSurface
	}

	profiles := b.profiles.ListBySurface(surface)
	seen := make(map[string]struct{})

	for _, profile := range profiles {
		if _, exists := seen[profile.Projection]; exists {
			continue
		}
		seen[profile.Projection] = struct{}{}

		if err := b.cache.DeleteProjection(ctx, tenantID, profile.Projection); err != nil {
			return err
		}
	}

	return nil
}
