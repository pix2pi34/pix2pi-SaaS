package service

import (
	"fmt"
	"strconv"
	"sync"
	"time"

	cacheservice "github.com/divrigili/pix2pi-SaaS/internal/platform/cache/service"
	gatewaydomain "github.com/divrigili/pix2pi-SaaS/internal/platform/gateway/domain"
)

type QuotaService struct {
	mu       sync.RWMutex
	redisSvc *cacheservice.RedisCacheService
	limitler map[string]int
	entity   string
	pencere  time.Duration
}

func NewQuotaService() *QuotaService {
	return NewQuotaServiceWithRedis(
		cacheservice.NewRedisCacheServiceFromEnv(),
	)
}

func NewQuotaServiceWithRedis(
	redisSvc *cacheservice.RedisCacheService,
) *QuotaService {
	return &QuotaService{
		redisSvc: redisSvc,
		limitler: make(map[string]int),
		entity:   "gateway_daily_quota",
		pencere:  24 * time.Hour,
	}
}

func (s *QuotaService) Close() error {
	if s == nil || s.redisSvc == nil {
		return nil
	}

	return s.redisSvc.Close()
}

func (s *QuotaService) SetPencere(sure time.Duration) {
	if sure <= 0 {
		return
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	s.pencere = sure
}

func (s *QuotaService) pencereGetir() time.Duration {
	s.mu.RLock()
	defer s.mu.RUnlock()

	return s.pencere
}

func (s *QuotaService) pencereAnahtari() string {
	return "day:" + time.Now().UTC().Format("20060102")
}

func (s *QuotaService) tenantLimitGetir(
	tenantID string,
) (int, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	limit, ok := s.limitler[tenantID]
	if !ok {
		return 0, fmt.Errorf("tenant quota kaydi bulunamadi")
	}

	return limit, nil
}

func (s *QuotaService) TenantTanimla(
	tenantID string,
	gunlukLimit int,
) error {
	if tenantID == "" {
		return fmt.Errorf("tenant id zorunlu")
	}
	if gunlukLimit <= 0 {
		return fmt.Errorf("gunluk limit pozitif olmali")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	s.limitler[tenantID] = gunlukLimit
	return nil
}

func (s *QuotaService) IstekGecir(
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
		return fmt.Errorf("gunluk quota asildi")
	}

	return nil
}

func (s *QuotaService) KayitGetir(
	tenantID string,
) (gatewaydomain.QuotaRecord, error) {
	if tenantID == "" {
		return gatewaydomain.QuotaRecord{}, fmt.Errorf("tenant id zorunlu")
	}
	if s.redisSvc == nil {
		return gatewaydomain.QuotaRecord{}, fmt.Errorf("redis cache service yok")
	}

	limit, err := s.tenantLimitGetir(tenantID)
	if err != nil {
		return gatewaydomain.QuotaRecord{}, err
	}

	sayacKey := s.pencereAnahtari()

	deger, err := s.redisSvc.Get(tenantID, s.entity, sayacKey)
	if err != nil {
		if err == cacheservice.ErrCacheKeyBulunamadi {
			return gatewaydomain.QuotaRecord{
				TenantID:    tenantID,
				GunlukLimit: limit,
				Kullanilan:  0,
			}, nil
		}
		return gatewaydomain.QuotaRecord{}, err
	}

	kullanilan, err := strconv.Atoi(deger)
	if err != nil {
		return gatewaydomain.QuotaRecord{}, err
	}

	return gatewaydomain.QuotaRecord{
		TenantID:    tenantID,
		GunlukLimit: limit,
		Kullanilan:  kullanilan,
	}, nil
}

func (s *QuotaService) Resetle(
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
