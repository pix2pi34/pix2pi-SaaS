package cache

import (
	"context"

	"github.com/redis/go-redis/v9"
)

var ctx = context.Background()

type RedisCache struct {
	Client *redis.Client
}

func NewRedis(addr string) *RedisCache {

	rdb := redis.NewClient(&redis.Options{
		Addr: addr,
	})

	return &RedisCache{
		Client: rdb,
	}
}

func (r *RedisCache) Set(key string, value string) error {
	return r.Client.Set(ctx, key, value, 0).Err()
}

func (r *RedisCache) Get(key string) (string, error) {
	return r.Client.Get(ctx, key).Result()
}
