package readcache

import (
	"context"
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"
)

var validPartRegex = regexp.MustCompile(`^[a-zA-Z0-9:_\-\.]+$`)

var (
	ErrNilStore          = errors.New("readcache: nil store")
	ErrEmptyEnv          = errors.New("readcache: empty env")
	ErrEmptyService      = errors.New("readcache: empty service")
	ErrEmptyTenantID     = errors.New("readcache: empty tenant id")
	ErrEmptyProjection   = errors.New("readcache: empty projection")
	ErrEmptyQueryName    = errors.New("readcache: empty query name")
	ErrInvalidKeyPart    = errors.New("readcache: invalid key part")
	ErrInvalidTTLClass   = errors.New("readcache: invalid ttl class")
	ErrInvalidPagination = errors.New("readcache: invalid pagination")
)

type Store interface {
	Get(ctx context.Context, key string, dest any) (bool, error)
	Set(ctx context.Context, key string, value any, ttl time.Duration) error
	Delete(ctx context.Context, key string) error
	DeletePattern(ctx context.Context, pattern string) error
}

type TTLClass string

const (
	TTLClassShort  TTLClass = "short"
	TTLClassMedium TTLClass = "medium"
	TTLClassLong   TTLClass = "long"
)

type TTLPolicy struct {
	Short  time.Duration
	Medium time.Duration
	Long   time.Duration
}

func DefaultTTLPolicy() TTLPolicy {
	return TTLPolicy{
		Short:  30 * time.Second,
		Medium: 5 * time.Minute,
		Long:   15 * time.Minute,
	}
}

func (p TTLPolicy) Resolve(class TTLClass) (time.Duration, error) {
	switch class {
	case TTLClassShort:
		return p.Short, nil
	case TTLClassMedium:
		return p.Medium, nil
	case TTLClassLong:
		return p.Long, nil
	default:
		return 0, ErrInvalidTTLClass
	}
}

type QuerySpec struct {
	TenantID   string
	Projection string
	QueryName  string
	Page       int
	PageSize   int
	Sort       string
	FilterData map[string]any
	TTLClass   TTLClass
}

func (s QuerySpec) Validate() error {
	if strings.TrimSpace(s.TenantID) == "" {
		return ErrEmptyTenantID
	}
	if strings.TrimSpace(s.Projection) == "" {
		return ErrEmptyProjection
	}
	if strings.TrimSpace(s.QueryName) == "" {
		return ErrEmptyQueryName
	}
	if s.Page < 0 || s.PageSize < 0 {
		return ErrInvalidPagination
	}

	if err := validateKeyPart(s.TenantID); err != nil {
		return fmt.Errorf("tenant id: %w", err)
	}
	if err := validateKeyPart(s.Projection); err != nil {
		return fmt.Errorf("projection: %w", err)
	}
	if err := validateKeyPart(s.QueryName); err != nil {
		return fmt.Errorf("query name: %w", err)
	}
	if s.Sort != "" {
		if err := validateKeyPart(s.Sort); err != nil {
			return fmt.Errorf("sort: %w", err)
		}
	}

	return nil
}

type ProjectionCache struct {
	store     Store
	env       string
	service   string
	ttlPolicy TTLPolicy
}

func NewProjectionCache(store Store, env, service string, ttlPolicy TTLPolicy) (*ProjectionCache, error) {
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
	if ttlPolicy.Short <= 0 || ttlPolicy.Medium <= 0 || ttlPolicy.Long <= 0 {
		ttlPolicy = DefaultTTLPolicy()
	}

	return &ProjectionCache{
		store:     store,
		env:       env,
		service:   service,
		ttlPolicy: ttlPolicy,
	}, nil
}

func (c *ProjectionCache) BuildKey(spec QuerySpec) (string, error) {
	if err := spec.Validate(); err != nil {
		return "", err
	}

	filterHash, err := buildFilterHash(spec.FilterData)
	if err != nil {
		return "", err
	}

	pagePart := strconv.Itoa(spec.Page)
	pageSizePart := strconv.Itoa(spec.PageSize)
	sortPart := spec.Sort
	if sortPart == "" {
		sortPart = "none"
	}

	key := strings.Join([]string{
		"pix2pi",
		c.env,
		c.service,
		"tenant",
		spec.TenantID,
		"projection",
		spec.Projection,
		"query",
		spec.QueryName,
		"page",
		pagePart,
		"size",
		pageSizePart,
		"sort",
		sortPart,
		"hash",
		filterHash,
	}, ":")

	return key, nil
}

func (c *ProjectionCache) BuildProjectionPattern(tenantID, projection string) (string, error) {
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

	pattern := strings.Join([]string{
		"pix2pi",
		c.env,
		c.service,
		"tenant",
		tenantID,
		"projection",
		projection,
		"*",
	}, ":")

	return pattern, nil
}

func (c *ProjectionCache) Set(ctx context.Context, spec QuerySpec, value any) error {
	key, err := c.BuildKey(spec)
	if err != nil {
		return err
	}

	ttl, err := c.ttlPolicy.Resolve(spec.TTLClass)
	if err != nil {
		return err
	}

	return c.store.Set(ctx, key, value, ttl)
}

func (c *ProjectionCache) Get(ctx context.Context, spec QuerySpec, dest any) (bool, error) {
	key, err := c.BuildKey(spec)
	if err != nil {
		return false, err
	}

	return c.store.Get(ctx, key, dest)
}

func (c *ProjectionCache) Delete(ctx context.Context, spec QuerySpec) error {
	key, err := c.BuildKey(spec)
	if err != nil {
		return err
	}

	return c.store.Delete(ctx, key)
}

func (c *ProjectionCache) DeleteProjection(ctx context.Context, tenantID, projection string) error {
	pattern, err := c.BuildProjectionPattern(tenantID, projection)
	if err != nil {
		return err
	}

	return c.store.DeletePattern(ctx, pattern)
}

func GetOrLoad[T any](ctx context.Context, cache *ProjectionCache, spec QuerySpec, loader func(context.Context) (T, error)) (T, bool, error) {
	var zero T
	if cache == nil {
		return zero, false, errors.New("readcache: nil projection cache")
	}
	if loader == nil {
		return zero, false, errors.New("readcache: nil loader")
	}

	var cached T
	found, err := cache.Get(ctx, spec, &cached)
	if err != nil {
		return zero, false, err
	}
	if found {
		return cached, true, nil
	}

	loaded, err := loader(ctx)
	if err != nil {
		return zero, false, err
	}

	if err := cache.Set(ctx, spec, loaded); err != nil {
		return zero, false, err
	}

	return loaded, false, nil
}

func buildFilterHash(filterData map[string]any) (string, error) {
	if len(filterData) == 0 {
		return "nofilter", nil
	}

	raw, err := json.Marshal(filterData)
	if err != nil {
		return "", fmt.Errorf("marshal filter data: %w", err)
	}

	sum := sha1.Sum(raw)
	return hex.EncodeToString(sum[:]), nil
}

func validateKeyPart(value string) error {
	if !validPartRegex.MatchString(value) {
		return ErrInvalidKeyPart
	}
	return nil
}
