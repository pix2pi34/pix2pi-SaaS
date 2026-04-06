package service

import (
	"fmt"

	gatewaydomain "github.com/divrigili/pix2pi-SaaS/internal/platform/gateway/domain"
)

type RateLimitService struct {
	kayitlar map[string]gatewaydomain.RateLimitRecord
}

func NewRateLimitService() *RateLimitService {
	return &RateLimitService{
		kayitlar: make(map[string]gatewaydomain.RateLimitRecord),
	}
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

	s.kayitlar[tenantID] = gatewaydomain.RateLimitRecord{
		TenantID:     tenantID,
		DakikaLimiti: dakikaLimiti,
		Kullanilan:   0,
	}

	return nil
}

func (s *RateLimitService) IstekGecir(
	tenantID string,
) error {
	if tenantID == "" {
		return fmt.Errorf("tenant id zorunlu")
	}

	kayit, ok := s.kayitlar[tenantID]
	if !ok {
		return fmt.Errorf("tenant rate limit kaydi bulunamadi")
	}

	if kayit.Kullanilan >= kayit.DakikaLimiti {
		return fmt.Errorf("rate limit asildi")
	}

	kayit.Kullanilan++
	s.kayitlar[tenantID] = kayit

	return nil
}

func (s *RateLimitService) KayitGetir(
	tenantID string,
) (gatewaydomain.RateLimitRecord, error) {
	if tenantID == "" {
		return gatewaydomain.RateLimitRecord{}, fmt.Errorf("tenant id zorunlu")
	}

	kayit, ok := s.kayitlar[tenantID]
	if !ok {
		return gatewaydomain.RateLimitRecord{}, fmt.Errorf("tenant rate limit kaydi bulunamadi")
	}

	return kayit, nil
}

func (s *RateLimitService) Resetle(
	tenantID string,
) error {
	if tenantID == "" {
		return fmt.Errorf("tenant id zorunlu")
	}

	kayit, ok := s.kayitlar[tenantID]
	if !ok {
		return fmt.Errorf("tenant rate limit kaydi bulunamadi")
	}

	kayit.Kullanilan = 0
	s.kayitlar[tenantID] = kayit

	return nil
}
