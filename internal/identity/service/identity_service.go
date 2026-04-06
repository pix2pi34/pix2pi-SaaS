package service

import (
	"github.com/divrigili/pix2pi-SaaS/internal/identity/repository"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/kernel"
)

type IdentityService struct {
	repo repository.IdentityRepository
}

func NewIdentityService(repo repository.IdentityRepository) *IdentityService {
	return &IdentityService{repo: repo}
}

func (s *IdentityService) WhoAmI(ctx kernel.Context) (map[string]any, error) {
	// İş kuralı burada büyüyecek (RBAC, kullanıcı, rol vs.)
	return s.repo.WhoAmI(ctx)
}
