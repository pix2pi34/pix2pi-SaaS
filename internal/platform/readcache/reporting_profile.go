package readcache

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

var (
	ErrEmptyReportingProjection = errors.New("readcache: empty reporting projection")
	ErrEmptyReportingQueryName  = errors.New("readcache: empty reporting query name")
	ErrDuplicateReportingProfile = errors.New("readcache: duplicate reporting profile")
	ErrUnknownReportingProfile   = errors.New("readcache: unknown reporting profile")
	ErrInvalidReportingSurface   = errors.New("readcache: invalid reporting surface")
)

type ReportingSurface string

const (
	ReportingSurfaceDashboard ReportingSurface = "dashboard"
	ReportingSurfaceReport    ReportingSurface = "report"
	ReportingSurfaceExport    ReportingSurface = "export"
)

type RefreshModel string

const (
	RefreshModelEvent   RefreshModel = "event_driven"
	RefreshModelDelayed RefreshModel = "delayed_refresh"
	RefreshModelManual  RefreshModel = "manual_refresh"
)

type ReportingProfile struct {
	Projection         string
	QueryName          string
	Surface            ReportingSurface
	Decision           CacheDecision
	TTLClass           TTLClass
	InvalidationMode   InvalidationMode
	RefreshModel       RefreshModel
	SupportsWarmup     bool
	SupportsExportSeed bool
	StaleTolerance     time.Duration
	Reason             string
}

func (p ReportingProfile) Validate() error {
	if strings.TrimSpace(p.Projection) == "" {
		return ErrEmptyReportingProjection
	}
	if strings.TrimSpace(p.QueryName) == "" {
		return ErrEmptyReportingQueryName
	}
	if err := validateKeyPart(p.Projection); err != nil {
		return fmt.Errorf("projection: %w", err)
	}
	if err := validateKeyPart(p.QueryName); err != nil {
		return fmt.Errorf("query name: %w", err)
	}

	switch p.Surface {
	case ReportingSurfaceDashboard, ReportingSurfaceReport, ReportingSurfaceExport:
	default:
		return ErrInvalidReportingSurface
	}

	switch p.Decision {
	case CacheDecisionAllow, CacheDecisionCaution, CacheDecisionDeny:
	default:
		return ErrInvalidKeyPart
	}

	switch p.InvalidationMode {
	case InvalidationModeWrite, InvalidationModeEvent, InvalidationModeRebuild, InvalidationModeNone:
	default:
		return ErrInvalidKeyPart
	}

	switch p.RefreshModel {
	case RefreshModelEvent, RefreshModelDelayed, RefreshModelManual:
	default:
		return ErrInvalidKeyPart
	}

	switch p.Decision {
	case CacheDecisionAllow, CacheDecisionCaution:
		if _, err := DefaultTTLPolicy().Resolve(p.TTLClass); err != nil {
			return err
		}
	case CacheDecisionDeny:
		if p.TTLClass != "" {
			if _, err := DefaultTTLPolicy().Resolve(p.TTLClass); err != nil {
				return err
			}
		}
	}

	return nil
}

type ReportingProfileRegistry struct {
	items map[string]ReportingProfile
}

func NewReportingProfileRegistry() *ReportingProfileRegistry {
	return &ReportingProfileRegistry{
		items: make(map[string]ReportingProfile),
	}
}

func (r *ReportingProfileRegistry) Register(profile ReportingProfile) error {
	if r == nil {
		return errors.New("readcache: nil reporting profile registry")
	}
	if err := profile.Validate(); err != nil {
		return err
	}

	key := r.profileKey(profile.Projection, profile.QueryName)
	if _, exists := r.items[key]; exists {
		return ErrDuplicateReportingProfile
	}

	r.items[key] = profile
	return nil
}

func (r *ReportingProfileRegistry) MustRegister(profile ReportingProfile) {
	if err := r.Register(profile); err != nil {
		panic(err)
	}
}

func (r *ReportingProfileRegistry) Get(projection, queryName string) (ReportingProfile, bool) {
	if r == nil {
		return ReportingProfile{}, false
	}
	item, ok := r.items[r.profileKey(projection, queryName)]
	return item, ok
}

func (r *ReportingProfileRegistry) List() []ReportingProfile {
	if r == nil {
		return nil
	}

	result := make([]ReportingProfile, 0, len(r.items))
	for _, item := range r.items {
		result = append(result, item)
	}

	sort.Slice(result, func(i, j int) bool {
		if result[i].Projection == result[j].Projection {
			return result[i].QueryName < result[j].QueryName
		}
		return result[i].Projection < result[j].Projection
	})

	return result
}

func (r *ReportingProfileRegistry) ListBySurface(surface ReportingSurface) []ReportingProfile {
	if r == nil {
		return nil
	}

	all := r.List()
	filtered := make([]ReportingProfile, 0)
	for _, item := range all {
		if item.Surface == surface {
			filtered = append(filtered, item)
		}
	}
	return filtered
}

func (r *ReportingProfileRegistry) profileKey(projection, queryName string) string {
	return projection + "::" + queryName
}

func DefaultReportingProfiles() *ReportingProfileRegistry {
	registry := NewReportingProfileRegistry()

	registry.MustRegister(ReportingProfile{
		Projection:         "dashboard_kpi",
		QueryName:          "summary_cards",
		Surface:            ReportingSurfaceDashboard,
		Decision:           CacheDecisionAllow,
		TTLClass:           TTLClassShort,
		InvalidationMode:   InvalidationModeEvent,
		RefreshModel:       RefreshModelEvent,
		SupportsWarmup:     true,
		SupportsExportSeed: false,
		StaleTolerance:     30 * time.Second,
		Reason:             "dashboard ozet kartlari icin uygun cache profili",
	})

	registry.MustRegister(ReportingProfile{
		Projection:         "dashboard_sales",
		QueryName:          "branch_overview",
		Surface:            ReportingSurfaceDashboard,
		Decision:           CacheDecisionCaution,
		TTLClass:           TTLClassShort,
		InvalidationMode:   InvalidationModeEvent,
		RefreshModel:       RefreshModelDelayed,
		SupportsWarmup:     true,
		SupportsExportSeed: false,
		StaleTolerance:     15 * time.Second,
		Reason:             "sik degisen dashboard verisi dikkatli cache edilmeli",
	})

	registry.MustRegister(ReportingProfile{
		Projection:         "sales_reports",
		QueryName:          "monthly_summary",
		Surface:            ReportingSurfaceReport,
		Decision:           CacheDecisionAllow,
		TTLClass:           TTLClassMedium,
		InvalidationMode:   InvalidationModeEvent,
		RefreshModel:       RefreshModelDelayed,
		SupportsWarmup:     false,
		SupportsExportSeed: true,
		StaleTolerance:     2 * time.Minute,
		Reason:             "rapor ozeti tarafinda uygun cache profili",
	})

	registry.MustRegister(ReportingProfile{
		Projection:         "export_sales",
		QueryName:          "prepare_excel_monthly",
		Surface:            ReportingSurfaceExport,
		Decision:           CacheDecisionCaution,
		TTLClass:           TTLClassMedium,
		InvalidationMode:   InvalidationModeRebuild,
		RefreshModel:       RefreshModelManual,
		SupportsWarmup:     false,
		SupportsExportSeed: true,
		StaleTolerance:     5 * time.Minute,
		Reason:             "export hazirlik akisi kontrollu cache ile calismali",
	})

	return registry
}

func BuildReportingQuerySpec(
	profile ReportingProfile,
	tenantID string,
	page int,
	pageSize int,
	sort string,
	filterData map[string]any,
) (QuerySpec, error) {
	if err := profile.Validate(); err != nil {
		return QuerySpec{}, err
	}
	if strings.TrimSpace(tenantID) == "" {
		return QuerySpec{}, ErrEmptyTenantID
	}
	if profile.Decision == CacheDecisionDeny {
		return QuerySpec{}, fmt.Errorf("readcache: reporting profile %s/%s cache deny", profile.Projection, profile.QueryName)
	}

	return QuerySpec{
		TenantID:   tenantID,
		Projection: profile.Projection,
		QueryName:  profile.QueryName,
		Page:       page,
		PageSize:   pageSize,
		Sort:       sort,
		FilterData: filterData,
		TTLClass:   profile.TTLClass,
	}, nil
}
