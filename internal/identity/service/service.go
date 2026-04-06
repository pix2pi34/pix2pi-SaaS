package service

import "github.com/divrigili/pix2pi-SaaS/internal/platform/kernel"

type Service struct{}

func New() *Service { return &Service{} }

// WhoAmI: KernelContext'i service seviyesinde kullandığımız ilk örnek
func (s *Service) WhoAmI(ctx kernel.Context) map[string]any {
	return map[string]any{
		"tenant_id":  ctx.TenantID,
		"request_id": ctx.RequestID,
	}
}
