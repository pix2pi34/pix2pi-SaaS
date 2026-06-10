package service

import (
	"fmt"
	"strconv"
	"sync"
	"time"

	cacheservice "github.com/divrigili/pix2pi-SaaS/internal/platform/cache/service"
	gatewaydomain "github.com/divrigili/pix2pi-SaaS/internal/platform/gateway/domain"
)

type RateLimitService struct {
	mu       sync.RWMutex
	redisSvc *cacheservice.RedisCacheService
	limitler map[string]int
	entity   string
	pencere  time.Duration
}

func NewRateLimitService() *RateLimitService {
	return NewRateLimitServiceWithRedis(
		cacheservice.NewRedisCacheServiceFromEnv(),
	)
}

func NewRateLimitServiceWithRedis(
	redisSvc *cacheservice.RedisCacheService,
) *RateLimitService {
	return &RateLimitService{
		redisSvc: redisSvc,
		limitler: make(map[string]int),
		entity:   "gateway_rate_limit",
		pencere:  time.Minute,
	}
}

func (s *RateLimitService) Close() error {
	if s == nil || s.redisSvc == nil {
		return nil
	}

	return s.redisSvc.Close()
}

func (s *RateLimitService) SetPencere(sure time.Duration) {
	if sure <= 0 {
		return
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	s.pencere = sure
}

func (s *RateLimitService) pencereGetir() time.Duration {
	s.mu.RLock()
	defer s.mu.RUnlock()

	return s.pencere
}

func (s *RateLimitService) pencereAnahtari() string {
	return "window:" + time.Now().UTC().Format("200601021504")
}

func (s *RateLimitService) tenantLimitGetir(
	tenantID string,
) (int, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	limit, ok := s.limitler[tenantID]
	if !ok {
		return 0, fmt.Errorf("tenant rate limit kaydi bulunamadi")
	}

	return limit, nil
}

func (s *RateLimitService) TenantTanimla(
	tenantID string,
	dakikaLimiti int,
) error {
	if tenantID == "" {
		return fmt.Errorf("tenant id zorunlu")
	}
	if dakikaLimiti <= 0 {
		return fmt.Errorf("dakika limiti pozitif olmali")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	s.limitler[tenantID] = dakikaLimiti
	return nil
}

func (s *RateLimitService) IstekGecir(
	tenantID string,
) error {
	if tenantID == "" {
		return fmt.Errorf("tenant id zorunlu")
	}
	if s.redisSvc == nil {
		return fmt.Errorf("redis cache service yok")
	}

	limit, err := s.tenantLimitGetir(tenantID)
	if err != nil {
		return err
	}

	sayacKey := s.pencereAnahtari()

	kullanilan, err := s.redisSvc.IncrWithTTLOnFirst(
		tenantID,
		s.entity,
		sayacKey,
		s.pencereGetir()+5*time.Second,
	)
	if err != nil {
		return err
	}

	if int(kullanilan) > limit {
		return fmt.Errorf("rate limit asildi")
	}

	return nil
}

func (s *RateLimitService) KayitGetir(
	tenantID string,
) (gatewaydomain.RateLimitRecord, error) {
	if tenantID == "" {
		return gatewaydomain.RateLimitRecord{}, fmt.Errorf("tenant id zorunlu")
	}
	if s.redisSvc == nil {
		return gatewaydomain.RateLimitRecord{}, fmt.Errorf("redis cache service yok")
	}

	limit, err := s.tenantLimitGetir(tenantID)
	if err != nil {
		return gatewaydomain.RateLimitRecord{}, err
	}

	sayacKey := s.pencereAnahtari()

	deger, err := s.redisSvc.Get(tenantID, s.entity, sayacKey)
	if err != nil {
		if err == cacheservice.ErrCacheKeyBulunamadi {
			return gatewaydomain.RateLimitRecord{
				TenantID:     tenantID,
				DakikaLimiti: limit,
				Kullanilan:   0,
			}, nil
		}
		return gatewaydomain.RateLimitRecord{}, err
	}

	kullanilan, err := strconv.Atoi(deger)
	if err != nil {
		return gatewaydomain.RateLimitRecord{}, err
	}

	return gatewaydomain.RateLimitRecord{
		TenantID:     tenantID,
		DakikaLimiti: limit,
		Kullanilan:   kullanilan,
	}, nil
}

func (s *RateLimitService) Resetle(
	tenantID string,
) error {
	if tenantID == "" {
		return fmt.Errorf("tenant id zorunlu")
	}
	if s.redisSvc == nil {
		return fmt.Errorf("redis cache service yok")
	}

	_, err := s.tenantLimitGetir(tenantID)
	if err != nil {
		return err
	}

	sayacKey := s.pencereAnahtari()

	return s.redisSvc.Delete(tenantID, s.entity, sayacKey)
}
