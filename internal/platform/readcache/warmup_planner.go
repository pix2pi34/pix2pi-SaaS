package readcache

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

var (
	ErrNilWarmupPlanner        = errors.New("readcache: nil warmup planner")
	ErrNilWarmupTargetRegistry = errors.New("readcache: nil warmup target registry")
	ErrEmptyWarmupLifecycle    = errors.New("readcache: empty warmup lifecycle")
	ErrEmptyWarmupProjection   = errors.New("readcache: empty warmup projection")
	ErrEmptyWarmupQueryName    = errors.New("readcache: empty warmup query name")
	ErrDuplicateWarmupTarget   = errors.New("readcache: duplicate warmup target")
	ErrInvalidWarmupPriority   = errors.New("readcache: invalid warmup priority")
)

type WarmupPriority string

const (
	WarmupPriorityHigh   WarmupPriority = "high"
	WarmupPriorityNormal WarmupPriority = "normal"
	WarmupPriorityLow    WarmupPriority = "low"
)

type WarmupTarget struct {
	LifecycleName string
	Projection    string
	QueryName     string
	Priority      WarmupPriority
	Reason        string
}

func (t WarmupTarget) Validate() error {
	if strings.TrimSpace(t.LifecycleName) == "" {
		return ErrEmptyWarmupLifecycle
	}
	if strings.TrimSpace(t.Projection) == "" {
		return ErrEmptyWarmupProjection
	}
	if strings.TrimSpace(t.QueryName) == "" {
		return ErrEmptyWarmupQueryName
	}

	if err := validateKeyPart(t.LifecycleName); err != nil {
		return fmt.Errorf("lifecycle: %w", err)
	}
	if err := validateKeyPart(t.Projection); err != nil {
		return fmt.Errorf("projection: %w", err)
	}
	if err := validateKeyPart(t.QueryName); err != nil {
		return fmt.Errorf("query name: %w", err)
	}

	switch t.Priority {
	case WarmupPriorityHigh, WarmupPriorityNormal, WarmupPriorityLow:
	default:
		return ErrInvalidWarmupPriority
	}

	return nil
}

type WarmupTask struct {
	TenantID      string
	LifecycleName string
	Projection    string
	QueryName     string
	Surface       ReportingSurface
	TTLClass      TTLClass
	Warmup        WarmupMode
	Priority      WarmupPriority
	Reason        string
}

type WarmupTargetRegistry struct {
	items map[string]WarmupTarget
}

func NewWarmupTargetRegistry() *WarmupTargetRegistry {
	return &WarmupTargetRegistry{
		items: make(map[string]WarmupTarget),
	}
}

func (r *WarmupTargetRegistry) Register(target WarmupTarget) error {
	if r == nil {
		return ErrNilWarmupTargetRegistry
	}
	if err := target.Validate(); err != nil {
		return err
	}

	key := r.key(target.Projection, target.QueryName)
	if _, exists := r.items[key]; exists {
		return ErrDuplicateWarmupTarget
	}

	r.items[key] = target
	return nil
}

func (r *WarmupTargetRegistry) MustRegister(target WarmupTarget) {
	if err := r.Register(target); err != nil {
		panic(err)
	}
}

func (r *WarmupTargetRegistry) Get(projection, queryName string) (WarmupTarget, bool) {
	if r == nil {
		return WarmupTarget{}, false
	}
	item, ok := r.items[r.key(projection, queryName)]
	return item, ok
}

func (r *WarmupTargetRegistry) List() []WarmupTarget {
	if r == nil {
		return nil
	}

	result := make([]WarmupTarget, 0, len(r.items))
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

func (r *WarmupTargetRegistry) key(projection, queryName string) string {
	return projection + "::" + queryName
}

func DefaultWarmupTargets() *WarmupTargetRegistry {
	registry := NewWarmupTargetRegistry()

	registry.MustRegister(WarmupTarget{
		LifecycleName: "dashboard_hot",
		Projection:    "dashboard_kpi",
		QueryName:     "summary_cards",
		Priority:      WarmupPriorityHigh,
		Reason:        "dashboard kartlari startup warmup alabilir",
	})

	registry.MustRegister(WarmupTarget{
		LifecycleName: "dashboard_hot",
		Projection:    "dashboard_sales",
		QueryName:     "branch_overview",
		Priority:      WarmupPriorityHigh,
		Reason:        "sube bazli dashboard verisi startup warmup alabilir",
	})

	registry.MustRegister(WarmupTarget{
		LifecycleName: "report_balanced",
		Projection:    "sales_reports",
		QueryName:     "monthly_summary",
		Priority:      WarmupPriorityNormal,
		Reason:        "rapor warmup adayi ama profile warmup destegi kontrol edilir",
	})

	registry.MustRegister(WarmupTarget{
		LifecycleName: "export_prepared",
		Projection:    "export_sales",
		QueryName:     "prepare_excel_monthly",
		Priority:      WarmupPriorityLow,
		Reason:        "export scheduled warmup adayi ama profile export destek kuralina tabi",
	})

	return registry
}

type WarmupPlanner struct {
	lifecycles *CacheLifecycleRegistry
	profiles   *ReportingProfileRegistry
	targets    *WarmupTargetRegistry
}

func NewWarmupPlanner(
	lifecycles *CacheLifecycleRegistry,
	profiles *ReportingProfileRegistry,
	targets *WarmupTargetRegistry,
) (*WarmupPlanner, error) {
	if lifecycles == nil {
		return nil, ErrUnknownLifecycleProfile
	}
	if profiles == nil {
		return nil, ErrNilReportingProfileRegistry
	}
	if targets == nil {
		return nil, ErrNilWarmupTargetRegistry
	}

	return &WarmupPlanner{
		lifecycles: lifecycles,
		profiles:   profiles,
		targets:    targets,
	}, nil
}

func (p *WarmupPlanner) Plan(tenantID string, mode WarmupMode) ([]WarmupTask, error) {
	if p == nil {
		return nil, ErrNilWarmupPlanner
	}
	if strings.TrimSpace(tenantID) == "" {
		return nil, ErrEmptyTenantID
	}
	if err := validateKeyPart(tenantID); err != nil {
		return nil, fmt.Errorf("tenant id: %w", err)
	}

	result := make([]WarmupTask, 0)

	for _, target := range p.targets.List() {
		lifecycle, ok := p.lifecycles.Get(target.LifecycleName)
		if !ok {
			return nil, fmt.Errorf("%w: %s", ErrUnknownLifecycleProfile, target.LifecycleName)
		}
		if lifecycle.Warmup != mode {
			continue
		}

		profile, ok := p.profiles.Get(target.Projection, target.QueryName)
		if !ok {
			return nil, fmt.Errorf("%w: %s/%s", ErrUnknownReportingProfile, target.Projection, target.QueryName)
		}
		if !profile.SupportsWarmup {
			continue
		}

		result = append(result, WarmupTask{
			TenantID:      tenantID,
			LifecycleName: target.LifecycleName,
			Projection:    target.Projection,
			QueryName:     target.QueryName,
			Surface:       profile.Surface,
			TTLClass:      lifecycle.TTLClass,
			Warmup:        lifecycle.Warmup,
			Priority:      target.Priority,
			Reason:        target.Reason,
		})
	}

	sort.Slice(result, func(i, j int) bool {
		if result[i].Priority == result[j].Priority {
			if result[i].Projection == result[j].Projection {
				return result[i].QueryName < result[j].QueryName
			}
			return result[i].Projection < result[j].Projection
		}

		order := map[WarmupPriority]int{
			WarmupPriorityHigh:   0,
			WarmupPriorityNormal: 1,
			WarmupPriorityLow:    2,
		}
		return order[result[i].Priority] < order[result[j].Priority]
	})

	return result, nil
}

func (p *WarmupPlanner) PlanBySurface(tenantID string, mode WarmupMode, surface ReportingSurface) ([]WarmupTask, error) {
	if p == nil {
		return nil, ErrNilWarmupPlanner
	}

	switch surface {
	case ReportingSurfaceDashboard, ReportingSurfaceReport, ReportingSurfaceExport:
	default:
		return nil, ErrInvalidReportingSurface
	}

	all, err := p.Plan(tenantID, mode)
	if err != nil {
		return nil, err
	}

	filtered := make([]WarmupTask, 0)
	for _, item := range all {
		if item.Surface == surface {
			filtered = append(filtered, item)
		}
	}

	return filtered, nil
}

func BuildWarmupQuerySpec(task WarmupTask, filterData map[string]any) (QuerySpec, error) {
	if strings.TrimSpace(task.TenantID) == "" {
		return QuerySpec{}, ErrEmptyTenantID
	}
	if strings.TrimSpace(task.Projection) == "" {
		return QuerySpec{}, ErrEmptyProjection
	}
	if strings.TrimSpace(task.QueryName) == "" {
		return QuerySpec{}, ErrEmptyQueryName
	}
	if _, err := DefaultTTLPolicy().Resolve(task.TTLClass); err != nil {
		return QuerySpec{}, err
	}

	return QuerySpec{
		TenantID:   task.TenantID,
		Projection: task.Projection,
		QueryName:  task.QueryName,
		Page:       1,
		PageSize:   50,
		Sort:       "warmup",
		FilterData: filterData,
		TTLClass:   task.TTLClass,
	}, nil
}
