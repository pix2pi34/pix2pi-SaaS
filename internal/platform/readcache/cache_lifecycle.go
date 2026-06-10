package readcache

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

var (
	ErrEmptyLifecycleName         = errors.New("readcache: empty lifecycle name")
	ErrDuplicateLifecycleProfile  = errors.New("readcache: duplicate lifecycle profile")
	ErrUnknownLifecycleProfile    = errors.New("readcache: unknown lifecycle profile")
	ErrInvalidWarmupMode          = errors.New("readcache: invalid warmup mode")
	ErrInvalidEvictionPolicy      = errors.New("readcache: invalid eviction policy")
	ErrInvalidFallbackMode        = errors.New("readcache: invalid fallback mode")
)

type WarmupMode string

const (
	WarmupModeNone      WarmupMode = "none"
	WarmupModeStartup   WarmupMode = "startup"
	WarmupModeLazy      WarmupMode = "lazy"
	WarmupModeScheduled WarmupMode = "scheduled"
)

type EvictionPolicy string

const (
	EvictionPolicyTTLOnly    EvictionPolicy = "ttl_only"
	EvictionPolicyLRULike    EvictionPolicy = "lru_like"
	EvictionPolicyManual     EvictionPolicy = "manual"
	EvictionPolicyProtected  EvictionPolicy = "protected"
)

type FallbackMode string

const (
	FallbackModeFailClosed   FallbackMode = "fail_closed"
	FallbackModeBypass       FallbackMode = "bypass_to_source"
	FallbackModeServeStale   FallbackMode = "serve_stale"
)

type CacheLifecycleProfile struct {
	Name               string
	TTLClass           TTLClass
	Warmup             WarmupMode
	Eviction           EvictionPolicy
	Fallback           FallbackMode
	HotKeyCandidate    bool
	RequiresTenantSafe bool
	Reason             string
}

func (p CacheLifecycleProfile) Validate() error {
	if strings.TrimSpace(p.Name) == "" {
		return ErrEmptyLifecycleName
	}
	if err := validateKeyPart(p.Name); err != nil {
		return fmt.Errorf("name: %w", err)
	}
	if _, err := DefaultTTLPolicy().Resolve(p.TTLClass); err != nil {
		return err
	}

	switch p.Warmup {
	case WarmupModeNone, WarmupModeStartup, WarmupModeLazy, WarmupModeScheduled:
	default:
		return ErrInvalidWarmupMode
	}

	switch p.Eviction {
	case EvictionPolicyTTLOnly, EvictionPolicyLRULike, EvictionPolicyManual, EvictionPolicyProtected:
	default:
		return ErrInvalidEvictionPolicy
	}

	switch p.Fallback {
	case FallbackModeFailClosed, FallbackModeBypass, FallbackModeServeStale:
	default:
		return ErrInvalidFallbackMode
	}

	return nil
}

type CacheLifecycleRegistry struct {
	items map[string]CacheLifecycleProfile
}

func NewCacheLifecycleRegistry() *CacheLifecycleRegistry {
	return &CacheLifecycleRegistry{
		items: make(map[string]CacheLifecycleProfile),
	}
}

func (r *CacheLifecycleRegistry) Register(profile CacheLifecycleProfile) error {
	if r == nil {
		return errors.New("readcache: nil cache lifecycle registry")
	}
	if err := profile.Validate(); err != nil {
		return err
	}
	if _, exists := r.items[profile.Name]; exists {
		return ErrDuplicateLifecycleProfile
	}

	r.items[profile.Name] = profile
	return nil
}

func (r *CacheLifecycleRegistry) MustRegister(profile CacheLifecycleProfile) {
	if err := r.Register(profile); err != nil {
		panic(err)
	}
}

func (r *CacheLifecycleRegistry) Get(name string) (CacheLifecycleProfile, bool) {
	if r == nil {
		return CacheLifecycleProfile{}, false
	}
	item, ok := r.items[name]
	return item, ok
}

func (r *CacheLifecycleRegistry) List() []CacheLifecycleProfile {
	if r == nil {
		return nil
	}

	result := make([]CacheLifecycleProfile, 0, len(r.items))
	for _, item := range r.items {
		result = append(result, item)
	}

	sort.Slice(result, func(i, j int) bool {
		return result[i].Name < result[j].Name
	})

	return result
}

func DefaultCacheLifecycleProfiles() *CacheLifecycleRegistry {
	registry := NewCacheLifecycleRegistry()

	registry.MustRegister(CacheLifecycleProfile{
		Name:               "dashboard_hot",
		TTLClass:           TTLClassShort,
		Warmup:             WarmupModeStartup,
		Eviction:           EvictionPolicyLRULike,
		Fallback:           FallbackModeServeStale,
		HotKeyCandidate:    true,
		RequiresTenantSafe: true,
		Reason:             "dashboard verileri sicak ve cok okunur",
	})

	registry.MustRegister(CacheLifecycleProfile{
		Name:               "report_balanced",
		TTLClass:           TTLClassMedium,
		Warmup:             WarmupModeLazy,
		Eviction:           EvictionPolicyTTLOnly,
		Fallback:           FallbackModeBypass,
		HotKeyCandidate:    false,
		RequiresTenantSafe: true,
		Reason:             "rapor cache kontrollu ama source'a donebilir",
	})

	registry.MustRegister(CacheLifecycleProfile{
		Name:               "export_prepared",
		TTLClass:           TTLClassMedium,
		Warmup:             WarmupModeScheduled,
		Eviction:           EvictionPolicyManual,
		Fallback:           FallbackModeBypass,
		HotKeyCandidate:    false,
		RequiresTenantSafe: true,
		Reason:             "export once hazirlanir ve gerektiginde temizlenir",
	})

	registry.MustRegister(CacheLifecycleProfile{
		Name:               "critical_reference",
		TTLClass:           TTLClassShort,
		Warmup:             WarmupModeNone,
		Eviction:           EvictionPolicyProtected,
		Fallback:           FallbackModeFailClosed,
		HotKeyCandidate:    false,
		RequiresTenantSafe: true,
		Reason:             "kritik veride agresif fallback ve eviction istemiyoruz",
	})

	return registry
}
