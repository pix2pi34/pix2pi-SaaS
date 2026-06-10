package readcache

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

var (
	ErrEmptyQueryScopeProjection = errors.New("readcache: empty query scope projection")
	ErrEmptyQueryScopeName       = errors.New("readcache: empty query scope query name")
	ErrDuplicateQueryScope       = errors.New("readcache: duplicate query scope")
	ErrUnknownQueryScope         = errors.New("readcache: unknown query scope")
)

type ReadFrequency string

const (
	ReadFrequencyLow    ReadFrequency = "low"
	ReadFrequencyMedium ReadFrequency = "medium"
	ReadFrequencyHigh   ReadFrequency = "high"
)

type ChangeFrequency string

const (
	ChangeFrequencyLow    ChangeFrequency = "low"
	ChangeFrequencyMedium ChangeFrequency = "medium"
	ChangeFrequencyHigh   ChangeFrequency = "high"
)

type ParameterCardinality string

const (
	ParameterCardinalityLow    ParameterCardinality = "low"
	ParameterCardinalityMedium ParameterCardinality = "medium"
	ParameterCardinalityHigh   ParameterCardinality = "high"
)

type InvalidationMode string

const (
	InvalidationModeWrite   InvalidationMode = "write_after_commit"
	InvalidationModeEvent   InvalidationMode = "event_after_projection"
	InvalidationModeRebuild InvalidationMode = "rebuild_flush"
	InvalidationModeNone    InvalidationMode = "none"
)

type CacheDecision string

const (
	CacheDecisionAllow   CacheDecision = "allow"
	CacheDecisionDeny    CacheDecision = "deny"
	CacheDecisionCaution CacheDecision = "caution"
)

type QueryScope struct {
	Projection            string
	QueryName             string
	ReadFrequency         ReadFrequency
	ChangeFrequency       ChangeFrequency
	ParameterCardinality  ParameterCardinality
	RequiresStrongFresh   bool
	FinancialSourceOfTruth bool
	SupportsPagination    bool
	Reason                string
	Decision              CacheDecision
	TTLClass              TTLClass
	InvalidationMode      InvalidationMode
}

func (q QueryScope) Validate() error {
	if strings.TrimSpace(q.Projection) == "" {
		return ErrEmptyQueryScopeProjection
	}
	if strings.TrimSpace(q.QueryName) == "" {
		return ErrEmptyQueryScopeName
	}
	if err := validateKeyPart(q.Projection); err != nil {
		return fmt.Errorf("projection: %w", err)
	}
	if err := validateKeyPart(q.QueryName); err != nil {
		return fmt.Errorf("query name: %w", err)
	}

	switch q.ReadFrequency {
	case ReadFrequencyLow, ReadFrequencyMedium, ReadFrequencyHigh:
	default:
		return fmt.Errorf("read frequency: %w", ErrInvalidKeyPart)
	}

	switch q.ChangeFrequency {
	case ChangeFrequencyLow, ChangeFrequencyMedium, ChangeFrequencyHigh:
	default:
		return fmt.Errorf("change frequency: %w", ErrInvalidKeyPart)
	}

	switch q.ParameterCardinality {
	case ParameterCardinalityLow, ParameterCardinalityMedium, ParameterCardinalityHigh:
	default:
		return fmt.Errorf("parameter cardinality: %w", ErrInvalidKeyPart)
	}

	switch q.Decision {
	case CacheDecisionAllow, CacheDecisionDeny, CacheDecisionCaution:
	default:
		return fmt.Errorf("decision: %w", ErrInvalidKeyPart)
	}

	switch q.InvalidationMode {
	case InvalidationModeWrite, InvalidationModeEvent, InvalidationModeRebuild, InvalidationModeNone:
	default:
		return fmt.Errorf("invalidation mode: %w", ErrInvalidKeyPart)
	}

	switch q.Decision {
	case CacheDecisionAllow, CacheDecisionCaution:
		if _, err := DefaultTTLPolicy().Resolve(q.TTLClass); err != nil {
			return err
		}
	case CacheDecisionDeny:
		if q.TTLClass != "" {
			if _, err := DefaultTTLPolicy().Resolve(q.TTLClass); err != nil {
				return err
			}
		}
	}

	return nil
}

type QueryScopeRegistry struct {
	items map[string]QueryScope
}

func NewQueryScopeRegistry() *QueryScopeRegistry {
	return &QueryScopeRegistry{
		items: make(map[string]QueryScope),
	}
}

func (r *QueryScopeRegistry) Register(scope QueryScope) error {
	if r == nil {
		return errors.New("readcache: nil query scope registry")
	}
	if err := scope.Validate(); err != nil {
		return err
	}

	key := r.scopeKey(scope.Projection, scope.QueryName)
	if _, exists := r.items[key]; exists {
		return ErrDuplicateQueryScope
	}

	r.items[key] = scope
	return nil
}

func (r *QueryScopeRegistry) MustRegister(scope QueryScope) {
	if err := r.Register(scope); err != nil {
		panic(err)
	}
}

func (r *QueryScopeRegistry) Get(projection, queryName string) (QueryScope, bool) {
	if r == nil {
		return QueryScope{}, false
	}
	scope, ok := r.items[r.scopeKey(projection, queryName)]
	return scope, ok
}

func (r *QueryScopeRegistry) List() []QueryScope {
	if r == nil {
		return nil
	}

	result := make([]QueryScope, 0, len(r.items))
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

func (r *QueryScopeRegistry) MustGet(projection, queryName string) QueryScope {
	scope, ok := r.Get(projection, queryName)
	if !ok {
		panic(fmt.Errorf("%w: %s/%s", ErrUnknownQueryScope, projection, queryName))
	}
	return scope
}

func (r *QueryScopeRegistry) scopeKey(projection, queryName string) string {
	return projection + "::" + queryName
}

func DefaultProjectionQueryScopes() *QueryScopeRegistry {
	registry := NewQueryScopeRegistry()

	registry.MustRegister(QueryScope{
		Projection:             "sales_summary",
		QueryName:              "list_monthly",
		ReadFrequency:          ReadFrequencyHigh,
		ChangeFrequency:        ChangeFrequencyMedium,
		ParameterCardinality:   ParameterCardinalityMedium,
		RequiresStrongFresh:    false,
		FinancialSourceOfTruth: false,
		SupportsPagination:     true,
		Reason:                 "dashboard ve rapor ozetleri icin uygun projection cache",
		Decision:               CacheDecisionAllow,
		TTLClass:               TTLClassMedium,
		InvalidationMode:       InvalidationModeEvent,
	})

	registry.MustRegister(QueryScope{
		Projection:             "stock_snapshot",
		QueryName:              "list_by_branch",
		ReadFrequency:          ReadFrequencyHigh,
		ChangeFrequency:        ChangeFrequencyHigh,
		ParameterCardinality:   ParameterCardinalityMedium,
		RequiresStrongFresh:    true,
		FinancialSourceOfTruth: false,
		SupportsPagination:     true,
		Reason:                 "stok hizli degistigi icin dikkatli cache gerekir",
		Decision:               CacheDecisionCaution,
		TTLClass:               TTLClassShort,
		InvalidationMode:       InvalidationModeEvent,
	})

	registry.MustRegister(QueryScope{
		Projection:             "ledger_entries",
		QueryName:              "list_posted_entries",
		ReadFrequency:          ReadFrequencyMedium,
		ChangeFrequency:        ChangeFrequencyMedium,
		ParameterCardinality:   ParameterCardinalityHigh,
		RequiresStrongFresh:    true,
		FinancialSourceOfTruth: true,
		SupportsPagination:     true,
		Reason:                 "kritik finansal source of truth query cache disi kalmali",
		Decision:               CacheDecisionDeny,
		TTLClass:               "",
		InvalidationMode:       InvalidationModeNone,
	})

	return registry
}

func BuildQuerySpecFromScope(scope QueryScope, tenantID string, page, pageSize int, sort string, filterData map[string]any) (QuerySpec, error) {
	if err := scope.Validate(); err != nil {
		return QuerySpec{}, err
	}
	if strings.TrimSpace(tenantID) == "" {
		return QuerySpec{}, ErrEmptyTenantID
	}
	if scope.Decision == CacheDecisionDeny {
		return QuerySpec{}, fmt.Errorf("readcache: query scope %s/%s cache deny", scope.Projection, scope.QueryName)
	}

	return QuerySpec{
		TenantID:   tenantID,
		Projection: scope.Projection,
		QueryName:  scope.QueryName,
		Page:       page,
		PageSize:   pageSize,
		Sort:       sort,
		FilterData: filterData,
		TTLClass:   scope.TTLClass,
	}, nil
}
