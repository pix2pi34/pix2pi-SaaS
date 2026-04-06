package platform

import (
	"context"
	"time"

	"github.com/redis/go-redis/v9"
)

type IdempotencyStore struct {
	rdb *redis.Client
	ctx context.Context
	ttl time.Duration
}

func NewIdempotencyStore(rdb *redis.Client, ttl time.Duration) *IdempotencyStore {
	return &IdempotencyStore{
		rdb: rdb,
		ctx: context.Background(),
		ttl: ttl,
	}
}

func (s *IdempotencyStore) key(eventID string) string {
	return "pix2pi:idempotency:" + eventID
}

func (s *IdempotencyStore) AlreadyProcessed(eventID string) (bool, error) {
	exists, err := s.rdb.Exists(s.ctx, s.key(eventID)).Result()
	if err != nil {
		return false, err
	}

	return exists == 1, nil
}

func (s *IdempotencyStore) MarkProcessed(eventID string) error {
	return s.rdb.Set(s.ctx, s.key(eventID), "1", s.ttl).Err()
}
