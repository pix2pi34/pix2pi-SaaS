package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

var (
	ErrRedisClientYok     = errors.New("redis client yok")
	ErrTenantIDZorunlu    = errors.New("tenant id zorunlu")
	ErrEntityZorunlu      = errors.New("entity zorunlu")
	ErrKeyZorunlu         = errors.New("key zorunlu")
	ErrCacheKeyBulunamadi = errors.New("cache key bulunamadi")
)

type RedisConfig struct {
	Addr         string
	Password     string
	DB           int
	KeyPrefix    string
	DefaultTTL   time.Duration
	DialTimeout  time.Duration
	ReadTimeout  time.Duration
	WriteTimeout time.Duration
}

type RedisCacheService struct {
	client *redis.Client
	ctx    context.Context
	cfg    RedisConfig
}

func defaultRedisConfig() RedisConfig {
	return RedisConfig{
		Addr:         "127.0.0.1:6379",
		Password:     "",
		DB:           0,
		KeyPrefix:    "tenant",
		DefaultTTL:   5 * time.Minute,
		DialTimeout:  3 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
	}
}

func envOrDefault(key string, fallback string) string {
	deger := strings.TrimSpace(os.Getenv(key))
	if deger == "" {
		return fallback
	}
	return deger
}

func envIntOrDefault(key string, fallback int) int {
	deger := strings.TrimSpace(os.Getenv(key))
	if deger == "" {
		return fallback
	}

	n, err := strconv.Atoi(deger)
	if err != nil {
		return fallback
	}

	return n
}

func envSecondsOrDefault(key string, fallback time.Duration) time.Duration {
	deger := strings.TrimSpace(os.Getenv(key))
	if deger == "" {
		return fallback
	}

	n, err := strconv.Atoi(deger)
	if err != nil || n <= 0 {
		return fallback
	}

	return time.Duration(n) * time.Second
}

func normalizeConfig(cfg RedisConfig) RedisConfig {
	def := defaultRedisConfig()

	if strings.TrimSpace(cfg.Addr) == "" {
		cfg.Addr = def.Addr
	}
	if strings.TrimSpace(cfg.KeyPrefix) == "" {
		cfg.KeyPrefix = def.KeyPrefix
	}
	if cfg.DefaultTTL <= 0 {
		cfg.DefaultTTL = def.DefaultTTL
	}
	if cfg.DialTimeout <= 0 {
		cfg.DialTimeout = def.DialTimeout
	}
	if cfg.ReadTimeout <= 0 {
		cfg.ReadTimeout = def.ReadTimeout
	}
	if cfg.WriteTimeout <= 0 {
		cfg.WriteTimeout = def.WriteTimeout
	}

	return cfg
}

func NewRedisCacheService(
	addr string,
	password string,
	db int,
) *RedisCacheService {
	cfg := RedisConfig{
		Addr:     addr,
		Password: password,
		DB:       db,
	}

	return NewRedisCacheServiceWithConfig(cfg)
}

func NewRedisCacheServiceWithConfig(
	cfg RedisConfig,
) *RedisCacheService {
	cfg = normalizeConfig(cfg)

	client := redis.NewClient(&redis.Options{
		Addr:         cfg.Addr,
		Password:     cfg.Password,
		DB:           cfg.DB,
		DialTimeout:  cfg.DialTimeout,
		ReadTimeout:  cfg.ReadTimeout,
		WriteTimeout: cfg.WriteTimeout,
	})

	return &RedisCacheService{
		client: client,
		ctx:    context.Background(),
		cfg:    cfg,
	}
}

func NewRedisCacheServiceFromEnv() *RedisCacheService {
	def := defaultRedisConfig()

	cfg := RedisConfig{
		Addr:         envOrDefault("REDIS_ADDR", def.Addr),
		Password:     envOrDefault("REDIS_PASSWORD", def.Password),
		DB:           envIntOrDefault("REDIS_DB", def.DB),
		KeyPrefix:    envOrDefault("REDIS_KEY_PREFIX", def.KeyPrefix),
		DefaultTTL:   envSecondsOrDefault("REDIS_DEFAULT_TTL_SECONDS", def.DefaultTTL),
		DialTimeout:  envSecondsOrDefault("REDIS_DIAL_TIMEOUT_SECONDS", def.DialTimeout),
		ReadTimeout:  envSecondsOrDefault("REDIS_READ_TIMEOUT_SECONDS", def.ReadTimeout),
		WriteTimeout: envSecondsOrDefault("REDIS_WRITE_TIMEOUT_SECONDS", def.WriteTimeout),
	}

	return NewRedisCacheServiceWithConfig(cfg)
}

func (s *RedisCacheService) Close() error {
	if s == nil || s.client == nil {
		return nil
	}

	return s.client.Close()
}

func (s *RedisCacheService) Addr() string {
	return s.cfg.Addr
}

func (s *RedisCacheService) KeyPrefix() string {
	return s.cfg.KeyPrefix
}

func (s *RedisCacheService) DefaultTTL() time.Duration {
	return s.cfg.DefaultTTL
}

func (s *RedisCacheService) Ping() error {
	if s.client == nil {
		return ErrRedisClientYok
	}

	_, err := s.client.Ping(s.ctx).Result()
	if err != nil {
		return err
	}

	return nil
}

func (s *RedisCacheService) tenantKey(
	tenantID string,
	entity string,
	key string,
) (string, error) {
	if strings.TrimSpace(tenantID) == "" {
		return "", ErrTenantIDZorunlu
	}
	if strings.TrimSpace(entity) == "" {
		return "", ErrEntityZorunlu
	}
	if strings.TrimSpace(key) == "" {
		return "", ErrKeyZorunlu
	}

	return fmt.Sprintf(
		"%s:%s:%s:%s",
		s.cfg.KeyPrefix,
		tenantID,
		entity,
		key,
	), nil
}

func (s *RedisCacheService) PatternOlustur(
	tenantID string,
	entity string,
	keyPattern string,
) (string, error) {
	if strings.TrimSpace(tenantID) == "" {
		return "", ErrTenantIDZorunlu
	}
	if strings.TrimSpace(entity) == "" {
		return "", ErrEntityZorunlu
	}
	if strings.TrimSpace(keyPattern) == "" {
		keyPattern = "*"
	}

	return fmt.Sprintf(
		"%s:%s:%s:%s",
		s.cfg.KeyPrefix,
		tenantID,
		entity,
		keyPattern,
	), nil
}

func (s *RedisCacheService) Set(
	tenantID string,
	entity string,
	key string,
	value string,
	ttl time.Duration,
) error {
	if s.client == nil {
		return ErrRedisClientYok
	}

	cacheKey, err := s.tenantKey(tenantID, entity, key)
	if err != nil {
		return err
	}

	if ttl <= 0 {
		ttl = s.cfg.DefaultTTL
	}

	return s.client.Set(s.ctx, cacheKey, value, ttl).Err()
}

func (s *RedisCacheService) SetKalici(
	tenantID string,
	entity string,
	key string,
	value string,
) error {
	if s.client == nil {
		return ErrRedisClientYok
	}

	cacheKey, err := s.tenantKey(tenantID, entity, key)
	if err != nil {
		return err
	}

	return s.client.Set(s.ctx, cacheKey, value, 0).Err()
}

func (s *RedisCacheService) Get(
	tenantID string,
	entity string,
	key string,
) (string, error) {
	if s.client == nil {
		return "", ErrRedisClientYok
	}

	cacheKey, err := s.tenantKey(tenantID, entity, key)
	if err != nil {
		return "", err
	}

	value, err := s.client.Get(s.ctx, cacheKey).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return "", ErrCacheKeyBulunamadi
		}
		return "", err
	}

	return value, nil
}

func (s *RedisCacheService) Delete(
	tenantID string,
	entity string,
	key string,
) error {
	if s.client == nil {
		return ErrRedisClientYok
	}

	cacheKey, err := s.tenantKey(tenantID, entity, key)
	if err != nil {
		return err
	}

	return s.client.Del(s.ctx, cacheKey).Err()
}

func (s *RedisCacheService) DeleteByPattern(
	tenantID string,
	entity string,
	keyPattern string,
) (int64, error) {
	if s.client == nil {
		return 0, ErrRedisClientYok
	}

	pattern, err := s.PatternOlustur(tenantID, entity, keyPattern)
	if err != nil {
		return 0, err
	}

	var toplam int64
	var cursor uint64

	for {
		keys, nextCursor, err := s.client.Scan(s.ctx, cursor, pattern, 200).Result()
		if err != nil {
			return toplam, err
		}

		if len(keys) > 0 {
			silinen, err := s.client.Del(s.ctx, keys...).Result()
			if err != nil {
				return toplam, err
			}
			toplam += silinen
		}

		cursor = nextCursor
		if cursor == 0 {
			break
		}
	}

	return toplam, nil
}

func (s *RedisCacheService) DeleteEntityNamespace(
	tenantID string,
	entity string,
) (int64, error) {
	return s.DeleteByPattern(tenantID, entity, "*")
}

func (s *RedisCacheService) TTLGetir(
	tenantID string,
	entity string,
	key string,
) (time.Duration, error) {
	if s.client == nil {
		return 0, ErrRedisClientYok
	}

	cacheKey, err := s.tenantKey(tenantID, entity, key)
	if err != nil {
		return 0, err
	}

	ttl, err := s.client.TTL(s.ctx, cacheKey).Result()
	if err != nil {
		return 0, err
	}

	return ttl, nil
}

func (s *RedisCacheService) RawKeyOlustur(
	tenantID string,
	entity string,
	key string,
) (string, error) {
	return s.tenantKey(tenantID, entity, key)
}

func (s *RedisCacheService) SetJSON(
	tenantID string,
	entity string,
	key string,
	value any,
	ttl time.Duration,
) error {
	bytes, err := json.Marshal(value)
	if err != nil {
		return err
	}

	return s.Set(
		tenantID,
		entity,
		key,
		string(bytes),
		ttl,
	)
}

func (s *RedisCacheService) GetJSON(
	tenantID string,
	entity string,
	key string,
	target any,
) error {
	value, err := s.Get(tenantID, entity, key)
	if err != nil {
		return err
	}

	return json.Unmarshal([]byte(value), target)
}

func (s *RedisCacheService) IncrWithTTLOnFirst(
	tenantID string,
	entity string,
	key string,
	ttl time.Duration,
) (int64, error) {
	if s.client == nil {
		return 0, ErrRedisClientYok
	}

	cacheKey, err := s.tenantKey(tenantID, entity, key)
	if err != nil {
		return 0, err
	}

	if ttl <= 0 {
		ttl = s.cfg.DefaultTTL
	}

	deger, err := s.client.Incr(s.ctx, cacheKey).Result()
	if err != nil {
		return 0, err
	}

	if deger == 1 {
		err = s.client.Expire(s.ctx, cacheKey, ttl).Err()
		if err != nil {
			return 0, err
		}
	}

	return deger, nil
}
