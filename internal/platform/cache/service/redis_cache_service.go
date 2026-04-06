package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

type RedisCacheService struct {
	client *redis.Client
	ctx    context.Context
}

func NewRedisCacheService(
	addr string,
	password string,
	db int,
) *RedisCacheService {
	ctx := context.Background()

	client := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: password,
		DB:       db,
	})

	return &RedisCacheService{
		client: client,
		ctx:    ctx,
	}
}

func (s *RedisCacheService) Ping() error {
	if s.client == nil {
		return errors.New("redis client yok")
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
	if tenantID == "" {
		return "", errors.New("tenant id zorunlu")
	}
	if entity == "" {
		return "", errors.New("entity zorunlu")
	}
	if key == "" {
		return "", errors.New("key zorunlu")
	}

	return fmt.Sprintf("tenant:%s:%s:%s", tenantID, entity, key), nil
}

func (s *RedisCacheService) Set(
	tenantID string,
	entity string,
	key string,
	value string,
	ttl time.Duration,
) error {
	if s.client == nil {
		return errors.New("redis client yok")
	}

	cacheKey, err := s.tenantKey(tenantID, entity, key)
	if err != nil {
		return err
	}

	return s.client.Set(s.ctx, cacheKey, value, ttl).Err()
}

func (s *RedisCacheService) Get(
	tenantID string,
	entity string,
	key string,
) (string, error) {
	if s.client == nil {
		return "", errors.New("redis client yok")
	}

	cacheKey, err := s.tenantKey(tenantID, entity, key)
	if err != nil {
		return "", err
	}

	value, err := s.client.Get(s.ctx, cacheKey).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return "", errors.New("cache key bulunamadi")
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
		return errors.New("redis client yok")
	}

	cacheKey, err := s.tenantKey(tenantID, entity, key)
	if err != nil {
		return err
	}

	return s.client.Del(s.ctx, cacheKey).Err()
}

func (s *RedisCacheService) RawKeyOlustur(
	tenantID string,
	entity string,
	key string,
) (string, error) {
	return s.tenantKey(tenantID, entity, key)
}
